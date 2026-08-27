import 'package:test/test.dart';
import 'package:dripple_rules/engine/game_engine.dart';
import 'package:dripple_rules/models/game_state.dart';

void main() {
  group('seating', () {
    test('offline still gets you and the bots', () {
      final g = GameNotifier(autoRunAI: false);
      g.startGame(const GameConfig(playerCount: 4));
      expect(g.state.players.map((p) => p.id),
          equals(['human_0', 'ai_1', 'ai_2', 'ai_3']));
      expect(g.state.players.map((p) => p.isAI),
          equals([false, true, true, true]));
    });

    test('online seats the people who actually joined', () {
      final g = GameNotifier(autoRunAI: false);
      g.startGame(
        const GameConfig(playerCount: 3),
        seats: const [
          SeatAssignment(id: 'uid_a', name: 'Mina'),
          SeatAssignment(id: 'uid_b', name: 'Jun'),
          SeatAssignment(id: 'ai_2', name: 'Robot', isAI: true),
        ],
      );
      expect(g.state.players.map((p) => p.id),
          equals(['uid_a', 'uid_b', 'ai_2']));
      expect(g.state.players.map((p) => p.name),
          equals(['Mina', 'Jun', 'Robot']));
      expect(g.state.players.map((p) => p.isAI), equals([false, false, true]));
    });

    test('every seat is dealt a hand', () {
      final g = GameNotifier(autoRunAI: false);
      g.startGame(
        const GameConfig(playerCount: 2, initialHandSize: 7),
        seats: const [
          SeatAssignment(id: 'uid_a', name: 'Mina'),
          SeatAssignment(id: 'uid_b', name: 'Jun'),
        ],
      );
      for (final p in g.state.players) {
        expect(p.hand.length, equals(7), reason: '${p.name} was short-dealt');
      }
    });

    test('a roster that disagrees with the player count is refused', () {
      final g = GameNotifier(autoRunAI: false);
      expect(
        () => g.startGame(
          const GameConfig(playerCount: 4),
          seats: const [SeatAssignment(id: 'uid_a', name: 'Mina')],
        ),
        throwsArgumentError,
      );
    });
  });
}
