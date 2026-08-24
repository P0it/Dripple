import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The type scale. Three weights, six sizes, nothing else.
///
/// Pretendard is bundled rather than fetched so the first frame never shows a
/// fallback face. Korean, Latin, and numerals share one family, which is half
/// of what makes a layout read as tidy.
///
/// Every style here is set in **ink**, because most type in the app sits on
/// paper — panels, sheets, tiles, cards. Type placed directly on the felt asks
/// for [onFelt], and having to ask is the point: it keeps the two materials
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

  /// Recolours a style for the felt. Secondary styles stay secondary.
  static TextStyle onFelt(TextStyle style) => style.copyWith(
        color: style.color == AppColors.textSecondary
            ? AppColors.onFeltSoft
            : AppColors.onFelt,
      );
}
