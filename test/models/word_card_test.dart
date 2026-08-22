import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/word_card.dart';

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

    test('noun is black large triangle', () {
      expect(c(PartOfSpeech.noun).posShape, PosShape.triangleLarge);
      expect(c(PartOfSpeech.noun).posColor, 0xFF1F2937);
    });

    test('verb is red circle', () {
      expect(c(PartOfSpeech.verb).posShape, PosShape.circle);
      expect(c(PartOfSpeech.verb).posColor, 0xFFDC2626);
    });

    test('preposition is green crescent', () {
      expect(c(PartOfSpeech.preposition).posShape, PosShape.crescent);
      expect(c(PartOfSpeech.preposition).posColor, 0xFF16A34A);
    });

    test('special cards have no part-of-speech shape', () {
      expect(WordCard.special('j', CardType.joker).posShape, PosShape.none);
    });
  });
}
