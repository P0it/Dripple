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
  final AIPlayer _aiPlayer;
  final Random _random;

  bool _isProcessingAI = false;

  GameNotifier({
    GrammarEngine? grammarEngine,
    AIPlayer? aiPlayer,
    Random? random,
  })  : _grammarEngine = grammarEngine ?? GrammarEngine(),
        _aiPlayer = aiPlayer ?? AIPlayer(),
        _random = random ?? Random(),
        super(const GameState());

  /// Whether AI turns are currently being processed
  bool get isProcessingAI => _isProcessingAI;

  /// Initialize a new game
  void startGame(GameConfig config) {
    _isProcessingAI = false;
    final deck = CardDeck.generateDeck()..shuffle(_random);

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
    if (card.isSpecial && card.type != CardType.wild) return;

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
    // Capture sentence BEFORE any state mutation
    final submittedSentence = List<WordCard>.from(player.sentenceZone);
    final result = _grammarEngine.validate(submittedSentence);

    JudgmentResult judgment;

    if (result.isValid) {
      final scoreWithCombo = GrammarEngine.calculateScoreWithCombo(
        result.score,
        player.comboCount + 1,
      );

      _updateCurrentPlayer(player.copyWith(
        sentenceZone: const [],
        score: player.score + scoreWithCombo,
        comboCount: player.comboCount + 1,
      ));

      judgment = JudgmentResult(
        isCorrect: true,
        scoreEarned: scoreWithCombo,
        playerName: player.name,
        sentence: submittedSentence,
      );
    } else {
      final returnedHand = [...player.hand, ...player.sentenceZone];
      _updateCurrentPlayer(player.copyWith(
        hand: returnedHand,
        sentenceZone: const [],
        comboCount: 0,
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

  /// Play a special card
  void playSpecialCard(int cardIndex, {int? targetPlayerIndex}) {
    if (state.phase != GamePhase.playing) return;
    final player = state.currentPlayer;
    if (cardIndex < 0 || cardIndex >= player.hand.length) return;

    final card = player.hand[cardIndex];
    if (!card.isSpecial) return;

    final newHand = List<WordCard>.from(player.hand)..removeAt(cardIndex);

    switch (card.type) {
      case CardType.skip:
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
        return;

      case CardType.steal:
        if (targetPlayerIndex != null &&
            targetPlayerIndex != state.currentPlayerIndex) {
          final target = state.players[targetPlayerIndex];
          if (target.hand.isNotEmpty) {
            final stolenIndex = _random.nextInt(target.hand.length);
            final stolenCard = target.hand[stolenIndex];
            final newTargetHand = List<WordCard>.from(target.hand)
              ..removeAt(stolenIndex);

            // Single atomic update: remove special card + steal card + advance turn
            final newPlayers = List<Player>.from(state.players);
            newPlayers[state.currentPlayerIndex] =
                player.copyWith(hand: [...newHand, stolenCard]);
            newPlayers[targetPlayerIndex] =
                target.copyWith(hand: newTargetHand);

            final nextIndex =
                (state.currentPlayerIndex + 1) % state.players.length;

            state = state.copyWith(
              players: newPlayers,
              currentPlayerIndex: nextIndex,
            );
            return;
          }
        }
        // No valid target — just remove card and advance
        _updateCurrentPlayer(player.copyWith(hand: newHand));
        _advanceTurn();

      case CardType.undo:
        if (targetPlayerIndex != null &&
            targetPlayerIndex != state.currentPlayerIndex) {
          final target = state.players[targetPlayerIndex];
          if (target.sentenceZone.isNotEmpty) {
            final removedCard = target.sentenceZone.last;
            final newSentence = List<WordCard>.from(target.sentenceZone)
              ..removeLast();

            // Single atomic update
            final newPlayers = List<Player>.from(state.players);
            newPlayers[state.currentPlayerIndex] =
                player.copyWith(hand: newHand);
            newPlayers[targetPlayerIndex] = target.copyWith(
              hand: [...target.hand, removedCard],
              sentenceZone: newSentence,
            );

            final nextIndex =
                (state.currentPlayerIndex + 1) % state.players.length;

            state = state.copyWith(
              players: newPlayers,
              currentPlayerIndex: nextIndex,
            );
            return;
          }
        }
        _updateCurrentPlayer(player.copyWith(hand: newHand));
        _advanceTurn();

      case CardType.wild:
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
          playSpecialCard(cardIdx, targetPlayerIndex: action.targetPlayer);
        }
        return null;
    }
  }

  /// Process all consecutive AI turns. Guarded against concurrent execution.
  Future<List<JudgmentResult>> processAITurns() async {
    if (_isProcessingAI) return [];
    _isProcessingAI = true;

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

    return results;
  }

  /// Advance to the next turn. Handles round transitions.
  void _advanceTurn() {
    if (state.phase == GamePhase.gameEnd) return;

    final nextIndex =
        (state.currentPlayerIndex + 1) % state.players.length;

    // Check if round is over (wrapped back to first player AND deck is empty)
    if (nextIndex == 0 && state.deck.isEmpty) {
      if (state.currentRound >= state.totalRounds) {
        state = state.copyWith(phase: GamePhase.gameEnd);
        return;
      }
      // Start new round: reshuffle deck and re-deal
      _startNewRound(nextIndex);
      return;
    }

    state = state.copyWith(currentPlayerIndex: nextIndex);
  }

  /// Start a new round: generate fresh deck, deal cards to all players
  void _startNewRound(int firstPlayerIndex) {
    final newDeck = CardDeck.generateDeck()..shuffle(_random);
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
