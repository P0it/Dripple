import '../../../models/word_card.dart';
import '../grammar_engine.dart';

/// Validates article-noun number agreement.
/// "a"/"an" can only precede singular countable nouns.
/// "the" can precede both singular and plural.
class NumberRule extends GrammarRule {
  @override
  List<ValidationError> validate(List<WordCard> sentence) {
    final errors = <ValidationError>[];

    for (int i = 0; i < sentence.length - 1; i++) {
      final card = sentence[i];
      // WILD cards have no pos/grammar metadata — skip them entirely.
      if (card.type == CardType.joker) continue;
      if (!card.isArticle) continue;

      // Find the noun this article refers to
      final noun = _findNoun(sentence, i + 1);
      if (noun == null) continue;

      // "a"/"an" + plural noun is invalid
      if ((card.word == 'a' || card.word == 'an') && noun.isPlural) {
        errors.add(ValidationError(
          code: 'article_plural',
          message: '"${card.word}" cannot be used with plural noun "${noun.word}"',
          localizedMessages: {
            'ko': '"${card.word}"는 복수 명사 "${noun.word}"와 함께 사용할 수 없습니다',
            'ja': '「${card.word}」は複数名詞「${noun.word}」と一緒に使えません',
          },
        ));
      }

      // "a"/"an" + uncountable noun is invalid
      if ((card.word == 'a' || card.word == 'an') && noun.countable == false) {
        errors.add(ValidationError(
          code: 'article_uncountable',
          message: '"${card.word}" cannot be used with uncountable noun "${noun.word}"',
          localizedMessages: {
            'ko': '"${card.word}"는 불가산 명사 "${noun.word}"와 함께 사용할 수 없습니다',
            'ja': '「${card.word}」は不可算名詞「${noun.word}」と一緒に使えません',
          },
        ));
      }
    }

    return errors;
  }

  /// Find the first noun after the article (may have adjectives in between, skips WILD cards)
  WordCard? _findNoun(List<WordCard> sentence, int startIndex) {
    for (int i = startIndex; i < sentence.length; i++) {
      // WILD cards have no pos — treat as transparent and keep scanning.
      if (sentence[i].type == CardType.joker) continue;
      if (sentence[i].isNoun) return sentence[i];
      // Only skip adjectives and adverbs between article and noun
      if (!sentence[i].isAdjective && sentence[i].pos != PartOfSpeech.adverb) {
        break;
      }
    }
    return null;
  }
}
