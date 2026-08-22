import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/providers/game_provider.dart';

void main() {
  test('game starts with 4 players in the draw phase', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(gameProvider.notifier).startGame(const GameConfig());
    final state = container.read(gameProvider);

    expect(state.players.length, 4);
    expect(state.phase, GamePhase.playing);
    expect(state.turnPhase, TurnPhase.draw);
    expect(state.currentPlayer.isAI, false);
    expect(state.discardPile.length, 1);
  });
}
