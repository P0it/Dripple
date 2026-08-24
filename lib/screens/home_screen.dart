import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/brand/dripple_mark.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';
import '../core/game_feedback.dart';

/// The front door.
///
/// One thing to do, one way to change it. The character moved to the board,
/// where it belongs; the Character and Ranking buttons that used to sit here
/// were wired to null, and a button a child can press that does nothing is
/// worse than no button at all.
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
      if (!mounted) return;
      ref.read(gameFeedbackProvider).playMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              const Center(child: DrippleMark(size: 96)),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Dripple',
                textAlign: TextAlign.center,
                style: AppTypography.display.copyWith(letterSpacing: -0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.wordCardBattle,
                textAlign: TextAlign.center,
                style: AppTypography.body
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(flex: 4),
              ElevatedButton(
                onPressed: () => _go(context, '/mode-select'),
                child: Text(l10n.play),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => _go(context, '/settings'),
                child: Text(l10n.settings),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    ref.read(gameFeedbackProvider).onButtonTap();
    context.push(route);
  }
}
