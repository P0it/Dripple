import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/design/table_column.dart';

/// The app is a phone-shaped card game, and a browser window is not a phone.
///
/// Every measurement on the board is taken against the width it is given —
/// `HandFan` spreads the fan across it, `home_screen` sizes the mark against
/// it — and none of them has an upper bound, because on the device there was
/// never a width worth bounding. On a 1920px desktop the same arithmetic lays
/// seven cards out end to end across a metre of screen.
///
/// So the width is bounded once, here, rather than in each of the places that
/// reads it.
void main() {
  /// The width the child is actually laid out at, and the width it is told
  /// about. Both matter: Flame reads its constraints and `home_screen` reads
  /// `MediaQuery`, and a fix that moves only one of them leaves the other
  /// measuring the window.
  Future<({double laidOut, double reported})> measure(
    WidgetTester tester,
    Size window,
  ) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late double laidOut;
    late double reported;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TableColumn(child: child!),
        home: LayoutBuilder(
          builder: (context, constraints) {
            laidOut = constraints.maxWidth;
            reported = MediaQuery.sizeOf(context).width;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    return (laidOut: laidOut, reported: reported);
  }

  testWidgets('a window wider than a phone is held to a phone', (tester) async {
    final m = await measure(tester, const Size(1920, 1080));

    expect(m.laidOut, TableColumn.maxWidth);
    expect(m.reported, TableColumn.maxWidth,
        reason: 'a screen measuring itself must see the column, not the window');
  });

  testWidgets('a phone is left alone', (tester) async {
    final m = await measure(tester, const Size(390, 844));

    expect(m.laidOut, 390);
    expect(m.reported, 390);
  });

  testWidgets('the cap is the only thing capped — height is untouched',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late double height;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TableColumn(child: child!),
        home: LayoutBuilder(
          builder: (context, constraints) {
            height = MediaQuery.sizeOf(context).height;
            return const SizedBox.expand();
          },
        ),
      ),
    );

    expect(height, 1080);
  });
}
