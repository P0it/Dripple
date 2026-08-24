import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../core/design/app_colors.dart';

/// A light travelling across the sentence well.
///
/// What a table does when a sentence parses. A judgment sheet says *correct*;
/// this says it a beat earlier, on the board, where the player is already
/// looking. It removes itself when it reaches the far edge, so nothing has to
/// remember to clean it up.
class SweepComponent extends PositionComponent {
  SweepComponent({required this.bounds})
      : super(priority: 2000);

  final ui.RRect bounds;

  /// Long enough to read as a sweep, short enough not to hold up the sheet
  /// that follows it.
  static const double _duration = 0.55;

  /// How far the band leans. A vertical band reads as a wipe; a raked one
  /// reads as light crossing a surface.
  static const double _rake = 0.30;

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt / _duration;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    final rect = bounds.outerRect;
    final width = rect.width * 0.22;
    // Start fully off the leading edge and finish fully off the trailing one,
    // so neither end of the sweep pops.
    final travel = rect.width + width * 2 + rect.height * _rake;
    final x = rect.left - width - rect.height * _rake + travel * _t;

    // Fades in and out across its run rather than at the edges of the well,
    // so the band never has a hard start.
    final alpha = math.sin(math.pi * _t.clamp(0.0, 1.0));

    canvas.save();
    canvas.clipRRect(bounds);

    final path = ui.Path()
      ..moveTo(x, rect.bottom)
      ..lineTo(x + rect.height * _rake, rect.top)
      ..lineTo(x + rect.height * _rake + width, rect.top)
      ..lineTo(x + width, rect.bottom)
      ..close();

    canvas.drawPath(
      path,
      ui.Paint()
        ..color = AppColors.brass.withValues(alpha: 0.34 * alpha)
        ..maskFilter =
            const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
    );

    canvas.restore();
  }
}
