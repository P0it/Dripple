import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/board_layout.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple_rules/models/word_card.dart';

/// The row under a held card opens a place for it while it is still in the air.
///
/// It used to rearrange only once the finger let go, which left a player
/// carrying a card with nothing to aim at: the row stood still and where the
/// card would land was a guess that resolved after the fact. Cards on a table
/// do not behave that way — you push the ones either side apart with the card
/// in your hand, and the space that opens *is* the aim.
List<WordCard> _hand(int n) => [
      for (var i = 0; i < n; i++)
        WordCard(id: 'c$i', word: 'word$i', pos: PartOfSpeech.noun),
    ];

Future<void> _pump(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<DrippleGame> _board(WidgetTester tester, int cards) async {
  final game = DrippleGame();
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
  await _pump(tester);
  game.updateHand(_hand(cards));
  await _pump(tester);
  return game;
}

void main() {
  testWidgets('the fan opens where a carried card would land', (tester) async {
    final game = await _board(tester, 5);
    final slots = HandFan.positions(game.size.x, 5, game.debugHandY);
    final carried = game.debugHandComponents.first;
    final neighbour = game.debugHandComponents[1];
    final neighbourStart = neighbour.position.x;

    final gesture = await tester.startGesture(
      Offset(slots[0].dx + 8, game.debugHandY),
    );
    // Carry it along the rail, three places to the right, and hold it there.
    await gesture.moveTo(Offset(slots[3].dx + 8, game.debugHandY));
    await _pump(tester, 20);

    expect(carried.isDragging, isTrue);
    expect(neighbour.position.x, lessThan(neighbourStart - 4),
        reason: 'the card behind it has moved up to fill the place it left');

    await gesture.up();
    await _pump(tester, 20);
  });

  testWidgets('the sentence opens as a card is pushed forward',
      (tester) async {
    final game = await _board(tester, 5);
    game.updateSentenceZone(_hand(2).map((c) {
      return WordCard(id: 's${c.id}', word: c.word, pos: c.pos);
    }).toList());
    await _pump(tester);

    final placed = game.debugSentenceComponents.toList();
    expect(placed, hasLength(2));
    final startXs = placed.map((c) => c.position.x).toList();

    final slots = HandFan.positions(game.size.x, 5, game.debugHandY);
    final gesture = await tester.startGesture(
      Offset(slots[0].dx + 8, game.debugHandY),
    );
    // Up past the midline, and over the left end of the line.
    await gesture.moveTo(
      Offset(placed.first.position.x, game.debugSentenceY),
    );
    await _pump(tester, 20);

    expect(placed.map((c) => c.position.x).toList(), isNot(startXs),
        reason: 'the cards in play have stood aside for the arriving one');

    await gesture.up();
    await _pump(tester, 20);
  });

  testWidgets('a refused drop puts the row back', (tester) async {
    final game = await _board(tester, 5);
    game.onHandReorder = (_, __) {}; // accepted but nothing re-lays the row
    final slots = HandFan.positions(game.size.x, 5, game.debugHandY);
    final neighbour = game.debugHandComponents[1];
    final home = neighbour.position.clone();

    final gesture = await tester.startGesture(
      Offset(slots[0].dx + 8, game.debugHandY),
    );
    await gesture.moveTo(Offset(slots[3].dx + 8, game.debugHandY));
    await _pump(tester, 20);
    expect(neighbour.position.x, isNot(closeTo(home.x, 1)));

    await gesture.up();
    await _pump(tester, 40);

    expect(neighbour.position.x, closeTo(home.x, 1.5),
        reason: 'the room that was made for the card has been given back');
  });
}
