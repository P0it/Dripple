import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/game_icons.dart';
import '../../models/game_state.dart';
import '../widgets/big_action_button.dart';

/// The one action with nothing on the board to touch.
///
/// Drawing is a tap on the deck, taking from the discard is a tap on the
/// pile, throwing a card away is a drag onto it, and using a JUMP or STEAL is
/// a tap on the card. Submitting a sentence has no such object, so it is the
/// only button left.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.gameState,
    required this.onSubmit,
  });

  final GameState gameState;
  final VoidCallback onSubmit;

  static const double _height = 84;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isHumanTurn = gameState.phase == GamePhase.playing &&
        gameState.players.isNotEmpty &&
        !gameState.currentPlayer.isAI;

    if (!isHumanTurn) {
      return SizedBox(
        height: _height,
        child: Center(
          child: Text(
            l10n.opponentThinking,
            style:
                AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (gameState.turnPhase == TurnPhase.draw) {
      return SizedBox(
        height: _height,
        child: Center(
          child: Text(
            l10n.tapDeckToDraw,
            style:
                AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final canSubmit = gameState.currentPlayer.sentenceZone.length >= 2;

    return SizedBox(
      height: _height,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Center(
          child: BigActionButton(
            label: l10n.completeSentence,
            sublabel: canSubmit ? null : l10n.needTwoCards,
            icon: GameIcon.check,
            color: AppColors.point,
            onPressed: canSubmit ? onSubmit : null,
          ),
        ),
      ),
    );
  }
}
