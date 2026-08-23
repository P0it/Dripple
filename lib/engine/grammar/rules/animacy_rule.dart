import '../../../models/word_card.dart';
import '../grammar_engine.dart';

/// Rejects sentences whose subject cannot perform the action.
///
/// The parser only checks shape, so "the flower reads" and "a star eats" pass
/// it happily. For a child learning English those sentences are worse than
/// useless, so verbs that need an actor declare it and this rule enforces it.
class AnimacyRule extends GrammarRule {
  @override
  List<ValidationError> validate(List<WordCard> sentence) {
    final verb = _findVerb(sentence);
    if (verb == null || !verb.requiresAnimateSubject) return const [];

    final subject = _findSubject(sentence);
    if (subject == null || subject.animacy != Animacy.inanimate) {
      return const [];
    }

    return [
      ValidationError(
        code: 'animacy',
        message: '"${subject.word}" cannot "${verb.word}"',
        localizedMessages: {
          'ko': '"${subject.word}"는 "${verb.word}" 할 수 없어요',
          'ja': '「${subject.word}」は「${verb.word}」できません',
        },
      ),
    ];
  }

  /// The head of the subject noun phrase: the first pronoun or noun that
  /// appears before the verb.
  WordCard? _findSubject(List<WordCard> sentence) {
    for (final card in sentence) {
      if (card.type == CardType.joker) continue;
      if (card.isVerb) return null; // verb came first — structure rule's job
      if (card.isPronoun || card.isNoun) return card;
    }
    return null;
  }

  WordCard? _findVerb(List<WordCard> sentence) {
    for (final card in sentence) {
      if (card.type == CardType.joker) continue;
      if (card.isVerb) return card;
    }
    return null;
  }
}
