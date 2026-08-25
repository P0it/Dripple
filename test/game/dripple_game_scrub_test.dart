import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/board_layout.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple/models/word_card.dart';

/// A fanned hand overlaps, so most of a card is behind the next one. Running a
/// thumb along the hand is how it is read: the card under the finger comes up
/// out of the fan, and pulling up from there plays the card you settled on —
/// not whichever one the press happened to land on first.
List<WordCard> _hand(int n) => [
      for (var i = 0; i < n; i++)
        WordCard(id: 'c$i', word: 'word$i', pos: PartOfSpeech.noun),
    ];

Future<void> _pump(WidgetTester tester, [int frames = 5]) async {
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
  testWidgets('running a thumb along the fan reads the card under it',
      (tester) async {
    final game = await _board(tester, 9);
    var placed = false;
    game.onCardPlaced = (_, __) => placed = true;

    final slots = HandFan.positions(game.size.x, 9, game.debugHandY);
    final gesture = await tester.startGesture(
      Offset(slots[0].dx + 20, game.debugHandY),
    );
    // Sideways only, well past several cards.
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }

    final peeking =
        game.debugHandComponents.where((c) => c.isPeeking).toList();
    expect(peeking, hasLength(1), reason: 'exactly one card is being read');
    expect(peeking.single.card.id, isNot('c0'),
        reason: 'the thumb moved on from the card it pressed');

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(placed, isFalse, reason: 'reading is not playing');
    expect(game.debugHandComponents.where((c) => c.isPeeking), isEmpty);
  });

  testWidgets('pulling up plays the card the thumb settled on', (tester) async {
    final game = await _board(tester, 9);
    int? placedIndex;
    game.onCardPlaced = (handIndex, _) => placedIndex = handIndex;

    final slots = HandFan.positions(game.size.x, 9, game.debugHandY);
    final gesture = await tester.startGesture(
      Offset(slots[0].dx + 20, game.debugHandY),
    );

    // Slide onto the fifth card, then pull straight up.
    final target = game.debugHandComponents[4];
    await gesture.moveTo(Offset(slots[4].dx + 4, game.debugHandY));
    await tester.pump(const Duration(milliseconds: 16));
    expect(target.isPeeking, isTrue);

    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(placedIndex, 4,
        reason: 'the card that was lifted is the one the thumb was on');
  });

  test('a thumb touches the topmost card covering it, not the nearest slot',
      () {
    // The fan overlaps left-to-right, so the card showing at a point is the
    // last one whose left edge is left of it. Nearest-slot hands back the card
    // behind, which is exactly the one the player cannot see.
    const width = 390.0;
    final slots = HandFan.positions(width, 7, 400);
    for (var i = 0; i < 7; i++) {
      expect(HandFan.indexUnder(slots[i].dx + 2, width, 7, 400), i);
    }
    expect(HandFan.indexUnder(-999, width, 7, 400), 0);
    expect(HandFan.indexUnder(9999, width, 7, 400), 6);
    expect(HandFan.indexUnder(0, width, 0, 400), -1);
  });
}
