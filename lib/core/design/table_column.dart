import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Holds the app to a phone's width, whatever the window is.
///
/// Everything on the board is measured against the width it is handed and
/// nothing sets a ceiling on it, because on a phone there was never a ceiling
/// worth setting: `HandFan` spreads the fan across the width it is given,
/// `SentenceLine` lays the played cards out across the same, and the home
/// screen sizes the mark against `MediaQuery`. Open the same build in a 1920px
/// browser window and none of that breaks — it just stops being a hand. Seven
/// cards spread end to end across a metre of screen are not a fan, and a fan
/// is the thing the player reads.
///
/// The bound is applied once, here, rather than in each of the places that
/// takes a measurement. Two of them have to agree: Flame reads its own
/// constraints and the widget layer reads `MediaQuery`, so this caps the box
/// *and* rewrites what a screen inside it is told the screen is. Capping only
/// the box leaves the mark sized for a window it is no longer in.
///
/// Below the cap this is not in the way at all — it returns the child
/// untouched, so a phone build carries none of it.
class TableColumn extends StatelessWidget {
  const TableColumn({super.key, required this.child});

  /// A generous phone. Wide enough that a 430pt device is unaffected, narrow
  /// enough that the fan on a desktop is the fan the game was drawn for.
  static const double maxWidth = 480;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= maxWidth) return child;

    return ColoredBox(
      // Flat, and the dark end of the table's own gradient rather than a new
      // colour. `Materials.table` paints its wash and its grain against the
      // bounds it is given, so painting it twice — once for the window, once
      // for the column — puts two differently-centred washes side by side and
      // the seam between them is the first thing you see. Ending the surround
      // where the table's own gradient ends means the bottom edge joins
      // exactly, and only the lit top of the column stands out, which is what
      // a table under a light does anyway.
      color: AppColors.tableEdge,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(
            data: media.copyWith(size: Size(maxWidth, media.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
