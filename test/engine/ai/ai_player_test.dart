import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/engine/ai/ai_player.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';

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
    GameState state(List<WordCard> aiHand) => GameState(
          phase: GamePhase.playing,
          turnPhase: TurnPhase.action,
          currentPlayerIndex: 1,
          players: [
            Player(id: 'human_0', name: 'You', hand: [_noun('h1', 'cats')]),
            Player(id: 'ai_1', name: 'AI 1', isAI: true, hand: aiHand),
          ],
        );

    test('submits a sentence when one exists', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_pron('p1', 'I'), _verb('v1', 'like'), _noun('n1', 'cats')];
      final s = state(hand);
      final action = ai.decideAction(s.players[1], s);
      expect(action.type, AIActionType.submitSentence);
      expect(action.cards!.length, 3);
    });

    test('discards when no sentence is possible', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_art('a1'), _art('a2'), _prep('r1')];
      final s = state(hand);
      final action = ai.decideAction(s.players[1], s);
      expect(action.type, AIActionType.discard);
      expect(action.discardIndex, inInclusiveRange(0, hand.length - 1));
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
