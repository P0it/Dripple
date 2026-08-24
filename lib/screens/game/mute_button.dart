import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/game_feedback.dart';
import '../../core/game_icons.dart';

/// Sound toggle, kept on the board rather than buried in settings — a child
/// playing next to someone else needs to silence it without leaving the game.
class MuteButton extends ConsumerStatefulWidget {
  const MuteButton({super.key});

  @override
  ConsumerState<MuteButton> createState() => MuteButtonState();
}

class MuteButtonState extends ConsumerState<MuteButton> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sound = ref.read(gameFeedbackProvider).sound;
    final on = sound.sfxEnabled || sound.musicEnabled;

    return Semantics(
      button: true,
      label: on ? l10n.soundOff : l10n.soundOn,
      child: InkWell(
        onTap: () {
          final next = !on;
          sound.sfxEnabled = next;
          sound.musicEnabled = next;
          setState(() {});
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: SizedBox(
          width: AppSpacing.minTouch - 16,
          height: AppSpacing.minTouch - 16,
          child: Center(
            child: GameIconView(
              on ? GameIcon.soundOn : GameIcon.soundOff,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
