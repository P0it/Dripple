import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/wire/wire.dart';

/// Where a room is in its life.
enum RoomStatus { lobby, playing, finished }

/// What is sitting in a seat.
enum SeatKind {
  /// A person, present or merely disconnected.
  human,

  /// A bot. Either a seat somebody walked away from, or one nobody took.
  bot,

  /// Nobody. Only possible before the game is dealt.
  empty,
}

/// One place at the table.
class Seat {
  /// The account sitting here, or empty for a bot or an unclaimed seat.
  ///
  /// A seat keeps its uid when its occupant disconnects, which is how they
  /// get their own cards back when they return rather than a stranger's.
  final String uid;
  final String name;
  final SeatKind kind;
  final bool ready;
  final bool connected;

  const Seat({
    this.uid = '',
    this.name = '',
    this.kind = SeatKind.empty,
    this.ready = false,
    this.connected = true,
  });

  bool get isEmpty => kind == SeatKind.empty;
  bool get isHuman => kind == SeatKind.human;

  Seat copyWith({
    String? uid,
    String? name,
    SeatKind? kind,
    bool? ready,
    bool? connected,
  }) =>
      Seat(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        ready: ready ?? this.ready,
        connected: connected ?? this.connected,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'kind': kind.name,
        'ready': ready,
        'connected': connected,
      };

  static Seat fromJson(Map<String, dynamic> json) => Seat(
        uid: json['uid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        kind: SeatKind.values.byName(json['kind'] as String? ?? 'empty'),
        ready: json['ready'] as bool? ?? false,
        connected: json['connected'] as bool? ?? true,
      );
}

/// A room and, once it is dealt, the game inside it.
///
/// [version] is what makes concurrent play safe. The server holds nothing
/// between requests, so two actions arriving together would each read the
/// same game, apply their own move, and the second write would erase the
/// first. Every write states the version it read; a store rejects the write
/// if that is no longer current, and the caller retries against fresh state.
class Room {
  final String id;
  final String code;
  final String hostUid;
  final RoomStatus status;
  final List<Seat> seats;

  /// The authoritative game, hands and deck included. Null until it is dealt.
  final GameState? game;

  final int version;

  /// When the seat in play runs out of time, in epoch milliseconds. Null when
  /// no timer is running — the turn timer is off by default.
  final int? turnDeadlineMs;

  const Room({
    required this.id,
    required this.code,
    required this.hostUid,
    this.status = RoomStatus.lobby,
    this.seats = const [],
    this.game,
    this.version = 0,
    this.turnDeadlineMs,
  });

  int get occupiedSeats => seats.where((s) => !s.isEmpty).length;
  int get humanSeats => seats.where((s) => s.isHuman).length;
  bool get isFull => seats.every((s) => !s.isEmpty);

  /// Two is enough to play. One person alone would be playing solitaire
  /// against nobody, and the offline game already exists for that.
  bool get canStart => status == RoomStatus.lobby && occupiedSeats >= 2;

  int seatOf(String uid) => seats.indexWhere((s) => s.uid == uid && s.isHuman);

  Room copyWith({
    RoomStatus? status,
    List<Seat>? seats,
    GameState? game,
    String? hostUid,
    int? version,
    int? turnDeadlineMs,
    bool clearDeadline = false,
  }) =>
      Room(
        id: id,
        code: code,
        hostUid: hostUid ?? this.hostUid,
        status: status ?? this.status,
        seats: seats ?? this.seats,
        game: game ?? this.game,
        version: version ?? this.version,
        turnDeadlineMs:
            clearDeadline ? null : (turnDeadlineMs ?? this.turnDeadlineMs),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'hostUid': hostUid,
        'status': status.name,
        'version': version,
        'turnDeadlineMs': turnDeadlineMs,
        'seats': [for (final s in seats) s.toJson()],
        if (game != null) 'game': GameSnapshot.encode(game!),
      };

  static Room fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        code: json['code'] as String,
        hostUid: json['hostUid'] as String,
        status: RoomStatus.values.byName(json['status'] as String),
        version: json['version'] as int? ?? 0,
        turnDeadlineMs: json['turnDeadlineMs'] as int?,
        seats: [
          for (final s in (json['seats'] as List? ?? const []))
            Seat.fromJson((s as Map).cast<String, dynamic>()),
        ],
        game: json['game'] == null
            ? null
            : GameSnapshot.decode((json['game'] as Map).cast<String, dynamic>()),
      );
}
