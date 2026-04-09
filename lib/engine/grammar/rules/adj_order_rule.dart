import '../../../models/word_card.dart';
import '../grammar_engine.dart';

/// Validates adjective ordering follows English convention:
/// 1=opinion, 2=size, 3=quality, 4=age, 5=color, 6=origin, 7=material, 8=purpose
class AdjectiveOrderRule extends GrammarRule {
  @override
  List<ValidationError> validate(List<WordCard> sentence) {
    final errors = <ValidationError>[];

    // Find consecutive adjectives
    final adjGroups = _findAdjectiveGroups(sentence);

    for (final group in adjGroups) {
      if (group.length < 2) continue;

      for (int i = 0; i < group.length - 1; i++) {
        final current = group[i];
        final next = group[i + 1];

        if (current.adjOrder != null &&
            next.adjOrder != null &&
            current.adjOrder! > next.adjOrder!) {
          errors.add(ValidationError(
            code: 'adj_order',
            message: '"${next.word}" should come before "${current.word}" (adjective order)',
            localizedMessages: {
              'ko': '"${next.word}"가 "${current.word}" 앞에 와야 합니다 (형용사 순서)',
              'ja': '「${next.word}」は「${current.word}」の前に来るべきです（形容詞の順序）',
            },
          ));
        }
      }
    }

    return errors;
  }

  /// Find groups of consecutive adjectives in the sentence
  List<List<WordCard>> _findAdjectiveGroups(List<WordCard> sentence) {
    final groups = <List<WordCard>>[];
    var currentGroup = <WordCard>[];

    for (final card in sentence) {
      if (card.isAdjective) {
        currentGroup.add(card);
      } else {
        if (currentGroup.length >= 2) {
          groups.add(List.from(currentGroup));
        }
        currentGroup = [];
      }
    }
    if (currentGroup.length >= 2) {
      groups.add(currentGroup);
    }

    return groups;
  }
}
