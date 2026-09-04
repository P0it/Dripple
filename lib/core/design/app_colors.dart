import 'package:flutter/material.dart';

import 'package:dripple_rules/models/word_card.dart';

/// Every colour in the app. Nothing outside this file defines one.
///
/// The palette is organised by **material**, not by role, because that is the
/// rule the whole design runs on:
///
/// > Two materials: ink and paper.
///
/// **Paper** is the card face and the sheets a player reads. Near-white stock,
/// ink type, the point blue, and the part-of-speech palette. Things are
/// *printed* here.
///
/// **Ink** is the table, the hand rail, the sentence well, screen grounds. The
/// ground, with hairlines and type set against it. Nothing is printed here,
/// only held.
///
/// Decoration serving neither does not ship. A gradient describing a lit
/// surface is material; a gradient on a button because it looked flat is not.
///
/// ## Night and day
///
/// One of those two materials moves and the other does not. The ink is a
/// ground, and a ground is whatever the light in the room makes it — so
/// [AppMode] swaps every token above the Paper heading and nothing below it.
/// A card is printed. Turning a light on does not reprint it.
///
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Ink — the only tokens a mode swap touches
  // ---------------------------------------------------------------------------

  /// The ink, and everything cut out of it.
  ///
  /// These are the only tokens a mode swap touches. Everything printed on a
  /// card — [paper], [ink], the part-of-speech palette — is a `const` below
  /// and stays one, because turning a light on does not reprint a card.
  ///
  /// They are getters over [_ink] rather than constants, because the surfaces
  /// they colour are painted outside the widget tree: Flame components and
  /// `CustomPainter`s cannot reach `Theme.of(context)`. A getter keeps all 177
  /// call sites written exactly as they were.

  /// The table.
  ///
  /// This was green felt, `#215442`, until 2026-09-01. Green felt plus a lit
  /// radial plus a vignette is the description of a casino table, and that is
  /// what it read as — a room the game is not set in, and one no six-year-old
  /// has been in. What it costs to leave: green is the complement of warm
  /// stock, so it flattered the cards more than anything else could.
  ///
  /// What replaces it does the same job by subtraction. A neutral dark holds
  /// no hue at all, so the only colours left on the screen are the ones
  /// printed on the cards — which is a better version of the same idea, and
  /// the version that also stops looking like a card room.
  ///
  /// By day it is the stock itself. A light mode that kept a grey table only
  /// turned the lights half on: the ground has to be as bright as the thing
  /// the player asked for. Cards do not vanish into it, because a card is not
  /// flat — it casts a shadow, and that shadow is what has been separating it
  /// from the ground all along.
  static Color get table => _ink.table;

  /// The rim. Barely off [table]: a ground wants a fall-off, not a vignette.
  /// A vignette is a spotlight, and a spotlight is the casino again.
  static Color get tableEdge => _ink.tableEdge;

  /// The hand rail — one step above the table, so cards read as resting on
  /// something raised.
  ///
  /// Lighter than [table], not darker. A rail keyed to the same value as its
  /// surroundings reads as a second recess rather than as a raised strip —
  /// and it is lighter in *both* modes, because a raised face catches more
  /// light whatever the light is. By day that leaves only white to be lighter
  /// with, which is why the rail is exactly white and nothing else is.
  static Color get rail => _ink.rail;

  /// The sentence recess floor. Darker than the table because it is a hole cut
  /// into it, and that is the whole read — in both modes.
  static Color get well => _ink.well;

  /// Hairlines, labels, active rings, the one button on the table.
  ///
  /// This used to be brass, `#C6A664`, and brass is what made the board read
  /// as old — not the green. A hundred-year-old casino table is green *and*
  /// gold, and it was the gold laying a yellow cast over every rule and pill
  /// that dated it.
  ///
  /// What replaced it is not another accent colour but the absence of one.
  /// The trim is the same value the ink already sets its type in, so the only
  /// things on this screen holding a colour are the ground itself and the
  /// part-of-speech ticks on the cards — which is exactly the ordering the
  /// game wants, because the cards are what you are meant to read.
  static Color get trim => _ink.trim;

  /// Trim at rest: an inactive track, an empty slot's outline. Keyed off the
  /// ground rather than off the type, so a dim rule reads as unlit surface
  /// instead of as dirty paper.
  static Color get trimDim => _ink.trimDim;

  /// Type on the ink. Neutral, because the ground is — the old cream had a
  /// green cast keyed to the felt, and on a hueless ground that read as
  /// stained.
  static Color get onTable => _ink.onTable;
  static Color get onTableSoft => _ink.onTableSoft;

  // ---------------------------------------------------------------------------
  // Paper
  // ---------------------------------------------------------------------------

  /// Card stock.
  ///
  /// This was `#FBF8F1` — a warm cream, on the argument that paper never is
  /// pure white. True of paper in a lit room, and wrong here: the ground went
  /// hueless on 2026-09-01 precisely so the only colours on screen would be
  /// the ones printed on the cards, and a cream card against a hueless ground
  /// reads as a *yellow* card. It was the brass problem again, arriving on the
  /// other material.
  ///
  /// Not pure white either. `#FDFCFA` keeps the barest warmth — enough that
  /// the stock is stock rather than a lit rectangle — while leaving the
  /// part-of-speech ticks the only hue on the card.
  static const paper = Color(0xFFFDFCFA);

  /// The cut edge of the stock. Visible as a sub-pixel rim around every card,
  /// which is what gives the card thickness.
  static const paperEdge = Color(0xFFE3DFD7);

  /// Pressed or recessed paper.
  static const paperShade = Color(0xFFF2F0EB);

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

  static Color get background => table;
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

  /// The brand blue lifted for the table.
  ///
  /// #1D74F5 is tuned for a near-white page and goes dull on a dark ground.
  /// The mark keeps its identity by getting brighter, not by changing hue.
  ///
  /// It carries more than the mark now. On green this blue was a compromise —
  /// blue and green sit at the same luminance in opposed hues, so it could
  /// never be the accent, and brass had the job instead. On a neutral ground
  /// it is finally free to be one: it rings the active player and draws the
  /// clock.
  static Color get pointOnTable => _ink.point;
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
  static Color get scrim => _ink.scrim;

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

  // ---------------------------------------------------------------------------
  // The two grounds
  // ---------------------------------------------------------------------------

  static _Ink _ink = _Ink.night;

  /// Bumped whenever the ground changes.
  ///
  /// A `CustomPainter` is asked `shouldRepaint(old)` and compares its own
  /// fields; none of them mention a colour, so a mode swap would leave every
  /// canvas holding the previous night. Painters carry this number so the
  /// question has an answer.
  static int generation = 0;

  static AppMode get mode => _ink.mode;

  /// Whether the ground is the light one. For the few places that need to
  /// invert a shadow rather than swap a colour.
  static bool get isDay => _ink.mode == AppMode.day;

  static void use(AppMode mode) {
    final next = switch (mode) {
      AppMode.night => _Ink.night,
      AppMode.day => _Ink.day,
    };
    if (identical(next, _ink)) return;
    _ink = next;
    generation++;
  }
}

/// Which ground the app is standing on.
enum AppMode { night, day }

/// One ground, and the values cut out of it.
class _Ink {
  const _Ink({
    required this.mode,
    required this.table,
    required this.tableEdge,
    required this.rail,
    required this.well,
    required this.trim,
    required this.trimDim,
    required this.onTable,
    required this.onTableSoft,
    required this.point,
    required this.scrim,
  });

  final AppMode mode;
  final Color table;
  final Color tableEdge;
  final Color rail;
  final Color well;
  final Color trim;
  final Color trimDim;
  final Color onTable;
  final Color onTableSoft;
  final Color point;
  final Color scrim;

  static const night = _Ink(
    mode: AppMode.night,
    table: Color(0xFF15181C),
    tableEdge: Color(0xFF101317),
    rail: Color(0xFF1D2126),
    well: Color(0xFF0B0E11),
    trim: Color(0xFFEDEBE6),
    trimDim: Color(0xFF464C54),
    onTable: Color(0xFFEDEBE6),
    onTableSoft: Color(0xFF8A9198),
    // #1D74F5 is tuned for a near-white page and goes dull on a dark ground.
    // The blue keeps its identity by getting brighter, not by changing hue.
    point: Color(0xFF5AA9FF),
    scrim: Color(0x8C08201A),
  );

  /// The ground is the stock itself.
  ///
  /// A light mode with a grey table was tried and rejected for being half a
  /// light: the ground has to be as bright as the thing the player asked for.
  /// What was supposed to be lost by making it the same white as a card — the
  /// card no longer reading as an object lying on something — is not lost,
  /// because a card is not flat. It carries two shadows, and the shadow is
  /// what has been separating it from the ground the whole time.
  ///
  /// The scrim inverts with everything else. Dimming means *toward the
  /// ground*, so by day the coach mark's cover is a white veil: the board
  /// fades into the page while the ring and the ink type stay dark on it.
  static const day = _Ink(
    mode: AppMode.day,
    table: Color(0xFFFDFCFA),
    tableEdge: Color(0xFFF1EEE9),
    // The one place white itself is used, and only because a raised face has
    // to be lighter than its ground and the ground has already spent
    // everything else.
    rail: Color(0xFFFFFFFF),
    well: Color(0xFFEDEAE4),
    trim: Color(0xFF24272C),
    trimDim: Color(0xFFD3CEC4),
    onTable: Color(0xFF1B1D21),
    onTableSoft: Color(0xFF6E727A),
    point: Color(0xFF1D74F5),
    scrim: Color(0xC7FDFCFA),
  );
}
