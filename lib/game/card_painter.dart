import 'dart:ui';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart'
    show FontWeight, TextAlign, TextPainter, TextSpan, TextStyle;

import '../core/design/app_colors.dart';
import '../core/game_icons.dart';
import '../models/word_card.dart';

/// Draws a word card.
///
/// Lives outside the Flame component so the same painting can be previewed in
/// a plain Flutter canvas and so the layout is readable on its own.
///
/// The drop shadow here is the only shadow left in the app. On a card it
/// reads as physical stock rather than as UI chrome, which is the point of
/// the board.
class CardPainter {
  const CardPainter._();

  /// Card width is capped by the board, not by taste: 84 is the widest card
  /// that still fits four across a 390pt phone, and four across is what keeps
  /// a seven-card hand down to two rows. Going to 96 forces three rows on
  /// every phone and eats half the screen.
  ///
  /// Legibility for a six-year-old is bought with type size instead — see
  /// the font ratio in [_band] — which is the lever that actually matters.
  static const double defaultWidth = 84;
  static const double defaultHeight = 122;

  static void paint(
    Canvas canvas,
    WordCard card,
    Size size, {
    bool highlighted = false,
    bool warned = false,
    String locale = 'ko',
  }) {
    final accent = card.isSpecial
        ? AppColors.specialCard(card.type)
        : AppColors.forPartOfSpeech(card.pos);

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.14),
    );

    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    _band(canvas, card, size, rrect, accent, locale);

    if (warned) {
      // Discard candidate: a wash plus ring, so a child can see which card
      // the next tap would throw away.
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
      canvas.drawRRect(
        rrect.deflate(1.5),
        Paint()
          ..color = AppColors.point
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  // ---------------------------------------------------------------------------

  static void _band(Canvas canvas, WordCard card, Size size, RRect rrect,
      Color accent, String locale) {
    canvas.drawRRect(rrect, Paint()..color = AppColors.surface);

    final bandHeight = size.height * 0.30;
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, bandHeight),
      Paint()..color = accent,
    );
    canvas.restore();

    _symbol(canvas, card,
        Rect.fromLTWH(0, 0, size.width, bandHeight), AppColors.surface);

    _word(canvas, card, size,
        top: bandHeight + size.height * 0.06,
        color: AppColors.textPrimary,
        maxFontSize: size.width * 0.26);

    _meaning(canvas, card, size, locale, accent);

    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  // ---------------------------------------------------------------------------

  static void _symbol(
      Canvas canvas, WordCard card, Rect bounds, Color color) {
    if (card.isSpecial) {
      final icon = switch (card.type) {
        CardType.jump => GameIcon.jump,
        CardType.steal => GameIcon.steal,
        CardType.joker => GameIcon.joker,
        CardType.word => null,
      };
      if (icon != null) {
        GameIconPainter.paint(canvas, icon, bounds, color);
      }
      return;
    }
    _posSymbol(canvas, card, bounds, color);
  }

  /// Montessori grammar symbol: shape carries the part of speech.
  static void _posSymbol(
      Canvas canvas, WordCard card, Rect bounds, Color color) {
    if (card.posShape == PosShape.none) return;

    final paint = Paint()..color = color;
    final cx = bounds.center.dx;
    final cy = bounds.center.dy;
    final unit = bounds.shortestSide;

    switch (card.posShape) {
      case PosShape.triangleLarge:
      case PosShape.triangleMedium:
      case PosShape.triangleSmall:
      case PosShape.trianglePronoun:
        final half = unit *
            switch (card.posShape) {
              PosShape.triangleLarge => 0.42,
              PosShape.triangleMedium => 0.34,
              PosShape.trianglePronoun => 0.34,
              _ => 0.26,
            };
        canvas.drawPath(
          Path()
            ..moveTo(cx, cy - half)
            ..lineTo(cx - half, cy + half)
            ..lineTo(cx + half, cy + half)
            ..close(),
          paint,
        );
      case PosShape.circle:
        canvas.drawCircle(Offset(cx, cy), unit * 0.38, paint);
      case PosShape.circleSmall:
        canvas.drawCircle(Offset(cx, cy), unit * 0.24, paint);
      case PosShape.crescent:
        final r = unit * 0.36;
        canvas.saveLayer(bounds.inflate(4), Paint());
        canvas.drawCircle(Offset(cx, cy), r, paint);
        canvas.drawCircle(
          Offset(cx + r * 0.55, cy - r * 0.22),
          r * 0.92,
          Paint()..blendMode = BlendMode.clear,
        );
        canvas.restore();
      case PosShape.none:
        break;
    }
  }

  static void _word(Canvas canvas, WordCard card, Size size,
      {required double top,
      required Color color,
      required double maxFontSize}) {
    final label = card.isSpecial ? card.type.name.toUpperCase() : card.word;
    final maxWidth = size.width * 0.88;

    TextPainter build(double fontSize) => TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: color,
              fontFamily: 'Pretendard',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

    final tp = build(fitFontSize(build, maxWidth, maxFontSize));
    tp.paint(canvas, Offset((size.width - tp.width) / 2, top));
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

  /// The child's own language, so a card teaches meaning as well as order.
  static void _meaning(Canvas canvas, WordCard card, Size size, String locale,
      Color color) {
    final meaning = card.meanings[locale];
    if (meaning == null || meaning.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(
        text: meaning,
        style: TextStyle(
          color: color.withValues(alpha: 0.85),
          fontFamily: 'Pretendard',
          fontSize: size.width * 0.135,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width * 0.86);

    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, size.height - tp.height - size.height * 0.07),
    );
  }

}
