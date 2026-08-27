import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple_rules/engine/ai/ai_player.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple/providers/game_provider.dart';
import 'package:dripple/screens/game_screen.dart';

void main() {
  testWidgets('a turn can be ended by throwing a card on the discard pile',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('ko'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(playerCount: 4, difficulty: AIDifficulty.medium),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 32));
    }

    final boardFinder = find.byWidgetPredicate((w) => w is GameWidget);
    final board = tester.getTopLeft(boardFinder);
    final widget = tester.widget<GameWidget>(boardFinder);
    final game = widget.game! as DrippleGame;
    Offset toScreen(Vector2 v) => board + Offset(v.x, v.y);

    // Step 1: draw, by tapping the deck the way you would reach for it.
    expect(container.read(gameProvider).turnPhase, TurnPhase.draw);
    await tester.tapAt(toScreen(game.debugDeckCentre!));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 32));
    }
    expect(container.read(gameProvider).turnPhase, TurnPhase.action);

    // Step 2: throw one away, by dragging it onto the pile.
    final handBefore = container.read(gameProvider).players[0].hand.length;
    final card = game.debugHandComponents.first;
    final from = toScreen(
      Vector2(card.position.x + card.size.x / 2,
          card.position.y + card.size.y / 2),
    );
    final to = toScreen(game.debugDiscardCentre!);
    final gesture = await tester.startGesture(from);
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(Offset((to.dx - from.dx) / 20, (to.dy - from.dy) / 20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 32));
    }

    final state = container.read(gameProvider);
    expect(state.players[0].hand.length, handBefore - 1);
    expect(state.currentPlayerIndex, isNot(0),
        reason: 'throwing a card away is the action, so the turn ends');

    // The turn timer and the AI loop both outlive the widget tree; tear the
    // container down here rather than in a callback, which runs after the
    // binding has already complained about the pending timer.
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    // Let the AI's in-flight delay expire; a disposed notifier drops it, but
    // the timer itself is still on the clock.
    await tester.pump(const Duration(seconds: 3));
  });
}
