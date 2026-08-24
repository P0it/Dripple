import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../core/design/app_colors.dart';
import '../core/design/felt_scaffold.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';
import 'widgets/settings_tile.dart';

/// Room state and player list for online and friend battles.
///
/// Not reachable yet — both modes are marked "coming soon" on the mode
/// screen — so this is the shape the screen will take once a
/// MultiplayerService exists behind it.
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({
    super.key,
    required this.mode,
    required this.playerCount,
  });

  /// 'online' or 'friend'.
  final String mode;
  final int playerCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = mode == 'online';

    return FeltScaffold(
      appBar: AppBar(
        title: Text(isOnline ? l10n.onlineBattle : l10n.friendBattle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoomHeader(isOnline: isOnline, l10n: l10n),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SettingsSection(
                  title: l10n.playerCount,
                  tiles: [
                    for (var i = 0; i < playerCount; i++)
                      SettingsTile(
                        title: i == 0 ? l10n.you : l10n.waiting,
                        showDivider: i < playerCount - 1,
                        trailing: i == 0
                            ? const Icon(Icons.check_circle,
                                color: AppColors.point, size: 20)
                            : const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.pointTint,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.point, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        isOnline
                            ? l10n.waitingForPlayers(playerCount)
                            : l10n.shareRoomCode,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.point),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.isOnline, required this.l10n});

  final bool isOnline;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            isOnline ? l10n.searchingPlayers : l10n.roomCode,
            style: AppTypography.label,
          ),
          const SizedBox(height: AppSpacing.md),
          if (isOnline)
            const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            Text(
              'ABC-123',
              style: AppTypography.display.copyWith(
                letterSpacing: 4,
                color: AppColors.point,
              ),
            ),
        ],
      ),
    );
  }
}
