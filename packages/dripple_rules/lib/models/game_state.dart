import 'package:equatable/equatable.dart';
import 'player.dart';
import 'word_card.dart';
import '../engine/ai/ai_player.dart';

enum GamePhase { setup, playing, gameEnd }

/// A turn is always "draw exactly one card, then take exactly one action".
enum TurnPhase { draw, action }

class GameConfig extends Equatable {
  final int playerCount;
  final int initialHandSize;

  /// 0 disables the countdown. Off by default — this is a children's game.
  final int turnTimerSeconds;
  final AIDifficulty difficulty;

  const GameConfig({
    this.playerCount = 4,
    this.initialHandSize = 7,
    this.turnTimerSeconds = 0,
    this.difficulty = AIDifficulty.medium,
  });

  @override
  List<Object?> get props =>
      [playerCount, initialHandSize, turnTimerSeconds, difficulty];
}

class GameState extends Equatable {
  final GamePhase phase;
  final TurnPhase turnPhase;
  final List<Player> players;
  final List<WordCard> deck;

  /// Face-up discard pile. The last element is the top card.
  final List<WordCard> discardPile;
  final int currentPlayerIndex;
  final GameConfig config;

  /// Seconds left on the current human turn. -1 means inactive.
  final int turnTimeRemaining;

  /// How many times the discard pile has been recycled into the deck.
  /// Two recycles followed by exhaustion ends the game (anti-stalling).
  final int deckRecycleCount;

  /// Id of the card taken from the discard pile this turn. Rummy forbids
  /// discarding it again on the same turn, which would otherwise let two
  /// players shuffle one card back and forth forever.
  final String? drawnFromDiscardCardId;
  final int? winnerIndex;

  /// Which seat this device is playing.
  ///
  /// Offline it is always the first: the other seats are bots, so "not a bot"
  /// and "me" were the same question and the screens asked the second by
  /// asking the first. Online three of four seats are people and only one is
  /// yours, so the question has to be asked directly.
  final int mySeatIndex;

  const GameState({
    this.phase = GamePhase.setup,
    this.turnPhase = TurnPhase.draw,
    this.players = const [],
    this.deck = const [],
    this.discardPile = const [],
    this.currentPlayerIndex = 0,
    this.config = const GameConfig(),
    this.turnTimeRemaining = -1,
    this.deckRecycleCount = 0,
    this.drawnFromDiscardCardId,
    this.winnerIndex,
    this.mySeatIndex = 0,
  });

  Player get currentPlayer {
    if (players.isEmpty || currentPlayerIndex >= players.length) {
      return const Player(id: '', name: '');
    }
    return players[currentPlayerIndex];
  }

  /// This device's own player.
  Player get me {
    if (players.isEmpty || mySeatIndex >= players.length) {
      return const Player(id: '', name: '');
    }
    return players[mySeatIndex];
  }

  /// Everybody else at the table, bots and people alike.
  List<Player> get opponents => [
        for (var i = 0; i < players.length; i++)
          if (i != mySeatIndex) players[i],
      ];

  /// Whether this device may act right now.
  bool get isMyTurn =>
      phase == GamePhase.playing &&
      players.isNotEmpty &&
      currentPlayerIndex == mySeatIndex;

  WordCard? get discardTop => discardPile.isEmpty ? null : discardPile.last;

  bool get isGameOver => phase == GamePhase.gameEnd;

  /// Players ordered by fewest cards remaining — the win condition is
  /// emptying your hand, so this is the standing.
  List<Player> get ranking => List<Player>.from(players)
    ..sort((a, b) => a.hand.length.compareTo(b.hand.length));

  GameState copyWith({
    GamePhase? phase,
    TurnPhase? turnPhase,
    List<Player>? players,
    List<WordCard>? deck,
    List<WordCard>? discardPile,
    int? currentPlayerIndex,
    GameConfig? config,
    int? turnTimeRemaining,
    int? deckRecycleCount,
    String? drawnFromDiscardCardId,
    int? winnerIndex,
    int? mySeatIndex,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      turnPhase: turnPhase ?? this.turnPhase,
      players: players ?? this.players,
      deck: deck ?? this.deck,
      discardPile: discardPile ?? this.discardPile,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      config: config ?? this.config,
      turnTimeRemaining: turnTimeRemaining ?? this.turnTimeRemaining,
      deckRecycleCount: deckRecycleCount ?? this.deckRecycleCount,
      drawnFromDiscardCardId:
          drawnFromDiscardCardId ?? this.drawnFromDiscardCardId,
      winnerIndex: winnerIndex ?? this.winnerIndex,
      mySeatIndex: mySeatIndex ?? this.mySeatIndex,
    );
  }

  /// copyWith cannot set a nullable field back to null, so clearing the
  /// discard-draw marker needs its own method.
  GameState clearDrawnFromDiscard() => GameState(
        phase: phase,
        turnPhase: turnPhase,
        players: players,
        deck: deck,
        discardPile: discardPile,
        currentPlayerIndex: currentPlayerIndex,
        config: config,
        turnTimeRemaining: turnTimeRemaining,
        deckRecycleCount: deckRecycleCount,
        drawnFromDiscardCardId: null,
        winnerIndex: winnerIndex,
        mySeatIndex: mySeatIndex,
      );

  @override
  List<Object?> get props => [
        phase,
        turnPhase,
        players,
        deck,
        discardPile,
        currentPlayerIndex,
        config,
        turnTimeRemaining,
        deckRecycleCount,
        drawnFromDiscardCardId,
        winnerIndex,
        mySeatIndex,
      ];
}
