import '../../models/word_card.dart';
import 'rules/article_rule.dart';
import 'rules/number_rule.dart';
import 'rules/sv_agreement_rule.dart';
import 'rules/adj_order_rule.dart';
import 'rules/structure_rule.dart';

class ValidationError {
  final String code;
  final String message;
  final Map<String, String>? localizedMessages;

  const ValidationError({
    required this.code,
    required this.message,
    this.localizedMessages,
  });

  @override
  String toString() => 'ValidationError($code: $message)';
}

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final int score;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.score = 0,
  });

  factory ValidationResult.valid(int score) =>
      ValidationResult(isValid: true, score: score);

  factory ValidationResult.invalid(List<ValidationError> errors) =>
      ValidationResult(isValid: false, errors: errors);
}

/// Rule interface for grammar validation
abstract class GrammarRule {
  List<ValidationError> validate(List<WordCard> sentence);
}

/// Main grammar validation engine.
/// Runs all rules against a sentence and aggregates results.
class GrammarEngine {
  final List<GrammarRule> _rules;

  GrammarEngine({List<GrammarRule>? rules})
      : _rules = rules ??
            [
              ArticleRule(),
              NumberRule(),
              SubjectVerbAgreementRule(),
              AdjectiveOrderRule(),
              StructureRule(),
            ];

  ValidationResult validate(List<WordCard> sentence) {
    if (sentence.isEmpty) {
      return ValidationResult.invalid([
        const ValidationError(
          code: 'empty_sentence',
          message: 'Sentence cannot be empty',
        ),
      ]);
    }

    // Filter out special cards, but keep joker cards (they act as any word)
    final wordCards =
        sentence.where((c) => c.type == CardType.word || c.type == CardType.joker).toList();
    // Need at least 2 cards total and at least 1 real word (joker alone can't form a sentence)
    final realWordCount = wordCards.where((c) => c.type == CardType.word).length;

    if (wordCards.length < 2 || realWordCount < 1) {
      return ValidationResult.invalid([
        const ValidationError(
          code: 'too_short',
          message: 'Sentence must have at least 2 words',
        ),
      ]);
    }

    final allErrors = <ValidationError>[];
    for (final rule in _rules) {
      allErrors.addAll(rule.validate(wordCards));
    }

    if (allErrors.isNotEmpty) {
      return ValidationResult.invalid(allErrors);
    }

    return ValidationResult.valid(_calculateScore(wordCards));
  }

  int _calculateScore(List<WordCard> sentence) {
    return sentence.length;
  }

  /// Calculate score with combo multiplier
  static int calculateScoreWithCombo(int baseScore, int comboCount) {
    if (comboCount <= 1) return baseScore;
    // 1.5x multiplier for combos
    return (baseScore * (1 + (comboCount - 1) * 0.5)).round();
  }
}
