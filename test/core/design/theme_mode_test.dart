import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/design/app_colors.dart';
import 'package:dripple/providers/theme_provider.dart';

/// The ground moves; the print does not.
///
/// A mode swap is the one thing in this design system that changes a colour at
/// runtime, so the invariants that survive it are worth stating out loud —
/// most of all the ones that are true of a real table and would be easy to
/// lose while picking hex values for the second palette.
void main() {
  // AppColors is a global, and a test that leaves it on the day palette hands
  // the next test somebody else's ground.
  tearDown(() => AppColors.use(AppMode.night));

  double lum(Color c) => c.computeLuminance();

  test('the ground moves', () {
    AppColors.use(AppMode.night);
    final night = AppColors.table;

    AppColors.use(AppMode.day);
    expect(AppColors.table, isNot(night));
    expect(lum(AppColors.table), greaterThan(lum(night)));
  });

  test('what is printed on a card does not', () {
    AppColors.use(AppMode.night);
    final printed = [
      AppColors.paper,
      AppColors.paperEdge,
      AppColors.paperShade,
      AppColors.ink,
      AppColors.inkSoft,
    ];

    AppColors.use(AppMode.day);
    expect(
      [
        AppColors.paper,
        AppColors.paperEdge,
        AppColors.paperShade,
        AppColors.ink,
        AppColors.inkSoft,
      ],
      printed,
      reason: 'turning a light on does not reprint a card',
    );
  });

  test('a card is never darker than the ground it lies on', () {
    for (final mode in AppMode.values) {
      AppColors.use(mode);
      expect(
        lum(AppColors.paper),
        greaterThanOrEqualTo(lum(AppColors.table)),
        reason: '$mode: a card catches at least as much light as the table',
      );
    }
  });

  test('by day the ground is the stock itself, on purpose', () {
    AppColors.use(AppMode.day);
    expect(
      AppColors.table,
      AppColors.paper,
      reason: 'A grey table was tried and rejected for being half a light. '
          'What separates a card from the ground by day is its shadow, not a '
          'contrast step — so if this ever stops being an equality, it is '
          'because somebody put the contrast step back.',
    );
  });

  test('the rail is raised and the well is cut, in both modes', () {
    for (final mode in AppMode.values) {
      AppColors.use(mode);
      expect(lum(AppColors.rail), greaterThan(lum(AppColors.table)),
          reason: '$mode: a raised strip catches more light');
      expect(lum(AppColors.well), lessThan(lum(AppColors.table)),
          reason: '$mode: a hole cut in the table is darker than the table');
    }
  });

  test('type on the ground separates from it, in both modes', () {
    for (final mode in AppMode.values) {
      AppColors.use(mode);
      final gap = (lum(AppColors.onTable) - lum(AppColors.table)).abs();
      expect(gap, greaterThan(0.5), reason: '$mode: onTable must read');
    }
  });

  test('the generation moves only when the ground actually changes', () {
    AppColors.use(AppMode.night);
    final start = AppColors.generation;

    AppColors.use(AppMode.night);
    expect(AppColors.generation, start, reason: 'nothing changed');

    AppColors.use(AppMode.day);
    expect(AppColors.generation, greaterThan(start));
  });

  group('the choice resolves against the phone', () {
    test('system follows the platform', () {
      expect(
        ThemeNotifier.resolve(ThemeChoice.system, Brightness.light),
        AppMode.day,
      );
      expect(
        ThemeNotifier.resolve(ThemeChoice.system, Brightness.dark),
        AppMode.night,
      );
    });

    test('an explicit choice overrides it', () {
      expect(
        ThemeNotifier.resolve(ThemeChoice.night, Brightness.light),
        AppMode.night,
      );
      expect(
        ThemeNotifier.resolve(ThemeChoice.day, Brightness.dark),
        AppMode.day,
      );
    });
  });
}
