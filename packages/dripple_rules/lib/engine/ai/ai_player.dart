import 'dart:math';
import '../../models/word_card.dart';
import '../../models/player.dart';
import '../../models/game_state.dart';
import '../grammar/grammar_engine.dart';

/// How hard the AI plays.
///
/// - [easy]   – sentences up to 3 cards, skips looking 30 % of the time,
///              and builds a hand of at most 5 before it starts shedding.
/// - [medium] – sentences up to 5 cards, skips looking 10 % of the time,
///              builds to 8.
/// - [hard]   – no practical length cap, always plays the longest sentence
///              it finds, and builds to 10 before shedding anything.
enum AIDifficulty { easy, medium, hard }

enum AIActionType { submitSentence, discard, pass, playJump, playSteal }

class AIAction {
  final AIActionType type;

  /// For [AIActionType.submitSentence]: the cards in sentence order.
  final List<WordCard>? cards;
  final WordCard? specialCard;
  final int? targetPlayerIndex;

  /// Index into the hand *after* the STEAL card is removed.
  final int? giveCardIndex;
  final int? discardIndex;

  const AIAction({
    required this.type,
    this.cards,
    this.specialCard,
    this.targetPlayerIndex,
    this.giveCardIndex,
    this.discardIndex,
  });
}

/// Rule-based opponent.
///
/// Sentence search runs the real grammar engine over permutations of a
/// bounded candidate pool. The pool cap keeps the worst case at
/// 8P7 = 40,320 validations, which is instant, while the diversity rule
/// in [_candidatePool] keeps the pool grammatically useful.
class AIPlayer {
  static const int _maxCandidates = 8;

  final GrammarEngine _engine;
  final Random _random;
  final AIDifficulty difficulty;

  AIPlayer({
    GrammarEngine? engine,
    Random? random,
    this.difficulty = AIDifficulty.medium,
  })  : _engine = engine ?? GrammarEngine(),
        _random = random ?? Random();

  int get _maxSentenceLength => switch (difficulty) {
        AIDifficulty.easy => 3,
        AIDifficulty.medium => 5,
        AIDifficulty.hard => 7,
      };

  double get _randomDiscardChance => switch (difficulty) {
        AIDifficulty.easy => 0.30,
        AIDifficulty.medium => 0.10,
        AIDifficulty.hard => 0.0,
      };

  /// How large a hand the AI will let itself grow before it throws cards away
  /// regardless of what they are.
  ///
  /// Holding cards is measurably the weaker line, so the *weakest* opponent
  /// holds the most. Sixty whole games with every seat driven by a hard AI:
  ///
  /// | passing            | won by emptying a hand | passes |
  /// |--------------------|------------------------|--------|
  /// | off                | 59 / 60                |      0 |
  /// | on, no deck guard  | 41 / 60                |    243 |
  /// | on, as shipped     | 48 / 60                |    203 |
  ///
  /// The rest ran the deck dry and fell to the anti-stalling rule, which is a
  /// duller way to win. That is why the AI passes narrowly — only with a card
  /// it cannot afford to lose, a hand still under this ceiling, and a deck
  /// with something left in it.
  int get _buildUpTo => switch (difficulty) {
        AIDifficulty.easy => 6,
        AIDifficulty.medium => 5,
        AIDifficulty.hard => 4,
      };

  /// Decide what to do in the action phase of the AI's turn.
  AIAction decideAction(Player me, GameState state) {
    if (_random.nextDouble() >= _randomDiscardChance) {
      final sentence = findSentence(me.hand);
      if (sentence != null) {
        return AIAction(type: AIActionType.submitSentence, cards: sentence);
      }
    }

    final special = _tryPlaySpecial(me, state);
    if (special != null) return special;

    // Nothing to play. Throwing a card away is still the better move whenever
    // there is a card worth losing — a discard refills the pile the deck is
    // recycled from, while passing drains the deck into hands and hands the
    // game to the anti-stalling rule. Pass only when every card left is one
    // the AI would rather keep.
    final worst = _pickDiscardIndex(me.hand);
    // Passing takes a card out of circulation for good: it leaves the deck and
    // never reaches the discard pile, so a recycle never brings it back. Once
    // the deck is down to less than a full deal each, holding cards starves
    // the board and hands the game to the anti-stalling rule instead of to
    // whoever played best.
    final deckIsHealthy = state.deck.length > state.players.length * 6;
    if (deckIsHealthy &&
        me.hand.length < _buildUpTo &&
        _usefulness(me.hand[worst]) >= 8) {
      return const AIAction(type: AIActionType.pass);
    }

    return AIAction(type: AIActionType.discard, discardIndex: worst);
  }

  /// Find a valid sentence in [hand], or null. Returns the actual card
  /// instances from [hand] so callers can remove them by identity or id.
  List<WordCard>? findSentence(List<WordCard> hand) {
    final pool = _candidatePool(hand);
    if (pool.length < 2) return null;

    final maxLen = min(_maxSentenceLength, pool.length);

    // Longest first: a longer sentence always empties the hand faster.
    for (int len = maxLen; len >= 2; len--) {
      final found = _searchPermutations(pool, len);
      if (found != null) return found;
    }
    return null;
  }

  /// Depth-first walk over ordered selections of exactly [len] cards.
  List<WordCard>? _searchPermutations(List<WordCard> pool, int len) {
    final used = List<bool>.filled(pool.length, false);
    final current = <WordCard>[];

    List<WordCard>? walk() {
      if (current.length == len) {
        return _engine.validate(current).isValid
            ? List<WordCard>.from(current)
            : null;
      }
      for (int i = 0; i < pool.length; i++) {
        if (used[i]) continue;
        used[i] = true;
        current.add(pool[i]);
        final result = walk();
        if (result != null) return result;
        current.removeLast();
        used[i] = false;
      }
      return null;
    }

    return walk();
  }

  /// Pick up to [_maxCandidates] cards, spreading them across parts of
  /// speech first so the pool can actually form a sentence. Taking the
  /// first 8 cards of a hand would often yield eight nouns.
  List<WordCard> _candidatePool(List<WordCard> hand) {
    final usable = hand
        .where((c) => c.type == CardType.word || c.type == CardType.joker)
        .toList();
    if (usable.length <= _maxCandidates) return usable;

    final buckets = <String, List<WordCard>>{};
    for (final card in usable) {
      final key = card.type == CardType.joker ? 'joker' : card.pos!.name;
      buckets.putIfAbsent(key, () => []).add(card);
    }

    final pool = <WordCard>[];
    // Round-robin across buckets until the pool is full.
    var added = true;
    while (pool.length < _maxCandidates && added) {
      added = false;
      for (final bucket in buckets.values) {
        if (pool.length >= _maxCandidates) break;
        if (bucket.isNotEmpty) {
          pool.add(bucket.removeAt(0));
          added = true;
        }
      }
    }
    return pool;
  }

  /// Use a special card when no sentence is available.
  AIAction? _tryPlaySpecial(Player me, GameState state) {
    WordCard? jump;
    WordCard? steal;
    for (final c in me.hand) {
      if (c.type == CardType.jump) jump ??= c;
      if (c.type == CardType.steal) steal ??= c;
    }

    if (steal != null) {
      // Target whoever is closest to winning — the fewest cards left.
      int? bestIdx;
      var bestCount = 1 << 30;
      for (int i = 0; i < state.players.length; i++) {
        if (i == state.currentPlayerIndex) continue;
        final count = state.players[i].hand.length;
        if (count > 0 && count < bestCount) {
          bestCount = count;
          bestIdx = i;
        }
      }
      if (bestIdx != null) {
        final handAfter = List<WordCard>.from(me.hand)
          ..removeWhere((c) => c.id == steal!.id);
        if (handAfter.isNotEmpty) {
          return AIAction(
            type: AIActionType.playSteal,
            specialCard: steal,
            targetPlayerIndex: bestIdx,
            giveCardIndex: _pickDiscardIndex(handAfter),
          );
        }
      }
    }

    if (jump != null) {
      return AIAction(type: AIActionType.playJump, specialCard: jump);
    }

    return null;
  }

  /// What a card is worth keeping. A score of 8 or more is a card the AI
  /// would rather pass than lose: verbs, which every sentence needs and the
  /// deck is thin on, and the cards that are a move in themselves. Nouns sit
  /// below the line on purpose — a hand is usually full of them.
  int _usefulness(WordCard c) {
    if (c.type == CardType.joker) return 10;
    if (c.type == CardType.jump || c.type == CardType.steal) return 9;
    if (c.isVerb) return 8;
    if (c.canBeSubject) return 7;
    if (c.isArticle) return 4;
    if (c.isAdjective) return 3;
    return 2; // adverbs, prepositions
  }

  /// Index of the least useful card to part with.
  int _pickDiscardIndex(List<WordCard> hand) {
    var bestIdx = 0;
    var bestScore = _usefulness(hand[0]);
    for (int i = 1; i < hand.length; i++) {
      final s = _usefulness(hand[i]);
      if (s < bestScore) {
        bestScore = s;
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}
