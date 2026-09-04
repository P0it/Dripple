import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// One seat at the table.
enum Seat {
  /// You. The only seat that takes the brand blue.
  you,

  /// Somebody already sitting there — an AI, or a friend who joined.
  taken,

  /// A chair nobody is in yet.
  open,
}

/// A table seen from above, with the seats that will be at it.
///
/// This replaces the row of Material icons the mode list used to carry — a
/// mortarboard, a robot, a plus, two heads, a globe. Five metaphors borrowed
/// from five unrelated pictures, sharing nothing with each other or with the
/// game, which is exactly what makes a screen read as assembled rather than
/// designed. The rest of the app already draws its own icons for the same
/// reason ([GameIcon]); the menu was the one place that did not.
///
/// What the marks say is also the thing that actually differs between the
/// modes: *who is on the other side of the table*. Learning is one chair.
/// An AI game is a full table. Making a room is you and three empty chairs;
/// joining one is a table with people at it and a chair left for you. The
/// picture carries the distinction the sentence underneath spells out, rather
/// than decorating it.
class SeatMark extends StatelessWidget {
  const SeatMark({
    super.key,
    required this.seats,
    required this.ground,
    this.size = 30,
    this.muted = false,
  });

  /// The seats, clockwise from the near edge — yours is the near one, because
  /// on a board you are always at the bottom.
  final List<Seat> seats;

  /// What the mark is drawn on. Open seats are rings, and a ring needs the
  /// table's own line cleared out from behind it.
  final Color ground;

  final double size;

  /// A mode that cannot be entered. Everything falls back to the dim trim.
  final bool muted;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _SeatMarkPainter(seats: seats, ground: ground, muted: muted),
      );
}

class _SeatMarkPainter extends CustomPainter {
  const _SeatMarkPainter({
    required this.seats,
    required this.ground,
    required this.muted,
  });

  final List<Seat> seats;
  final Color ground;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final centre = Offset(size.width / 2, size.height / 2);
    // The chairs have to be small against the table, or four of them punch
    // the ring away and the mark falls apart into loose dots.
    final ring = s * 0.34;
    final seat = s * 0.105;
    final line = math.max(1.0, s * 0.04);

    // The table. Always drawn, whoever is at it — it is what makes a lone
    // player read as somebody sitting down rather than as a stray dot.
    canvas.drawCircle(
      centre,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = line
        ..color = AppColors.trimDim,
    );

    // Clockwise from the near edge. A single seat is yours and sits nearest.
    for (var i = 0; i < seats.length; i++) {
      final angle = math.pi / 2 - i * 2 * math.pi / seats.length;
      final at = centre + Offset(math.cos(angle) * ring, -math.sin(angle) * ring);

      // Cut the table's line out from under the chair before drawing it.
      canvas.drawCircle(at, seat + line * 0.9, Paint()..color = ground);

      final colour = switch ((muted, seats[i])) {
        (true, _) => AppColors.trimDim,
        (_, Seat.you) => AppColors.pointOnTable,
        (_, Seat.taken) => AppColors.onTable,
        // A step above the table's own line, so an empty chair reads as a
        // chair rather than as part of the table.
        (_, Seat.open) => AppColors.onTableSoft,
      };

      canvas.drawCircle(
        at,
        seat,
        seats[i] == Seat.open
            ? (Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = line
              ..color = colour)
            : (Paint()..color = colour),
      );
    }
  }

  @override
  bool shouldRepaint(_SeatMarkPainter old) =>
      old.muted != muted ||
      old.ground != ground ||
      !listEquals(old.seats, seats);
}
