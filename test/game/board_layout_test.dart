
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/board_layout.dart';

void main() {
  group('HandFan', () {
    test('lays a small hand out at full width with gaps', () {
      final slots = HandFan.positions(390, 3, 400);
      final step = slots[1].dx - slots[0].dx;
      expect(step, closeTo(BoardLayout.cardWidth + HandFan.gap, 0.01));
    });

    test('overlaps rather than wrapping once the row is full', () {
      // The whole point of the redesign: one line, always. A seventh card
      // tightens the overlap; it never starts a second row.
      for (var count = 1; count <= 9; count++) {
        final slots = HandFan.positions(390, count, 400);
        expect(slots, hasLength(count));
        final tops = slots.map((s) => s.dy).toSet();
        // The arc moves cards vertically, but never by a card's height —
        // that would be a second row.
        expect(tops.reduce((a, b) => a > b ? a : b) -
            tops.reduce((a, b) => a < b ? a : b),
            lessThan(BoardLayout.cardHeight));
      }
    });

    test('keeps the whole row on screen', () {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        for (var count = 1; count <= 9; count++) {
          final slots = HandFan.positions(width, count, 400);
          // Measured against the width the cards actually are: the fan shrinks
          // them to keep a readable sliver showing, so the constant is not the
          // right edge any more.
          final card = HandFan.cardSize(width, count);
          expect(slots.first.dx, greaterThanOrEqualTo(-0.01),
              reason: '$count cards on a ${width.toInt()}pt screen');
          expect(slots.last.dx + card.width, lessThanOrEqualTo(width + 0.01),
              reason: '$count cards on a ${width.toInt()}pt screen');
        }
      }
    });

    test('the middle of the fan sits square and the ends splay', () {
      expect(HandFan.lean(0, 5), lessThan(0));
      expect(HandFan.lean(2, 5), closeTo(0, 0.001));
      expect(HandFan.lean(4, 5), greaterThan(0));
      expect(HandFan.lean(0, 1), 0);
    });

    test('a point lands on the card nearest it', () {
      final slots = HandFan.positions(390, 5, 400);
      for (var i = 0; i < slots.length; i++) {
        expect(HandFan.indexAt(slots[i], 390, 5, 400), i);
      }
    });
  });

  group('SentenceLine', () {
    test('does not shrink a line that already fits', () {
      expect(SentenceLine.scaleFor(390, 1), 1);
      expect(SentenceLine.scaleFor(390, 4), 1);
    });

    test('shrinks rather than overlapping or wrapping', () {
      // A sentence has to be read left to right, so the cards give up size
      // before they give up either of those.
      for (var count = 1; count <= 7; count++) {
        final scale = SentenceLine.scaleFor(390, count);
        final w = BoardLayout.cardWidth * scale;
        final slots = SentenceLine.positions(390, count, 400);

        for (var i = 1; i < slots.length; i++) {
          expect(slots[i].dx - slots[i - 1].dx, greaterThanOrEqualTo(w - 0.01),
              reason: 'cards overlap at $count');
        }
        expect(slots.map((s) => s.dy).toSet(), hasLength(1),
            reason: 'the line wrapped at $count');
        expect(slots.first.dx, greaterThanOrEqualTo(-0.01));
        expect(slots.last.dx + w, lessThanOrEqualTo(390 + 0.01));
      }
    });

    test('stays centred on the same eye level however much it shrinks', () {
      double centre(int count) {
        final s = SentenceLine.positions(390, count, 400).first;
        return s.dy + SentenceLine.cardSize(390, count).height / 2;
      }

      expect(centre(2), closeTo(400, 0.01));
      expect(centre(7), closeTo(400, 0.01));
    });

    test('an inserting card measures against the post-insert line', () {
      // Measuring against the pre-insert layout is what made every dropped
      // card land at the tail.
      const existing = 3;
      final after = SentenceLine.positions(390, existing + 1, 400);
      for (var i = 0; i <= existing; i++) {
        expect(
          SentenceLine.insertionIndexAt(after[i], 390, existing, 400),
          i,
          reason: 'slot $i',
        );
      }
    });

    test('an empty line takes a card at the front', () {
      expect(
        SentenceLine.insertionIndexAt(const Offset(999, 999), 390, 0, 400),
        0,
      );
    });

    test('a dropped card lands in the slot it was dropped on', () {
      final slots = SentenceLine.positions(390, 4, 400);
      for (var i = 0; i < slots.length; i++) {
        expect(SentenceLine.indexAt(slots[i], 390, 4, 400), i);
      }
      final nudged = slots[2] + const Offset(6, 4);
      expect(SentenceLine.indexAt(nudged, 390, 4, 400), 2);
    });
  });
}
