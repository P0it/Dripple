import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/game/card_row_layout.dart';
import 'package:dripple/game/components/card_component.dart';

/// The row must never run off screen — on a phone a full hand at full
/// spacing is roughly 700px wide, which put the outermost cards out of reach.
void main() {
  const phone = 390.0;
  const tablet = 1200.0;

  group('step', () {
    test('uses full spacing when the row fits', () {
      expect(CardRowLayout.step(tablet, 7),
          CardComponent.cardWidth + CardRowLayout.preferredGap);
    });

    test('tightens the spacing when the row would overflow', () {
      final s = CardRowLayout.step(phone, 7);
      expect(s, lessThan(CardComponent.cardWidth + CardRowLayout.preferredGap));
      expect(s, greaterThan(0));
    });

    test('a single card uses full spacing', () {
      expect(CardRowLayout.step(phone, 1),
          CardComponent.cardWidth + CardRowLayout.preferredGap);
    });
  });

  group('the row always stays on screen', () {
    for (final width in [320.0, 390.0, 430.0, 768.0, 1200.0]) {
      for (final count in [1, 2, 5, 7, 8, 12, 20]) {
        test('${width.toInt()}px wide, $count cards', () {
          final start = CardRowLayout.startX(width, count);
          final end = start + CardRowLayout.totalWidth(width, count);

          expect(start, greaterThanOrEqualTo(CardRowLayout.edgePadding - 0.01),
              reason: 'row starts off the left edge');
          expect(end, lessThanOrEqualTo(width - CardRowLayout.edgePadding + 0.01),
              reason: 'row runs past the right edge');
        });
      }
    }
  });

  group('indexAtX', () {
    // indexAtX receives a dragged card's left edge, so slot i is anchored
    // at start + i * step.
    test('maps each slot position back to its own index', () {
      const count = 7;
      final step = CardRowLayout.step(phone, count);
      final start = CardRowLayout.startX(phone, count);

      for (int i = 0; i < count; i++) {
        expect(CardRowLayout.indexAtX(start + i * step, phone, count), i,
            reason: 'exact slot $i');
        expect(
            CardRowLayout.indexAtX(start + i * step + step * 0.3, phone, count),
            i,
            reason: 'slot $i, dragged slightly right');
      }
    });

    test('dragging past halfway lands in the next slot', () {
      const count = 7;
      final step = CardRowLayout.step(phone, count);
      final start = CardRowLayout.startX(phone, count);

      expect(CardRowLayout.indexAtX(start + step * 0.7, phone, count), 1);
    });

    test('clamps coordinates outside the row', () {
      expect(CardRowLayout.indexAtX(-500, phone, 7), 0);
      expect(CardRowLayout.indexAtX(5000, phone, 7), 6);
    });
  });
}
