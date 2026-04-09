import 'package:equatable/equatable.dart';
import 'player.dart';
import 'word_card.dart';

enum GamePhase { setup, playing, roundEnd, gameEnd }

enum TurnAction { placeCard, drawCard, playSpecial, submit }

class GameConfig {
  final int playerCount;
  final int totalRounds;
  final int initialHandSize;
  final int turnTimerSeconds;

  const GameConfig({
    this.playerCount = 2,
    this.totalRounds = 5,
    this.initialHandSize = 7,
    this.turnTimerSeconds = 30,
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

  const GameState({
    this.phase = GamePhase.setup,
    this.players = const [],
    this.deck = const [],
    this.currentPlayerIndex = 0,
    this.currentRound = 1,
    this.totalRounds = 5,
    this.config = const GameConfig(),
  });

  Player get currentPlayer => players[currentPlayerIndex];
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
  }) {
    return GameState(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      deck: deck ?? this.deck,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      config: config ?? this.config,
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
      ];
}
