import 'dart:ui';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart'
    show FontWeight, TextAlign, TextPainter, TextSpan, TextStyle;

import '../core/design/app_colors.dart';
import '../core/design/materials.dart';
import '../core/game_icons.dart';
import '../models/word_card.dart';
import 'pos_pip.dart';

/// Draws a word card as a playing card.
///
/// Lives outside the Flame component so the same painting can be previewed in
/// a plain Flutter canvas and so the layout is readable on its own.
///
/// The anatomy, outside in, is a real card's: two shadows, the cut edge of the
/// stock, the face, grain, a printed frame, corner indices, the headword, a
/// dictionary rule, and the gloss. Every one of those is load-bearing — drop
/// any and it slides back toward a rounded rectangle with text in it.
class CardPainter {
  const CardPainter._();

  /// Card width is capped by the board, not by taste: 84 is the widest card
  /// that still fits four across a 390pt phone, and four across is what keeps
  /// a seven-card hand down to two rows.
  static const double defaultWidth = 84;

  /// Poker proportion, 63:88. The height follows from the width; it is not a
  /// free number. `test/game/card_painter_test.dart` holds it there, because
  /// the proportion is the thing most likely to drift back.
  static const double defaultHeight = defaultWidth * 88 / 63;

  /// A real poker card's corner is about 5.5% of its width. The old 14% is
  /// what made every card read as app chrome; this single number moves it
  /// further than anything else in the redesign.
  static const double radiusRatio = 0.06;

  /// How far the printed frame sits in from the card's edge.
  static const double _frameInset = 0.085;

  static RRect outline(Size size) => RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * radiusRatio),
      );

  static void paint(
    Canvas canvas,
    WordCard card,
    Size size, {
    bool highlighted = false,
    bool warned = false,
    double lift = 0,
    bool shadow = true,
    String locale = 'ko',
  }) {
    final accent = card.isSpecial
        ? AppColors.specialCard(card.type)
        : AppColors.forPartOfSpeech(card.pos);
    final printed = AppColors.readableOnPaper(accent);

    final rrect = outline(size);

    if (shadow) Materials.cardShadow(canvas, rrect, lift: lift);

    _stock(canvas, rrect);
    _face(canvas, card, size, rrect, accent, printed, locale);

    if (warned) {
      canvas.drawRRect(
        rrect,
        Paint()..color = AppColors.danger.withValues(alpha: 0.16),
      );
      canvas.drawRRect(
        rrect.deflate(1.5),
        Paint()
          ..color = AppColors.danger
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else if (highlighted) {
      // Outside the stock, not inside it — a card you are holding is ringed by
      // the table light behind it, and a ring drawn on the face would look
      // printed on.
      canvas.drawRRect(
        rrect.inflate(1.75),
        Paint()
          ..color = AppColors.point
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  // ---------------------------------------------------------------------------

  /// The cut edge of the card stock. What is left visible is a sub-pixel rim
  /// slightly darker than the face, and that rim is the card's thickness.
  static void _stock(Canvas canvas, RRect rrect) {
    canvas.drawRRect(rrect, Paint()..color = AppColors.paperEdge);
  }

  static void _face(
    Canvas canvas,
    WordCard card,
    Size size,
    RRect rrect,
    Color accent,
    Color printed,
    String locale,
  ) {
    final face = rrect.deflate(1);
    canvas.drawRRect(face, Paint()..color = AppColors.paper);

    canvas.save();
    canvas.clipRRect(face);
    Materials.grainOver(canvas, face.outerRect, 0.05);
    canvas.restore();

    _frame(canvas, size, accent);

    if (card.isSpecial) {
      _specialIcon(
        canvas,
        card,
        Rect.fromLTWH(0, size.height * 0.14, size.width, size.height * 0.20),
        accent,
      );
      _word(canvas, card, size,
          centerY: size.height * 0.50, maxFontSize: size.width * 0.21);
    } else {
      _indices(canvas, card, size, printed);
      // The word owns the card. It is the thing being learned.
      _word(canvas, card, size,
          centerY: size.height * 0.375, maxFontSize: size.width * 0.30);
    }

    _rule(canvas, size, accent);
    _meaning(canvas, card, size, locale, printed);
  }

  /// The printed frame. Part-of-speech colour lives here now rather than in a
  /// bar across the top: it outlines the whole face, so it carries more signal
  /// than the old 7.5% band while reading as printing rather than as a UI
  /// element applied over the card.
  static void _frame(Canvas canvas, Size size, Color accent) {
    final inset = size.width * _frameInset;
    final radius = Radius.circular(size.width * radiusRatio * 0.55);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, size.width - inset * 2,
            size.height - inset * 2),
        radius,
      ),
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final inner = inset + 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(inner, inner, size.width - inner * 2,
            size.height - inner * 2),
        radius,
      ),
      Paint()
        ..color = accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  // ---------------------------------------------------------------------------

  /// Top-left and bottom-right, the second rotated 180°.
  ///
  /// This is the device that lets a hand be read while the cards overlap, and
  /// it is the most card-like thing on the card. Without it a fanned hand is
  /// a row of hidden words.
  static void _indices(Canvas canvas, WordCard card, Size size, Color printed) {
    final tag = PosPip.tagFor(card.pos);
    final inset = size.width * (_frameInset + 0.045);

    void block() {
      final tp = _tag(tag, size.width * 0.105, printed);
      tp.paint(canvas, Offset(inset, inset));

      final pipTop = inset + tp.height + size.height * 0.008;
      final pipSide = size.width * 0.075;
      PosPip.paint(
        canvas,
        card.pos,
        Rect.fromLTWH(inset + (tp.width - pipSide) / 2, pipTop, pipSide,
            pipSide),
        printed,
      );
    }

    block();

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(3.141592653589793);
    canvas.translate(-size.width / 2, -size.height / 2);
    block();
    canvas.restore();
  }

  static TextPainter _tag(String value, double fontSize, Color color) =>
      TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontFamily: 'Pretendard',
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.0,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  /// JUMP / STEAL / JOKER only. Word cards carry an index instead.
  static void _specialIcon(
      Canvas canvas, WordCard card, Rect bounds, Color color) {
    final icon = switch (card.type) {
      CardType.jump => GameIcon.jump,
      CardType.steal => GameIcon.steal,
      CardType.joker => GameIcon.joker,
      CardType.word => null,
    };
    if (icon != null) GameIconPainter.paint(canvas, icon, bounds, color);
  }

  static void _word(Canvas canvas, WordCard card, Size size,
      {required double centerY, required double maxFontSize}) {
    final label = card.isSpecial ? card.type.name.toUpperCase() : card.word;
    final maxWidth = size.width * 0.78;

    TextPainter build(double fontSize) => TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: AppColors.ink,
              fontFamily: 'Pretendard',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: card.isSpecial ? 0.8 : -0.2,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

    final tp = build(fitFontSize(build, maxWidth, maxFontSize));
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, centerY - tp.height / 2),
    );
  }

  /// Largest font size at which [build] lays out no wider than [maxWidth].
  ///
  /// Measure and shrink rather than guessing from the character count: a
  /// single word cannot be broken, so a wide glyph set overflows the card
  /// even at a length a threshold would treat as short. "quickly" and
  /// "happy" both did.
  ///
  /// The floor stops a pathological word from shrinking to nothing — it will
  /// clip instead, which at least stays legible.
  @visibleForTesting
  static double fitFontSize(
    TextPainter Function(double fontSize) build,
    double maxWidth,
    double maxFontSize,
  ) {
    final floor = maxFontSize * 0.5;
    var fontSize = maxFontSize;
    while (fontSize > floor && build(fontSize).width > maxWidth) {
      fontSize -= 0.5;
    }
    return fontSize;
  }

  /// The hairline between headword and gloss, the way a dictionary entry sets
  /// it. Short and centred — it separates without dividing the card in two.
  static void _rule(Canvas canvas, Size size, Color accent) {
    final half = size.width * 0.11;
    final y = size.height * 0.545;
    canvas.drawLine(
      Offset(size.width / 2 - half, y),
      Offset(size.width / 2 + half, y),
      Paint()
        ..color = accent.withValues(alpha: 0.35)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// The learner's own language, so a card teaches meaning as well as order.
  ///
  /// It sits between the rule and the bottom index rather than at the card's
  /// foot, which is both where a dictionary puts a gloss and the only band
  /// wide enough to hold it without running into the index.
  static void _meaning(
      Canvas canvas, WordCard card, Size size, String locale, Color printed) {
    final meaning = card.meanings[locale];
    if (meaning == null || meaning.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(
        text: meaning,
        style: TextStyle(
          color: printed.withValues(alpha: 0.85),
          fontFamily: 'Pretendard',
          fontSize: size.width * 0.12,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width * 0.70);

    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, size.height * 0.615),
    );
  }

  // ---------------------------------------------------------------------------

  /// The back of a card: what the deck shows.
  ///
  /// A field, a lattice, a double border, and the mark — the four things every
  /// card back in the world is made of. The lattice is the mark repeated small,
  /// so a face-down stack is unmistakably this game's.
  static void paintBack(Canvas canvas, Size size, {bool shadow = true}) {
    final rrect = outline(size);
    if (shadow) Materials.cardShadow(canvas, rrect);

    _stock(canvas, rrect);

    final face = rrect.deflate(1);
    canvas.drawRRect(face, Paint()..color = AppColors.cardBack);

    canvas.save();
    canvas.clipRRect(face);
    _lattice(canvas, size);
    Materials.grainOver(canvas, face.outerRect, 0.04);
    canvas.restore();

    final inset = size.width * _frameInset;
    final radius = Radius.circular(size.width * radiusRatio * 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            inset, inset, size.width - inset * 2, size.height - inset * 2),
        radius,
      ),
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final inner = inset + 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            inner, inner, size.width - inner * 2, size.height - inner * 2),
        radius,
      ),
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _markOnBack(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.56,
        height: size.width * 0.56,
      ),
      const Color(0xFFFFFFFF),
    );
  }

  /// The mark repeated at 6% across the back, on a staggered grid.
  static void _lattice(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.07);
    final step = size.width * 0.20;
    final r = size.width * 0.030;

    for (var row = 0; row * step < size.height + step; row++) {
      final y = row * step;
      final offset = row.isEven ? 0.0 : step / 2;
      for (var col = 0; col * step - step < size.width; col++) {
        canvas.drawCircle(Offset(col * step + offset, y), r, paint);
      }
    }
  }

  /// The three bouncing dots, simplified for the small panel on a card back.
  /// Kept here rather than reaching for DrippleMarkPainter so the board does
  /// not depend on the widget layer.
  static void _markOnBack(Canvas canvas, Rect bounds, Color color) {
    const dots = [
      (x: 0.20, rise: 0.13, radius: 0.070),
      (x: 0.50, rise: 0.32, radius: 0.100),
      (x: 0.80, rise: 0.52, radius: 0.135),
    ];
    final baselineY = bounds.top + bounds.height * 0.78;
    final solid = Paint()..color = color;

    canvas.drawLine(
      Offset(bounds.left + bounds.width * 0.10, baselineY),
      Offset(bounds.right - bounds.width * 0.10, baselineY),
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = bounds.width * 0.040
        ..strokeCap = StrokeCap.round,
    );

    for (final dot in dots) {
      canvas.drawCircle(
        Offset(bounds.left + bounds.width * dot.x,
            baselineY - bounds.height * dot.rise),
        bounds.width * dot.radius,
        solid,
      );
    }
  }

  /// An empty slot where a pile would sit — a brass outline on the felt, so
  /// the space still reads as a place rather than as nothing.
  static void paintEmptySlot(Canvas canvas, Size size) {
    final rrect = outline(size);
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.22),
    );
    Materials.hairline(canvas, rrect,
        color: AppColors.brassDim, width: 1.5, dashed: true);
  }
}
