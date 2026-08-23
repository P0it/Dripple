import 'package:flutter/material.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../character/character_widget.dart';
import '../core/game_feedback.dart';
import '../core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameFeedbackProvider).playMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedback = ref.read(gameFeedbackProvider);

    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Character (placeholder — will use Rive when assets are ready)
                const CharacterWidget(
                  characterId: 'default',
                  size: 160,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.appTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.wordCardBattle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withAlpha(220),
                      ),
                ),
                const Spacer(),
                SizedBox(
                  width: 220,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      feedback.onButtonTap();
                      context.push('/mode-select');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.point,
                    ),
                    child: Text(
                      l10n.play,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _navButton(Icons.person, l10n.character, null),
                    const SizedBox(width: 24),
                    _navButton(Icons.leaderboard, l10n.ranking, null),
                    const SizedBox(width: 24),
                    _navButton(Icons.settings, l10n.settings, () {
                      feedback.onButtonTap();
                      context.push('/settings');
                    }),
                  ],
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, String label, VoidCallback? onPressed) {
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      child: Column(
        children: [
          Opacity(
            opacity: onPressed != null ? 1.0 : 0.5,
            child: IconButton(
              onPressed: onPressed,
              tooltip: label,
              icon: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
