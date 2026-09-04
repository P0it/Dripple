@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/core/design/app_colors.dart';
import 'package:dripple/core/design/materials.dart';

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

  test('the mark at tab size, plain against compact', () async {
    // Blown up with nearest-neighbour so the pixels are visible, because at
    // these sizes the pixels are the whole argument: the plain mark's ticks
    // land on less than a pixel each and grey out, and a mark whose two
    // colours are gone is not saying the thing it exists to say.
    const sizes = [16, 24, 32, 48];
    const zoom = 9;

    final rows = <List<ui.Image>>[];
    for (final compact in [false, true]) {
      final row = <ui.Image>[];
      for (final px in sizes) {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        Materials.table(c, Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));
        DrippleMarkPainter(progress: 1, compact: compact)
            .paint(c, Size.square(px.toDouble()));
        row.add(await rec.endRecording().toImage(px, px));
      }
      rows.add(row);
    }

    const pad = 14.0;
    final cell = sizes.last * zoom.toDouble();
    final width = pad + sizes.length * (cell + pad);
    final height = pad + 2 * (cell + pad);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height),
        Paint()..color = const Color(0xFF2A2A2A));
    for (var r = 0; r < 2; r++) {
      var x = pad;
      for (var i = 0; i < sizes.length; i++) {
        final s = sizes[i] * zoom.toDouble();
        canvas.drawImageRect(
          rows[r][i],
          Rect.fromLTWH(0, 0, sizes[i].toDouble(), sizes[i].toDouble()),
          Rect.fromLTWH(x + (cell - s) / 2,
              pad + r * (cell + pad) + (cell - s) / 2, s, s),
          Paint()..filterQuality = FilterQuality.none,
        );
        x += cell + pad;
      }
    }

    final image = await recorder
        .endRecording()
        .toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/launch/favicon_before_after.png');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
    expect(out.existsSync(), isTrue);
  });
}
