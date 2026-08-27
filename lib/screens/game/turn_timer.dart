import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_typography.dart';

/// Circular countdown arc shown during a human turn.
class TurnTimerWidget extends StatelessWidget {
  const TurnTimerWidget({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  final int secondsRemaining;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsRemaining <= 5;
    final arcColor = isUrgent ? AppColors.danger : AppColors.trim;
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
          trackColor: AppColors.trimDim,
        ),
        child: Center(
          child: Text(
            '$secondsRemaining',
            style: AppTypography.caption.copyWith(
              color: arcColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class CountdownArcPainter extends CustomPainter {
  const CountdownArcPainter({
    required this.fraction,
    required this.arcColor,
    required this.trackColor,
  });

  final double fraction;
  final Color arcColor;
  final Color trackColor;

  static const _fullTurn = 6.283185307179586;
  static const _twelveOClock = -1.5707963267948966;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    const strokeWidth = 3.0;

    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 0, _fullTurn, false, stroke(trackColor));
    if (fraction > 0) {
      canvas.drawArc(
          rect, _twelveOClock, fraction * _fullTurn, false, stroke(arcColor));
    }
  }

  @override
  bool shouldRepaint(CountdownArcPainter old) =>
      old.fraction != fraction ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor;
}
