import 'package:test/test.dart';
import 'package:dripple_rules/engine/game_engine.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/player.dart';
import 'package:dripple_rules/wire/wire.dart';

/// Which seat belongs to this device used to be inferred from `isAI` — the
/// one player that was not a bot was you. Online that stops being true: three
/// of the four seats are people, and only one of them is yours.
void main() {
  const table = [
    Player(id: 'a', name: 'A'),
    Player(id: 'b', name: 'B'),
    Player(id: 'c', name: 'C'),
  ];

  group('my seat', () {
    test('is the first one unless told otherwise', () {
      const state = GameState(players: table);
      expect(state.mySeatIndex, equals(0));
      expect(state.me.id, equals('a'));
    });

    test('is whichever seat was given', () {
      const state = GameState(players: table, mySeatIndex: 2);
      expect(state.me.id, equals('c'));
      expect(state.opponents.map((p) => p.id), equals(['a', 'b']));
    });

    test('names my turn without asking who is a bot', () {
      const mine = GameState(
        phase: GamePhase.playing,
        players: table,
        mySeatIndex: 1,
        currentPlayerIndex: 1,
      );
      expect(mine.isMyTurn, isTrue);

      const theirs = GameState(
        phase: GamePhase.playing,
        players: table,
        mySeatIndex: 1,
        currentPlayerIndex: 2,
      );
      expect(theirs.isMyTurn, isFalse);
    });

    test('is nobody\'s turn once the game is over', () {
      const over = GameState(
        phase: GamePhase.gameEnd,
        players: table,
        mySeatIndex: 0,
        currentPlayerIndex: 0,
      );
      expect(over.isMyTurn, isFalse);
    });

    test('survives an empty table without throwing', () {
      const empty = GameState();
      expect(empty.isMyTurn, isFalse);
      expect(empty.opponents, isEmpty);
      expect(empty.me.id, isEmpty);
    });

    test('an offline game still puts you in the first chair', () {
      final g = GameNotifier(autoRunAI: false);
      g.startGame(const GameConfig(playerCount: 4));
      expect(g.snapshot.mySeatIndex, equals(0));
      expect(g.snapshot.isMyTurn, isTrue);
      expect(g.snapshot.opponents.every((p) => p.isAI), isTrue);
    });

    test('a rebuilt view sits in the seat it was rebuilt for', () {
      final g = GameNotifier(autoRunAI: false);
      g.startGame(const GameConfig(playerCount: 4));
      final view = PublicView.decode(
        PublicView.encode(g.snapshot),
        viewerSeat: 2,
        myHandIds: g.snapshot.players[2].hand.map((c) => c.id).toList(),
      );
      expect(view.mySeatIndex, equals(2));
      expect(view.me.hand, equals(g.snapshot.players[2].hand));
    });
  });
}
