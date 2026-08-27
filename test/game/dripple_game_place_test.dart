import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/board_layout.dart';
import 'package:dripple/game/components/card_component.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple_rules/models/word_card.dart';

/// Drives a card through a real drag: press, move to [to], release.
void _drag(DrippleGame game, CardComponent card, Vector2 to) {
  card.onDragStart(
    DragStartEvent(1, game, DragStartDetails(globalPosition: Offset.zero)),
  );
  card.position = to;
  card.onDragEnd(DragEndEvent(1, DragEndDetails()));
}

void main() {
  testWithGame<DrippleGame>(
    'a hand card dropped on the front of the sentence goes to the front',
    DrippleGame.new,
    (game) async {
      final placements = <List<int>>[];
      game.onCardPlaced = (handIndex, insertAt) =>
          placements.add([handIndex, insertAt]);

      game.updateSentenceZone(const [
        WordCard(id: 's0', word: 'cats', pos: PartOfSpeech.noun),
        WordCard(id: 's1', word: 'run', pos: PartOfSpeech.verb),
      ]);
      game.updateHand(const [
        WordCard(id: 'h0', word: 'the', pos: PartOfSpeech.article),
      ]);
      await game.ready();

      // Where the card would sit if it became the first of three.
      final after =
          SentenceLine.positions(game.size.x, 3, game.debugSentenceY);
      final handCard =
          game.debugHandComponents.firstWhere((c) => c.card.id == 'h0');

      _drag(game, handCard, Vector2(after[0].dx, after[0].dy));

      expect(placements, [
        [0, 0]
      ]);
    },
  );

  testWithGame<DrippleGame>(
    'a hand card dropped on the tail of the sentence goes to the tail',
    DrippleGame.new,
    (game) async {
      final placements = <List<int>>[];
      game.onCardPlaced = (handIndex, insertAt) =>
          placements.add([handIndex, insertAt]);

      game.updateSentenceZone(const [
        WordCard(id: 's0', word: 'cats', pos: PartOfSpeech.noun),
        WordCard(id: 's1', word: 'run', pos: PartOfSpeech.verb),
      ]);
      game.updateHand(const [
        WordCard(id: 'h0', word: 'fast', pos: PartOfSpeech.adverb),
      ]);
      await game.ready();

      final after =
          SentenceLine.positions(game.size.x, 3, game.debugSentenceY);
      final handCard =
          game.debugHandComponents.firstWhere((c) => c.card.id == 'h0');

      _drag(game, handCard, Vector2(after[2].dx, after[2].dy));

      expect(placements, [
        [0, 2]
      ]);
    },
  );

  testWithGame<DrippleGame>(
    'dropping onto an empty sentence zone inserts at 0',
    DrippleGame.new,
    (game) async {
      int? insertAt;
      game.onCardPlaced = (_, at) => insertAt = at;

      game.updateHand(const [
        WordCard(id: 'h0', word: 'cats', pos: PartOfSpeech.noun),
      ]);
      await game.ready();

      final handCard = game.debugHandComponents.single;
      _drag(game, handCard, Vector2(game.size.x / 2, game.debugSentenceY));

      expect(insertAt, 0);
    },
  );
}
