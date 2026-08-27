import 'package:flutter/material.dart';

import 'package:dripple_rules/models/word_card.dart';

/// Every colour in the app. Nothing outside this file defines one.
///
/// The palette is organised by **material**, not by role, because that is the
/// rule the whole design now runs on:
///
/// > Paper takes the brand. Furniture takes brass.
///
/// **Paper** is the card face, sheets, dialogs — anything that reads as printed
/// stock. Warm off-white, ink type, the point blue, and the part-of-speech
/// palette. Information lives here.
///
/// **Furniture** is the table, the hand rail, the sentence well, screen
/// grounds. Deep felt, brass hairlines, cream type. Nothing is read here, only
/// held.
///
/// Decoration that serves neither material does not ship. A gradient that
/// describes a lit felt surface is furniture; a gradient on a button because it
/// looked flat is not.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Furniture
  // ---------------------------------------------------------------------------

  /// The lit centre of the table.
  static const feltCore = Color(0xFF215442);

  /// The rim, where the table's radial lands.
  static const feltEdge = Color(0xFF0A1F19);

  /// The hand rail — one step above the felt, so cards read as resting on
  /// something raised.
  ///
  /// Lighter than [feltCore], not darker. The rail sits at the bottom of the
  /// screen where the table's radial and vignette are both at their darkest,
  /// so a rail keyed off the felt's *nominal* colour lands below its
  /// surroundings and reads as a second recess.
  static const rail = Color(0xFF2A6350);

  /// The sentence recess floor. Darker than the felt because it is a hole cut
  /// into the table, and that is the whole read.
  static const well = Color(0xFF0B211B);

  /// Hairlines, labels, active rings, the one button on the table.
  ///
  /// This used to be brass, `#C6A664`, and brass is what made the board read
  /// as old — not the green. A hundred-year-old casino table is green *and*
  /// gold, and it was the gold laying a yellow cast over every rule and pill
  /// that dated it.
  ///
  /// What replaced it is not another accent colour but the absence of one.
  /// The trim is the same cream the furniture already sets its type in, so
  /// the only things on this screen holding a colour are the felt itself and
  /// the part-of-speech ticks on the cards — which is exactly the ordering
  /// the game wants, because the cards are what you are meant to read.
  static const trim = Color(0xFFF2EDE1);

  /// Trim at rest: an inactive track, an empty slot's outline. Keyed off the
  /// felt rather than off the cream, so a dim rule reads as unlit table
  /// instead of as dirty paper.
  static const trimDim = Color(0xFF6E8378);

  /// Type on furniture.
  static const onFelt = Color(0xFFF2EDE1);
  static const onFeltSoft = Color(0xFF9FAFA5);

  // ---------------------------------------------------------------------------
  // Paper
  // ---------------------------------------------------------------------------

  /// Card stock. Warm, not pure white — paper never is, and the eye knows.
  static const paper = Color(0xFFFBF8F1);

  /// The cut edge of the stock. Visible as a sub-pixel rim around every card,
  /// which is what gives the card thickness.
  static const paperEdge = Color(0xFFDED6C6);

  /// Pressed or recessed paper.
  static const paperShade = Color(0xFFF1EBDE);

  /// The word.
  static const ink = Color(0xFF1B1D21);

  /// The gloss under the word.
  static const inkSoft = Color(0xFF767B84);

  // ---------------------------------------------------------------------------
  // Repointed role tokens
  // ---------------------------------------------------------------------------
  // The names the screens already import. What changed is what they mean, so
  // the eight screens keep compiling and the redesign lands as a palette swap
  // rather than a rename sweep.

  static const background = feltCore;
  static const surface = paper;
  static const divider = paperEdge;
  static const border = Color(0xFFC9BFA9);
  static const textPrimary = ink;
  static const textSecondary = inkSoft;
  static const textDisabled = Color(0xFFA8A294);

  // ---------------------------------------------------------------------------
  // Brand and status
  // ---------------------------------------------------------------------------

  /// The brand is a water drop, so blue is the thematic choice. It lives on
  /// paper and in the mark. The one place it earns a spot on furniture is the
  /// drag ring — blue separates cleanly from green, which is exactly what a
  /// "this card is in your hand right now" signal needs to do.
  static const point = Color(0xFF1D74F5);
  static const pointPressed = Color(0xFF1662D6);

  /// The brand blue lifted until it reads on green.
  ///
  /// #1D74F5 is tuned for a near-white page; against deep felt it goes muddy —
  /// the two are close in luminance and opposed in hue, which is the one
  /// combination that reads as neither. The mark keeps its identity on the
  /// table by getting brighter, not by changing hue.
  static const pointOnFelt = Color(0xFF5AA9FF);
  static const pointTint = Color(0xFFE7EFFC);

  /// The card back's field: the point blue taken down until white printing
  /// reads cleanly on it.
  static const cardBack = Color(0xFF12385E);

  /// The table seen through a coach mark's cover.
  ///
  /// Deep felt at a little over half, not black. A covered part of the board
  /// has to read as "not needed right now"; blacked out, it reads as gone,
  /// and a child who cannot see the rest of the table cannot tell what the
  /// bright part is part of.
  static const scrim = Color(0x8C08201A);

  static const success = Color(0xFF12B76A);
  static const danger = Color(0xFFE5484D);

  /// A card whose part of speech the deck did not set.
  static const posNeutral = Color(0xFF8A929E);

  /// Montessori grammar colours, desaturated to sit inside the palette.
  /// The semantics are preserved; only the saturation changed.
  static Color forPartOfSpeech(PartOfSpeech? pos) => switch (pos) {
        PartOfSpeech.noun => const Color(0xFF2E3A4F),
        PartOfSpeech.adjective => const Color(0xFF3D5AA8),
        PartOfSpeech.article => const Color(0xFF7FB4D8),
        PartOfSpeech.pronoun => const Color(0xFF7A63D9),
        PartOfSpeech.verb => const Color(0xFFC8413F),
        PartOfSpeech.adverb => const Color(0xFFD07A2E),
        PartOfSpeech.preposition => const Color(0xFF358B5E),
        null => posNeutral,
      };

  /// Special cards read as actions rather than words, so they take the point
  /// colour family instead of the grammar palette.
  static Color specialCard(CardType type) => switch (type) {
        CardType.jump => const Color(0xFF1D74F5),
        CardType.steal => const Color(0xFF5B4BC4),
        CardType.joker => const Color(0xFF0E8E9A),
        CardType.word => posNeutral,
      };

  /// Darkens an accent until it is readable as small type on card stock.
  ///
  /// The part-of-speech palette includes deliberately pale colours — the
  /// article blue is nearly sky — and setting an index or a gloss in one of
  /// those makes it disappear.
  static Color readableOnPaper(Color accent) {
    var out = accent;
    while (out.computeLuminance() > 0.30) {
      out = Color.lerp(out, ink, 0.15)!;
    }
    return out;
  }
}
