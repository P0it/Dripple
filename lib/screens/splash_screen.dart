import 'package:flutter/material.dart';

import '../core/brand/dripple_mark.dart';
import '../core/design/table_scaffold.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';

/// The first screen: one card is laid down, a second is dealt out from under
/// it, and the name arrives once they have settled.
///
/// The mark is two cards at rest and exactly one card at `progress` 0, because
/// the pair starts squared up — so the whole opening is a matter of *timing*,
/// not of geometry. What makes it read as one card becoming two is the 180ms
/// in the middle where nothing happens: without that beat the card appears and
/// splits in the same motion, and a viewer never sees the single card at all.
///
/// [onFinished] is injected rather than navigating directly, so the timeline
/// can be tested without standing up a router.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 1600);

  late final AnimationController _controller;
  late final Animation<double> _cardIn;
  late final Animation<double> _cardRise;
  late final Animation<double> _deal;
  late final Animation<double> _wordFade;
  late final Animation<double> _wordRise;

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();

    // 0–260ms: one card rises into place. The pair is still squared up here,
    // so what arrives is a single card.
    _cardIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.1625, curve: Curves.easeOut),
    );
    _cardRise = Tween<double>(begin: 6, end: 0).animate(_cardIn);

    // 260–440ms is the hold, and it is the whole point: it is simply the gap
    // between the two intervals either side of it.

    // 440–1100ms: the deal. Linear here because the painter applies
    // easeOutCubic itself — curving both ends would double the ease and leave
    // the card crawling into place.
    _deal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.275, 0.6875),
    );

    // 1100–1400ms: the name, after the cards have stopped moving.
    _wordFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6875, 0.875, curve: Curves.easeOut),
    );
    _wordRise = Tween<double>(begin: 8, end: 0).animate(_wordFade);
  }

  /// A splash must never be a wall, so a tap ends it early. Guarded because
  /// the controller completing would otherwise fire it a second time.
  void _finish() {
    if (_done) return;
    _done = true;
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The mark's width, and with it the wordmark and the gap beneath — both are
  /// set against it rather than chosen, so the lockup holds its proportions at
  /// every size.
  ///
  /// Scaled and clamped, the way the home screen already sizes the same mark.
  /// It was a flat 148 until the web build was opened on a desktop: 148 is 38%
  /// of a phone and 8% of a browser window, so the opening of the game was a
  /// speck in the middle of a dark screen. `TableColumn` holds the app to a
  /// phone's width above this, which is what keeps the two numbers agreeing.
  static double _markWidthFor(double screenWidth) =>
      (screenWidth * 0.38).clamp(120.0, 200.0);

  @override
  Widget build(BuildContext context) {
    final markSize = _markWidthFor(MediaQuery.sizeOf(context).width);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: TableScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _cardIn,
                builder: (_, child) => Opacity(
                  opacity: _cardIn.value,
                  child: Transform.translate(
                    offset: Offset(0, _cardRise.value),
                    child: child,
                  ),
                ),
                // Tight, because the square box's empty band would add itself
                // to the gap below and push the name away from the mark.
                child: DrippleMark(
                  size: markSize,
                  animation: _deal,
                  tight: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md + AppSpacing.xs),
              AnimatedBuilder(
                animation: _wordFade,
                builder: (_, child) => Opacity(
                  opacity: _wordFade.value,
                  child: Transform.translate(
                    offset: Offset(0, _wordRise.value),
                    child: child,
                  ),
                ),
                child: Text(
                  'Dripple',
                  style: AppTypography.onTable(AppTypography.wordmark)
                      .copyWith(fontSize: markSize * 0.176),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
