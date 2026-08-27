import 'dart:convert';

import 'package:dripple_rules/wire/wire.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'actions.dart';
import 'auth.dart';
import 'errors.dart';
import 'game_service.dart';
import 'room.dart';

/// The HTTP face of [GameService].
///
/// Actions come in over HTTP rather than through the database because a
/// player needs to be told, in the same breath, that their sentence did not
/// parse and why. A write to a database can only be followed by waiting to
/// see what happens.
///
/// What a client is told back is deliberately not the whole room: [_view]
/// strips it to what that seat may see.
class Api {
  final GameService _service;
  final TokenVerifier _verifier;

  Api({required GameService service, required TokenVerifier verifier})
      : _service = service,
        _verifier = verifier;

  Handler get handler {
    final router = Router()
      ..get('/health', (Request r) => Response.ok('ok'))
      ..post('/rooms', _guard(_createRoom))
      ..post('/rooms/join', _guard(_joinRoom))
      ..post('/rooms/<roomId>/ready', _guard(_setReady))
      ..post('/rooms/<roomId>/presence', _guard(_setConnected))
      ..post('/rooms/<roomId>/leave', _guard(_leaveRoom))
      ..post('/rooms/<roomId>/start', _guard(_startGame))
      ..post('/rooms/<roomId>/action', _guard(_act))
      // Anyone at the table may nudge a stalled game along — a bot's turn, or
      // somebody who ran out of time. The version check makes a crowd of
      // simultaneous nudges harmless.
      ..post('/rooms/<roomId>/tick', _guard(_tick));
    return router.call;
  }

  // ---------------------------------------------------------------------

  Future<Response> _createRoom(Request request, String uid) async {
    final body = await _body(request);
    final room = await _service.createRoom(
      uid: uid,
      name: _name(body),
      maxPlayers: (body['maxPlayers'] as int?) ?? 4,
    );
    return _ok(_view(room, uid));
  }

  Future<Response> _joinRoom(Request request, String uid) async {
    final body = await _body(request);
    final code = body['code'] as String?;
    if (code == null) throw const GameError('bad_request', 'no code given');
    final room =
        await _service.joinRoom(code: code, uid: uid, name: _name(body));
    return _ok(_view(room, uid));
  }

  Future<Response> _setReady(Request request, String uid) async {
    final body = await _body(request);
    final room = await _service.setReady(
      roomId: request.params['roomId']!,
      uid: uid,
      ready: body['ready'] as bool? ?? false,
    );
    return _ok(_view(room, uid));
  }

  Future<Response> _setConnected(Request request, String uid) async {
    final body = await _body(request);
    final room = await _service.setConnected(
      roomId: request.params['roomId']!,
      uid: uid,
      connected: body['connected'] as bool? ?? true,
    );
    return _ok(_view(room, uid));
  }

  Future<Response> _leaveRoom(Request request, String uid) async {
    final room = await _service.leaveRoom(
      roomId: request.params['roomId']!,
      uid: uid,
    );
    return _ok(_view(room, uid));
  }

  Future<Response> _startGame(Request request, String uid) async {
    final body = await _body(request);
    final room = await _service.startGame(
      roomId: request.params['roomId']!,
      uid: uid,
      turnTimerSeconds: body['turnTimerSeconds'] as int? ?? 0,
    );
    return _ok(_view(room, uid));
  }

  Future<Response> _act(Request request, String uid) async {
    final body = await _body(request);
    final outcome = await _service.act(
      roomId: request.params['roomId']!,
      uid: uid,
      action: GameAction.fromJson(body),
    );
    return _ok({
      ..._view(outcome.room, uid),
      if (outcome.judgment != null)
        'judgment': {
          'isCorrect': outcome.judgment!.isCorrect,
          'errors': [
            for (final e in outcome.judgment!.errors)
              {
                'code': e.code,
                'message': e.message,
                if (e.localizedMessages != null)
                  'localized': e.localizedMessages,
              },
          ],
        },
    });
  }

  Future<Response> _tick(Request request, String uid) async {
    final room = await _service.tick(request.params['roomId']!);
    return _ok(_view(room, uid));
  }

  // ---------------------------------------------------------------------

  /// What one seat is allowed to be told.
  ///
  /// The room carries every hand and the deck in order. Handing that back
  /// would defeat the entire reason the server exists, so a response carries
  /// the public view plus the requester's own cards and nothing else.
  Map<String, dynamic> _view(Room room, String uid) {
    final seat = room.seats.indexWhere((s) => s.uid == uid);
    final game = room.game;
    return {
      'roomId': room.id,
      'code': room.code,
      'hostUid': room.hostUid,
      'status': room.status.name,
      'version': room.version,
      'turnDeadlineMs': room.turnDeadlineMs,
      'yourSeat': seat,
      'seats': [for (final s in room.seats) s.toJson()],
      if (game != null) 'public': PublicView.encode(game),
      if (game != null && seat >= 0 && seat < game.players.length)
        'yourHand': [for (final c in game.players[seat].hand) c.id],
    };
  }

  Map<String, dynamic> _bodyOrEmpty(String raw) {
    if (raw.trim().isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const GameError('bad_request', 'body must be an object');
    }
    return decoded.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> _body(Request request) async =>
      _bodyOrEmpty(await request.readAsString());

  String _name(Map<String, dynamic> body) {
    final name = (body['name'] as String? ?? '').trim();
    return name.isEmpty ? 'Player' : name;
  }

  Response _ok(Map<String, dynamic> json) => Response.ok(
        jsonEncode(json),
        headers: {'content-type': 'application/json'},
      );

  /// Establish who is calling, and turn a refused move into an answer rather
  /// than a stack trace.
  Future<Response> Function(Request) _guard(
    Future<Response> Function(Request, String uid) inner,
  ) =>
      (Request request) async {
        final header = request.headers['authorization'] ?? '';
        final token = header.startsWith('Bearer ') ? header.substring(7) : '';
        final uid = await _verifier.verify(token);
        if (uid == null) {
          return Response.unauthorized(
            jsonEncode({'code': 'unauthenticated', 'message': 'sign in first'}),
            headers: {'content-type': 'application/json'},
          );
        }
        try {
          return await inner(request, uid);
        } on GameError catch (e) {
          return Response(
            _statusFor(e),
            body: jsonEncode({'code': e.code, 'message': e.message}),
            headers: {'content-type': 'application/json'},
          );
        }
      };

  int _statusFor(GameError e) => switch (e.code) {
        'no_such_room' => 404,
        'not_in_room' || 'not_host' => 403,
        'conflict' => 409,
        'room_full' ||
        'already_started' ||
        'not_started' ||
        'not_enough_players' ||
        'not_your_turn' ||
        'no_such_card' =>
          422,
        _ => 400,
      };
}
