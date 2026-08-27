import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/dripple_game.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/l10n/app_localizations_ko.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/providers/game_provider.dart';
import 'package:dripple/screens/game_screen.dart';
import 'package:dripple/screens/tutorial/tutorial_overlay.dart';

Widget _host(ProviderContainer container) => UncontrolledProviderScope(
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
        home: GameScreen(playerCount: 1, tutorial: true),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 32));
  }
}

void main() {
  final ko = AppLocalizationsKo();

  testWidgets('the lesson opens on a dealt board with the first mark up',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container));
    await _settle(tester);

    expect(find.text(ko.tutorialWelcome), findsOneWidget);
    // One player has nobody to hand a turn to.
    expect(find.text(ko.passTurn), findsNothing);
    expect(container.read(gameProvider).players, hasLength(1));
    expect(container.read(gameProvider).turnPhase, TurnPhase.draw);
  });

  testWidgets('the mark for the deck sits on the deck', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container));
    await _settle(tester);

    await tester.tap(find.text(ko.tutorialNext));
    await _settle(tester);
    expect(find.text(ko.tutorialDeck), findsOneWidget);

    final boardFinder = find.byWidgetPredicate((w) => w is GameWidget);
    final game =
        tester.widget<GameWidget>(boardFinder).game! as DrippleGame;
    final boardOrigin = tester.getTopLeft(boardFinder);
    final deck = game.deckRect!;

    final hole = tester.widget<TutorialOverlay>(
      find.byType(TutorialOverlay),
    ).hole!;

    // The overlay fills the SafeArea; the board sits inside it. Comparing in
    // screen coordinates is what a finger would do.
    final holeOnScreen =
        hole.shift(tester.getTopLeft(find.byType(TutorialOverlay)));
    expect(holeOnScreen.center.dx,
        closeTo(boardOrigin.dx + deck.center.dx, 1.5));
    expect(holeOnScreen.center.dy,
        closeTo(boardOrigin.dy + deck.center.dy, 1.5));
  });

  testWidgets('drawing a card is what ends the draw step', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container));
    await _settle(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(ko.tutorialNext));
      await _settle(tester);
    }
    expect(find.text(ko.tutorialDraw), findsOneWidget);
    // A step that asks for a gesture offers no way past it.
    expect(find.text(ko.tutorialNext), findsNothing);

    final boardFinder = find.byWidgetPredicate((w) => w is GameWidget);
    final game =
        tester.widget<GameWidget>(boardFinder).game! as DrippleGame;
    final boardOrigin = tester.getTopLeft(boardFinder);

    await tester.tapAt(boardOrigin +
        Offset(game.deckRect!.center.dx, game.deckRect!.center.dy));
    await _settle(tester);

    expect(container.read(gameProvider).turnPhase, TurnPhase.action);
    expect(find.text(ko.tutorialSort), findsOneWidget);
    // Sorting is optional, so this one does offer a way past.
    expect(find.text(ko.tutorialSkip), findsOneWidget);
  });
}
