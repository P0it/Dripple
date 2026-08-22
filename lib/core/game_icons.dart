import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Every icon the game draws.
///
/// Emoji were replaced with these because emoji render inconsistently across
/// platforms — and not at all inside the Flame canvas, which uses the bundled
/// font and has no colour-emoji table. Drawing paths also keeps one visual
/// language across the Flutter widgets and the Flame board.
enum GameIcon {
  // Special cards
  jump,
  steal,
  joker,
  // Result screen
  crown,
  // Board actions
  deck,
  discard,
  check,
  soundOn,
  soundOff,
  // Emotes and character states
  faceIdle,
  faceHappy,
  faceSad,
  faceAngry,
  faceSmug,
  faceExcited,
  faceShocked,
  faceCelebrate,
}

/// Draws [GameIcon]s as vector paths.
///
/// All geometry is authored in a 0..1 square and scaled to the target rect,
/// so an icon is identical at 16px in a chip and 40px on a card.
class GameIconPainter {
  const GameIconPainter._();

  static void paint(
    Canvas canvas,
    GameIcon icon,
    Rect bounds,
    Color color,
  ) {
    canvas.save();
    canvas.translate(bounds.left, bounds.top);
    final side = math.min(bounds.width, bounds.height);
    canvas.translate(
      (bounds.width - side) / 2,
      (bounds.height - side) / 2,
    );
    canvas.scale(side);

    switch (icon) {
      case GameIcon.jump:
        _jump(canvas, color);
      case GameIcon.steal:
        _steal(canvas, color);
      case GameIcon.joker:
        _joker(canvas, color);
      case GameIcon.crown:
        _crown(canvas, color);
      case GameIcon.deck:
        _deck(canvas, color);
      case GameIcon.discard:
        _discard(canvas, color);
      case GameIcon.check:
        _check(canvas, color);
      case GameIcon.soundOn:
        _sound(canvas, color, on: true);
      case GameIcon.soundOff:
        _sound(canvas, color, on: false);
      case GameIcon.faceIdle:
        _face(canvas, color, eyes: _Eyes.dots, mouth: _Mouth.neutral);
      case GameIcon.faceHappy:
        _face(canvas, color, eyes: _Eyes.arcs, mouth: _Mouth.smile);
      case GameIcon.faceSad:
        _face(canvas, color, eyes: _Eyes.dots, mouth: _Mouth.frown);
      case GameIcon.faceAngry:
        _face(canvas, color,
            eyes: _Eyes.dots, mouth: _Mouth.frown, brows: true);
      case GameIcon.faceSmug:
        _face(canvas, color, eyes: _Eyes.wink, mouth: _Mouth.smirk);
      case GameIcon.faceExcited:
        _face(canvas, color, eyes: _Eyes.stars, mouth: _Mouth.open);
      case GameIcon.faceShocked:
        _face(canvas, color, eyes: _Eyes.wide, mouth: _Mouth.oh);
      case GameIcon.faceCelebrate:
        _face(canvas, color, eyes: _Eyes.arcs, mouth: _Mouth.open);
        _sparkles(canvas, color);
    }

    canvas.restore();
  }

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Paint _fill(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  // ---------------------------------------------------------------------------
  // Special cards
  // ---------------------------------------------------------------------------

  /// Two chevrons and a bar — "skip ahead".
  static void _jump(Canvas canvas, Color color) {
    final p = _stroke(color, 0.13);
    for (final dx in [0.0, 0.30]) {
      canvas.drawPath(
        Path()
          ..moveTo(0.14 + dx, 0.24)
          ..lineTo(0.42 + dx, 0.5)
          ..lineTo(0.14 + dx, 0.76),
        p,
      );
    }
    canvas.drawLine(const Offset(0.88, 0.24), const Offset(0.88, 0.76), p);
  }

  /// Two arrows swapping places — STEAL is a forced exchange, not a theft.
  static void _steal(Canvas canvas, Color color) {
    final p = _stroke(color, 0.11);

    canvas.drawLine(const Offset(0.14, 0.33), const Offset(0.80, 0.33), p);
    canvas.drawPath(
      Path()
        ..moveTo(0.62, 0.17)
        ..lineTo(0.86, 0.33)
        ..lineTo(0.62, 0.49),
      p,
    );

    canvas.drawLine(const Offset(0.86, 0.67), const Offset(0.20, 0.67), p);
    canvas.drawPath(
      Path()
        ..moveTo(0.38, 0.51)
        ..lineTo(0.14, 0.67)
        ..lineTo(0.38, 0.83),
      p,
    );
  }

  /// A four-point sparkle — the wildcard.
  static void _joker(Canvas canvas, Color color) {
    canvas.drawPath(_starPath(const Offset(0.5, 0.5), 0.46, 0.15), _fill(color));
    canvas.drawPath(
      _starPath(const Offset(0.84, 0.18), 0.16, 0.05),
      _fill(color.withValues(alpha: 0.75)),
    );
  }

  /// Four-pointed star: points at the compass directions, waist pulled in
  /// to [waist] so the arms read as a sparkle rather than a diamond.
  static Path _starPath(Offset c, double r, double waist) {
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + waist, c.dy - waist, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + waist, c.dy + waist, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - waist, c.dy + waist, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - waist, c.dy - waist, c.dx, c.dy - r)
      ..close();
  }

  static void _crown(Canvas canvas, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(0.08, 0.72)
        ..lineTo(0.08, 0.30)
        ..lineTo(0.29, 0.50)
        ..lineTo(0.50, 0.20)
        ..lineTo(0.71, 0.50)
        ..lineTo(0.92, 0.30)
        ..lineTo(0.92, 0.72)
        ..close(),
      _fill(color),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(0.08, 0.76, 0.92, 0.88),
        const Radius.circular(0.04),
      ),
      _fill(color),
    );
  }

  /// A stack of cards.
  static void _deck(Canvas canvas, Color color) {
    final line = _stroke(color, 0.085);
    for (final dy in [0.0, 0.12]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.16, 0.20 + dy, 0.62, 0.46),
          const Radius.circular(0.07),
        ),
        line,
      );
    }
  }

  /// A card dropping onto a pile.
  static void _discard(Canvas canvas, Color color) {
    final line = _stroke(color, 0.085);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.22, 0.06, 0.50, 0.34),
        const Radius.circular(0.06),
      ),
      line,
    );
    canvas.drawLine(const Offset(0.47, 0.48), const Offset(0.47, 0.70), line);
    canvas.drawPath(
      Path()
        ..moveTo(0.33, 0.58)
        ..lineTo(0.47, 0.74)
        ..lineTo(0.61, 0.58),
      line,
    );
    canvas.drawLine(const Offset(0.12, 0.88), const Offset(0.82, 0.88), line);
  }

  static void _check(Canvas canvas, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(0.16, 0.52)
        ..lineTo(0.40, 0.75)
        ..lineTo(0.84, 0.25),
      _stroke(color, 0.15),
    );
  }

  static void _sound(Canvas canvas, Color color, {required bool on}) {
    final line = _stroke(color, 0.09);
    canvas.drawPath(
      Path()
        ..moveTo(0.14, 0.36)
        ..lineTo(0.30, 0.36)
        ..lineTo(0.50, 0.16)
        ..lineTo(0.50, 0.84)
        ..lineTo(0.30, 0.64)
        ..lineTo(0.14, 0.64)
        ..close(),
      _fill(color),
    );
    if (on) {
      canvas.drawArc(
          const Rect.fromLTRB(0.44, 0.28, 0.80, 0.72), -0.9, 1.8, false, line);
      canvas.drawArc(
          const Rect.fromLTRB(0.44, 0.14, 0.96, 0.86), -0.9, 1.8, false, line);
    } else {
      canvas.drawLine(const Offset(0.64, 0.36), const Offset(0.90, 0.64), line);
      canvas.drawLine(const Offset(0.90, 0.36), const Offset(0.64, 0.64), line);
    }
  }

  // ---------------------------------------------------------------------------
  // Faces
  // ---------------------------------------------------------------------------

  static void _face(
    Canvas canvas,
    Color color, {
    required _Eyes eyes,
    required _Mouth mouth,
    bool brows = false,
  }) {
    final line = _stroke(color, 0.075);
    canvas.drawCircle(const Offset(0.5, 0.5), 0.43, line);

    const leftEye = Offset(0.35, 0.42);
    const rightEye = Offset(0.65, 0.42);

    switch (eyes) {
      case _Eyes.dots:
        canvas.drawCircle(leftEye, 0.055, _fill(color));
        canvas.drawCircle(rightEye, 0.055, _fill(color));
      case _Eyes.wide:
        canvas.drawCircle(leftEye, 0.09, line);
        canvas.drawCircle(rightEye, 0.09, line);
      case _Eyes.arcs:
        for (final e in [leftEye, rightEye]) {
          canvas.drawPath(
            Path()
              ..moveTo(e.dx - 0.08, e.dy + 0.03)
              ..quadraticBezierTo(e.dx, e.dy - 0.10, e.dx + 0.08, e.dy + 0.03),
            line,
          );
        }
      case _Eyes.wink:
        canvas.drawPath(
          Path()
            ..moveTo(leftEye.dx - 0.08, leftEye.dy)
            ..lineTo(leftEye.dx + 0.08, leftEye.dy),
          line,
        );
        canvas.drawCircle(rightEye, 0.055, _fill(color));
      case _Eyes.stars:
        canvas.drawPath(_starPath(leftEye, 0.11, 0.03), _fill(color));
        canvas.drawPath(_starPath(rightEye, 0.11, 0.03), _fill(color));
    }

    if (brows) {
      canvas.drawLine(
          const Offset(0.24, 0.26), const Offset(0.42, 0.33), line);
      canvas.drawLine(
          const Offset(0.76, 0.26), const Offset(0.58, 0.33), line);
    }

    switch (mouth) {
      case _Mouth.neutral:
        canvas.drawLine(
            const Offset(0.38, 0.66), const Offset(0.62, 0.66), line);
      case _Mouth.smile:
        canvas.drawPath(
          Path()
            ..moveTo(0.32, 0.61)
            ..quadraticBezierTo(0.5, 0.78, 0.68, 0.61),
          line,
        );
      case _Mouth.frown:
        canvas.drawPath(
          Path()
            ..moveTo(0.32, 0.72)
            ..quadraticBezierTo(0.5, 0.56, 0.68, 0.72),
          line,
        );
      case _Mouth.smirk:
        canvas.drawPath(
          Path()
            ..moveTo(0.34, 0.66)
            ..quadraticBezierTo(0.52, 0.76, 0.68, 0.62),
          line,
        );
      case _Mouth.open:
        canvas.drawPath(
          Path()
            ..moveTo(0.32, 0.60)
            ..quadraticBezierTo(0.5, 0.84, 0.68, 0.60)
            ..close(),
          _fill(color),
        );
      case _Mouth.oh:
        canvas.drawOval(
            const Rect.fromLTRB(0.42, 0.60, 0.58, 0.78), _fill(color));
    }
  }

  static void _sparkles(Canvas canvas, Color color) {
    final faded = color.withValues(alpha: 0.8);
    canvas.drawPath(_starPath(const Offset(0.10, 0.16), 0.11, 0.03),
        _fill(faded));
    canvas.drawPath(_starPath(const Offset(0.90, 0.20), 0.08, 0.02),
        _fill(faded));
  }
}

enum _Eyes { dots, wide, arcs, wink, stars }

enum _Mouth { neutral, smile, frown, smirk, open, oh }

/// Flutter widget wrapper so the same paths appear in chips, dialogs and the
/// character view.
class GameIconView extends StatelessWidget {
  final GameIcon icon;
  final double size;
  final Color color;

  const GameIconView(
    this.icon, {
    super.key,
    this.size = 24,
    this.color = const Color(0xFF1F2937),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GameIconCustomPainter(icon, color)),
    );
  }
}

class _GameIconCustomPainter extends CustomPainter {
  final GameIcon icon;
  final Color color;

  const _GameIconCustomPainter(this.icon, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    GameIconPainter.paint(canvas, icon, Offset.zero & size, color);
  }

  @override
  bool shouldRepaint(_GameIconCustomPainter old) =>
      old.icon != icon || old.color != color;
}
