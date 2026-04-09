import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/engine/grammar/grammar_engine.dart';

/// Helper to quickly create word cards for testing
WordCard _pronoun(String word, int person, String number) => WordCard(
      id: 'test_$word',
      word: word,
      pos: PartOfSpeech.pronoun,
      person: person,
      number: number,
    );

WordCard _article(String word, {bool? vowelStart}) => WordCard(
      id: 'test_$word',
      word: word,
      pos: PartOfSpeech.article,
      vowelStart: vowelStart,
    );

WordCard _noun(String word,
        {int person = 3,
        String number = 'singular',
        bool countable = true,
        bool vowelStart = false}) =>
    WordCard(
      id: 'test_$word',
      word: word,
      pos: PartOfSpeech.noun,
      person: person,
      number: number,
      countable: countable,
      vowelStart: vowelStart,
    );

WordCard _verb(String word, {int person = 1, String number = 'plural'}) =>
    WordCard(
      id: 'test_$word',
      word: word,
      pos: PartOfSpeech.verb,
      person: person,
      number: number,
    );

WordCard _adj(String word, {int? adjOrder}) => WordCard(
      id: 'test_$word',
      word: word,
      pos: PartOfSpeech.adjective,
      adjOrder: adjOrder,
    );

void main() {
  late GrammarEngine engine;

  setUp(() {
    engine = GrammarEngine();
  });

  group('GrammarEngine basics', () {
    test('empty sentence is invalid', () {
      final result = engine.validate([]);
      expect(result.isValid, false);
      expect(result.errors.first.code, 'empty_sentence');
    });

    test('single word sentence is invalid', () {
      final result = engine.validate([_pronoun('I', 1, 'singular')]);
      expect(result.isValid, false);
      expect(result.errors.first.code, 'too_short');
    });
  });

  group('Valid sentences', () {
    test('"I like cats" is valid (SVO)', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('like', person: 1, number: 'plural'),
        _noun('cats', number: 'plural'),
      ]);
      expect(result.isValid, true);
      expect(result.score, 3);
    });

    test('"she likes cats" is valid', () {
      final result = engine.validate([
        _pronoun('she', 3, 'singular'),
        _verb('likes', person: 3, number: 'singular'),
        _noun('cats', number: 'plural'),
      ]);
      expect(result.isValid, true);
    });

    test('"they run" is valid (SV)', () {
      final result = engine.validate([
        _pronoun('they', 3, 'plural'),
        _verb('run', person: 1, number: 'plural'),
      ]);
      expect(result.isValid, true);
    });

    test('"the cat runs" is valid', () {
      final result = engine.validate([
        _article('the'),
        _noun('cat', number: 'singular'),
        _verb('runs', person: 3, number: 'singular'),
      ]);
      expect(result.isValid, true);
    });

    test('"I am happy" is valid (SVC)', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('am', person: 1, number: 'singular'),
        _adj('happy'),
      ]);
      expect(result.isValid, true);
    });

    test('"the big cat likes the small dog" is valid', () {
      final result = engine.validate([
        _article('the'),
        _adj('big', adjOrder: 2),
        _noun('cat', number: 'singular'),
        _verb('likes', person: 3, number: 'singular'),
        _article('the'),
        _adj('small', adjOrder: 2),
        _noun('dog', number: 'singular'),
      ]);
      expect(result.isValid, true);
    });
  });

  group('Article agreement', () {
    test('"a apple" is invalid (should be "an")', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('like', person: 1, number: 'plural'),
        _article('a', vowelStart: false),
        _noun('apple', vowelStart: true),
      ]);
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.code == 'article_a_vowel'), true);
    });

    test('"an cat" is invalid (should be "a")', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('like', person: 1, number: 'plural'),
        _article('an', vowelStart: true),
        _noun('cat', vowelStart: false),
      ]);
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.code == 'article_an_consonant'), true);
    });
  });

  group('Number agreement', () {
    test('"a cats" is invalid (article + plural)', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('like', person: 1, number: 'plural'),
        _article('a', vowelStart: false),
        _noun('cats', number: 'plural', vowelStart: false),
      ]);
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.code == 'article_plural'), true);
    });

    test('"a water" is invalid (article + uncountable)', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('like', person: 1, number: 'plural'),
        _article('a', vowelStart: false),
        _noun('water', countable: false, vowelStart: false),
      ]);
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.code == 'article_uncountable'), true);
    });

    test('"the cats" is valid', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('like', person: 1, number: 'plural'),
        _article('the'),
        _noun('cats', number: 'plural'),
      ]);
      expect(result.isValid, true);
    });
  });

  group('Subject-verb agreement', () {
    test('"he like cats" is invalid (needs "likes")', () {
      final result = engine.validate([
        _pronoun('he', 3, 'singular'),
        _verb('like', person: 1, number: 'plural'),
        _noun('cats', number: 'plural'),
      ]);
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.code == 'sv_agreement'), true);
    });

    test('"I likes cats" is invalid', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('likes', person: 3, number: 'singular'),
        _noun('cats', number: 'plural'),
      ]);
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.code == 'sv_agreement'), true);
    });

    test('"he is happy" is valid', () {
      final result = engine.validate([
        _pronoun('he', 3, 'singular'),
        _verb('is', person: 3, number: 'singular'),
        _adj('happy'),
      ]);
      expect(result.isValid, true);
    });

    test('"he am happy" is invalid', () {
      final result = engine.validate([
        _pronoun('he', 3, 'singular'),
        _verb('am', person: 1, number: 'singular'),
        _adj('happy'),
      ]);
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.code == 'sv_agreement_be'), true);
    });
  });

  group('Adjective order', () {
    test('"big red ball" is valid (size before color)', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('like', person: 1, number: 'plural'),
        _article('the'),
        _adj('big', adjOrder: 2),
        _adj('red', adjOrder: 5),
        _noun('ball'),
      ]);
      expect(result.isValid, true);
    });

    test('"red big ball" is invalid (color before size)', () {
      final result = engine.validate([
        _pronoun('I', 1, 'singular'),
        _verb('like', person: 1, number: 'plural'),
        _article('the'),
        _adj('red', adjOrder: 5),
        _adj('big', adjOrder: 2),
        _noun('ball'),
      ]);
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.code == 'adj_order'), true);
    });
  });

  group('Score calculation', () {
    test('combo score multiplier works', () {
      expect(GrammarEngine.calculateScoreWithCombo(3, 0), 3);
      expect(GrammarEngine.calculateScoreWithCombo(3, 1), 3);
      expect(GrammarEngine.calculateScoreWithCombo(3, 2), 5); // 3 * 1.5
      expect(GrammarEngine.calculateScoreWithCombo(4, 3), 8); // 4 * 2.0
    });
  });
}
