import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/core/design/table_scaffold.dart';
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

  testWidgets('paints no gradient in a widget decoration', (tester) async {
    // Gradients are not banned any more — the felt is one. They are confined
    // to painters, so a screen decorating a Container with one is the
    // regression worth catching.
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

  testWidgets('stands on the table', (tester) async {
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump();

    expect(find.byType(TableGround), findsOneWidget);
    // Transparent, so the one felt underneath shows through rather than a
    // second flat ground painting over it.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.transparent);
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
