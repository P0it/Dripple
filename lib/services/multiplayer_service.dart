import 'dart:async';
import '../character/emote_system.dart';
import '../models/game_state.dart' show TurnAction;

/// Game room state synced between players
class GameRoom {
  final String roomId;
  final String hostId;
  final List<OnlinePlayer> players;
  final GameRoomStatus status;
  final int maxPlayers;

  const GameRoom({
    required this.roomId,
    required this.hostId,
    this.players = const [],
    this.status = GameRoomStatus.waiting,
    this.maxPlayers = 4,
  });

  bool get isFull => players.length >= maxPlayers;
  bool get canStart => players.length >= 2;
}

enum GameRoomStatus { waiting, playing, finished }

class OnlinePlayer {
  final String id;
  final String name;
  final bool isReady;

  const OnlinePlayer({
    required this.id,
    required this.name,
    this.isReady = false,
  });
}

/// Turn data synced via Firebase Realtime DB
class TurnData {
  final String playerId;
  final TurnAction action;
  final int? cardIndex;
  final int? targetPlayerIndex;
  final List<String>? sentenceCardIds;

  const TurnData({
    required this.playerId,
    required this.action,
    this.cardIndex,
    this.targetPlayerIndex,
    this.sentenceCardIds,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'action': action.name,
        'cardIndex': cardIndex,
        'targetPlayerIndex': targetPlayerIndex,
        'sentenceCardIds': sentenceCardIds,
      };

  factory TurnData.fromJson(Map<String, dynamic> json) => TurnData(
        playerId: json['playerId'] as String,
        action: TurnAction.values.byName(json['action'] as String),
        cardIndex: json['cardIndex'] as int?,
        targetPlayerIndex: json['targetPlayerIndex'] as int?,
        sentenceCardIds: (json['sentenceCardIds'] as List?)?.cast<String>(),
      );
}

/// Abstract multiplayer service interface.
/// Implement with Firebase Realtime DB for production.
abstract class MultiplayerService {
  /// Create a new game room
  Future<GameRoom> createRoom({required int maxPlayers});

  /// Join an existing room by code
  Future<GameRoom?> joinRoom(String roomCode);

  /// Join random matchmaking queue
  Future<GameRoom?> joinMatchmaking({required int playerCount});

  /// Leave current room
  Future<void> leaveRoom(String roomId);

  /// Listen for room state changes
  Stream<GameRoom> watchRoom(String roomId);

  /// Send a turn action to all players
  Future<void> sendTurn(String roomId, TurnData turn);

  /// Listen for turn actions from other players
  Stream<TurnData> watchTurns(String roomId);

  /// Send an emote to all players
  Future<void> sendEmote(String roomId, EmoteEvent emote);

  /// Listen for emotes from other players
  Stream<EmoteEvent> watchEmotes(String roomId);

  /// Start the game (host only)
  Future<void> startGame(String roomId);

  /// Get a shareable room invite code/link
  String getInviteCode(String roomId);
}

/// Firebase Realtime Database structure:
///
/// ```
/// rooms/{roomId}/
///   ├── host: "userId"
///   ├── status: "waiting" | "playing" | "finished"
///   ├── maxPlayers: 4
///   ├── players/
///   │   ├── {playerId}/
///   │   │   ├── name: "Player 1"
///   │   │   ├── isReady: true
///   │   │   └── hand: [...cardIds]
///   ├── deck: [...cardIds]
///   ├── currentTurn: 0
///   ├── currentRound: 1
///   ├── turns/
///   │   └── {timestamp}: { playerId, action, cardIndex, ... }
///   └── emotes/
///       └── {timestamp}: { playerId, emoteType }
///
/// matchmaking/
///   ├── queue2/ (2-player queue)
///   │   └── {playerId}: { name, timestamp }
///   ├── queue3/
///   └── queue4/
/// ```
