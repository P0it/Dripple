@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/core/design/app_colors.dart';

/// Renders the mark on the grounds it actually has to live on, so it can be
/// looked at rather than argued about.
void main() {
  test('preview the mark on felt, on paper and small', () async {
    const cell = 320.0;
    const strip = Size(cell * 3, cell);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    void ground(Rect r, Color c) => canvas.drawRect(r, Paint()..color = c);

    ground(const Rect.fromLTWH(0, 0, cell, cell), AppColors.table);
    ground(const Rect.fromLTWH(cell, 0, cell, cell), const Color(0xFFFFFFFF));
    ground(const Rect.fromLTWH(cell * 2, 0, cell, cell), AppColors.table);

    void mark(double x, double y, double size, {bool onLight = false}) {
      canvas.save();
      canvas.translate(x, y);
      DrippleMarkPainter(progress: 1, onLight: onLight)
          .paint(canvas, Size.square(size));
      canvas.restore();
    }

    mark(30, 30, 260);
    mark(cell + 30, 30, 260, onLight: true);

    // Small sizes, where a mark either survives or does not.
    var x = cell * 2 + 24;
    for (final s in [96.0, 48.0, 24.0, 16.0]) {
      mark(x, cell / 2 - s / 2, s);
      x += s + 20;
    }

    final image = await recorder
        .endRecording()
        .toImage(strip.width.toInt(), strip.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/launch/mark_preview.png');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
    expect(out.existsSync(), isTrue);
  });
}
