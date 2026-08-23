# Dripple Visual Redesign — Design Spec

**Date:** 2026-08-23
**Status:** Approved, ready for planning

## Problem

Three things are wrong at once, and they share one root.

1. **Sentence-zone cards cannot be reordered by dragging.** The model
   reorders; the screen snaps back. The two disagree permanently.
2. **There is no brand.** No logo asset exists. The home screen renders
   the word "DRIPPLE" in `FontWeight.w900` over a green gradient, and the
   splash screen is Flutter's untouched default.
3. **The visual language reads as a 1990s app.** `app_theme.dart` is 66
   lines; the real styling lives inline across every screen as full-bleed
   green gradients, white `w900` text, and `elevation: 4` drop shadows.

The root is that there is no design system — only a seed colour and a
font, with every screen improvising from there.

## Goals

- Fix the drag reorder so the board matches the model, always.
- Give Dripple an original mark, used consistently across splash, home,
  and app icon.
- Replace the visual language wholesale with a clean, restrained system
  in the vein of modern Korean consumer apps (Toss): near-white ground,
  a neutral grey scale, one point colour, no gradients, no drop shadows,
  hierarchy from weight and whitespace rather than decoration.

## Non-Goals

- Replacing Flame with Flutter widgets. Design decision 6 in `CLAUDE.md`
  stands; the card-game feel is the point.
- Rive character assets. The placeholder is restyled, not replaced.
- Game rules, grammar engine, or AI changes. This is a visual pass; the
  90 existing unit tests must keep passing untouched.
- Firebase, ads, or store submission work.

## Audience Constraint

`CLAUDE.md` targets children aged 6-10. The Toss aesthetic is adult
fintech. Resolution, decided during brainstorming: **keep the Toss
structural language, scale the ergonomics up for children.** Restraint,
palette, and typography come from Toss. Touch targets, font sizes, and
card dimensions are sized for a six-year-old.

| | Adult app | Dripple |
|---|---|---|
| Min touch target | 44 px | **56 px** |
| Primary button height | 48-52 px | **60 px** |
| Body text | 15 px | **16 px** |
| Card size | — | **96 x 132** (from 84 x 116) |

---

## 1. Design System

Replaces `lib/core/theme/app_theme.dart` (66 lines) with `lib/core/design/`.

### Files

```
lib/core/design/
├── app_colors.dart      colour tokens + part-of-speech mapping
├── app_typography.dart   text style scale
├── app_spacing.dart      4pt grid, radii, touch minimums
└── app_theme.dart        assembles ThemeData from the tokens
```

`lib/core/theme/app_theme.dart` is deleted. Every import of `AppColors`
or `AppTheme` is repointed.

### Colour

One point colour. No gradients anywhere in the app.

```
background   #F7F8FA
surface      #FFFFFF
divider      #EEF0F3
border       #D9DDE3

textPrimary  #17181C
textSecondary #6B7684
textDisabled #9AA1AC

point        #1D74F5
pointPressed #1662D6
pointTint    #EAF2FE

success      #12B76A
danger       #E5484D
```

Blue is thematically correct — the brand is a water drop. `greenGradient`
and the entire `AppColors` green family are removed.

### Part-of-Speech Colours

`WordCard.posColor` and `WordCard.posShape` currently live on the model,
which means the data layer holds UI constants. They move to
`AppColors.forPartOfSpeech(...)` in the design package. The model exposes
part of speech only.

Montessori semantics are preserved — a child learns that nouns and verbs
are consistently different — but saturation drops to sit inside the new
palette:

| Part of speech | Current | New |
|---|---|---|
| noun | `#1F2937` | `#2E3A4F` |
| adjective | `#1E3A8A` | `#3D5AA8` |
| article | `#7DD3FC` | `#8FC5E8` |
| pronoun | `#7C3AED` | `#7A63D9` |
| verb | `#DC2626` | `#D14A4E` |
| adverb | `#F97316` | `#E08A42` |
| preposition | `#16A34A` | `#3F9E6B` |
| other | `#6B7280` | `#8A929E` |

Special cards (`JOKER` / `JUMP` / `STEAL`) take the point colour family
rather than the current yellow/red/purple trio.

### Typography

Nunito is dropped. **Pretendard** replaces it: Korean, English, and
numerals render at uniform weight and rhythm in a single family, which is
half of what makes the target aesthetic read as clean. Bundled as an
asset (not `google_fonts`) so the first frame never falls back.

Three weights only. `w900` is banned.

```
display  32 / w700
title    24 / w700
heading  20 / w700
body     16 / w400
label    15 / w600   buttons, emphasis
caption  13 / w400
```

### Spacing, Shape, Elevation

- 4pt grid: `xs 4, sm 8, md 16, lg 24, xl 32, xxl 48`
- Radii, three values: `sm 12` (chips, small cells), `md 16` (buttons,
  cards), `lg 24` (bottom sheets)
- **No shadows.** `elevation: 0` everywhere; separation comes from a 1px
  `divider` border or a `background`/`surface` contrast step. The one
  exception is the Flame card art, where a soft shadow reads as physical
  card stock rather than as UI chrome.

---

## 2. Brand Mark and Splash

### The Mark

"Dripple" reads as drip + ripple — a drop landing and spreading. The mark
is that, and it doubles as the product metaphor: a word lands, a sentence
spreads out from it.

```
      ●        drop    (point colour, solid)
   ⌒─────⌒     ripple 1 (point @ 30%)
 ⌒─────────⌒   ripple 2 (point @ 15%)
```

`lib/core/brand/dripple_mark.dart` — a single `CustomPainter`-backed
widget, no raster asset, so it is crisp at any size.

```dart
DrippleMark({ double size, Animation<double>? animation })
```

One widget serves both the static mark (home header, app bar, result
screen) and the animated splash. With `animation == null` it paints the
resting state.

### Splash Screen

A new `SplashScreen` takes route `/`; the home screen moves to `/home`.

```
0.0s   white
0.2s   drop falls from above, bounces on landing
0.5s   two ripples expand outward in sequence and fade
0.9s   "Dripple" wordmark fades in, rising 8px
1.4s   fade to /home
```

Total 1.4s. The route redirects immediately if the animation is skipped
by a tap, so the splash is never a wall.

### Native Splash

`android/app/src/main/res/drawable*/launch_background.xml` and iOS
`Runner/Assets.xcassets/LaunchImage.imageset` become a white ground with
the mark centred, so there is no flash between the OS splash and the
Flutter one. The mark is baked to PNG once at 1x/2x/3x for this purpose
only; in-app rendering stays vector.

The app icon uses the same mark on the point colour.

---

## 3. Drag Reorder Fix

`lib/game/components/card_component.dart` — the defect, precisely:

```
onDragEnd()
  1. onDragEnded?.call(...)        -> reorderSentence() updates Riverpod   OK
  2. add(MoveEffect.to(_originalPosition))   <-- unconditional snap-back
  3. game_screen's postFrameCallback -> updateSentenceZone()
                                     -> comp.position = targetPos
  4. the effect from (2) is still running and overwrites position each
     tick, landing the card back in its pre-drag slot                      BUG
```

Because the model did change, the next `updateSentenceZone` sees an equal
list, returns early at `_listsEqual`, and never corrects the view. The
board and the model stay out of sync for the rest of the game.

### Fix

**a.** `onDragEnded` returns `bool` — did the drop change anything? The
snap-back becomes conditional:

```dart
final handled = onDragEnded?.call(this, position.clone()) ?? false;
if (!handled) {
  add(MoveEffect.to(_originalPosition, EffectController(
      duration: 0.15, curve: Curves.easeOut)));
}
```

**b.** In `dripple_game.dart`, `_diffUpdateComponents` stops assigning
`comp.position = targetPos` directly and animates instead:

```dart
comp.add(MoveEffect.to(targetPos, EffectController(
    duration: 0.18, curve: Curves.easeOutCubic)));
```

This fixes the race and makes cards glide into place, which suits the new
visual tone. Any in-flight `MoveEffect` on the component is removed first
so two effects never fight.

**c.** A component with `isDragging == true` is skipped by
`_diffUpdateComponents` — the finger owns its position while it is down.

---

## 4. Screen Work

`lib/game/card_painter.dart` already exists with a `band` style close to
the target; card art is a retune to the new tokens, not a rewrite.

| Screen | Work |
|---|---|
| **Splash** | New. Section 2. |
| **Home** | Gradient out. White ground, mark, wordmark, one-line description, solid CTA, text links for secondary nav. |
| **ModeSelect** | Green cards become white list cells; selection is a point-colour border, not a fill. |
| **Game** | Status bar rebuilt; Flame background to `#F7F8FA`; action buttons retyped. Rendering split out of the 740-line `game_screen.dart` into `screens/game/` widgets — **state logic untouched**. |
| **CardPainter** | Retune `band` to new tokens: flat fill, hairline border, larger word, part-of-speech label instead of the Montessori shape. |
| **Judgment** | Dialog becomes a bottom sheet; colour plus one line of text replaces the tick/cross. |
| **Result** | White ground, ranking as a list. |
| **Lobby / Settings** | Unified list cells and toggles. Missing settings l10n strings filled in. |
| **SpecialCardSheet / EmoteBar** | New tokens applied. |
| **CharacterWidget** | Emoji placeholder restyled as a minimal face drawn in the same visual language as the mark. Rive remains future work. |

---

## Testing

The 90 existing tests cover the grammar engine and game logic. This is a
visual pass; they must keep passing without modification. That is the
primary regression signal.

New tests:

- `CardRowLayout` index arithmetic — `indexAtX` round-trips against
  `startX`/`step` for hands of 1 to 12 cards, at several screen widths.
  This is the arithmetic the drag order depends on.
- **Reorder regression test** — drive `DrippleGame` through a drag that
  changes order, then assert the component's effect target matches the
  new slot rather than the original position. This is the test that would
  have caught the bug.
- `AppColors.forPartOfSpeech` returns a distinct colour per part of
  speech (guards against a copy-paste collision in the mapping table).

Not tested: design token values, widget snapshots. They cost maintenance
and catch nothing that looking at the screen would not.

## Risks

- **`game_screen.dart` is 740 lines.** Splitting rendering out while
  leaving state logic alone is the riskiest edit in this spec. Mitigated
  by moving widgets only — no provider or lifecycle changes — and by the
  existing game-logic tests.
- **Pretendard bundle size.** Two weights subset for Korean adds roughly
  1-2 MB. Acceptable; the alternative is a first-frame font swap.
- **Blue point colour resembles Toss's own.** Any blue would. This is the
  requested aesthetic, and the mark, typography, and layout are original.
