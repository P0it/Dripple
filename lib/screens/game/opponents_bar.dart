import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../models/game_state.dart';

class OpponentsBar extends StatelessWidget {
  final GameState gameState;

  const OpponentsBar({
    super.key,required this.gameState});

  @override
  Widget build(BuildContext context) {
    final opponents = gameState.players.where((p) => p.isAI).toList();
    if (opponents.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opponents.map((opp) {
          final isCurrentTurn =
              gameState.currentPlayer.id == opp.id;
          return Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isCurrentTurn ? AppColors.point : Colors.grey.shade300,
                child: Icon(
                  Icons.smart_toy,
                  color: isCurrentTurn ? Colors.white : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                opp.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isCurrentTurn ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.nCards(opp.hand.length),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
