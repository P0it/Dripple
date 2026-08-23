import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/core/design/app_colors.dart';
import 'package:dripple/models/word_card.dart';

void main() {
  group('AppColors.forPartOfSpeech', () {
    test('gives every part of speech its own colour', () {
      final seen = <PartOfSpeech, Color>{};
      for (final pos in PartOfSpeech.values) {
        seen[pos] = AppColors.forPartOfSpeech(pos);
      }
      // A copy-paste slip in the mapping table would collapse two entries.
      expect(seen.values.toSet().length, PartOfSpeech.values.length);
    });

    test('falls back to a neutral for a card with no part of speech', () {
      final fallback = AppColors.forPartOfSpeech(null);
      for (final pos in PartOfSpeech.values) {
        expect(AppColors.forPartOfSpeech(pos), isNot(fallback));
      }
    });

    /// The Montessori palette is not decoration: a child comes to expect
    /// verbs red and prepositions green. Desaturating the hues is fine;
    /// swapping which family a part of speech belongs to is not.
    test('keeps the Montessori hue families', () {
      double hue(PartOfSpeech pos) =>
          HSLColor.fromColor(AppColors.forPartOfSpeech(pos)).hue;

      expect(hue(PartOfSpeech.verb), anyOf(greaterThan(340), lessThan(20)),
          reason: 'verb should read as red');
      expect(hue(PartOfSpeech.preposition), inInclusiveRange(90, 170),
          reason: 'preposition should read as green');
      expect(hue(PartOfSpeech.adverb), inInclusiveRange(20, 50),
          reason: 'adverb should read as orange');
      expect(hue(PartOfSpeech.pronoun), inInclusiveRange(240, 290),
          reason: 'pronoun should read as purple');
      expect(hue(PartOfSpeech.adjective), inInclusiveRange(200, 250),
          reason: 'adjective should read as blue');
    });

    test('is stable across calls', () {
      expect(
        AppColors.forPartOfSpeech(PartOfSpeech.noun),
        AppColors.forPartOfSpeech(PartOfSpeech.noun),
      );
    });
  });

  group('AppColors.specialCard', () {
    test('gives each special card its own colour', () {
      const special = [CardType.jump, CardType.steal, CardType.joker];
      final colours = special.map(AppColors.specialCard).toSet();
      expect(colours.length, special.length);
    });
  });
}
