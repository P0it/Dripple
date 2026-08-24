import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import 'mute_button.dart';

/// The top strip: which step of the turn you are on, the clock, and how many
/// cards everyone is holding.
///
/// A flat white strip over the board rather than a coloured header — the
/// board below is the thing to look at, and a solid bar of colour up here
/// competes with the cards for attention.
class ScoreboardBar extends StatelessWidget {
  const ScoreboardBar({super.key, required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final drawing = gameState.turnPhase == TurnPhase.draw;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.pointTint,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              drawing ? l10n.turnStepDraw : l10n.turnStepAction,
              style: AppTypography.caption.copyWith(
                color: AppColors.point,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const MuteButton(),
          const Spacer(),
          if (gameState.turnTimeRemaining >= 0 &&
              gameState.phase == GamePhase.playing)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TurnTimerWidget(
                secondsRemaining: gameState.turnTimeRemaining,
                totalSeconds: gameState.config.turnTimerSeconds,
              ),
            ),
          for (final player in gameState.players)
            _HandCount(player: player),
        ],
      ),
    );
  }
}

/// One player's remaining card count. A single card is the danger sign, so it
/// is the one thing here allowed to shout.
class _HandCount extends StatelessWidget {
  const _HandCount({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final nearlyOut = player.hand.length == 1;

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.isAI ? AppColors.background : AppColors.pointTint,
            ),
            child: Text(
              player.name.characters.first,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    player.isAI ? AppColors.textSecondary : AppColors.point,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${player.hand.length}',
            style: AppTypography.label.copyWith(
              color: nearlyOut ? AppColors.danger : AppColors.textPrimary,
              fontSize: nearlyOut ? 17 : 15,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final arcColor = isUrgent ? AppColors.danger : AppColors.point;
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
          trackColor: AppColors.divider,
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
