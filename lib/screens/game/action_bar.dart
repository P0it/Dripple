import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/game_icons.dart';
import 'package:dripple_rules/models/game_state.dart';
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
    required this.onPass,
    this.submitKey,
  });

  final GameState gameState;
  final VoidCallback onSubmit;

  /// Null hides the button. The tutorial is a one-player board, where handing
  /// the turn on hands it straight back.
  final VoidCallback? onPass;

  /// Lets the tutorial find this button. The board's own furniture is drawn
  /// on a canvas and asked for its rectangle; this is a widget, so it is
  /// found the way a widget is found.
  final Key? submitKey;

  /// Tall enough for the button row plus a hint that wraps to two lines in
  /// the wordier locales on a narrow phone.
  static const double _height = 122;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!gameState.isMyTurn) {
      return SizedBox(
        height: _height,
        child: Center(
          child: Text(
            l10n.opponentThinking,
            style:
                AppTypography.label.copyWith(color: AppColors.onTableSoft),
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
                AppTypography.label.copyWith(color: AppColors.onTableSoft),
          ),
        ),
      );
    }

    final canSubmit = gameState.currentPlayer.sentenceZone.length >= 2;

    // Two ways to finish a turn, because a hand that cannot make a sentence
    // still has to be able to end one. Passing keeps the card you drew — that
    // is the move that grows a hand into a long sentence, and the reason a
    // player is never forced to throw a card away just to hand over the turn.
    // Throwing one away stays a gesture on the board, named in the line below.
    return SizedBox(
      height: _height,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: BigActionButton(
                    key: submitKey,
                    label: l10n.completeSentence,
                    icon: GameIcon.check,
                    color: AppColors.trim,
                    onPressed: canSubmit ? onSubmit : null,
                  ),
                ),
                if (onPass case final pass?) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: BigActionButton(
                      label: l10n.passTurn,
                      sublabel: l10n.passTurnSub,
                      icon: GameIcon.jump,
                      color: AppColors.ink,
                      filled: false,
                      onPressed: pass,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // One line, saying whatever is most useful right now: why the
            // submit button will not press yet, or — once it will — the one
            // move that is made on the board rather than down here.
            Text(
              canSubmit ? l10n.dragToDiscard : l10n.needTwoCards,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTypography.caption
                  .copyWith(color: AppColors.onTableSoft),
            ),
          ],
        ),
      ),
    );
  }
}
