import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The type scale. Three weights, six sizes, nothing else.
///
/// Pretendard is bundled rather than fetched so the first frame never shows a
/// fallback face. Korean, Latin, and numerals share one family, which is half
/// of what makes a layout read as tidy.
///
/// Every style here is set in **ink**, because most type in the app sits on
/// paper — panels, sheets, tiles, cards. Type placed directly on the table asks
/// for [onTable], and having to ask is the point: it keeps the two materials
/// from blurring into one another by accident.
abstract final class AppTypography {
  static const String family = 'Pretendard';

  static const display = TextStyle(
    fontFamily: family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const heading = TextStyle(
    fontFamily: family,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const label = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// The name of the game, set once — the splash and nowhere else yet.
  ///
  /// The only place in the app that is not Pretendard, and it is deliberate: a
  /// wordmark is not UI text. Set in the UI face it reads as a heading that
  /// happens to say "Dripple"; set in Fraunces it reads as a name printed on a
  /// box. `SOFT` rounds the terminals so the letters carry the same slightly
  /// absorbed edge the card stock has, and `opsz` is pinned near the top of
  /// its range because the mark is only ever seen large.
  ///
  /// Sizing is left to the caller — the splash sets it against the mark.
  static const wordmark = TextStyle(
    fontFamily: 'Fraunces',
    fontWeight: FontWeight.w700,
    fontVariations: [
      FontVariation('wght', 700),
      FontVariation('SOFT', 60),
      FontVariation('WONK', 0),
      FontVariation('opsz', 96),
    ],
    letterSpacing: -0.5,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  /// Recolours a style for the table. Secondary styles stay secondary.
  static TextStyle onTable(TextStyle style) => style.copyWith(
        color: style.color == AppColors.textSecondary
            ? AppColors.onTableSoft
            : AppColors.onTable,
      );
}
