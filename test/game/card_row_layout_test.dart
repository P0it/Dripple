import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/game/card_row_layout.dart';

/// Cards must never run off screen and must never overlap — a child who
/// cannot read a card cannot play it.
void main() {
  const widths = [320.0, 390.0, 430.0, 768.0, 1200.0];
  const counts = [1, 2, 4, 5, 7, 8, 12, 20];

  group('perRow', () {
    test('fits fewer cards on a narrow screen', () {
      expect(CardRowLayout.perRow(320), lessThan(CardRowLayout.perRow(1200)));
    });

    test('never returns zero, even on an absurdly narrow screen', () {
      expect(CardRowLayout.perRow(50), 1);
    });
  });

  group('rowCount', () {
    test('wraps onto extra rows instead of squeezing', () {
      final columns = CardRowLayout.perRow(390);
      expect(CardRowLayout.rowCount(390, columns), 1);
      expect(CardRowLayout.rowCount(390, columns + 1), 2);
    });

    test('no cards means no rows', () {
      expect(CardRowLayout.rowCount(390, 0), 0);
    });
  });

  for (final width in widths) {
    for (final count in counts) {
      test('${width.toInt()}px, $count cards: every card is fully on screen',
          () {
        final slots = CardRowLayout.positions(width, count, 400);
        expect(slots.length, count);

        for (final s in slots) {
          expect(s.dx, greaterThanOrEqualTo(-0.01),
              reason: 'card starts off the left edge');
          expect(s.dx + CardRowLayout.cardWidth,
              lessThanOrEqualTo(width + 0.01),
              reason: 'card runs past the right edge');
        }
      });

      test('${width.toInt()}px, $count cards: no two cards overlap', () {
        final slots = CardRowLayout.positions(width, count, 400);
        for (int i = 0; i < slots.length; i++) {
          for (int j = i + 1; j < slots.length; j++) {
            final dx = (slots[i].dx - slots[j].dx).abs();
            final dy = (slots[i].dy - slots[j].dy).abs();
            final overlaps = dx < CardRowLayout.cardWidth - 0.01 &&
                dy < CardRowLayout.cardHeight - 0.01;
            expect(overlaps, false,
                reason: 'cards $i and $j overlap at ${slots[i]} / ${slots[j]}');
          }
        }
      });
    }
  }

  group('indexAt', () {
    test('maps each slot back to its own index', () {
      const width = 390.0;
      const count = 7;
      final slots = CardRowLayout.positions(width, count, 400);
      for (int i = 0; i < count; i++) {
        expect(CardRowLayout.indexAt(slots[i], width, count, 400), i);
      }
    });

    test('picks the nearest slot for an in-between drop', () {
      const width = 390.0;
      const count = 7;
      final slots = CardRowLayout.positions(width, count, 400);
      final nudged = slots[2].translate(6, 4);
      expect(CardRowLayout.indexAt(nudged, width, count, 400), 2);
    });
  });
}
