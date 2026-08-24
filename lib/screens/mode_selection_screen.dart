import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';
import '../engine/ai/ai_player.dart';

/// Pick an opponent, then pick how hard it plays.
///
/// Selection is marked with a border and a tint rather than a filled block:
/// a solid colour reads as "pressed" and leaves nowhere for the text to sit.
class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.selectMode)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
          children: [
            _ModeCell(
              icon: Icons.smart_toy_outlined,
              title: l10n.aiBattle,
              subtitle: l10n.aiBattleDesc,
              onTap: () => _pickDifficulty(context, l10n),
            ),
            _ModeCell(
              icon: Icons.public,
              title: l10n.onlineBattle,
              subtitle: l10n.onlineBattleDesc,
              badge: l10n.comingSoon,
            ),
            _ModeCell(
              icon: Icons.group_outlined,
              title: l10n.friendBattle,
              subtitle: l10n.friendBattleDesc,
              badge: l10n.comingSoon,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDifficulty(
      BuildContext context, AppLocalizations l10n) async {
    final choice = await showModalBottomSheet<AIDifficulty>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Text(l10n.aiDifficulty, style: AppTypography.heading),
            ),
            _DifficultyCell(
              label: l10n.difficultyEasy,
              description: l10n.difficultyEasyDesc,
              onTap: () => Navigator.of(sheet).pop(AIDifficulty.easy),
            ),
            _DifficultyCell(
              label: l10n.difficultyMedium,
              description: l10n.difficultyMediumDesc,
              onTap: () => Navigator.of(sheet).pop(AIDifficulty.medium),
            ),
            _DifficultyCell(
              label: l10n.difficultyHard,
              description: l10n.difficultyHardDesc,
              onTap: () => Navigator.of(sheet).pop(AIDifficulty.hard),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;
    // Player count is fixed at four: JUMP and STEAL only matter with
    // opponents to point them at, and asking a child two questions before
    // the game starts is one too many.
    context.push('/game?players=4&difficulty=${choice.name}');
  }
}

/// One opponent option.
class _ModeCell extends StatelessWidget {
  const _ModeCell({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground =
        enabled ? AppColors.textPrimary : AppColors.textDisabled;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouch + 20),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 28,
                    color: enabled ? AppColors.point : AppColors.textDisabled),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: AppTypography.label
                              .copyWith(fontSize: 17, color: foreground)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                if (badge case final text?)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(text, style: AppTypography.caption),
                  )
                else if (enabled)
                  const Icon(Icons.chevron_right,
                      color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One difficulty row inside the sheet.
class _DifficultyCell extends StatelessWidget {
  const _DifficultyCell({
    required this.label,
    required this.description,
    required this.onTap,
  });

  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch + 8),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTypography.body),
                  const SizedBox(height: 2),
                  Text(description, style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
