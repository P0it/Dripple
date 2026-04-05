import 'package:equatable/equatable.dart';

enum CardType { word, skip, steal, undo, wild }

enum PartOfSpeech {
  noun,
  verb,
  adjective,
  adverb,
  article,
  pronoun,
  preposition,
  conjunction,
}

class WordCard extends Equatable {
  final String id;
  final String word;
  final CardType type;
  final PartOfSpeech? pos;
  final int? person; // 1, 2, 3
  final String? number; // "singular", "plural"
  final bool? countable;
  final bool? vowelStart;
  final int? adjOrder; // 1-8 for adjective ordering
  final Map<String, String> meanings; // {"ko": "...", "ja": "...", "en": "..."}

  const WordCard({
    required this.id,
    required this.word,
    this.type = CardType.word,
    this.pos,
    this.person,
    this.number,
    this.countable,
    this.vowelStart,
    this.adjOrder,
    this.meanings = const {},
  });

  bool get isSpecial => type != CardType.word;
  bool get isNoun => pos == PartOfSpeech.noun;
  bool get isVerb => pos == PartOfSpeech.verb;
  bool get isAdjective => pos == PartOfSpeech.adjective;
  bool get isArticle => pos == PartOfSpeech.article;
  bool get isPronoun => pos == PartOfSpeech.pronoun;
  bool get isSingular => number == 'singular';
  bool get isPlural => number == 'plural';
  bool get isThirdPersonSingular => person == 3 && isSingular;

  /// Whether this card can act as a subject (pronoun or noun)
  bool get canBeSubject => isPronoun || isNoun;

  /// Create a special card
  factory WordCard.special(String id, CardType type) {
    assert(type != CardType.word);
    return WordCard(
      id: id,
      word: type.name.toUpperCase(),
      type: type,
    );
  }

  @override
  List<Object?> get props => [id, word, type, pos, person, number];

  @override
  String toString() => 'WordCard($word, ${type == CardType.word ? pos?.name : type.name})';
}
