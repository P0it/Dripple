import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple_rules/models/word_card.dart';
import 'package:dripple/providers/game_provider.dart';
import 'package:dripple/screens/judgment_screen.dart';

JudgmentResult _correct() => const JudgmentResult(
      isCorrect: true,
      playerName: 'You',
      sentence: [
        WordCard(id: 'a', word: 'cats', pos: PartOfSpeech.noun),
        WordCard(id: 'b', word: 'run', pos: PartOfSpeech.verb),
      ],
    );

Widget _host(void Function(BuildContext) capture) => MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        capture(context);
        return const Scaffold(body: SizedBox.shrink());
      }),
    );

void main() {
  testWidgets('the verdict arrives as a sheet, not a dialog', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(_host((c) => context = c));

    final closed = showJudgmentSheet(context, _correct());
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    // The submitted sentence is the thing a child needs to see.
    expect(find.text('cats run'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await closed;

    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a failed sentence shows what was wrong', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(_host((c) => context = c));

    showJudgmentSheet(
      context,
      const JudgmentResult(
        isCorrect: false,
        playerName: 'You',
        sentence: [WordCard(id: 'a', word: 'cat', pos: PartOfSpeech.noun)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);
  });
}
