import 'dart:math';

import 'package:dripple_rules/engine/game_engine.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/player.dart';
import 'package:dripple_rules/models/word_card.dart';

import 'actions.dart';
import 'errors.dart';
import 'room.dart';
import 'room_code.dart';
import 'room_store.dart';

/// What came back from an action: the room as it now stands, and — when a
/// sentence was played — how it was judged.
class ActionOutcome {
  final Room room;
  final JudgmentResult? judgment;

  const ActionOutcome({required this.room, this.judgment});
}

/// The authority for online games.
///
/// It owns the two things no player may hold: the order of the deck, and
/// everybody's hand. It judges sentences with [GameNotifier] — the same code
/// the app plays by — so there is one implementation of the rules, not two
/// that drift.
///
/// Nothing is held between calls. Each one reads the room, applies exactly one
/// change, and writes it back against the version it read.
class GameService {
  final RoomStore _store;
  final Random _random;
  final DateTime Function() _now;

  /// How many times a write may lose a race before the caller is told to
  /// retry. Losing twice in a row means real contention, not a hiccup.
  static const _maxWriteAttempts = 3;

  GameService({
    required RoomStore store,
    Random? random,
    DateTime Function()? clock,
  })  : _store = store,
        _random = random ?? Random.secure(),
        _now = clock ?? DateTime.now;

  // ---------------------------------------------------------------------
  // Lobby
  // ---------------------------------------------------------------------

  Future<Room> createRoom({
    required String uid,
    required String name,
    int maxPlayers = 4,
  }) async {
    for (var attempt = 0; attempt < _maxWriteAttempts; attempt++) {
      final code = RoomCode.generate(_random);
      final room = Room(
        id: 'room_${code}_${_now().millisecondsSinceEpoch}',
        code: code,
        hostUid: uid,
        seats: [
          Seat(uid: uid, name: name, kind: SeatKind.human),
          for (var i = 1; i < maxPlayers; i++) const Seat(),
        ],
      );
      if (await _store.create(room)) return room;
    }
    throw const GameError('code_collision', 'could not allocate a room code');
  }

  Future<Room> joinRoom({
    required String code,
    required String uid,
    required String name,
  }) =>
      _mutateByCode(code, (room) {
        if (room.status != RoomStatus.lobby) throw GameError.alreadyStarted;

        // Rejoining is not a second seat. Somebody who backgrounded the app
        // and came back must land where they were sitting.
        final existing = room.seatOf(uid);
        if (existing >= 0) {
          return room.copyWith(
            seats: _replaceSeat(room.seats, existing,
                room.seats[existing].copyWith(name: name, connected: true)),
          );
        }

        final free = room.seats.indexWhere((s) => s.isEmpty);
        if (free < 0) throw GameError.roomFull;
        return room.copyWith(
          seats: _replaceSeat(
            room.seats,
            free,
            Seat(uid: uid, name: name, kind: SeatKind.human),
          ),
        );
      });

  Future<Room> setReady({
    required String roomId,
    required String uid,
    required bool ready,
  }) =>
      _mutate(roomId, (room) {
        final seat = _requireSeat(room, uid);
        return room.copyWith(
          seats: _replaceSeat(
              room.seats, seat, room.seats[seat].copyWith(ready: ready)),
        );
      });

  Future<Room> setConnected({
    required String roomId,
    required String uid,
    required bool connected,
  }) =>
      _mutate(roomId, (room) {
        final seat = _requireSeat(room, uid);
        return room.copyWith(
          seats: _replaceSeat(room.seats, seat,
              room.seats[seat].copyWith(connected: connected)),
        );
      });

  /// Leave. Before the deal this frees the seat; after it the seat plays on as
  /// a bot, because the remaining players' game should not collapse because
  /// somebody's train went into a tunnel.
  Future<Room> leaveRoom({
    required String roomId,
    required String uid,
  }) =>
      _mutate(roomId, (room) {
        final seat = _requireSeat(room, uid);

        if (room.status == RoomStatus.lobby) {
          final seats = _replaceSeat(room.seats, seat, const Seat());
          return _rehost(room.copyWith(seats: seats), leaving: uid);
        }

        // Mid-game the uid stays on the seat: it is how they get their own
        // cards back rather than a stranger's if they come back.
        final seats = _replaceSeat(
          room.seats,
          seat,
          room.seats[seat].copyWith(kind: SeatKind.bot, connected: false),
        );
        var updated = _rehost(room.copyWith(seats: seats), leaving: uid);
        final game = updated.game;
        if (game != null) {
          final players = [...game.players];
          players[seat] = Player(
            id: players[seat].id,
            name: players[seat].name,
            isAI: true,
            hand: players[seat].hand,
            sentenceZone: players[seat].sentenceZone,
            score: players[seat].score,
          );
          updated = updated.copyWith(game: game.copyWith(players: players));
        }
        return updated;
      });

  /// Deal. Only the host, and only with two or more at the table.
  Future<Room> startGame({
    required String roomId,
    required String uid,
    int turnTimerSeconds = 0,
  }) =>
      _mutate(roomId, (room) {
        if (room.status != RoomStatus.lobby) throw GameError.alreadyStarted;
        if (room.hostUid != uid) throw GameError.notHost;
        if (!room.canStart) throw GameError.notEnoughPlayers;

        // Empty seats are dropped rather than filled with bots: the rules run
        // at any player count, so two friends play a two-handed game instead
        // of a four-handed one with two strangers who are not there.
        final taken = room.seats.where((s) => !s.isEmpty).toList();
        final engine = GameNotifier(autoRunAI: false, random: _random);
        engine.startGame(
          GameConfig(
            playerCount: taken.length,
            turnTimerSeconds: turnTimerSeconds,
          ),
          seats: [
            for (final s in taken)
              SeatAssignment(
                id: s.uid.isEmpty ? 'bot_${taken.indexOf(s)}' : s.uid,
                name: s.name,
                isAI: s.kind == SeatKind.bot,
              ),
          ],
        );

        return room.copyWith(
          status: RoomStatus.playing,
          seats: taken,
          game: engine.snapshot,
          turnDeadlineMs: _deadlineFor(engine.snapshot),
        );
      });

  // ---------------------------------------------------------------------
  // Play
  // ---------------------------------------------------------------------

  /// Apply one action on behalf of [uid].
  Future<ActionOutcome> act({
    required String roomId,
    required String uid,
    required GameAction action,
  }) async {
    JudgmentResult? judgment;
    final room = await _mutate(roomId, (room) {
      final game = room.game;
      if (room.status != RoomStatus.playing || game == null) {
        throw GameError.notStarted;
      }
      final seat = _requireSeat(room, uid);

      final engine = GameNotifier(autoRunAI: false, random: _random)
        ..restore(_afterAnyExpiredTurn(room));

      if (engine.snapshot.currentPlayerIndex != seat) throw GameError.notYourTurn;

      judgment = _apply(engine, action);
      return room.copyWith(
        game: engine.snapshot,
        status: engine.snapshot.isGameOver ? RoomStatus.finished : null,
        turnDeadlineMs: _deadlineFor(engine.snapshot),
      );
    });
    return ActionOutcome(room: room, judgment: judgment);
  }

  /// Move the game on when nobody is going to act: a bot's turn, or a person
  /// who ran out of time. Clients poke this; the version check makes it
  /// harmless when several poke at once.
  Future<Room> tick(String roomId) => _mutate(roomId, (room) {
        final game = room.game;
        if (room.status != RoomStatus.playing || game == null) return room;

        final engine = GameNotifier(autoRunAI: false, random: _random)
          ..restore(_afterAnyExpiredTurn(room));
        engine.runOneAITurn();

        return room.copyWith(
          game: engine.snapshot,
          status: engine.snapshot.isGameOver ? RoomStatus.finished : null,
          turnDeadlineMs: _deadlineFor(engine.snapshot),
        );
      });

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  JudgmentResult? _apply(GameNotifier engine, GameAction action) {
    switch (action) {
      case DrawAction(:final fromDiscard):
        if (fromDiscard) {
          engine.drawFromDiscard();
        } else {
          engine.drawFromDeck();
        }
        return null;

      case SubmitAction(:final cardIds):
        // Lay the cards out in the order they were sent, then judge. A failed
        // submission costs nothing: the engine puts them back in hand.
        for (final id in cardIds) {
          final index = _handIndex(engine.snapshot, id);
          engine.placeCard(index);
        }
        return engine.submitSentence();

      case DiscardAction(:final cardId):
        engine.discardCard(_handIndex(engine.snapshot, cardId));
        return null;

      case PassAction():
        engine.passTurn();
        return null;

      case JumpAction(:final cardId):
        engine.playJump(_handIndex(engine.snapshot, cardId));
        return null;

      case StealAction(:final cardId, :final targetSeat, :final giveCardId):
        engine.playSteal(
          _handIndex(engine.snapshot, cardId),
          targetPlayerIndex: targetSeat,
          giveCardIndex: _handIndex(engine.snapshot, giveCardId),
        );
        return null;
    }
  }

  int _handIndex(GameState state, String cardId) {
    final index =
        state.currentPlayer.hand.indexWhere((WordCard c) => c.id == cardId);
    if (index < 0) throw GameError.noSuchCard;
    return index;
  }

  /// Forfeit the turn in play if its deadline has passed.
  ///
  /// The server runs no clock of its own — it is not there between requests —
  /// so an expired turn is noticed on the next request that touches the room,
  /// whoever sent it.
  GameState _afterAnyExpiredTurn(Room room) {
    final game = room.game!;
    final deadline = room.turnDeadlineMs;
    if (deadline == null) return game;
    if (_now().millisecondsSinceEpoch < deadline) return game;

    final engine = GameNotifier(autoRunAI: false, random: _random)
      ..restore(game);
    if (engine.snapshot.turnPhase == TurnPhase.draw) engine.drawFromDeck();
    if (!engine.passTurn()) engine.endTurn();
    return engine.snapshot;
  }

  int? _deadlineFor(GameState state) {
    final seconds = state.config.turnTimerSeconds;
    if (seconds <= 0) return null;
    if (state.phase != GamePhase.playing) return null;
    if (state.currentPlayer.isAI) return null;
    return _now().millisecondsSinceEpoch + seconds * 1000;
  }

  int _requireSeat(Room room, String uid) {
    final seat = room.seats.indexWhere((s) => s.uid == uid);
    if (seat < 0) throw GameError.notInRoom;
    return seat;
  }

  List<Seat> _replaceSeat(List<Seat> seats, int index, Seat seat) =>
      [...seats]..[index] = seat;

  /// Hand the host role on when the host leaves. The host is only whoever
  /// presses start — the server owns the game — so this is bookkeeping, not
  /// a transfer of authority.
  Room _rehost(Room room, {required String leaving}) {
    if (room.hostUid != leaving) return room;
    final next = room.seats.firstWhere(
      (s) => s.isHuman && s.uid != leaving,
      orElse: () => const Seat(),
    );
    return room.copyWith(hostUid: next.uid);
  }

  Future<Room> _mutate(String roomId, Room Function(Room) change) async {
    for (var attempt = 0; attempt < _maxWriteAttempts; attempt++) {
      final room = await _store.load(roomId);
      if (room == null) throw GameError.noSuchRoom;
      final updated = change(room);
      final next = updated.copyWith(version: room.version + 1);
      if (await _store.save(next, expectedVersion: room.version)) return next;
    }
    throw GameError.conflict;
  }

  Future<Room> _mutateByCode(String code, Room Function(Room) change) async {
    final roomId = await _store.roomIdForCode(RoomCode.normalize(code));
    if (roomId == null) throw GameError.noSuchRoom;
    return _mutate(roomId, change);
  }
}
