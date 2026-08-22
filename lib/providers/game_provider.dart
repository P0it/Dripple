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

  /// Disabled in tests so turns can be stepped deterministically.
  final bool autoRunAI;

  Timer? _turnTimer;
  int _timerGeneration = 0;
  bool _isProcessingAI = false;

  GameNotifier({
    GrammarEngine? grammarEngine,
    AIPlayer? aiPlayer,
    Random? random,
    this.autoRunAI = true,
  })  : _grammarEngine = grammarEngine ?? GrammarEngine(),
        _aiPlayer = aiPlayer ?? AIPlayer(),
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
    _aiPlayer = AIPlayer(difficulty: config.difficulty);

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
  }

  // -------------------------------------------------------------------------
  // Draw phase
  // -------------------------------------------------------------------------

  void drawFromDeck() {
    if (state.phase != GamePhase.playing) return;
    if (state.turnPhase != TurnPhase.draw) return;

    var working = state;
    if (working.deck.isEmpty) {
      working = _recycleDiscardIntoDeck(working);
      if (working.deck.isEmpty) {
        // Nothing left to draw: skip straight to the action phase.
        state = working.copyWith(turnPhase: TurnPhase.action);
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
  // Helpers
  // -------------------------------------------------------------------------

  void _updateCurrentPlayer(Player updated) {
    final players = List<Player>.from(state.players);
    players[state.currentPlayerIndex] = updated;
    state = state.copyWith(players: players);
  }

  /// Implemented in the action-phase task.
  void endTurn({int skip = 0}) {}
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
