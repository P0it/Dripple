import 'dart:math';

import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/providers/online_providers.dart';
import 'package:dripple/screens/lobby_screen.dart';
import 'package:dripple/services/online_client.dart';
import 'package:dripple/services/player_identity.dart';
import 'package:dripple_server/dripple_server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../support/in_process_client.dart';

/// The lobby against the real server: the code it shows is the code the
/// server issued, and the chairs are the chairs it says are taken.
void main() {
  late shelf.Handler handler;
  final baseUrl = Uri.parse('http://dripple.test');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    handler = Api(
      service: GameService(store: InMemoryRoomStore(), random: Random(9)),
      verifier: const TrustingTokenVerifier(),
    ).handler;
  });

  OnlineClient clientFor(String uid) => OnlineClient(
        baseUrl: baseUrl,
        token: () async => uid,
        httpClient: InProcessClient(handler),
      );

  /// The lobby reads preferences and asks the server before it can draw
  /// anything, so it needs a few frames rather than one. pumpAndSettle is no
  /// use here — the poll timer never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<Widget> host(String roomId, String uid) async {
    final identity = await PlayerIdentity.load();
    return ProviderScope(
      overrides: [
        playerIdentityProvider.overrideWithValue(identity),
        serverUrlProvider.overrideWithValue(baseUrl),
        onlineClientProvider.overrideWith((ref) => clientFor(uid)),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: LobbyScreen(roomId: roomId),
      ),
    );
  }

  testWidgets('shows the room code and who is sitting down', (tester) async {
    final made = await clientFor('mina').createRoom(name: 'Mina');
    await clientFor('jun').joinRoom(code: made.code, name: 'Jun');

    await tester.pumpWidget(await host(made.roomId, 'mina'));
    await settle(tester);

    expect(find.text(made.code), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Jun'), findsOneWidget);

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    // Four seats, two taken.
    expect(find.text(l10n.emptySeat), findsNWidgets(2));
    expect(find.text(l10n.hostLabel), findsOneWidget);
  });

  testWidgets('offers the deal to the host', (tester) async {
    final made = await clientFor('mina').createRoom(name: 'Mina');
    await clientFor('jun').joinRoom(code: made.code, name: 'Jun');
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(await host(made.roomId, 'mina'));
    await settle(tester);

    expect(find.text(l10n.startGame), findsOneWidget);
    expect(find.text(l10n.waitingForHost), findsNothing);
  });

  testWidgets('and an explanation to everybody else', (tester) async {
    final made = await clientFor('mina').createRoom(name: 'Mina');
    await clientFor('jun').joinRoom(code: made.code, name: 'Jun');
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(await host(made.roomId, 'jun'));
    await settle(tester);

    expect(find.text(l10n.waitingForHost), findsOneWidget);
    expect(find.text(l10n.startGame), findsNothing);
  });

  testWidgets('will not deal a room with nobody else in it', (tester) async {
    final made = await clientFor('mina').createRoom(name: 'Mina');
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(await host(made.roomId, 'mina'));
    await settle(tester);

    expect(find.text(l10n.needTwoPlayers), findsOneWidget);
    final button = tester.widget<FilledButton>(find.ancestor(
      of: find.text(l10n.startGame),
      matching: find.byType(FilledButton),
    ));
    expect(button.onPressed, isNull, reason: 'the deal button is not live yet');
  });
}
