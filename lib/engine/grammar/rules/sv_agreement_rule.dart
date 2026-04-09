import '../../../models/word_card.dart';
import '../grammar_engine.dart';

/// Validates subject-verb agreement.
/// 3rd person singular subjects require singular verb forms (he likes, she runs).
/// Other subjects require base verb forms (I like, they run).
class SubjectVerbAgreementRule extends GrammarRule {
  // Special be-verb mapping: subject → required verb
  static const _beVerbMap = {
    // person_number → allowed be-verb
    '1_singular': 'am',
    '2_singular': 'are',
    '3_singular': 'is',
    '1_plural': 'are',
    '2_plural': 'are',
    '3_plural': 'are',
  };

  @override
  List<ValidationError> validate(List<WordCard> sentence) {
    final errors = <ValidationError>[];

    // Find subject and verb
    final subject = _findSubject(sentence);
    final verb = _findVerb(sentence);

    if (subject == null || verb == null) return errors;

    final subjectKey = '${subject.person}_${subject.number}';

    // Handle be-verbs (is/am/are)
    if (_isBeVerb(verb.word)) {
      final expectedBe = _beVerbMap[subjectKey];
      if (expectedBe != null && verb.word != expectedBe) {
        errors.add(ValidationError(
          code: 'sv_agreement_be',
          message: '"${subject.word}" should use "$expectedBe" instead of "${verb.word}"',
          localizedMessages: {
            'ko': '"${subject.word}"는 "${verb.word}" 대신 "$expectedBe"를 사용해야 합니다',
            'ja': '「${subject.word}」は「${verb.word}」ではなく「$expectedBe」を使います',
          },
        ));
      }
      return errors;
    }

    // Handle regular verbs
    final needsSingularVerb =
        subject.person == 3 && subject.number == 'singular';
    final verbIsSingularForm =
        verb.person == 3 && verb.number == 'singular';

    if (needsSingularVerb && !verbIsSingularForm) {
      errors.add(ValidationError(
        code: 'sv_agreement',
        message: '"${subject.word}" (3rd person singular) requires singular verb form, not "${verb.word}"',
        localizedMessages: {
          'ko': '"${subject.word}" (3인칭 단수)에는 단수 동사형이 필요합니다. "${verb.word}"는 사용할 수 없습니다',
          'ja': '「${subject.word}」(三人称単数)には単数動詞形が必要です',
        },
      ));
    } else if (!needsSingularVerb && verbIsSingularForm) {
      errors.add(ValidationError(
        code: 'sv_agreement',
        message: '"${subject.word}" should not use singular verb form "${verb.word}"',
        localizedMessages: {
          'ko': '"${subject.word}"는 단수 동사형 "${verb.word}"를 사용할 수 없습니다',
          'ja': '「${subject.word}」は単数動詞形「${verb.word}」を使えません',
        },
      ));
    }

    return errors;
  }

  bool _isBeVerb(String word) => word == 'is' || word == 'am' || word == 'are';

  WordCard? _findSubject(List<WordCard> sentence) {
    // Subject is typically the first pronoun or [article + noun]
    for (int i = 0; i < sentence.length; i++) {
      final card = sentence[i];
      if (card.isPronoun) return card;
      if (card.isArticle) {
        // Look for the noun after this article
        for (int j = i + 1; j < sentence.length; j++) {
          if (sentence[j].isNoun) return sentence[j];
          if (!sentence[j].isAdjective && sentence[j].pos != PartOfSpeech.adverb) break;
        }
      }
      if (card.isNoun) return card;
    }
    return null;
  }

  WordCard? _findVerb(List<WordCard> sentence) {
    for (final card in sentence) {
      if (card.isVerb) return card;
    }
    return null;
  }
}
