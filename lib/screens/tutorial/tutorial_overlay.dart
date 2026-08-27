import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../tutorial/tutorial_script.dart';

/// The lesson drawn over the board.
///
/// Two treatments, because the steps do two different jobs. A step that points
/// at something covers the rest of the table, leaving one bright place for the
/// eye to land. A step that asks for a gesture covers nothing and rings the
/// target instead — a hand cannot aim at what it cannot see, and a card that
/// misses has to be able to find its way home.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.step,
    required this.hole,
    required this.onNext,
    required this.onFinish,
    required this.onQuit,
    this.isLastStep = false,
    this.isRetrying = false,
  });

  final TutorialStep step;

  /// Where the target is, in this overlay's own coordinates. Null when the
  /// step points at nothing.
  final Rect? hole;

  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onQuit;
  final bool isLastStep;
  final bool isRetrying;

  /// How far the ring stands off the thing it rings.
  static const double _halo = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final target = hole?.inflate(_halo);

    final marks = CustomPaint(
      painter: _CoachMarkPainter(hole: target, dim: step.dim),
      size: Size.infinite,
    );

    return Stack(
      children: [
        // While the board is covered there is nothing on it to touch, so the
        // cover takes the taps. While it is not, every touch belongs to the
        // board underneath and passes straight through.
        Positioned.fill(
          child: step.dim
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: marks,
                )
              : IgnorePointer(child: marks),
        ),
        _bubble(context, l10n, target),
      ],
    );
  }

  /// The coach mark sits on the far side of the target from the middle of the
  /// screen, so it never lands on the thing it is talking about.
  Widget _bubble(BuildContext context, AppLocalizations l10n, Rect? target) {
    final card = _Bubble(
      text: step.text(l10n),
      hint: isRetrying ? l10n.tutorialTryAgain : null,
      primaryLabel: isLastStep ? l10n.tutorialPlayForReal : l10n.tutorialNext,
      onPrimary: isLastStep ? onFinish : onNext,
      // A step waiting on a gesture has no Next; one that is merely optional
      // offers Skip, so nobody is trapped by a move they cannot make.
      showPrimary: !step.waitsForPlayer || step.skippable,
      primaryIsSkip: step.waitsForPlayer && step.skippable,
      skipLabel: l10n.tutorialSkip,
      quitLabel: l10n.tutorialQuit,
      onQuit: onQuit,
    );

    if (target == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: card,
        ),
      );
    }

    // Below the target only while the target is near the top of the screen.
    // Anywhere lower and "below" lands on the hand rail, and a coach mark
    // that covers the cards is a coach mark telling you to move cards you
    // cannot reach.
    final height = MediaQuery.sizeOf(context).height;
    final below = target.bottom + AppSpacing.md;
    final placeBelow =
        target.bottom < height * 0.40 && height - below > height * 0.25;

    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: placeBelow ? below : null,
      bottom: placeBelow ? null : height - target.top + AppSpacing.md,
      child: card,
    );
  }
}

/// The cover and the ring.
class _CoachMarkPainter extends CustomPainter {
  const _CoachMarkPainter({required this.hole, required this.dim});

  final Rect? hole;
  final bool dim;

  static const Radius _radius = Radius.circular(AppSpacing.radiusMd);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final target = hole;

    if (dim) {
      final cover = Path()..addRect(rect);
      final lit = target == null
          ? null
          : (Path()..addRRect(RRect.fromRectAndRadius(target, _radius)));
      canvas.drawPath(
        lit == null
            ? cover
            : Path.combine(PathOperation.difference, cover, lit),
        Paint()..color = AppColors.scrim,
      );
    }

    if (target == null) return;

    final rrect = RRect.fromRectAndRadius(target, _radius);

    // The glow is a blurred stroke rather than a shadow: the ring has to read
    // as the target being lit, not as the ring floating above it.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.trim.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.trim,
    );
  }

  @override
  bool shouldRepaint(_CoachMarkPainter old) =>
      old.hole != hole || old.dim != dim;
}

/// What the lesson says, on paper.
///
/// Paper, because it is read. Everything read in this game is printed on
/// stock; the felt only holds things.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.hint,
    required this.primaryLabel,
    required this.onPrimary,
    required this.showPrimary,
    required this.primaryIsSkip,
    required this.skipLabel,
    required this.quitLabel,
    required this.onQuit,
  });

  final String text;
  final String? hint;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool showPrimary;
  final bool primaryIsSkip;
  final String skipLabel;
  final String quitLabel;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.paperEdge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hint case final retry?) ...[
              Text(
                retry,
                style: AppTypography.caption.copyWith(color: AppColors.danger),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(text, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton(
                  onPressed: onQuit,
                  child: Text(quitLabel, style: AppTypography.caption),
                ),
                const Spacer(),
                if (showPrimary)
                  FilledButton(
                    onPressed: onPrimary,
                    child: Text(primaryIsSkip ? skipLabel : primaryLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
