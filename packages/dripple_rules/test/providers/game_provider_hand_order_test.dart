import 'dart:math';
import 'package:test/test.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/player.dart';
import 'package:dripple_rules/models/word_card.dart';
import 'package:dripple_rules/engine/game_engine.dart';

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
    test('sorts my hand while somebody else is thinking', () {
      // Arranging the hand is how a player works out a sentence, and most of
      // the time they are doing it is time spent waiting for a turn. It moved
      // `currentPlayer`'s cards before, so off-turn it reached into an
      // opponent's hand and left the player's own fan untouched — the card
      // slid and then snapped back.
      final n = _board();
      n.debugSetState(n.state.copyWith(currentPlayerIndex: 1));

      n.reorderHand(0, 2);

      expect(n.state.players[0].hand.map((c) => c.id).toList(),
          ['b', 'c', 'a'], reason: 'my hand is the one that moved');
      expect(n.state.players[1].hand, isEmpty,
          reason: "nobody reaches into anybody else's hand");
    });

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
