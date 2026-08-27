import 'dart:math';

import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_server/src/actions.dart';
import 'package:dripple_server/src/errors.dart';
import 'package:dripple_server/src/game_service.dart';
import 'package:dripple_server/src/room.dart';
import 'package:dripple_server/src/room_store.dart';
import 'package:test/test.dart';

/// A clock the test moves by hand, so turn expiry can be tested without
/// waiting for it.
class _Clock {
  DateTime now = DateTime.utc(2026, 8, 26, 12);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

void main() {
  late InMemoryRoomStore store;
  late GameService service;
  late _Clock clock;

  setUp(() {
    store = InMemoryRoomStore();
    clock = _Clock();
    service = GameService(store: store, random: Random(7), clock: clock.call);
  });

  Future<Room> roomOfTwo() async {
    final room = await service.createRoom(uid: 'mina', name: 'Mina');
    await service.joinRoom(code: room.code, uid: 'jun', name: 'Jun');
    return service.startGame(roomId: room.id, uid: 'mina');
  }

  group('a room', () {
    test('opens with the host seated and the rest free', () async {
      final room = await service.createRoom(uid: 'mina', name: 'Mina');
      expect(room.seats.length, equals(4));
      expect(room.seats.first.uid, equals('mina'));
      expect(room.occupiedSeats, equals(1));
      expect(room.hostUid, equals('mina'));
      expect(room.status, equals(RoomStatus.lobby));
    });

    test('is found by its code however it was typed', () async {
      final room = await service.createRoom(uid: 'mina', name: 'Mina');
      final joined = await service.joinRoom(
        code: room.code.toLowerCase().split('').join('-'),
        uid: 'jun',
        name: 'Jun',
      );
      expect(joined.id, equals(room.id));
      expect(joined.seatOf('jun'), equals(1));
    });

    test('refuses a fifth player', () async {
      final room = await service.createRoom(uid: 'a', name: 'A');
      for (final uid in ['b', 'c', 'd']) {
        await service.joinRoom(code: room.code, uid: uid, name: uid);
      }
      expect(
        () => service.joinRoom(code: room.code, uid: 'e', name: 'E'),
        throwsA(isA<GameError>()
            .having((e) => e.code, 'code', 'room_full')),
      );
    });

    test('seats a returning player where they were, not somewhere new',
        () async {
      final room = await service.createRoom(uid: 'mina', name: 'Mina');
      await service.joinRoom(code: room.code, uid: 'jun', name: 'Jun');
      final again =
          await service.joinRoom(code: room.code, uid: 'jun', name: 'Jun');
      expect(again.seatOf('jun'), equals(1));
      expect(again.occupiedSeats, equals(2));
    });

    test('is unknown by a code nobody issued', () async {
      expect(
        () => service.joinRoom(code: 'ZZZZZZ', uid: 'a', name: 'A'),
        throwsA(isA<GameError>()
            .having((e) => e.code, 'code', 'no_such_room')),
      );
    });
  });

  group('dealing', () {
    test('is the host\'s to do', () async {
      final room = await service.createRoom(uid: 'mina', name: 'Mina');
      await service.joinRoom(code: room.code, uid: 'jun', name: 'Jun');
      expect(
        () => service.startGame(roomId: room.id, uid: 'jun'),
        throwsA(isA<GameError>().having((e) => e.code, 'code', 'not_host')),
      );
    });

    test('needs somebody to play against', () async {
      final room = await service.createRoom(uid: 'mina', name: 'Mina');
      expect(
        () => service.startGame(roomId: room.id, uid: 'mina'),
        throwsA(isA<GameError>()
            .having((e) => e.code, 'code', 'not_enough_players')),
      );
    });

    test('drops the empty seats rather than filling them with bots', () async {
      final room = await roomOfTwo();
      expect(room.seats.length, equals(2));
      expect(room.game!.players.length, equals(2));
      expect(room.game!.players.every((p) => !p.isAI), isTrue);
    });

    test('seats people under their own names and ids', () async {
      final room = await roomOfTwo();
      expect(room.game!.players.map((p) => p.id), equals(['mina', 'jun']));
      expect(room.game!.players.map((p) => p.name), equals(['Mina', 'Jun']));
    });

    test('deals every seat a full hand', () async {
      final room = await roomOfTwo();
      for (final p in room.game!.players) {
        expect(p.hand.length, equals(7));
      }
    });

    test('cannot be done twice', () async {
      final room = await roomOfTwo();
      expect(
        () => service.startGame(roomId: room.id, uid: 'mina'),
        throwsA(isA<GameError>()
            .having((e) => e.code, 'code', 'already_started')),
      );
    });
  });

  group('taking a turn', () {
    test('is refused to the seat that is not in play', () async {
      final room = await roomOfTwo();
      expect(
        () => service.act(
            roomId: room.id, uid: 'jun', action: const DrawAction()),
        throwsA(isA<GameError>()
            .having((e) => e.code, 'code', 'not_your_turn')),
      );
    });

    test('is refused to somebody who is not in the room', () async {
      final room = await roomOfTwo();
      expect(
        () => service.act(
            roomId: room.id, uid: 'stranger', action: const DrawAction()),
        throwsA(isA<GameError>()
            .having((e) => e.code, 'code', 'not_in_room')),
      );
    });

    test('starts with one card and only one', () async {
      final room = await roomOfTwo();
      final after = await service.act(
          roomId: room.id, uid: 'mina', action: const DrawAction());
      expect(after.room.game!.players[0].hand.length, equals(8));
      expect(after.room.game!.turnPhase, equals(TurnPhase.action));

      final again = await service.act(
          roomId: room.id, uid: 'mina', action: const DrawAction());
      expect(again.room.game!.players[0].hand.length, equals(8),
          reason: 'the mandatory draw is spent');
    });

    test('passing keeps the draw and hands the turn on', () async {
      final room = await roomOfTwo();
      await service.act(
          roomId: room.id, uid: 'mina', action: const DrawAction());
      final after = await service.act(
          roomId: room.id, uid: 'mina', action: const PassAction());
      expect(after.room.game!.players[0].hand.length, equals(8));
      expect(after.room.game!.currentPlayerIndex, equals(1));
    });

    test('a card that is not in hand is refused', () async {
      final room = await roomOfTwo();
      await service.act(
          roomId: room.id, uid: 'mina', action: const DrawAction());
      expect(
        () => service.act(
          roomId: room.id,
          uid: 'mina',
          action: const DiscardAction(cardId: 'card_9999'),
        ),
        throwsA(isA<GameError>()
            .having((e) => e.code, 'code', 'no_such_card')),
      );
    });

    test('every action bumps the version', () async {
      final room = await roomOfTwo();
      final before = room.version;
      final after = await service.act(
          roomId: room.id, uid: 'mina', action: const DrawAction());
      expect(after.room.version, greaterThan(before));
    });
  });

  group('a sentence', () {
    test('that does not parse costs nothing and returns the cards', () async {
      final room = await roomOfTwo();
      await service.act(
          roomId: room.id, uid: 'mina', action: const DrawAction());
      final hand = (await store.load(room.id))!.game!.players[0].hand;

      // One card is never a sentence — the parser's floor is two — so this
      // fails whatever the deal was.
      final outcome = await service.act(
        roomId: room.id,
        uid: 'mina',
        action: SubmitAction(cardIds: [hand[0].id]),
      );
      expect(outcome.judgment, isNotNull);
      expect(outcome.judgment!.isCorrect, isFalse);
      expect(outcome.room.game!.players[0].hand.length, equals(hand.length),
          reason: 'a failed submission returns the cards');
      expect(outcome.room.game!.currentPlayerIndex, equals(0),
          reason: 'and does not cost the turn');
    });

    test('naming the same card twice changes nothing at all', () async {
      final room = await roomOfTwo();
      await service.act(
          roomId: room.id, uid: 'mina', action: const DrawAction());
      final before = (await store.load(room.id))!;

      expect(
        () => service.act(
          roomId: room.id,
          uid: 'mina',
          action: SubmitAction(cardIds: [
            before.game!.players[0].hand[0].id,
            before.game!.players[0].hand[0].id,
          ]),
        ),
        throwsA(isA<GameError>()
            .having((e) => e.code, 'code', 'no_such_card')),
      );

      // A rejected action is not a half-applied one: the first card must not
      // be left sitting in the sentence zone.
      final after = (await store.load(room.id))!;
      expect(after.version, equals(before.version));
      expect(after.game!.players[0].hand,
          equals(before.game!.players[0].hand));
      expect(after.game!.players[0].sentenceZone, isEmpty);
    });
  });

  group('leaving', () {
    test('before the deal frees the seat', () async {
      final room = await service.createRoom(uid: 'mina', name: 'Mina');
      await service.joinRoom(code: room.code, uid: 'jun', name: 'Jun');
      final after = await service.leaveRoom(roomId: room.id, uid: 'jun');
      expect(after.occupiedSeats, equals(1));
      expect(after.seats[1].isEmpty, isTrue);
    });

    test('hands the host role on when the host goes', () async {
      final room = await service.createRoom(uid: 'mina', name: 'Mina');
      await service.joinRoom(code: room.code, uid: 'jun', name: 'Jun');
      final after = await service.leaveRoom(roomId: room.id, uid: 'mina');
      expect(after.hostUid, equals('jun'));
    });

    test('mid-game leaves a bot in the chair, holding the same cards',
        () async {
      final room = await roomOfTwo();
      final handBefore = room.game!.players[1].hand;
      final after = await service.leaveRoom(roomId: room.id, uid: 'jun');

      expect(after.seats[1].kind, equals(SeatKind.bot));
      expect(after.seats[1].uid, equals('jun'),
          reason: 'the seat is kept for them to come back to');
      expect(after.game!.players[1].isAI, isTrue);
      expect(after.game!.players[1].hand, equals(handBefore));
      expect(after.status, equals(RoomStatus.playing));
    });

    test('and the game plays itself out from there', () async {
      final room = await roomOfTwo();
      await service.leaveRoom(roomId: room.id, uid: 'jun');
      await service.leaveRoom(roomId: room.id, uid: 'mina');

      var current = await store.load(room.id);
      var guard = 0;
      while (current!.status == RoomStatus.playing && guard++ < 5000) {
        current = await service.tick(room.id);
      }
      expect(current.status, equals(RoomStatus.finished));
      expect(current.game!.winnerIndex, isNotNull);
    });
  });

  group('running out of time', () {
    Future<Room> timedRoom() async {
      final room = await service.createRoom(uid: 'mina', name: 'Mina');
      await service.joinRoom(code: room.code, uid: 'jun', name: 'Jun');
      return service.startGame(
          roomId: room.id, uid: 'mina', turnTimerSeconds: 30);
    }

    test('sets a deadline only while a person is on the clock', () async {
      final room = await timedRoom();
      expect(room.turnDeadlineMs, isNotNull);
    });

    test('costs the turn, and the next seat gets a fresh clock', () async {
      final room = await timedRoom();
      expect(room.game!.currentPlayerIndex, equals(0));

      clock.advance(const Duration(seconds: 31));
      final after = await service.tick(room.id);

      expect(after.game!.currentPlayerIndex, equals(1),
          reason: 'the turn was forfeited');
      expect(after.turnDeadlineMs,
          greaterThan(clock.now.millisecondsSinceEpoch));
    });

    test('is not charged while there is still time', () async {
      final room = await timedRoom();
      clock.advance(const Duration(seconds: 29));
      final after = await service.tick(room.id);
      expect(after.game!.currentPlayerIndex, equals(0));
    });

    test('no timer means no deadline', () async {
      final room = await roomOfTwo();
      expect(room.turnDeadlineMs, isNull);
      clock.advance(const Duration(hours: 3));
      final after = await service.tick(room.id);
      expect(after.game!.currentPlayerIndex, equals(0));
    });
  });

  group('two people acting at once', () {
    test('the loser is told to read the room again, not silently erased',
        () async {
      final room = await roomOfTwo();

      // A store that lets the first write through and then pretends every
      // later one raced — the shape of two devices acting on the same tick.
      final blocked = _AlwaysStaleStore(store);
      final racing = GameService(store: blocked, random: Random(7), clock: clock.call);

      expect(
        () => racing.act(
            roomId: room.id, uid: 'mina', action: const DrawAction()),
        throwsA(isA<GameError>().having((e) => e.code, 'code', 'conflict')),
      );
    });
  });
}

/// A store whose writes always lose the race.
class _AlwaysStaleStore implements RoomStore {
  final RoomStore _inner;
  _AlwaysStaleStore(this._inner);

  @override
  Future<Room?> load(String roomId) => _inner.load(roomId);

  @override
  Future<bool> create(Room room) => _inner.create(room);

  @override
  Future<bool> save(Room room, {required int expectedVersion}) async => false;

  @override
  Future<String?> roomIdForCode(String code) => _inner.roomIdForCode(code);

  @override
  Future<void> delete(String roomId) => _inner.delete(roomId);
}
