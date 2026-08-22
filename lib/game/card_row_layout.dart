import 'components/card_component.dart';

/// Horizontal layout maths for a row of cards.
///
/// Extracted from [DrippleGame] so it can be tested without a running Flame
/// game loop — the overflow behaviour is the part most likely to regress.
class CardRowLayout {
  /// Space left on each side of the row.
  static const double edgePadding = 12;

  /// Gap between cards when they all fit.
  static const double preferredGap = 8;

  static const double _preferredStep =
      CardComponent.cardWidth + preferredGap;

  /// Distance between the left edges of adjacent cards.
  ///
  /// A full hand at full spacing is wider than a phone screen, so cards
  /// overlap once they would run off the edge — the way a real hand fans.
  /// Always leaves [edgePadding] on both sides so the outermost cards stay
  /// reachable.
  static double step(double screenWidth, int count) {
    if (count <= 1) return _preferredStep;

    final available =
        screenWidth - edgePadding * 2 - CardComponent.cardWidth;
    if (available <= 0) return _preferredStep;

    final fitted = available / (count - 1);
    return fitted < _preferredStep ? fitted : _preferredStep;
  }

  /// Total width the row occupies.
  static double totalWidth(double screenWidth, int count) {
    if (count <= 0) return 0;
    return (count - 1) * step(screenWidth, count) + CardComponent.cardWidth;
  }

  /// X coordinate of the left edge of the row, centred on screen.
  static double startX(double screenWidth, int count) {
    if (count <= 0) return 0;
    return (screenWidth - totalWidth(screenWidth, count)) / 2;
  }

  /// Which slot an x-coordinate falls into, for a row of [count] cards.
  static int indexAtX(double x, double screenWidth, int count) {
    if (count <= 1) return 0;
    final raw =
        ((x - startX(screenWidth, count)) / step(screenWidth, count)).round();
    return raw.clamp(0, count - 1);
  }
}
