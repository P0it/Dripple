import 'package:test/test.dart';
import 'package:dripple_rules/engine/game_engine.dart';
import 'package:dripple_rules/models/game_state.dart';

/// The online server drives a game one step at a time from stored state, so
/// it needs two things a local game never did: a way to pick a game back up,
/// and a way to run a single bot turn rather than every consecutive one.
void main() {
  group('restore', () {
    test('picks a game back up exactly where it was', () {
      final a = GameNotifier(autoRunAI: false);
      a.startGame(const GameConfig(playerCount: 3));
      a.drawFromDeck();

      final b = GameNotifier(autoRunAI: false);
      b.restore(a.state);

      expect(b.state, equals(a.state));
      expect(b.state.turnPhase, equals(TurnPhase.action));
    });

    test('a restored game keeps playing by the same rules', () {
      final a = GameNotifier(autoRunAI: false);
      a.startGame(const GameConfig(playerCount: 2));

      final b = GameNotifier(autoRunAI: false)..restore(a.state);
      b.drawFromDeck();

      expect(b.state.currentPlayer.hand.length,
          equals(a.state.currentPlayer.hand.length + 1));
      // The mandatory draw is spent, so a second one is refused.
      final deckBefore = b.state.deck.length;
      b.drawFromDeck();
      expect(b.state.deck.length, equals(deckBefore));
    });
  });

  group('runOneAITurn', () {
    test('advances exactly one seat', () {
      final g = GameNotifier(autoRunAI: false);
      g.startGame(
        const GameConfig(playerCount: 4),
        seats: const [
          SeatAssignment(id: 'bot_0', name: 'A', isAI: true),
          SeatAssignment(id: 'bot_1', name: 'B', isAI: true),
          SeatAssignment(id: 'bot_2', name: 'C', isAI: true),
          SeatAssignment(id: 'bot_3', name: 'D', isAI: true),
        ],
      );
      expect(g.state.currentPlayerIndex, equals(0));

      expect(g.runOneAITurn(), isTrue);
      expect(g.state.currentPlayerIndex, isNot(equals(0)),
          reason: 'one bot turn should hand the turn on');
    });

    test('declines when the seat in play is a person', () {
      final g = GameNotifier(autoRunAI: false);
      g.startGame(const GameConfig(playerCount: 4));
      expect(g.state.currentPlayer.isAI, isFalse);
      expect(g.runOneAITurn(), isFalse);
      expect(g.state.currentPlayerIndex, equals(0));
    });

    test('declines once the game is over', () {
      final g = GameNotifier(autoRunAI: false);
      g.startGame(const GameConfig(playerCount: 2));
      g.restore(g.state.copyWith(phase: GamePhase.gameEnd));
      expect(g.runOneAITurn(), isFalse);
    });

    test('called repeatedly, it plays the game out', () {
      final g = GameNotifier(autoRunAI: false);
      g.startGame(
        const GameConfig(playerCount: 4),
        seats: const [
          SeatAssignment(id: 'bot_0', name: 'A', isAI: true),
          SeatAssignment(id: 'bot_1', name: 'B', isAI: true),
          SeatAssignment(id: 'bot_2', name: 'C', isAI: true),
          SeatAssignment(id: 'bot_3', name: 'D', isAI: true),
        ],
      );
      var turns = 0;
      while (g.state.phase == GamePhase.playing && turns < 5000) {
        expect(g.runOneAITurn(), isTrue);
        turns++;
      }
      expect(g.state.phase, equals(GamePhase.gameEnd));
    });
  });
}
