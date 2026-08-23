import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/engine/grammar/sentence_parser.dart';

WordCard _c(String word, PartOfSpeech pos) =>
    WordCard(id: 'p_$word', word: word, pos: pos);
WordCard _joker() => WordCard.special('p_joker', CardType.joker);

void main() {
  final parser = SentenceParser();

  group('SentenceParser', () {
    test('SV: "they run"', () {
      expect(parser.parse([
        _c('they', PartOfSpeech.pronoun),
        _c('run', PartOfSpeech.verb),
      ]), true);
    });

    test('SVO: "I like cats"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('like', PartOfSpeech.verb),
        _c('cats', PartOfSpeech.noun),
      ]), true);
    });

    test('Art+Adj+N subject: "the big cat runs"', () {
      expect(parser.parse([
        _c('the', PartOfSpeech.article),
        _c('big', PartOfSpeech.adjective),
        _c('cat', PartOfSpeech.noun),
        _c('runs', PartOfSpeech.verb),
      ]), true);
    });

    test('SVC: "I am happy"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('am', PartOfSpeech.verb),
        _c('happy', PartOfSpeech.adjective),
      ]), true);
    });

    test('SVC with adverb: "I am very happy"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('am', PartOfSpeech.verb),
        _c('very', PartOfSpeech.adverb),
        _c('happy', PartOfSpeech.adjective),
      ]), true);
    });

    test('SV+Adv: "I run fast"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('run', PartOfSpeech.verb),
        _c('fast', PartOfSpeech.adverb),
      ]), true);
    });

    test('prepositional phrase: "I like the cat in the box"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('like', PartOfSpeech.verb),
        _c('the', PartOfSpeech.article),
        _c('cat', PartOfSpeech.noun),
        _c('in', PartOfSpeech.preposition),
        _c('the', PartOfSpeech.article),
        _c('box', PartOfSpeech.noun),
      ]), true);
    });

    test('two prepositional phrases', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('sit', PartOfSpeech.verb),
        _c('on', PartOfSpeech.preposition),
        _c('the', PartOfSpeech.article),
        _c('chair', PartOfSpeech.noun),
        _c('with', PartOfSpeech.preposition),
        _c('you', PartOfSpeech.pronoun),
      ]), true);
    });

    test('joker acts as any part of speech', () {
      expect(parser.parse([
        _joker(),
        _c('run', PartOfSpeech.verb),
      ]), true);
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _joker(),
      ]), true);
    });

    test('rejects verb-first sentence', () {
      expect(parser.parse([
        _c('run', PartOfSpeech.verb),
        _c('I', PartOfSpeech.pronoun),
      ]), false);
    });

    test('rejects sentence with no verb', () {
      expect(parser.parse([
        _c('the', PartOfSpeech.article),
        _c('big', PartOfSpeech.adjective),
        _c('cat', PartOfSpeech.noun),
      ]), false);
    });

    test('rejects dangling preposition', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('run', PartOfSpeech.verb),
        _c('in', PartOfSpeech.preposition),
      ]), false);
    });

    test('rejects a subject pronoun in object position: "cats like I"', () {
      expect(parser.parse([
        _c('cats', PartOfSpeech.noun),
        _c('like', PartOfSpeech.verb),
        _c('I', PartOfSpeech.pronoun),
      ]), false);
    });

    test('accepts case-neutral pronoun as object: "cats like you"', () {
      expect(parser.parse([
        _c('cats', PartOfSpeech.noun),
        _c('like', PartOfSpeech.verb),
        _c('you', PartOfSpeech.pronoun),
      ]), true);
    });

    test('rejects a bare singular countable noun: "tree wants"', () {
      expect(parser.parse([
        WordCard(
            id: 'n', word: 'tree', pos: PartOfSpeech.noun,
            number: 'singular', countable: true),
        _c('wants', PartOfSpeech.verb),
      ]), false);
    });

    test('accepts the same noun with an article: "the tree grows"', () {
      expect(parser.parse([
        _c('the', PartOfSpeech.article),
        WordCard(
            id: 'n', word: 'tree', pos: PartOfSpeech.noun,
            number: 'singular', countable: true),
        _c('grows', PartOfSpeech.verb),
      ]), true);
    });

    test('accepts a bare plural: "cats run"', () {
      expect(parser.parse([
        WordCard(
            id: 'n', word: 'cats', pos: PartOfSpeech.noun,
            number: 'plural', countable: true),
        _c('run', PartOfSpeech.verb),
      ]), true);
    });

    test('accepts a bare uncountable: "water is cold"', () {
      expect(parser.parse([
        WordCard(
            id: 'n', word: 'water', pos: PartOfSpeech.noun,
            number: 'singular', countable: false),
        _c('is', PartOfSpeech.verb),
        _c('cold', PartOfSpeech.adjective),
      ]), true);
    });

    // Valency now comes from the card, so the verb has to declare it.
    test('rejects an adjective complement after a non-linking verb', () {
      expect(parser.parse([
        _c('they', PartOfSpeech.pronoun),
        const WordCard(
          id: 'v_read',
          word: 'read',
          pos: PartOfSpeech.verb,
          frames: {VerbFrame.intransitive, VerbFrame.transitive},
        ),
        _c('small', PartOfSpeech.adjective),
      ]), false);
    });

    test('rejects single card', () {
      expect(parser.parse([_c('I', PartOfSpeech.pronoun)]), false);
    });
  });
}
