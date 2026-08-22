import 'dart:ui';

import 'package:flutter/material.dart' show Colors, FontWeight, TextAlign,
    TextPainter, TextSpan, TextStyle;

import '../core/game_icons.dart';
import '../models/word_card.dart';

/// Visual treatments for a word card.
enum CardStyle {
  /// Coloured header band carrying the part-of-speech symbol, word below,
  /// Korean meaning at the foot.
  band,

  /// Whole card tinted, white panel holding the word.
  tinted,

  /// Playing-card layout: corner pips, large centred word.
  playingCard,
}

/// Draws a word card.
///
/// Lives outside the Flame component so the same painting can be previewed
/// in a plain Flutter canvas and so the layout is readable on its own.
class CardPainter {
  const CardPainter._();

  static const double defaultWidth = 84;
  static const double defaultHeight = 116;

  static void paint(
    Canvas canvas,
    WordCard card,
    Size size, {
    CardStyle style = CardStyle.band,
    bool highlighted = false,
    bool warned = false,
    String locale = 'ko',
  }) {
    final accent = Color(card.posColor);
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.14),
    );

    // Drop shadow, softer than a UI shadow so cards feel physical.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    switch (style) {
      case CardStyle.band:
        _band(canvas, card, size, rrect, accent, locale);
      case CardStyle.tinted:
        _tinted(canvas, card, size, rrect, accent, locale);
      case CardStyle.playingCard:
        _playingCard(canvas, card, size, rrect, accent, locale);
    }

    if (warned) {
      // Discard candidate: a red wash plus ring, so a child can see which
      // card the next tap would throw away.
      canvas.drawRRect(rrect, Paint()..color = const Color(0x33EF4444));
      canvas.drawRRect(
        rrect.deflate(1.5),
        Paint()
          ..color = const Color(0xFFEF4444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else if (highlighted) {
      canvas.drawRRect(
        rrect.deflate(1.5),
        Paint()
          ..color = const Color(0xFF22C55E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  // ---------------------------------------------------------------------------

  static void _band(Canvas canvas, WordCard card, Size size, RRect rrect,
      Color accent, String locale) {
    canvas.drawRRect(rrect, Paint()..color = Colors.white);

    final bandHeight = size.height * 0.30;
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, bandHeight),
      Paint()..color = accent,
    );
    canvas.restore();

    _symbol(canvas, card,
        Rect.fromLTWH(0, 0, size.width, bandHeight), Colors.white);

    _word(canvas, card, size,
        top: bandHeight + size.height * 0.06,
        color: const Color(0xFF111827),
        maxFontSize: size.width * 0.21);

    _meaning(canvas, card, size, locale, accent);

    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..color = const Color(0x14000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  static void _tinted(Canvas canvas, WordCard card, Size size, RRect rrect,
      Color accent, String locale) {
    canvas.drawRRect(rrect, Paint()..color = _soften(accent, 0.86));

    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.26,
          size.width * 0.84, size.height * 0.50),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(inner, Paint()..color = Colors.white);

    _symbol(canvas, card,
        Rect.fromLTWH(0, size.height * 0.02, size.width, size.height * 0.22),
        accent);

    _word(canvas, card, size,
        top: size.height * 0.36,
        color: const Color(0xFF111827),
        maxFontSize: size.width * 0.20);

    _meaning(canvas, card, size, locale, _darken(accent));
  }

  static void _playingCard(Canvas canvas, WordCard card, Size size, RRect rrect,
      Color accent, String locale) {
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect.deflate(2),
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final pip = size.width * 0.20;
    _symbol(canvas, card,
        Rect.fromLTWH(size.width * 0.07, size.height * 0.05, pip, pip), accent);

    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(3.14159265);
    _symbol(canvas, card,
        Rect.fromLTWH(size.width * 0.07, size.height * 0.05, pip, pip), accent);
    canvas.restore();

    _word(canvas, card, size,
        top: size.height * 0.36,
        color: const Color(0xFF111827),
        maxFontSize: size.width * 0.22);

    _meaning(canvas, card, size, locale, accent);
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
    final fontSize = label.length > 7
        ? maxFontSize * 0.72
        : label.length > 5
            ? maxFontSize * 0.86
            : maxFontSize;

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * 0.88);

    tp.paint(canvas, Offset((size.width - tp.width) / 2, top));
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
          fontSize: size.width * 0.125,
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

  static Color _soften(Color c, double t) => Color.lerp(c, Colors.white, t)!;
  static Color _darken(Color c) => Color.lerp(c, Colors.black, 0.25)!;
}
