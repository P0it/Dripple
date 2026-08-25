import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/screens/game/action_bar.dart';

GameState _playing({required TurnPhase turnPhase}) => GameState(
      phase: GamePhase.playing,
      turnPhase: turnPhase,
      currentPlayerIndex: 0,
      players: [
        Player(
          id: 'me',
          name: 'me',
          isAI: false,
          hand: const [WordCard(id: 'a', word: 'cats', pos: PartOfSpeech.noun)],
        ),
        Player(id: 'ai', name: 'ai', isAI: true),
      ],
    );

Widget _host(GameState state) => MaterialApp(
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
          child: ActionBar(gameState: state, onSubmit: () {}),
        ),
      ),
    );

void main() {
  testWidgets('the action step says how to end a turn without a sentence',
      (tester) async {
    await tester.pumpWidget(_host(_playing(turnPhase: TurnPhase.action)));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l10n.completeSentence), findsOneWidget);
    expect(find.text(l10n.dragToDiscard), findsOneWidget);
  });

  testWidgets('the draw step still only asks for a draw', (tester) async {
    await tester.pumpWidget(_host(_playing(turnPhase: TurnPhase.draw)));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l10n.tapDeckToDraw), findsOneWidget);
    expect(find.text(l10n.dragToDiscard), findsNothing);
  });
}
