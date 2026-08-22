import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/word_card.dart';
import '../data/card_deck.dart';
import '../engine/grammar/grammar_engine.dart';
import '../engine/ai/ai_player.dart';

/// Judgment result after sentence submission
class JudgmentResult {
  final bool isCorrect;
  final int scoreEarned;
  final List<ValidationError> errors;
  final String playerName;
  final List<WordCard> sentence;

  const JudgmentResult({
    required this.isCorrect,
    this.scoreEarned = 0,
    this.errors = const [],
    required this.playerName,
    required this.sentence,
  });
}

class GameNotifier extends StateNotifier<GameState> {
  final GrammarEngine _grammarEngine;
  // Mutable so startGame can recreate it with the chosen AIDifficulty.
  AIPlayer _aiPlayer;
  final Random _random;

  bool _isProcessingAI = false;
  Timer? _turnTimer;
  int _timerGeneration = 0;

  GameNotifier({
    GrammarEngine? grammarEngine,
    AIPlayer? aiPlayer,
    Random? random,
  })  : _grammarEngine = grammarEngine ?? GrammarEngine(),
        _aiPlayer = aiPlayer ?? AIPlayer(),
        _random = random ?? Random(),
        super(const GameState());

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  /// Whether AI turns are currently being processed
  bool get isProcessingAI => _isProcessingAI;

  /// Initialize a new game
  void startGame(GameConfig config) {
    _isProcessingAI = false;
    // Rebuild the AI player with the difficulty chosen for this game.
    _aiPlayer = AIPlayer(difficulty: config.difficulty);
    final deck = CardDeck().generate()..shuffle(_random);

    final players = <Player>[];
    players.add(Player(id: 'human_0', name: 'You'));
    for (int i = 1; i < config.playerCount; i++) {
      players.add(Player(id: 'ai_$i', name: 'AI $i', isAI: true));
    }

    final mutableDeck = List<WordCard>.from(deck);
    final dealtPlayers = players.map((p) {
      final hand = <WordCard>[];
      for (int i = 0; i < config.initialHandSize && mutableDeck.isNotEmpty; i++) {
        hand.add(mutableDeck.removeLast());
      }
      return p.copyWith(hand: hand);
    }).toList();

    state = GameState(
      phase: GamePhase.playing,
      players: dealtPlayers,
      deck: mutableDeck,
      currentPlayerIndex: 0,
      currentRound: 1,
      totalRounds: config.totalRounds,
      config: config,
    );

    // Player 0 is always human — start the timer immediately.
    _startTurnTimer();
  }

  /// Place a card from hand to sentence zone.
  /// WILD cards can also be placed (they act as any word).
  void placeCard(int cardIndex) {
    if (state.phase != GamePhase.playing) return;
    final player = state.currentPlayer;
    if (player.isAI) return;
    if (cardIndex < 0 || cardIndex >= player.hand.length) return;

    final card = player.hand[cardIndex];
    // Special cards other than WILD use playSpecialCard
    if (card.isSpecial && card.type != CardType.joker) return;

    final newHand = List<WordCard>.from(player.hand)..removeAt(cardIndex);
    final newSentence = [...player.sentenceZone, card];

    _updateCurrentPlayer(
      player.copyWith(hand: newHand, sentenceZone: newSentence),
    );
  }

  /// Remove last card from sentence zone back to hand
  void undoPlacement() {
    if (state.phase != GamePhase.playing) return;
    final player = state.currentPlayer;
    if (player.isAI) return;
    if (player.sentenceZone.isEmpty) return;

    final card = player.sentenceZone.last;
    final newSentence = List<WordCard>.from(player.sentenceZone)..removeLast();
    final newHand = [...player.hand, card];

    _updateCurrentPlayer(
      player.copyWith(hand: newHand, sentenceZone: newSentence),
    );
  }

  /// Draw a card from the deck (atomic state update)
  void drawCard() {
    if (state.phase != GamePhase.playing) return;
    if (state.deck.isEmpty) return;

    // Cancel before mutating state so the timer can't fire mid-action.
    _cancelTurnTimer();

    final player = state.currentPlayer;
    final newDeck = List<WordCard>.from(state.deck);
    final drawnCard = newDeck.removeLast();
    final newHand = [...player.hand, drawnCard];

    // Single atomic state update instead of multiple assignments
    final newPlayers = List<Player>.from(state.players);
    newPlayers[state.currentPlayerIndex] =
        player.copyWith(hand: newHand);

    final nextIndex =
        (state.currentPlayerIndex + 1) % state.players.length;

    state = state.copyWith(
      players: newPlayers,
      deck: newDeck,
      currentPlayerIndex: nextIndex,
    );

    _startTurnTimer();
  }

  /// Submit the current sentence for validation
  JudgmentResult submitSentence() {
    if (state.phase != GamePhase.playing) {
      return JudgmentResult(
        isCorrect: false,
        playerName: state.players.isNotEmpty
            ? state.currentPlayer.name
            : '',
        sentence: const [],
      );
    }

    final player = state.currentPlayer;

    // Block submission if sentence is too short
    if (player.sentenceZone.length < state.config.minSentenceLength) {
      return JudgmentResult(
        isCorrect: false,
        errors: [ValidationError(
          code: 'too_few_cards',
          message: 'Need at least ${state.config.minSentenceLength} cards',
          localizedMessages: {
            'ko': '최소 ${state.config.minSentenceLength}장의 카드가 필요합니다',
            'ja': '最低${state.config.minSentenceLength}枚のカードが必要です',
          },
        )],
        playerName: player.name,
        sentence: List<WordCard>.from(player.sentenceZone),
      );
    }

    // Stop the countdown before any state mutation.
    _cancelTurnTimer();

    // Capture sentence BEFORE any state mutation
    final submittedSentence = List<WordCard>.from(player.sentenceZone);
    final result = _grammarEngine.validate(submittedSentence);

    JudgmentResult judgment;

    if (result.isValid) {
      _updateCurrentPlayer(player.copyWith(
        sentenceZone: const [],
        score: player.score + result.score,
      ));

      judgment = JudgmentResult(
        isCorrect: true,
        scoreEarned: result.score,
        playerName: player.name,
        sentence: submittedSentence,
      );
    } else {
      final returnedHand = [...player.hand, ...player.sentenceZone];
      _updateCurrentPlayer(player.copyWith(
        hand: returnedHand,
        sentenceZone: const [],
      ));

      judgment = JudgmentResult(
        isCorrect: false,
        errors: result.errors,
        playerName: player.name,
        sentence: submittedSentence,
      );
    }

    _advanceTurn();
    return judgment;
  }

  /// Play a special card.
  /// For STEAL: [targetPlayerIndex] is whose card to steal,
  /// [giveCardIndex] is which card from your hand to give them (forced exchange).
  void playSpecialCard(int cardIndex, {int? targetPlayerIndex, int? giveCardIndex}) {
    if (state.phase != GamePhase.playing) return;
    final player = state.currentPlayer;
    if (cardIndex < 0 || cardIndex >= player.hand.length) return;

    final card = player.hand[cardIndex];
    if (!card.isSpecial) return;

    // Cancel before any state mutation so the timer can't fire mid-action.
    _cancelTurnTimer();

    final newHand = List<WordCard>.from(player.hand)..removeAt(cardIndex);

    switch (card.type) {
      case CardType.jump:
        // Skip next player: advance by 2 in a single atomic update
        final skipCount = state.players.length > 2 ? 2 : 1;
        final nextIndex =
            (state.currentPlayerIndex + skipCount) % state.players.length;

        final newPlayers = List<Player>.from(state.players);
        newPlayers[state.currentPlayerIndex] =
            player.copyWith(hand: newHand);

        state = state.copyWith(
          players: newPlayers,
          currentPlayerIndex: nextIndex,
        );
        _startTurnTimer();
        return;

      case CardType.steal:
        // Forced exchange: steal 1 random card from target, give 1 card back.
        // giveCardIndex refers to the index in newHand (after removing the
        // STEAL card itself).
        if (targetPlayerIndex != null &&
            targetPlayerIndex != state.currentPlayerIndex &&
            giveCardIndex != null) {
          final target = state.players[targetPlayerIndex];
          if (target.hand.isNotEmpty &&
              giveCardIndex >= 0 && giveCardIndex < newHand.length) {
            // Steal a random card from target
            final stolenIndex = _random.nextInt(target.hand.length);
            final stolenCard = target.hand[stolenIndex];

            // Give one of our cards to target
            final givenCard = newHand[giveCardIndex];

            final myUpdatedHand = List<WordCard>.from(newHand)
              ..removeAt(giveCardIndex)
              ..add(stolenCard);

            final targetUpdatedHand = List<WordCard>.from(target.hand)
              ..removeAt(stolenIndex)
              ..add(givenCard);

            // Single atomic update
            final newPlayers = List<Player>.from(state.players);
            newPlayers[state.currentPlayerIndex] =
                player.copyWith(hand: myUpdatedHand);
            newPlayers[targetPlayerIndex] =
                target.copyWith(hand: targetUpdatedHand);

            final nextIndex =
                (state.currentPlayerIndex + 1) % state.players.length;

            state = state.copyWith(
              players: newPlayers,
              currentPlayerIndex: nextIndex,
            );
            _startTurnTimer();
            return;
          }
        }
        // No valid target or no card to give — just remove card and advance
        _updateCurrentPlayer(player.copyWith(hand: newHand));
        _advanceTurn();

      case CardType.joker:
        // WILD cards are placed via placeCard(), not played as special
        // If somehow played here, just discard it
        _updateCurrentPlayer(player.copyWith(hand: newHand));
        _advanceTurn();

      case CardType.word:
        break;
    }
  }

  /// Execute AI turn. Returns a JudgmentResult if AI submitted a sentence.
  Future<JudgmentResult?> executeAITurn() async {
    if (state.phase != GamePhase.playing) return null;
    final player = state.currentPlayer;
    if (!player.isAI) return null;

    final action = _aiPlayer.decideTurn(player, state);

    switch (action.type) {
      case AIActionType.buildAndSubmit:
        final cardsToPlace = action.cardsToPlace ?? [];
        var currentPlayer = player;
        for (final card in cardsToPlace) {
          final idx = currentPlayer.hand.indexWhere((c) => c.id == card.id);
          if (idx >= 0) {
            final newHand = List<WordCard>.from(currentPlayer.hand)
              ..removeAt(idx);
            final newSentence = [...currentPlayer.sentenceZone, card];
            currentPlayer =
                currentPlayer.copyWith(hand: newHand, sentenceZone: newSentence);
          }
        }
        _updateCurrentPlayer(currentPlayer);
        return submitSentence();

      case AIActionType.drawCard:
        drawCard();
        return null;

      case AIActionType.playSpecial:
        final cardIdx =
            player.hand.indexWhere((c) => c.id == action.specialCard?.id);
        if (cardIdx >= 0) {
          playSpecialCard(
            cardIdx,
            targetPlayerIndex: action.targetPlayer,
            giveCardIndex: action.giveCardIndex,
          );
        }
        return null;
    }
  }

  /// Process all consecutive AI turns. Guarded against concurrent execution.
  Future<List<JudgmentResult>> processAITurns() async {
    if (_isProcessingAI) return [];
    _isProcessingAI = true;

    // Suppress the human timer while AI is in control.
    _cancelTurnTimer();

    final results = <JudgmentResult>[];

    try {
      while (state.phase == GamePhase.playing &&
          state.currentPlayer.isAI) {
        await Future.delayed(const Duration(milliseconds: 800));
        final result = await executeAITurn();
        if (result != null) results.add(result);
      }
    } finally {
      _isProcessingAI = false;
    }

    // Resume the human timer now that it is the human's turn again
    // (or do nothing if the game has ended).
    if (state.phase == GamePhase.playing && !state.currentPlayer.isAI) {
      _startTurnTimer();
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Turn timer helpers
  // ---------------------------------------------------------------------------

  /// Start (or restart) the countdown for the current human turn.
  /// Does nothing if the current player is an AI.
  void _startTurnTimer() {
    _turnTimer?.cancel();

    if (state.currentPlayer.isAI) {
      // AI manages its own timing; surface -1 so the UI hides the widget.
      state = state.copyWith(turnTimeRemaining: -1);
      return;
    }

    final seconds = state.config.turnTimerSeconds;
    state = state.copyWith(turnTimeRemaining: seconds);

    final generation = ++_timerGeneration;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || generation != _timerGeneration) return;
      final remaining = state.turnTimeRemaining;
      if (remaining <= 0 || state.phase != GamePhase.playing) {
        _turnTimer?.cancel();
        return;
      }

      final next = remaining - 1;
      if (next == 0) {
        _turnTimer?.cancel();
        _forfeitTurn();
      } else {
        state = state.copyWith(turnTimeRemaining: next);
      }
    });
  }

  /// Cancel the active timer and mark it inactive in state.
  void _cancelTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
    // Only update state when it is meaningful to avoid spurious rebuilds.
    if (state.turnTimeRemaining != -1) {
      state = state.copyWith(turnTimeRemaining: -1);
    }
  }

  /// Called when the timer reaches zero for the human player.
  /// Returns all sentence-zone cards to hand and advances the turn (draw
  /// penalty, same as the draw-card path).
  void _forfeitTurn() {
    if (state.phase != GamePhase.playing) return;
    final player = state.currentPlayer;
    if (player.isAI) return; // Safety guard — should never happen.

    // Return sentence-zone cards to hand.
    final returnedHand = [...player.hand, ...player.sentenceZone];
    _updateCurrentPlayer(player.copyWith(
      hand: returnedHand,
      sentenceZone: const [],
    ));

    _advanceTurn();
  }

  // ---------------------------------------------------------------------------
  // Turn management
  // ---------------------------------------------------------------------------

  /// Advance to the next turn. Handles round transitions.
  void _advanceTurn() {
    if (state.phase == GamePhase.gameEnd) return;

    final nextIndex =
        (state.currentPlayerIndex + 1) % state.players.length;

    // Check if round is over (wrapped back to first player AND deck is empty)
    if (nextIndex == 0 && state.deck.isEmpty) {
      if (state.currentRound >= state.totalRounds) {
        _cancelTurnTimer();
        state = state.copyWith(phase: GamePhase.gameEnd);
        return;
      }
      // Pause at roundEnd so the UI can show the transition overlay.
      // The UI must call continueToNextRound() to proceed.
      _cancelTurnTimer();
      state = state.copyWith(
        phase: GamePhase.roundEnd,
        currentPlayerIndex: nextIndex,
      );
      return;
    }

    state = state.copyWith(currentPlayerIndex: nextIndex);

    // Restart the timer for whoever's turn it now is.
    // If it's an AI turn, _startTurnTimer() will set turnTimeRemaining to -1
    // and return without creating a periodic timer, which is correct — the
    // AI drives its own pacing via processAITurns().
    _startTurnTimer();
  }

  /// Called by the UI when the player dismisses the round-end overlay.
  /// Deals a fresh hand to all players and resumes gameplay.
  void continueToNextRound() {
    if (state.phase != GamePhase.roundEnd) return;
    _startNewRound(state.currentPlayerIndex);
    // Phase is set back to playing AFTER the new round state is written,
    // so widgets that read phase see a consistent snapshot.
    state = state.copyWith(phase: GamePhase.playing);
    _startTurnTimer();
  }

  /// Start a new round: generate fresh deck, deal cards to all players.
  /// Does NOT change [phase] — callers are responsible for setting phase.
  void _startNewRound(int firstPlayerIndex) {
    final newDeck = CardDeck().generate()..shuffle(_random);
    final mutableDeck = List<WordCard>.from(newDeck);
    final config = state.config;

    final newPlayers = state.players.map((p) {
      final hand = <WordCard>[];
      for (int i = 0; i < config.initialHandSize && mutableDeck.isNotEmpty; i++) {
        hand.add(mutableDeck.removeLast());
      }
      return p.copyWith(
        hand: hand,
        sentenceZone: const [],
      );
    }).toList();

    state = state.copyWith(
      players: newPlayers,
      deck: mutableDeck,
      currentPlayerIndex: firstPlayerIndex,
      currentRound: state.currentRound + 1,
    );
    // Timer is started by the caller (continueToNextRound) after setting phase.
  }

  void _updateCurrentPlayer(Player updated) {
    _updatePlayer(state.currentPlayerIndex, updated);
  }

  void _updatePlayer(int index, Player updated) {
    final newPlayers = List<Player>.from(state.players);
    newPlayers[index] = updated;
    state = state.copyWith(players: newPlayers);
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
