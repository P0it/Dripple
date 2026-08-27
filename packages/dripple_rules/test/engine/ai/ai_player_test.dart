import 'dart:math';
import 'package:test/test.dart';
import 'package:dripple_rules/engine/ai/ai_player.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/player.dart';
import 'package:dripple_rules/models/word_card.dart';

WordCard _pron(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.pronoun, person: 1, number: 'singular');
WordCard _verb(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.verb, person: 1, number: 'plural');
WordCard _noun(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.noun, person: 3, number: 'plural');
WordCard _art(String id) =>
    WordCard(id: id, word: 'the', pos: PartOfSpeech.article);
WordCard _prep(String id) =>
    WordCard(id: id, word: 'in', pos: PartOfSpeech.preposition);

void main() {
  group('findSentence', () {
    test('finds a sentence in a hand that contains one', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final found = ai.findSentence([
        _noun('n1', 'cats'),
        _pron('p1', 'I'),
        _verb('v1', 'like'),
      ]);
      expect(found, isNotNull);
      expect(found!.length, greaterThanOrEqualTo(2));
      expect(found.map((c) => c.word).join(' '), 'I like cats');
    });

    test('hard difficulty prefers the longest sentence available', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final found = ai.findSentence([
        _pron('p1', 'I'),
        _verb('v1', 'like'),
        _art('a1'),
        _noun('n1', 'cats'),
        _prep('r1'),
        _art('a2'),
        _noun('n2', 'boxes'),
      ]);
      expect(found, isNotNull);
      expect(found!.length, greaterThan(3));
    });

    test('easy difficulty caps sentence length at 3', () {
      final ai = AIPlayer(difficulty: AIDifficulty.easy, random: Random(1));
      final found = ai.findSentence([
        _pron('p1', 'I'),
        _verb('v1', 'like'),
        _art('a1'),
        _noun('n1', 'cats'),
        _prep('r1'),
        _art('a2'),
        _noun('n2', 'boxes'),
      ]);
      expect(found, isNotNull);
      expect(found!.length, lessThanOrEqualTo(3));
    });

    test('returns null when no sentence is possible', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      expect(ai.findSentence([_art('a1'), _art('a2'), _prep('r1')]), null);
    });

    test('returns cards that are the same instances as the hand', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_pron('p1', 'I'), _verb('v1', 'like'), _noun('n1', 'cats')];
      final found = ai.findSentence(hand)!;
      for (final c in found) {
        expect(hand.any((h) => identical(h, c)), true);
      }
    });
  });

  group('decideAction', () {
    /// The deck matters: the AI will not hold cards back once the deck is
    /// nearly out, so a board with no deck left never passes.
    GameState state(List<WordCard> aiHand, {int deckCount = 40}) => GameState(
          phase: GamePhase.playing,
          turnPhase: TurnPhase.action,
          currentPlayerIndex: 1,
          players: [
            Player(id: 'human_0', name: 'You', hand: [_noun('h1', 'cats')]),
            Player(id: 'ai_1', name: 'AI 1', isAI: true, hand: aiHand),
          ],
          deck: [for (var i = 0; i < deckCount; i++) _noun('d$i', 'cats')],
        );

    test('submits a sentence when one exists', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_pron('p1', 'I'), _verb('v1', 'like'), _noun('n1', 'cats')];
      final s = state(hand);
      final action = ai.decideAction(s.players[1], s);
      expect(action.type, AIActionType.submitSentence);
      expect(action.cards!.length, 3);
    });

    test('passes when every card left is one it needs', () {
      // Three verbs and no subject: no sentence, and nothing here the AI can
      // afford to lose. Being made to discard would cost it a verb, which the
      // deck is thin on.
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final s = state([_verb('v1', 'like'), _verb('v2', 'run'),
          _verb('v3', 'read')]);
      expect(ai.decideAction(s.players[1], s).type, AIActionType.pass);
    });

    test('discards as soon as one card is worth less than the turn', () {
      // Same dead hand plus an article. Discarding beats passing whenever
      // there is something to lose: the card goes to the pile and comes back
      // to everyone on the next recycle, where a passed card never does.
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_verb('v1', 'like'), _verb('v2', 'run'), _art('a1')];
      final s = state(hand);
      final action = ai.decideAction(s.players[1], s);
      expect(action.type, AIActionType.discard);
      expect(hand[action.discardIndex!].id, 'a1');
    });

    test('the weakest opponent is the one that holds on longest', () {
      // Holding cards is the weaker line, so easy holds this hand and hard
      // has already started shedding.
      final hand = [for (var i = 0; i < 5; i++) _verb('v$i', 'run')];
      final s = state(hand);
      expect(
        AIPlayer(difficulty: AIDifficulty.easy, random: Random(7))
            .decideAction(s.players[1], s)
            .type,
        AIActionType.pass,
      );
      expect(
        AIPlayer(difficulty: AIDifficulty.hard, random: Random(7))
            .decideAction(s.players[1], s)
            .type,
        AIActionType.discard,
      );
    });

    test('stops holding cards back once the deck is nearly out', () {
      // A passed card never returns to the deck on a recycle, so late in the
      // game holding one starves the board into the anti-stalling rule.
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_verb('v1', 'like'), _verb('v2', 'run')];
      final rich = state(hand);
      final poor = state(hand, deckCount: 4);
      expect(ai.decideAction(rich.players[1], rich).type, AIActionType.pass);
      expect(ai.decideAction(poor.players[1], poor).type, AIActionType.discard);
    });

    test('a special card still beats passing', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final s = state([_verb('v1', 'run'), WordCard.special('j1', CardType.jump)]);
      expect(ai.decideAction(s.players[1], s).type, AIActionType.playJump);
    });

    test('plays JUMP when holding one and no sentence is possible', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_art('a1'), WordCard.special('j1', CardType.jump)];
      final s = state(hand);
      final action = ai.decideAction(s.players[1], s);
      expect(action.type, AIActionType.playJump);
      expect(action.specialCard!.id, 'j1');
    });
  });
}
