import 'package:equatable/equatable.dart';

enum CardType { word, jump, steal, joker }

enum PartOfSpeech {
  noun,
  verb,
  adjective,
  adverb,
  article,
  pronoun,
  preposition,
}

/// What a verb can take after it.
///
/// A single `transitive` flag is not enough: "read", "eat" and "play" work
/// both with and without an object, so a card carries the set of frames it
/// allows and the parser checks the complement against it.
enum VerbFrame {
  /// No complement — "I run".
  intransitive,

  /// A noun phrase object — "I read books".
  transitive,

  /// An adjective complement — "I am happy".
  linking,
}

/// Where an adverb belongs in the sentence.
///
/// English puts these in three different places, and a single "adverb" part
/// of speech would let "they read always" and "they slowly read" through.
enum AdverbKind {
  /// Before the verb — "they always read".
  frequency,

  /// After the verb and its object — "they read slowly".
  manner,

  /// Before an adjective — "we are very happy".
  degree,
}

/// Whether a noun names something that can act.
///
/// Lets the engine reject "the flower reads" — grammatical, but the kind of
/// sentence that teaches a child the wrong thing.
enum Animacy { animate, inanimate }

/// Montessori grammar symbol shapes. A child who cannot yet read the word
/// can still see the shape of the sentence.
enum PosShape {
  triangleLarge,   // noun
  triangleMedium,  // adjective
  triangleSmall,   // article
  trianglePronoun, // pronoun
  circle,          // verb
  circleSmall,     // adverb
  crescent,        // preposition
  none,            // special cards
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
  /// Verb cards only. Null means unconstrained, which keeps fixtures that
  /// predate valency data parsing.
  final Set<VerbFrame>? frames;

  /// Nouns and pronouns. Null means unconstrained.
  final Animacy? animacy;

  /// Adverb cards only. Null means the adverb may sit in any of the three
  /// positions, which keeps older fixtures parsing.
  final AdverbKind? adverbKind;

  /// Verb cards only. When true the subject must be [Animacy.animate], so
  /// "the star eats" fails while "the girl eats" passes.
  final bool requiresAnimateSubject;
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
    this.frames,
    this.animacy,
    this.adverbKind,
    this.requiresAnimateSubject = false,
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

  /// Whether the word begins with a vowel sound, for "a" versus "an".
  ///
  /// [vowelStart] is the authority when set, so exceptions like "hour" can be
  /// declared. Otherwise it is derived from the spelling — adjectives carry no
  /// explicit flag, and without this "an green friend" slipped through.
  bool get startsWithVowelSound {
    if (vowelStart != null) return vowelStart!;
    if (word.isEmpty) return false;
    return const {'a', 'e', 'i', 'o', 'u'}.contains(word[0].toLowerCase());
  }

  /// Whether this adverb may sit in [kind]'s position. An adverb with no
  /// kind is unconstrained.
  bool allowsAdverbKind(AdverbKind kind) =>
      adverbKind == null || adverbKind == kind;

  /// Whether this verb allows [frame]. A card with no valency data allows
  /// everything, so missing data never blocks a play.
  bool allowsFrame(VerbFrame frame) => frames == null || frames!.contains(frame);

  /// Whether this card can act as a subject (pronoun or noun)
  bool get canBeSubject => isPronoun || isNoun;

  /// Whether this card can stand in object position (after a verb or a
  /// preposition).
  ///
  /// The deck carries only subject pronouns, so "cats like I" must be
  /// rejected. Only the case-neutral pronouns may appear as objects.
  bool get canBeObject {
    if (type == CardType.joker) return true;
    if (isPronoun) return word == 'you' || word == 'it';
    return isNoun;
  }

  /// Montessori grammar symbol shape for this card's part of speech.
  PosShape get posShape {
    if (isSpecial) return PosShape.none;
    switch (pos) {
      case PartOfSpeech.noun:
        return PosShape.triangleLarge;
      case PartOfSpeech.adjective:
        return PosShape.triangleMedium;
      case PartOfSpeech.article:
        return PosShape.triangleSmall;
      case PartOfSpeech.pronoun:
        return PosShape.trianglePronoun;
      case PartOfSpeech.verb:
        return PosShape.circle;
      case PartOfSpeech.adverb:
        return PosShape.circleSmall;
      case PartOfSpeech.preposition:
        return PosShape.crescent;
      default:
        return PosShape.none;
    }
  }

  /// ARGB colour for this card's part of speech (Montessori convention).
  int get posColor {
    if (isSpecial) return 0xFF8B5CF6;
    switch (pos) {
      case PartOfSpeech.noun:
        return 0xFF1F2937; // black
      case PartOfSpeech.adjective:
        return 0xFF1E3A8A; // navy
      case PartOfSpeech.article:
        return 0xFF7DD3FC; // light blue
      case PartOfSpeech.pronoun:
        return 0xFF7C3AED; // purple
      case PartOfSpeech.verb:
        return 0xFFDC2626; // red
      case PartOfSpeech.adverb:
        return 0xFFF97316; // orange
      case PartOfSpeech.preposition:
        return 0xFF16A34A; // green
      default:
        return 0xFF6B7280;
    }
  }

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
  List<Object?> get props =>
      [id, word, type, pos, person, number, frames, animacy];

  @override
  String toString() => 'WordCard($word, ${type == CardType.word ? pos?.name : type.name})';
}
