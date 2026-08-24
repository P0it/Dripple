import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/game_icons.dart';
import '../../models/game_state.dart';
import '../../models/word_card.dart';
import '../widgets/big_action_button.dart';

/// The two things you can do, and nothing else.
///
/// A turn is draw-then-act, so this bar only ever offers the step you are on.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.gameState,
    required this.discardMode,
    required this.onDrawFromDeck,
    required this.onDrawFromDiscard,
    required this.onSubmit,
    required this.onToggleDiscard,
  });

  final GameState gameState;
  final bool discardMode;
  final VoidCallback onDrawFromDeck;
  final VoidCallback onDrawFromDiscard;
  final VoidCallback onSubmit;
  final VoidCallback onToggleDiscard;

  static const double _height = 76;

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
            style: AppTypography.label
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (discardMode) {
      return Container(
        height: _height,
        color: AppColors.danger.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.pickCardToDiscard,
                style: AppTypography.label.copyWith(color: AppColors.danger),
              ),
            ),
            BigActionButton(
              label: l10n.cancel,
              color: AppColors.textPrimary,
              filled: false,
              onPressed: onToggleDiscard,
            ),
          ],
        ),
      );
    }

    // Turn step 1: draw exactly one card.
    if (gameState.turnPhase == TurnPhase.draw) {
      final top = gameState.discardTop;
      return _Row(
        children: [
          BigActionButton(
            label: l10n.drawNewCard,
            sublabel: l10n.deckRemaining(gameState.deck.length),
            icon: GameIcon.deck,
            color: AppColors.point,
            onPressed: onDrawFromDeck,
          ),
          BigActionButton(
            label: top?.word ?? l10n.discardPile,
            sublabel: top == null ? l10n.discardPileEmpty : l10n.takeIt,
            icon: GameIcon.discard,
            color: AppColors.textPrimary,
            filled: false,
            onPressed: top == null ? null : onDrawFromDiscard,
          ),
        ],
      );
    }

    // Turn step 2: exactly one action.
    final canSubmit = gameState.currentPlayer.sentenceZone.length >= 2;
    return _Row(
      children: [
        BigActionButton(
          label: l10n.completeSentence,
          sublabel: canSubmit ? null : l10n.needTwoCards,
          icon: GameIcon.check,
          color: AppColors.point,
          onPressed: canSubmit ? onSubmit : null,
        ),
        BigActionButton(
          label: l10n.discardACard,
          icon: GameIcon.discard,
          color: AppColors.textPrimary,
          filled: false,
          onPressed: onToggleDiscard,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }
}

/// JUMP / STEAL cards surfaced as chips — the hand itself is drawn by Flame,
/// which has no notion of tapping a card to open a sheet.
class SpecialCardRow extends StatelessWidget {
  const SpecialCardRow({super.key, required this.hand, required this.onTap});

  final List<WordCard> hand;
  final void Function(int handIndex) onTap;

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (var i = 0; i < hand.length; i++)
        if (hand[i].type == CardType.jump || hand[i].type == CardType.steal) i,
    ];
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final i in entries)
            ActionChip(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              avatar: GameIconView(
                hand[i].type == CardType.jump
                    ? GameIcon.jump
                    : GameIcon.steal,
                size: 18,
                color: AppColors.specialCard(hand[i].type),
              ),
              label: Text(
                hand[i].type == CardType.jump ? 'JUMP' : 'STEAL',
                style: AppTypography.caption
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              onPressed: () => onTap(i),
            ),
        ],
      ),
    );
  }
}
