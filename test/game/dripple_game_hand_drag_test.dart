import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/board_layout.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple_rules/models/word_card.dart';

/// A card in the fan is picked up by pressing it, and it goes wherever the
/// finger goes.
///
/// This replaced a modal gesture: a press used to put the hand into a "read"
/// mode where the finger slid along the fan raising whichever card it passed
/// over, and only an upward pull of 16px turned the gesture into a pick-up.
/// Sideways movement was therefore never a drag — it handed the grab to the
/// neighbour — so sliding a card along the rail to reorder was impossible
/// without first pulling it out of the fan, and nothing on screen said so.
///
/// Arranging the hand *is* the game: a player tries an order in the fan before
/// pushing the sentence forward. That gesture has to be the direct one.
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
  testWidgets('sliding sideways carries the card that was pressed',
      (tester) async {
    final game = await _board(tester, 7);
    int? from;
    int? to;
    game.onHandReorder = (f, t) {
      from = f;
      to = t;
    };

    final slots = HandFan.positions(game.size.x, 7, game.debugHandY);
    final pressed = game.debugHandComponents.first;
    final gesture = await tester.startGesture(
      Offset(slots[0].dx + 8, game.debugHandY),
    );

    // Straight along the rail, past three cards. No upward pull anywhere.
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(Offset((slots[3].dx - slots[0].dx) / 6, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(pressed.isDragging, isTrue,
        reason: 'the card under the finger is the one being dragged');
    expect(pressed.position.x, greaterThan(slots[0].dx + 20),
        reason: 'it travelled with the finger');

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(from, 0, reason: 'the card that was pressed is the card that moved');
    expect(to, isNotNull);
    expect(to, greaterThan(0), reason: 'it landed further along the rail');
  });

  testWidgets('sideways alone picks the card up, with no upward ritual',
      (tester) async {
    final game = await _board(tester, 7);

    final slots = HandFan.positions(game.size.x, 7, game.debugHandY);
    final pressed = game.debugHandComponents[2];
    final gesture = await tester.startGesture(
      Offset(slots[2].dx + 8, game.debugHandY),
    );

    // Straight sideways, and only just far enough to be a drag at all.
    // Flame's drag sits on Flutter's MultiDragGestureRecognizer, which does
    // not accept the gesture — so onDragStart cannot fire — until the pointer
    // has travelled further than kTouchSlop. That floor is the framework's and
    // applies in every direction alike, which is exactly why it does not
    // reintroduce the modal gesture this test guards against: what was removed
    // was an *upward* pull of 16px on top of it, a direction the player was
    // never told about.
    await gesture.moveBy(const Offset(kTouchSlop + 1, 0));
    await tester.pump(const Duration(milliseconds: 16));

    expect(pressed.isDragging, isTrue);
    expect(game.debugHandComponents.where((c) => c.isDragging), hasLength(1),
        reason: 'exactly one card is in hand');

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('pushing a card forward plays it', (tester) async {
    final game = await _board(tester, 7);
    int? playedIndex;
    game.onCardPlaced = (handIndex, _) => playedIndex = handIndex;

    final slots = HandFan.positions(game.size.x, 7, game.debugHandY);
    final gesture = await tester.startGesture(
      Offset(slots[4].dx + 8, game.debugHandY),
    );
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(playedIndex, 4,
        reason: 'the card pressed is the card played, wherever it started');
  });
}
