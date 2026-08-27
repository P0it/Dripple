import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/providers/game_provider.dart';

WordCard _noun(String id) =>
    WordCard(id: id, word: id, pos: PartOfSpeech.noun, number: 'plural');

GameNotifier _board() {
  final n = GameNotifier(random: Random(1), autoRunAI: false);
  n.debugSetState(GameState(
    phase: GamePhase.playing,
    turnPhase: TurnPhase.action,
    players: [
      Player(
        id: 'human_0',
        name: 'You',
        hand: [_noun('a'), _noun('b'), _noun('c')],
      ),
      const Player(id: 'ai_1', name: 'AI 1', isAI: true),
    ],
  ));
  return n;
}

void main() {
  group('reorderHand', () {
    test('slides a card to a later place on the rail', () {
      final n = _board();
      n.reorderHand(0, 2);
      expect(n.state.players[0].hand.map((c) => c.id).toList(),
          ['b', 'c', 'a']);
    });

    test('slides a card to an earlier place', () {
      final n = _board();
      n.reorderHand(2, 0);
      expect(n.state.players[0].hand.map((c) => c.id).toList(),
          ['c', 'a', 'b']);
    });

    test('a card dropped where it already was changes nothing', () {
      final n = _board();
      final before = n.state;
      n.reorderHand(1, 1);
      expect(identical(n.state, before), isTrue);
    });

    test('an index off the end is ignored rather than throwing', () {
      final n = _board();
      n.reorderHand(0, 9);
      n.reorderHand(-1, 0);
      expect(n.state.players[0].hand.map((c) => c.id).toList(),
          ['a', 'b', 'c']);
    });

    test('reordering the hand never touches the sentence', () {
      final n = _board();
      n.placeCard(0);
      n.reorderHand(0, 1);
      expect(n.state.players[0].sentenceZone.single.id, 'a');
      expect(n.state.players[0].hand.map((c) => c.id).toList(), ['c', 'b']);
    });
  });
}
