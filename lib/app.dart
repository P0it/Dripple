import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/design/app_theme.dart';
import 'engine/ai/ai_player.dart';
import 'screens/home_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/game_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';

CustomTransitionPage _fadeTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _fadeTransition(const HomeScreen(), state),
    ),
    GoRoute(
      path: '/mode-select',
      pageBuilder: (context, state) =>
          _fadeTransition(const ModeSelectionScreen(), state),
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) {
        final playerCount =
            int.tryParse(state.uri.queryParameters['players'] ?? '2') ?? 2;
        final difficultyName =
            state.uri.queryParameters['difficulty'] ?? 'medium';
        final difficulty = AIDifficulty.values.firstWhere(
          (d) => d.name == difficultyName,
          orElse: () => AIDifficulty.medium,
        );
        return _fadeTransition(
          GameScreen(playerCount: playerCount, difficulty: difficulty),
          state,
        );
      },
    ),
    GoRoute(
      path: '/lobby',
      pageBuilder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'online';
        final playerCount =
            int.tryParse(state.uri.queryParameters['players'] ?? '2') ?? 2;
        return _fadeTransition(
          LobbyScreen(mode: mode, playerCount: playerCount),
          state,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _fadeTransition(const SettingsScreen(), state),
    ),
    GoRoute(
      path: '/result',
      pageBuilder: (context, state) =>
          _fadeTransition(const ResultScreen(), state),
    ),
  ],
);

class DrippleApp extends StatelessWidget {
  const DrippleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dripple',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
