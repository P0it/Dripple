import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/word_card.dart';
import '../data/card_deck.dart';
import '../engine/grammar/grammar_engine.dart';
import '../engine/ai/ai_player.dart';

/// Outcome of a sentence submission, surfaced to the UI for the judgment
/// dialog.
class JudgmentResult {
  final bool isCorrect;
  final List<ValidationError> errors;
  final String playerName;
  final List<WordCard> sentence;

  const JudgmentResult({
    required this.isCorrect,
    this.errors = const [],
    required this.playerName,
    required this.sentence,
  });
}

class GameNotifier extends StateNotifier<GameState> {
  final GrammarEngine _grammarEngine;
  final Random _random;
  AIPlayer _aiPlayer;

  /// Whether the caller handed us an opponent to use.
  ///
  /// [startGame] builds one from the chosen difficulty, which silently threw
  /// away anything a test had passed in — including its seeded [Random], so a
  /// test that looked like it played the same twenty games every run was in
  /// fact playing twenty different ones.
  final bool _aiPlayerIsInjected;

  /// Disabled in tests so turns can be stepped deterministically.
  final bool autoRunAI;

  /// Pause before each AI action, so a child can see what happened.
  final Duration aiTurnDelay;

  Timer? _turnTimer;
  int _timerGeneration = 0;
  bool _isProcessingAI = false;

  GameNotifier({
    GrammarEngine? grammarEngine,
    AIPlayer? aiPlayer,
    Random? random,
    this.autoRunAI = true,
    this.aiTurnDelay = const Duration(milliseconds: 700),
  })  : _grammarEngine = grammarEngine ?? GrammarEngine(),
        _aiPlayer = aiPlayer ?? AIPlayer(),
        _aiPlayerIsInjected = aiPlayer != null,
        _random = random ?? Random(),
        super(const GameState());

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  bool get isProcessingAI => _isProcessingAI;

  /// Test-only escape hatch for setting up specific board states.
  void debugSetState(GameState s) => state = s;

  // -------------------------------------------------------------------------
  // Setup
  // -------------------------------------------------------------------------

  void startGame(GameConfig config) {
    _isProcessingAI = false;
    if (!_aiPlayerIsInjected) {
      _aiPlayer = AIPlayer(difficulty: config.difficulty);
    }

    final deck = CardDeck().generate()..shuffle(_random);
    final (hands, remaining) = CardDeck.dealGuaranteedHands(
      deck: deck,
      playerCount: config.playerCount,
      handSize: config.initialHandSize,
    );

    final players = <Player>[
      Player(id: 'human_0', name: 'You', hand: hands[0]),
      for (int i = 1; i < config.playerCount; i++)
        Player(id: 'ai_$i', name: 'AI $i', isAI: true, hand: hands[i]),
    ];

    final workingDeck = List<WordCard>.from(remaining);
    // Open one card face up to seed the discard pile.
    final opener = workingDeck.removeLast();

    state = GameState(
      phase: GamePhase.playing,
      turnPhase: TurnPhase.draw,
      players: players,
      deck: workingDeck,
      discardPile: [opener],
      currentPlayerIndex: 0,
      config: config,
    );

    _startTurnTimer();
    if (autoRunAI) unawaited(_runAITurnsIfNeeded());
  }

  /// Deal the scripted one-player board the tutorial is taught on.
  ///
  /// A guided lesson laid over a real game would be a test, not a lesson: the
  /// hand is random, so there is no promise a playable sentence is in it, and
  /// a beginner asked to find one that may not exist learns only that the
  /// game is broken. Dealing the board instead means every instruction can be
  /// followed.
  ///
  /// There are no opponents. Everything the lesson teaches — the two piles,
  /// sorting a hand, building a sentence — happens inside one turn, so an
  /// opponent would add waiting and teach nothing.
  void startTutorial() {
    _isProcessingAI = false;
    _cancelTurnTimer();

    final setup = CardDeck.tutorialSetup();

    state = GameState(
      phase: GamePhase.playing,
      turnPhase: TurnPhase.draw,
      players: [Player(id: 'human_0', name: 'You', hand: setup.hand)],
      deck: setup.deck,
      discardPile: setup.discard,
      currentPlayerIndex: 0,
      config: const GameConfig(playerCount: 1, initialHandSize: 3),
    );
  }

  // -------------------------------------------------------------------------
  // Draw phase
  // -------------------------------------------------------------------------

  void drawFromDeck() {
    if (state.phase != GamePhase.playing) return;
    if (state.turnPhase != TurnPhase.draw) return;

    var working = state;
    if (working.deck.isEmpty) {
      if (working.deckRecycleCount >= 2) {
        _endGameOnExhaustion();
        return;
      }
      working = _recycleDiscardIntoDeck(working);
      if (working.deck.isEmpty) {
        _endGameOnExhaustion();
        return;
      }
    }

    final newDeck = List<WordCard>.from(working.deck);
    final drawn = newDeck.removeLast();

    final players = List<Player>.from(working.players);
    final me = players[working.currentPlayerIndex];
    players[working.currentPlayerIndex] = me.copyWith(hand: [...me.hand, drawn]);

    state = working.copyWith(
      players: players,
      deck: newDeck,
      turnPhase: TurnPhase.action,
    );
  }

  void drawFromDiscard() {
    if (state.phase != GamePhase.playing) return;
    if (state.turnPhase != TurnPhase.draw) return;
    if (state.discardPile.isEmpty) return;

    final newPile = List<WordCard>.from(state.discardPile);
    final taken = newPile.removeLast();

    final players = List<Player>.from(state.players);
    final me = players[state.currentPlayerIndex];
    players[state.currentPlayerIndex] = me.copyWith(hand: [...me.hand, taken]);

    state = state.copyWith(
      players: players,
      discardPile: newPile,
      turnPhase: TurnPhase.action,
      drawnFromDiscardCardId: taken.id,
    );
  }

  /// Shuffle the discard pile (minus its top card) back into the deck.
  GameState _recycleDiscardIntoDeck(GameState s) {
    if (s.discardPile.length <= 1) return s;

    final pile = List<WordCard>.from(s.discardPile);
    final top = pile.removeLast();
    pile.shuffle(_random);

    return s.copyWith(
      deck: pile,
      discardPile: [top],
      deckRecycleCount: s.deckRecycleCount + 1,
    );
  }

  // -------------------------------------------------------------------------
  // Turn timer
  // -------------------------------------------------------------------------

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;

    final seconds = state.config.turnTimerSeconds;
    if (seconds <= 0 || state.currentPlayer.isAI) {
      if (state.turnTimeRemaining != -1) {
        state = state.copyWith(turnTimeRemaining: -1);
      }
      return;
    }

    state = state.copyWith(turnTimeRemaining: seconds);
    final generation = ++_timerGeneration;

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || generation != _timerGeneration) return;
      if (state.phase != GamePhase.playing) {
        _turnTimer?.cancel();
        return;
      }
      final next = state.turnTimeRemaining - 1;
      if (next <= 0) {
        _turnTimer?.cancel();
        _forfeitTurn();
      } else {
        state = state.copyWith(turnTimeRemaining: next);
      }
    });
  }

  void _cancelTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
    _timerGeneration++;
    if (state.turnTimeRemaining != -1) {
      state = state.copyWith(turnTimeRemaining: -1);
    }
  }

  /// Timer expiry: return sentence-zone cards to hand and end the turn.
  void _forfeitTurn() {
    if (state.phase != GamePhase.playing) return;
    endTurn();
  }

  // -------------------------------------------------------------------------
  // Sentence zone editing (free-form — a child who gets stuck must be able
  // to back out of any arrangement, not just undo the last card)
  // -------------------------------------------------------------------------

  /// Stages a hand card into the sentence.
  ///
  /// [insertAt] is where in the sentence it lands; omitted (a tap rather than
  /// a drag) it goes to the tail.
  void placeCard(int handIndex, {int? insertAt}) {
    if (state.phase != GamePhase.playing) return;
    final me = state.currentPlayer;
    if (handIndex < 0 || handIndex >= me.hand.length) return;

    final card = me.hand[handIndex];
    // JUMP and STEAL are actions, not words.
    if (card.type == CardType.jump || card.type == CardType.steal) return;

    final hand = List<WordCard>.from(me.hand)..removeAt(handIndex);
    final zone = List<WordCard>.from(me.sentenceZone)
      ..insert((insertAt ?? me.sentenceZone.length).clamp(0, me.sentenceZone.length), card);
    _updateCurrentPlayer(me.copyWith(hand: hand, sentenceZone: zone));
  }

  void removeFromSentence(int sentenceIndex) {
    if (state.phase != GamePhase.playing) return;
    final me = state.currentPlayer;
    if (sentenceIndex < 0 || sentenceIndex >= me.sentenceZone.length) return;

    final zone = List<WordCard>.from(me.sentenceZone);
    final card = zone.removeAt(sentenceIndex);
    _updateCurrentPlayer(
      me.copyWith(hand: [...me.hand, card], sentenceZone: zone),
    );
  }

  /// Move a held card to another place on the rail.
  ///
  /// Purely cosmetic — the hand is a set, and nothing in the rules reads its
  /// order. It exists because a player sorting their hand is half of holding
  /// one, and because a fan whose cards can be pushed forward but not slid
  /// sideways reads as a fan that is stuck.
  void reorderHand(int from, int to) {
    if (state.phase != GamePhase.playing) return;
    final me = state.currentPlayer;
    final hand = List<WordCard>.from(me.hand);
    if (from < 0 || from >= hand.length) return;
    if (to < 0 || to >= hand.length) return;
    if (from == to) return;

    final card = hand.removeAt(from);
    hand.insert(to, card);
    _updateCurrentPlayer(me.copyWith(hand: hand));
  }

  void reorderSentence(int from, int to) {
    if (state.phase != GamePhase.playing) return;
    final me = state.currentPlayer;
    final zone = List<WordCard>.from(me.sentenceZone);
    if (from < 0 || from >= zone.length) return;
    if (to < 0 || to >= zone.length) return;
    if (from == to) return;

    final card = zone.removeAt(from);
    zone.insert(to, card);
    _updateCurrentPlayer(me.copyWith(sentenceZone: zone));
  }

  // -------------------------------------------------------------------------
  // Action phase
  // -------------------------------------------------------------------------

  /// Validate the sentence zone. On success the cards leave the hand for
  /// good and the turn ends. On failure the cards return to hand and the
  /// turn continues — failure must not cost a child their turn.
  JudgmentResult submitSentence() {
    final me = state.currentPlayer;
    final submitted = List<WordCard>.from(me.sentenceZone);

    if (state.phase != GamePhase.playing ||
        state.turnPhase != TurnPhase.action) {
      return JudgmentResult(
        isCorrect: false,
        playerName: me.name,
        sentence: submitted,
      );
    }

    final result = _grammarEngine.validate(submitted);

    if (!result.isValid) {
      _updateCurrentPlayer(me.copyWith(
        hand: [...me.hand, ...submitted],
        sentenceZone: const [],
      ));
      return JudgmentResult(
        isCorrect: false,
        errors: result.errors,
        playerName: me.name,
        sentence: submitted,
      );
    }

    _updateCurrentPlayer(me.copyWith(sentenceZone: const []));

    final judgment = JudgmentResult(
      isCorrect: true,
      playerName: me.name,
      sentence: submitted,
    );

    if (state.currentPlayer.hand.isEmpty) {
      _endGame(winnerIndex: state.currentPlayerIndex);
    } else {
      endTurn();
    }
    return judgment;
  }

  /// End the turn holding everything you drew.
  ///
  /// Only a completed sentence takes cards out of a hand for good, so a player
  /// who draws one card and throws one away every turn holds the same number
  /// of cards forever and can never finish. Keeping the card is what breaks
  /// that loop: the hand grows, and a bigger hand is what a long sentence is
  /// made of. Discarding is the move for a card you do not want, not the toll
  /// you pay to end a turn.
  ///
  /// Available only after the draw. Passing before it would leave the board
  /// in exactly the state it started the turn in, which is a turn that has
  /// not happened.
  bool passTurn() {
    if (state.phase != GamePhase.playing) return false;
    if (state.turnPhase != TurnPhase.action) return false;
    endTurn();
    return true;
  }

  /// Discard one card face up. Returns false if the discard is illegal.
  bool discardCard(int handIndex) {
    if (state.phase != GamePhase.playing) return false;
    if (state.turnPhase != TurnPhase.action) return false;

    final me = state.currentPlayer;
    if (handIndex < 0 || handIndex >= me.hand.length) return false;

    final card = me.hand[handIndex];
    // Rummy: the card you just took from the pile cannot go straight back.
    if (card.id == state.drawnFromDiscardCardId) return false;

    final hand = List<WordCard>.from(me.hand)..removeAt(handIndex);
    final players = List<Player>.from(state.players);
    players[state.currentPlayerIndex] = me.copyWith(hand: hand);

    state = state.copyWith(
      players: players,
      discardPile: [...state.discardPile, card],
    );

    if (hand.isEmpty) {
      _endGame(winnerIndex: state.currentPlayerIndex);
    } else {
      endTurn();
    }
    return true;
  }

  /// JUMP: skip the next player's turn. Costs the turn's single action.
  bool playJump(int handIndex) {
    if (state.phase != GamePhase.playing) return false;
    if (state.turnPhase != TurnPhase.action) return false;

    final me = state.currentPlayer;
    if (handIndex < 0 || handIndex >= me.hand.length) return false;
    if (me.hand[handIndex].type != CardType.jump) return false;

    final hand = List<WordCard>.from(me.hand)..removeAt(handIndex);
    _updateCurrentPlayer(me.copyWith(hand: hand));

    if (hand.isEmpty) {
      _endGame(winnerIndex: state.currentPlayerIndex);
      return true;
    }
    endTurn(skip: 1);
    return true;
  }

  /// STEAL: take one random card from [targetPlayerIndex] and give them one
  /// card of your choosing. Opponent hands are hidden, so the player picks
  /// the victim, not the card.
  ///
  /// [giveCardIndex] indexes the hand *after* the STEAL card is removed.
  bool playSteal(
    int handIndex, {
    required int targetPlayerIndex,
    required int giveCardIndex,
  }) {
    if (state.phase != GamePhase.playing) return false;
    if (state.turnPhase != TurnPhase.action) return false;
    if (targetPlayerIndex == state.currentPlayerIndex) return false;
    if (targetPlayerIndex < 0 || targetPlayerIndex >= state.players.length) {
      return false;
    }

    final me = state.currentPlayer;
    if (handIndex < 0 || handIndex >= me.hand.length) return false;
    if (me.hand[handIndex].type != CardType.steal) return false;

    final target = state.players[targetPlayerIndex];
    if (target.hand.isEmpty) return false;

    final handAfterSteal = List<WordCard>.from(me.hand)..removeAt(handIndex);
    if (giveCardIndex < 0 || giveCardIndex >= handAfterSteal.length) {
      return false;
    }

    final stolenIndex = _random.nextInt(target.hand.length);
    final stolen = target.hand[stolenIndex];
    final given = handAfterSteal[giveCardIndex];

    final myHand = List<WordCard>.from(handAfterSteal)
      ..removeAt(giveCardIndex)
      ..add(stolen);
    final targetHand = List<WordCard>.from(target.hand)
      ..removeAt(stolenIndex)
      ..add(given);

    final players = List<Player>.from(state.players);
    players[state.currentPlayerIndex] = me.copyWith(hand: myHand);
    players[targetPlayerIndex] = target.copyWith(hand: targetHand);

    state = state.copyWith(players: players);

    if (myHand.isEmpty) {
      _endGame(winnerIndex: state.currentPlayerIndex);
      return true;
    }
    endTurn();
    return true;
  }

  // -------------------------------------------------------------------------
  // Turn advance / game end
  // -------------------------------------------------------------------------

  /// Advance to [skip]+1 players ahead. JUMP passes skip: 1.
  void endTurn({int skip = 0}) {
    if (state.phase != GamePhase.playing) return;
    _cancelTurnTimer();

    // Any cards left staged in the sentence zone go back to hand.
    final me = state.currentPlayer;
    var working = state;
    if (me.sentenceZone.isNotEmpty) {
      final players = List<Player>.from(working.players);
      players[working.currentPlayerIndex] = me.copyWith(
        hand: [...me.hand, ...me.sentenceZone],
        sentenceZone: const [],
      );
      working = working.copyWith(players: players);
    }

    final next =
        (working.currentPlayerIndex + 1 + skip) % working.players.length;

    state = working
        .clearDrawnFromDiscard()
        .copyWith(currentPlayerIndex: next, turnPhase: TurnPhase.draw);

    _startTurnTimer();
    if (autoRunAI) unawaited(_runAITurnsIfNeeded());
  }

  void _endGame({required int winnerIndex}) {
    _cancelTurnTimer();
    state = state.copyWith(
      phase: GamePhase.gameEnd,
      winnerIndex: winnerIndex,
    );
  }

  /// Anti-stalling: after two recycles the deck running dry ends the game,
  /// and the player holding the fewest cards wins.
  void _endGameOnExhaustion() {
    final winnerId = state.ranking.first.id;
    _endGame(winnerIndex: state.players.indexWhere((p) => p.id == winnerId));
  }

  // -------------------------------------------------------------------------
  // AI turn driving
  // -------------------------------------------------------------------------

  Future<void> _runAITurnsIfNeeded() async {
    if (state.phase != GamePhase.playing) return;
    if (!state.currentPlayer.isAI) return;
    await runAITurns();
  }

  /// Drive every consecutive AI turn until control returns to a human or
  /// the game ends.
  ///
  /// This lives in the notifier, not the screen. When the UI owned it, any
  /// turn advance the UI did not initiate — a timer expiry, a JUMP — left
  /// nobody to run the AI and the game froze.
  Future<List<JudgmentResult>> runAITurns() async {
    if (_isProcessingAI) return const [];
    _isProcessingAI = true;

    final results = <JudgmentResult>[];
    try {
      // Runaway backstop only. It must sit well above any turn count the
      // rules can legitimately produce: with four players drawing and
      // discarding, the deck takes ~80 turns to empty and the anti-stalling
      // rule needs two recycles before it fires, so a real game can run past
      // 240 turns. A tighter bound here silently left the game hung.
      var guard = 0;
      while (state.phase == GamePhase.playing &&
          state.currentPlayer.isAI &&
          guard++ < 5000) {
        if (aiTurnDelay > Duration.zero) {
          await Future<void>.delayed(aiTurnDelay);
        }
        if (!mounted) break;
        final result = _executeOneAITurn();
        if (result != null) results.add(result);
      }
    } finally {
      _isProcessingAI = false;
    }
    return results;
  }

  /// One complete AI turn: mandatory draw, then a single action.
  JudgmentResult? _executeOneAITurn() {
    final startIndex = state.currentPlayerIndex;

    // --- Draw phase ---
    if (state.turnPhase == TurnPhase.draw) {
      final top = state.discardTop;
      final wantsDiscard = top != null &&
          _aiPlayer.findSentence(state.currentPlayer.hand) == null &&
          _aiPlayer.findSentence([...state.currentPlayer.hand, top]) != null;
      if (wantsDiscard) {
        drawFromDiscard();
      } else {
        drawFromDeck();
      }
    }
    if (state.phase != GamePhase.playing) return null;
    if (state.currentPlayerIndex != startIndex) return null;

    // --- Action phase ---
    final me = state.currentPlayer;
    final action = _aiPlayer.decideAction(me, state);

    switch (action.type) {
      case AIActionType.submitSentence:
        for (final card in action.cards!) {
          final idx =
              state.currentPlayer.hand.indexWhere((c) => c.id == card.id);
          if (idx >= 0) placeCard(idx);
        }
        return submitSentence();

      case AIActionType.playJump:
        final idx = me.hand.indexWhere((c) => c.id == action.specialCard!.id);
        if (idx >= 0 && playJump(idx)) return null;

      case AIActionType.playSteal:
        final idx = me.hand.indexWhere((c) => c.id == action.specialCard!.id);
        if (idx >= 0 &&
            playSteal(
              idx,
              targetPlayerIndex: action.targetPlayerIndex!,
              giveCardIndex: action.giveCardIndex!,
            )) {
          return null;
        }

      case AIActionType.discard:
        if (discardCard(action.discardIndex!)) return null;

      case AIActionType.pass:
        if (passTurn()) return null;
    }

    // Fallback: the chosen action was rejected. Passing always ends a turn
    // that has had its draw, so the loop cannot spin; try to shed a card
    // first, since a turn that costs nothing gets the AI no closer to
    // winning.
    final hand = state.currentPlayer.hand;
    for (int i = 0; i < hand.length; i++) {
      if (discardCard(i)) return null;
    }
    if (passTurn()) return null;
    endTurn();
    return null;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _updateCurrentPlayer(Player updated) {
    final players = List<Player>.from(state.players);
    players[state.currentPlayerIndex] = updated;
    state = state.copyWith(players: players);
  }

}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
