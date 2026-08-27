import 'package:test/test.dart';
import 'package:dripple_rules/engine/grammar/grammar_engine.dart';
import 'package:dripple_rules/models/word_card.dart';

WordCard _art(String w, {bool? vowelStart}) => WordCard(
    id: 'a_$w', word: w, pos: PartOfSpeech.article, vowelStart: vowelStart);
WordCard _adj(String w) =>
    WordCard(id: 'j_$w', word: w, pos: PartOfSpeech.adjective);
WordCard _noun(String w, {bool vowelStart = false}) => WordCard(
    id: 'n_$w', word: w, pos: PartOfSpeech.noun, person: 3,
    number: 'singular', countable: true, vowelStart: vowelStart);
WordCard _verb(String w) => WordCard(
    id: 'v_$w', word: w, pos: PartOfSpeech.verb, person: 3,
    number: 'singular', frames: {VerbFrame.intransitive});

void main() {
  final engine = GrammarEngine();
  bool valid(List<WordCard> s) => engine.validate(s).isValid;

  group('the article agrees with the word right after it', () {
    // Adjective cards carry no explicit vowelStart, so this used to pass.
    test('"an green friend runs" is rejected', () {
      expect(valid([_art('an'), _adj('green'), _noun('friend'), _verb('runs')]),
          false);
    });

    test('"a green friend runs" is accepted', () {
      expect(valid([_art('a'), _adj('green'), _noun('friend'), _verb('runs')]),
          true);
    });

    test('"an old friend runs" is accepted', () {
      expect(valid([_art('an'), _adj('old'), _noun('friend'), _verb('runs')]),
          true);
    });

    test('"a old friend runs" is rejected', () {
      expect(valid([_art('a'), _adj('old'), _noun('friend'), _verb('runs')]),
          false);
    });
  });

  group('an explicit flag still wins over the spelling', () {
    test('a word declared consonant-sounding takes "a"', () {
      final hour = _noun('hour', vowelStart: false);
      expect(valid([_art('a'), hour, _verb('runs')]), true);
      expect(valid([_art('an'), hour, _verb('runs')]), false);
    });
  });
}
