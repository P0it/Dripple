import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/core/design/app_colors.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/screens/home_screen.dart';

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('the mark carries the screen', (tester) async {
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump();
    expect(find.byType(DrippleMark), findsOneWidget);
  });

  testWidgets('has no gradient anywhere', (tester) async {
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump();

    final gradients = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => (c.decoration as BoxDecoration?)?.gradient != null);
    expect(gradients, isEmpty);

    final decorated = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((d) => (d.decoration as BoxDecoration?)?.gradient != null);
    expect(decorated, isEmpty);
  });

  testWidgets('sits on a flat app surface', (tester) async {
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor,
        anyOf(AppColors.surface, AppColors.background));
  });

  testWidgets('offers no dead affordances', (tester) async {
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump();

    // The old screen showed Character and Ranking buttons wired to null.
    // A button a child can press that does nothing is worse than no button.
    // byType matches the exact runtime type, so the subclasses need a
    // predicate.
    final buttons = tester
        .widgetList<Widget>(find.byWidgetPredicate((w) => w is ButtonStyleButton))
        .cast<ButtonStyleButton>();
    expect(buttons, isNotEmpty);
    for (final button in buttons) {
      expect(button.onPressed, isNotNull);
    }
  });
}
