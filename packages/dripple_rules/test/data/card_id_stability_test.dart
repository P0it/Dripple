import 'package:test/test.dart';
import 'package:dripple_rules/data/card_deck.dart';

/// Online play sends card ids over the wire, not card contents — the deck is
/// static data both ends already hold. That only works if the same card gets
/// the same id on every device and in every process.
void main() {
  group('card ids are deterministic', () {
    test('two decks from the same instance agree', () {
      final deck = CardDeck();
      final first = deck.generate().map((c) => c.id).toList();
      final second = deck.generate().map((c) => c.id).toList();
      expect(second, equals(first));
    });

    test('two decks from separate instances agree', () {
      final a = CardDeck().generate().map((c) => c.id).toList();
      final b = CardDeck().generate().map((c) => c.id).toList();
      expect(b, equals(a));
    });

    test('ids are unique', () {
      final ids = CardDeck().generate().map((c) => c.id).toList();
      expect(ids.toSet().length, equals(ids.length));
    });

    test('an id resolves back to the same card', () {
      final deck = CardDeck().generate();
      for (final card in deck) {
        expect(CardDeck.cardById(card.id), equals(card),
            reason: 'id ${card.id} did not resolve back');
      }
    });

    test('an unknown id resolves to null', () {
      expect(CardDeck.cardById('card_no_such_thing'), isNull);
    });
  });
}
