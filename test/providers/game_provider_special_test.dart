import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/providers/game_provider.dart';

WordCard _noun(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.noun, person: 3, number: 'plural');

GameNotifier _board() {
  final n = GameNotifier(random: Random(7), autoRunAI: false);
  n.debugSetState(GameState(
    phase: GamePhase.playing,
    turnPhase: TurnPhase.action,
    players: [
      Player(id: 'human_0', name: 'You', hand: [
        WordCard.special('j1', CardType.jump),
        WordCard.special('s1', CardType.steal),
        _noun('c1', 'cats'),
      ]),
      Player(id: 'ai_1', name: 'AI 1', isAI: true, hand: [_noun('a1', 'dogs')]),
      Player(id: 'ai_2', name: 'AI 2', isAI: true, hand: [_noun('b1', 'birds')]),
      Player(id: 'ai_3', name: 'AI 3', isAI: true, hand: [_noun('e1', 'fish')]),
    ],
    deck: [_noun('d1', 'apples')],
    discardPile: [_noun('x1', 'water')],
  ));
  return n;
}

void main() {
  group('JUMP', () {
    test('skips the next player', () {
      final n = _board();
      expect(n.playJump(0), true);
      expect(n.state.currentPlayerIndex, 2, reason: 'player 1 is skipped');
      expect(n.state.players[0].hand.any((c) => c.id == 'j1'), false);
      expect(n.state.turnPhase, TurnPhase.draw);
    });

    test('is rejected during the draw phase', () {
      final n = _board();
      n.debugSetState(n.state.copyWith(turnPhase: TurnPhase.draw));
      expect(n.playJump(0), false);
    });

    test('is rejected when the card is not a JUMP', () {
      final n = _board();
      expect(n.playJump(2), false);
    });
  });

  group('STEAL', () {
    test('exchanges one card with the target and preserves hand sizes', () {
      final n = _board();
      expect(n.playSteal(1, targetPlayerIndex: 2, giveCardIndex: 1), true);

      final me = n.state.players[0];
      final target = n.state.players[2];

      expect(me.hand.length, 2, reason: 'STEAL spent, one given, one taken');
      expect(target.hand.length, 1, reason: 'one taken, one received');
      expect(me.hand.any((c) => c.id == 'b1'), true);
      expect(target.hand.any((c) => c.id == 'c1'), true);
      expect(n.state.currentPlayerIndex, 1);
    });

    test('is rejected when targeting yourself', () {
      final n = _board();
      expect(n.playSteal(1, targetPlayerIndex: 0, giveCardIndex: 1), false);
    });

    test('is rejected when the target has no cards', () {
      final n = _board();
      final players = List<Player>.from(n.state.players);
      players[2] = players[2].copyWith(hand: const []);
      n.debugSetState(n.state.copyWith(players: players));

      expect(n.playSteal(1, targetPlayerIndex: 2, giveCardIndex: 1), false);
    });
  });
}
