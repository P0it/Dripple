import 'package:test/test.dart';
import 'package:dripple_rules/data/card_deck.dart';
import 'package:dripple_rules/models/word_card.dart';

void main() {
  group('CardDeck composition', () {
    test('generates 110 cards', () {
      expect(CardDeck().generate().length, 110);
    });

    test('has the specified part-of-speech distribution', () {
      final deck = CardDeck().generate();
      int countPos(PartOfSpeech p) =>
          deck.where((c) => c.type == CardType.word && c.pos == p).length;

      expect(countPos(PartOfSpeech.pronoun), 12);
      expect(countPos(PartOfSpeech.article), 10);
      expect(countPos(PartOfSpeech.noun), 26);
      expect(countPos(PartOfSpeech.verb), 26);
      expect(countPos(PartOfSpeech.adjective), 12);
      expect(countPos(PartOfSpeech.adverb), 6);
      expect(countPos(PartOfSpeech.preposition), 8);
    });

    test('has 4 jokers, 3 jumps, 3 steals', () {
      final deck = CardDeck().generate();
      expect(deck.where((c) => c.type == CardType.joker).length, 4);
      expect(deck.where((c) => c.type == CardType.jump).length, 3);
      expect(deck.where((c) => c.type == CardType.steal).length, 3);
    });

    test('contains no conjunctions', () {
      final deck = CardDeck().generate();
      expect(deck.any((c) => c.word == 'and' || c.word == 'but'), false);
    });

    test('all card ids are unique', () {
      final deck = CardDeck().generate();
      expect(deck.map((c) => c.id).toSet().length, deck.length);
    });

    test('each independently generated deck is internally unique', () {
      final a = CardDeck().generate();
      final b = CardDeck().generate();
      expect(a.map((c) => c.id).toSet().length, a.length);
      expect(b.map((c) => c.id).toSet().length, b.length);
    });
  });

  group('Guaranteed opening hands', () {
    test('every hand has at least one verb and one subject-capable card', () {
      for (var trial = 0; trial < 50; trial++) {
        final deck = CardDeck().generate()..shuffle();
        final (hands, _) = CardDeck.dealGuaranteedHands(
          deck: deck,
          playerCount: 4,
          handSize: 7,
        );
        expect(hands.length, 4);
        for (final hand in hands) {
          expect(hand.length, 7);
          expect(hand.any((c) => c.isVerb), true,
              reason: 'hand without a verb: ${hand.map((c) => c.word)}');
          expect(hand.any((c) => c.canBeSubject), true,
              reason: 'hand without a subject: ${hand.map((c) => c.word)}');
        }
      }
    });

    test('dealt cards are removed from the remaining deck', () {
      final deck = CardDeck().generate()..shuffle();
      final (hands, rest) = CardDeck.dealGuaranteedHands(
        deck: deck,
        playerCount: 4,
        handSize: 7,
      );
      expect(rest.length, 110 - 28);
      final dealtIds = hands.expand((h) => h).map((c) => c.id).toSet();
      expect(rest.any((c) => dealtIds.contains(c.id)), false);
    });
  });
}
