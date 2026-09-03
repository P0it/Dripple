import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'app_colors.dart';

/// The two materials the app is made of, as paint.
///
/// Colour lives in [AppColors]; this file is about surface — grain, ground,
/// bevel, and the shadows a card casts. It is the one place a gradient or a
/// blur is authored, which is what keeps materiality from leaking into a
/// screen as decoration.
abstract final class Materials {
  // ---------------------------------------------------------------------------
  // Grain
  // ---------------------------------------------------------------------------

  /// A tileable noise square, generated once and reused as a repeating shader.
  ///
  /// Drawn rather than bundled, like the mark. A texture asset would be
  /// sharper, but it would also be the first binary the design system owns,
  /// and 64px of procedural speckle at 5% opacity is doing a job no one is
  /// meant to consciously see.
  static const int _grainTile = 64;

  static Image? _grain;

  static Image get grain => _grain ??= _bakeGrain();

  static Image _bakeGrain() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // A fixed seed, so the grain is identical on every launch and every
    // device. Noise that changes between frames is static, not paper.
    final random = math.Random(20260825);
    final paint = Paint();

    for (var i = 0; i < _grainTile * _grainTile ~/ 3; i++) {
      final x = random.nextDouble() * _grainTile;
      final y = random.nextDouble() * _grainTile;
      final dark = random.nextBool();
      paint.color = (dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF))
          .withValues(alpha: 0.10 + random.nextDouble() * 0.35);
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }

    return recorder
        .endRecording()
        .toImageSync(_grainTile, _grainTile);
  }

  static final Float64List _identity = Float64List.fromList(
    const [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
  );

  /// Lays grain over whatever is already on [canvas], inside the current clip.
  static void grainOver(Canvas canvas, Rect bounds, double opacity) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ImageShader(
          grain,
          TileMode.repeated,
          TileMode.repeated,
          _identity,
        )
        ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity),
    );
  }

  // ---------------------------------------------------------------------------
  // The table
  // ---------------------------------------------------------------------------

  /// Paints the table: a flat dark ground, a breath of light at the top, grain.
  ///
  /// What is *not* here is the point. This used to be a lit radial with a
  /// vignette on the rim — a lamp hanging over a card table, and a lamp over a
  /// green table is a casino. The room was doing more talking than the game.
  ///
  /// What is left is the least a ground can do and still be a surface. The
  /// light is one soft wash near the top at 4%, so the screen has a direction
  /// without having a spotlight, and the fall-off to [AppColors.tableEdge] is a
  /// few values rather than a stop. The grain stays: the alternative is flat
  /// #15181C, and flat is a colour swatch rather than a thing.
  static void table(Canvas canvas, Rect bounds) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          const [AppColors.table, AppColors.tableEdge],
          const [0.0, 1.0],
        ),
    );

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = Gradient.radial(
          Offset(bounds.center.dx, bounds.top + bounds.height * 0.06),
          math.max(bounds.width, bounds.height) * 0.78,
          const [Color(0x0BFFFFFF), Color(0x00FFFFFF)],
          const [0.0, 1.0],
        ),
    );

    canvas.save();
    canvas.clipRect(bounds);
    grainOver(canvas, bounds, 0.045);
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Shadows
  // ---------------------------------------------------------------------------

  /// The shadow a card casts, in two layers.
  ///
  /// A single shadow floats on a page. Two — a tight dark contact and a wide
  /// soft ambient — sit on a surface. [lift] runs 0 (resting) to 1 (held), and
  /// spreads and softens both layers as the card rises; a card whose shadow
  /// does not change while it lifts reads as a sticker.
  static void cardShadow(Canvas canvas, RRect rrect, {double lift = 0}) {
    final t = lift.clamp(0.0, 1.0);

    canvas.drawRRect(
      rrect.shift(Offset(0, 1 + 3 * t)),
      Paint()
        ..color = const Color(0xFF000000)
            .withValues(alpha: 0.25 - 0.10 * t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 + 4 * t),
    );

    canvas.drawRRect(
      rrect.shift(Offset(0, 5 + 12 * t)),
      Paint()
        ..color = const Color(0xFF000000)
            .withValues(alpha: 0.20 + 0.06 * t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + 16 * t),
    );
  }

  /// A recess: a dark floor, an inner shadow under the top edge, and a
  /// highlight along the bottom one. What makes a shape read as cut into the
  /// table rather than laid on it.
  static void recess(Canvas canvas, RRect rrect, Color floor) {
    canvas.drawRRect(rrect, Paint()..color = floor);

    canvas.save();
    canvas.clipRRect(rrect);

    // Light falls from above, so the shadow inside a hole hugs its top edge.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 5)),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );

    grainOver(canvas, rrect.outerRect, 0.05);
    canvas.restore();

    // The lower lip catches the light.
    canvas.drawRRect(
      rrect.deflate(0.5).shift(const Offset(0, -0.5)),
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// A raised strip: the hand rail. The inverse of [recess] — highlight on
  /// top, shadow below.
  static void raised(Canvas canvas, RRect rrect, Color face) {
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x4D000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawRRect(rrect, Paint()..color = face);

    canvas.save();
    canvas.clipRRect(rrect);
    grainOver(canvas, rrect.outerRect, 0.05);
    canvas.restore();

    // The lit top edge, and the shaded underside that proves it is a ledge.
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(
      rrect.shift(const Offset(0, 1.5)),
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, -4)),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    canvas.restore();
  }

  /// A trim hairline along a shape's outline. [dashed] draws it as a run of
  /// dashes, which is how an empty target says "put something here" without
  /// becoming a sticker.
  static void hairline(
    Canvas canvas,
    RRect rrect, {
    Color color = AppColors.trim,
    double width = 1,
    bool dashed = false,
    double opacity = 1,
  }) {
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    if (!dashed) {
      canvas.drawRRect(rrect, paint);
      return;
    }

    const dash = 8.0, gap = 6.0;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gap;
      }
    }
  }
}
