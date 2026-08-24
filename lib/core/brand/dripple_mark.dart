import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/app_colors.dart';

/// The Dripple mark: three dots bouncing along a line.
///
/// The name is dribble — you dribble a sentence, moving words along under
/// control until they arrive somewhere. So the mark is a rhythm, not an
/// object: three bounces gaining height as they travel left to right, which
/// is also the direction English word order runs.
///
/// Drawn rather than bundled so it is crisp at every size, from a 16px icon
/// to a full-screen splash.
class DrippleMark extends StatelessWidget {
  const DrippleMark({
    super.key,
    this.size = 72,
    this.animation,
    this.color,
  });

  final double size;

  /// Drives the bounce. Null paints the resting state.
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

/// Paints the mark part-way through its bounce.
///
/// [progress] 0 has every dot on the line; 1 has all three at rest, each at
/// its own height. Exposed so the app-icon and launch-screen bake can reuse
/// the exact geometry rather than tracing it again.
class DrippleMarkPainter extends CustomPainter {
  const DrippleMarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  /// Where the dots land, as a fraction of height.
  static const double _baseline = 0.78;

  /// Each dot: how far along, how high it rests, how big it is — all as
  /// fractions of the mark's box. Gaining height and weight as they travel
  /// is what makes it read as momentum rather than as three loose dots.
  static const _dots = [
    (x: 0.20, rise: 0.13, radius: 0.070),
    (x: 0.50, rise: 0.32, radius: 0.100),
    (x: 0.80, rise: 0.52, radius: 0.135),
  ];

  /// Fraction of the timeline each dot's own bounce takes.
  static const double _beat = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final baselineY = size.height * _baseline;

    _line(canvas, size, baselineY);

    final paint = Paint()..color = color;
    for (var i = 0; i < _dots.length; i++) {
      final dot = _dots[i];

      // Stagger the three bounces so they read as one travelling rhythm.
      final start = i * (1 - _beat) / (_dots.length - 1);
      final local = ((t - start) / _beat).clamp(0.0, 1.0);
      final height = Curves.easeOutCubic.transform(local);

      final cx = size.width * dot.x;
      final cy = baselineY - size.height * dot.rise * height;

      // Squash on the way up, so it reads as a push off the line rather than
      // a dot sliding upward.
      final squash = 1 + 0.18 * math.sin(local * math.pi);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(1 / squash, squash);
      canvas.drawCircle(Offset.zero, size.width * dot.radius, paint);
      canvas.restore();
    }
  }

  /// The ground the dots bounce off. Faint — it is context, not content.
  void _line(Canvas canvas, Size size, double y) {
    final inset = size.width * 0.10;
    canvas.drawLine(
      Offset(inset, y),
      Offset(size.width - inset, y),
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = size.width * 0.040
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(DrippleMarkPainter old) =>
      old.progress != progress || old.color != color;
}
