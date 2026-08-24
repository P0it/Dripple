import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/data/card_deck.dart';
import 'package:dripple/game/pos_pip.dart';
import 'package:dripple/models/word_card.dart';

/// The corner index is what lets a hand be read while the cards overlap, so a
/// part of speech with no tag or no pip is a card that cannot be scanned.
void main() {
  test('every part of speech has an abbreviation', () {
    for (final pos in PartOfSpeech.values) {
      expect(PosPip.tagFor(pos), isNotEmpty, reason: '$pos has no tag');
    }
  });

  test('an abbreviation fits in a card corner', () {
    // The index column is roughly a quarter of the card. Anything longer than
    // five characters at that size runs into the word.
    for (final pos in PartOfSpeech.values) {
      expect(PosPip.tagFor(pos).length, lessThanOrEqualTo(5), reason: '$pos');
    }
  });

  test('a joker carries no part of speech and so no tag', () {
    expect(PosPip.tagFor(null), isEmpty);
  });

  test('every pip paints without throwing, including the null case', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (final pos in [...PartOfSpeech.values, null]) {
      PosPip.paint(
        canvas,
        pos,
        const Rect.fromLTWH(0, 0, 6, 6),
        const Color(0xFF000000),
      );
    }
    recorder.endRecording();
  });

  test('every word card in the deck has a part of speech to index', () {
    final missing = CardDeck().generate()
        .where((c) => !c.isSpecial && c.pos == null)
        .map((c) => c.word)
        .toList();
    expect(missing, isEmpty);
  });
}
