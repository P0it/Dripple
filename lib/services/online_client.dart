import 'dart:convert';

import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/wire/wire.dart';
import 'package:http/http.dart' as http;

/// Something the server refused, in a form a screen can act on.
///
/// [code] is the contract — `not_your_turn`, `room_full`, `no_such_room` —
/// and what a localized message is looked up by. The message is for logs.
class OnlineError implements Exception {
  final String code;
  final String message;
  final int status;

  const OnlineError(this.code, this.message, this.status);

  /// Nothing reached the server at all.
  bool get isOffline => status == 0;

  @override
  String toString() => 'OnlineError($code/$status): $message';
}

/// A room as this device is allowed to know it.
///
/// The server sends the table plus this seat's own cards, never the deck and
/// never another hand, so this is the whole of what a client can hold.
class RoomView {
  final String roomId;
  final String code;
  final String hostUid;
  final String status;
  final int version;
  final int yourSeat;
  final int? turnDeadlineMs;
  final List<SeatView> seats;

  /// The playable game, or null while the room is still a lobby.
  final GameState? game;

  /// The judgment for a sentence just submitted, when this view came back
  /// from submitting one.
  final Judgment? judgment;

  const RoomView({
    required this.roomId,
    required this.code,
    required this.hostUid,
    required this.status,
    required this.version,
    required this.yourSeat,
    this.turnDeadlineMs,
    this.seats = const [],
    this.game,
    this.judgment,
  });

  bool get isLobby => status == 'lobby';
  bool get isPlaying => status == 'playing';
  bool get isFinished => status == 'finished';
  bool amHost(String uid) => hostUid == uid;

  static RoomView fromJson(Map<String, dynamic> json) {
    final publicJson = json['public'] as Map?;
    final seat = json['yourSeat'] as int? ?? -1;
    return RoomView(
      roomId: json['roomId'] as String,
      code: json['code'] as String,
      hostUid: json['hostUid'] as String? ?? '',
      status: json['status'] as String,
      version: json['version'] as int? ?? 0,
      yourSeat: seat,
      turnDeadlineMs: json['turnDeadlineMs'] as int?,
      seats: [
        for (final s in (json['seats'] as List? ?? const []))
          SeatView.fromJson((s as Map).cast<String, dynamic>()),
      ],
      game: publicJson == null || seat < 0
          ? null
          : PublicView.decode(
              publicJson.cast<String, dynamic>(),
              viewerSeat: seat,
              myHandIds: [
                for (final id in (json['yourHand'] as List? ?? const []))
                  id as String,
              ],
            ),
      judgment: json['judgment'] == null
          ? null
          : Judgment.fromJson((json['judgment'] as Map).cast<String, dynamic>()),
    );
  }
}

class SeatView {
  final String uid;
  final String name;
  final String kind;
  final bool ready;
  final bool connected;

  const SeatView({
    required this.uid,
    required this.name,
    required this.kind,
    this.ready = false,
    this.connected = true,
  });

  bool get isEmpty => kind == 'empty';

  static SeatView fromJson(Map<String, dynamic> json) => SeatView(
        uid: json['uid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        kind: json['kind'] as String? ?? 'empty',
        ready: json['ready'] as bool? ?? false,
        connected: json['connected'] as bool? ?? true,
      );
}

/// How a submitted sentence was judged. The error codes are the grammar
/// engine's own, so the app shows the same reasons offline and online.
class Judgment {
  final bool isCorrect;
  final List<String> errorCodes;
  final List<String> messages;

  const Judgment({
    required this.isCorrect,
    this.errorCodes = const [],
    this.messages = const [],
  });

  static Judgment fromJson(Map<String, dynamic> json) {
    final errors = (json['errors'] as List? ?? const []).cast<Map>();
    return Judgment(
      isCorrect: json['isCorrect'] as bool? ?? false,
      errorCodes: [for (final e in errors) e['code'] as String? ?? ''],
      messages: [for (final e in errors) e['message'] as String? ?? ''],
    );
  }
}

/// Talks to the game server.
///
/// Actions go over HTTP rather than through a database because a player has
/// to be told in the same breath that their sentence did not parse, and why.
class OnlineClient {
  final Uri baseUrl;
  final http.Client _http;

  /// How this device proves who it is. Today that is a locally-kept id; when
  /// Firebase Auth lands it becomes an ID token, and nothing else changes.
  final Future<String> Function() _token;

  OnlineClient({
    required this.baseUrl,
    required Future<String> Function() token,
    http.Client? httpClient,
  })  : _token = token,
        _http = httpClient ?? http.Client();

  Future<RoomView> createRoom({required String name, int maxPlayers = 4}) =>
      _post('/rooms', {'name': name, 'maxPlayers': maxPlayers});

  Future<RoomView> joinRoom({required String code, required String name}) =>
      _post('/rooms/join', {'code': code, 'name': name});

  Future<RoomView> readRoom(String roomId) => _get('/rooms/$roomId');

  Future<RoomView> setReady(String roomId, bool ready) =>
      _post('/rooms/$roomId/ready', {'ready': ready});

  Future<RoomView> setConnected(String roomId, bool connected) =>
      _post('/rooms/$roomId/presence', {'connected': connected});

  Future<RoomView> leaveRoom(String roomId) => _post('/rooms/$roomId/leave', {});

  Future<RoomView> startGame(String roomId, {int turnTimerSeconds = 0}) =>
      _post('/rooms/$roomId/start', {'turnTimerSeconds': turnTimerSeconds});

  Future<RoomView> draw(String roomId, {bool fromDiscard = false}) =>
      _act(roomId, {'kind': 'draw', 'fromDiscard': fromDiscard});

  Future<RoomView> submit(String roomId, List<String> cardIds) =>
      _act(roomId, {'kind': 'submit', 'cardIds': cardIds});

  Future<RoomView> discard(String roomId, String cardId) =>
      _act(roomId, {'kind': 'discard', 'cardId': cardId});

  Future<RoomView> pass(String roomId) => _act(roomId, {'kind': 'pass'});

  Future<RoomView> jump(String roomId, String cardId) =>
      _act(roomId, {'kind': 'jump', 'cardId': cardId});

  Future<RoomView> steal(
    String roomId, {
    required String cardId,
    required int targetSeat,
    required String giveCardId,
  }) =>
      _act(roomId, {
        'kind': 'steal',
        'cardId': cardId,
        'targetSeat': targetSeat,
        'giveCardId': giveCardId,
      });

  /// Nudge a game nobody is going to move: a bot's turn, or a player who ran
  /// out of time. Safe to send from every device at once — the server's
  /// version check settles the race.
  Future<RoomView> tick(String roomId) => _post('/rooms/$roomId/tick', {});

  void dispose() => _http.close();

  // ---------------------------------------------------------------------

  Future<RoomView> _act(String roomId, Map<String, dynamic> action) =>
      _post('/rooms/$roomId/action', action);

  Future<RoomView> _get(String path) async => _send(
        (headers) => _http.get(baseUrl.resolve(path), headers: headers),
      );

  Future<RoomView> _post(String path, Map<String, dynamic> body) async => _send(
        (headers) => _http.post(
          baseUrl.resolve(path),
          headers: {...headers, 'content-type': 'application/json'},
          body: jsonEncode(body),
        ),
      );

  Future<RoomView> _send(
    Future<http.Response> Function(Map<String, String>) call,
  ) async {
    final http.Response response;
    try {
      response = await call({'authorization': 'Bearer ${await _token()}'});
    } catch (e) {
      // A request that never arrived is not a refusal; the screen should say
      // "no connection", not "the rules say no".
      throw OnlineError('offline', e.toString(), 0);
    }

    final decoded = response.body.trim().isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(response.body);
    final json = decoded is Map
        ? decoded.cast<String, dynamic>()
        : const <String, dynamic>{};

    if (response.statusCode >= 400) {
      throw OnlineError(
        json['code'] as String? ?? 'unknown',
        json['message'] as String? ?? response.reasonPhrase ?? '',
        response.statusCode,
      );
    }
    return RoomView.fromJson(json);
  }
}
