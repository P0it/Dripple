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
/// identity only in the word across its middle. Everything on the face hangs
/// off the left margin now, inside the sliver a covered card still shows, so
/// overlap is allowed. It is allowed *up to a point*, and [minVisible] is the
/// point: the ban went with the thing that made it necessary, not with the
/// reason behind the ban.
abstract final class HandFan {
  /// Gap between cards when they all fit at full width.
  static const double gap = 8;

  /// The least of a covered card that stays showing, as a fraction of its
  /// width — enough for the whole of the longest word in the deck.
  ///
  /// Measured, not chosen. At the card's own type size the widest label needs
  /// `CardPainter.wordMaxWidth` plus the face's left margin, and the fraction
  /// is scale-invariant because the type scales with the card. Before this
  /// existed the floor was a flat 18pt — 21% of a card — and at a seven-card
  /// hand on a 390pt screen only half the deck's words survived it: `have`
  /// read as "have" with its last letter gone, `house` as "hous", `JOKER` as
  /// "JOK". A word game whose cards cannot be read is not a hard problem, it
  /// is the wrong answer.
  static const double minVisible = 0.85;

  /// How small a card may get in service of [minVisible]. Below this the type
  /// is too small for the audience, and a very large hand goes back to losing
  /// the ends of its longest words instead.
  static const double minScale = 0.62;

  /// How far the outer cards dip below the middle one, and how far they lean.
  /// Small on purpose: enough that the row reads as held rather than stacked,
  /// not so much that the ends fall off the rail.
  static const double arcRise = 9;
  static const double arcLean = 0.075; // radians at the ends, ~4.3°

  /// How far a leaning card's corner swings outside its own box. The fan is
  /// inset by this much so the ends stay on the ledge instead of hanging over
  /// the edge of the screen.
  static double leanMargin([double scale = 1]) =>
      BoardLayout.cardHeight * scale / 2 * arcLean + 1;

  /// Width the fan may spread across — the rail's width, less the room a
  /// leaning card needs at each end.
  static double _usable(double screenWidth, [double scale = 1]) => math.max(
        BoardLayout.cardWidth * scale,
        BoardLayout.usableWidth(screenWidth) - leanMargin(scale) * 2,
      );

  /// How much the cards shrink so that [count] of them fit on one line with
  /// [minVisible] of each still showing.
  ///
  /// This is the choice the row makes that [SentenceLine] makes too, and for
  /// the same reason: a held card has to be *identifiable* and a played card
  /// has to be *read*, but neither is either if the word is cut in half. The
  /// fan spent overlap first and shrank never; it now spends overlap down to
  /// the floor and then shrinks.
  static double scaleFor(double screenWidth, int count) {
    if (count <= 1) return 1;
    // leanMargin depends on the scale it is solving for, so solve at 1 and
    // then once more with the answer — it converges immediately at this size.
    var s = 1.0;
    for (var pass = 0; pass < 2; pass++) {
      final needed =
          BoardLayout.cardWidth * ((count - 1) * minVisible + 1);
      s = math.min(1, _usable(screenWidth, s) / needed);
    }
    return math.max(minScale, s);
  }

  static Size cardSize(double screenWidth, int count) {
    final s = scaleFor(screenWidth, count);
    return Size(BoardLayout.cardWidth * s, BoardLayout.cardHeight * s);
  }

  /// Distance between the left edges of adjacent cards, which is also how much
  /// of a covered card stays showing.
  ///
  /// Full width plus a gap while they fit, and otherwise whatever gets them all
  /// onto one line. The [minVisible] floor is not applied here: [scaleFor]
  /// has already shrunk the cards until the spread *is* the floor, so the two
  /// agree by construction — and where the scale has bottomed out at
  /// [minScale], the spread is the only honest answer, because a floor the row
  /// cannot afford would just push the fan off the screen.
  static double step(double screenWidth, int count) {
    if (count <= 1) return BoardLayout.cardWidth + gap;
    final w = cardSize(screenWidth, count).width;
    final spread = (_usable(screenWidth, w / BoardLayout.cardWidth) - w) /
        (count - 1);
    return math.min(w + gap, spread);
  }

  /// Top-left offsets, laid out around [centerY].
  static List<Offset> positions(
      double screenWidth, int count, double centerY) {
    if (count <= 0) return const [];

    final s = step(screenWidth, count);
    final card = cardSize(screenWidth, count);
    final rowWidth = (count - 1) * s + card.width;
    final left = (screenWidth - rowWidth) / 2;
    final top = centerY - card.height / 2;

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
  static double blockHeight(int count, [double screenWidth = double.infinity]) =>
      count <= 0
          ? 0
          : cardSize(screenWidth, count).height + (count > 1 ? arcRise : 0);

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
