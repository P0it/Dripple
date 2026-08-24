import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/game_icons.dart';
import '../../models/game_state.dart';
import '../../models/word_card.dart';
import '../widgets/big_action_button.dart';

class ActionBar extends StatelessWidget {
  final GameState gameState;
  final bool discardMode;
  final VoidCallback onDrawFromDeck;
  final VoidCallback onDrawFromDiscard;
  final VoidCallback onSubmit;
  final VoidCallback onToggleDiscard;

  const ActionBar({
    super.key,
    required this.gameState,
    required this.discardMode,
    required this.onDrawFromDeck,
    required this.onDrawFromDiscard,
    required this.onSubmit,
    required this.onToggleDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final isHumanTurn = gameState.phase == GamePhase.playing &&
        gameState.players.isNotEmpty &&
        !gameState.currentPlayer.isAI;

    if (!isHumanTurn) {
      return Container(
        height: 76,
        alignment: Alignment.center,
        child: Text(
          '상대가 생각하고 있어요...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (discardMode) {
      return Container(
        height: 76,
        color: const Color(0xFFFEF2F2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                '버릴 카드를 골라 톡 눌러요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
            BigActionButton(
              label: '취소',
              color: const Color(0xFF9CA3AF),
              onPressed: onToggleDiscard,
            ),
          ],
        ),
      );
    }

    // Turn step 1: you must draw exactly one card.
    if (gameState.turnPhase == TurnPhase.draw) {
      final top = gameState.discardTop;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            BigActionButton(
              label: '새 카드',
              sublabel: '${gameState.deck.length}장 남음',
              icon: GameIcon.deck,
              color: AppColors.point,
              onPressed: onDrawFromDeck,
            ),
            BigActionButton(
              label: top == null ? '버린 카드' : top.word,
              sublabel: top == null ? '없어요' : '가져오기',
              icon: GameIcon.discard,
              color: const Color(0xFF3B82F6),
              onPressed: top == null ? null : onDrawFromDiscard,
            ),
          ],
        ),
      );
    }

    // Turn step 2: exactly one action.
    final canSubmit = gameState.currentPlayer.sentenceZone.length >= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BigActionButton(
            label: '문장 완성',
            sublabel: canSubmit ? null : '카드를 2장 이상 놓아요',
            icon: GameIcon.check,
            color: AppColors.point,
            onPressed: canSubmit ? onSubmit : null,
          ),
          BigActionButton(
            label: '카드 버리기',
            icon: GameIcon.discard,
            color: const Color(0xFFF97316),
            onPressed: onToggleDiscard,
          ),
        ],
      ),
    );
  }
}
class SpecialCardRow extends StatelessWidget {
  final List<WordCard> hand;
  final void Function(int handIndex) onTap;

  const SpecialCardRow({
    super.key,required this.hand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final entries = <int>[];
    for (int i = 0; i < hand.length; i++) {
      if (hand[i].type == CardType.jump || hand[i].type == CardType.steal) {
        entries.add(i);
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          for (final i in entries)
            ActionChip(
              avatar: GameIconView(
                hand[i].type == CardType.jump
                    ? GameIcon.jump
                    : GameIcon.steal,
                size: 18,
                color: AppColors.point,
              ),
              label: Text(hand[i].type == CardType.jump ? 'JUMP' : 'STEAL'),
              onPressed: () => onTap(i),
            ),
        ],
      ),
    );
  }
}
