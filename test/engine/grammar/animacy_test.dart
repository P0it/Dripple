import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/data/card_deck.dart';
import 'package:dripple/engine/grammar/grammar_engine.dart';
import 'package:dripple/models/word_card.dart';

WordCard _noun(String w, Animacy a,
        {String number = 'singular', bool countable = true}) =>
    WordCard(
        id: 'n_$w', word: w, pos: PartOfSpeech.noun, person: 3,
        number: number, countable: countable, animacy: a);
WordCard _art(String w) =>
    WordCard(id: 'a_$w', word: w, pos: PartOfSpeech.article);
WordCard _verb(String w,
        {required Set<VerbFrame> frames,
        bool animate = false,
        int person = 3,
        String number = 'singular'}) =>
    WordCard(
        id: 'v_$w', word: w, pos: PartOfSpeech.verb, person: person,
        number: number, frames: frames, requiresAnimateSubject: animate);

void main() {
  final engine = GrammarEngine();

  group('animacy', () {
    test('an inanimate subject cannot read', () {
      final r = engine.validate([
        _art('the'),
        _noun('flower', Animacy.inanimate),
        _verb('reads',
            frames: {VerbFrame.intransitive, VerbFrame.transitive},
            animate: true),
      ]);
      expect(r.isValid, false);
      expect(r.errors.any((e) => e.code == 'animacy'), true);
    });

    test('an animate subject can read', () {
      final r = engine.validate([
        _art('the'),
        _noun('girl', Animacy.animate),
        _verb('reads',
            frames: {VerbFrame.intransitive, VerbFrame.transitive},
            animate: true),
      ]);
      expect(r.isValid, true);
    });

    test('a verb with no animacy requirement accepts anything', () {
      final r = engine.validate([
        _art('the'),
        _noun('house', Animacy.inanimate),
        _verb('has', frames: {VerbFrame.transitive}),
        _noun('books', Animacy.inanimate, number: 'plural'),
      ]);
      expect(r.isValid, true);
    });

    test('the error message names the offending word in Korean', () {
      final r = engine.validate([
        _art('the'),
        _noun('star', Animacy.inanimate),
        _verb('eats',
            frames: {VerbFrame.intransitive, VerbFrame.transitive},
            animate: true),
      ]);
      final e = r.errors.firstWhere((e) => e.code == 'animacy');
      expect(e.localizedMessages?['ko'], contains('star'));
      expect(e.localizedMessages?['ko'], contains('eats'));
    });
  });

  group('deck data', () {
    test('every noun declares animacy', () {
      final deck = CardDeck().generate();
      final nouns = deck.where((c) => c.isNoun).toList();
      expect(nouns, isNotEmpty);
      for (final n in nouns) {
        expect(n.animacy, isNotNull, reason: '"${n.word}" has no animacy');
      }
    });

    test('"the flower reads" is rejected using real deck cards', () {
      final deck = CardDeck().generate();
      final the = deck.firstWhere((c) => c.word == 'the');
      final flower = deck.firstWhere((c) => c.word == 'flower');
      final reads = deck.firstWhere((c) => c.word == 'reads');
      expect(engine.validate([the, flower, reads]).isValid, false);
    });

    test('"the girl reads" is accepted using real deck cards', () {
      final deck = CardDeck().generate();
      final the = deck.firstWhere((c) => c.word == 'the');
      final girl = deck.firstWhere((c) => c.word == 'girl');
      final reads = deck.firstWhere((c) => c.word == 'reads');
      expect(engine.validate([the, girl, reads]).isValid, true);
    });
  });
}
