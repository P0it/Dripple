import 'dart:math';
import '../../models/word_card.dart';
import '../../models/player.dart';
import '../../models/game_state.dart';
import '../grammar/grammar_engine.dart';

/// How hard the AI plays.
///
/// - [easy]   – sentences up to 3 cards, discards at random 30 % of the time.
/// - [medium] – sentences up to 5 cards, discards at random 10 % of the time.
/// - [hard]   – no practical length cap, always plays the longest sentence
///              it finds.
enum AIDifficulty { easy, medium, hard }

enum AIActionType { submitSentence, discard, playJump, playSteal }

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

    return AIAction(
      type: AIActionType.discard,
      discardIndex: _pickDiscardIndex(me.hand),
    );
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

  /// Index of the least useful card to part with.
  int _pickDiscardIndex(List<WordCard> hand) {
    int usefulness(WordCard c) {
      if (c.type == CardType.joker) return 10;
      if (c.type == CardType.jump || c.type == CardType.steal) return 9;
      if (c.isVerb) return 8;
      if (c.canBeSubject) return 7;
      if (c.isArticle) return 4;
      if (c.isAdjective) return 3;
      return 2; // adverbs, prepositions
    }

    var bestIdx = 0;
    var bestScore = usefulness(hand[0]);
    for (int i = 1; i < hand.length; i++) {
      final s = usefulness(hand[i]);
      if (s < bestScore) {
        bestScore = s;
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}
