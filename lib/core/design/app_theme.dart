import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles [ThemeData] from the tokens. No colour or size is invented here.
///
/// The ground is felt and the surfaces are paper, so the two are separated by
/// material rather than by a contrast step: a panel is lighter *and* warmer
/// *and* casts a shadow, because that is what a sheet of paper on a table
/// does. Buttons are keys — they have a real elevation, which is the one lift
/// furniture gets.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.family,
        scaffoldBackgroundColor: AppColors.feltCore,
        colorScheme: const ColorScheme.light(
          primary: AppColors.point,
          onPrimary: Colors.white,
          secondary: AppColors.trim,
          onSecondary: AppColors.ink,
          surface: AppColors.paper,
          onSurface: AppColors.ink,
          error: AppColors.danger,
        ),
        dividerColor: AppColors.paperEdge,
        splashFactory: InkSparkle.splashFactory,
        textTheme: const TextTheme(
          displaySmall: AppTypography.display,
          titleLarge: AppTypography.title,
          titleMedium: AppTypography.heading,
          bodyLarge: AppTypography.body,
          labelLarge: AppTypography.label,
          bodySmall: AppTypography.caption,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.onFelt,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: AppTypography.onFelt(AppTypography.heading),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // Cream, not blue. A button is furniture, and the rule says so —
            // but the reason is plainer than the rule: blue and green sit at
            // the same luminance in opposite hues, and a blue key on a green
            // table reads as neither one thing nor the other. Cream is the
            // one value that separates from felt at any lighting.
            backgroundColor: AppColors.trim,
            foregroundColor: AppColors.ink,
            disabledBackgroundColor: AppColors.trimDim,
            disabledForegroundColor: AppColors.onFeltSoft,
            minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
            // A key on a table, not a rectangle on a page.
            elevation: 4,
            shadowColor: AppColors.feltEdge,
            textStyle: AppTypography.label.copyWith(fontSize: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onFeltSoft,
            minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
            textStyle: AppTypography.label,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppColors.onFeltSoft,
            minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.paper,
          elevation: 3,
          shadowColor: AppColors.feltEdge,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.paper,
          elevation: 8,
          shadowColor: AppColors.feltEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.paper,
          elevation: 12,
          shadowColor: AppColors.feltEdge,
          showDragHandle: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.point
                : AppColors.border,
          ),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      );
}
