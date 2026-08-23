/// The 4pt grid, the three radii, and the touch minimums.
///
/// Touch targets are larger than an adult app's because the audience is
/// 6-10 year olds.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;

  static const double minTouch = 56;
  static const double buttonHeight = 60;
}
