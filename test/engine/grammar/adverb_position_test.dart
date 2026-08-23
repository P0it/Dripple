import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/data/card_deck.dart';
import 'package:dripple/engine/grammar/sentence_parser.dart';
import 'package:dripple/models/word_card.dart';

WordCard _pron(String w) => WordCard(
    id: 'p_$w', word: w, pos: PartOfSpeech.pronoun,
    person: 1, number: 'plural', animacy: Animacy.animate);
WordCard _noun(String w) => WordCard(
    id: 'n_$w', word: w, pos: PartOfSpeech.noun, person: 3,
    number: 'plural', countable: true, animacy: Animacy.inanimate);
WordCard _adj(String w) =>
    WordCard(id: 'a_$w', word: w, pos: PartOfSpeech.adjective);
WordCard _adv(String w, AdverbKind kind) => WordCard(
    id: 'd_$w', word: w, pos: PartOfSpeech.adverb, adverbKind: kind);
WordCard _verb(String w, Set<VerbFrame> frames) => WordCard(
    id: 'v_$w', word: w, pos: PartOfSpeech.verb,
    person: 1, number: 'plural', frames: frames);

void main() {
  final parser = SentenceParser();
  final read = {VerbFrame.intransitive, VerbFrame.transitive};

  group('frequency adverbs sit before the verb', () {
    test('"they always read" parses', () {
      expect(
        parser.parse([
          _pron('they'),
          _adv('always', AdverbKind.frequency),
          _verb('read', read),
        ]),
        true,
      );
    });

    test('"they read always" does not', () {
      expect(
        parser.parse([
          _pron('they'),
          _verb('read', read),
          _adv('always', AdverbKind.frequency),
        ]),
        false,
      );
    });
  });

  group('manner adverbs sit after the verb', () {
    test('"they read slowly" parses', () {
      expect(
        parser.parse([
          _pron('they'),
          _verb('read', read),
          _adv('slowly', AdverbKind.manner),
        ]),
        true,
      );
    });

    test('"they slowly read" does not', () {
      expect(
        parser.parse([
          _pron('they'),
          _adv('slowly', AdverbKind.manner),
          _verb('read', read),
        ]),
        false,
      );
    });

    test('a manner adverb still follows an object', () {
      expect(
        parser.parse([
          _pron('they'),
          _verb('read', read),
          _noun('books'),
          _adv('slowly', AdverbKind.manner),
        ]),
        true,
      );
    });
  });

  group('degree adverbs modify adjectives', () {
    test('"we are very happy" parses', () {
      expect(
        parser.parse([
          _pron('we'),
          _verb('are', {VerbFrame.linking, VerbFrame.transitive}),
          _adv('very', AdverbKind.degree),
          _adj('happy'),
        ]),
        true,
      );
    });

    test('a degree adverb cannot stand alone after a verb', () {
      expect(
        parser.parse([
          _pron('they'),
          _verb('read', read),
          _adv('very', AdverbKind.degree),
        ]),
        false,
      );
    });
  });

  test('every adverb in the deck declares its kind', () {
    final deck = CardDeck().generate();
    final adverbs =
        deck.where((c) => c.pos == PartOfSpeech.adverb).toList();
    expect(adverbs, isNotEmpty);
    for (final a in adverbs) {
      expect(a.adverbKind, isNotNull, reason: '"${a.word}" has no kind');
    }
  });
}
