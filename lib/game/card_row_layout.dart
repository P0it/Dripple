import 'dart:math' as math;
import 'dart:ui';

import 'card_painter.dart';

/// Where each card in a hand or sentence goes.
///
/// Cards wrap onto extra rows rather than overlapping. Overlapping fits more
/// cards but hides the word, and a child who cannot read the card cannot play
/// it — so the row count grows instead of the card shrinking.
class CardRowLayout {
  const CardRowLayout._();

  /// Space left on each side of the board.
  static const double edgePadding = 12;

  /// Gap between cards, horizontally and between rows.
  static const double gap = 8;

  static const double cardWidth = CardPainter.defaultWidth;
  static const double cardHeight = CardPainter.defaultHeight;

  /// How many cards fit on one row at this width. Always at least one.
  static int perRow(double screenWidth) {
    final usable = screenWidth - edgePadding * 2 + gap;
    final fit = usable ~/ (cardWidth + gap);
    return math.max(1, fit);
  }

  /// Number of rows [count] cards occupy.
  static int rowCount(double screenWidth, int count) {
    if (count <= 0) return 0;
    return (count / perRow(screenWidth)).ceil();
  }

  /// Total height of the block, including the gaps between rows.
  static double blockHeight(double screenWidth, int count) {
    final rows = rowCount(screenWidth, count);
    if (rows == 0) return 0;
    return rows * cardHeight + (rows - 1) * gap;
  }

  /// Top-left offsets for every card, laid out around [centerY].
  ///
  /// Rows are centred horizontally; a short final row sits centred under the
  /// full ones rather than left-aligned, which reads as deliberate.
  static List<Offset> positions(double screenWidth, int count, double centerY) {
    if (count <= 0) return const [];

    final columns = perRow(screenWidth);
    final rows = rowCount(screenWidth, count);
    final blockTop = centerY - blockHeight(screenWidth, count) / 2;

    final out = <Offset>[];
    for (int row = 0; row < rows; row++) {
      final first = row * columns;
      final inRow = math.min(columns, count - first);
      final rowWidth = inRow * cardWidth + (inRow - 1) * gap;
      final startX = (screenWidth - rowWidth) / 2;
      final y = blockTop + row * (cardHeight + gap);

      for (int i = 0; i < inRow; i++) {
        out.add(Offset(startX + i * (cardWidth + gap), y));
      }
    }
    return out;
  }

  /// Which slot a dropped card's top-left corner falls into.
  static int indexAt(
      Offset position, double screenWidth, int count, double centerY) {
    if (count <= 1) return 0;

    final slots = positions(screenWidth, count, centerY);
    var best = 0;
    var bestDistance = double.infinity;
    for (int i = 0; i < slots.length; i++) {
      final d = (slots[i] - position).distanceSquared;
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    return best;
  }
}
