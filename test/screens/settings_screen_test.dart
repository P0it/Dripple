import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/screens/settings_screen.dart';

Widget _host(Locale locale) => ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    );

void main() {
  testWidgets('every visible string is localised', (tester) async {
    await tester.pumpWidget(_host(const Locale('ko')));
    await tester.pump();

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();

    expect(texts, isNotEmpty);

    // In the Korean locale no label should still be bare ASCII English.
    // "Dripple" and version numbers are allowed through.
    final untranslated = texts
        .where((s) => s != 'Dripple')
        .where((s) => !RegExp(r'^[\d.v ]+$').hasMatch(s))
        .where((s) => RegExp(r'^[A-Za-z][A-Za-z .!?/-]*$').hasMatch(s))
        .toList();

    expect(untranslated, isEmpty,
        reason: 'hard-coded English left in the settings screen');
  });
}
