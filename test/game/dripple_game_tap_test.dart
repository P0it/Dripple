import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/board_layout.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple/models/word_card.dart';

/// Taps are how a card is discarded and how a staged card is taken back, so
/// they have to survive on a component that also drags. Flame registers one
/// gesture recognizer per callback mixin in the order the mixins mount, and a
/// stationary tap is decided by an arena sweep that awards the win to whoever
/// registered first — so a drag-first component swallows every tap. Only a
/// tap driven through the real widget gesture stack can catch that; calling
/// `onTapUp` on the component sails straight past it.
List<WordCard> _twoCards() => const [
      WordCard(id: 'a', word: 'cats', pos: PartOfSpeech.noun),
      WordCard(id: 'b', word: 'run', pos: PartOfSpeech.verb),
    ];

Future<void> _pumpFrames(WidgetTester tester, [int frames = 5]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Offset _centreOf(List<Offset> slots, int index) => Offset(
      slots[index].dx + BoardLayout.cardWidth / 2,
      slots[index].dy + BoardLayout.cardHeight / 2,
    );

void main() {
  testWidgets('tapping a hand card reports its index', (tester) async {
    final game = DrippleGame();
    final tapped = <int>[];
    game.onHandCardTapped = tapped.add;

    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await _pumpFrames(tester);
    game.updateHand(_twoCards());
    await _pumpFrames(tester);

    final slots = HandFan.positions(game.size.x, 2, game.debugHandY);
    await tester.tapAt(_centreOf(slots, 1));
    await tester.pump(const Duration(seconds: 1));

    expect(tapped, [1]);
  });

  testWidgets('tapping a staged card takes it back', (tester) async {
    final game = DrippleGame();
    final removed = <int>[];
    game.onSentenceRemove = removed.add;

    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await _pumpFrames(tester);
    game.updateSentenceZone(_twoCards());
    await _pumpFrames(tester);

    final slots = SentenceLine.positions(game.size.x, 2, game.debugSentenceY);
    await tester.tapAt(_centreOf(slots, 0));
    await tester.pump(const Duration(seconds: 1));

    expect(removed, [0]);
  });

  testWidgets('dragging a hand card up still stages it', (tester) async {
    final game = DrippleGame();
    var placed = false;
    game.onCardPlaced = (_, __) => placed = true;

    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await _pumpFrames(tester);
    game.updateHand(_twoCards());
    await _pumpFrames(tester);

    final slots = HandFan.positions(game.size.x, 2, game.debugHandY);
    final from = _centreOf(slots, 0);
    final gesture = await tester.startGesture(from);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(placed, isTrue);
  });
}
