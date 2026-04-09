import 'package:equatable/equatable.dart';
import 'player.dart';
import 'word_card.dart';
import '../engine/ai/ai_player.dart';

enum GamePhase { setup, playing, roundEnd, gameEnd }

class GameConfig {
  final int playerCount;
  final int totalRounds;
  final int initialHandSize;
  final int turnTimerSeconds;
  final AIDifficulty difficulty;
  /// Minimum number of cards in the sentence zone to allow submission.
  final int minSentenceLength;

  const GameConfig({
    this.playerCount = 2,
    this.totalRounds = 5,
    this.initialHandSize = 7,
    this.turnTimerSeconds = 30,
    this.difficulty = AIDifficulty.medium,
    this.minSentenceLength = 5,
  });
}

class GameState extends Equatable {
  final GamePhase phase;
  final List<Player> players;
  final List<WordCard> deck;
  final int currentPlayerIndex;
  final int currentRound;
  final int totalRounds;
  final GameConfig config;
  /// Seconds remaining on the current human turn. -1 means timer is inactive
  /// (e.g. AI turn or game not started).
  final int turnTimeRemaining;

  const GameState({
    this.phase = GamePhase.setup,
    this.players = const [],
    this.deck = const [],
    this.currentPlayerIndex = 0,
    this.currentRound = 1,
    this.totalRounds = 5,
    this.config = const GameConfig(),
    this.turnTimeRemaining = -1,
  });

  Player get currentPlayer {
    if (players.isEmpty || currentPlayerIndex >= players.length) {
      return const Player(id: '', name: '');
    }
    return players[currentPlayerIndex];
  }
  bool get isGameOver => phase == GamePhase.gameEnd;
  bool get isRoundOver => phase == GamePhase.roundEnd;

  /// Get players sorted by score (descending)
  List<Player> get ranking =>
      List<Player>.from(players)..sort((a, b) => b.score.compareTo(a.score));

  GameState copyWith({
    GamePhase? phase,
    List<Player>? players,
    List<WordCard>? deck,
    int? currentPlayerIndex,
    int? currentRound,
    int? totalRounds,
    GameConfig? config,
    int? turnTimeRemaining,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      deck: deck ?? this.deck,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      config: config ?? this.config,
      turnTimeRemaining: turnTimeRemaining ?? this.turnTimeRemaining,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        players,
        deck,
        currentPlayerIndex,
        currentRound,
        totalRounds,
        config,
        turnTimeRemaining,
      ];
}
