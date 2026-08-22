import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/engine/ai/ai_player.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/providers/game_provider.dart';

/// Rebuild a player as AI-controlled so `runAITurns` can drive every seat.
Player _asAI(Player p) => Player(
      id: p.id,
      name: p.name,
      isAI: true,
      hand: p.hand,
      sentenceZone: p.sentenceZone,
    );

GameNotifier _allAIGame(int seed) {
  final n = GameNotifier(
    random: Random(seed),
    aiPlayer: AIPlayer(difficulty: AIDifficulty.hard, random: Random(seed)),
    aiTurnDelay: Duration.zero,
    autoRunAI: false,
  );
  n.startGame(const GameConfig());
  n.debugSetState(n.state.copyWith(
    players: [for (final p in n.state.players) _asAI(p)],
  ));
  return n;
}

/// Plays whole 4-player games with every seat driven by the AI, to prove the
/// rules terminate and that turns never wedge.
void main() {
  test('a full 4-player game always reaches a winner', () async {
    for (var seed = 0; seed < 20; seed++) {
      final n = _allAIGame(seed);

      await n.runAITurns();

      expect(n.state.phase, GamePhase.gameEnd,
          reason: 'seed $seed did not terminate');
      expect(n.state.winnerIndex, isNotNull, reason: 'seed $seed has no winner');
    }
  });

  test('sentences actually get played over a full game', () async {
    final n = _allAIGame(11);

    final results = await n.runAITurns();

    expect(results.where((r) => r.isCorrect).length, greaterThan(3),
        reason: 'the AI must build sentences, not just draw and discard');
    expect(n.state.ranking.first.hand.length, lessThan(7),
        reason: 'the leader ended with fewer cards than they started with');
  });
}
