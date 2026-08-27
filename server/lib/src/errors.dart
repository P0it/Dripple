/// Something the caller asked for that the rules do not allow.
///
/// The [code] is what the app switches on and what it looks up a message for,
/// so it is part of the wire contract; the message is for logs and for the
/// developer reading a failed request.
class GameError implements Exception {
  final String code;
  final String message;

  const GameError(this.code, this.message);

  /// The room code was never issued, or the room has since been cleaned up.
  static const noSuchRoom = GameError('no_such_room', 'no such room');

  /// Somebody tried to act in a room they are not sitting in.
  static const notInRoom = GameError('not_in_room', 'you are not in this room');

  static const roomFull = GameError('room_full', 'the room is full');

  static const alreadyStarted =
      GameError('already_started', 'the game has already started');

  static const notStarted = GameError('not_started', 'the game has not started');

  static const notEnoughPlayers =
      GameError('not_enough_players', 'two players are needed to start');

  /// The action was legal but it is somebody else's turn.
  static const notYourTurn = GameError('not_your_turn', 'it is not your turn');

  /// Only the host may deal.
  static const notHost = GameError('not_host', 'only the host can start');

  /// A card id that is not in the hand it was played from.
  static const noSuchCard = GameError('no_such_card', 'no such card in hand');

  /// The room moved on between the read and the write. The caller retries.
  static const conflict =
      GameError('conflict', 'the room changed; read it again');

  @override
  String toString() => 'GameError($code): $message';
}
