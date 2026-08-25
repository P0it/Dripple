import 'dart:math' as math;
import 'dart:ui';

import 'card_painter.dart';

/// Where the cards on the board go.
///
/// There is one hand, not a hand and a tray. The cards you are holding back
/// stay fanned on the rail; the cards you are playing are pushed forward, up
/// and clear of the fan, where they read as a line. That is the gesture a
/// player already makes at a table — you push what you are playing toward the
/// middle — and it is why there is no box to drop things into.
///
/// The two layouts differ because the two states have different jobs. A held
/// card only has to be *identifiable*, so the fan overlaps and lets the corner
/// index carry it. A played card has to be *read*, so the line never overlaps
/// and shrinks instead.
abstract final class BoardLayout {
  /// Space left on each side of the board.
  static const double edgePadding = 10;

  static const double cardWidth = CardPainter.defaultWidth;
  static const double cardHeight = CardPainter.defaultHeight;

  static double usableWidth(double screenWidth) =>
      math.max(cardWidth, screenWidth - edgePadding * 2);

  /// Nearest slot to [position] among [slots], comparing top-left corners.
  static int nearestSlot(List<Offset> slots, Offset position) {
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < slots.length; i++) {
      final d = (slots[i] - position).distanceSquared;
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    return best;
  }
}

/// The cards you are holding back: one overlapping, slightly curved row.
///
/// Overlap used to be forbidden — "a child who cannot read the card cannot
/// play it" — and that was right at the time, because a card carried its
/// identity only in the word across its middle. A card now carries a
/// dictionary abbreviation and a suit pip in its corner, which is precisely
/// what a corner index is for: being read while the card is covered. The ban
/// went with the thing that made it necessary.
abstract final class HandFan {
  /// Gap between cards when they all fit at full width.
  static const double gap = 8;

  /// How far the outer cards dip below the middle one, and how far they lean.
  /// Small on purpose: enough that the row reads as held rather than stacked,
  /// not so much that the ends fall off the rail.
  static const double arcRise = 9;
  static const double arcLean = 0.075; // radians at the ends, ~4.3°

  /// How far a leaning card's corner swings outside its own box. The fan is
  /// inset by this much so the ends stay on the ledge instead of hanging over
  /// the edge of the screen.
  static double get leanMargin => BoardLayout.cardHeight / 2 * arcLean + 1;

  /// Width the fan may spread across — the rail's width, less the room a
  /// leaning card needs at each end.
  static double _usable(double screenWidth) => math.max(
        BoardLayout.cardWidth,
        BoardLayout.usableWidth(screenWidth) - leanMargin * 2,
      );

  /// Distance between the left edges of adjacent cards.
  ///
  /// Full width plus a gap while they fit; once they do not, whatever gets
  /// them all onto one line. The line never wraps and the card never shrinks —
  /// the overlap absorbs it.
  static double step(double screenWidth, int count) {
    if (count <= 1) return BoardLayout.cardWidth + gap;
    final spread =
        (_usable(screenWidth) - BoardLayout.cardWidth) / (count - 1);
    return math.min(BoardLayout.cardWidth + gap, math.max(18, spread));
  }

  /// Top-left offsets, laid out around [centerY].
  static List<Offset> positions(
      double screenWidth, int count, double centerY) {
    if (count <= 0) return const [];

    final s = step(screenWidth, count);
    final rowWidth = (count - 1) * s + BoardLayout.cardWidth;
    final left = (screenWidth - rowWidth) / 2;
    final top = centerY - BoardLayout.cardHeight / 2;

    return [
      for (var i = 0; i < count; i++)
        Offset(left + i * s, top + arcRise * _curve(i, count)),
    ];
  }

  /// How far each card leans, in radians. The middle sits square and the ends
  /// splay, which is what makes the row read as a fan and not as a stack that
  /// slipped.
  static double lean(int index, int count) {
    if (count <= 1) return 0;
    return _across(index, count) * arcLean;
  }

  /// -1 at the left end, 0 in the middle, 1 at the right.
  static double _across(int index, int count) =>
      count <= 1 ? 0 : (index / (count - 1)) * 2 - 1;

  /// 0 in the middle, 1 at both ends.
  static double _curve(int index, int count) {
    final t = _across(index, count);
    return t * t;
  }

  /// Total vertical space the fan occupies, arc included.
  static double blockHeight(int count) =>
      count <= 0 ? 0 : BoardLayout.cardHeight + (count > 1 ? arcRise : 0);

  /// Which card is showing at [x] — the one a thumb resting there is touching.
  ///
  /// Not the nearest slot: the fan overlaps, and the card you are touching is
  /// the topmost one covering that point, which is the last one whose left
  /// edge is left of the finger. Nearest-slot would hand you the card behind.
  static int indexUnder(
      double x, double screenWidth, int count, double centerY) {
    if (count <= 0) return -1;
    final slots = positions(screenWidth, count, centerY);
    for (var i = count - 1; i >= 0; i--) {
      if (x >= slots[i].dx) return i;
    }
    return 0;
  }

  /// Which card a point falls on, by nearest slot.
  static int indexAt(
      Offset position, double screenWidth, int count, double centerY) {
    if (count <= 1) return 0;
    return BoardLayout.nearestSlot(
        positions(screenWidth, count, centerY), position);
  }
}

/// The cards you have pushed forward: one line, never overlapping.
///
/// A sentence has to be read left to right, so this line never wraps and never
/// covers a word. When it outgrows the board the cards shrink instead — which
/// only happens once you have already built a long sentence, and a long
/// sentence is the thing worth seeing whole.
abstract final class SentenceLine {
  static const double gap = 6;

  /// How much the cards shrink to fit [count] of them on one line.
  static double scaleFor(double screenWidth, int count) {
    if (count <= 0) return 1;
    final needed = count * BoardLayout.cardWidth + (count - 1) * gap;
    final available = BoardLayout.usableWidth(screenWidth);
    return math.min(1, available / needed);
  }

  static Size cardSize(double screenWidth, int count) {
    final s = scaleFor(screenWidth, count);
    return Size(BoardLayout.cardWidth * s, BoardLayout.cardHeight * s);
  }

  /// Top-left offsets, laid out around [centerY].
  ///
  /// Cards are centred on [centerY] rather than top-aligned so a line that has
  /// shrunk still sits on the same eye level as one that has not.
  static List<Offset> positions(
      double screenWidth, int count, double centerY) {
    if (count <= 0) return const [];

    final s = scaleFor(screenWidth, count);
    final w = BoardLayout.cardWidth * s;
    final g = gap * s;
    final rowWidth = count * w + (count - 1) * g;
    final left = (screenWidth - rowWidth) / 2;
    final top = centerY - BoardLayout.cardHeight * s / 2;

    return [for (var i = 0; i < count; i++) Offset(left + i * (w + g), top)];
  }

  /// Where a card arriving from the hand should be inserted.
  ///
  /// Distinct from [indexAt]: an arriving card makes the line one longer, so
  /// the slots it can land on are the *post-insert* ones — [currentCount] + 1
  /// of them. Measuring against the pre-insert layout is what made every
  /// dropped card land at the tail.
  static int insertionIndexAt(
      Offset position, double screenWidth, int currentCount, double centerY) {
    if (currentCount <= 0) return 0;
    return BoardLayout.nearestSlot(
      positions(screenWidth, currentCount + 1, centerY),
      position,
    );
  }

  /// Which slot a dropped card's top-left corner falls into.
  static int indexAt(
      Offset position, double screenWidth, int count, double centerY) {
    if (count <= 1) return 0;
    return BoardLayout.nearestSlot(
        positions(screenWidth, count, centerY), position);
  }
}
