import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/game_screen.dart';
import 'screens/result_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/mode-select',
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) {
        final playerCount =
            int.tryParse(state.uri.queryParameters['players'] ?? '2') ?? 2;
        return GameScreen(playerCount: playerCount);
      },
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
  ],
);

class DrippleApp extends StatelessWidget {
  const DrippleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dripple',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
