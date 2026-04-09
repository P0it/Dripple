import 'dart:math';
import '../../models/word_card.dart';
import '../../models/player.dart';
import '../../models/game_state.dart';
import '../grammar/grammar_engine.dart';

enum AIActionType { buildAndSubmit, drawCard, playSpecial }

class AIAction {
  final AIActionType type;
  final List<WordCard>? cardsToPlace;
  final WordCard? specialCard;
  final int? targetPlayer;

  const AIAction({
    required this.type,
    this.cardsToPlace,
    this.specialCard,
    this.targetPlayer,
  });

  factory AIAction.submit(List<WordCard> cards) =>
      AIAction(type: AIActionType.buildAndSubmit, cardsToPlace: cards);

  factory AIAction.draw() =>
      const AIAction(type: AIActionType.drawCard);

  factory AIAction.special(WordCard card, {int? target}) =>
      AIAction(
        type: AIActionType.playSpecial,
        specialCard: card,
        targetPlayer: target,
      );
}

/// Rule-based AI player that selects cards to form valid sentences.
class AIPlayer {
  final GrammarEngine _engine;
  final Random _random;

  AIPlayer({GrammarEngine? engine, Random? random})
      : _engine = engine ?? GrammarEngine(),
        _random = random ?? Random();

  /// Decide what action to take on the AI's turn
  AIAction decideTurn(Player player, GameState gameState) {
    // Occasionally make a mistake (20% chance of suboptimal play)
    if (_random.nextDouble() < 0.2) {
      return AIAction.draw();
    }

    // Try to play a special card against the leader
    final specialAction = _tryPlaySpecial(player, gameState);
    if (specialAction != null && _random.nextDouble() < 0.3) {
      return specialAction;
    }

    // Try to find the longest valid sentence from hand
    final sentence = _findBestSentence(player.hand);
    if (sentence != null && sentence.length >= 2) {
      return AIAction.submit(sentence);
    }

    // If existing sentence zone + hand cards can make a valid sentence
    if (player.sentenceZone.isNotEmpty) {
      final combined = [...player.sentenceZone];
      final additionalCards = _findCompletionCards(combined, player.hand);
      if (additionalCards != null) {
        return AIAction.submit([...combined, ...additionalCards]);
      }
    }

    // Default: draw a card
    return AIAction.draw();
  }

  /// Try to find the longest valid sentence from available cards
  List<WordCard>? _findBestSentence(List<WordCard> hand) {
    final wordCards = hand.where((c) => c.type == CardType.word).toList();
    if (wordCards.length < 2) return null;

    List<WordCard>? best;

    // Try common sentence patterns
    // Pattern: Subject + Verb
    for (final subj in wordCards.where((c) => c.canBeSubject)) {
      for (final verb in wordCards.where((c) => c.isVerb)) {
        final sentence = [subj, verb];
        if (_isValid(sentence)) {
          if (best == null || sentence.length > best.length) {
            best = sentence;
          }

          // Try extending: Subject + Verb + Object
          for (final obj in wordCards.where(
              (c) => c.isNoun && c.id != subj.id)) {
            final extended = [subj, verb, obj];
            if (_isValid(extended)) {
              if (best == null || extended.length > best.length) {
                best = extended;
              }
            }
          }

          // Try extending: Subject + Verb + Adjective (SVC)
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

    // Try: Article + Noun(subject) + Verb patterns
    for (final art in wordCards.where((c) => c.isArticle)) {
      for (final noun in wordCards.where((c) => c.isNoun)) {
        for (final verb in wordCards.where((c) => c.isVerb)) {
          final sentence = [art, noun, verb];
          if (_isValid(sentence)) {
            if (best == null || sentence.length > best.length) {
              best = sentence;
            }

            // Try Art + Noun + Verb + Object
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
            return AIAction.special(card, target: leaderId);
          }
        case CardType.undo:
          if (gameState.players[leaderId].sentenceZone.isNotEmpty) {
            return AIAction.special(card, target: leaderId);
          }
        case CardType.skip:
          return AIAction.special(card);
        default:
          break;
      }
    }

    return null;
  }

  bool _isValid(List<WordCard> sentence) {
    return _engine.validate(sentence).isValid;
  }
}
