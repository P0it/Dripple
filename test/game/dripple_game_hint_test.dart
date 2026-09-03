import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/game/dripple_game.dart';
import 'package:dripple_rules/models/word_card.dart';

/// The felt asks for a sentence only when it will accept one.
///
/// The invitation used to be drawn whenever the space was empty and the hand
/// was not, so "push cards up to build a sentence" sat on the table while an
/// opponent was thinking and through the player's own draw step — both states
/// in which the gesture is refused. A player could not tell from that whether
/// the space was somewhere to try an order out ahead of their turn or
/// somewhere to submit an answer, because in the state they were looking at it
/// was neither.
List<WordCard> _hand(int n) => [
      for (var i = 0; i < n; i++)
        WordCard(id: 'c$i', word: 'word$i', pos: PartOfSpeech.noun),
    ];

Future<DrippleGame> _board(WidgetTester tester) async {
  final game = DrippleGame();
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  game.updateHand(_hand(5));
  await tester.pump(const Duration(milliseconds: 16));
  return game;
}

void main() {
  testWidgets('silent until the player may actually push a card forward',
      (tester) async {
    final game = await _board(tester);

    expect(game.showsHint, isFalse,
        reason: "nobody's turn has been granted yet");

    game.canBuild = true;
    expect(game.showsHint, isTrue);

    game.canBuild = false;
    expect(game.showsHint, isFalse,
        reason: 'an opponent is thinking, or the draw is still owed');
  });

  testWidgets('gone the moment the first card is out there', (tester) async {
    final game = await _board(tester);
    game.canBuild = true;
    expect(game.showsHint, isTrue);

    game.updateSentenceZone(_hand(1));
    await tester.pump(const Duration(milliseconds: 16));

    expect(game.showsHint, isFalse,
        reason: 'the cards on the felt say it better than the line does');
  });

  testWidgets('nothing to invite with an empty hand', (tester) async {
    final game = DrippleGame();
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await tester.pump(const Duration(milliseconds: 16));
    game.canBuild = true;

    expect(game.showsHint, isFalse);
  });
}
