import 'dart:ui';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart'
    show FontWeight, TextAlign, TextPainter, TextSpan, TextStyle;

import '../core/design/app_colors.dart';
import '../core/design/materials.dart';
import '../core/game_icons.dart';
import '../models/word_card.dart';

/// Draws a word card as a playing card.
///
/// Lives outside the Flame component so the same painting can be previewed in
/// a plain Flutter canvas and so the layout is readable on its own.
///
/// The anatomy, outside in: two shadows, the cut edge of the stock, the face,
/// grain, and then three marks — a short part-of-speech tick at the top left,
/// the headword at the bottom left, and the gloss under it.
///
/// **Everything on the face is flush left, and that is the whole layout.** A
/// fanned hand overlaps, and what stays visible of a covered card is its left
/// edge. Centre the word and only the top card is readable; hang everything
/// off the left margin and all seven are. That single move retired the printed
/// frame, both corner indices and the dictionary rule — the frame because a
/// 32%-wide tick says the same thing without tinting the paper, and the
/// indices because the word is already sitting where an index would go.
class CardPainter {
  const CardPainter._();

  /// Card width is capped by the board, not by taste: 84 is the widest card
  /// that still fits four across a 390pt phone, and four across is what keeps
  /// a seven-card hand down to two rows.
  static const double defaultWidth = 84;

  /// Poker proportion, 63:88. The height follows from the width; it is not a
  /// free number — `test/core/design/no_legacy_theme_test.dart` pins it,
  /// because the proportion is the thing most likely to drift back.
  static const double defaultHeight = defaultWidth * 88 / 63;

  /// A real poker card's corner is about 5.5% of its width. The old 14% is
  /// what made every card read as app chrome; this single number moves it
  /// further than anything else in the redesign.
  static const double radiusRatio = 0.06;

  /// The face's margins, as fractions of the card's width. Left and bottom
  /// are equal so the headword sits in a true corner; the top is a shade
  /// deeper because a tick reads as floating if it is level with the word.
  static const double _padTop = 0.114;
  static const double _padSide = 0.091;
  static const double _padBottom = 0.091;

  /// The part-of-speech tick: a third of the card wide, fully rounded.
  ///
  /// This replaced a frame around the whole face. The frame carried more
  /// signal than it needed to — it tinted the paper, and the paper is the one
  /// thing on this board that has to stay white.
  static const double _tickWidth = 0.318;
  static const double _tickHeight = 0.068;

  /// Type sizes, also as fractions of the width, so a card is the same card
  /// at every scale on the board.
  static const double _wordSize = 0.227;
  static const double _glossSize = 0.148;
  static const double _glossGap = 0.023;

  /// How far the card back's printed border sits in from the edge.
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
          ..color = AppColors.pointOnFelt
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

    if (card.isSpecial) {
      _specialIcon(
        canvas,
        card,
        Rect.fromLTWH(0, size.height * 0.14, size.width, size.height * 0.20),
        accent,
      );
      _word(canvas, card, size,
          centerY: size.height * 0.50, maxFontSize: size.width * 0.21);
      return;
    }

    _tick(canvas, size, accent);
    _headword(canvas, card, size, locale);
  }

  /// The part-of-speech mark: a short rounded tick in the top-left corner.
  ///
  /// Drawn at full strength rather than the printed shade the frame used. A
  /// frame at raw saturation read as "a lighter card"; a tick is a colour chip
  /// and wants to be the colour it is naming.
  static void _tick(Canvas canvas, Size size, Color accent) {
    final w = size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            w * _padSide, w * _padTop, w * _tickWidth, w * _tickHeight),
        Radius.circular(w * _tickHeight / 2),
      ),
      Paint()..color = accent,
    );
  }

  /// The word, and under it the gloss — both flush left, both hanging off the
  /// bottom margin so the gloss appearing or vanishing pushes the word up
  /// rather than leaving a hole where it used to be.
  static void _headword(
      Canvas canvas, WordCard card, Size size, String locale) {
    final w = size.width;
    final maxWidth = w * (1 - _padSide * 2);

    TextPainter build(double fontSize) => TextPainter(
          text: TextSpan(
            text: card.word,
            style: TextStyle(
              color: AppColors.ink,
              fontFamily: 'Pretendard',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -0.2,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
        )..layout();

    final word = build(fitFontSize(build, maxWidth, w * _wordSize));
    final gloss = _gloss(card, size, locale, maxWidth);

    var bottom = size.height - w * _padBottom;
    if (gloss != null) {
      gloss.paint(canvas, Offset(w * _padSide, bottom - gloss.height));
      bottom -= gloss.height + w * _glossGap;
    }
    word.paint(canvas, Offset(w * _padSide, bottom - word.height));
  }

  /// Whether [card] has anything to say in [locale] that the headword does
  /// not already say.
  @visibleForTesting
  static bool showsGloss(WordCard card, String locale) {
    final meaning = card.meanings[locale];
    if (meaning == null || meaning.isEmpty) return false;
    return meaning.toLowerCase() != card.word.toLowerCase();
  }

  /// The learner's own language, so a card teaches meaning as well as order.
  ///
  /// Null when there is nothing to teach, which is two cases and not one. The
  /// obvious one is a locale the deck has no entry for. The other is English:
  /// `meanings['en']` of an English word is that same word, so an English
  /// player was reading `you` glossed as `you` — or, until the locale was
  /// actually wired through, reading Korean.
  static TextPainter? _gloss(
      WordCard card, Size size, String locale, double maxWidth) {
    if (!showsGloss(card, locale)) return null;
    final meaning = card.meanings[locale]!;

    return TextPainter(
      text: TextSpan(
        text: meaning,
        style: TextStyle(
          color: AppColors.inkSoft,
          fontFamily: 'Pretendard',
          fontSize: size.width * _glossSize,
          fontWeight: FontWeight.w500,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
  }

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

  /// A pin-dot ground across the back, on a staggered grid. Not the mark
  /// repeated — the mark is two cards, and cards printed on a card back read
  /// as a mistake.
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

  /// The mark, in white, on the panel at the centre of the back.
  ///
  /// Drawn here rather than reaching for DrippleMarkPainter so the board does
  /// not depend on the widget layer — but it is the same geometry, and if one
  /// moves the other has to.
  static void _markOnBack(Canvas canvas, Rect bounds, Color color) {
    const cardWidth = 0.435;
    const cardHeight = cardWidth * 88 / 63;
    const radius = cardWidth * 0.155;
    const lean = 0.297;

    final w = bounds.width;

    void card(Rect rect, double alpha) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius * w)),
        Paint()..color = color.withValues(alpha: alpha),
      );
    }

    final back = Rect.fromLTWH(bounds.left + 0.235 * w,
        bounds.top + 0.200 * w, cardWidth * w, cardHeight * w);
    final front = Rect.fromLTWH(bounds.left + 0.350 * w,
        bounds.top + 0.225 * w, cardWidth * w, cardHeight * w);

    canvas.save();
    canvas.translate(back.center.dx, back.center.dy);
    canvas.rotate(-lean);
    canvas.translate(-back.center.dx, -back.center.dy);
    // The back card is held down to 45% so the two read as two even though
    // both are printed in the one ink a card back has.
    card(back, 0.45);
    canvas.restore();

    card(front, 1);
  }

  /// An empty slot where a pile would sit — a dashed outline on the felt, so
  /// the space still reads as a place rather than as nothing.
  static void paintEmptySlot(Canvas canvas, Size size) {
    final rrect = outline(size);
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.22),
    );
    Materials.hairline(canvas, rrect,
        color: AppColors.trimDim, width: 1.5, dashed: true);
  }
}
