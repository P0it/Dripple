import 'package:flutter/material.dart';

import '../core/brand/dripple_mark.dart';
import '../core/design/app_colors.dart';
import '../core/design/felt_scaffold.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';

/// The first screen: three dots bounce along the line, then the wordmark
/// arrives.
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
  static const _total = Duration(milliseconds: 1400);

  late final AnimationController _controller;
  late final Animation<double> _mark;
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

    // 0.14–0.64 of 1400ms is 200ms–900ms: the three staggered bounces.
    _mark = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.14, 0.64),
    );

    // 0.64–0.86 is 900ms–1200ms: the wordmark arrives.
    _wordFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.64, 0.86, curve: Curves.easeOut),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: FeltScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DrippleMark(
                size: 132,
                animation: _mark,
                color: AppColors.pointOnFelt,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                  style: AppTypography.onFelt(AppTypography.display)
                      .copyWith(letterSpacing: -0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
