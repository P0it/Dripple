import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/screens/splash_screen.dart';

/// The `progress` the mark is being painted at right now.
double _markProgress(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(DrippleMark),
      matching: find.byType(CustomPaint),
    ),
  );
  return (paint.painter! as DrippleMarkPainter).progress;
}

void main() {
  testWidgets('shows the mark and the wordmark', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.byType(DrippleMark), findsOneWidget);
    expect(find.text('Dripple'), findsOneWidget);

    // Let the timeline finish so the test does not end mid-animation.
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('holds at one card before dealing the second', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    // 300ms is inside the hold: the card has arrived, and the pair is still
    // squared up, which is what makes it read as a single card.
    await tester.pump(const Duration(milliseconds: 300));
    expect(_markProgress(tester), 0);

    // 400ms is still the hold — nothing has moved yet.
    await tester.pump(const Duration(milliseconds: 100));
    expect(_markProgress(tester), 0);

    // 800ms is mid-deal.
    await tester.pump(const Duration(milliseconds: 400));
    expect(_markProgress(tester), greaterThan(0));
    expect(_markProgress(tester), lessThan(1));

    // Dealt by the time the name arrives.
    await tester.pump(const Duration(milliseconds: 400));
    expect(_markProgress(tester), 1);

    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('calls onFinished once the timeline completes', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onFinished: () => finished++)),
    );

    await tester.pump(const Duration(milliseconds: 900));
    expect(finished, 0, reason: 'still animating');

    await tester.pump(const Duration(milliseconds: 900));
    expect(finished, 1);
  });

  testWidgets('a tap skips the rest of the timeline', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onFinished: () => finished++)),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(SplashScreen));
    await tester.pump();

    expect(finished, 1);

    // Letting the controller run on must not fire it a second time.
    await tester.pump(const Duration(milliseconds: 1700));
    expect(finished, 1);
  });
}
