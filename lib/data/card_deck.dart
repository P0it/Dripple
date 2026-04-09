import '../models/word_card.dart';

/// Curated card deck for Dripple.
/// Cards are designed as semantically compatible groups to prevent
/// nonsensical sentences (e.g., "The chair eats a book").
class CardDeck {
  static int _idCounter = 0;
  static String _nextId() => 'card_${_idCounter++}';

  /// Reset ID counter (for testing)
  static void resetIds() => _idCounter = 0;

  /// Generate a full deck of cards
  static List<WordCard> generateDeck() {
    _idCounter = 0;
    return [
      ..._pronouns(),
      ..._articles(),
      ..._nouns(),
      ..._verbs(),
      ..._adjectives(),
      ..._adverbs(),
      ..._specialCards(),
    ];
  }

  // === PRONOUNS ===
  static List<WordCard> _pronouns() => [
        WordCard(
          id: _nextId(), word: 'I', pos: PartOfSpeech.pronoun,
          person: 1, number: 'singular',
          meanings: {'ko': '나', 'ja': '私', 'en': 'I'},
        ),
        WordCard(
          id: _nextId(), word: 'you', pos: PartOfSpeech.pronoun,
          person: 2, number: 'singular',
          meanings: {'ko': '너', 'ja': 'あなた', 'en': 'you'},
        ),
        WordCard(
          id: _nextId(), word: 'he', pos: PartOfSpeech.pronoun,
          person: 3, number: 'singular',
          meanings: {'ko': '그', 'ja': '彼', 'en': 'he'},
        ),
        WordCard(
          id: _nextId(), word: 'she', pos: PartOfSpeech.pronoun,
          person: 3, number: 'singular',
          meanings: {'ko': '그녀', 'ja': '彼女', 'en': 'she'},
        ),
        WordCard(
          id: _nextId(), word: 'we', pos: PartOfSpeech.pronoun,
          person: 1, number: 'plural',
          meanings: {'ko': '우리', 'ja': '私たち', 'en': 'we'},
        ),
        WordCard(
          id: _nextId(), word: 'they', pos: PartOfSpeech.pronoun,
          person: 3, number: 'plural',
          meanings: {'ko': '그들', 'ja': '彼ら', 'en': 'they'},
        ),
      ];

  // === ARTICLES ===
  static List<WordCard> _articles() => [
        WordCard(
          id: _nextId(), word: 'a', pos: PartOfSpeech.article,
          vowelStart: false,
          meanings: {'ko': '하나의', 'ja': 'ある', 'en': 'a'},
        ),
        WordCard(
          id: _nextId(), word: 'a', pos: PartOfSpeech.article,
          vowelStart: false,
          meanings: {'ko': '하나의', 'ja': 'ある', 'en': 'a'},
        ),
        WordCard(
          id: _nextId(), word: 'an', pos: PartOfSpeech.article,
          vowelStart: true,
          meanings: {'ko': '하나의', 'ja': 'ある', 'en': 'an'},
        ),
        WordCard(
          id: _nextId(), word: 'the', pos: PartOfSpeech.article,
          meanings: {'ko': '그', 'ja': 'その', 'en': 'the'},
        ),
        WordCard(
          id: _nextId(), word: 'the', pos: PartOfSpeech.article,
          meanings: {'ko': '그', 'ja': 'その', 'en': 'the'},
        ),
      ];

  // === NOUNS ===
  static List<WordCard> _nouns() => [
        // Animals (singular)
        WordCard(
          id: _nextId(), word: 'cat', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '고양이', 'ja': '猫', 'en': 'cat'},
        ),
        WordCard(
          id: _nextId(), word: 'dog', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '개', 'ja': '犬', 'en': 'dog'},
        ),
        WordCard(
          id: _nextId(), word: 'bird', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '새', 'ja': '鳥', 'en': 'bird'},
        ),
        // Animals (plural)
        WordCard(
          id: _nextId(), word: 'cats', pos: PartOfSpeech.noun,
          person: 3, number: 'plural', countable: true, vowelStart: false,
          meanings: {'ko': '고양이들', 'ja': '猫たち', 'en': 'cats'},
        ),
        WordCard(
          id: _nextId(), word: 'dogs', pos: PartOfSpeech.noun,
          person: 3, number: 'plural', countable: true, vowelStart: false,
          meanings: {'ko': '개들', 'ja': '犬たち', 'en': 'dogs'},
        ),
        // Food
        WordCard(
          id: _nextId(), word: 'apple', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: true,
          meanings: {'ko': '사과', 'ja': 'りんご', 'en': 'apple'},
        ),
        WordCard(
          id: _nextId(), word: 'apples', pos: PartOfSpeech.noun,
          person: 3, number: 'plural', countable: true, vowelStart: true,
          meanings: {'ko': '사과들', 'ja': 'りんご', 'en': 'apples'},
        ),
        WordCard(
          id: _nextId(), word: 'cake', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '케이크', 'ja': 'ケーキ', 'en': 'cake'},
        ),
        WordCard(
          id: _nextId(), word: 'water', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: false, vowelStart: false,
          meanings: {'ko': '물', 'ja': '水', 'en': 'water'},
        ),
        // Objects
        WordCard(
          id: _nextId(), word: 'ball', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '공', 'ja': 'ボール', 'en': 'ball'},
        ),
        WordCard(
          id: _nextId(), word: 'book', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '책', 'ja': '本', 'en': 'book'},
        ),
        WordCard(
          id: _nextId(), word: 'books', pos: PartOfSpeech.noun,
          person: 3, number: 'plural', countable: true, vowelStart: false,
          meanings: {'ko': '책들', 'ja': '本', 'en': 'books'},
        ),
        // People
        WordCard(
          id: _nextId(), word: 'friend', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '친구', 'ja': '友達', 'en': 'friend'},
        ),
        WordCard(
          id: _nextId(), word: 'friends', pos: PartOfSpeech.noun,
          person: 3, number: 'plural', countable: true, vowelStart: false,
          meanings: {'ko': '친구들', 'ja': '友達', 'en': 'friends'},
        ),
      ];

  // === VERBS ===
  static List<WordCard> _verbs() => [
        // like / likes
        WordCard(
          id: _nextId(), word: 'like', pos: PartOfSpeech.verb,
          person: 1, number: 'plural', // base form (I/you/we/they like)
          meanings: {'ko': '좋아하다', 'ja': '好き', 'en': 'like'},
        ),
        WordCard(
          id: _nextId(), word: 'likes', pos: PartOfSpeech.verb,
          person: 3, number: 'singular', // 3rd person singular (he/she likes)
          meanings: {'ko': '좋아하다', 'ja': '好き', 'en': 'likes'},
        ),
        // eat / eats
        WordCard(
          id: _nextId(), word: 'eat', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '먹다', 'ja': '食べる', 'en': 'eat'},
        ),
        WordCard(
          id: _nextId(), word: 'eats', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '먹다', 'ja': '食べる', 'en': 'eats'},
        ),
        // run / runs
        WordCard(
          id: _nextId(), word: 'run', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '달리다', 'ja': '走る', 'en': 'run'},
        ),
        WordCard(
          id: _nextId(), word: 'runs', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '달리다', 'ja': '走る', 'en': 'runs'},
        ),
        // have / has
        WordCard(
          id: _nextId(), word: 'have', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '가지다', 'ja': '持つ', 'en': 'have'},
        ),
        WordCard(
          id: _nextId(), word: 'has', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '가지다', 'ja': '持つ', 'en': 'has'},
        ),
        // read / reads
        WordCard(
          id: _nextId(), word: 'read', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '읽다', 'ja': '読む', 'en': 'read'},
        ),
        WordCard(
          id: _nextId(), word: 'reads', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '읽다', 'ja': '読む', 'en': 'reads'},
        ),
        // is / are (linking verbs)
        WordCard(
          id: _nextId(), word: 'is', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '~이다', 'ja': 'です', 'en': 'is'},
        ),
        WordCard(
          id: _nextId(), word: 'are', pos: PartOfSpeech.verb,
          person: 2, number: 'plural',
          meanings: {'ko': '~이다', 'ja': 'です', 'en': 'are'},
        ),
        WordCard(
          id: _nextId(), word: 'am', pos: PartOfSpeech.verb,
          person: 1, number: 'singular',
          meanings: {'ko': '~이다', 'ja': 'です', 'en': 'am'},
        ),
      ];

  // === ADJECTIVES ===
  static List<WordCard> _adjectives() => [
        WordCard(
          id: _nextId(), word: 'big', pos: PartOfSpeech.adjective,
          adjOrder: 2, // size
          meanings: {'ko': '큰', 'ja': '大きい', 'en': 'big'},
        ),
        WordCard(
          id: _nextId(), word: 'small', pos: PartOfSpeech.adjective,
          adjOrder: 2,
          meanings: {'ko': '작은', 'ja': '小さい', 'en': 'small'},
        ),
        WordCard(
          id: _nextId(), word: 'red', pos: PartOfSpeech.adjective,
          adjOrder: 5, // color
          meanings: {'ko': '빨간', 'ja': '赤い', 'en': 'red'},
        ),
        WordCard(
          id: _nextId(), word: 'blue', pos: PartOfSpeech.adjective,
          adjOrder: 5,
          meanings: {'ko': '파란', 'ja': '青い', 'en': 'blue'},
        ),
        WordCard(
          id: _nextId(), word: 'happy', pos: PartOfSpeech.adjective,
          adjOrder: 1, // opinion
          meanings: {'ko': '행복한', 'ja': '幸せな', 'en': 'happy'},
        ),
        WordCard(
          id: _nextId(), word: 'fast', pos: PartOfSpeech.adjective,
          adjOrder: 3, // quality
          meanings: {'ko': '빠른', 'ja': '速い', 'en': 'fast'},
        ),
        WordCard(
          id: _nextId(), word: 'cute', pos: PartOfSpeech.adjective,
          adjOrder: 1,
          meanings: {'ko': '귀여운', 'ja': 'かわいい', 'en': 'cute'},
        ),
        WordCard(
          id: _nextId(), word: 'old', pos: PartOfSpeech.adjective,
          adjOrder: 4, // age
          meanings: {'ko': '오래된', 'ja': '古い', 'en': 'old'},
        ),
      ];

  // === ADVERBS ===
  static List<WordCard> _adverbs() => [
        WordCard(
          id: _nextId(), word: 'very', pos: PartOfSpeech.adverb,
          meanings: {'ko': '매우', 'ja': 'とても', 'en': 'very'},
        ),
        WordCard(
          id: _nextId(), word: 'really', pos: PartOfSpeech.adverb,
          meanings: {'ko': '정말', 'ja': '本当に', 'en': 'really'},
        ),
      ];

  // === SPECIAL CARDS ===
  static List<WordCard> _specialCards() => [
        WordCard.special(_nextId(), CardType.skip),
        WordCard.special(_nextId(), CardType.skip),
        WordCard.special(_nextId(), CardType.skip),
        WordCard.special(_nextId(), CardType.skip),
        WordCard.special(_nextId(), CardType.steal),
        WordCard.special(_nextId(), CardType.steal),
        WordCard.special(_nextId(), CardType.steal),
        WordCard.special(_nextId(), CardType.undo),
        WordCard.special(_nextId(), CardType.undo),
        WordCard.special(_nextId(), CardType.undo),
        WordCard.special(_nextId(), CardType.wild),
        WordCard.special(_nextId(), CardType.wild),
      ];
}
