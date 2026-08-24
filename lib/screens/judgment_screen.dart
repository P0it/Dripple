import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';
import '../providers/game_provider.dart';

/// Shows the verdict on a submitted sentence.
///
/// A dialog interrupts; a sheet arrives from the same edge as the cards. A
/// failed sentence costs a child nothing but a retry, so the verdict must not
/// land like an error box — colour and one line carry it, not a big red cross.
Future<void> showJudgmentSheet(BuildContext context, JudgmentResult result) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => JudgmentSheet(result: result),
  );
}

class JudgmentSheet extends StatelessWidget {
  const JudgmentSheet({super.key, required this.result});

  final JudgmentResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = result.isCorrect ? AppColors.success : AppColors.danger;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The verdict, carried by a bar of colour rather than an icon.
          Container(height: 4, color: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.isCorrect ? l10n.correct : l10n.incorrect,
                  style: AppTypography.title.copyWith(color: accent),
                ),
                const SizedBox(height: AppSpacing.md),
                if (result.sentence.isNotEmpty)
                  Text(
                    result.sentence.map((c) => c.word).join(' '),
                    style: AppTypography.heading.copyWith(
                      decoration:
                          result.isCorrect ? null : TextDecoration.lineThrough,
                      decorationColor: AppColors.danger,
                    ),
                  ),
                if (!result.isCorrect && result.errors.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  for (final error in result.errors.take(2))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        error.message,
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                ],
                if (result.isCorrect) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    // Scoring is gone — emptying your hand is the goal, so the
                    // meaningful number is how many cards just left it.
                    l10n.nCards(result.sentence.length),
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ),
        ],
      ),
    );
  }
}
