import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/player.dart';
import 'package:dripple_rules/models/word_card.dart';
import 'package:dripple/screens/game/action_bar.dart';

GameState _playing({
  required TurnPhase turnPhase,
  List<WordCard> staged = const [],
}) =>
    GameState(
      phase: GamePhase.playing,
      turnPhase: turnPhase,
      currentPlayerIndex: 0,
      players: [
        Player(
          id: 'me',
          name: 'me',
          isAI: false,
          hand: const [WordCard(id: 'a', word: 'cats', pos: PartOfSpeech.noun)],
          sentenceZone: staged,
        ),
        Player(id: 'ai', name: 'ai', isAI: true),
      ],
    );

Widget _host(GameState state, {VoidCallback? onPass}) => MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ActionBar(
            gameState: state,
            onSubmit: () {},
            onPass: onPass ?? () {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('the action step says how to end a turn without a sentence',
      (tester) async {
    await tester.pumpWidget(_host(_playing(
      turnPhase: TurnPhase.action,
      staged: const [
        WordCard(id: 'b', word: 'cats', pos: PartOfSpeech.noun),
        WordCard(id: 'c', word: 'run', pos: PartOfSpeech.verb),
      ],
    )));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l10n.completeSentence), findsOneWidget);
    expect(find.text(l10n.dragToDiscard), findsOneWidget);
  });

  testWidgets('a turn can be ended without spending a card', (tester) async {
    var passed = false;
    await tester.pumpWidget(_host(
      _playing(turnPhase: TurnPhase.action),
      onPass: () => passed = true,
    ));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    // Enabled even with nothing staged: a hand that cannot make a sentence is
    // exactly the hand that needs to hand the turn over.
    await tester.tap(find.text(l10n.passTurn));
    await tester.pump();
    expect(passed, isTrue);
  });

  testWidgets('the draw step still only asks for a draw', (tester) async {
    await tester.pumpWidget(_host(_playing(turnPhase: TurnPhase.draw)));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l10n.tapDeckToDraw), findsOneWidget);
    expect(find.text(l10n.dragToDiscard), findsNothing);
    // Passing before the draw would end a turn in which nothing happened.
    expect(find.text(l10n.passTurn), findsNothing);
  });
}
