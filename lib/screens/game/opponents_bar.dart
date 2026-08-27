import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import 'mute_button.dart';
import 'turn_timer.dart';

/// The AI opponents, whose turn it is, and the two controls that belong to no
/// player — the clock and the mute.
///
/// The active player is marked with a ring rather than a filled disc: a solid
/// block of colour at this size reads as a button and invites a tap that does
/// nothing.
///
/// The clock and the mute used to live in a strip of their own above this row,
/// alongside a copy of every player's card count. The counts were already
/// printed under each opponent here, so the strip was a second row saying what
/// this one says. These two had no double, so they came down here and the
/// strip went — which is a whole band of a short screen given back to the
/// table.
class OpponentsBar extends StatelessWidget {
  const OpponentsBar({super.key, required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final opponents = gameState.players.where((p) => p.isAI).toList();
    if (opponents.isEmpty) return const SizedBox.shrink();

    final showTimer = gameState.turnTimeRemaining >= 0 &&
        gameState.phase == GamePhase.playing;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final opponent in opponents)
                  _Opponent(
                    opponent: opponent,
                    isTheirTurn: gameState.currentPlayer.id == opponent.id,
                  ),
              ],
            ),
          ),
          if (showTimer)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: TurnTimerWidget(
                secondsRemaining: gameState.turnTimeRemaining,
                totalSeconds: gameState.config.turnTimerSeconds,
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.xs),
            child: MuteButton(),
          ),
        ],
      ),
    );
  }
}

class _Opponent extends StatelessWidget {
  const _Opponent({required this.opponent, required this.isTheirTurn});

  final Player opponent;
  final bool isTheirTurn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.rail,
            border: Border.all(
              color: isTheirTurn
                  ? AppColors.trim
                  : AppColors.trim.withValues(alpha: 0.3),
              width: isTheirTurn ? 2 : 1,
            ),
          ),
          child: Icon(
            Icons.smart_toy_outlined,
            size: 20,
            color: isTheirTurn ? AppColors.trim : AppColors.onFeltSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          opponent.name,
          style: AppTypography.caption.copyWith(
            color: isTheirTurn ? AppColors.onFelt : AppColors.onFeltSoft,
            fontWeight: isTheirTurn ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          l10n.nCards(opponent.hand.length),
          style: AppTypography.caption
              .copyWith(fontSize: 11, color: AppColors.onFeltSoft),
        ),
      ],
    );
  }
}
