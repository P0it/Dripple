import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/data/card_deck.dart';
import 'package:dripple/engine/grammar/sentence_parser.dart';
import 'package:dripple/models/word_card.dart';

WordCard _pron(String w) => WordCard(
    id: 'p_$w', word: w, pos: PartOfSpeech.pronoun,
    person: 1, number: 'plural');
WordCard _noun(String w) => WordCard(
    id: 'n_$w', word: w, pos: PartOfSpeech.noun,
    person: 3, number: 'plural', countable: true);
WordCard _adj(String w) =>
    WordCard(id: 'a_$w', word: w, pos: PartOfSpeech.adjective);
WordCard _verb(String w, Set<VerbFrame> frames) => WordCard(
    id: 'v_$w', word: w, pos: PartOfSpeech.verb,
    person: 1, number: 'plural', frames: frames);

void main() {
  final parser = SentenceParser();

  group('verb valency', () {
    test('an intransitive verb refuses an object', () {
      expect(
        parser.parse([
          _noun('apples'),
          _verb('run', {VerbFrame.intransitive}),
          _noun('friends'),
        ]),
        false,
      );
    });

    test('an intransitive verb stands alone', () {
      expect(
        parser.parse([_noun('apples'), _verb('run', {VerbFrame.intransitive})]),
        true,
      );
    });

    test('a transitive-only verb refuses to stand alone', () {
      expect(
        parser.parse([_pron('we'), _verb('make', {VerbFrame.transitive})]),
        false,
      );
    });

    test('a transitive verb takes an object', () {
      expect(
        parser.parse([
          _pron('we'),
          _verb('make', {VerbFrame.transitive}),
          _noun('cakes'),
        ]),
        true,
      );
    });

    test('a verb with both frames works either way', () {
      final read = {VerbFrame.intransitive, VerbFrame.transitive};
      expect(parser.parse([_pron('we'), _verb('read', read)]), true);
      expect(
        parser.parse([_pron('we'), _verb('read', read), _noun('books')]),
        true,
      );
    });

    test('only a linking verb takes an adjective complement', () {
      expect(
        parser.parse([
          _pron('we'),
          _verb('are', {VerbFrame.linking, VerbFrame.transitive}),
          _adj('happy'),
        ]),
        true,
      );
      expect(
        parser.parse([
          _pron('we'),
          _verb('read', {VerbFrame.intransitive, VerbFrame.transitive}),
          _adj('small'),
        ]),
        false,
      );
    });

    test('a card with no frame data is left unconstrained', () {
      // Test fixtures elsewhere build verbs without valency; those must keep
      // parsing rather than silently failing.
      const bare = WordCard(
          id: 'v_bare', word: 'run', pos: PartOfSpeech.verb,
          person: 1, number: 'plural');
      expect(parser.parse([_pron('we'), bare]), true);
      expect(parser.parse([_pron('we'), bare, _noun('books')]), true);
    });
  });

  group('deck data', () {
    test('every verb card declares its frames', () {
      final deck = CardDeck().generate();
      final verbs = deck.where((c) => c.isVerb).toList();
      expect(verbs, isNotEmpty);
      for (final v in verbs) {
        expect(v.frames, isNotNull, reason: '"${v.word}" has no frames');
        expect(v.frames, isNotEmpty, reason: '"${v.word}" has empty frames');
      }
    });

    test('"run" cannot take an object once dealt from the real deck', () {
      final deck = CardDeck().generate();
      final run = deck.firstWhere((c) => c.word == 'run');
      final cats = deck.firstWhere((c) => c.word == 'cats');
      final we = deck.firstWhere((c) => c.word == 'we');

      expect(parser.parse([we, run, cats]), false);
      expect(parser.parse([we, run]), true);
    });
  });
}
