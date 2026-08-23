# Dripple Visual Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Dripple's ad-hoc green-gradient styling with a token-driven
design system, give it an original brand mark and splash, and fix the
sentence-zone drag reorder that snaps cards back to their old slot.

**Architecture:** A new `lib/core/design/` token package (colour, typography,
spacing) is the single source of truth; `ThemeData` is assembled from it and
every screen is migrated off inline styling. The old
`lib/core/theme/app_theme.dart` becomes a deprecated shim during the migration
so the app compiles at every commit, and is deleted in the final task. The
brand mark is a `CustomPainter` — no raster asset — reused by the splash, home
header, and app icon. The drag fix makes snap-back conditional and turns
layout repositioning into an animation, which removes the race between the two.

**Tech Stack:** Flutter 3.x / Dart, Flame 1.23 (game board), Riverpod 2.6
(state), GoRouter 14.8 (routing), Pretendard (bundled font).

**Spec:** `docs/superpowers/specs/2026-08-23-dripple-visual-redesign-design.md`

## Global Constraints

- **The 90 existing tests must pass unmodified after every task.** They cover
  the grammar engine, game logic, and card row layout. This is a visual pass;
  if a change to game logic seems necessary, stop and ask.
- **No gradients anywhere.** `AppTheme.greenGradient` and the whole green
  family are removed.
- **No shadows in Flutter widgets.** `elevation: 0` everywhere. Separation
  comes from a 1px `#EEF0F3` border or a `#F7F8FA`/`#FFFFFF` contrast step.
  The single exception is `CardPainter`, where a soft shadow reads as physical
  card stock.
- **Font weights: `w400`, `w600`, `w700` only.** `w800` and `w900` are banned,
  including inside `CardPainter`.
- **Radii: 12, 16, 24 only.**
- **Touch targets: minimum 56px. Primary buttons 60px tall.** The audience is
  6-10 year olds.
- **Point colour `#1D74F5`.** Exactly one accent colour in the UI chrome.
  Part-of-speech colours on cards are a separate, deliberate palette.
- Run `flutter analyze` before every commit; it must be clean.
- Flutter may not be on PATH. If `flutter` is not found, run
  `export PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH"`
  and prefix commands with `FLUTTER_ALLOW_ROOT=true`.

---

### Task 1: Design token package

Creates the token package and bundles Pretendard. The old theme file becomes a
shim that forwards to the new tokens, so the app keeps compiling while later
tasks migrate screens one at a time.

**Files:**
- Create: `lib/core/design/app_colors.dart`
- Create: `lib/core/design/app_typography.dart`
- Create: `lib/core/design/app_spacing.dart`
- Create: `lib/core/design/app_theme.dart`
- Create: `assets/fonts/Pretendard-Regular.ttf`, `-SemiBold.ttf`, `-Bold.ttf`
- Modify: `pubspec.yaml` (add font declarations, drop `google_fonts`)
- Modify: `lib/core/theme/app_theme.dart` (becomes a deprecated shim)
- Modify: `lib/app.dart:81` (`theme: AppTheme.lightTheme` repointed)
- Test: `test/core/design/app_colors_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `AppColors.background/surface/divider/border` → `Color`
  - `AppColors.textPrimary/textSecondary/textDisabled` → `Color`
  - `AppColors.point/pointPressed/pointTint` → `Color`
  - `AppColors.success/danger` → `Color`
  - `AppColors.forPartOfSpeech(PartOfSpeech pos)` → `Color`
  - `AppColors.specialCard(CardType type)` → `Color`
  - `AppTypography.display/title/heading/body/label/caption` → `TextStyle`
  - `AppSpacing.xs/sm/md/lg/xl/xxl` → `double` (4/8/16/24/32/48)
  - `AppSpacing.radiusSm/radiusMd/radiusLg` → `double` (12/16/24)
  - `AppSpacing.minTouch` → `double` (56), `AppSpacing.buttonHeight` → `double` (60)
  - `AppTheme.light` → `ThemeData`

- [ ] **Step 1: Download and install the font**

```bash
cd /Users/pluto/orca/Dripple
mkdir -p assets/fonts
TMP=$(mktemp -d)
curl -sL -o "$TMP/pretendard.zip" \
  https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip
unzip -j -o "$TMP/pretendard.zip" \
  'public/static/alternative/Pretendard-Regular.ttf' \
  'public/static/alternative/Pretendard-SemiBold.ttf' \
  'public/static/alternative/Pretendard-Bold.ttf' \
  -d assets/fonts/
rm -rf "$TMP"
ls -la assets/fonts/
```

Expected: three `.ttf` files, roughly 2.7 MB each.

Note: the `alternative` variant is the one whose vertical metrics match
Flutter's line-height model. Do not substitute `public/static/Pretendard-*.ttf`.

- [ ] **Step 2: Declare the font and drop google_fonts in `pubspec.yaml`**

Remove the `google_fonts: ^6.2.1` line from `dependencies`.

Under `flutter:`, add `assets/fonts/` to the existing `assets:` list and add a
`fonts:` block:

```yaml
flutter:
  generate: true
  uses-material-design: true

  assets:
    - assets/sounds/
    - assets/music/
    - assets/fonts/

  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/Pretendard-Regular.ttf
          weight: 400
        - asset: assets/fonts/Pretendard-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Pretendard-Bold.ttf
          weight: 700
```

Then run `flutter pub get`.

- [ ] **Step 3: Write the failing test**

Create `test/core/design/app_colors_test.dart`:

```dart
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

    test('is stable across calls', () {
      expect(
        AppColors.forPartOfSpeech(PartOfSpeech.noun),
        AppColors.forPartOfSpeech(PartOfSpeech.noun),
      );
    });
  });

  group('AppColors.specialCard', () {
    test('gives each special card its own colour', () {
      final special = [CardType.jump, CardType.steal, CardType.joker];
      final colours = special.map(AppColors.specialCard).toSet();
      expect(colours.length, special.length);
    });
  });
}
```

If `PartOfSpeech` is not the enum name in `lib/models/word_card.dart`, read
that file and use the actual name — do not invent one.

- [ ] **Step 4: Run the test to verify it fails**

Run: `flutter test test/core/design/app_colors_test.dart`
Expected: FAIL — `app_colors.dart` does not exist.

- [ ] **Step 5: Write `lib/core/design/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

import '../../models/word_card.dart';

/// Every colour in the app. Nothing outside this file defines one.
///
/// One accent colour carries the UI. The part-of-speech palette below is a
/// separate, deliberate exception: a child learns word order partly by
/// noticing that nouns and verbs are consistently different colours.
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

  /// Montessori grammar colours, desaturated to sit inside the palette.
  /// The semantics are preserved; only the saturation changed.
  static Color forPartOfSpeech(PartOfSpeech pos) => switch (pos) {
        PartOfSpeech.noun => const Color(0xFF2E3A4F),
        PartOfSpeech.adjective => const Color(0xFF3D5AA8),
        PartOfSpeech.article => const Color(0xFF8FC5E8),
        PartOfSpeech.pronoun => const Color(0xFF7A63D9),
        PartOfSpeech.verb => const Color(0xFFD14A4E),
        PartOfSpeech.adverb => const Color(0xFFE08A42),
        PartOfSpeech.preposition => const Color(0xFF3F9E6B),
        _ => const Color(0xFF8A929E),
      };

  /// Special cards read as UI actions rather than words, so they take the
  /// point colour family instead of the grammar palette.
  static Color specialCard(CardType type) => switch (type) {
        CardType.jump => const Color(0xFF1D74F5),
        CardType.steal => const Color(0xFF5B4BC4),
        CardType.joker => const Color(0xFF0E9AA7),
        CardType.word => textSecondary,
      };
}
```

Adjust the `switch` arms to the real enum members in
`lib/models/word_card.dart`. Every member must be covered and every colour
must be distinct — that is what the test checks.

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/core/design/app_colors_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 7: Write `lib/core/design/app_spacing.dart`**

```dart
/// The 4pt grid, the three radii, and the touch minimums.
///
/// Touch targets are larger than an adult app's because the audience is
/// 6-10 year olds.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;

  static const double minTouch = 56;
  static const double buttonHeight = 60;
}
```

- [ ] **Step 8: Write `lib/core/design/app_typography.dart`**

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The type scale. Three weights, six sizes, nothing else.
///
/// Pretendard is bundled rather than fetched so the first frame never shows a
/// fallback face. Korean, Latin, and numerals share one family, which is half
/// of what makes the layout read as tidy.
abstract final class AppTypography {
  static const String family = 'Pretendard';

  static const display = TextStyle(
      fontFamily: family, fontSize: 32, fontWeight: FontWeight.w700,
      height: 1.3, color: AppColors.textPrimary);
  static const title = TextStyle(
      fontFamily: family, fontSize: 24, fontWeight: FontWeight.w700,
      height: 1.35, color: AppColors.textPrimary);
  static const heading = TextStyle(
      fontFamily: family, fontSize: 20, fontWeight: FontWeight.w700,
      height: 1.4, color: AppColors.textPrimary);
  static const body = TextStyle(
      fontFamily: family, fontSize: 16, fontWeight: FontWeight.w400,
      height: 1.5, color: AppColors.textPrimary);
  static const label = TextStyle(
      fontFamily: family, fontSize: 15, fontWeight: FontWeight.w600,
      height: 1.4, color: AppColors.textPrimary);
  static const caption = TextStyle(
      fontFamily: family, fontSize: 13, fontWeight: FontWeight.w400,
      height: 1.4, color: AppColors.textSecondary);
}
```

- [ ] **Step 9: Write `lib/core/design/app_theme.dart`**

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles [ThemeData] from the tokens. No colour or size is invented here.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.family,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.point,
          onPrimary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.danger,
        ),
        dividerColor: AppColors.divider,
        textTheme: const TextTheme(
          displaySmall: AppTypography.display,
          titleLarge: AppTypography.title,
          titleMedium: AppTypography.heading,
          bodyLarge: AppTypography.body,
          labelLarge: AppTypography.label,
          bodySmall: AppTypography.caption,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.point,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.divider,
            disabledForegroundColor: AppColors.textDisabled,
            minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
            elevation: 0,
            shadowColor: Colors.transparent,
            textStyle: AppTypography.label.copyWith(fontSize: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
            textStyle: AppTypography.label,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.point
                  : AppColors.border),
          trackOutlineColor:
              const WidgetStatePropertyAll(Colors.transparent),
        ),
      );
}
```

- [ ] **Step 10: Turn the old theme file into a shim**

Replace the entire contents of `lib/core/theme/app_theme.dart` with:

```dart
/// Deprecated. Kept only so screens still compile while they are migrated
/// to `lib/core/design/`. Delete once no screen imports it (see Task 10).
@Deprecated('Import package:dripple/core/design/app_colors.dart instead')
library;

export '../design/app_colors.dart';
export '../design/app_spacing.dart';
export '../design/app_theme.dart';
export '../design/app_typography.dart';
```

The old names `AppColors.primary`, `AppColors.textOnPrimary`,
`AppColors.correctGreen`, `AppColors.cardSkip`, `AppTheme.greenGradient`, and
`AppTheme.lightTheme` no longer exist, so screens referencing them will not
compile. Fix each reference with the mechanical mapping below — this is
mapping, not redesign; the redesign of each screen happens in its own task.

| Old | New |
|---|---|
| `AppColors.primary` | `AppColors.point` |
| `AppColors.primaryDark` | `AppColors.pointPressed` |
| `AppColors.primaryLight` | `AppColors.pointTint` |
| `AppColors.textOnPrimary` | `Colors.white` |
| `AppColors.correctGreen` | `AppColors.success` |
| `AppColors.incorrectRed` | `AppColors.danger` |
| `AppColors.cardNormal` | `AppColors.surface` |
| `AppColors.cardSkip/cardSteal/cardJoker` | `AppColors.specialCard(type)` |
| `AppColors.cardUndo` | `AppColors.point` |
| `AppTheme.lightTheme` | `AppTheme.light` |
| `AppTheme.greenGradient` | delete the `BoxDecoration`; use `color: AppColors.background` |

- [ ] **Step 11: Repoint the app**

In `lib/app.dart`, change the import from `core/theme/app_theme.dart` to
`core/design/app_theme.dart` and `theme: AppTheme.lightTheme` to
`theme: AppTheme.light`.

- [ ] **Step 12: Make the whole project compile**

Run: `flutter analyze`
Fix every error using the mapping table in Step 10. Files that will need it:
`lib/screens/settings_screen.dart`, `mode_selection_screen.dart`,
`judgment_screen.dart`, `home_screen.dart`, `lobby_screen.dart`,
`game_screen.dart`, `result_screen.dart`, `lib/character/emote_bar.dart`.
Expected when done: `No issues found!`

- [ ] **Step 13: Run the full suite**

Run: `flutter test`
Expected: all tests pass — the 90 existing plus the 3 new ones.

- [ ] **Step 14: Commit**

```bash
git add -A
git commit -m "feat: add the design token package and bundle Pretendard

One accent colour, a three-weight type scale, a 4pt grid, and no shadows.
The old theme file becomes a shim so screens can migrate one at a time."
```

---

### Task 2: Fix the sentence-zone drag reorder

The highest-value fix in the plan and fully independent of the visual work.

**The defect.** `CardComponent.onDragEnd` fires the drop callback — which does
reorder the Riverpod state — and then *unconditionally* adds a `MoveEffect`
back to `_originalPosition`. One frame later `updateSentenceZone` assigns
`comp.position = targetPos`, but the effect is still running and overwrites
`position` on every tick, landing the card in its pre-drag slot. Because the
model *did* change, the next `updateSentenceZone` sees an equal list and
returns early at `_listsEqual`, so the view is never corrected. Board and model
stay out of sync for the rest of the game.

**Files:**
- Modify: `lib/game/components/card_component.dart:21-22,77-90`
- Modify: `lib/game/dripple_game.dart` (`_diffUpdateComponents`)
- Test: `test/game/dripple_game_reorder_test.dart`

**Interfaces:**
- Consumes: `CardRowLayout.positions(double screenWidth, int count, double centerY)` → `List<Offset>` (already exists)
- Produces:
  - `CardComponent.onDragEnded` changes type to
    `bool Function(CardComponent component, Vector2 dropPosition)?` — the
    return value means "the drop changed something, do not snap back".
  - `CardComponent.isSettling` → `bool`, true while a layout move is animating.

- [ ] **Step 1: Write the failing test**

Create `test/game/dripple_game_reorder_test.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/game/card_row_layout.dart';
import 'package:dripple/game/dripple_game.dart';
import 'package:dripple/models/word_card.dart';

/// Two cards is the smallest hand that can be reordered.
List<WordCard> _twoCards() => [
      const WordCard(id: 'a', word: 'cats', type: CardType.word),
      const WordCard(id: 'b', word: 'run', type: CardType.word),
    ];

void main() {
  testWithGame<DrippleGame>(
    'a card dropped on the other slot ends up in that slot',
    DrippleGame.new,
    (game) async {
      game.onSentenceReorder = (from, to) {
        final cards = List<WordCard>.from(game.debugSentenceZone);
        final moved = cards.removeAt(from);
        cards.insert(to, moved);
        game.updateSentenceZone(cards);
      };

      game.updateSentenceZone(_twoCards());
      await game.ready();

      final slots = CardRowLayout.positions(
          game.size.x, 2, game.size.y * 0.30);

      final first = game.debugSentenceComponents
          .firstWhere((c) => c.card.id == 'a');

      // Drag card 'a' onto slot 1 and release.
      first.position = Vector2(slots[1].dx, slots[1].dy);
      first.onDragEnded?.call(first, first.position.clone());

      // Let the settle animation finish.
      game.update(0.5);
      await game.ready();

      expect(game.debugSentenceZone.map((c) => c.id).toList(), ['b', 'a']);
      expect(first.position.x, closeTo(slots[1].dx, 1.0));
      expect(first.position.y, closeTo(slots[1].dy, 1.0));
    },
  );

  testWithGame<DrippleGame>(
    'a card dropped back on its own slot returns to where it started',
    DrippleGame.new,
    (game) async {
      var reorderCalls = 0;
      game.onSentenceReorder = (_, __) => reorderCalls++;

      game.updateSentenceZone(_twoCards());
      await game.ready();

      final first = game.debugSentenceComponents
          .firstWhere((c) => c.card.id == 'a');
      final home = first.position.clone();

      // Nudge it a few pixels — not far enough to change slot — and release.
      first.position = home + Vector2(6, 4);
      first.onDragEnded?.call(first, first.position.clone());

      game.update(0.5);
      await game.ready();

      expect(reorderCalls, 0);
      expect(first.position.x, closeTo(home.x, 1.0));
      expect(first.position.y, closeTo(home.y, 1.0));
    },
  );
}
```

The `WordCard` constructor call must match the real one in
`lib/models/word_card.dart` — read it and pass whatever fields are required.

`debugSentenceZone` and `debugSentenceComponents` do not exist yet; add them in
Step 3 as `@visibleForTesting` getters over the existing private fields.

- [ ] **Step 2: Add the test dependency and run the test to verify it fails**

`flame_test` is not yet a dependency. Add it:

```bash
flutter pub add --dev flame_test
```

Run: `flutter test test/game/dripple_game_reorder_test.dart`
Expected: FAIL — `debugSentenceZone` is not defined. After Step 3 exposes the
getters but before Step 4, the first test fails on the position assertion,
which is the actual bug.

- [ ] **Step 3: Expose the test seams in `lib/game/dripple_game.dart`**

Add near the other getters:

```dart
  @visibleForTesting
  List<WordCard> get debugSentenceZone => List.unmodifiable(_sentenceZone);

  @visibleForTesting
  List<CardComponent> get debugSentenceComponents =>
      List.unmodifiable(_sentenceComponents);

  @visibleForTesting
  List<CardComponent> get debugHandComponents =>
      List.unmodifiable(_handComponents);
```

This needs `import 'package:flutter/foundation.dart' show visibleForTesting;`
— the file already imports `package:flutter/material.dart as material`, so
either use `material.visibleForTesting` or add the explicit import.

- [ ] **Step 4: Make the snap-back conditional in `card_component.dart`**

Change the field type:

```dart
  /// Fires when a drag finishes, with the component's dropped position.
  /// The parent decides what the drop meant and returns true if it acted on
  /// it — a handled drop must not snap back, because the parent is about to
  /// move the card somewhere new.
  final bool Function(CardComponent component, Vector2 dropPosition)?
      onDragEnded;
```

Replace `onDragEnd`:

```dart
  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    priority = _restingPriority;

    final handled = onDragEnded?.call(this, position.clone()) ?? false;
    if (handled) return; // the parent will settle us into the new slot

    settleTo(_originalPosition);
  }

  /// Animates the card into [target], cancelling any settle already running so
  /// two effects never fight over `position`.
  void settleTo(Vector2 target) {
    children.whereType<MoveEffect>().forEach((e) => e.removeFromParent());
    isSettling = true;
    add(MoveEffect.to(
      target,
      EffectController(duration: 0.18, curve: material.Curves.easeOutCubic),
      onComplete: () => isSettling = false,
    ));
  }

  /// True while a settle animation owns `position`.
  bool isSettling = false;
```

- [ ] **Step 5: Return `bool` from every drop handler in `dripple_game.dart`**

In `_diffUpdateComponents`, the `onDragEnded` closure must return `true` when
it acted and `false` otherwise:

```dart
          onDragEnded: (component, dropPosition) {
            if (isSentenceZone) {
              final from = _sentenceZone.indexWhere((c) => c.id == cardId);
              if (from < 0) return false;
              // Dragged clear of the zone — send it back to hand.
              final zoneReach =
                  CardRowLayout.blockHeight(size.x, _sentenceZone.length) / 2 +
                      CardComponent.cardHeight * 0.6;
              if ((dropPosition.y - _sentenceZoneY).abs() > zoneReach) {
                onSentenceRemove?.call(from);
                return true;
              }
              final to = CardRowLayout.indexAt(
                ui.Offset(dropPosition.x, dropPosition.y),
                size.x,
                _sentenceZone.length,
                _sentenceZoneY,
              );
              if (to == from) return false;
              onSentenceReorder?.call(from, to);
              return true;
            }
            // Hand card lifted toward the sentence zone.
            final handReach =
                CardRowLayout.blockHeight(size.x, _hand.length) / 2;
            if (dropPosition.y < _handY - handReach) {
              final idx = _hand.indexWhere((c) => c.id == cardId);
              if (idx >= 0) {
                onCardPlaced?.call(idx);
                return true;
              }
            }
            return false;
          },
```

- [ ] **Step 6: Animate repositioning instead of assigning it**

Still in `_diffUpdateComponents`, replace the existing-card branch:

```dart
      if (existingMap.containsKey(card.id)) {
        final comp = existingMap[card.id]!;
        // A card under the finger owns its own position.
        if (!comp.isDragging) comp.settleTo(targetPos);
        comp.priority = i;
        comp.markedForDiscard = !isSentenceZone && _discardMode;
        updatedComponents.add(comp);
      } else {
```

New components still take `position: targetPos` directly — there is nowhere to
animate from.

- [ ] **Step 7: Run the reorder test to verify it passes**

Run: `flutter test test/game/dripple_game_reorder_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 8: Run the full suite and analyze**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

If `game_screen.dart` fails to compile because its `onDragEnded` assignment now
returns `void`, that is expected — `dripple_game.dart` owns those closures, so
no screen change should be needed. If a screen does assign one, make it return
`bool`.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "fix: sentence-zone cards now stay where they are dropped

onDragEnd added an unconditional snap-back MoveEffect that kept running
after the state update repositioned the card, so it animated back to the
pre-drag slot while the model held the new order. The two never
reconciled, because the next update saw an unchanged list.

Snap-back is now conditional on the drop being unhandled, and layout
repositioning animates through the same settle path so only one effect
ever owns position."
```

---

### Task 3: Brand mark

**Files:**
- Create: `lib/core/brand/dripple_mark.dart`
- Test: `test/core/brand/dripple_mark_test.dart`

**Interfaces:**
- Consumes: `AppColors.point` from Task 1.
- Produces:
  - `DrippleMark({double size, Animation<double>? animation, Color? color})` — a `StatelessWidget`. With `animation == null` it paints the resting state.
  - `DrippleMarkPainter({required double progress, required Color color})` — a `CustomPainter`, exposed so the app-icon bake script can use it.

The mark is a drop over two ripples — "Dripple" reads as drip + ripple, and it
doubles as the product metaphor: a word lands, a sentence spreads from it.

```
      ●        drop     point colour, solid
   ⌒─────⌒     ripple 1 point @ 30%
 ⌒─────────⌒   ripple 2 point @ 15%
```

The `progress` parameter drives the splash: 0 is the drop suspended above,
0.45 is impact, 1.0 is ripples fully spread and faded.

- [ ] **Step 1: Write the failing test**

Create `test/core/brand/dripple_mark_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/core/brand/dripple_mark.dart';

void main() {
  testWidgets('renders at the requested size', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: DrippleMark(size: 96)),
    ));
    expect(find.byType(DrippleMark), findsOneWidget);
    expect(tester.getSize(find.byType(CustomPaint).first).width, 96);
  });

  test('repaints only when progress or colour changes', () {
    const a = DrippleMarkPainter(progress: 0.5, color: Color(0xFF1D74F5));
    const b = DrippleMarkPainter(progress: 0.5, color: Color(0xFF1D74F5));
    const c = DrippleMarkPainter(progress: 0.9, color: Color(0xFF1D74F5));
    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
  });

  testWidgets('paints without throwing across the whole progress range',
      (tester) async {
    for (final p in [0.0, 0.25, 0.45, 0.7, 1.0]) {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: CustomPaint(
            size: const Size(120, 120),
            painter: DrippleMarkPainter(
                progress: p, color: const Color(0xFF1D74F5)),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/brand/dripple_mark_test.dart`
Expected: FAIL — `dripple_mark.dart` does not exist.

- [ ] **Step 3: Write `lib/core/brand/dripple_mark.dart`**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/app_colors.dart';

/// The Dripple mark: a drop landing, two ripples spreading.
///
/// "Dripple" reads as drip + ripple, and the image doubles as the product
/// metaphor — a word lands, a sentence spreads out from it.
///
/// Drawn rather than bundled so it is crisp at every size, from a 16px
/// favicon to a full-screen splash.
class DrippleMark extends StatelessWidget {
  const DrippleMark({
    super.key,
    this.size = 72,
    this.animation,
    this.color,
  });

  final double size;

  /// Drives the drop-and-spread. Null paints the resting state.
  final Animation<double>? animation;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final paintColor = color ?? AppColors.point;
    final anim = animation;

    if (anim == null) {
      return CustomPaint(
        size: Size.square(size),
        painter: DrippleMarkPainter(progress: 1, color: paintColor),
      );
    }

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => CustomPaint(
        size: Size.square(size),
        painter:
            DrippleMarkPainter(progress: anim.value, color: paintColor),
      ),
    );
  }
}

/// Paints the mark at a point in its fall.
///
/// [progress] 0 holds the drop above the surface, 0.45 is impact, 1 is fully
/// spread. Exposed so the app-icon bake can reuse the exact geometry.
class DrippleMarkPainter extends CustomPainter {
  const DrippleMarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  /// Where the drop rests, as a fraction of height.
  static const double _restY = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final t = progress.clamp(0.0, 1.0);

    // Fall: eased descent from above the canvas to the resting height.
    const impact = 0.45;
    final fall = (t / impact).clamp(0.0, 1.0);
    final eased = Curves.easeInCubic.transform(fall);
    final dropY = h * (_restY - 0.5) + h * 0.5 * eased + h * _restY * 0 +
        (h * -0.45) * (1 - eased);

    // Squash on impact, recovering over the next fifth of the timeline.
    final sinceImpact = ((t - impact) / 0.2).clamp(0.0, 1.0);
    final squash = 1 - 0.28 * math.sin(sinceImpact * math.pi);

    _ripples(canvas, size, cx, h * _restY, t);

    final r = w * 0.13;
    canvas.save();
    canvas.translate(cx, dropY);
    canvas.scale(1 / squash, squash);
    canvas.drawPath(_dropPath(r), Paint()..color = color);
    canvas.restore();
  }

  /// A teardrop: round bottom, pointed top.
  Path _dropPath(double r) => Path()
    ..moveTo(0, -r * 1.9)
    ..cubicTo(r * 0.95, -r * 0.5, r, r * 0.25, 0, r)
    ..cubicTo(-r, r * 0.25, -r * 0.95, -r * 0.5, 0, -r * 1.9)
    ..close();

  void _ripples(
      Canvas canvas, Size size, double cx, double cy, double t) {
    const impact = 0.45;
    if (t <= impact) return;

    final spread = ((t - impact) / (1 - impact)).clamp(0.0, 1.0);

    // Two arcs, the outer one lagging the inner one.
    _ripple(canvas, size, cx, cy, spread, delay: 0.0, alpha: 0.30);
    _ripple(canvas, size, cx, cy, spread, delay: 0.25, alpha: 0.15);
  }

  void _ripple(Canvas canvas, Size size, double cx, double cy, double spread,
      {required double delay, required double alpha}) {
    final local = ((spread - delay) / (1 - delay)).clamp(0.0, 1.0);
    if (local <= 0) return;

    final eased = Curves.easeOutCubic.transform(local);
    final rx = size.width * (0.16 + 0.30 * eased);
    final ry = rx * 0.30;
    final y = cy + size.height * (0.14 + 0.05 * eased);

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035 * (1 - 0.4 * eased)
      ..strokeCap = StrokeCap.round;

    // An arc, not a full ellipse — it reads as a ripple seen at an angle.
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, y), width: rx * 2, height: ry * 2),
      math.pi * 0.08,
      math.pi * 0.84,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(DrippleMarkPainter old) =>
      old.progress != progress || old.color != color;
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/brand/dripple_mark_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Eyeball it**

The geometry above is a starting point, not a finished mark. Render it and
look:

```bash
flutter run -d macos    # or any available device
```

Temporarily point the `/` route at a scratch page showing
`DrippleMark(size: 240)` and three static `CustomPaint`s at `progress` 0.2,
0.5, and 1.0. Adjust `_dropPath` proportions, ripple radii, and arc sweep
until the resting mark reads as a drop over water at 240px *and* at 32px.
Revert the scratch route before committing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add the Dripple brand mark

A drop landing over two ripples, drawn rather than bundled so it is crisp
from a 16px icon to a full-screen splash. The same painter drives the
splash animation and the app icon bake."
```

---

### Task 4: Splash screen and native launch screen

**Files:**
- Create: `lib/screens/splash_screen.dart`
- Modify: `lib/app.dart` (routes: `/` → splash, `/home` → home)
- Modify: `lib/screens/home_screen.dart` (no route changes, but any `context.go('/')` becomes `/home`)
- Modify: `android/app/src/main/res/drawable/launch_background.xml`
- Modify: `android/app/src/main/res/drawable-v21/launch_background.xml`
- Modify: `android/app/src/main/res/values/styles.xml`, `values-night/styles.xml`
- Create: `android/app/src/main/res/drawable/splash_mark.png` (+ `-hdpi`, `-xhdpi`, `-xxhdpi`)
- Modify: `ios/Runner/Assets.xcassets/LaunchImage.imageset/` (three PNGs + `Contents.json`)
- Test: `test/screens/splash_screen_test.dart`

**Interfaces:**
- Consumes: `DrippleMark`, `DrippleMarkPainter` (Task 3); `AppColors`, `AppTypography` (Task 1).
- Produces: `SplashScreen` — a `StatefulWidget` at route `/`.

Timeline, 1.4s total:

```
0.0s   white
0.2s   drop falls from above, bounces on landing
0.5s   two ripples expand in sequence and fade
0.9s   "Dripple" wordmark fades in, rising 8px
1.4s   fade to /home
```

A tap anywhere skips straight to `/home` — a splash must never be a wall.

- [ ] **Step 1: Write the failing test**

Create `test/screens/splash_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/screens/splash_screen.dart';

void main() {
  testWidgets('shows the mark and the wordmark', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.byType(DrippleMark), findsOneWidget);
    expect(find.text('Dripple'), findsOneWidget);

    // Let the timeline finish so the test does not end mid-animation.
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('calls onFinished once the timeline completes', (tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(onFinished: () => finished++),
    ));

    await tester.pump(const Duration(milliseconds: 700));
    expect(finished, 0, reason: 'still animating');

    await tester.pump(const Duration(milliseconds: 900));
    expect(finished, 1);
  });

  testWidgets('a tap skips the rest of the timeline', (tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(onFinished: () => finished++),
    ));

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(SplashScreen));
    await tester.pump();

    expect(finished, 1);

    // A second tap must not fire it again.
    await tester.tap(find.byType(SplashScreen));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(finished, 1);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/screens/splash_screen_test.dart`
Expected: FAIL — `splash_screen.dart` does not exist.

- [ ] **Step 3: Write `lib/screens/splash_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../core/brand/dripple_mark.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';

/// The first screen: a drop lands, ripples spread, the wordmark arrives.
///
/// [onFinished] is injected rather than navigating directly so the timeline
/// can be tested without a router.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 1400);

  late final AnimationController _controller;
  late final Animation<double> _mark;
  late final Animation<double> _wordFade;
  late final Animation<double> _wordRise;

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();

    // 0.14–0.64 of 1400ms is 200ms–900ms: the fall and the ripples.
    _mark = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.14, 0.64, curve: Curves.linear),
    );

    // 0.64–0.86 is 900ms–1200ms: the wordmark.
    _wordFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.64, 0.86, curve: Curves.easeOut),
    );
    _wordRise = Tween<double>(begin: 8, end: 0).animate(_wordFade);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DrippleMark(size: 132, animation: _mark),
              const SizedBox(height: AppSpacing.lg),
              AnimatedBuilder(
                animation: _wordFade,
                builder: (_, child) => Opacity(
                  opacity: _wordFade.value,
                  child: Transform.translate(
                    offset: Offset(0, _wordRise.value),
                    child: child,
                  ),
                ),
                child: Text(
                  'Dripple',
                  style: AppTypography.display.copyWith(
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/screens/splash_screen_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Wire the routes in `lib/app.dart`**

Add the import and change the route table so `/` is the splash and `/home` is
the home screen:

```dart
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fadeTransition(
        SplashScreen(onFinished: () => context.go('/home')),
        state,
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) =>
          _fadeTransition(const HomeScreen(), state),
    ),
```

Then search for any navigation back to the old home route and repoint it:

```bash
grep -rn "go('/')\|push('/')\|context.go(\"/\")" lib
```

Every hit becomes `/home`. The result screen and the game screen's "back to
home" paths are the likely ones.

- [ ] **Step 6: Bake the mark to PNG for the native launch screens**

The native splash cannot run Dart, so it needs a raster. Write a throwaway
script that renders `DrippleMarkPainter(progress: 1)` to PNG at four
densities:

Create `tool/bake_mark.dart`:

```dart
// Throwaway: renders the brand mark to PNG for the native launch screens
// and the app icon. Run with `flutter run -d macos -t tool/bake_mark.dart`,
// then delete the generated files from the app's own asset folders — these
// go into android/res and ios/Assets.xcassets only.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:dripple/core/brand/dripple_mark.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  for (final entry in {'mdpi': 96, 'hdpi': 144, 'xhdpi': 192, 'xxhdpi': 288}
      .entries) {
    final px = entry.value;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const DrippleMarkPainter(progress: 1, color: Color(0xFF1D74F5))
        .paint(canvas, Size(px.toDouble(), px.toDouble()));
    final image = await recorder.endRecording().toImage(px, px);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/splash_mark_${entry.key}.png');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
    stdout.writeln('wrote ${out.path} (${px}px)');
  }
  exit(0);
}
```

Run it, then copy the output:

```bash
flutter run -d macos -t tool/bake_mark.dart
cp build/splash_mark_mdpi.png   android/app/src/main/res/drawable/splash_mark.png
mkdir -p android/app/src/main/res/drawable-hdpi android/app/src/main/res/drawable-xhdpi android/app/src/main/res/drawable-xxhdpi
cp build/splash_mark_hdpi.png   android/app/src/main/res/drawable-hdpi/splash_mark.png
cp build/splash_mark_xhdpi.png  android/app/src/main/res/drawable-xhdpi/splash_mark.png
cp build/splash_mark_xxhdpi.png android/app/src/main/res/drawable-xxhdpi/splash_mark.png
cp build/splash_mark_mdpi.png   ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png
cp build/splash_mark_hdpi.png   ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png
cp build/splash_mark_xhdpi.png  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png
```

- [ ] **Step 7: Point the Android launch screen at the mark**

Both `android/app/src/main/res/drawable/launch_background.xml` and
`drawable-v21/launch_background.xml` become:

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_mark" />
    </item>
</layer-list>
```

In `android/app/src/main/res/values/styles.xml` **and**
`values-night/styles.xml`, the launch screen must be white in both, so the
in-app splash does not flash against a dark ground. Set both `LaunchTheme`
entries to use `@drawable/launch_background`, and set both `NormalTheme`
`android:windowBackground` values to `@android:color/white`.

- [ ] **Step 8: Verify on a device**

```bash
flutter run
```

Watch the launch: the OS splash (white + mark) must hand over to the Flutter
splash with no colour flash, and the app must land on the home screen after
1.4s. Tap during the animation to confirm the skip works.

- [ ] **Step 9: Run the full suite and analyze, then commit**

```bash
flutter test && flutter analyze
git add -A
git commit -m "feat: add the splash screen and match the native launch screens

The drop falls, ripples spread, the wordmark arrives, and the app moves
to /home after 1.4s. A tap skips it. The native launch screens carry the
same mark on white so there is no flash on handover."
```

---

### Task 5: Retune the card art

**Files:**
- Modify: `lib/game/card_painter.dart`
- Modify: `lib/models/word_card.dart` (remove `posColor`; keep `posShape`)
- Modify: `lib/game/card_row_layout.dart` (card size constants follow `CardPainter`)
- Test: `test/models/word_card_test.dart` (drop any `posColor` assertions)
- Test: `test/game/card_painter_test.dart`

**Interfaces:**
- Consumes: `AppColors.forPartOfSpeech`, `AppColors.specialCard` (Task 1).
- Produces: `CardPainter.paint(Canvas, WordCard, Size, {bool highlighted, bool warned, String locale})` — the `CardStyle` parameter is **removed**.

Three changes:

1. **Delete the unused styles.** `CardStyle.tinted` and `CardStyle.playingCard`
   have no call sites anywhere in `lib/` or `test/` — only `band` is used.
   Delete the enum and both methods; inline `_band` into `paint`.
2. **Colours come from the design package**, not from `WordCard.posColor`. The
   model should not hold UI constants.
3. **Retune to the new tokens**: hairline `#EEF0F3` border instead of
   `#14000000`, `w700` word instead of `w800`, highlight ring in
   `AppColors.point` instead of `#22C55E`, discard wash in `AppColors.danger`.
   The soft drop shadow **stays** — on a card it reads as physical stock, which
   is the one exception in the global constraints.

- [ ] **Step 1: Write the failing test**

Create `test/game/card_painter_test.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/game/card_painter.dart';
import 'package:dripple/models/word_card.dart';

void main() {
  /// Painting into a recorder is enough to catch a null deref, a bad clip, or
  /// an unbalanced save/restore — the failures that actually happen here.
  void paintCard(WordCard card, {bool highlighted = false, bool warned = false}) {
    final recorder = ui.PictureRecorder();
    CardPainter.paint(
      Canvas(recorder),
      card,
      const Size(CardPainter.defaultWidth, CardPainter.defaultHeight),
      highlighted: highlighted,
      warned: warned,
    );
    recorder.endRecording().dispose();
  }

  test('paints a word card in every state', () {
    const card = WordCard(id: 'w', word: 'cat', type: CardType.word);
    expect(() => paintCard(card), returnsNormally);
    expect(() => paintCard(card, highlighted: true), returnsNormally);
    expect(() => paintCard(card, warned: true), returnsNormally);
  });

  test('paints every special card', () {
    for (final t in [CardType.jump, CardType.steal, CardType.joker]) {
      expect(
        () => paintCard(WordCard(id: t.name, word: t.name, type: t)),
        returnsNormally,
      );
    }
  });

  test('paints a card with no meaning for the locale', () {
    const card = WordCard(id: 'x', word: 'the', type: CardType.word);
    expect(() => paintCard(card), returnsNormally);
  });

  test('paints a long word without overflowing the layout', () {
    const card =
        WordCard(id: 'y', word: 'extraordinary', type: CardType.word);
    expect(() => paintCard(card), returnsNormally);
  });
}
```

Match the real `WordCard` constructor. If `meanings` is required, pass
`meanings: const {}` for the no-meaning case and `meanings: const {'ko': '고양이'}`
otherwise.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/game/card_painter_test.dart`
Expected: FAIL — `CardPainter.paint` still requires a `style` argument, or the
signature does not match.

- [ ] **Step 3: Rewrite the head of `card_painter.dart`**

Delete the `CardStyle` enum entirely. Replace the class head and `paint` with:

```dart
import 'dart:ui';

import 'package:flutter/material.dart'
    show Colors, FontWeight, TextAlign, TextPainter, TextSpan, TextStyle;

import '../core/design/app_colors.dart';
import '../core/game_icons.dart';
import '../models/word_card.dart';

/// Draws a word card.
///
/// Lives outside the Flame component so the same painting can be previewed in
/// a plain Flutter canvas and so the layout is readable on its own.
///
/// The drop shadow here is the one shadow left in the app. On a card it reads
/// as physical stock rather than as UI chrome, which is the point of the
/// board.
class CardPainter {
  const CardPainter._();

  static const double defaultWidth = 96;
  static const double defaultHeight = 132;

  static void paint(
    Canvas canvas,
    WordCard card,
    Size size, {
    bool highlighted = false,
    bool warned = false,
    String locale = 'ko',
  }) {
    final accent = card.isSpecial
        ? AppColors.specialCard(card.type)
        : AppColors.forPartOfSpeech(card.partOfSpeech);

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.14),
    );

    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    _band(canvas, card, size, rrect, accent, locale);

    if (warned) {
      canvas.drawRRect(rrect, Paint()..color = AppColors.danger.withValues(alpha: 0.16));
      canvas.drawRRect(
        rrect.deflate(1.5),
        Paint()
          ..color = AppColors.danger
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else if (highlighted) {
      canvas.drawRRect(
        rrect.deflate(1.5),
        Paint()
          ..color = AppColors.point
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
```

Use the real part-of-speech accessor name from `WordCard` in place of
`card.partOfSpeech`.

- [ ] **Step 4: Retune `_band` and the text helpers**

In `_band`, change the border colour and drop the `_soften`/`_darken` helpers
if they become unused:

```dart
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
```

and the fill from `Colors.white` to `AppColors.surface`.

In `_word`, change `fontWeight: FontWeight.w800` to `FontWeight.w700` and the
colour from `const Color(0xFF111827)` to `AppColors.textPrimary`.

In `_meaning`, change `fontWeight: FontWeight.w600` — that one is already
legal — and leave the accent colour as-is.

Delete `_tinted`, `_playingCard`, and any helper left with no callers. Run
`flutter analyze` to find them.

- [ ] **Step 5: Remove `posColor` from the model**

In `lib/models/word_card.dart`, delete the `int get posColor` getter. `posShape`
stays — it is geometry, not colour, and `CardPainter._posSymbol` needs it.

Then fix the call site in `card_painter.dart` (`Color(card.posColor)` is gone,
replaced by the `accent` computed in `paint`).

- [ ] **Step 6: Run the tests**

Run: `flutter test`
Expected: PASS. If `test/models/word_card_test.dart` asserts on `posColor`,
delete those assertions — the behaviour moved to
`test/core/design/app_colors_test.dart`, which already covers it.

Also confirm `test/game/card_row_layout_test.dart` still passes: the card grew
from 84x116 to 96x132, so cards-per-row changes at some widths. If that test
hard-codes an expected count for a given width, recompute it from
`CardRowLayout.cardWidth` rather than pasting a new literal.

- [ ] **Step 7: Analyze and commit**

```bash
flutter analyze
git add -A
git commit -m "refactor: retune the card art to the design tokens

Colours now come from the design package instead of a posColor getter on
the model — the data layer should not hold UI constants. The two unused
CardStyle variants are deleted. Cards grow to 96x132 for smaller hands."
```

---

### Task 6: Home and mode-select screens

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Modify: `lib/screens/mode_selection_screen.dart`
- Test: `test/screens/home_screen_test.dart`

**Interfaces:**
- Consumes: `DrippleMark` (Task 3); `AppColors`, `AppTypography`, `AppSpacing` (Task 1).
- Produces: nothing other tasks depend on.

Home becomes: white ground, mark, wordmark, one line of description, a solid
CTA, and secondary navigation as text buttons rather than white-on-green icon
columns. The `greenGradient` `Container` goes.

Mode select: the green cards become white list cells; a selected cell is marked
by a `AppColors.point` border and a tinted background, never a filled block.

- [ ] **Step 1: Write the failing test**

Create `test/screens/home_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/core/brand/dripple_mark.dart';
import 'package:dripple/core/design/app_colors.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/screens/home_screen.dart';

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('shows the brand mark', (tester) async {
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump();
    expect(find.byType(DrippleMark), findsOneWidget);
  });

  testWidgets('has no gradient anywhere', (tester) async {
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump();

    final gradients = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((d) => (d.decoration as BoxDecoration?)?.gradient != null);
    expect(gradients, isEmpty);
  });

  testWidgets('sits on the app background colour', (tester) async {
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
      scaffold.backgroundColor,
      anyOf(AppColors.surface, AppColors.background, isNull),
    );
  });
}
```

The sound manager fires in `initState`; if the test throws on audio, override
`gameFeedbackProvider` in the `ProviderScope` with a no-op fake rather than
weakening the test.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/screens/home_screen_test.dart`
Expected: FAIL — no `DrippleMark` in the tree, and the gradient assertion trips.

- [ ] **Step 3: Rewrite the home screen body**

Replace the `Container(decoration: BoxDecoration(gradient: ...))` wrapper and
everything inside it:

```dart
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              const Center(child: DrippleMark(size: 96)),
              const SizedBox(height: AppSpacing.xl),
              Text('Dripple',
                  textAlign: TextAlign.center,
                  style: AppTypography.display
                      .copyWith(letterSpacing: -0.5)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.wordCardBattle,
                textAlign: TextAlign.center,
                style: AppTypography.body
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(flex: 4),
              ElevatedButton(
                onPressed: () {
                  feedback.onButtonTap();
                  context.push('/mode-select');
                },
                child: Text(l10n.play),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  feedback.onButtonTap();
                  context.push('/settings');
                },
                child: Text(l10n.settings),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
```

Delete the `_navButton` helper and the `CharacterWidget` from this screen — the
character belongs on the board, not the front door. The disabled
Character/Ranking buttons were dead affordances; they go with it.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/screens/home_screen_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Rewrite the mode-select cells**

In `lib/screens/mode_selection_screen.dart`, replace every gradient/green
container with this cell shape, and use it for both the player-count and
difficulty options:

```dart
  Widget _optionCell({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? AppColors.pointTint : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Container(
            constraints:
                const BoxConstraints(minHeight: AppSpacing.minTouch + 12),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected ? AppColors.point : AppColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.label),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: AppColors.point, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
```

Set `Scaffold(backgroundColor: AppColors.background)` and give the screen a
plain `AppBar` with the screen title — the theme already flattens it.

- [ ] **Step 6: Look at both screens**

```bash
flutter run
```

Check the home screen and mode select on a real device size. The CTA must be
reachable with a thumb and the cells must be at least 68px tall.

- [ ] **Step 7: Run the full suite, analyze, and commit**

```bash
flutter test && flutter analyze
git add -A
git commit -m "feat: rebuild home and mode select on the design tokens

The gradient and the two disabled nav buttons are gone; the mark carries
the screen. Mode options become list cells that mark selection with a
border rather than a filled green block."
```

---

### Task 7: Game screen — split and restyle

The largest task. `game_screen.dart` is ~850 lines but already decomposed into
private widget classes, so the split is mechanical: move each class to its own
file under `lib/screens/game/`, changing nothing but visibility and imports.
**Do the move and the restyle as two separate commits** so a reviewer can see
that the move changed no behaviour.

**Files:**
- Create: `lib/screens/game/scoreboard_bar.dart` (`ScoreboardBar`, `TurnTimerWidget`, `CountdownArcPainter`)
- Create: `lib/screens/game/opponents_bar.dart` (`OpponentsBar`)
- Create: `lib/screens/game/action_bar.dart` (`ActionBar`, `SpecialCardRow`, `MuteButton`)
- Create: `lib/screens/game/game_end_overlay.dart` (`GameEndOverlay`, `ScoreRow`)
- Modify: `lib/screens/game_screen.dart` (keeps only `GameScreen` + `_GameScreenState`)
- Modify: `lib/game/dripple_game.dart` (`backgroundColor`, drop-zone colours)

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `AppSpacing` (Task 1).
- Produces: the four widgets above, made public (leading underscore dropped) so
  they can live in separate files. Constructor parameters are unchanged from
  their current private versions.

- [ ] **Step 1: Move the widgets, changing nothing else**

For each target file, cut the class from `game_screen.dart`, paste it in, drop
the leading underscore from the class name, and add whatever imports it needs.
Update the references in `_GameScreenState.build`.

Do not touch layout, colour, or logic in this step. The diff should be pure
motion.

- [ ] **Step 2: Verify the move changed nothing**

Run: `flutter test && flutter analyze`
Expected: all tests pass, `No issues found!`

```bash
flutter run
```

Play one full turn: draw, place a card, submit, discard. Behaviour must be
identical.

- [ ] **Step 3: Commit the move on its own**

```bash
git add -A
git commit -m "refactor: split the game screen widgets into their own files

Pure motion — no layout, colour, or logic changed. game_screen.dart keeps
only the screen and its state."
```

- [ ] **Step 4: Restyle the Flame board background**

In `lib/game/dripple_game.dart`:

```dart
  @override
  ui.Color backgroundColor() => const ui.Color(0xFFF7F8FA);
```

and retint the drop zone from the old greens to the point colour:

```dart
    canvas.drawRRect(rrect, ui.Paint()..color = const ui.Color(0x0F1D74F5));
    _drawDashedRRect(canvas, rrect, const ui.Color(0x4D1D74F5));
```

with the hint text style becoming:

```dart
      style: material.TextStyle(
        fontFamily: 'Pretendard',
        color: ui.Color(0xFF1D74F5),
        fontSize: 15,
        fontWeight: material.FontWeight.w600,
        height: 1.4,
      ),
```

The literal hex values are unavoidable here — Flame's `backgroundColor()` and
the raw `ui.Paint` calls take `dart:ui` colours. Add a comment naming them as
`AppColors.background` and `AppColors.point` so a future reader can find the
source of truth.

The hint string `'여기에 카드를 올려\n문장을 만들어요'` is hard-coded Korean inside
the Flame canvas, which has no `BuildContext`. Leave it for now and note it —
localising it means threading the locale into `DrippleGame`, which is out of
scope for a visual pass.

- [ ] **Step 5: Restyle the moved widgets**

Apply the tokens to each of the four files. The rules, applied uniformly:

- Every `Container` with a green background or gradient becomes
  `AppColors.surface` with a 1px `AppColors.divider` border.
- Every `BoxShadow` is deleted.
- `FontWeight.w900`/`w800` become `w700`; every hard-coded `TextStyle` becomes
  an `AppTypography` constant with `copyWith` only for colour and size.
- Every hard-coded colour becomes an `AppColors` constant.
- Any tappable smaller than 56px gets `minimumSize: Size(56, 56)`.
- `_CountdownArcPainter`'s arc colour: `AppColors.point` normally, and
  `AppColors.danger` under five seconds remaining.
- The current turn indicator in `ScoreboardBar` and `OpponentsBar` marks the
  active player with an `AppColors.point` ring, not a filled green pill.

- [ ] **Step 6: Verify on a device**

```bash
flutter run
```

Play a full game against AI. Check: the timer arc turns red near zero, the
active-player ring follows the turn, the action bar buttons are reachable, and
the board background matches the widget background with no seam.

- [ ] **Step 7: Run the full suite, analyze, and commit**

```bash
flutter test && flutter analyze
git add -A
git commit -m "feat: restyle the game board on the design tokens

The board background now matches the app background so there is no seam
between the Flame canvas and the widgets around it."
```

---

### Task 8: Judgment sheet and result screen

**Files:**
- Modify: `lib/screens/judgment_screen.dart`
- Modify: `lib/screens/result_screen.dart`
- Modify: `lib/screens/game_screen.dart:112-131` (`_onSubmit` — `showDialog` → `showModalBottomSheet`)
- Test: `test/screens/judgment_sheet_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `AppSpacing` (Task 1).
- Produces: `showJudgmentSheet(BuildContext context, JudgmentResult result)` → `Future<void>` — replaces the `JudgmentDialog` widget as the entry point.

A dialog is a modal interruption; a sheet is the lighter gesture and matches
the target aesthetic. Correct/incorrect is carried by a colour bar and one line
of text, not by a large tick or cross.

- [ ] **Step 1: Write the failing test**

Create `test/screens/judgment_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/screens/judgment_screen.dart';

void main() {
  testWidgets('opens as a bottom sheet and closes on confirm',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: SizedBox.shrink());
      }),
    ));

    // Build a JudgmentResult using the real constructor from the engine.
    final result = makeCorrectResult();

    final future = showJudgmentSheet(ctx, result);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await future;

    expect(find.byType(BottomSheet), findsNothing);
  });
}
```

`makeCorrectResult()` is a helper you must write at the top of the test file,
constructing a real `JudgmentResult` — read
`lib/engine/grammar/grammar_engine.dart` for its constructor and required
fields. Do not stub the type.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/screens/judgment_sheet_test.dart`
Expected: FAIL — `showJudgmentSheet` is not defined.

- [ ] **Step 3: Rewrite `judgment_screen.dart`**

Replace `JudgmentDialog` with a sheet body plus its launcher:

```dart
/// Shows the verdict as a bottom sheet.
///
/// A dialog interrupts; a sheet arrives from where the cards are. A failed
/// sentence costs a child nothing but a re-try, so the verdict should not
/// land like an error box.
Future<void> showJudgmentSheet(
    BuildContext context, JudgmentResult result) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface,
    builder: (_) => JudgmentSheet(result: result),
  );
}
```

The sheet body: a 4px full-width bar in `AppColors.success` or
`AppColors.danger` at the top, the submitted sentence in `AppTypography.title`,
the explanation in `AppTypography.body` coloured `AppColors.textSecondary`, and
a full-width `ElevatedButton` to dismiss. Keep whatever explanation text the
current dialog shows.

- [ ] **Step 4: Update the call site**

In `lib/screens/game_screen.dart`, replace the `showDialog(...)` block in
`_onSubmit` with `await showJudgmentSheet(context, result);`.

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/screens/judgment_sheet_test.dart`
Expected: PASS.

- [ ] **Step 6: Restyle the result screen**

`lib/screens/result_screen.dart`: white ground, the `DrippleMark` at the top,
the winner's name in `AppTypography.display`, and the standings as plain list
rows — rank, name, cards left — separated by 1px `AppColors.divider` lines. The
crown icon (`GameIcon.crown`) stays for first place. Buttons: one
`ElevatedButton` to play again, one `TextButton` back to `/home`.

- [ ] **Step 7: Run the full suite, analyze, and commit**

```bash
flutter test && flutter analyze
git add -A
git commit -m "feat: judgment becomes a sheet, result screen restyled

A failed sentence does not cost a turn, so the verdict should not land
like an error dialog. Colour plus one line replaces the tick and cross."
```

---

### Task 9: Lobby and settings, and the missing strings

**Files:**
- Modify: `lib/screens/settings_screen.dart`
- Modify: `lib/screens/lobby_screen.dart`
- Create: `lib/screens/widgets/settings_tile.dart`
- Modify: `lib/l10n/app_en.arb`, `app_ko.arb`, `app_ja.arb`
- Test: `test/screens/settings_screen_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `AppSpacing` (Task 1).
- Produces: `SettingsTile({required String title, String? subtitle, Widget? trailing, VoidCallback? onTap})` — the shared list-row shape used by both screens.

The settings screen currently has hard-coded English strings. Find them:

```bash
grep -n "Text('" lib/screens/settings_screen.dart
```

Every literal becomes an ARB key with Korean, English, and Japanese values.

- [ ] **Step 1: Write the failing test**

Create `test/screens/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:dripple/screens/settings_screen.dart';

Widget _host(Locale locale) => ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    );

void main() {
  testWidgets('every visible string is localised', (tester) async {
    await tester.pumpWidget(_host(const Locale('ko')));
    await tester.pumpAndSettle();

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();

    expect(texts, isNotEmpty);

    // In the Korean locale no label should still be bare ASCII English.
    final untranslated = texts.where(
        (s) => RegExp(r'^[A-Za-z][A-Za-z .!?/-]*$').hasMatch(s)).toList();
    expect(untranslated, isEmpty,
        reason: 'hard-coded English left in the settings screen');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/screens/settings_screen_test.dart`
Expected: FAIL, listing the hard-coded English labels.

- [ ] **Step 3: Add the missing ARB keys**

For each literal found, add to all three ARB files. Follow the existing key
style in the files. Then regenerate:

```bash
flutter gen-l10n
```

- [ ] **Step 4: Replace the literals and run the test**

Swap each `Text('...')` for `Text(l10n.<key>)`.

Run: `flutter test test/screens/settings_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the shared tile**

Create `lib/screens/widgets/settings_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';

/// One row in a settings or lobby list.
///
/// Both screens were building their own row shape with slightly different
/// padding and dividers; this is the one shape they share.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch + 8),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTypography.body),
                  if (subtitle case final s?) ...[
                    const SizedBox(height: 2),
                    Text(s, style: AppTypography.caption),
                  ],
                ],
              ),
            ),
            if (trailing case final t?) t,
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Rebuild both screens on the tile**

Settings: group tiles under `AppTypography.caption` section headers (Sound,
Haptics, Language, About) on `AppColors.background`, with each group a white
block with `radiusMd` corners. Toggles are plain `Switch`es — the theme already
styles them.

Lobby: the same tile for each player row, with the ready state as a trailing
`AppColors.point` dot rather than a coloured row background.

- [ ] **Step 7: Run the full suite, analyze, and commit**

```bash
flutter test && flutter analyze
git add -A
git commit -m "feat: rebuild settings and lobby on a shared list tile

Both screens were rolling their own row shape. The settings screen's
hard-coded English strings are now in the ARB files for all three locales."
```

---

### Task 10: Emotes, character, and removing the shim

The last task. Restyles what is left and deletes the deprecated theme file, so
the design package is the only source of colour in the app.

**Files:**
- Modify: `lib/character/emote_bar.dart`
- Modify: `lib/character/character_widget.dart`
- Modify: `lib/screens/widgets/special_card_sheet.dart`
- Delete: `lib/core/theme/app_theme.dart` (and the now-empty `lib/core/theme/`)
- Test: `test/core/design/no_legacy_theme_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1-9.
- Produces: nothing.

- [ ] **Step 1: Write the failing test**

Create `test/core/design/no_legacy_theme_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The design package is meant to be the only place a colour is defined.
/// This guards the boundary — it is cheap and it catches the one regression
/// that actually happens: someone pasting a hex literal into a screen.
void main() {
  final lib = Directory('lib');

  List<File> dartFiles() => lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('the legacy theme file is gone', () {
    expect(File('lib/core/theme/app_theme.dart').existsSync(), isFalse);
    expect(Directory('lib/core/theme').existsSync(), isFalse);
  });

  test('nothing imports the legacy theme', () {
    final offenders = dartFiles()
        .where((f) => f.readAsStringSync().contains('core/theme/app_theme'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });

  test('no gradient is constructed outside the design package', () {
    final offenders = dartFiles()
        .where((f) => !f.path.startsWith('lib/core/design/'))
        .where((f) => f.readAsStringSync().contains('LinearGradient'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });

  test('screens do not define their own colours', () {
    // Painters legitimately take dart:ui colours; screens do not.
    const allowed = {
      'lib/core/design/app_colors.dart',
      'lib/core/game_icons.dart',
      'lib/game/card_painter.dart',
      'lib/game/dripple_game.dart',
    };
    final hex = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
    final offenders = dartFiles()
        .where((f) => !allowed.contains(f.path))
        .where((f) => hex.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty,
        reason: 'move these into AppColors');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/design/no_legacy_theme_test.dart`
Expected: FAIL — the shim still exists and several files still hold hex
literals.

- [ ] **Step 3: Restyle the emote bar**

`lib/character/emote_bar.dart`: emote buttons become 56px circular
`AppColors.background` chips with the `GameIconPainter` face drawn in
`AppColors.textSecondary`. The cooldown state dims to `AppColors.textDisabled`
rather than greying the whole bar.

- [ ] **Step 4: Restyle the character widget**

`lib/character/character_widget.dart`: the placeholder becomes a filled circle
in `AppColors.pointTint` with the `GameIcon.face*` for the current emotion
drawn in `AppColors.point` — the same visual language as the brand mark. Keep
the existing emotion-to-icon mapping and the Rive TODO comment.

- [ ] **Step 5: Restyle the special card sheet**

`lib/screens/widgets/special_card_sheet.dart`: `radiusLg` top corners, a
`AppTypography.heading` title, cards rendered through `CardPainter` so they
match the board exactly, and a full-width `ElevatedButton` to confirm.

- [ ] **Step 6: Delete the shim**

```bash
git rm lib/core/theme/app_theme.dart
rmdir lib/core/theme 2>/dev/null || true
flutter analyze
```

Every remaining error is a file still importing the old path. Repoint each to
`package:dripple/core/design/app_colors.dart` (or `app_theme.dart`,
`app_typography.dart`, `app_spacing.dart` as needed).

- [ ] **Step 7: Clear the remaining hex literals**

Run the guard test and move each reported literal into `AppColors`:

Run: `flutter test test/core/design/no_legacy_theme_test.dart`
Expected: PASS, 4 tests.

If a literal genuinely belongs to a painter that cannot import Flutter widgets,
add its file to the `allowed` set in the test **and** leave a comment in that
file naming the `AppColors` constant it mirrors. Do not widen `allowed` to
silence a screen.

- [ ] **Step 8: Full verification**

```bash
flutter test
flutter analyze
flutter run
```

Play a complete game start to finish: splash → home → mode select → game →
several turns including a drag reorder, a special card, and a discard →
judgment sheet → result → home. Every screen must be on the new palette with
no green left and no gradient.

- [ ] **Step 9: Update `CLAUDE.md`**

Under **Design Decisions**, replace the "Duolingo-level UX" line with a note
that the visual language is a token-driven minimal system (`lib/core/design/`)
with one accent colour, no gradients, and no shadows, sized for 6-10 year olds.
Under **Tech Stack**, change the theme line to name Pretendard and the design
package, and remove `google_fonts`.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat: finish the redesign and delete the legacy theme

The design package is now the only place a colour is defined, guarded by
a test that fails if a hex literal reappears in a screen."
```

---

## Self-Review Notes

**Spec coverage.** Every spec section maps to a task: design system → Task 1;
brand mark → Task 3; splash and native launch → Task 4; drag fix → Task 2; card
art → Task 5; the screen table → Tasks 6-10. The spec's testing section is
covered by Tasks 2, 3, 5, and 10; the `CardRowLayout` test it asks for already
exists at `test/game/card_row_layout_test.dart`, so Task 5 Step 6 verifies it
still holds after the card size change rather than duplicating it.

**Two spec statements corrected against the code.** The spec's screen table
mentions removing emoji from the board; that already happened in commit
`7eb5c42` (`lib/core/game_icons.dart`). And the spec describes the card fan as
overlapping, but `CardRowLayout` now wraps cards onto rows instead — the drag
index arithmetic in Task 2 follows the code, not the spec's older description.

**Known scope note.** The Flame drop-zone hint string is hard-coded Korean and
stays that way (Task 7, Step 4). Localising it means threading a locale into
`DrippleGame`, which is a behaviour change rather than a visual one.
