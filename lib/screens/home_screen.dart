import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/brand/dripple_mark.dart';
import '../core/design/app_colors.dart';
import '../core/design/table_scaffold.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';
import '../core/game_feedback.dart';
import '../core/tutorial_prefs.dart';

/// The front door.
///
/// One thing to do, one way to change it. The character moved to the board,
/// where it belongs; the Character and Ranking buttons that used to sit here
/// were wired to null, and a button a child can press that does nothing is
/// worse than no button at all.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Whether to offer the lesson here. Null until it is known, so nothing
  /// flickers into place on the first frame.
  bool? _needsTutorial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gameFeedbackProvider).playMenuMusic();
    });
    TutorialPrefs.isCompleted().then((done) {
      if (mounted) setState(() => _needsTutorial = !done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // The mark is measured off the screen, not typed. A fixed 96pt was set
    // against a phone in a simulator and then shipped to every size there is:
    // on a modern handset it left the front door almost empty, a small pair of
    // cards adrift in the middle of a large dark table, with the name under it
    // at the size of a section heading. A wordmark is the largest thing on the
    // screen it introduces or it is not a wordmark.
    //
    // Both numbers are clamped as well as scaled — unbounded, the pair takes
    // over a tablet, and a mark that fills the width is a splash screen rather
    // than a front door.
    final width = MediaQuery.sizeOf(context).width;
    final markSize = (width * 0.46).clamp(120.0, 208.0);
    final wordSize = (width * 0.17).clamp(48.0, 76.0);

    return TableScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 5),
              Center(
                // Tight, so the mark's own icon margin does not silently add
                // itself to the gap between the cards and the name.
                child: DrippleMark(size: markSize, tight: true),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Dripple',
                textAlign: TextAlign.center,
                // Fraunces, not Pretendard. The face exists for exactly this
                // one string and was going unused: set in the UI face the name
                // reads as a heading that happens to say "Dripple", and set in
                // Fraunces it reads as a name printed on a box.
                style: AppTypography.onTable(AppTypography.wordmark)
                    .copyWith(fontSize: wordSize),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.wordCardBattle,
                textAlign: TextAlign.center,
                style: AppTypography.body
                    .copyWith(color: AppColors.onTableSoft),
              ),
              const Spacer(flex: 4),
              ElevatedButton(
                onPressed: () => _go(context, '/mode-select'),
                child: Text(l10n.play),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Offered here only until it has been played once. After that
              // it lives in the mode list, where someone who wants it again
              // knows to look.
              if (_needsTutorial ?? false)
                TextButton(
                  onPressed: () => _go(context, '/tutorial'),
                  child: Text(l10n.tutorialFirstTime),
                ),
              TextButton(
                onPressed: () => _go(context, '/settings'),
                child: Text(l10n.settings),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    ref.read(gameFeedbackProvider).onButtonTap();
    context.push(route);
  }
}
