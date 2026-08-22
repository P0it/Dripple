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

  void placeCard(int handIndex) {
    if (state.phase != GamePhase.playing) return;
    final me = state.currentPlayer;
    if (handIndex < 0 || handIndex >= me.hand.length) return;

    final card = me.hand[handIndex];
    // JUMP and STEAL are actions, not words.
    if (card.type == CardType.jump || card.type == CardType.steal) return;

    final hand = List<WordCard>.from(me.hand)..removeAt(handIndex);
    _updateCurrentPlayer(
      me.copyWith(hand: hand, sentenceZone: [...me.sentenceZone, card]),
    );
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

  /// Implemented in the AI-ownership task.
  Future<void> _runAITurnsIfNeeded() async {}

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
