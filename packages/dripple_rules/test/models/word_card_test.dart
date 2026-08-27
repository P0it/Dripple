import 'package:test/test.dart';
import 'package:dripple_rules/models/word_card.dart';

void main() {
  group('CardType', () {
    test('has exactly word, jump, steal, joker', () {
      expect(CardType.values.length, 4);
      expect(CardType.values.contains(CardType.jump), true);
      expect(CardType.values.contains(CardType.steal), true);
      expect(CardType.values.contains(CardType.joker), true);
    });
  });

  group('Montessori part-of-speech symbols', () {
    WordCard c(PartOfSpeech pos) => WordCard(id: 'x', word: 'w', pos: pos);

    test('noun is a large triangle', () {
      expect(c(PartOfSpeech.noun).posShape, PosShape.triangleLarge);
    });

    test('verb is a circle', () {
      expect(c(PartOfSpeech.verb).posShape, PosShape.circle);
    });

    test('preposition is a crescent', () {
      expect(c(PartOfSpeech.preposition).posShape, PosShape.crescent);
    });

    test('special cards have no part-of-speech shape', () {
      expect(WordCard.special('j', CardType.joker).posShape, PosShape.none);
    });
  });
}
