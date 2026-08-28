import 'dart:io';
import 'dart:math';

import 'package:dripple/services/online_client.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_server/dripple_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// The client is tested against the real server rather than a mock of it. A
/// mock would agree with whatever the client expects, which is exactly the
/// thing worth checking.
void main() {
  late HttpServer server;
  late Uri baseUrl;
  late InMemoryRoomStore store;

  OnlineClient clientFor(String uid) =>
      OnlineClient(baseUrl: baseUrl, token: () async => uid);

  setUp(() async {
    store = InMemoryRoomStore();
    final api = Api(
      service: GameService(store: store, random: Random(3)),
      verifier: const TrustingTokenVerifier(),
    );
    server = await shelf_io.serve(api.handler, InternetAddress.loopbackIPv4, 0);
    baseUrl = Uri.parse('http://${server.address.host}:${server.port}');
  });

  tearDown(() async => server.close(force: true));

  group('a room, from the app\'s side', () {
    test('is made, joined by code, and dealt', () async {
      final mina = clientFor('mina');
      final jun = clientFor('jun');

      final made = await mina.createRoom(name: 'Mina');
      expect(made.isLobby, isTrue);
      expect(made.yourSeat, equals(0));
      expect(made.amHost('mina'), isTrue);
      expect(made.game, isNull, reason: 'a lobby has no game yet');

      final joined = await jun.joinRoom(code: made.code, name: 'Jun');
      expect(joined.yourSeat, equals(1));
      expect(joined.amHost('jun'), isFalse);

      final started = await mina.startGame(made.roomId);
      expect(started.isPlaying, isTrue);
      expect(started.game, isNotNull);
      expect(started.game!.mySeatIndex, equals(0));
      expect(started.game!.me.hand.length, equals(7));
    });

    test('gives each player a board they can already draw', () async {
      final mina = clientFor('mina');
      final jun = clientFor('jun');
      final made = await mina.createRoom(name: 'Mina');
      await jun.joinRoom(code: made.code, name: 'Jun');
      await mina.startGame(made.roomId);

      final seenByJun = await jun.readRoom(made.roomId);
      final game = seenByJun.game!;

      expect(game.mySeatIndex, equals(1));
      expect(game.isMyTurn, isFalse, reason: 'Mina goes first');
      expect(game.me.hand.every((c) => !c.isFaceDown), isTrue,
          reason: 'my own cards are readable');
      expect(game.opponents.single.hand.length, equals(7));
      expect(game.opponents.single.hand.every((c) => c.isFaceDown), isTrue,
          reason: 'and nobody else\'s are');
      expect(game.deck.every((c) => c.isFaceDown), isTrue);
      expect(game.discardTop, isNotNull);
      expect(game.discardTop!.isFaceDown, isFalse,
          reason: 'the top of the discard pile is face up');
    });
  });

  group('playing', () {
    late String roomId;
    late OnlineClient mina;
    late OnlineClient jun;

    setUp(() async {
      mina = clientFor('mina');
      jun = clientFor('jun');
      final made = await mina.createRoom(name: 'Mina');
      roomId = made.roomId;
      await jun.joinRoom(code: made.code, name: 'Jun');
      await mina.startGame(roomId);
    });

    test('a draw arrives as a card I can read', () async {
      final after = await mina.draw(roomId);
      expect(after.game!.me.hand.length, equals(8));
      expect(after.game!.turnPhase, equals(TurnPhase.action));
      expect(after.game!.me.hand.every((c) => !c.isFaceDown), isTrue);
    });

    test('passing hands the turn to the other person', () async {
      await mina.draw(roomId);
      final after = await mina.pass(roomId);
      expect(after.game!.isMyTurn, isFalse);
      expect(after.game!.currentPlayerIndex, equals(1));

      final junsView = await jun.readRoom(roomId);
      expect(junsView.game!.isMyTurn, isTrue);
    });

    test('a sentence that does not parse comes back judged', () async {
      final drawn = await mina.draw(roomId);
      final oneCard = drawn.game!.me.hand.first.id;

      final judged = await mina.submit(roomId, [oneCard]);
      expect(judged.judgment, isNotNull);
      expect(judged.judgment!.isCorrect, isFalse);
      expect(judged.judgment!.errorCodes, isNotEmpty);
      expect(judged.game!.me.hand.length, equals(8),
          reason: 'the cards came back');
      expect(judged.game!.isMyTurn, isTrue, reason: 'and the turn did not');
    });

    test('acting out of turn is refused with a code, not a crash', () async {
      await expectLater(
        jun.draw(roomId),
        throwsA(isA<OnlineError>()
            .having((e) => e.code, 'code', 'not_your_turn')
            .having((e) => e.status, 'status', 422)),
      );
    });

    test('a card I do not hold is refused', () async {
      await mina.draw(roomId);
      await expectLater(
        mina.discard(roomId, 'card_99999'),
        throwsA(isA<OnlineError>()
            .having((e) => e.code, 'code', 'no_such_card')),
      );
    });
  });

  group('when things go wrong', () {
    test('a code nobody issued is a plain no_such_room', () async {
      await expectLater(
        clientFor('mina').joinRoom(code: 'ZZZZZZ', name: 'Mina'),
        throwsA(isA<OnlineError>()
            .having((e) => e.code, 'code', 'no_such_room')
            .having((e) => e.status, 'status', 404)),
      );
    });

    test('an unreachable server is offline, not a refusal', () async {
      final stranded = OnlineClient(
        // Port 1 is reserved and nothing listens there.
        baseUrl: Uri.parse('http://127.0.0.1:1'),
        token: () async => 'mina',
      );
      await expectLater(
        stranded.createRoom(name: 'Mina'),
        throwsA(isA<OnlineError>().having((e) => e.isOffline, 'isOffline', isTrue)),
      );
    });
  });

  group('leaving', () {
    test('mid-game leaves a bot playing my cards', () async {
      final mina = clientFor('mina');
      final jun = clientFor('jun');
      final made = await mina.createRoom(name: 'Mina');
      await jun.joinRoom(code: made.code, name: 'Jun');
      await mina.startGame(made.roomId);

      await jun.leaveRoom(made.roomId);
      final seenByMina = await mina.readRoom(made.roomId);

      expect(seenByMina.isPlaying, isTrue);
      expect(seenByMina.seats[1].kind, equals('bot'));
      expect(seenByMina.seats[1].uid, equals('jun'),
          reason: 'the chair is still theirs to come back to');
    });

    test('and a nudge moves the bot along', () async {
      final mina = clientFor('mina');
      final jun = clientFor('jun');
      final made = await mina.createRoom(name: 'Mina');
      await jun.joinRoom(code: made.code, name: 'Jun');
      await mina.startGame(made.roomId);

      await mina.draw(made.roomId);
      await mina.pass(made.roomId);
      await jun.leaveRoom(made.roomId);

      final before = await mina.readRoom(made.roomId);
      expect(before.game!.currentPlayerIndex, equals(1));

      final after = await mina.tick(made.roomId);
      expect(after.game!.currentPlayerIndex, equals(0),
          reason: 'the bot took its turn');
    });
  });
}
