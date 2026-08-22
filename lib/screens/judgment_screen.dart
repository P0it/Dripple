import 'package:flutter/material.dart';
import 'package:dripple/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_provider.dart';

class JudgmentDialog extends StatelessWidget {
  final JudgmentResult result;

  const JudgmentDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCorrect = result.isCorrect;
    final bgColor = isCorrect ? AppColors.correctGreen : AppColors.incorrectRed;

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.celebration : Icons.close,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isCorrect ? l10n.correct : l10n.incorrect,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.playerName,
            style: TextStyle(
              color: Colors.white.withAlpha(220),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // Show the sentence
          if (result.sentence.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.sentence.map((c) => c.word).join(' '),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration:
                      isCorrect ? null : TextDecoration.lineThrough,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          if (isCorrect)
            Text(
              l10n.pointsEarned(result.scoreEarned),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (!isCorrect && result.errors.isNotEmpty)
            ...result.errors.take(2).map((e) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    e.message,
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.ok,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
