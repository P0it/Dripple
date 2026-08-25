import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/board_layout.dart';
import 'package:dripple/game/components/card_component.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple/models/word_card.dart';

/// Two cards is the smallest hand that can be reordered.
List<WordCard> _twoCards() => const [
      WordCard(id: 'a', word: 'cats', pos: PartOfSpeech.noun),
      WordCard(id: 'b', word: 'run', pos: PartOfSpeech.verb),
    ];

/// Drives a card through a real drag: press, move to [to], release.
///
/// Going through the component's own event handlers is the whole point — the
/// bug lived in `onDragEnd`, so a test that calls the `onDragEnded` callback
/// directly would sail straight past it.
void _drag(DrippleGame game, CardComponent card, Vector2 to) {
  card.onDragStart(
    DragStartEvent(1, game, DragStartDetails(globalPosition: Offset.zero)),
  );
  card.position = to;
  card.onDragEnd(DragEndEvent(1, DragEndDetails()));
}

void main() {
  testWithGame<DrippleGame>(
    'a card dropped on the other slot ends up in that slot',
    DrippleGame.new,
    (game) async {
      game.onSentenceReorder = (from, to) {
        final cards = List<WordCard>.from(game.debugSentenceZone);
        final moved = cards.removeAt(from);
        cards.insert(to, moved);
        game.updateSentenceZone(cards);
      };

      game.updateSentenceZone(_twoCards());
      await game.ready();

      final slots =
          SentenceLine.positions(game.size.x, 2, game.debugSentenceY);
      final first =
          game.debugSentenceComponents.firstWhere((c) => c.card.id == 'a');

      _drag(game, first, Vector2(slots[1].dx, slots[1].dy));

      // Let any settle animation run to completion.
      for (var i = 0; i < 40; i++) {
        game.update(0.016);
      }
      await game.ready();

      expect(game.debugSentenceZone.map((c) => c.id).toList(), ['b', 'a']);
      expect(first.position.x, closeTo(slots[1].dx, 1.0));
      expect(first.position.y, closeTo(slots[1].dy, 1.0));
    },
  );

  testWithGame<DrippleGame>(
    'a card dropped back on its own slot returns to where it started',
    DrippleGame.new,
    (game) async {
      var reorderCalls = 0;
      game.onSentenceReorder = (_, __) => reorderCalls++;

      game.updateSentenceZone(_twoCards());
      await game.ready();

      final first =
          game.debugSentenceComponents.firstWhere((c) => c.card.id == 'a');
      final home = first.position.clone();

      // Nudge it a few pixels — not far enough to change slot — and release.
      _drag(game, first, home + Vector2(6, 4));

      for (var i = 0; i < 40; i++) {
        game.update(0.016);
      }
      await game.ready();

      expect(reorderCalls, 0);
      expect(first.position.x, closeTo(home.x, 1.0));
      expect(first.position.y, closeTo(home.y, 1.0));
    },
  );
}
