import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/game_icons.dart';
import '../../models/game_state.dart';
import '../../models/word_card.dart';
import '../../providers/game_provider.dart';

/// Bottom sheet for playing a JUMP or STEAL card.
///
/// Before this existed the human player had no way to play special cards at
/// all — only the AI could.
Future<void> showSpecialCardSheet(
  BuildContext context, {
  required WidgetRef ref,
  required WordCard card,
  required int handIndex,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final state = ref.read(gameProvider);
      final notifier = ref.read(gameProvider.notifier);

      if (card.type == CardType.jump) {
        return _JumpSheet(
          onConfirm: () {
            notifier.playJump(handIndex);
            Navigator.of(sheetContext).pop();
          },
        );
      }

      return _StealSheet(
        state: state,
        handIndex: handIndex,
        onConfirm: (targetIndex, giveIndex) {
          notifier.playSteal(
            handIndex,
            targetPlayerIndex: targetIndex,
            giveCardIndex: giveIndex,
          );
          Navigator.of(sheetContext).pop();
        },
      );
    },
  );
}

class _JumpSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  const _JumpSheet({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GameIconView(GameIcon.jump, size: 26),
              SizedBox(width: 8),
              Text('JUMP',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('다음 사람의 차례를 건너뜁니다.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onConfirm, child: const Text('사용하기')),
        ],
      ),
    );
  }
}

class _StealSheet extends StatefulWidget {
  final GameState state;
  final int handIndex;
  final void Function(int targetIndex, int giveIndex) onConfirm;

  const _StealSheet({
    required this.state,
    required this.handIndex,
    required this.onConfirm,
  });

  @override
  State<_StealSheet> createState() => _StealSheetState();
}

class _StealSheetState extends State<_StealSheet> {
  int? _target;
  int? _give;

  @override
  Widget build(BuildContext context) {
    final me = widget.state.currentPlayer;
    // playSteal indexes the hand after the STEAL card is removed.
    final handAfter = List<WordCard>.from(me.hand)..removeAt(widget.handIndex);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GameIconView(GameIcon.steal, size: 26),
              SizedBox(width: 8),
              Text('STEAL',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('상대를 고르고, 대신 줄 카드를 고르세요.'),
          const SizedBox(height: 16),
          const Text('누구에게서 가져올까요?'),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < widget.state.players.length; i++)
                if (i != widget.state.currentPlayerIndex &&
                    widget.state.players[i].hand.isNotEmpty)
                  ChoiceChip(
                    label: Text(
                      '${widget.state.players[i].name} '
                      '(${widget.state.players[i].hand.length})',
                    ),
                    selected: _target == i,
                    onSelected: (_) => setState(() => _target = i),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('어떤 카드를 줄까요?'),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < handAfter.length; i++)
                ChoiceChip(
                  label: Text(handAfter[i].word),
                  selected: _give == i,
                  onSelected: (_) => setState(() => _give = i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: (_target != null && _give != null)
                  ? () => widget.onConfirm(_target!, _give!)
                  : null,
              child: const Text('사용하기'),
            ),
          ),
        ],
      ),
    );
  }
}
