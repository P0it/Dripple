import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/board_layout.dart';
import 'package:dripple/game/components/card_component.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple_rules/models/word_card.dart';

List<WordCard> _threeCards() => const [
      WordCard(id: 'a', word: 'runs', pos: PartOfSpeech.verb),
      WordCard(id: 'b', word: 'the', pos: PartOfSpeech.article),
      WordCard(id: 'c', word: 'cat', pos: PartOfSpeech.noun),
    ];

void _drag(DrippleGame game, CardComponent card, Vector2 to) {
  card.onDragStart(
    DragStartEvent(1, game, DragStartDetails(globalPosition: Offset.zero)),
  );
  card.position = to;
  card.onDragEnd(DragEndEvent(1, DragEndDetails()));
}

void main() {
  testWithGame<DrippleGame>(
    'a held card slid onto another card\'s slot takes that place',
    DrippleGame.new,
    (game) async {
      game.onHandReorder = (from, to) {
        final cards = List<WordCard>.from(game.debugHandComponents.map((c) => c.card));
        final moved = cards.removeAt(from);
        cards.insert(to, moved);
        game.updateHand(cards);
      };

      game.updateHand(_threeCards());
      await game.ready();

      final slots = HandFan.positions(game.size.x, 3, game.debugHandY);
      final first =
          game.debugHandComponents.firstWhere((c) => c.card.id == 'a');

      _drag(game, first, Vector2(slots[2].dx, slots[2].dy));
      for (var i = 0; i < 40; i++) {
        game.update(0.016);
      }
      await game.ready();

      expect(game.debugHandComponents.map((c) => c.card.id).toList(),
          ['b', 'c', 'a']);
    },
  );

  testWithGame<DrippleGame>(
    'a held card nudged in place is not a reorder',
    DrippleGame.new,
    (game) async {
      var calls = 0;
      game.onHandReorder = (_, __) => calls++;

      game.updateHand(_threeCards());
      await game.ready();

      final first =
          game.debugHandComponents.firstWhere((c) => c.card.id == 'a');
      _drag(game, first, first.position + Vector2(4, 3));
      for (var i = 0; i < 40; i++) {
        game.update(0.016);
      }

      expect(calls, 0);
    },
  );

  testWithGame<DrippleGame>(
    'a card pushed past the midline is still played, not reordered',
    DrippleGame.new,
    (game) async {
      var reorders = 0;
      int? played;
      game.onHandReorder = (_, __) => reorders++;
      game.onCardPlaced = (handIndex, _) => played = handIndex;

      game.updateHand(_threeCards());
      await game.ready();

      final first =
          game.debugHandComponents.firstWhere((c) => c.card.id == 'a');
      _drag(game, first, Vector2(game.size.x / 2, game.debugSentenceY));

      expect(reorders, 0);
      expect(played, 0);
    },
  );

  testWithGame<DrippleGame>(
    'the board says where its furniture is',
    DrippleGame.new,
    (game) async {
      game.updateHand(_threeCards());
      game.updatePiles(deckCount: 5, discardTop: null);
      await game.ready();

      expect(game.deckRect, isNotNull);
      expect(game.discardRect, isNotNull);
      expect(game.deckRect!.right, lessThan(game.discardRect!.left));
      expect(game.handRect, isNotNull);
      expect(game.handRect!.center.dy, closeTo(game.debugHandY, 12));
      expect(game.sentenceRect.center.dy, closeTo(game.debugSentenceY, 1));
      // An empty sentence still has a place to point at.
      expect(game.sentenceRect.width, greaterThan(0));
    },
  );
}
