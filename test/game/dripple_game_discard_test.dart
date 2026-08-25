import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/board_layout.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple/models/word_card.dart';

List<WordCard> _hand() => const [
      WordCard(id: 'a', word: 'cats', pos: PartOfSpeech.noun),
      WordCard(id: 'b', word: 'run', pos: PartOfSpeech.verb),
    ];

void main() {
  testWidgets('dragging a hand card onto the discard pile throws it away',
      (tester) async {
    final game = DrippleGame();
    final discarded = <int>[];
    final placed = <int>[];
    game.onDiscardCard = discarded.add;
    game.onCardPlaced = (i, _) => placed.add(i);

    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    game.updatePiles(
      deckCount: 20,
      discardTop: const WordCard(id: 'z', word: 'sun', pos: PartOfSpeech.noun),
    );
    game.updateHand(_hand());
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final slots = HandFan.positions(game.size.x, 2, game.debugHandY);
    final from = Offset(
      slots[0].dx + BoardLayout.cardWidth / 2,
      slots[0].dy + BoardLayout.cardHeight / 2,
    );
    final pile = game.debugDiscardCentre!;
    final to = Offset(pile.x, pile.y);

    // ignore: avoid_print
    print('DRAG from=$from to=$to boardSize=${game.size}');

    final gesture = await tester.startGesture(from);
    const steps = 20;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset((to.dx - from.dx) / steps,
          (to.dy - from.dy) / steps));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    // ignore: avoid_print
    print('RESULT discarded=$discarded placed=$placed');
    expect(discarded, [0]);
    expect(placed, isEmpty);
  });
}
