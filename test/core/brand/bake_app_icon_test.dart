@Tags(['bake'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/core/design/materials.dart';

/// Bakes the app icon from the mark, at every size the two stores ask for.
///
/// The icon is the mark on the table, because the mark is two cards of warm
/// stock and stock has nothing to be against a white home screen. The ground
/// is [Materials.table] rather than a flat fill picked here — the icon stands
/// on the same surface the game does.
///
/// Not part of the normal suite. Run it deliberately:
///
///   flutter test --tags bake --run-skipped test/core/brand/bake_app_icon_test.dart
///
/// Output lands in build/icons/ for the copy step below the test.
void main() {
  /// How much of the canvas the mark's own box takes.
  ///
  /// The mark already leaves margin inside its box — the pair fills about 64%
  /// of it — so these are multipliers on top of that. Full bleed can use the
  /// whole canvas; a maskable icon has to stay inside the circle the launcher
  /// may cut, and Android's adaptive foreground inside its 66.7% safe zone.
  const fullBleed = 1.0;
  const maskable = 0.84;
  const adaptive = 0.88;

  Future<void> bake(
    String path,
    int px, {
    required double fill,
    bool ground = true,
    bool compact = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = px.toDouble();

    if (ground) {
      Materials.table(canvas, Rect.fromLTWH(0, 0, size, size));
    }

    final inner = size * fill;
    canvas.save();
    canvas.translate((size - inner) / 2, (size - inner) / 2);
    DrippleMarkPainter(progress: 1, compact: compact)
        .paint(canvas, Size.square(inner));
    canvas.restore();

    final image = await recorder.endRecording().toImage(px, px);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  }

  test('bake the app icon for iOS, Android and the web', () async {
    // ---- iOS: one file per size the asset catalogue names.
    const ios = {
      'Icon-App-20x20@1x': 20,
      'Icon-App-20x20@2x': 40,
      'Icon-App-20x20@3x': 60,
      'Icon-App-29x29@1x': 29,
      'Icon-App-29x29@2x': 58,
      'Icon-App-29x29@3x': 87,
      'Icon-App-40x40@1x': 40,
      'Icon-App-40x40@2x': 80,
      'Icon-App-40x40@3x': 120,
      'Icon-App-60x60@2x': 120,
      'Icon-App-60x60@3x': 180,
      'Icon-App-76x76@1x': 76,
      'Icon-App-76x76@2x': 152,
      'Icon-App-83.5x83.5@2x': 167,
      'Icon-App-1024x1024@1x': 1024,
    };
    for (final e in ios.entries) {
      await bake('build/icons/ios/${e.key}.png', e.value, fill: fullBleed);
    }

    // ---- Android: the legacy square, and the adaptive foreground that
    // replaces it on Android 8 and up. The adaptive layer carries no ground —
    // the background is a colour resource, so the launcher can animate them.
    const legacy = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final e in legacy.entries) {
      await bake('build/icons/android/mipmap-${e.key}/ic_launcher.png', e.value,
          fill: maskable);
    }

    // 108dp foreground at each density, mark inside the 72dp safe zone.
    const foreground = {
      'mdpi': 108,
      'hdpi': 162,
      'xhdpi': 216,
      'xxhdpi': 324,
      'xxxhdpi': 432,
    };
    for (final e in foreground.entries) {
      await bake(
        'build/icons/android/drawable-${e.key}/ic_launcher_foreground.png',
        e.value,
        fill: adaptive,
        ground: false,
      );
    }

    // ---- Web: the PWA pair, their maskable twins, and the tab favicon.
    await bake('build/icons/web/Icon-192.png', 192, fill: fullBleed);
    await bake('build/icons/web/Icon-512.png', 512, fill: fullBleed);
    await bake('build/icons/web/Icon-maskable-192.png', 192, fill: maskable);
    await bake('build/icons/web/Icon-maskable-512.png', 512, fill: maskable);
    // The tab favicon, at the sizes a browser actually asks for rather than
    // one file it has to shrink. A 64px icon resampled to 16 is the mark's
    // three small-size failures plus a resampling blur on top, and the browser
    // will always pick an exact match over a downscale when it is offered one.
    //
    // These are the only icons drawn compact: everything above is 48px or
    // larger, where the full-size drawing is what the mark should be.
    for (final px in [16, 32, 48]) {
      await bake('build/icons/web/favicon-$px.png', px,
          fill: fullBleed, compact: true);
    }
    // Kept for anything that asks for the old path by name.
    await bake('build/icons/web/favicon.png', 32,
        fill: fullBleed, compact: true);

    expect(File('build/icons/ios/Icon-App-1024x1024@1x.png').existsSync(),
        isTrue);
  });
}
