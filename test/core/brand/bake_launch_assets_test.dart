@Tags(['bake'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';

/// Bakes the brand mark to PNG for the native launch screens and the app
/// icon, which cannot run Dart.
///
/// Not part of the normal suite — it is tagged `bake` and excluded in
/// dart_test.yaml. Run it deliberately:
///
///   flutter test --tags bake test/core/brand/bake_launch_assets_test.dart
///
/// Output lands in build/launch/ for the copy step in the plan.
void main() {
  test('bake the launch mark at four densities', () async {
    const densities = {'mdpi': 96, 'hdpi': 144, 'xhdpi': 192, 'xxhdpi': 288};

    final dir = Directory('build/launch');
    await dir.create(recursive: true);

    for (final entry in densities.entries) {
      final px = entry.value;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const DrippleMarkPainter(progress: 1, color: Color(0xFF1D74F5))
          .paint(canvas, Size(px.toDouble(), px.toDouble()));

      final image = await recorder.endRecording().toImage(px, px);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('${dir.path}/splash_mark_${entry.key}.png');
      await out.writeAsBytes(bytes!.buffer.asUint8List());
      expect(out.existsSync(), isTrue);
    }
  });
}
