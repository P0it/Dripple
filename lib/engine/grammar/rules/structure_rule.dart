import '../../../models/word_card.dart';
import '../grammar_engine.dart';
import '../sentence_parser.dart';

/// Validates that the sentence forms a complete structure (S := NP VP).
class StructureRule extends GrammarRule {
  final SentenceParser _parser;

  StructureRule({SentenceParser? parser})
      : _parser = parser ?? SentenceParser();

  @override
  List<ValidationError> validate(List<WordCard> sentence) {
    if (_parser.parse(sentence)) return const [];

    final display = sentence.map((c) => c.word).join(' ');
    return [
      ValidationError(
        code: 'invalid_structure',
        message: 'Not a complete sentence: $display',
        localizedMessages: {
          'ko': '완전한 문장이 아닙니다: $display',
          'ja': '完全な文ではありません: $display',
        },
      ),
    ];
  }
}
