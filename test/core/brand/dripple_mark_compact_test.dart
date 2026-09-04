import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/core/design/app_colors.dart';
import 'package:dripple/core/design/materials.dart';
import 'package:dripple_rules/models/word_card.dart';

/// A browser tab draws the mark at 16px, and at 16px the mark it draws has to
/// be a different drawing.
///
/// Three things go wrong at that size and none of them is a rendering bug:
/// the two cards use only about two thirds of their box, so a 16px icon spends
/// a third of itself on margin; the part-of-speech tick is 6.8% of a card's
/// width, which at 16px is under half a pixel; and the two shadows, which sit
/// a card on a table at 148px, are grey mud under a 6px card. `compact` is the
/// optical size that answers all three. It is asked for rather than inferred —
/// a mark that silently becomes a different mark below a threshold is a mark
/// nobody can predict.
Future<({Uint32List pixels, int side})> render(
  int px, {
  required bool compact,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  Materials.table(canvas, Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));
  DrippleMarkPainter(progress: 1, compact: compact)
      .paint(canvas, Size.square(px.toDouble()));

  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return (pixels: data!.buffer.asUint32List(), side: px);
}

/// Pixels that are actually [target], not a wash of it.
///
/// The tolerance is tight on purpose. Loose enough (60 was tried) and the dark
/// table ground counts as the adjective's navy, which reports the plain mark
/// as carrying accents it has entirely lost — the measurement inventing the
/// result. At 30 a pixel has to be the colour.
int countNear(Uint32List pixels, Color target, {int tolerance = 30}) {
  final tr = (target.r * 255).round();
  final tg = (target.g * 255).round();
  final tb = (target.b * 255).round();
  var n = 0;
  for (final p in pixels) {
    // rawRgba is little-endian ABGR in a Uint32.
    final r = p & 0xFF;
    final g = (p >> 8) & 0xFF;
    final b = (p >> 16) & 0xFF;
    if ((r - tr).abs() <= tolerance &&
        (g - tg).abs() <= tolerance &&
        (b - tb).abs() <= tolerance) {
      n++;
    }
  }
  return n;
}

/// How much of the box the paper actually covers, as a fraction of the side.
double paperSpan(Uint32List pixels, int side) {
  var left = side, right = -1, top = side, bottom = -1;
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final p = pixels[y * side + x];
      final r = p & 0xFF;
      final g = (p >> 8) & 0xFF;
      final b = (p >> 16) & 0xFF;
      // The stock is the only near-white thing in the picture.
      if (r > 200 && g > 195 && b > 185) {
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }
  if (right < 0) return 0;
  final w = (right - left + 1) / side;
  final h = (bottom - top + 1) / side;
  return w > h ? w : h;
}

void main() {
  final verb = AppColors.forPartOfSpeech(PartOfSpeech.verb);
  final adjective = AppColors.forPartOfSpeech(PartOfSpeech.adjective);

  test('at tab size both accents survive, and without compact they do not',
      () async {
    final small = await render(16, compact: true);
    final plain = await render(16, compact: false);

    // The whole statement the mark makes is "two words, of different kinds".
    // If only one colour lands, the mark at 16px is a pale rectangle.
    expect(countNear(small.pixels, verb), greaterThanOrEqualTo(2),
        reason: 'the verb tick has to land on at least a couple of pixels');
    expect(countNear(small.pixels, adjective), greaterThanOrEqualTo(2),
        reason: 'and so does the adjective tick');

    // And the reason compact exists: at this size the plain mark keeps no
    // pixel of either colour at all. Not fewer — none.
    expect(countNear(plain.pixels, verb), 0);
    expect(countNear(plain.pixels, adjective), 0);
  });

  test('compact spends the box on the cards rather than on margin', () async {
    final small = await render(64, compact: true);
    final plain = await render(64, compact: false);

    expect(paperSpan(small.pixels, 64), greaterThan(0.85),
        reason: 'a favicon cannot afford a third of itself as margin');
    expect(paperSpan(plain.pixels, 64), lessThan(0.8),
        reason: 'the full-size mark keeps its breathing room');
  });

  test('compact is a different painting, so it repaints', () {
    const plain = DrippleMarkPainter(progress: 1);
    const small = DrippleMarkPainter(progress: 1, compact: true);
    expect(plain.shouldRepaint(small), isTrue);
    expect(small.shouldRepaint(small), isFalse);
  });

  testWidgets('the mark a screen shows is untouched by any of this',
      (tester) async {
    // `compact` is off unless asked for, and nothing in the app asks.
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: DrippleMark(size: 148)),
    ));
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(DrippleMark),
        matching: find.byType(CustomPaint),
      ),
    );
    expect((paint.painter! as DrippleMarkPainter).compact, isFalse);
  });
}
