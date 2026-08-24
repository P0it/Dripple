import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';

class GameEndOverlay extends StatefulWidget {
  final GameState gameState;
  final Animation<double> fadeAnimation;
  final VoidCallback onDismiss;

  const GameEndOverlay({
    super.key,
    required this.gameState,
    required this.fadeAnimation,
    required this.onDismiss,
  });

  @override
  State<GameEndOverlay> createState() => GameEndOverlayState();
}

class GameEndOverlayState extends State<GameEndOverlay> {
  bool _dismissed = false;

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  void initState() {
    super.initState();
    // Auto-navigate after 1.5 s if the player does not tap first.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.gameState.ranking.first;
    final isHumanWinner = winner.id == 'human_0';

    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: widget.fadeAnimation,
        child: Container(
          color: Colors.black.withAlpha(204), // ~80% opacity
          child: Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Game Over!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isHumanWinner
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isHumanWinner ? 'You win!' : '${winner.name} wins!',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Final scores sorted by rank
                    ...widget.gameState.ranking.map((p) => ScoreRow(player: p)),
                    const SizedBox(height: 16),
                    Text(
                      'Tap anywhere to continue',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared score row used by both overlays

class ScoreRow extends StatelessWidget {
  final Player player;

  const ScoreRow({
    super.key,required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    player.isAI ? AppColors.textSecondary : AppColors.point,
                child: Text(
                  player.name[0],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                player.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            '${player.score} pts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.point,
            ),
          ),
        ],
      ),
    );
  }
}
