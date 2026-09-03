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

  test('sorting the hand is answered here, whoever is up', () async {
    // Trying orders out in the fan is how a player works a sentence out, and
    // most of that happens while somebody else is taking their turn. Nothing
    // in the rules reads the hand's order, so the server is never told.
    final notifier = await watching('jun');
    addTearDown(notifier.dispose);

    final before =
        notifier.state.game!.me.hand.map((c) => c.id).toList();
    expect(before, hasLength(greaterThan(2)));

    notifier.reorderHand(0, 2);

    final after = notifier.state.game!.me.hand.map((c) => c.id).toList();
    expect(after, [before[1], before[2], before[0], ...before.sublist(3)]);
    expect(after.toSet(), before.toSet(), reason: 'no card appeared or left');

    // And the next snapshot from the authority does not undo it.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(notifier.state.game!.me.hand.map((c) => c.id).toList(), after);
  });

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
    notifier.placeCard(0);
    await notifier.submitStaged();

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

  group('building a sentence', () {
    test('moves a card out of the hand and onto the table, locally', () async {
      final notifier = await watching('mina');
      addTearDown(notifier.dispose);
      await notifier.drawFromDeck();

      final held = notifier.state.game!.me.hand.length;
      final first = notifier.state.game!.me.hand.first.id;
      notifier.placeCard(0);

      expect(notifier.state.game!.me.hand.length, equals(held - 1));
      expect(notifier.state.game!.me.sentenceZone.map((c) => c.id),
          equals([first]));
    });

    test('and back again when it is taken off', () async {
      final notifier = await watching('mina');
      addTearDown(notifier.dispose);
      await notifier.drawFromDeck();
      final held = notifier.state.game!.me.hand.length;

      notifier.placeCard(0);
      notifier.removeFromSentence(0);

      expect(notifier.state.game!.me.hand.length, equals(held));
      expect(notifier.state.game!.me.sentenceZone, isEmpty);
    });

    test('keeps the order the cards were laid in, and lets it be changed',
        () async {
      final notifier = await watching('mina');
      addTearDown(notifier.dispose);
      await notifier.drawFromDeck();

      final hand = notifier.state.game!.me.hand;
      final a = hand[0].id, b = hand[1].id, c = hand[2].id;
      notifier.placeCard(0);
      notifier.placeCard(0);
      notifier.placeCard(0);
      expect(notifier.state.game!.me.sentenceZone.map((x) => x.id),
          equals([a, b, c]));

      notifier.reorderSentence(2, 0);
      expect(notifier.state.game!.me.sentenceZone.map((x) => x.id),
          equals([c, a, b]));
    });

    test('is not swept away by a poll that changed nothing', () async {
      final notifier = await watching('mina');
      addTearDown(notifier.dispose);
      await notifier.drawFromDeck();
      notifier.placeCard(0);
      final staged = notifier.state.staged;

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(notifier.state.staged, equals(staged),
          reason: 'a poll must not knock the cards off the table');
    });

    test('is cleared once the sentence has been judged', () async {
      final notifier = await watching('mina');
      addTearDown(notifier.dispose);
      await notifier.drawFromDeck();
      notifier.placeCard(0);
      await notifier.submitStaged();

      expect(notifier.state.judgment, isNotNull);
      expect(notifier.state.staged, isEmpty);
      expect(notifier.state.game!.me.sentenceZone, isEmpty);
    });

    test('cannot be built on somebody else\'s turn', () async {
      final notifier = await watching('jun');
      addTearDown(notifier.dispose);
      notifier.placeCard(0);
      expect(notifier.state.staged, isEmpty);
    });
  });
}
