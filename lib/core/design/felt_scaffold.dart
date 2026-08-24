import 'package:flutter/material.dart';

import 'materials.dart';

/// A [Scaffold] standing on the table.
///
/// The felt is a lit radial with grain and a vignette, and `ThemeData` has no
/// way to express that — a theme can name a colour, not a surface. So the
/// ground is a widget, and every screen stands on it, which is also what keeps
/// the felt in one place instead of being re-derived per screen.
class FeltScaffold extends StatelessWidget {
  const FeltScaffold({
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
        const Positioned.fill(child: FeltGround()),
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
class FeltGround extends StatelessWidget {
  const FeltGround({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _FeltPainter(), child: SizedBox.expand());
}

class _FeltPainter extends CustomPainter {
  const _FeltPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      Materials.felt(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_FeltPainter oldDelegate) => false;
}
