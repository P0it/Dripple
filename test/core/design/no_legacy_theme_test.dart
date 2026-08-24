import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The design package is meant to be the only place a colour is defined.
/// These guard that boundary — cheap, and they catch the one regression that
/// actually happens: someone pasting a hex literal into a screen.
void main() {
  List<File> dartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

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

  test('no gradient is constructed anywhere', () {
    final offenders = dartFiles()
        .where((f) => f.readAsStringSync().contains('LinearGradient'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });

  test('screens do not define their own colours', () {
    // Painters legitimately take dart:ui colours because they cannot reach
    // the widget layer. Screens have no such excuse.
    const allowed = {
      'lib/core/design/app_colors.dart',
      'lib/core/game_icons.dart',
      'lib/game/card_painter.dart',
      'lib/game/dripple_game.dart',
    };
    final hex = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
    final offenders = dartFiles()
        .where((f) => !allowed.contains(f.path))
        .where((f) => hex.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty, reason: 'move these into AppColors');
  });

  test('no widget paints a shadow', () {
    // The one shadow left in the app is the card's, and it lives in a
    // painter — on a card it reads as physical stock, not as UI chrome.
    final offenders = dartFiles()
        .where((f) => f.path != 'lib/game/card_painter.dart')
        .where((f) => f.readAsStringSync().contains('BoxShadow'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
