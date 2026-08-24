import 'dart:ui';

import '../models/word_card.dart';

/// The suit mark in a card's corner index.
///
/// These are the Montessori grammar symbols — noun a triangle, verb a circle,
/// preposition a crescent — returned to the card at the size a suit mark
/// actually is.
///
/// The 2026-08-22 commit removed these deliberately, and this is not a blind
/// revert. What it removed was a *large* shape sitting in a coloured band
/// across the top of the card, which it correctly judged to be a block of
/// colour with nothing in it. What comes back is a 3px mark under a dictionary
/// abbreviation, doing the job a suit does: letting a hand be read while the
/// cards overlap. The semantics were never the problem. The size was.
///
/// Geometry is authored in a 0..1 square and scaled to the target rect, the
/// same contract [GameIconPainter] uses, so a pip is identical at any size.
abstract final class PosPip {
  /// The dictionary abbreviation printed above the pip.
  ///
  /// Lowercase with a full stop, the way a dictionary sets it. An adult reads
  /// the abbreviation; a child reads the shape and the colour. Neither has to
  /// wait for the other.
  static String tagFor(PartOfSpeech? pos) => switch (pos) {
        PartOfSpeech.noun => 'n.',
        PartOfSpeech.pronoun => 'pron.',
        PartOfSpeech.verb => 'v.',
        PartOfSpeech.adjective => 'adj.',
        PartOfSpeech.adverb => 'adv.',
        PartOfSpeech.article => 'art.',
        PartOfSpeech.preposition => 'prep.',
        null => '',
      };

  /// Relative weight of each pip, so the Montessori size hierarchy survives:
  /// the noun's triangle is the big one, the article's the small one, and the
  /// adjective sits between them.
  static double _scaleFor(PartOfSpeech? pos) => switch (pos) {
        PartOfSpeech.noun => 1.00,
        PartOfSpeech.pronoun => 0.92,
        PartOfSpeech.verb => 1.00,
        PartOfSpeech.adjective => 0.82,
        PartOfSpeech.adverb => 0.70,
        PartOfSpeech.article => 0.64,
        PartOfSpeech.preposition => 0.92,
        null => 0.80,
      };

  static void paint(
    Canvas canvas,
    PartOfSpeech? pos,
    Rect bounds,
    Color color,
  ) {
    final side = bounds.shortestSide * _scaleFor(pos);
    if (side <= 0) return;

    canvas.save();
    canvas.translate(
      bounds.left + (bounds.width - side) / 2,
      bounds.top + (bounds.height - side) / 2,
    );
    canvas.scale(side);

    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    switch (pos) {
      case PartOfSpeech.noun:
      case PartOfSpeech.adjective:
      case PartOfSpeech.article:
        _triangle(canvas, paint, width: 1.0);
      case PartOfSpeech.pronoun:
        // Narrower, so it reads as its own symbol beside the noun's at a
        // glance rather than only as a smaller one.
        _triangle(canvas, paint, width: 0.74);
      case PartOfSpeech.verb:
      case PartOfSpeech.adverb:
        canvas.drawCircle(const Offset(0.5, 0.5), 0.5, paint);
      case PartOfSpeech.preposition:
        _crescent(canvas, paint);
      case null:
        canvas.drawRect(const Rect.fromLTWH(0.12, 0.12, 0.76, 0.76), paint);
    }

    canvas.restore();
  }

  static void _triangle(Canvas canvas, Paint paint, {required double width}) {
    final inset = (1 - width) / 2;
    canvas.drawPath(
      Path()
        ..moveTo(0.5, 0.02)
        ..lineTo(1 - inset, 0.98)
        ..lineTo(inset, 0.98)
        ..close(),
      paint,
    );
  }

  /// Two circles, differenced. The bite is offset up and right so the crescent
  /// opens the way the Montessori symbol does.
  static void _crescent(Canvas canvas, Paint paint) {
    final full = Path()
      ..addOval(Rect.fromCircle(center: const Offset(0.5, 0.5), radius: 0.5));
    final bite = Path()
      ..addOval(Rect.fromCircle(center: const Offset(0.72, 0.34), radius: 0.44));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, bite),
      paint,
    );
  }
}
