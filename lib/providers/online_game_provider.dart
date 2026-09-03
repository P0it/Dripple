import 'dart:async';

import 'package:collection/collection.dart';
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

  /// Cards this player has pushed forward into a sentence but not yet
  /// submitted, by id and in the order they were laid out.
  ///
  /// The server does not know about these and should not: building a sentence
  /// moves cards around inside one hand and changes nothing anybody else can
  /// see. Only the finished sentence is sent.
  final List<String> staged;

  /// The order this player has slid their held cards into, by id.
  ///
  /// Local for the same reason [staged] is: sorting a hand changes nothing
  /// anybody else can see, and nothing in the rules reads the order. Keeping
  /// it here rather than asking the server is also what lets a player arrange
  /// a sentence in the fan while somebody else is taking their turn, which is
  /// most of the time they spend doing it.
  ///
  /// Ids the server has dealt since are not in here; they fall in at the end.
  final List<String> handOrder;

  const OnlineState({
    this.room,
    this.error,
    this.judgment,
    this.busy = false,
    this.staged = const [],
    this.handOrder = const [],
  });

  /// The board as it should be drawn: the server's game, with the cards this
  /// player has pushed forward moved out of the hand and into the sentence.
  GameState? get game {
    final served = room?.game;
    if (served == null) return served;
    if (staged.isEmpty && handOrder.isEmpty) return served;

    final me = served.me;
    final staging = <WordCard>[];
    for (final id in staged) {
      final card = me.hand.where((c) => c.id == id).firstOrNull;
      if (card != null) staging.add(card);
    }
    final served0 = [
      for (final c in me.hand)
        if (!staged.contains(c.id)) c,
    ];
    // Sorted ids first, in the order the player put them, then anything dealt
    // since in the order the server gave it. Built rather than sorted: with an
    // empty [handOrder] every card ranks equal, and `List.sort` is not stable,
    // so sorting would shuffle a hand nobody had touched.
    final held = [
      for (final id in handOrder)
        ...served0.where((c) => c.id == id),
      for (final c in served0)
        if (!handOrder.contains(c.id)) c,
    ];

    final players = [...served.players];
    players[served.mySeatIndex] =
        me.copyWith(hand: held, sentenceZone: staging);
    return served.copyWith(players: players);
  }



  bool get isMyTurn => room?.game?.isMyTurn ?? false;

  OnlineState copyWith({
    RoomView? room,
    OnlineError? error,
    Judgment? judgment,
    bool? busy,
    List<String>? staged,
    List<String>? handOrder,
    bool clearError = false,
    bool clearJudgment = false,
  }) =>
      OnlineState(
        room: room ?? this.room,
        error: clearError ? null : (error ?? this.error),
        judgment: clearJudgment ? null : (judgment ?? this.judgment),
        busy: busy ?? this.busy,
        staged: staged ?? this.staged,
        handOrder: handOrder ?? this.handOrder,
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

  /// Push a held card forward into the sentence.
  ///
  /// Local only, and instant: nothing anybody else can see has changed, so
  /// there is nothing to wait for. [insertAt] drops it into the line rather
  /// than at the end.
  void placeCard(int handIndex, {int? insertAt}) {
    final game = state.game;
    if (game == null || !state.isMyTurn) return;
    if (handIndex < 0 || handIndex >= game.me.hand.length) return;

    final staged = [...state.staged];
    final id = game.me.hand[handIndex].id;
    final at = insertAt == null ? staged.length : insertAt.clamp(0, staged.length);
    staged.insert(at, id);
    state = state.copyWith(staged: staged);
  }

  /// Take a card back out of the sentence.
  void removeFromSentence(int index) {
    if (index < 0 || index >= state.staged.length) return;
    state = state.copyWith(staged: [...state.staged]..removeAt(index));
  }

  /// The player's own order for their own cards, carried across a reply.
  ///
  /// A reply is the new truth about *what* is in the hand, and says nothing
  /// about how the player has arranged it — so the arrangement survives, minus
  /// any card that has since left. Without this, every poll rebuilt the state
  /// from scratch and a sorted hand snapped back to the server's order within
  /// the polling interval.
  List<String> _handOrderStillValid(RoomView room) {
    final hand = room.game?.me.hand;
    if (hand == null) return const [];
    final ids = hand.map((c) => c.id).toSet();
    return [
      for (final id in state.handOrder)
        if (ids.contains(id)) id,
    ];
  }

  /// Slide a held card along the rail. Answered here and never sent: it is
  /// this player's own view of their own hand.
  void reorderHand(int from, int to) {
    final hand = state.game?.me.hand;
    if (hand == null) return;
    if (from < 0 || from >= hand.length) return;
    if (to < 0 || to >= hand.length) return;
    if (from == to) return;

    final ids = hand.map((c) => c.id).toList();
    final id = ids.removeAt(from);
    ids.insert(to, id);
    state = state.copyWith(handOrder: ids);
  }

  void reorderSentence(int from, int to) {
    final staged = [...state.staged];
    if (from < 0 || from >= staged.length) return;
    final card = staged.removeAt(from);
    staged.insert(to.clamp(0, staged.length), card);
    state = state.copyWith(staged: staged);
  }

  /// Send the sentence as it stands.
  Future<void> submitStaged() async {
    if (state.staged.isEmpty) return;
    await _run(() => _client.submit(roomId, state.staged));
  }

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

  /// Keep the sentence being built across a poll that changed nothing about
  /// this hand, and drop it the moment the hand itself moved. Otherwise a
  /// poll arriving mid-build would sweep the cards back off the table.
  List<String> _stagingStillValid(RoomView room) {
    if (state.staged.isEmpty) return const [];
    if (room.judgment != null) return const [];
    final hand = room.game?.me.hand;
    if (hand == null) return const [];
    final held = {for (final c in hand) c.id};
    return state.staged.every(held.contains) ? state.staged : const [];
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
      // A reply is the new truth, and staging is not part of it. Cards that
      // were played are gone from the hand; cards from a rejected sentence
      // are back in it, which is where a rejected sentence belongs.
      state = OnlineState(
        room: room,
        judgment: room.judgment,
        staged: _stagingStillValid(room),
        handOrder: _handOrderStillValid(room),
      );
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
