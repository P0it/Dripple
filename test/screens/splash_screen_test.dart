import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/screens/splash_screen.dart';

void main() {
  testWidgets('shows the mark and the wordmark', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.byType(DrippleMark), findsOneWidget);
    expect(find.text('Dripple'), findsOneWidget);

    // Let the timeline finish so the test does not end mid-animation.
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('calls onFinished once the timeline completes', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onFinished: () => finished++)),
    );

    await tester.pump(const Duration(milliseconds: 700));
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
    await tester.pump(const Duration(milliseconds: 1500));
    expect(finished, 1);
  });
}
