import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';

WordCard _w(String id) => WordCard(id: id, word: id, pos: PartOfSpeech.noun);

void main() {
  group('GameConfig defaults', () {
    test('4 players, 7 cards, timer off', () {
      const c = GameConfig();
      expect(c.playerCount, 4);
      expect(c.initialHandSize, 7);
      expect(c.turnTimerSeconds, 0);
    });
  });

  group('GamePhase', () {
    test('has no roundEnd phase', () {
      expect(GamePhase.values.length, 3);
      expect(GamePhase.values.map((e) => e.name).contains('roundEnd'), false);
    });
  });

  group('GameState', () {
    test('discardTop returns the last discarded card', () {
      final s = GameState(discardPile: [_w('a'), _w('b')]);
      expect(s.discardTop?.id, 'b');
    });

    test('discardTop is null when the pile is empty', () {
      expect(const GameState().discardTop, null);
    });

    test('ranking sorts by fewest cards remaining', () {
      final s = GameState(players: [
        Player(id: 'a', name: 'A', hand: [_w('1'), _w('2')]),
        const Player(id: 'b', name: 'B', hand: []),
        Player(id: 'c', name: 'C', hand: [_w('3')]),
      ]);
      expect(s.ranking.map((p) => p.id).toList(), ['b', 'c', 'a']);
    });

    test('clearDrawnFromDiscard resets the marker to null', () {
      final s = const GameState().copyWith(drawnFromDiscardCardId: 'x');
      expect(s.drawnFromDiscardCardId, 'x');
      expect(s.clearDrawnFromDiscard().drawnFromDiscardCardId, null);
    });

    test('turnPhase defaults to draw', () {
      expect(const GameState().turnPhase, TurnPhase.draw);
    });
  });
}
