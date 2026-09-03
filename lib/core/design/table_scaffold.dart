import 'package:flutter/material.dart';

import 'materials.dart';

/// A [Scaffold] standing on the table.
///
/// The table is a wash of light over a dark ground with grain on it, and
/// `ThemeData` has no way to express that — a theme can name a colour, not a
/// surface. So the ground is a widget, and every screen stands on it, which is
/// also what keeps the table in one place instead of being re-derived per
/// screen.
class TableScaffold extends StatelessWidget {
  const TableScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: TableGround()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        ),
      ],
    );
  }
}

/// The table itself, paintable on its own where a full scaffold is not wanted.
class TableGround extends StatelessWidget {
  const TableGround({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _TablePainter(), child: SizedBox.expand());
}

class _TablePainter extends CustomPainter {
  const _TablePainter();

  @override
  void paint(Canvas canvas, Size size) =>
      Materials.table(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_TablePainter oldDelegate) => false;
}
