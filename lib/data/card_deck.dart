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
    // Don't reset _idCounter — ensures unique IDs across rounds
    return [
      ..._pronouns(),
      ..._articles(),
      ..._nouns(),
      ..._verbs(),
      ..._adjectives(),
      ..._adverbs(),
      ..._prepositions(),
      ..._conjunctions(),
      ..._specialCards(),
    ];
  }

  // === PRONOUNS (8 cards) ===
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
        WordCard(
          id: _nextId(), word: 'it', pos: PartOfSpeech.pronoun,
          person: 3, number: 'singular',
          meanings: {'ko': '그것', 'ja': 'それ', 'en': 'it'},
        ),
        WordCard(
          id: _nextId(), word: 'you', pos: PartOfSpeech.pronoun,
          person: 2, number: 'plural',
          meanings: {'ko': '너희', 'ja': 'あなたたち', 'en': 'you'},
        ),
      ];

  // === ARTICLES (7 cards) ===
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
        WordCard(
          id: _nextId(), word: 'the', pos: PartOfSpeech.article,
          meanings: {'ko': '그', 'ja': 'その', 'en': 'the'},
        ),
      ];

  // === NOUNS (30 cards) ===
  static List<WordCard> _nouns() => [
        // Animals
        WordCard(
          id: _nextId(), word: 'cat', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '고양이', 'ja': '猫', 'en': 'cat'},
        ),
        WordCard(
          id: _nextId(), word: 'cats', pos: PartOfSpeech.noun,
          person: 3, number: 'plural', countable: true, vowelStart: false,
          meanings: {'ko': '고양이들', 'ja': '猫たち', 'en': 'cats'},
        ),
        WordCard(
          id: _nextId(), word: 'dog', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '개', 'ja': '犬', 'en': 'dog'},
        ),
        WordCard(
          id: _nextId(), word: 'dogs', pos: PartOfSpeech.noun,
          person: 3, number: 'plural', countable: true, vowelStart: false,
          meanings: {'ko': '개들', 'ja': '犬たち', 'en': 'dogs'},
        ),
        WordCard(
          id: _nextId(), word: 'bird', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '새', 'ja': '鳥', 'en': 'bird'},
        ),
        WordCard(
          id: _nextId(), word: 'fish', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '물고기', 'ja': '魚', 'en': 'fish'},
        ),
        WordCard(
          id: _nextId(), word: 'rabbit', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '토끼', 'ja': 'うさぎ', 'en': 'rabbit'},
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
        WordCard(
          id: _nextId(), word: 'egg', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: true,
          meanings: {'ko': '달걀', 'ja': '卵', 'en': 'egg'},
        ),
        WordCard(
          id: _nextId(), word: 'milk', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: false, vowelStart: false,
          meanings: {'ko': '우유', 'ja': '牛乳', 'en': 'milk'},
        ),
        WordCard(
          id: _nextId(), word: 'rice', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: false, vowelStart: false,
          meanings: {'ko': '밥', 'ja': 'ご飯', 'en': 'rice'},
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
        WordCard(
          id: _nextId(), word: 'car', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '자동차', 'ja': '車', 'en': 'car'},
        ),
        WordCard(
          id: _nextId(), word: 'hat', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '모자', 'ja': '帽子', 'en': 'hat'},
        ),
        WordCard(
          id: _nextId(), word: 'house', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '집', 'ja': '家', 'en': 'house'},
        ),
        WordCard(
          id: _nextId(), word: 'star', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '별', 'ja': '星', 'en': 'star'},
        ),
        WordCard(
          id: _nextId(), word: 'stars', pos: PartOfSpeech.noun,
          person: 3, number: 'plural', countable: true, vowelStart: false,
          meanings: {'ko': '별들', 'ja': '星たち', 'en': 'stars'},
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
        WordCard(
          id: _nextId(), word: 'boy', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '소년', 'ja': '男の子', 'en': 'boy'},
        ),
        WordCard(
          id: _nextId(), word: 'girl', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '소녀', 'ja': '女の子', 'en': 'girl'},
        ),
        WordCard(
          id: _nextId(), word: 'teacher', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '선생님', 'ja': '先生', 'en': 'teacher'},
        ),
        WordCard(
          id: _nextId(), word: 'baby', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '아기', 'ja': '赤ちゃん', 'en': 'baby'},
        ),
        // Places / Nature
        WordCard(
          id: _nextId(), word: 'tree', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '나무', 'ja': '木', 'en': 'tree'},
        ),
        WordCard(
          id: _nextId(), word: 'flower', pos: PartOfSpeech.noun,
          person: 3, number: 'singular', countable: true, vowelStart: false,
          meanings: {'ko': '꽃', 'ja': '花', 'en': 'flower'},
        ),
      ];

  // === VERBS (24 cards) ===
  static List<WordCard> _verbs() => [
        // like / likes
        WordCard(
          id: _nextId(), word: 'like', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '좋아하다', 'ja': '好き', 'en': 'like'},
        ),
        WordCard(
          id: _nextId(), word: 'likes', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
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
        // want / wants
        WordCard(
          id: _nextId(), word: 'want', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '원하다', 'ja': '欲しい', 'en': 'want'},
        ),
        WordCard(
          id: _nextId(), word: 'wants', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '원하다', 'ja': '欲しい', 'en': 'wants'},
        ),
        // see / sees
        WordCard(
          id: _nextId(), word: 'see', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '보다', 'ja': '見る', 'en': 'see'},
        ),
        WordCard(
          id: _nextId(), word: 'sees', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '보다', 'ja': '見る', 'en': 'sees'},
        ),
        // make / makes
        WordCard(
          id: _nextId(), word: 'make', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '만들다', 'ja': '作る', 'en': 'make'},
        ),
        WordCard(
          id: _nextId(), word: 'makes', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '만들다', 'ja': '作る', 'en': 'makes'},
        ),
        // play / plays
        WordCard(
          id: _nextId(), word: 'play', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '놀다', 'ja': '遊ぶ', 'en': 'play'},
        ),
        WordCard(
          id: _nextId(), word: 'plays', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '놀다', 'ja': '遊ぶ', 'en': 'plays'},
        ),
        // is / are / am (linking verbs)
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
        // love / loves
        WordCard(
          id: _nextId(), word: 'love', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '사랑하다', 'ja': '愛する', 'en': 'love'},
        ),
        WordCard(
          id: _nextId(), word: 'loves', pos: PartOfSpeech.verb,
          person: 3, number: 'singular',
          meanings: {'ko': '사랑하다', 'ja': '愛する', 'en': 'loves'},
        ),
        // need / needs
        WordCard(
          id: _nextId(), word: 'need', pos: PartOfSpeech.verb,
          person: 1, number: 'plural',
          meanings: {'ko': '필요하다', 'ja': '必要', 'en': 'need'},
        ),
      ];

  // === ADJECTIVES (14 cards) ===
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
          id: _nextId(), word: 'green', pos: PartOfSpeech.adjective,
          adjOrder: 5,
          meanings: {'ko': '초록', 'ja': '緑', 'en': 'green'},
        ),
        WordCard(
          id: _nextId(), word: 'happy', pos: PartOfSpeech.adjective,
          adjOrder: 1, // opinion
          meanings: {'ko': '행복한', 'ja': '幸せな', 'en': 'happy'},
        ),
        WordCard(
          id: _nextId(), word: 'sad', pos: PartOfSpeech.adjective,
          adjOrder: 1,
          meanings: {'ko': '슬픈', 'ja': '悲しい', 'en': 'sad'},
        ),
        WordCard(
          id: _nextId(), word: 'fast', pos: PartOfSpeech.adjective,
          adjOrder: 3, // quality
          meanings: {'ko': '빠른', 'ja': '速い', 'en': 'fast'},
        ),
        WordCard(
          id: _nextId(), word: 'slow', pos: PartOfSpeech.adjective,
          adjOrder: 3,
          meanings: {'ko': '느린', 'ja': '遅い', 'en': 'slow'},
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
        WordCard(
          id: _nextId(), word: 'new', pos: PartOfSpeech.adjective,
          adjOrder: 4,
          meanings: {'ko': '새로운', 'ja': '新しい', 'en': 'new'},
        ),
        WordCard(
          id: _nextId(), word: 'good', pos: PartOfSpeech.adjective,
          adjOrder: 1,
          meanings: {'ko': '좋은', 'ja': '良い', 'en': 'good'},
        ),
        WordCard(
          id: _nextId(), word: 'bad', pos: PartOfSpeech.adjective,
          adjOrder: 1,
          meanings: {'ko': '나쁜', 'ja': '悪い', 'en': 'bad'},
        ),
      ];

  // === ADVERBS (4 cards) ===
  static List<WordCard> _adverbs() => [
        WordCard(
          id: _nextId(), word: 'very', pos: PartOfSpeech.adverb,
          meanings: {'ko': '매우', 'ja': 'とても', 'en': 'very'},
        ),
        WordCard(
          id: _nextId(), word: 'really', pos: PartOfSpeech.adverb,
          meanings: {'ko': '정말', 'ja': '本当に', 'en': 'really'},
        ),
        WordCard(
          id: _nextId(), word: 'always', pos: PartOfSpeech.adverb,
          meanings: {'ko': '항상', 'ja': 'いつも', 'en': 'always'},
        ),
        WordCard(
          id: _nextId(), word: 'never', pos: PartOfSpeech.adverb,
          meanings: {'ko': '절대', 'ja': '決して', 'en': 'never'},
        ),
      ];

  // === PREPOSITIONS (4 cards) ===
  static List<WordCard> _prepositions() => [
        WordCard(
          id: _nextId(), word: 'in', pos: PartOfSpeech.preposition,
          meanings: {'ko': '~안에', 'ja': '~の中に', 'en': 'in'},
        ),
        WordCard(
          id: _nextId(), word: 'on', pos: PartOfSpeech.preposition,
          meanings: {'ko': '~위에', 'ja': '~の上に', 'en': 'on'},
        ),
        WordCard(
          id: _nextId(), word: 'with', pos: PartOfSpeech.preposition,
          meanings: {'ko': '~와 함께', 'ja': '~と一緒に', 'en': 'with'},
        ),
        WordCard(
          id: _nextId(), word: 'for', pos: PartOfSpeech.preposition,
          meanings: {'ko': '~을 위해', 'ja': '~のために', 'en': 'for'},
        ),
      ];

  // === CONJUNCTIONS (3 cards) ===
  static List<WordCard> _conjunctions() => [
        WordCard(
          id: _nextId(), word: 'and', pos: PartOfSpeech.conjunction,
          meanings: {'ko': '그리고', 'ja': 'そして', 'en': 'and'},
        ),
        WordCard(
          id: _nextId(), word: 'but', pos: PartOfSpeech.conjunction,
          meanings: {'ko': '하지만', 'ja': 'しかし', 'en': 'but'},
        ),
        WordCard(
          id: _nextId(), word: 'or', pos: PartOfSpeech.conjunction,
          meanings: {'ko': '또는', 'ja': 'または', 'en': 'or'},
        ),
      ];

  // === SPECIAL CARDS (12 cards) ===
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
        WordCard.special(_nextId(), CardType.joker),
        WordCard.special(_nextId(), CardType.joker),
        WordCard.special(_nextId(), CardType.joker),
      ];
}
