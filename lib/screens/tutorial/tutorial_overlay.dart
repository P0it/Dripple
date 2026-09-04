import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/design/materials.dart';
import '../../tutorial/tutorial_script.dart';

/// The lesson drawn over the board.
///
/// Two treatments, because the steps do two different jobs. A step that points
/// at something covers the rest of the table, leaving one bright place for the
/// eye to land. A step that asks for a gesture covers nothing and rings the
/// target instead — a hand cannot aim at what it cannot see, and a card that
/// misses has to be able to find its way home.
///
/// **What the lesson says is set on the ink, not on a card.** It used to be a
/// rounded panel of stock with a border and a Next button in the corner, which
/// is the anatomy of a web dialog: the one shape this game is not made of. The
/// game has two materials — ink and paper — and paper is where things are
/// *printed*: cards, the sheets a player reads. A voice explaining what to do
/// next is not a printed object, so it takes no object's shape. It is type on
/// the ink, in the same cream the table sets everything else in.
///
/// That subtraction paid for two other things at once. Nothing covers the
/// board any more, so the ring can be looked at while the words are read; and
/// with no panel there is nowhere to put a button, which is right, because
/// **the whole screen is the button** — see [onNext].
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.step,
    required this.hole,
    required this.onNext,
    required this.onFinish,
    required this.onQuit,
    this.stepNumber,
    this.stepCount,
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

  /// Which step this is, 1-based, and how many there are. Both null hides the
  /// count — a lesson with no end in sight is a lesson nobody starts.
  final int? stepNumber;
  final int? stepCount;

  final bool isLastStep;
  final bool isRetrying;

  /// How far the ring stands off the thing it rings.
  static const double _halo = 8;

  /// Whether a tap anywhere moves the lesson on.
  ///
  /// Only while the lesson is talking. A step waiting on a gesture has handed
  /// the board back to the player, and a tap there belongs to the deck or the
  /// card underneath — swallowing it would teach the gesture and then refuse
  /// it. Those steps end because the board changed, which is the whole design
  /// of [TutorialController].
  bool get _tapAdvances => !step.waitsForPlayer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final target = hole?.inflate(_halo);

    final marks = CustomPaint(
      painter: _CoachMarkPainter(
        hole: target,
        dim: step.dim,
        ground: AppColors.generation,
      ),
      size: Size.infinite,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: _tapAdvances
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isLastStep ? onFinish : onNext,
                  child: marks,
                )
              : IgnorePointer(child: marks),
        ),
        _words(context, l10n, target),
        // Leaving is the one thing that must not happen by accident now that
        // every other touch means "go on", so it sits alone in the corner
        // furthest from where the reading eye ends.
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: TextButton(
            onPressed: onQuit,
            child: Text(
              l10n.tutorialQuit,
              style: AppTypography.onTable(AppTypography.caption),
            ),
          ),
        ),
      ],
    );
  }

  /// The words sit on the far side of the target from the middle of the
  /// screen, so they never land on the thing they are talking about.
  Widget _words(BuildContext context, AppLocalizations l10n, Rect? target) {
    final body = _Lesson(
      text: step.text(l10n),
      hint: isRetrying ? l10n.tutorialTryAgain : null,
      counter: (stepNumber != null && stepCount != null)
          ? '$stepNumber / $stepCount'
          : null,
      // A step waiting on a gesture is ended by the board, so it must not
      // claim a tap will do it. A skippable one still offers the way out.
      footer: switch ((step.waitsForPlayer, step.skippable)) {
        (true, true) => l10n.tutorialSkip,
        (true, false) => null,
        _ => l10n.tutorialTapToContinue,
      },
      // Only the Skip footer is something to press; the rest is a statement
      // about the tap the whole screen already takes.
      onFooter: step.waitsForPlayer && step.skippable ? onNext : null,
      isLastStep: isLastStep,
      playLabel: l10n.tutorialPlayForReal,
    );

    if (target == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: body,
        ),
      );
    }

    // Below the target only while the target is near the top of the screen.
    // Anywhere lower and "below" lands on the hand rail, and words that cover
    // the cards are words telling you to move cards you cannot reach.
    final height = MediaQuery.sizeOf(context).height;
    final below = target.bottom + AppSpacing.lg;
    final placeBelow =
        target.bottom < height * 0.40 && height - below > height * 0.25;

    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      top: placeBelow ? below : null,
      bottom: placeBelow ? null : height - target.top + AppSpacing.lg,
      child: body,
    );
  }
}

/// The cover and the ring.
class _CoachMarkPainter extends CustomPainter {
  const _CoachMarkPainter({
    required this.hole,
    required this.dim,
    required this.ground,
  });

  final Rect? hole;
  final bool dim;

  /// [AppColors.generation]. The cover and the ring take their colours from
  /// the palette, and a mode swap changes both without changing the hole.
  final int ground;

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
      old.hole != hole || old.dim != dim || old.ground != ground;
}

/// What the lesson says — type on the ink, and nothing else.
///
/// No fill, no border, no radius, no button. The only concession to the board
/// underneath is a shadow cast by the letters themselves, which is what keeps
/// the words legible over a step that dims nothing.
class _Lesson extends StatelessWidget {
  const _Lesson({
    required this.text,
    required this.hint,
    required this.counter,
    required this.footer,
    required this.onFooter,
    required this.isLastStep,
    required this.playLabel,
  });

  final String text;
  final String? hint;
  final String? counter;
  final String? footer;
  final VoidCallback? onFooter;
  final bool isLastStep;
  final String playLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (counter case final n?) ...[
          Text(
            n,
            style: AppTypography.caption.copyWith(
              color: AppColors.pointOnTable,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              shadows: Materials.legibilityOnInk,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (hint case final retry?) ...[
          Text(
            retry,
            style: AppTypography.caption.copyWith(
              color: AppColors.danger,
              shadows: Materials.legibilityOnInk,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          text,
          style: AppTypography.onTable(AppTypography.heading)
              .copyWith(height: 1.45, shadows: Materials.legibilityOnInk),
        ),
        if (footer case final label?) ...[
          const SizedBox(height: AppSpacing.md),
          // The last step is the one place a word is worth pressing on its
          // own, because leaving the lesson for a real game is not "next".
          if (onFooter != null)
            TextButton(
              onPressed: onFooter,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, AppSpacing.minTouch),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                label,
                style: AppTypography.onTable(AppTypography.label)
                    .copyWith(shadows: Materials.legibilityOnInk),
              ),
            )
          else
            Text(
              isLastStep ? playLabel : label,
              style: AppTypography.caption.copyWith(
                color: AppColors.onTableSoft,
                shadows: Materials.legibilityOnInk,
              ),
            ),
        ],
      ],
    );
  }
}
