import 'dart:async';

import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/word_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/online_client.dart';

/// The board as this device currently believes it to be.
class OnlineState {
  /// Null until the first reply arrives.
  final RoomView? room;

  /// The last refusal, for the screen to show and then clear.
  final OnlineError? error;

  /// A sentence just judged. Cleared once shown.
  final Judgment? judgment;

  /// True while a request this player made is in flight, so the board can
  /// stop taking a second tap rather than sending it.
  final bool busy;

  const OnlineState({this.room, this.error, this.judgment, this.busy = false});

  GameState? get game => room?.game;
  bool get isMyTurn => room?.game?.isMyTurn ?? false;

  OnlineState copyWith({
    RoomView? room,
    OnlineError? error,
    Judgment? judgment,
    bool? busy,
    bool clearError = false,
    bool clearJudgment = false,
  }) =>
      OnlineState(
        room: room ?? this.room,
        error: clearError ? null : (error ?? this.error),
        judgment: clearJudgment ? null : (judgment ?? this.judgment),
        busy: busy ?? this.busy,
      );
}

/// Keeps one online game in step with the server.
///
/// The server is the authority, so this never guesses ahead: every action is
/// a request whose reply is the new truth. That costs a round trip on each
/// tap and buys never having to unwind a move the server did not allow.
///
/// Between taps it polls. A push channel is the better shape and is where
/// this is going, but polling is what works before there is one, and the
/// reconnect path needs a plain read either way.
class OnlineGameNotifier extends StateNotifier<OnlineState> {
  final OnlineClient _client;
  final String roomId;

  /// How often to ask when it is somebody else's move. Fast enough that a
  /// turn does not feel posted, slow enough not to hammer a free tier.
  final Duration pollInterval;

  /// How long to leave a bot's turn on screen before nudging it along, so a
  /// bot appears to think rather than to have already moved.
  final Duration botPause;

  Timer? _poller;
  bool _inFlight = false;

  OnlineGameNotifier({
    required OnlineClient client,
    required this.roomId,
    this.pollInterval = const Duration(milliseconds: 900),
    this.botPause = const Duration(milliseconds: 700),
  })  : _client = client,
        super(const OnlineState());

  Future<void> start() async {
    await _run(() => _client.readRoom(roomId));
    _poller = Timer.periodic(pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Lobby
  // ---------------------------------------------------------------------

  Future<void> setReady(bool ready) =>
      _run(() => _client.setReady(roomId, ready));

  Future<void> startGame({int turnTimerSeconds = 0}) => _run(
      () => _client.startGame(roomId, turnTimerSeconds: turnTimerSeconds));

  Future<void> leave() => _run(() => _client.leaveRoom(roomId));

  // ---------------------------------------------------------------------
  // Play
  // ---------------------------------------------------------------------

  Future<void> drawFromDeck() => _run(() => _client.draw(roomId));

  Future<void> drawFromDiscard() =>
      _run(() => _client.draw(roomId, fromDiscard: true));

  Future<void> submit(List<WordCard> sentence) =>
      _run(() => _client.submit(roomId, [for (final c in sentence) c.id]));

  Future<void> discard(WordCard card) =>
      _run(() => _client.discard(roomId, card.id));

  Future<void> pass() => _run(() => _client.pass(roomId));

  Future<void> playJump(WordCard card) =>
      _run(() => _client.jump(roomId, card.id));

  Future<void> playSteal({
    required WordCard card,
    required int targetSeat,
    required WordCard give,
  }) =>
      _run(() => _client.steal(
            roomId,
            cardId: card.id,
            targetSeat: targetSeat,
            giveCardId: give.id,
          ));

  void clearError() => state = state.copyWith(clearError: true);
  void clearJudgment() => state = state.copyWith(clearJudgment: true);

  // ---------------------------------------------------------------------

  /// One read, plus a nudge if the game is waiting on nobody.
  Future<void> _poll() async {
    if (_inFlight) return;
    final room = state.room;

    // A seat nobody is going to move — a bot, or a player who ran out of
    // time — needs somebody to say so. Any client may; the server's version
    // check settles who actually did it.
    if (room != null && room.isPlaying && _waitingOnNobody(room)) {
      await Future<void>.delayed(botPause);
      if (!mounted) return;
      await _run(() => _client.tick(roomId), quiet: true);
      return;
    }
    await _run(() => _client.readRoom(roomId), quiet: true);
  }

  bool _waitingOnNobody(RoomView room) {
    final game = room.game;
    if (game == null || game.phase != GamePhase.playing) return false;
    if (game.isMyTurn) return false;

    final seat = game.currentPlayerIndex;
    if (seat < 0 || seat >= room.seats.length) return false;
    if (room.seats[seat].kind == 'bot') return true;

    final deadline = room.turnDeadlineMs;
    return deadline != null &&
        DateTime.now().millisecondsSinceEpoch > deadline;
  }

  /// Send one request and make its reply the new truth.
  ///
  /// [quiet] is for polling: a poll that fails should not throw an error
  /// banner over a game that is still perfectly playable, because the next
  /// one a second later will probably succeed.
  Future<void> _run(
    Future<RoomView> Function() request, {
    bool quiet = false,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    if (!quiet) state = state.copyWith(busy: true, clearError: true);
    try {
      final room = await request();
      if (!mounted) return;
      state = OnlineState(room: room, judgment: room.judgment);
    } on OnlineError catch (e) {
      if (!mounted) return;
      state = quiet
          ? state.copyWith(busy: false)
          : state.copyWith(busy: false, error: e);
    } finally {
      _inFlight = false;
    }
  }
}
