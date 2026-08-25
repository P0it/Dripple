import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/engine/ai/ai_player.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/screens/game_screen.dart';

const _out = String.fromEnvironment('SHOT_DIR', defaultValue: '/tmp');

Future<void> _shot(WidgetTester tester, Size logical, String name) async {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('shot'),
      child: const ProviderScope(
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
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 32));
  }

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  late ui.Image image;
  await tester.runAsync(() async {
    image = await boundary.toImage(pixelRatio: 2);
  });
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('SHOT $_out/$name.png');
}

void main() {
  testWidgets('iphone 14', (tester) async {
    await _shot(tester, const Size(390, 844), 'board_390x844');
  });
  testWidgets('iphone se', (tester) async {
    await _shot(tester, const Size(375, 667), 'board_375x667');
  });
}
