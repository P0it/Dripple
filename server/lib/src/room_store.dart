import 'room.dart';

/// Where rooms live between requests.
///
/// The server keeps nothing in memory — it scales to nothing when idle — so
/// every request reads a room, changes it, and writes it back. [save] is a
/// compare-and-set on [Room.version]: it returns false when somebody else
/// wrote first, and the caller reads again rather than clobbering them.
abstract class RoomStore {
  Future<Room?> load(String roomId);

  /// Create a room and bind its code. Fails if the code is already taken,
  /// which is how code collisions are resolved rather than by hoping.
  Future<bool> create(Room room);

  /// Write [room] back, but only if the stored version is [expectedVersion].
  Future<bool> save(Room room, {required int expectedVersion});

  Future<String?> roomIdForCode(String code);

  Future<void> delete(String roomId);
}

/// A store in a single process's memory.
///
/// This is what the tests run against, and it is deliberately the same class
/// the production store must behave like — every rule of the game is verified
/// here, so the Firebase store only has to be a correct key-value store, not
/// a correct game.
class InMemoryRoomStore implements RoomStore {
  final Map<String, Room> _rooms = {};
  final Map<String, String> _codes = {};

  @override
  Future<Room?> load(String roomId) async => _rooms[roomId];

  @override
  Future<bool> create(Room room) async {
    if (_codes.containsKey(room.code) || _rooms.containsKey(room.id)) {
      return false;
    }
    _rooms[room.id] = room;
    _codes[room.code] = room.id;
    return true;
  }

  @override
  Future<bool> save(Room room, {required int expectedVersion}) async {
    final current = _rooms[room.id];
    if (current == null || current.version != expectedVersion) return false;
    _rooms[room.id] = room;
    return true;
  }

  @override
  Future<String?> roomIdForCode(String code) async => _codes[code];

  @override
  Future<void> delete(String roomId) async {
    final room = _rooms.remove(roomId);
    if (room != null) _codes.remove(room.code);
  }
}
