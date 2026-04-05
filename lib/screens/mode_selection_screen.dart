import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Mode'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.greenGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _ModeCard(
                  icon: Icons.smart_toy,
                  title: 'AI Battle',
                  subtitle: 'Play against AI opponents',
                  enabled: true,
                  onTap: () => _showPlayerCountDialog(context),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.public,
                  title: 'Online Battle',
                  subtitle: 'Random matchmaking',
                  enabled: false,
                  badge: 'COMING SOON',
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.group,
                  title: 'Friend Battle',
                  subtitle: 'Invite via code/link',
                  enabled: false,
                  badge: 'COMING SOON',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlayerCountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Player Count'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final count in [2, 3, 4])
              ListTile(
                leading: Icon(Icons.people, color: AppColors.primary),
                title: Text('$count Players'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/game?players=$count');
                },
              ),
          ],
        ),
      ),
    );
  }
}

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
                Icon(icon, size: 40, color: AppColors.primary),
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
                      color: AppColors.cardSkip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (enabled)
                  const Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
