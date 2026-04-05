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

  JudgmentResult? lastJudgment;

  GameNotifier({
    GrammarEngine? grammarEngine,
    AIPlayer? aiPlayer,
    Random? random,
  })  : _grammarEngine = grammarEngine ?? GrammarEngine(),
        _aiPlayer = aiPlayer ?? AIPlayer(),
        _random = random ?? Random(),
        super(const GameState());

  /// Initialize a new game
  void startGame(GameConfig config) {
    final deck = CardDeck.generateDeck()..shuffle(_random);

    // Create players
    final players = <Player>[];
    players.add(Player(id: 'human_0', name: 'You'));
    for (int i = 1; i < config.playerCount; i++) {
      players.add(Player(id: 'ai_$i', name: 'AI $i', isAI: true));
    }

    // Deal initial hands
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

    lastJudgment = null;
  }

  /// Place a card from hand to sentence zone
  void placeCard(int cardIndex) {
    if (state.phase != GamePhase.playing) return;
    final player = state.currentPlayer;
    if (player.isAI) return;
    if (cardIndex < 0 || cardIndex >= player.hand.length) return;

    final card = player.hand[cardIndex];
    if (card.isSpecial) return; // Special cards use playSpecialCard

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

  /// Draw a card from the deck
  void drawCard() {
    if (state.phase != GamePhase.playing) return;
    if (state.deck.isEmpty) return;

    final player = state.currentPlayer;
    final newDeck = List<WordCard>.from(state.deck);
    final drawnCard = newDeck.removeLast();
    final newHand = [...player.hand, drawnCard];

    _updateCurrentPlayer(player.copyWith(hand: newHand));
    state = state.copyWith(deck: newDeck);

    _advanceTurn();
  }

  /// Submit the current sentence for validation
  JudgmentResult submitSentence() {
    if (state.phase != GamePhase.playing) {
      return JudgmentResult(
        isCorrect: false,
        playerName: state.currentPlayer.name,
        sentence: const [],
      );
    }

    final player = state.currentPlayer;
    final result = _grammarEngine.validate(player.sentenceZone);

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

      lastJudgment = JudgmentResult(
        isCorrect: true,
        scoreEarned: scoreWithCombo,
        playerName: player.name,
        sentence: player.sentenceZone,
      );
    } else {
      // Wrong: lose turn, reset combo, return cards to hand
      final returnedHand = [...player.hand, ...player.sentenceZone];
      _updateCurrentPlayer(player.copyWith(
        hand: returnedHand,
        sentenceZone: const [],
        comboCount: 0,
      ));

      lastJudgment = JudgmentResult(
        isCorrect: false,
        errors: result.errors,
        playerName: player.name,
        sentence: player.sentenceZone,
      );
    }

    _advanceTurn();
    return lastJudgment!;
  }

  /// Play a special card
  void playSpecialCard(int cardIndex, {int? targetPlayerIndex}) {
    if (state.phase != GamePhase.playing) return;
    final player = state.currentPlayer;
    if (cardIndex < 0 || cardIndex >= player.hand.length) return;

    final card = player.hand[cardIndex];
    if (!card.isSpecial) return;

    final newHand = List<WordCard>.from(player.hand)..removeAt(cardIndex);
    _updateCurrentPlayer(player.copyWith(hand: newHand));

    switch (card.type) {
      case CardType.skip:
        // Skip next player by advancing turn twice
        _advanceTurn();
        _advanceTurn();
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

            final currentPlayer = state.players[state.currentPlayerIndex];
            _updatePlayer(
              targetPlayerIndex,
              target.copyWith(hand: newTargetHand),
            );
            _updateCurrentPlayer(
              currentPlayer.copyWith(hand: [...currentPlayer.hand, stolenCard]),
            );
          }
        }
        _advanceTurn();

      case CardType.undo:
        if (targetPlayerIndex != null &&
            targetPlayerIndex != state.currentPlayerIndex) {
          final target = state.players[targetPlayerIndex];
          if (target.sentenceZone.isNotEmpty) {
            final removedCard = target.sentenceZone.last;
            final newSentence = List<WordCard>.from(target.sentenceZone)
              ..removeLast();
            _updatePlayer(
              targetPlayerIndex,
              target.copyWith(
                hand: [...target.hand, removedCard],
                sentenceZone: newSentence,
              ),
            );
          }
        }
        _advanceTurn();

      case CardType.wild:
        // Wild card is handled during placement as any word
        _advanceTurn();

      case CardType.word:
        break; // Not a special card
    }
  }

  /// Execute AI turn
  Future<JudgmentResult?> executeAITurn() async {
    if (state.phase != GamePhase.playing) return null;
    final player = state.currentPlayer;
    if (!player.isAI) return null;

    final action = _aiPlayer.decideTurn(player, state);

    switch (action.type) {
      case AIActionType.buildAndSubmit:
        // AI places cards then submits
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

  void _advanceTurn() {
    final nextIndex =
        (state.currentPlayerIndex + 1) % state.players.length;

    // Check if round is over (all players had a turn with empty deck)
    if (nextIndex == 0 && state.deck.isEmpty) {
      if (state.currentRound >= state.totalRounds) {
        state = state.copyWith(phase: GamePhase.gameEnd);
        return;
      }
      state = state.copyWith(
        currentPlayerIndex: nextIndex,
        currentRound: state.currentRound + 1,
      );
      return;
    }

    state = state.copyWith(currentPlayerIndex: nextIndex);
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
