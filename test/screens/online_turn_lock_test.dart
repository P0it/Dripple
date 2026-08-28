import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/screens/game/action_bar.dart';
import 'package:dripple/screens/game/opponents_bar.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/player.dart';
import 'package:dripple_rules/models/word_card.dart';

/// Online, three of the four seats are people and only one is yours. The
/// screens used to answer "may I act?" by asking whether the seat in play was
/// a bot, which is the right answer only when every other seat is one.
GameState _table({
  required int mySeat,
  required int currentSeat,
}) =>
    GameState(
      phase: GamePhase.playing,
      turnPhase: TurnPhase.draw,
      currentPlayerIndex: currentSeat,
      mySeatIndex: mySeat,
      players: const [
        Player(
          id: 'mina',
          name: 'Mina',
          hand: [WordCard(id: 'a', word: 'cats', pos: PartOfSpeech.noun)],
        ),
        Player(
          id: 'jun',
          name: 'Jun',
          hand: [WordCard(id: 'b', word: 'run', pos: PartOfSpeech.verb)],
        ),
        Player(
          id: 'sora',
          name: 'Sora',
          hand: [WordCard(id: 'c', word: 'the', pos: PartOfSpeech.article)],
        ),
      ],
    );

/// The opponents bar carries a mute button that reads a provider, and it lays
/// its seats out across whatever width it is given — hence the scope and the
/// bounded box rather than a bare widget.
Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(width: 400, child: child),
        ),
      ),
    );

void main() {
  testWidgets('the action bar waits while another person is playing',
      (tester) async {
    await tester.pumpWidget(_host(
      ActionBar(
        gameState: _table(mySeat: 1, currentSeat: 0),
        onSubmit: () {},
        onPass: () {},
      ),
    ));
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l10n.opponentThinking), findsOneWidget);
  });

  testWidgets('and offers the turn when it comes round', (tester) async {
    await tester.pumpWidget(_host(
      ActionBar(
        gameState: _table(mySeat: 1, currentSeat: 1),
        onSubmit: () {},
        onPass: () {},
      ),
    ));
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l10n.opponentThinking), findsNothing);
  });

  testWidgets('the opponents bar shows the other people, not the other bots',
      (tester) async {
    await tester.pumpWidget(_host(
      OpponentsBar(gameState: _table(mySeat: 1, currentSeat: 0)),
    ));
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Sora'), findsOneWidget);
    expect(find.text('Jun'), findsNothing, reason: 'Jun is me');
  });
}
