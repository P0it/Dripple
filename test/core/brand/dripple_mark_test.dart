import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';

void main() {
  testWidgets('renders at the requested size', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: DrippleMark(size: 96)),
    ));
    expect(find.byType(DrippleMark), findsOneWidget);
    // Scoped to the mark: a MaterialApp puts its own CustomPaints above it.
    final painted = find.descendant(
      of: find.byType(DrippleMark),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(painted.first), const Size(96, 96));
  });

  test('repaints only when progress or colour changes', () {
    const a = DrippleMarkPainter(progress: 0.5, color: Color(0xFF1D74F5));
    const b = DrippleMarkPainter(progress: 0.5, color: Color(0xFF1D74F5));
    const c = DrippleMarkPainter(progress: 0.9, color: Color(0xFF1D74F5));
    const d = DrippleMarkPainter(progress: 0.5, color: Color(0xFF000000));
    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
    expect(a.shouldRepaint(d), isTrue);
  });

  testWidgets('paints without throwing across the whole progress range',
      (tester) async {
    for (final p in [0.0, 0.25, 0.45, 0.7, 1.0]) {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: CustomPaint(
            size: const Size(120, 120),
            painter:
                DrippleMarkPainter(progress: p, color: const Color(0xFF1D74F5)),
          ),
        ),
      ));
      expect(tester.takeException(), isNull, reason: 'at progress $p');
    }
  });

  testWidgets('an animated mark follows its controller', (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 300),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Center(child: DrippleMark(size: 80, animation: controller)),
    ));

    controller.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.isCompleted, isTrue);
  });
}
