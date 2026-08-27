import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/brand/dripple_mark.dart';
import '../core/design/app_colors.dart';
import '../core/design/felt_scaffold.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';
import '../core/game_icons.dart';
import 'package:dripple_rules/models/player.dart';
import '../providers/game_provider.dart';

/// Final standings.
///
/// The old screen showed "pts" for every player, but Player.score is never
/// written anywhere in the game — it always read 0. Ranking is by cards left,
/// so that is the number shown.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ranking = ref.watch(gameProvider).ranking;

    return FeltScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            const Center(
                child: DrippleMark(size: 56, color: AppColors.pointOnFelt)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.gameOver,
              textAlign: TextAlign.center,
              style: AppTypography.onFelt(AppTypography.display),
            ),
            if (ranking.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                ranking.first.name,
                textAlign: TextAlign.center,
                style: AppTypography.body
                    .copyWith(color: AppColors.onFeltSoft),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                itemCount: ranking.length,
                itemBuilder: (context, index) => _StandingRow(
                  player: ranking[index],
                  rank: index + 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/mode-select'),
                    child: Text(l10n.playAgain),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(l10n.home),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.player, required this.rank});

  final Player player;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final won = rank == 1;

    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTypography.label.copyWith(
                color: won ? AppColors.point : AppColors.textDisabled,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    player.name,
                    style: won
                        ? AppTypography.body
                            .copyWith(fontWeight: FontWeight.w700)
                        : AppTypography.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (won) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const GameIconView(GameIcon.crown,
                      size: 18, color: AppColors.point),
                ],
              ],
            ),
          ),
          Text(
            l10n.cardsLeftLabel(player.hand.length),
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
