import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/card_painter.dart';

/// The design package is meant to be the only place a colour is defined, and
/// materiality is meant to be a decision rather than a habit.
///
/// These guard both boundaries — cheap, and they catch the regressions that
/// actually happen.
///
/// The earlier version of this file banned gradients and shadows outright, on
/// behalf of a "restraint over decoration" rule the 2026-08-25 redesign
/// repealed. A card game is made of stock, ground, bevel, and contact shadow, so
/// a blanket ban could not survive the goal. What replaced it is narrower:
///
/// > Paper takes the brand. Furniture takes brass.
///
/// A gradient that describes a lit surface is furniture and belongs in a
/// painter. A gradient on a button because it looked flat is decoration and
/// belongs nowhere. The tests below cannot tell those apart by taste, so they
/// guard the thing they can: material is authored in the design package and in
/// `lib/game/`, and never invented inside a screen.
void main() {
  List<File> dartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// Where surface may be authored.
  bool isMaterialAuthor(String path) =>
      path.startsWith('lib/core/design/') ||
      path.startsWith('lib/game/') ||
      path == 'lib/core/game_icons.dart' ||
      path == 'lib/core/brand/dripple_mark.dart';

  test('the legacy theme file is gone', () {
    expect(File('lib/core/theme/app_theme.dart').existsSync(), isFalse);
    expect(Directory('lib/core/theme').existsSync(), isFalse);
  });

  test('nothing imports the legacy theme', () {
    final offenders = dartFiles()
        .where((f) => f.readAsStringSync().contains('core/theme/app_theme'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });

  test('screens do not define their own colours', () {
    // Painters legitimately take dart:ui colours because they cannot reach
    // the widget layer. Screens have no such excuse.
    final hex = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
    final offenders = dartFiles()
        .where((f) => !isMaterialAuthor(f.path))
        .where((f) => hex.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty, reason: 'move these into AppColors');
  });

  test('gradients are authored as material, never inside a screen', () {
    final gradient = RegExp(r'Gradient\.(radial|linear|sweep)|LinearGradient|'
        r'RadialGradient|SweepGradient');
    final offenders = dartFiles()
        .where((f) => !isMaterialAuthor(f.path))
        .where((f) => gradient.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty,
        reason: 'a gradient describes a surface — put it in Materials');
  });

  test('a shadow a screen paints is coloured from the palette', () {
    // Shadows are allowed now: paper on a table casts one. What is not allowed
    // is a screen inventing the colour of the light.
    // Capture the colour expression and read it, rather than asserting with a
    // negative lookahead: `\s*` happily backtracks to zero width, which makes
    // the lookahead pass on every well-behaved shadow in the codebase.
    final shadowColour = RegExp(r'BoxShadow\([^)]*?color:\s*([\w.]+)');
    final offenders = dartFiles()
        .where((f) => !isMaterialAuthor(f.path))
        .where((f) => shadowColour
            .allMatches(f.readAsStringSync())
            .any((m) => !m.group(1)!.startsWith('AppColors.')))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty,
        reason: 'shadow colours come from AppColors, like every other colour');
  });

  test('a card keeps its poker proportion', () {
    // 63:88. The proportion is the single thing most likely to drift back
    // toward the rounded rectangle this redesign replaced, so it is pinned.
    expect(
      CardPainter.defaultHeight / CardPainter.defaultWidth,
      closeTo(88 / 63, 0.001),
    );
    // And a real card's corner is a twentieth of its width, not a seventh.
    expect(CardPainter.radiusRatio, lessThan(0.08));
  });
}
