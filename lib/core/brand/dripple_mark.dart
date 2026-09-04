import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:dripple_rules/models/word_card.dart';

import '../../game/card_painter.dart';
import '../design/app_colors.dart';

/// The Dripple mark: two cards, dealt.
///
/// The cards are not shapes that resemble the game's cards — they are the
/// game's cards. Proportion, corner radius and the part-of-speech tick all
/// come from [CardPainter], so a change to the deck reaches the logo on the
/// same commit. A mark drawn freehand next to the thing it stands for drifts
/// away from it within a release or two.
///
/// Two ticks, in two different colours, because that is the game in one
/// picture: a sentence is words of *different kinds* put in an order. One card
/// would be a card game; two the same colour would be a pair. Two that differ
/// is a sentence starting.
///
/// The face carries the tick and nothing else. A bar standing in for the
/// headword was tried and cut: two bars turned the face into lines of text and
/// the mark into a notes icon, and one bar still collapsed into a single dark
/// stripe across the card at 24px, which is the size where a mark has to be
/// most certain of what it is. The drop from the older name went for a
/// different reason — it only ever meant anything while the name did.
///
/// What went wrong before is worth naming, because it is the easy mistake:
/// the two cards were nearly the same size and overlapped by more than half,
/// so the back one stopped reading as a card and became a coloured sliver
/// behind a rectangle. The pair is carried by *angle and offset*, not by
/// stacking — and the group is centred by measuring both cards rather than by
/// hand-placed numbers, which is what left the old mark hanging low and right.
///
/// Drawn rather than bundled so it is crisp at every size, from a 16px icon
/// to a full-screen splash.
class DrippleMark extends StatelessWidget {
  const DrippleMark({
    super.key,
    this.size = 72,
    this.animation,
    this.onLight = false,
    this.tight = false,
  });

  final double size;

  /// Drives the deal. Null paints the cards at rest.
  final Animation<double>? animation;

  /// Draw each card's cut edge harder, for grounds the stock would otherwise
  /// disappear into — a white page, a light document, print.
  final bool onLight;

  /// Trim the box down to what the cards actually occupy.
  ///
  /// A square box leaves roughly a fifth of its height empty above and below
  /// the pair, which is right for an icon — an icon needs its own margin —
  /// and wrong wherever something is set directly beneath the mark, because
  /// that empty band silently adds itself to the gap. The painter scales off
  /// the width and centres in whatever box it is handed, so a shorter box
  /// crops the padding without moving or resizing anything.
  final bool tight;

  Size get _box => tight
      ? Size(size, size * DrippleMarkPainter.contentHeight)
      : Size.square(size);

  @override
  Widget build(BuildContext context) {
    final anim = animation;

    if (anim == null) {
      return CustomPaint(
        size: _box,
        painter: DrippleMarkPainter(progress: 1, onLight: onLight),
      );
    }

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => CustomPaint(
        size: _box,
        painter: DrippleMarkPainter(progress: anim.value, onLight: onLight),
      ),
    );
  }
}

/// Paints the mark part-way through the deal.
///
/// [progress] 0 has the two cards squared up in a stack; 1 has them dealt.
/// Exposed so the app-icon and launch-screen bake reuse the exact geometry
/// rather than tracing it again.
class DrippleMarkPainter extends CustomPainter {
  const DrippleMarkPainter({
    required this.progress,
    this.onLight = false,
    this.compact = false,
  });

  final double progress;
  final bool onLight;

  /// The optical size for a tab favicon and the smallest launcher icons.
  ///
  /// Three things fail below about 32px, and none of them is a rendering bug —
  /// they are all the drawing being wrong for the size. The pair uses about
  /// two thirds of its box, so a 16px icon spends a third of itself on margin.
  /// The tick is 6.8% of a card's width, which at that size is under half a
  /// pixel, so both accents grey out and the mark stops saying "two words, of
  /// different kinds" — which is the only thing it says. And the two shadows,
  /// which sit a card on a table at 148px, are mud under a 6px card.
  ///
  /// So compact fills the box, floors the tick at a whole pixel, and drops the
  /// shadows. It is asked for, never inferred from the size handed in: a mark
  /// that silently becomes a different mark below a threshold is a mark nobody
  /// can predict, and every use inside the app is far above any threshold
  /// worth setting.
  final bool compact;

  /// How much of the box the pair fills when [compact]. Not 1: a corner that
  /// touches the edge reads as cropped, and the lean needs somewhere to go.
  static const double _compactFill = 0.92;

  /// The tick's floor when [compact], in whole device pixels.
  ///
  /// One was tried and is not enough. A one-pixel bar is never one pixel of
  /// its own colour — it lands across a pixel boundary and antialiasing mixes
  /// most of it back into the paper, leaving a grey dash that says nothing.
  /// Two pixels is the first height at which a run of the colour survives
  /// intact, and at 16px it is still only an eighth of the card.
  static const double _compactTickFloor = 2;

  /// Card width as a fraction of the mark's box. The height and the corner
  /// follow from the deck's own proportions — they are not free numbers here
  /// any more than they are on the board.
  static const double _cardWidth = 0.415;
  static double get _cardHeight => _cardWidth * 88 / 63;

  /// Where the two cards sit, before the group is centred. Only the gap
  /// between them matters; the absolute position is thrown away.
  ///
  /// The overlap is a third of a card, not two thirds. That single number is
  /// the difference between "two cards on a table" and "one card with
  /// something stuck behind it".
  static const double _frontLeft = 0.35;
  static const double _frontTop = 0.20;
  static const double _backLeft = 0.13;
  static const double _backTop = 0.20;

  /// How far the front card leans at rest, in radians.
  ///
  /// Only one of them leans, and it is the front one, rightward. Two cards on
  /// a table have one lying square and the next thrown down across it — and
  /// the one thrown is the one on top. Leaning the *back* card instead swung
  /// its lower corner out to the left and tipped the whole pair the wrong way;
  /// leaning both left them near parallel, which reads as one thick card that
  /// has split rather than as two.
  static const double _frontLean = 0.16; // ~9°
  static const double _backLean = 0;

  /// How tall the dealt pair actually is, as a fraction of the mark's width.
  ///
  /// The leaning front card is the taller of the two, so the pair measures
  /// `w·sin θ + h·cos θ`; the shadow under it wants a hair more. This is what
  /// [DrippleMark.tight] hands to the painter, and it is derived rather than
  /// typed so a change to the lean or the proportion cannot leave the mark
  /// clipped at its corner.
  static double get contentHeight =>
      _cardWidth * math.sin(_frontLean) +
      _cardHeight * math.cos(_frontLean) +
      0.026;

  /// The two ticks. A sentence is made of different kinds of word, so the
  /// mark shows two — pulled from the grammar palette rather than picked, so
  /// they stay the colours the cards themselves use.
  static Color get _backAccent =>
      AppColors.forPartOfSpeech(PartOfSpeech.adjective);
  static Color get _frontAccent =>
      AppColors.forPartOfSpeech(PartOfSpeech.verb);

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final w = size.width;
    final card = Size(_cardWidth * w, _cardHeight * w);

    // Undealt, the two cards are squared up on top of one another; the deal is
    // the mark assembling itself.
    final frontRect = Offset(_frontLeft * w, _frontTop * w) & card;
    final backRect = Offset(
          _lerp(_frontLeft, _backLeft, t) * w,
          _lerp(_frontTop, _backTop, t) * w,
        ) &
        card;
    final frontLean = _frontLean * t;
    final backLean = _backLean * t;

    // Centre the pair by measuring it. The old mark placed both cards by hand
    // and sat low and right in its own box at every size.
    final bounds = _rotatedBounds(backRect, backLean)
        .expandToInclude(_rotatedBounds(frontRect, frontLean));
    final shift = Offset(size.width, size.height) / 2 - bounds.center;

    canvas.save();
    if (compact) {
      // Scale the pair about its own centre until it fills the box. Everything
      // below is then drawn in units that are `scale` physical pixels each,
      // which is why the tick's floor is divided by it.
      final scale = math.min(
        size.width * _compactFill / bounds.width,
        size.height * _compactFill / bounds.height,
      );
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(scale);
      canvas.translate(-bounds.center.dx, -bounds.center.dy);
      final tickFloor = _compactTickFloor / scale;
      _card(canvas, backRect, backLean, w, _backAccent, tickFloor);
      _card(canvas, frontRect, frontLean, w, _frontAccent, tickFloor);
    } else {
      canvas.translate(shift.dx, shift.dy);
      _card(canvas, backRect, backLean, w, _backAccent, 0);
      _card(canvas, frontRect, frontLean, w, _frontAccent, 0);
    }
    canvas.restore();
  }

  /// One card: stock, face, and the part-of-speech tick the deck prints.
  void _card(Canvas canvas, Rect rect, double lean, double w, Color accent,
      double tickFloor) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(lean);
    canvas.translate(-rect.center.dx, -rect.center.dy);

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.width * CardPainter.radiusRatio),
    );

    // No shadow when compact. Two soft shadows under a 6px card are not a
    // card on a table, they are less contrast between the stock and the ground
    // at exactly the size where that contrast is all there is.
    if (!compact) _shadow(canvas, rrect, w);

    // The cut edge of the stock, then the face inside it — the same two
    // rectangles a card on the board is made of.
    canvas.drawRRect(rrect, Paint()..color = AppColors.paperEdge);
    canvas.drawRRect(
      rrect.deflate(math.max(1, w * (onLight ? 0.010 : 0.005))),
      Paint()..color = AppColors.paper,
    );

    canvas.save();
    canvas.translate(rect.left, rect.top);
    CardPainter.tick(canvas, rect.size, accent, minThickness: tickFloor);
    canvas.restore();

    canvas.restore();
  }

  /// Two shadows, near and far, because one reads as a glow. Both are tighter
  /// than a card on the table casts: at logo scale a soft shadow is the thing
  /// that turns a mark into an app-icon blob.
  void _shadow(Canvas canvas, RRect rrect, double w) {
    canvas.drawRRect(
      rrect.shift(Offset(0, w * 0.006)),
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.008),
    );
    canvas.drawRRect(
      rrect.shift(Offset(0, w * 0.020)),
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.024),
    );
  }

  /// The box a rectangle occupies once it has been turned about its centre.
  static Rect _rotatedBounds(Rect rect, double angle) {
    final c = rect.center;
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    var left = double.infinity, top = double.infinity;
    var right = -double.infinity, bottom = -double.infinity;

    for (final p in [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ]) {
      final dx = p.dx - c.dx;
      final dy = p.dy - c.dy;
      final x = c.dx + dx * cos - dy * sin;
      final y = c.dy + dx * sin + dy * cos;
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(DrippleMarkPainter old) =>
      old.progress != progress ||
      old.onLight != onLight ||
      old.compact != compact;
}
