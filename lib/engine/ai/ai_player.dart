import 'dart:math';
import '../../models/word_card.dart';
import '../../models/player.dart';
import '../../models/game_state.dart';
import '../grammar/grammar_engine.dart';

/// Controls how strategically the AI player behaves.
///
/// - [easy]   – 40 % random draw, only tries 2-card SV patterns.
/// - [medium] – 20 % random draw, tries up to 3-card sentences (default).
/// - [hard]   – 5 % random draw, tries all patterns including 4-card
///              Art+Noun+Verb+Object, and uses special cards more aggressively.
enum AIDifficulty { easy, medium, hard }

enum AIActionType { buildAndSubmit, drawCard, playSpecial }

class AIAction {
  final AIActionType type;
  final List<WordCard>? cardsToPlace;
  final WordCard? specialCard;
  final int? targetPlayer;
  /// For STEAL: index of the card to give to the target (in hand after
  /// removing the STEAL card).
  final int? giveCardIndex;

  const AIAction({
    required this.type,
    this.cardsToPlace,
    this.specialCard,
    this.targetPlayer,
    this.giveCardIndex,
  });

  factory AIAction.submit(List<WordCard> cards) =>
      AIAction(type: AIActionType.buildAndSubmit, cardsToPlace: cards);

  factory AIAction.draw() =>
      const AIAction(type: AIActionType.drawCard);

  factory AIAction.special(WordCard card, {int? target, int? giveIndex}) =>
      AIAction(
        type: AIActionType.playSpecial,
        specialCard: card,
        targetPlayer: target,
        giveCardIndex: giveIndex,
      );
}

/// Rule-based AI player that selects cards to form valid sentences.
class AIPlayer {
  final GrammarEngine _engine;
  final Random _random;
  final AIDifficulty difficulty;

  AIPlayer({
    GrammarEngine? engine,
    Random? random,
    this.difficulty = AIDifficulty.medium,
  })  : _engine = engine ?? GrammarEngine(),
        _random = random ?? Random();

  /// Decide what action to take on the AI's turn.
  ///
  /// Behaviour varies by [difficulty]:
  /// - Easy:   40 % random draw; only attempts 2-card Subject+Verb patterns.
  /// - Medium: 20 % random draw; attempts up to 3-card patterns (default).
  /// - Hard:   5 % random draw; attempts all patterns including 4-card
  ///           Art+Noun+Verb+Object; uses special cards 60 % of the time.
  AIAction decideTurn(Player player, GameState gameState) {
    // Difficulty-scaled random draw probability
    final drawChance = switch (difficulty) {
      AIDifficulty.easy => 0.40,
      AIDifficulty.medium => 0.20,
      AIDifficulty.hard => 0.05,
    };

    if (_random.nextDouble() < drawChance) {
      return AIAction.draw();
    }

    // Special-card aggressiveness: hard AI uses specials more often
    final specialChance = switch (difficulty) {
      AIDifficulty.easy => 0.10,
      AIDifficulty.medium => 0.30,
      AIDifficulty.hard => 0.60,
    };

    final specialAction = _tryPlaySpecial(player, gameState);
    if (specialAction != null && _random.nextDouble() < specialChance) {
      return specialAction;
    }

    final minLen = gameState.config.minSentenceLength;

    // Try to find the best valid sentence from hand
    final sentence = _findBestSentence(player.hand, minLen);
    if (sentence != null && sentence.length >= minLen) {
      return AIAction.submit(sentence);
    }

    // If existing sentence zone + hand cards can extend to a valid sentence
    if (player.sentenceZone.isNotEmpty) {
      final totalNeeded = minLen - player.sentenceZone.length;
      if (totalNeeded > 0) {
        final combined = [...player.sentenceZone];
        final additionalCards = _findCompletionCards(combined, player.hand);
        if (additionalCards != null &&
            (player.sentenceZone.length + additionalCards.length) >= minLen) {
          return AIAction.submit(additionalCards);
        }
      }
    }

    return AIAction.draw();
  }

  /// Try to find the longest valid sentence from available cards.
  ///
  /// The maximum sentence complexity explored scales with [difficulty]:
  /// - Easy:   Subject + Verb only (2 cards).
  /// - Medium: Subject + Verb + Object/Adjective, Art + Noun + Verb (3 cards).
  /// - Hard:   All of the above plus Art + Noun + Verb + Object (4 cards).
  List<WordCard>? _findBestSentence(List<WordCard> hand, [int minLen = 2]) {
    final wordCards = hand.where((c) => c.type == CardType.word).toList();
    if (wordCards.length < 2) return null;

    List<WordCard>? best;

    // Pattern: Subject + Verb (all difficulty levels)
    for (final subj in wordCards.where((c) => c.canBeSubject)) {
      for (final verb in wordCards.where((c) => c.isVerb)) {
        final sentence = [subj, verb];
        if (_isValid(sentence)) {
          if (best == null || sentence.length > best.length) {
            best = sentence;
          }

          // Medium and Hard: try 3-card extensions
          if (difficulty != AIDifficulty.easy) {
            // Subject + Verb + Object
            for (final obj in wordCards.where(
                (c) => c.isNoun && c.id != subj.id)) {
              final extended = [subj, verb, obj];
              if (_isValid(extended)) {
                if (best == null || extended.length > best.length) {
                  best = extended;
                }
              }
            }

            // Subject + Verb + Adjective (SVC)
            for (final adj in wordCards.where((c) => c.isAdjective)) {
              final extended = [subj, verb, adj];
              if (_isValid(extended)) {
                if (best == null || extended.length > best.length) {
                  best = extended;
                }
              }
            }
          }
        }
      }
    }

    // Medium and Hard: Article + Noun + Verb patterns
    if (difficulty != AIDifficulty.easy) {
      for (final art in wordCards.where((c) => c.isArticle)) {
        for (final noun in wordCards.where((c) => c.isNoun)) {
          for (final verb in wordCards.where((c) => c.isVerb)) {
            final sentence = [art, noun, verb];
            if (_isValid(sentence)) {
              if (best == null || sentence.length > best.length) {
                best = sentence;
              }

              // Hard only: Art + Noun + Verb + Object (4 cards)
              if (difficulty == AIDifficulty.hard) {
                for (final obj in wordCards.where(
                    (c) => c.isNoun && c.id != noun.id)) {
                  final extended = [art, noun, verb, obj];
                  if (_isValid(extended)) {
                    if (best == null || extended.length > best.length) {
                      best = extended;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return best;
  }

  /// Find additional cards from hand that would complete a sentence
  List<WordCard>? _findCompletionCards(
      List<WordCard> current, List<WordCard> hand) {
    final wordCards = hand.where((c) => c.type == CardType.word).toList();

    // Try adding one card at a time
    for (final card in wordCards) {
      final attempt = [...current, card];
      if (_isValid(attempt)) return [card];
    }

    return null;
  }

  /// Try to play a special card strategically
  AIAction? _tryPlaySpecial(Player player, GameState gameState) {
    final specials = player.hand.where((c) => c.isSpecial).toList();
    if (specials.isEmpty) return null;

    // Find the leading player (not self)
    final others = gameState.players
        .asMap()
        .entries
        .where((e) => e.value.id != player.id)
        .toList();
    if (others.isEmpty) return null;

    others.sort((a, b) => b.value.score.compareTo(a.value.score));
    final leaderId = others.first.key;

    for (final card in specials) {
      switch (card.type) {
        case CardType.steal:
          if (gameState.players[leaderId].hand.isNotEmpty) {
            // Pick the least useful card to give away.
            // Hand after removing the STEAL card:
            final handAfterSteal = List<WordCard>.from(player.hand)
              ..removeWhere((c) => c.id == card.id);
            if (handAfterSteal.isNotEmpty) {
              final giveIdx = _pickLeastUsefulIndex(handAfterSteal);
              return AIAction.special(card, target: leaderId, giveIndex: giveIdx);
            }
          }
        case CardType.jump:
          return AIAction.special(card);
        default:
          break;
      }
    }

    return null;
  }

  /// Pick the index of the least useful card to give away in a STEAL exchange.
  /// Prefers giving away duplicates, then adverbs/adjectives, then articles.
  int _pickLeastUsefulIndex(List<WordCard> hand) {
    // Score each card: lower = less useful = better to give away
    int usefulness(WordCard c) {
      if (c.isSpecial) return 10; // keep special cards
      if (c.isVerb) return 8;
      if (c.canBeSubject) return 7; // pronouns, nouns
      if (c.isArticle) return 4;
      if (c.isAdjective) return 3;
      return 2; // adverbs, prepositions, conjunctions
    }

    int bestIdx = 0;
    int bestScore = usefulness(hand[0]);
    for (int i = 1; i < hand.length; i++) {
      final s = usefulness(hand[i]);
      if (s < bestScore) {
        bestScore = s;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  bool _isValid(List<WordCard> sentence) {
    return _engine.validate(sentence).isValid;
  }
}
