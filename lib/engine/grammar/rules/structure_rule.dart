import '../../../models/word_card.dart';
import '../grammar_engine.dart';
import '../sentence_templates.dart';

/// Validates that the sentence matches a valid structure template (SVO, SVC, SV, etc.)
class StructureRule extends GrammarRule {
  @override
  List<ValidationError> validate(List<WordCard> sentence) {
    final errors = <ValidationError>[];

    final pattern = _toStructurePattern(sentence);

    if (!SentenceTemplates.isValidPattern(pattern)) {
      // Show pattern without wildcards for user-facing message
      final display = pattern.join(' ');
      errors.add(ValidationError(
        code: 'invalid_structure',
        message: 'Invalid sentence structure: $display',
        localizedMessages: {
          'ko': '잘못된 문장 구조입니다: $display',
          'ja': '無効な文構造です: $display',
        },
      ));
    }

    return errors;
  }

  /// Convert a sentence to its structural pattern.
  /// Joker cards produce a '*' wildcard token that can match any position
  /// in a template during pattern matching.
  List<String> _toStructurePattern(List<WordCard> sentence) {
    final pattern = <String>[];

    for (final card in sentence) {
      if (card.type == CardType.joker) {
        pattern.add('*');
        continue;
      }
      switch (card.pos) {
        case PartOfSpeech.pronoun:
          pattern.add('S'); // Subject
        case PartOfSpeech.article:
          pattern.add('Art');
        case PartOfSpeech.adjective:
          pattern.add('Adj');
        case PartOfSpeech.noun:
          // Noun can be subject or object depending on position
          if (!pattern.contains('S') && !pattern.contains('Art')) {
            pattern.add('S');
          } else if (pattern.contains('V')) {
            pattern.add('O');
          } else if (pattern.contains('Art') && !pattern.contains('V')) {
            // Article + Noun as subject
            pattern.add('S');
          } else {
            pattern.add('O');
          }
        case PartOfSpeech.verb:
          pattern.add('V');
        case PartOfSpeech.adverb:
          pattern.add('Adv');
        default:
          pattern.add('?');
      }
    }

    return pattern;
  }
}
