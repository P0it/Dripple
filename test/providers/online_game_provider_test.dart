import 'dart:io';
import 'dart:math';

import 'package:dripple/providers/online_game_provider.dart';
import 'package:dripple/services/online_client.dart';
import 'package:dripple_server/dripple_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Driven against the real server, so what the board believes is checked
/// against what the authority actually says.
void main() {
  late HttpServer server;
  late Uri baseUrl;

  OnlineClient clientFor(String uid) =>
      OnlineClient(baseUrl: baseUrl, token: () async => uid);

  setUp(() async {
    final api = Api(
      service: GameService(store: InMemoryRoomStore(), random: Random(5)),
      verifier: const TrustingTokenVerifier(),
    );
    server = await shelf_io.serve(api.handler, InternetAddress.loopbackIPv4, 0);
    baseUrl = Uri.parse('http://${server.address.host}:${server.port}');
  });

  tearDown(() async => server.close(force: true));

  /// A dealt two-hander, and a notifier already watching it for [uid].
  Future<OnlineGameNotifier> watching(String uid, {Duration? poll}) async {
    final mina = clientFor('mina');
    final jun = clientFor('jun');
    final made = await mina.createRoom(name: 'Mina');
    await jun.joinRoom(code: made.code, name: 'Jun');
    await mina.startGame(made.roomId);

    final notifier = OnlineGameNotifier(
      client: clientFor(uid),
      roomId: made.roomId,
      pollInterval: poll ?? const Duration(milliseconds: 40),
      botPause: Duration.zero,
    );
    await notifier.start();
    return notifier;
  }

  test('starts by learning where the game already is', () async {
    final notifier = await watching('jun');
    addTearDown(notifier.dispose);

    expect(notifier.state.room, isNotNull);
    expect(notifier.state.game, isNotNull);
    expect(notifier.state.game!.mySeatIndex, equals(1));
    expect(notifier.state.isMyTurn, isFalse);
    expect(notifier.state.busy, isFalse);
  });

  test('an action makes the reply the new truth', () async {
    final notifier = await watching('mina');
    addTearDown(notifier.dispose);

    await notifier.drawFromDeck();
    expect(notifier.state.game!.me.hand.length, equals(8));
    expect(notifier.state.error, isNull);
  });

  test('a refusal is kept for the screen and then cleared', () async {
    final notifier = await watching('jun');
    addTearDown(notifier.dispose);

    await notifier.drawFromDeck(); // not Jun's turn
    expect(notifier.state.error, isNotNull);
    expect(notifier.state.error!.code, equals('not_your_turn'));

    notifier.clearError();
    expect(notifier.state.error, isNull);
  });

  test('a judged sentence is surfaced and then cleared', () async {
    final notifier = await watching('mina');
    addTearDown(notifier.dispose);

    await notifier.drawFromDeck();
    await notifier.submit([notifier.state.game!.me.hand.first]);

    expect(notifier.state.judgment, isNotNull);
    expect(notifier.state.judgment!.isCorrect, isFalse);
    notifier.clearJudgment();
    expect(notifier.state.judgment, isNull);
  });

  test('polling notices the other player moving', () async {
    final notifier = await watching('jun');
    addTearDown(notifier.dispose);
    expect(notifier.state.isMyTurn, isFalse);

    final mina = clientFor('mina');
    final room = notifier.state.room!;
    await mina.draw(room.roomId);
    await mina.pass(room.roomId);

    // Give the poller a few beats to catch up.
    for (var i = 0; i < 40 && !notifier.state.isMyTurn; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect(notifier.state.isMyTurn, isTrue);
  });

  test('a seat nobody will move gets nudged along', () async {
    final notifier = await watching('mina');
    addTearDown(notifier.dispose);

    await notifier.drawFromDeck();
    await notifier.pass();
    expect(notifier.state.isMyTurn, isFalse);

    // Jun walks out; the chair becomes a bot that nobody is driving.
    await clientFor('jun').leaveRoom(notifier.state.room!.roomId);

    for (var i = 0; i < 60 && !notifier.state.isMyTurn; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect(notifier.state.isMyTurn, isTrue,
        reason: 'the bot should have been nudged into taking its turn');
  });

  test('a poll that fails does not put an error over a playable board',
      () async {
    final notifier = await watching('mina');
    addTearDown(notifier.dispose);
    final before = notifier.state.game;

    await server.close(force: true);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(notifier.state.error, isNull,
        reason: 'a missed poll is not something to shout about');
    expect(notifier.state.game, equals(before));
  });
}
