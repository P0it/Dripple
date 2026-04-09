import '../../../models/word_card.dart';
import '../grammar_engine.dart';

/// Validates article agreement: "a" + consonant start, "an" + vowel start.
class ArticleRule extends GrammarRule {
  @override
  List<ValidationError> validate(List<WordCard> sentence) {
    final errors = <ValidationError>[];

    for (int i = 0; i < sentence.length - 1; i++) {
      final card = sentence[i];
      // WILD cards have no pos/grammar metadata — skip them entirely.
      if (card.type == CardType.joker) continue;
      if (!card.isArticle) continue;

      // Find the next noun or adjective (skip adverbs like "very")
      final nextWord = _findNextRelevantWord(sentence, i + 1);
      if (nextWord == null) continue;

      if (card.word == 'a' && nextWord.vowelStart == true) {
        errors.add(ValidationError(
          code: 'article_a_vowel',
          message: 'Use "an" before words starting with a vowel sound: "${nextWord.word}"',
          localizedMessages: {
            'ko': '모음으로 시작하는 단어 "${nextWord.word}" 앞에는 "an"을 사용하세요',
            'ja': '母音で始まる単語「${nextWord.word}」の前には「an」を使います',
          },
        ));
      } else if (card.word == 'an' && nextWord.vowelStart == false) {
        errors.add(ValidationError(
          code: 'article_an_consonant',
          message: 'Use "a" before words starting with a consonant sound: "${nextWord.word}"',
          localizedMessages: {
            'ko': '자음으로 시작하는 단어 "${nextWord.word}" 앞에는 "a"를 사용하세요',
            'ja': '子音で始まる単語「${nextWord.word}」の前には「a」を使います',
          },
        ));
      }
    }

    return errors;
  }

  /// Find the next noun or adjective after the article (skipping adverbs and WILD cards)
  WordCard? _findNextRelevantWord(List<WordCard> sentence, int startIndex) {
    for (int i = startIndex; i < sentence.length; i++) {
      final card = sentence[i];
      // WILD cards have no pos — treat as transparent and keep scanning.
      if (card.type == CardType.joker) continue;
      if (card.isNoun || card.isAdjective) return card;
      if (card.pos != PartOfSpeech.adverb) break;
    }
    return null;
  }
}
