import 'dart:convert';
import 'dart:math';

import 'package:dripple_server/dripple_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Every string anywhere in a payload. Leak checks compare ids exactly:
/// `card_2` is a substring of `card_20`, so searching the text of a response
/// reports leaks that are not there.
Set<String> everyString(Object? node) {
  if (node is String) return {node};
  if (node is Map) {
    return {for (final e in node.entries) ...everyString(e.value)};
  }
  if (node is Iterable) return {for (final i in node) ...everyString(i)};
  return const {};
}

void main() {
  late InMemoryRoomStore store;
  late Handler handler;

  setUp(() {
    store = InMemoryRoomStore();
    handler = Api(
      service: GameService(store: store, random: Random(11)),
      verifier: const TrustingTokenVerifier(),
    ).handler;
  });

  Future<Map<String, dynamic>> post(
    String path,
    String uid, [
    Map<String, dynamic> body = const {},
  ]) async {
    final response = await handler(Request(
      'POST',
      Uri.parse('http://localhost$path'),
      headers: {'authorization': 'Bearer $uid'},
      body: jsonEncode(body),
    ));
    final text = await response.readAsString();
    return {
      'status': response.statusCode,
      'body': text.isEmpty ? <String, dynamic>{} : jsonDecode(text),
    };
  }

  group('signing in', () {
    test('a request with no token is turned away', () async {
      final response = await handler(Request(
        'POST',
        Uri.parse('http://localhost/rooms'),
        body: '{}',
      ));
      expect(response.statusCode, equals(401));
    });

    test('health needs nothing', () async {
      final response = await handler(
          Request('GET', Uri.parse('http://localhost/health')));
      expect(response.statusCode, equals(200));
    });
  });

  group('a room over HTTP', () {
    test('is made, joined and dealt', () async {
      final made = await post('/rooms', 'mina', {'name': 'Mina'});
      expect(made['status'], equals(200));
      final code = made['body']['code'] as String;
      final roomId = made['body']['roomId'] as String;
      expect(made['body']['yourSeat'], equals(0));

      final joined =
          await post('/rooms/join', 'jun', {'code': code, 'name': 'Jun'});
      expect(joined['status'], equals(200));
      expect(joined['body']['yourSeat'], equals(1));

      final started = await post('/rooms/$roomId/start', 'mina');
      expect(started['status'], equals(200));
      expect(started['body']['status'], equals('playing'));
      expect((started['body']['yourHand'] as List).length, equals(7));
    });

    test('tells a guest they may not deal', () async {
      final made = await post('/rooms', 'mina', {'name': 'Mina'});
      final code = made['body']['code'] as String;
      final roomId = made['body']['roomId'] as String;
      await post('/rooms/join', 'jun', {'code': code, 'name': 'Jun'});

      final refused = await post('/rooms/$roomId/start', 'jun');
      expect(refused['status'], equals(403));
      expect(refused['body']['code'], equals('not_host'));
    });

    test('says which code it did not recognise, and with a 404', () async {
      final missing = await post('/rooms/join', 'mina', {'code': 'ZZZZZZ'});
      expect(missing['status'], equals(404));
      expect(missing['body']['code'], equals('no_such_room'));
    });

    test('refuses a move out of turn with a reason a screen can show',
        () async {
      final made = await post('/rooms', 'mina', {'name': 'Mina'});
      final code = made['body']['code'] as String;
      final roomId = made['body']['roomId'] as String;
      await post('/rooms/join', 'jun', {'code': code, 'name': 'Jun'});
      await post('/rooms/$roomId/start', 'mina');

      final refused =
          await post('/rooms/$roomId/action', 'jun', {'kind': 'draw'});
      expect(refused['status'], equals(422));
      expect(refused['body']['code'], equals('not_your_turn'));
    });
  });

  group('what a seat is told', () {
    late String roomId;

    setUp(() async {
      final made = await post('/rooms', 'mina', {'name': 'Mina'});
      final code = made['body']['code'] as String;
      roomId = made['body']['roomId'] as String;
      await post('/rooms/join', 'jun', {'code': code, 'name': 'Jun'});
      await post('/rooms/$roomId/start', 'mina');
    });

    test('is its own hand and no other', () async {
      final response = await post('/rooms/$roomId/tick', 'mina');
      final told = everyString(response['body']);
      final game = (await store.load(roomId))!.game!;

      for (final card in game.players[0].hand) {
        expect(told, contains(card.id), reason: 'mina should see her own hand');
      }
      for (final card in game.players[1].hand) {
        expect(told, isNot(contains(card.id)),
            reason: 'jun\'s ${card.id} was told to mina');
      }
    });

    test('never includes the deck', () async {
      final response = await post('/rooms/$roomId/tick', 'mina');
      final told = everyString(response['body']);
      final game = (await store.load(roomId))!.game!;
      for (final card in game.deck) {
        expect(told, isNot(contains(card.id)));
      }
    });

    test('carries how many cards everyone holds', () async {
      final response = await post('/rooms/$roomId/tick', 'mina');
      final public = response['body']['public'] as Map;
      expect(public['handCounts'], equals([7, 7]));
      expect(public['currentSeat'], equals(0));
    });
  });

  group('playing over HTTP', () {
    test('a bad sentence comes back judged, not merely refused', () async {
      final made = await post('/rooms', 'mina', {'name': 'Mina'});
      final code = made['body']['code'] as String;
      final roomId = made['body']['roomId'] as String;
      await post('/rooms/join', 'jun', {'code': code, 'name': 'Jun'});
      await post('/rooms/$roomId/start', 'mina');
      final drawn =
          await post('/rooms/$roomId/action', 'mina', {'kind': 'draw'});

      final oneCard = (drawn['body']['yourHand'] as List).first as String;
      final submitted = await post('/rooms/$roomId/action', 'mina', {
        'kind': 'submit',
        'cardIds': [oneCard],
      });

      expect(submitted['status'], equals(200));
      expect(submitted['body']['judgment']['isCorrect'], isFalse);
      expect((submitted['body']['judgment']['errors'] as List), isNotEmpty);
      expect((submitted['body']['yourHand'] as List).length, equals(8),
          reason: 'the cards came back');
    });

    test('an action nobody defined is a bad request, not a crash', () async {
      final made = await post('/rooms', 'mina', {'name': 'Mina'});
      final code = made['body']['code'] as String;
      final roomId = made['body']['roomId'] as String;
      await post('/rooms/join', 'jun', {'code': code, 'name': 'Jun'});
      await post('/rooms/$roomId/start', 'mina');

      final nonsense =
          await post('/rooms/$roomId/action', 'mina', {'kind': 'fly'});
      expect(nonsense['status'], equals(400));
      expect(nonsense['body']['code'], equals('bad_action'));
    });
  });
}
