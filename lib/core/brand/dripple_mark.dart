import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/app_colors.dart';

/// The Dripple mark: a drop landing, two ripples spreading.
///
/// "Dripple" reads as drip + ripple, and the image doubles as the product
/// metaphor — a word lands, a sentence spreads out from it.
///
/// Drawn rather than bundled so it is crisp at every size, from a 16px
/// favicon to a full-screen splash.
class DrippleMark extends StatelessWidget {
  const DrippleMark({
    super.key,
    this.size = 72,
    this.animation,
    this.color,
  });

  final double size;

  /// Drives the drop-and-spread. Null paints the resting state.
  final Animation<double>? animation;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final paintColor = color ?? AppColors.point;
    final anim = animation;

    if (anim == null) {
      return CustomPaint(
        size: Size.square(size),
        painter: DrippleMarkPainter(progress: 1, color: paintColor),
      );
    }

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => CustomPaint(
        size: Size.square(size),
        painter: DrippleMarkPainter(progress: anim.value, color: paintColor),
      ),
    );
  }
}

/// Paints the mark at a point in its fall.
///
/// [progress] 0 holds the drop above the surface, [_impact] is the landing,
/// 1 is fully spread. Exposed so the app-icon and launch-screen bake can
/// reuse the exact geometry rather than tracing it again.
class DrippleMarkPainter extends CustomPainter {
  const DrippleMarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  /// Where in the timeline the drop lands.
  static const double _impact = 0.45;

  /// The drop's resting centre, as a fraction of height.
  static const double _restY = 0.42;

  /// Where the drop starts, as a fraction of height. Above the canvas.
  static const double _startY = -0.30;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final t = progress.clamp(0.0, 1.0);

    // Fall: accelerating descent from above the canvas to the resting height.
    final fall = (t / _impact).clamp(0.0, 1.0);
    final dropY = h *
        (_startY + (_restY - _startY) * Curves.easeInCubic.transform(fall));

    // Squash on impact, recovering over the next fifth of the timeline.
    final sinceImpact = ((t - _impact) / 0.2).clamp(0.0, 1.0);
    final squash = 1 - 0.26 * math.sin(sinceImpact * math.pi);

    // Ripples sit behind the drop.
    _ripples(canvas, size, cx, h * _restY, t);

    final r = w * 0.15;
    canvas.save();
    canvas.translate(cx, dropY);
    canvas.scale(1 / squash, squash);
    canvas.drawPath(_dropPath(r), Paint()..color = color);
    canvas.restore();
  }

  /// A teardrop: round at the bottom, drawn to a point at the top.
  Path _dropPath(double r) => Path()
    ..moveTo(0, -r * 1.85)
    ..cubicTo(r * 0.62, -r * 0.95, r, -r * 0.20, r, r * 0.10)
    ..arcToPoint(Offset(-r, r * 0.10), radius: Radius.circular(r))
    ..cubicTo(-r, -r * 0.20, -r * 0.62, -r * 0.95, 0, -r * 1.85)
    ..close();

  void _ripples(Canvas canvas, Size size, double cx, double cy, double t) {
    if (t <= _impact) return;
    final spread = ((t - _impact) / (1 - _impact)).clamp(0.0, 1.0);

    // Two arcs. They differ in final radius as well as in timing — staggering
    // the timing alone leaves them landing on the same circle, which reads as
    // one thick ring instead of a spreading pair.
    _ripple(canvas, size, cx, cy, spread,
        delay: 0.0, alpha: 0.34, reach: 0.20);
    _ripple(canvas, size, cx, cy, spread,
        delay: 0.26, alpha: 0.17, reach: 0.40);
  }

  void _ripple(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double spread, {
    required double delay,
    required double alpha,

    /// How far past the drop this arc spreads, as a fraction of width.
    required double reach,
  }) {
    final local = ((spread - delay) / (1 - delay)).clamp(0.0, 1.0);
    if (local <= 0) return;

    final eased = Curves.easeOutCubic.transform(local);
    final rx = size.width * (0.15 + reach * eased);
    final ry = rx * 0.30;
    final y = cy + size.height * (0.17 + 0.04 * eased);

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.042 * (1 - 0.35 * eased)
      ..strokeCap = StrokeCap.round;

    // An arc rather than a full ellipse — it reads as a ripple seen at an
    // angle, and the open top leaves room for the drop.
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, y), width: rx * 2, height: ry * 2),
      math.pi * 0.06,
      math.pi * 0.88,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(DrippleMarkPainter old) =>
      old.progress != progress || old.color != color;
}
