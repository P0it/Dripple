import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/engine/ai/ai_player.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/screens/game_screen.dart';

void main() {
  late Size _size;
  Future<void> body(WidgetTester tester) async {
    tester.view.physicalSize = _size * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 32));
    }

    final box = tester.renderObject<RenderBox>(find.byWidgetPredicate((w) => w is GameWidget));
    // ignore: avoid_print
    print('BOARD view=$_size board=${box.size}');
  }

  for (final s in const [Size(390, 844), Size(375, 667), Size(360, 640)]) {
    testWidgets('board size $s', (tester) async {
      _size = s;
      await body(tester);
    });
  }
}
