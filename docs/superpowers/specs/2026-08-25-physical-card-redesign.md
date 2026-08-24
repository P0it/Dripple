# The Dripple Deck — a physical card redesign

**Date:** 2026-08-25
**Supersedes:** design decision 8 of `CLAUDE.md` ("restraint over decoration")
**Status:** approved, implementing

## Why

The board reads as a web page. A card is a white rounded rectangle with a
coloured bar, one soft shadow, and a hairline border — the anatomy of a CSS
`.card`, not of a playing card. Put it beside Google's I/O FLIP, which is
Flutter and Flame like we are, and the gap is not technology. It is that
nothing on our board has a material.

Two decisions were taken with this redesign:

**The audience widened.** Dripple is no longer only for 6-10 year olds. Adults
learning English in other countries are now a first-class audience. This is
load-bearing on the visual direction rather than incidental to it: an object
that an adult reads as a well-made card game is one a child can also enjoy,
while the reverse does not hold. A nursery palette would have closed the door.

**Restraint is repealed, app-wide.** Decision 8 forbade gradients, shadows
outside the card, and anything but a near-white ground. Card-game materiality
is *made of* those things — stock, grain, felt, bevel, contact shadow. The
decision cannot survive the goal, so it goes. What replaces it is not licence
but a narrower rule, below.

## The rule that replaces "restraint"

> **Paper takes the brand. Furniture takes brass.**

Every surface in the app is one of two materials.

- **Paper** — the card face, sheets, dialogs, anything that reads as printed
  stock. Warm off-white, grain, the point blue, the part-of-speech palette,
  ink type. This is where information lives.
- **Furniture** — the table, the hand rail, the sentence well, screen grounds.
  Deep felt green, brass hairlines, cream type. This is where nothing is read,
  only held.

Decoration that does not serve one of these two materials does not ship. A
gradient that describes a lit felt surface is furniture; a gradient on a button
because it looked flat is not. This is a statable line the way the old one was,
and it is the thing to point at in review.

## Palette

Added to `AppColors`. Nothing outside the design package defines a colour, as
before.

### Furniture

| Token | Value | Use |
|---|---|---|
| `feltCore` | `#1C4436` | lit centre of the table |
| `feltEdge` | `#0E2820` | rim, where the radial lands |
| `rail` | `#173C2F` | the hand rail, one step above felt |
| `well` | `#0B211B` | the sentence recess floor |
| `brass` | `#C6A664` | hairlines, labels, frames |
| `brassDim` | `#7E6A42` | inactive brass |
| `onFelt` | `#F2EDE1` | type on furniture |
| `onFeltSoft` | `#9FAFA5` | secondary type on furniture |

### Paper

| Token | Value | Use |
|---|---|---|
| `paper` | `#FBF8F1` | card face, sheets |
| `paperEdge` | `#DED6C6` | the cut edge of the stock, dividers |
| `paperShade` | `#F1EBDE` | pressed / recessed paper |
| `ink` | `#1B1D21` | the word |
| `inkSoft` | `#767B84` | the meaning |

### Repointed existing tokens

`surface` → `paper`. `divider` → `paperEdge`. `textPrimary` → `ink`.
`textSecondary` → `inkSoft`. `background` → `feltCore`. This keeps the eight
screens compiling without a rename sweep; what changes is what the names mean.

`point` (`#1D74F5`) is unchanged and stays the brand. It appears on paper, in
the mark, and as the drag-highlight ring — a blue ring on green felt separates
cleanly, which is the one place blue earns a spot on furniture.

The part-of-speech palette is unchanged. It sits on paper, where it was
already tuned, and it is the one colour system with a learning job.

## The card

### Geometry

Poker proportion, **63:88**. Width stays 84 — that is a board constraint, four
across a 390pt phone — so height becomes **117**, down from 122. The hand gets
slightly shorter, which the two-row layout welcomes.

Corner radius `w * 0.06` ≈ 5, down from `w * 0.14` ≈ 11.8. A real poker card's
corner is about 5.5% of its width. This single number does more to move the
card away from "app chrome" than anything else in this document.

### Anatomy, outside in

1. **Contact shadow** — `Offset(0, 1)`, blur 2.5, `#00000040`. Tight and dark;
   this is the card touching the table.
2. **Ambient shadow** — `Offset(0, 5)`, blur 12, `#00000033`. Wide and soft.
   One shadow floats on a page. Two sit on a surface.
3. **Stock** — the full rrect filled `paperEdge`. What remains visible is a
   sub-pixel rim reading as the cut edge of the card.
4. **Face** — `rrect.deflate(1)` filled `paper`.
5. **Grain** — a procedurally generated noise tile at 5% alpha, clipped to the
   face. Generated once into a `ui.Image` and cached statically; no asset.
6. **Face frame** — `rrect.deflate(w * 0.085)` stroked in the part-of-speech
   accent at 55% alpha, 1px, with a second hairline 2.5px inside at 18%. This
   is where part-of-speech colour now lives. It outlines the whole face, so it
   carries more colour signal than the old 7.5% bar did while looking printed
   rather than applied.
7. **Corner indices** — top-left, and the same rotated 180° at bottom-right.
   The device that lets a fanned hand be read. Each index is a dictionary
   abbreviation (`n. v. adj. adv. pron. art. prep.`) at `w * 0.10` over a
   part-of-speech pip.
8. **Word** — centred, Pretendard w700, `ink`, fitted to `w * 0.30` by the
   existing `fitFontSize` measure-and-shrink.
9. **Dictionary rule** — a `w * 0.22` wide, 1.5px accent line at 35% alpha
   below the word, separating headword from gloss the way a dictionary entry
   does.
10. **Meaning** — the learner's own language, `w * 0.125`, `inkSoft`.

### The pips

The pip returns the Montessori grammar symbols to the card: noun a filled
triangle, verb a circle, preposition a crescent, and so on, in the
part-of-speech colour.

The 2026-08-22 commit removed these deliberately, and this is not a blind
revert. What was removed was a *large* shape occupying a coloured band across
the top of the card, which the commit correctly judged to be a block of colour
with nothing in it. What returns is a 3px suit mark in a corner index. The
semantics were never the problem; the size was.

| Part of speech | Pip |
|---|---|
| noun | filled triangle, wide |
| pronoun | filled triangle, tall |
| adjective | filled triangle, medium |
| article | filled triangle, small |
| verb | filled circle |
| adverb | filled circle, small |
| preposition | crescent |
| none | filled square |

### Card back

Needed for the deck, and for opponent cards later. A deep field
(`point` darkened to `#12385E`), a lattice of small Dripple droplets at 10%
white, a double frame line at 25% and 12% white, and the mark centred in
cream. Exposed as `CardPainter.paintBack`.

### States

- **Dragging** — a `point` ring 2.5px outside the stock, plus lift (below).
- **Discard candidate** — `danger` wash at 16% and a 3px `danger` ring, as
  today, on the new anatomy.
- **Special cards** — the icon sits in the face frame's upper half as a
  medallion; the word moves below it. Special cards take the point-family
  colour as today and carry no pip, since they have no part of speech.

## The table

`DrippleGame.render` stops drawing two flat bands and draws a table.

- **Felt** — `Gradient.radial` from `feltCore` at the board's upper third to
  `feltEdge` at the corners, plus the same noise tile at 6% and a vignette
  radial to `#000000` at 35% on the rim.
- **Sentence well** — a recess, not a target sticker. Floor in `well`, an inner
  shadow along the top edge, a 1px `#FFFFFF` 6% highlight along the bottom
  edge. Brass border: dashed while empty, a solid hairline once occupied.
- **Hand rail** — a raised strip in `rail`, a `#FFFFFF` 8% highlight along its
  top edge and a brass hairline at 35%.

Recess versus rail is a stronger read than the old blue-tint versus white-tray,
and it is the same distinction a real table makes: you put cards *into* the
well, you take them *from* the rail.

- **Labels** — brass and cream, small, letter-spaced 1.2. The drop hint stays,
  in `onFeltSoft`.
- **Piles** — `PileComponent` draws a real stack: four or five backs offset by
  0.6px with a deterministic ±0.6° rotation derived from the index, so a pile
  has thickness and is never identical to a single card.

## Motion

Five changes, in order of how much each is worth.

1. **Perspective tilt on drag.** `CardComponent.render` wraps painting in a
   `Matrix4` with a perspective entry and a Y rotation driven by smoothed drag
   velocity, clamped to ±8°, decaying to zero in `update`. This is the single
   largest "it feels real" win available and costs one matrix.
2. **Lift.** While dragging, a `_lift` value animates 0→1 and drives both scale
   (1.0→1.05) and the shadow parameters, so the shadow spreads and softens as
   the card rises. A card whose shadow does not change while it lifts reads as
   a sticker.
3. **Resting jitter.** Each card takes a deterministic rotation of up to ±1.2°
   from its own id. Cards laid on a table are never in a grid. Cheap, and it
   dismantles the CSS-grid read on its own.
4. **Settle.** `easeOutCubic` at 0.20s, with a 1.03 scale pulse over 0.18s so
   the card lands rather than arrives.
5. **Deal-in and success sweep.** New components enter from the deck's position
   at 0.6 scale. A completed sentence gets a specular band travelling
   left-to-right across the well over 0.5s.

## Screens

The reskin is app-wide, so all eight screens move onto felt.

- A `FeltBackground` widget in the design package paints the radial, grain, and
  vignette; screens wrap their `Scaffold` body in it. `ThemeData` cannot
  express a gradient ground, which is why this is a widget and not a token.
- `AppTheme` moves to a dark scheme: felt scaffold, paper surfaces, `onFelt`
  type, brass dividers.
- Buttons gain a 3px darker bottom edge — a physical key rather than a
  gradient. This is furniture, and it is the one lift a button gets.
- `AppSpacing.minTouch` stays at 56. It was chosen for six-year-olds and it is
  also simply a good number for adults; nothing about widening the audience
  argues for smaller targets. Type sizes on the card come down slightly, which
  is where the adult read is bought.

## Guard test

`test/core/design/no_legacy_theme_test.dart` currently enforces the repealed
decision — no gradient anywhere, no `BoxShadow` outside the card painter. Those
assertions now contradict the design and are replaced by ones that guard the
new rule:

- hex literals stay banned outside the design package and the painters, with
  the painter allow-list extended to the new files;
- gradients and shadows are permitted **only** inside the design package and
  `lib/game/`, so they stay a material decision and never leak into a screen;
- the card's aspect ratio is asserted to be 63:88, because the proportion is
  the thing most likely to drift back;
- the legacy-theme assertions are kept as they were.

## Out of scope

Rive character art, sound, and the deal/flip choreography for opponent hands.
Opponent cards remain the existing bar; only their card backs become real.

## Files

New:
- `lib/core/design/materials.dart` — grain tile, felt painting, shadow specs
- `lib/core/design/felt_background.dart` — the screen ground widget
- `lib/game/pos_pip.dart` — the eight pip shapes

Rewritten:
- `lib/core/design/app_colors.dart`, `app_theme.dart`, `app_typography.dart`
- `lib/game/card_painter.dart`, `lib/game/dripple_game.dart`
- `lib/game/components/card_component.dart`, `pile_component.dart`
- the eight screens and the game sub-widgets, for ground and tone
- `test/core/design/no_legacy_theme_test.dart`
