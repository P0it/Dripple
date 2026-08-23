import 'package:flutter/material.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/word_card.dart';
import '../engine/ai/ai_player.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectMode),
        backgroundColor: AppColors.point,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _ModeCard(
                  icon: Icons.smart_toy,
                  title: l10n.aiBattle,
                  subtitle: l10n.aiBattleDesc,
                  enabled: true,
                  onTap: () => _showDifficultyDialog(context, l10n),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.public,
                  title: l10n.onlineBattle,
                  subtitle: l10n.onlineBattleDesc,
                  enabled: false,
                  badge: l10n.comingSoon,
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.group,
                  title: l10n.friendBattle,
                  subtitle: l10n.friendBattleDesc,
                  enabled: false,
                  badge: l10n.comingSoon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Step 1: pick a difficulty level.
  void _showDifficultyDialog(BuildContext context, AppLocalizations l10n) {
    showDialog<AIDifficulty>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DifficultyTile(
              difficulty: AIDifficulty.easy,
              label: 'Easy',
              description: 'Relaxed – great for beginners',
              icon: Icons.sentiment_satisfied_alt,
              color: Colors.green,
              onTap: () => Navigator.of(ctx).pop(AIDifficulty.easy),
            ),
            _DifficultyTile(
              difficulty: AIDifficulty.medium,
              label: 'Medium',
              description: 'Balanced – the default challenge',
              icon: Icons.sentiment_neutral,
              color: Colors.orange,
              onTap: () => Navigator.of(ctx).pop(AIDifficulty.medium),
            ),
            _DifficultyTile(
              difficulty: AIDifficulty.hard,
              label: 'Hard',
              description: 'Ruthless – for experienced players',
              icon: Icons.sentiment_very_dissatisfied,
              color: Colors.red,
              onTap: () => Navigator.of(ctx).pop(AIDifficulty.hard),
            ),
          ],
        ),
      ),
    ).then((difficulty) {
      if (difficulty != null && context.mounted) {
        // Player count is fixed at four: JUMP and STEAL only matter with
        // opponents to point them at, and asking a child two questions
        // before the game starts is one too many.
        context.push('/game?players=4&difficulty=${difficulty.name}');
      }
    });
  }

}

// ---------------------------------------------------------------------------
// Difficulty tile used inside the difficulty dialog
// ---------------------------------------------------------------------------

class _DifficultyTile extends StatelessWidget {
  final AIDifficulty difficulty;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.difficulty,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Mode card widget (unchanged from original)
// ---------------------------------------------------------------------------

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final String? badge;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 40, color: AppColors.point),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.specialCard(CardType.jump),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (enabled)
                  const Icon(Icons.chevron_right, color: AppColors.point),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
