import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../models/game_state.dart';
import 'mute_button.dart';

class ScoreboardBar extends StatelessWidget {
  final GameState gameState;

  const ScoreboardBar({
    super.key,required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.point,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Turn step indicator — rounds are gone; the turn has two steps.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              gameState.turnPhase == TurnPhase.draw ? '① 뽑기' : '② 액션',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const MuteButton(),
          const Spacer(),
          // Turn timer - only shown during a human turn
          if (gameState.turnTimeRemaining >= 0 &&
              gameState.phase == GamePhase.playing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TurnTimerWidget(
                secondsRemaining: gameState.turnTimeRemaining,
                totalSeconds: gameState.config.turnTimerSeconds,
              ),
            ),
          // Cards remaining per player — one card left is the danger sign.
          ...gameState.players.map((p) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: p.isAI ? Colors.white24 : Colors.white,
                      child: Text(
                        p.name[0],
                        style: TextStyle(
                          fontSize: 12,
                          color: p.isAI ? Colors.white : AppColors.point,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${p.hand.length}',
                      style: TextStyle(
                        color: p.hand.length == 1
                            ? Colors.amberAccent
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: p.hand.length == 1 ? 18 : 14,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Circular countdown arc displayed in the scoreboard bar during human turns.

/// Circular countdown arc displayed in the scoreboard bar during human turns.
class TurnTimerWidget extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;

  const TurnTimerWidget({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsRemaining <= 5;
    final arcColor = isUrgent ? AppColors.danger : Colors.white;
    final fraction = totalSeconds > 0
        ? (secondsRemaining / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: CountdownArcPainter(
          fraction: fraction,
          arcColor: arcColor,
          trackColor: Colors.white24,
        ),
        child: Center(
          child: Text(
            '$secondsRemaining',
            style: TextStyle(
              color: arcColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class CountdownArcPainter extends CustomPainter {
  final double fraction;
  final Color arcColor;
  final Color trackColor;

  const CountdownArcPainter({
    required this.fraction,
    required this.arcColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    const strokeWidth = 3.0;
    const startAngle = -1.5707963267948966; // -pi/2 (12 o'clock)

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track (full circle)
    canvas.drawArc(rect, 0, 6.283185307179586, false, trackPaint);

    // Remaining time arc (sweeps clockwise from 12 o'clock)
    if (fraction > 0) {
      canvas.drawArc(rect, startAngle, fraction * 6.283185307179586, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(CountdownArcPainter old) =>
      old.fraction != fraction ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor;
}
