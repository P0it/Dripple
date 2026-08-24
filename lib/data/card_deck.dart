import '../models/word_card.dart';

/// Curated card deck for Dripple.
/// Cards are designed as semantically compatible groups to prevent
/// nonsensical sentences (e.g., "The chair eats a book").
class CardDeck {
  int _idCounter = 0;
  String _nextId() => 'card_${_idCounter++}';

  /// Generate a full deck of cards
  List<WordCard> generate() {
    return [
      ..._pronouns(),
      ..._articles(),
      ..._nouns(),
      ..._verbs(),
      ..._adjectives(),
      ..._adverbs(),
      ..._prepositions(),
      ..._specialCards(),
    ];
  }

  /// Deal [playerCount] hands of [handSize] cards, guaranteeing every hand
  /// contains at least one verb and at least one subject-capable card.
  ///
  /// Without this an opening hand can be unplayable, which to a 6-10 year
  /// old reads as the game being broken. Mirrors Scrabble's "redraw if you
  /// have no vowels" tournament rule.
  ///
  /// Returns the hands and the remaining deck.
  static (List<List<WordCard>>, List<WordCard>) dealGuaranteedHands({
    required List<WordCard> deck,
    required int playerCount,
    required int handSize,
  }) {
    final pool = List<WordCard>.from(deck);
    final hands = <List<WordCard>>[];

    WordCard? takeWhere(bool Function(WordCard) test) {
      final idx = pool.indexWhere(test);
      if (idx < 0) return null;
      return pool.removeAt(idx);
    }

    for (int p = 0; p < playerCount; p++) {
      final hand = <WordCard>[];

      final verb = takeWhere((c) => c.isVerb);
      if (verb != null) hand.add(verb);

      final subject = takeWhere((c) => c.canBeSubject);
      if (subject != null) hand.add(subject);

      while (hand.length < handSize && pool.isNotEmpty) {
        hand.add(pool.removeLast());
      }

      hand.shuffle();
      hands.add(hand);
    }

    return (hands, pool);
  }

  /// Where each adverb belongs. English places these differently, so the
  /// parser needs to know which is which.
  static const Map<String, AdverbKind> _adverbKinds = {
    'very': AdverbKind.degree,
    'really': AdverbKind.degree,
    'always': AdverbKind.frequency,
    'never': AdverbKind.frequency,
    'fast': AdverbKind.manner,
    'slowly': AdverbKind.manner,
  };

  /// What each verb can take after it.
  ///
  /// Keyed by surface form because the deck carries both "eat" and "eats".
  /// A verb missing from this table would parse unconstrained, so
  /// card_deck_test asserts every verb card ends up with frames.
  static const Map<String, Set<VerbFrame>> _verbFrames = {
    // Transitive only — these need something to act on.
    'like': {VerbFrame.transitive},
    'likes': {VerbFrame.transitive},
    'have': {VerbFrame.transitive},
    'has': {VerbFrame.transitive},
    'want': {VerbFrame.transitive},
    'wants': {VerbFrame.transitive},
    'make': {VerbFrame.transitive},
    'makes': {VerbFrame.transitive},
    'need': {VerbFrame.transitive},
    'needs': {VerbFrame.transitive},
    'love': {VerbFrame.transitive},
    'loves': {VerbFrame.transitive},

    // Intransitive only — "apples run a friend" must not parse.
    'run': {VerbFrame.intransitive},
    'runs': {VerbFrame.intransitive},
    'go': {VerbFrame.intransitive},

    // Both — "I read" and "I read books" are each fine.
    'eat': {VerbFrame.intransitive, VerbFrame.transitive},
    'eats': {VerbFrame.intransitive, VerbFrame.transitive},
    'read': {VerbFrame.intransitive, VerbFrame.transitive},
    'reads': {VerbFrame.intransitive, VerbFrame.transitive},
    'see': {VerbFrame.intransitive, VerbFrame.transitive},
    'sees': {VerbFrame.intransitive, VerbFrame.transitive},
    'play': {VerbFrame.intransitive, VerbFrame.transitive},
    'plays': {VerbFrame.intransitive, VerbFrame.transitive},

    // Be-verbs take an adjective ("I am happy") or a noun ("I am a boy").
    'is': {VerbFrame.linking, VerbFrame.transitive},
    'am': {VerbFrame.linking, VerbFrame.transitive},
    'are': {VerbFrame.linking, VerbFrame.transitive},
  };

  // === PRONOUNS (12 cards) ===
  List<WordCard> _pronouns() => [
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
          id: _nextId(), word: 'we', pos: PartOfSpeech.pronoun,
          person: 1, number: 'plural',
          meanings: {'ko': '우리', 'ja': '私たち', 'en': 'we'},
        ),
      ];

  // === ARTICLES (10 cards) ===
  List<WordCard> _articles() => [
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
      ];

  // === NOUNS (26 cards) ===
  List<WordCard> _nouns() => [
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
  List<WordCard> _verbs() => [
        // like / likes
        WordCard(
          id: _nextId(), word: 'like', pos: PartOfSpeech.verb,
          frames: _verbFrames['like'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '좋아하다', 'ja': '好き', 'en': 'like'},
        ),
        WordCard(
          id: _nextId(), word: 'likes', pos: PartOfSpeech.verb,
          frames: _verbFrames['likes'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '좋아하다', 'ja': '好き', 'en': 'likes'},
        ),
        // eat / eats
        WordCard(
          id: _nextId(), word: 'eat', pos: PartOfSpeech.verb,
          frames: _verbFrames['eat'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '먹다', 'ja': '食べる', 'en': 'eat'},
        ),
        WordCard(
          id: _nextId(), word: 'eats', pos: PartOfSpeech.verb,
          frames: _verbFrames['eats'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '먹다', 'ja': '食べる', 'en': 'eats'},
        ),
        // run / runs
        WordCard(
          id: _nextId(), word: 'run', pos: PartOfSpeech.verb,
          frames: _verbFrames['run'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '달리다', 'ja': '走る', 'en': 'run'},
        ),
        WordCard(
          id: _nextId(), word: 'runs', pos: PartOfSpeech.verb,
          frames: _verbFrames['runs'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '달리다', 'ja': '走る', 'en': 'runs'},
        ),
        // have / has
        WordCard(
          id: _nextId(), word: 'have', pos: PartOfSpeech.verb,
          frames: _verbFrames['have'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '가지다', 'ja': '持つ', 'en': 'have'},
        ),
        WordCard(
          id: _nextId(), word: 'has', pos: PartOfSpeech.verb,
          frames: _verbFrames['has'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '가지다', 'ja': '持つ', 'en': 'has'},
        ),
        // read / reads
        WordCard(
          id: _nextId(), word: 'read', pos: PartOfSpeech.verb,
          frames: _verbFrames['read'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '읽다', 'ja': '読む', 'en': 'read'},
        ),
        WordCard(
          id: _nextId(), word: 'reads', pos: PartOfSpeech.verb,
          frames: _verbFrames['reads'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '읽다', 'ja': '読む', 'en': 'reads'},
        ),
        // want / wants
        WordCard(
          id: _nextId(), word: 'want', pos: PartOfSpeech.verb,
          frames: _verbFrames['want'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '원하다', 'ja': '欲しい', 'en': 'want'},
        ),
        WordCard(
          id: _nextId(), word: 'wants', pos: PartOfSpeech.verb,
          frames: _verbFrames['wants'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '원하다', 'ja': '欲しい', 'en': 'wants'},
        ),
        // see / sees
        WordCard(
          id: _nextId(), word: 'see', pos: PartOfSpeech.verb,
          frames: _verbFrames['see'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '보다', 'ja': '見る', 'en': 'see'},
        ),
        WordCard(
          id: _nextId(), word: 'sees', pos: PartOfSpeech.verb,
          frames: _verbFrames['sees'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '보다', 'ja': '見る', 'en': 'sees'},
        ),
        // make / makes
        WordCard(
          id: _nextId(), word: 'make', pos: PartOfSpeech.verb,
          frames: _verbFrames['make'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '만들다', 'ja': '作る', 'en': 'make'},
        ),
        WordCard(
          id: _nextId(), word: 'makes', pos: PartOfSpeech.verb,
          frames: _verbFrames['makes'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '만들다', 'ja': '作る', 'en': 'makes'},
        ),
        // play / plays
        WordCard(
          id: _nextId(), word: 'play', pos: PartOfSpeech.verb,
          frames: _verbFrames['play'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '놀다', 'ja': '遊ぶ', 'en': 'play'},
        ),
        WordCard(
          id: _nextId(), word: 'plays', pos: PartOfSpeech.verb,
          frames: _verbFrames['plays'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '놀다', 'ja': '遊ぶ', 'en': 'plays'},
        ),
        // is / are / am (linking verbs)
        WordCard(
          id: _nextId(), word: 'is', pos: PartOfSpeech.verb,
          frames: _verbFrames['is'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '~이다', 'ja': 'です', 'en': 'is'},
        ),
        WordCard(
          id: _nextId(), word: 'are', pos: PartOfSpeech.verb,
          frames: _verbFrames['are'],
         
          person: 2, number: 'plural',
          meanings: {'ko': '~이다', 'ja': 'です', 'en': 'are'},
        ),
        WordCard(
          id: _nextId(), word: 'am', pos: PartOfSpeech.verb,
          frames: _verbFrames['am'],
         
          person: 1, number: 'singular',
          meanings: {'ko': '~이다', 'ja': 'です', 'en': 'am'},
        ),
        // love / loves
        WordCard(
          id: _nextId(), word: 'love', pos: PartOfSpeech.verb,
          frames: _verbFrames['love'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '사랑하다', 'ja': '愛する', 'en': 'love'},
        ),
        WordCard(
          id: _nextId(), word: 'loves', pos: PartOfSpeech.verb,
          frames: _verbFrames['loves'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '사랑하다', 'ja': '愛する', 'en': 'loves'},
        ),
        // need / needs
        WordCard(
          id: _nextId(), word: 'need', pos: PartOfSpeech.verb,
          frames: _verbFrames['need'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '필요하다', 'ja': '必要', 'en': 'need'},
        ),
        WordCard(
          id: _nextId(), word: 'needs', pos: PartOfSpeech.verb,
          frames: _verbFrames['needs'],
         
          person: 3, number: 'singular',
          meanings: {'ko': '필요하다', 'ja': '必要', 'en': 'needs'},
        ),
        WordCard(
          id: _nextId(), word: 'go', pos: PartOfSpeech.verb,
          frames: _verbFrames['go'],
         
          person: 1, number: 'plural',
          meanings: {'ko': '가다', 'ja': '行く', 'en': 'go'},
        ),
      ];

  // === ADJECTIVES (12 cards) ===
  List<WordCard> _adjectives() => [
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
          id: _nextId(), word: 'good', pos: PartOfSpeech.adjective,
          adjOrder: 1,
          meanings: {'ko': '좋은', 'ja': '良い', 'en': 'good'},
        ),
      ];

  // === ADVERBS (4 cards) ===
  List<WordCard> _adverbs() => [
        WordCard(
          id: _nextId(), word: 'very', pos: PartOfSpeech.adverb,
          adverbKind: _adverbKinds['very'],
          meanings: {'ko': '매우', 'ja': 'とても', 'en': 'very'},
        ),
        WordCard(
          id: _nextId(), word: 'really', pos: PartOfSpeech.adverb,
          adverbKind: _adverbKinds['really'],
          meanings: {'ko': '정말', 'ja': '本当に', 'en': 'really'},
        ),
        WordCard(
          id: _nextId(), word: 'always', pos: PartOfSpeech.adverb,
          adverbKind: _adverbKinds['always'],
          meanings: {'ko': '항상', 'ja': 'いつも', 'en': 'always'},
        ),
        WordCard(
          id: _nextId(), word: 'never', pos: PartOfSpeech.adverb,
          adverbKind: _adverbKinds['never'],
          meanings: {'ko': '절대', 'ja': '決して', 'en': 'never'},
        ),
        WordCard(
          id: _nextId(), word: 'fast', pos: PartOfSpeech.adverb,
          adverbKind: _adverbKinds['fast'],
          meanings: {'ko': '빠르게', 'ja': '速く', 'en': 'fast'},
        ),
        WordCard(
          id: _nextId(), word: 'slowly', pos: PartOfSpeech.adverb,
          adverbKind: _adverbKinds['slowly'],
          meanings: {'ko': '천천히', 'ja': 'ゆっくり', 'en': 'slowly'},
        ),
      ];

  // === PREPOSITIONS (4 cards) ===
  List<WordCard> _prepositions() => [
        for (final w in const [
          'in', 'in', 'on', 'on', 'under', 'under', 'with', 'with',
        ])
          WordCard(
            id: _nextId(), word: w, pos: PartOfSpeech.preposition,
            meanings: _prepMeanings[w]!,
          ),
      ];

  static const _prepMeanings = {
    'in': {'ko': '~안에', 'ja': '~の中に', 'en': 'in'},
    'on': {'ko': '~위에', 'ja': '~の上に', 'en': 'on'},
    'under': {'ko': '~아래에', 'ja': '~の下に', 'en': 'under'},
    'with': {'ko': '~와 함께', 'ja': '~と一緒に', 'en': 'with'},
  };


  // === SPECIAL CARDS (12 cards) ===
  List<WordCard> _specialCards() => [
        for (int i = 0; i < 4; i++) WordCard.special(_nextId(), CardType.joker),
        for (int i = 0; i < 3; i++) WordCard.special(_nextId(), CardType.jump),
        for (int i = 0; i < 3; i++) WordCard.special(_nextId(), CardType.steal),
      ];
}
