import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/app_colors.dart';

/// The Dripple mark: two cards, dealt.
///
/// A card game's mark should be made of the thing the game is made of. So the
/// mark is a poker-proportioned card with a second one laid under it at an
/// angle — the moment two cards land on a table, which is the moment the game
/// starts.
///
/// There is no letter on it and no pip. The earlier mark was three dots
/// bouncing along a line, which is the shape of a loading indicator, and the
/// first thing after it was a card with a `D` and a dot printed in the corner.
/// Both were the mark saying its own name out loud. A pair of cards does not
/// need to.
///
/// Nothing is outlined. The back card is the brand blue, the front is stock,
/// and what separates them is a two-layer shadow — the same shadow a real card
/// casts on the one beneath it. That is why [onLight] exists: on felt, on ink,
/// on paper, a shadow is enough, but on pure white the front card has nothing
/// to be lighter than and vanishes into the page. There the cut edge of the
/// stock is drawn as a hairline, which is not a border added to the mark but
/// the same 1px rim every card in this game already carries.
///
/// Drawn rather than bundled so it is crisp at every size, from a 16px icon
/// to a full-screen splash.
class DrippleMark extends StatelessWidget {
  const DrippleMark({
    super.key,
    this.size = 72,
    this.animation,
    this.color,
    this.onLight = false,
  });

  final double size;

  /// Drives the deal. Null paints the cards at rest.
  final Animation<double>? animation;

  /// Overrides the back card's colour. The front card is always stock.
  final Color? color;

  /// Draw the front card's cut edge, for grounds it would otherwise disappear
  /// into — a white page, a light document, print.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final anim = animation;

    DrippleMarkPainter painter(double progress) => DrippleMarkPainter(
          progress: progress,
          color: color ?? AppColors.point,
          onLight: onLight,
        );

    if (anim == null) {
      return CustomPaint(size: Size.square(size), painter: painter(1));
    }

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) =>
          CustomPaint(size: Size.square(size), painter: painter(anim.value)),
    );
  }
}

/// Paints the mark part-way through the deal.
///
/// [progress] 0 has both cards square and stacked; 1 has the back card swung
/// out to its angle and the front card settled forward. Exposed so the
/// app-icon and launch-screen bake can reuse the exact geometry rather than
/// tracing it again.
class DrippleMarkPainter extends CustomPainter {
  const DrippleMarkPainter({
    required this.progress,
    required this.color,
    this.onLight = false,
  });

  final double progress;
  final Color color;
  final bool onLight;

  /// Both cards, as fractions of the mark's box. Poker proportion, and a
  /// corner radius a shade over the deck's own 1/20 — a mark has to survive
  /// 16px, where a 5% corner disappears. Not much over: at 15% the cards
  /// stopped reading as cards and started reading as app-icon blobs.
  static const double _cardWidth = 0.40;
  static const double _cardHeight = _cardWidth * 88 / 63;
  static const double _radius = _cardWidth * 0.09;

  /// Where the front card sits, and how far behind and to the left the back
  /// one lands. The gap between them is the mark — too small and the pair
  /// reads as one thick card with a blue rim.
  static const double _frontLeft = 0.405;
  static const double _frontTop = 0.235;
  static const double _backLeft = 0.205;
  static const double _backTop = 0.175;

  /// The back card's final angle, in radians (~20°).
  static const double _lean = 0.350;

  /// The cut edge, a step darker than the board's `paperEdge`. On felt the
  /// rim only has to hint at thickness; on a white page it is the only thing
  /// holding the card's shape, so it has to carry.
  static const Color _lightEdge = Color(0xFFCDC3AF);

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final w = size.width;

    // The back card swings out from under the front one, so at rest they are
    // stacked and the deal is the mark assembling itself.
    final backRect = Rect.fromLTWH(
      _lerp(_frontLeft, _backLeft, t) * w,
      _lerp(_frontTop, _backTop, t) * w,
      _cardWidth * w,
      _cardHeight * w,
    );
    final frontRect = Rect.fromLTWH(
      _frontLeft * w,
      _frontTop * w,
      _cardWidth * w,
      _cardHeight * w,
    );

    canvas.save();
    canvas.translate(backRect.center.dx, backRect.center.dy);
    canvas.rotate(-_lean * t);
    canvas.translate(-backRect.center.dx, -backRect.center.dy);
    _card(canvas, backRect, w, _backFill(backRect));
    canvas.restore();

    _card(canvas, frontRect, w, _frontFill(frontRect), edge: onLight);
  }

  /// The back card takes the brand blue, lit from the top-left the way a card
  /// lying on a table is.
  Paint _backFill(Rect rect) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(color, const Color(0xFFFFFFFF), 0.16)!,
        Color.lerp(color, const Color(0xFF000000), 0.38)!,
      ],
    ).createShader(rect);

  /// The front card is stock, with the faintest fall-off across it. Flat paper
  /// at this scale reads as a white rectangle; a card catches light.
  ///
  /// It starts at the deck's own warm off-white and not at pure white, which
  /// is the same reason real card stock is not white either: against a white
  /// page, a white card has nothing to be.
  Paint _frontFill(Rect rect) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [AppColors.paper, AppColors.paperShade],
    ).createShader(rect);

  void _card(Canvas canvas, Rect rect, double w, Paint fill,
      {bool edge = false}) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(_radius * w));

    // Two shadows, near and far, because one shadow reads as a glow. The near
    // one is contact; the far one is height.
    canvas.drawRRect(
      rrect.shift(Offset(0, w * 0.012)),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.016),
    );
    canvas.drawRRect(
      rrect.shift(Offset(0, w * 0.042)),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.048),
    );

    canvas.drawRRect(rrect, fill);

    if (edge) {
      canvas.drawRRect(
        rrect.deflate(w * 0.004),
        Paint()
          ..color = _lightEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, w * 0.011),
      );
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(DrippleMarkPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.onLight != onLight;
}
