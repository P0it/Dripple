import 'package:flutter/material.dart';

import '../../models/word_card.dart';

/// Every colour in the app. Nothing outside this file defines one.
///
/// One accent colour carries the UI. The part-of-speech palette below is a
/// deliberate exception: a child learns word order partly by noticing that
/// nouns and verbs are consistently different colours, so those hues earn
/// their place.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const divider = Color(0xFFEEF0F3);
  static const border = Color(0xFFD9DDE3);

  // Text
  static const textPrimary = Color(0xFF17181C);
  static const textSecondary = Color(0xFF6B7684);
  static const textDisabled = Color(0xFF9AA1AC);

  // Accent — the brand is a water drop, so blue is the thematic choice.
  static const point = Color(0xFF1D74F5);
  static const pointPressed = Color(0xFF1662D6);
  static const pointTint = Color(0xFFEAF2FE);

  // Status
  static const success = Color(0xFF12B76A);
  static const danger = Color(0xFFE5484D);

  /// A card whose part of speech the deck did not set.
  static const posNeutral = Color(0xFF8A929E);

  /// Montessori grammar colours, desaturated to sit inside the palette.
  /// The semantics are preserved; only the saturation changed.
  static Color forPartOfSpeech(PartOfSpeech? pos) => switch (pos) {
        PartOfSpeech.noun => const Color(0xFF2E3A4F),
        PartOfSpeech.adjective => const Color(0xFF3D5AA8),
        PartOfSpeech.article => const Color(0xFF8FC5E8),
        PartOfSpeech.pronoun => const Color(0xFF7A63D9),
        PartOfSpeech.verb => const Color(0xFFD14A4E),
        PartOfSpeech.adverb => const Color(0xFFE08A42),
        PartOfSpeech.preposition => const Color(0xFF3F9E6B),
        null => posNeutral,
      };

  /// Special cards read as actions rather than words, so they take the point
  /// colour family instead of the grammar palette.
  static Color specialCard(CardType type) => switch (type) {
        CardType.jump => const Color(0xFF1D74F5),
        CardType.steal => const Color(0xFF5B4BC4),
        CardType.joker => const Color(0xFF0E9AA7),
        CardType.word => posNeutral,
      };
}
