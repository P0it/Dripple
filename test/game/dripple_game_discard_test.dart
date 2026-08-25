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


    final gesture = await tester.startGesture(from);
    const steps = 20;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset((to.dx - from.dx) / steps,
          (to.dy - from.dy) / steps));
      await tester.pump(const Duration(milliseconds: 16));
      if (i == 2) {
        // Barely moved yet, nowhere near the pile: the pile still has to say
        // it will take the card, or nothing on the board ever admits that
        // throwing one away is a move.
        expect(game.debugDiscardPile!.isInviting, isTrue,
            reason: 'the pile should invite as soon as a card is lifted');
        expect(game.debugDiscardPile!.isDropTarget, isFalse);
      }
    }
    expect(game.debugDiscardPile!.isDropTarget, isTrue,
        reason: 'the pile should light up once the card is over it');
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(discarded, [0]);
    expect(placed, isEmpty);
  });
}
