import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/game_feedback.dart';
import '../core/game_icons.dart';
import 'emote_system.dart';

/// Emote bar with 5 character expression buttons.
/// These are custom character face variations drawn as vector paths, so they
/// look identical on every platform and inside the Flame canvas.
class EmoteBar extends ConsumerWidget {
  final String playerId;

  const EmoteBar({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emoteState = ref.watch(emoteProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: EmoteType.values.map((emote) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: _EmoteButton(
              emote: emote,
              isOnCooldown: emoteState.isOnCooldown,
              onPressed: () {
                ref.read(emoteProvider.notifier).sendEmote(playerId, emote);
                ref.read(gameFeedbackProvider).onEmoteSent();
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmoteButton extends StatelessWidget {
  final EmoteType emote;
  final bool isOnCooldown;
  final VoidCallback onPressed;

  const _EmoteButton({
    required this.emote,
    required this.isOnCooldown,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: emote.name,
      button: true,
      enabled: !isOnCooldown,
      child: GestureDetector(
        onTap: isOnCooldown ? null : onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isOnCooldown ? 0.4 : 1.0,
          child: Container(
            width: AppSpacing.minTouch,
            height: AppSpacing.minTouch,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: GameIconView(
                emote.icon,
                size: 24,
                color: isOnCooldown
                    ? AppColors.textDisabled
                    : AppColors.textSecondary,
              ),
            ),
          ),
      ),
    ),
  );
  }
}

/// Emote bubble that appears above a character when they emote
class EmoteBubble extends StatelessWidget {
  final EmoteType emote;

  const EmoteBubble({super.key, required this.emote});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: GameIconView(emote.icon, size: 30, color: AppColors.point),
      ),
    );
  }
}
