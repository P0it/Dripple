# Dripple

## Project Overview

Dripple is an English word card battle game built with Flutter, for anyone
learning English word order for the first time — children aged 6-10, and adult
learners abroad. Players race to empty their hand by arranging word cards into
grammatically correct sentences. **Learning is the purpose; a real card game is
the form** — not a drill app.

The audience widened on 2026-08-25, and it is load-bearing on the look rather
than incidental to it: an object an adult reads as a well-made card game is one
a child can also enjoy, while the reverse does not hold.

**Design Spec:** `docs/superpowers/specs/2026-04-05-dripple-design.md`
**Current Redesign Spec:** `docs/superpowers/specs/2026-08-22-dripple-card-battle-redesign.md`
**Visual Redesign Spec:** `docs/superpowers/specs/2026-08-25-physical-card-redesign.md`
**Implementation Plan:** `docs/superpowers/plans/2026-08-22-card-battle-redesign.md`

## Tech Stack

- **Framework:** Flutter (Dart) — iOS + Android cross-platform
- **Game Engine:** Flame Engine — card physics, drag & drop
- **Character Animation:** Rive — State Machine driven emotions (like Duolingo)
- **Backend:** Firebase — Auth, Realtime DB, Matchmaking
- **Ads:** Google AdMob — rewarded + banner
- **Audio:** audioplayers — SFX (21 types) + BGM (6 tracks) with crossfade
- **Haptics:** vibration — 6 intensity patterns for game events
- **State Management:** Riverpod
- **Routing:** GoRouter with fade transitions
- **Design System:** `lib/core/design/` tokens + materials + bundled Pretendard
  (no `google_fonts`)
- **Grammar Engine:** Custom rule-based (Dart) — $0 operational cost
- **AI Player:** Custom rule-based (Dart) — offline capable

## Architecture

- All game logic runs on client (offline AI battles work without internet)
- Server only for online multiplayer (Firebase Realtime DB)
- Grammar validation is rule-based (no LLM dependency)
- Character animations via Rive State Machine

## Game Rules

4 players (1 human + 3 AI), 7 cards each, single game. First to empty their
hand wins.

```
Your turn
 (1) Draw exactly one card — deck top OR discard pile top (face up)
 (2) Take exactly one action
       - complete a sentence  (cards leave your hand for good)
       - play JUMP or STEAL
       - discard one card face up
```

- No minimum or maximum sentence length. The grammar engine's 2-card floor is
  the only bound; longer sentences empty the hand faster, so the structure
  rewards them without a rule.
- A failed submission does **not** cost the action. Cards return to hand.
- A card taken from the discard pile cannot be discarded on the same turn
  (Gin Rummy rule — otherwise two players trade one card forever).
- Deck empty: shuffle the discard pile back in. After two recycles, the player
  holding the fewest cards wins (anti-stalling).
- Opening hands are guaranteed at least one verb and one subject-capable card.
- Special cards: **JOKER** (wildcard word) / **JUMP** (skip the next player) /
  **STEAL** (forced card exchange with a chosen player).

### What counts as a correct sentence

**The standard: a sentence is correct when its construction is correct.
Meaning is not judged.**

This line is deliberate and load-bearing. Cards are dealt at random, so
requiring sentences to also *make sense* would leave a player almost nothing
to play, and the game would stop being a game. `the flower reads` and
`water has apples` are therefore **accepted**.

`apples run a friend` is still **rejected** — not because apples cannot run,
but because `run` cannot take an object at all. That is a fact about English
grammar, not about meaning.

Everything the engine checks falls into two layers, both of which come
straight out of an English grammar book:

**1. Structure** — a recursive chunk parser
(`lib/engine/grammar/sentence_parser.dart`):

```
NP   := Pronoun | (Art)? (Adj)* Noun
AdjP := (AdvDegree)* Adj+
PP   := Prep NP
VP   := Verb (NP | AdjP)? (AdvManner)? (PP)*
S    := NP (AdvFreq)? VP
```

**2. Form and agreement** — five rules in `lib/engine/grammar/rules/`:

| Check | Rejected | Accepted |
|---|---|---|
| Article agreement | `an green friend` | `a green friend` |
| Number | `a cats` | `the cats` |
| Subject-verb agreement | `he like cats` | `he likes cats` |
| Adjective order | `red big ball` | `big red ball` |
| Verb valency (`VerbFrame`) | `apples run a friend`, `they read small` | `I read`, `I read books`, `I am happy` |
| Pronoun case | `cats like I` | `cats like you` |
| Determiners | `tree wants` | `the tree wants` |
| Adverb position (`AdverbKind`) | `they read always` | `they always read` |

JOKER matches any part of speech, any verb frame, any adverb slot.

Article agreement looks at the word directly after the article, adjectives
included, and falls back to spelling when a card carries no explicit
`vowelStart` — otherwise `an green friend` slips through.

**Out of scope, by decision:** semantics of every kind, plus conjunctions,
tense, questions and negation. An earlier build checked subject animacy so
that `the flower reads` would fail; it was removed because the standard has
to be one statable line, and half a semantic check is worse than none.

## Project Structure

```
lib/
├── main.dart / app.dart          # Entry point + routing
├── core/
│   ├── design/                   # Design system — the only place a colour lives
│   │   ├── app_colors.dart       #   palette by material: paper vs furniture
│   │   ├── materials.dart        #   grain, felt, recess, rail, card shadows
│   │   ├── felt_scaffold.dart    #   the table every screen stands on
│   │   ├── app_typography.dart   #   Pretendard, three weights, ink by default
│   │   ├── app_spacing.dart      #   4pt grid, three radii, 56px touch floor
│   │   └── app_theme.dart        #   ThemeData assembled from the tokens
│   ├── brand/dripple_mark.dart   # The bouncing-dots mark, drawn not bundled
│   ├── sound_manager.dart        # SFX + BGM with crossfade
│   ├── haptic_manager.dart       # Vibration patterns
│   └── game_feedback.dart        # Unified audio + haptic controller
├── models/                       # WordCard, Player, GameState
├── engine/
│   ├── grammar/                  # 5 validation rules + sentence templates
│   └── ai/                       # Rule-based AI player
├── data/card_deck.dart           # Curated card deck (60+ cards)
├── game/                         # Flame components (card drag, hand fan)
│   ├── card_painter.dart         #   the card's anatomy, 63:88
│   ├── pos_pip.dart              #   Montessori suit marks for the indices
│   └── dripple_game.dart         #   the well and the rail
├── character/                    # Character widget, emotions, emote system
├── screens/                      # Home, ModeSelect, Game, Judgment, Result, Lobby, Settings
├── providers/                    # Riverpod state management
└── services/                     # Auth, Multiplayer, Ad service interfaces
```

## Current Status

### Completed (Phase 1-8, then the 2026-08-22 card battle redesign)
- [x] Flutter project + all dependencies
- [x] Data models (WordCard, Player, GameState)
- [x] Card deck (60+ curated cards with multilingual meanings)
- [x] Grammar engine (5 rules: article, number, SV agreement, adj order, structure)
- [x] Recursive chunk parser with prepositional phrases and pronoun case
- [x] Rummy turn structure (draw → one action), discard pile, deck recycling
- [x] AI rewritten — searches with the grammar engine, actually plays sentences
- [x] Special card UI for the human player (JUMP / STEAL)
- [x] Free sentence-zone reordering inside Flame
- [x] 90 unit tests passing
- [x] Game logic + turn management + scoring with combo
- [x] AI player (rule-based, strategic special card usage)
- [x] Flame game board (drag & drop cards, sentence zone)
- [x] All screens (Home, ModeSelect, Game, Judgment, Result, Lobby, Settings)
- [x] i18n (Korean, English, Japanese)
- [x] Character widget with emotion states (placeholder for Rive)
- [x] Emote system (5 types + cooldown)
- [x] Audio system (21 SFX + 6 BGM tracks + crossfade)
- [x] Haptic feedback (6 intensity patterns)
- [x] Multiplayer service interface (abstract)
- [x] Ad service interface (abstract)

### Next Steps (Planned)
- [ ] Room creation (title, password)
- [ ] Online multiplayer (Firebase Realtime DB implementation)
- [ ] Friends list + online presence
- [ ] Quick messages (preset phrases instead of free chat)
- [ ] Rive character assets (2-3 characters for launch)
- [ ] Audio assets (kenney.nl Casino Audio + freesound.org + pixabay.com)
- [ ] AdMob integration
- [ ] App store submission

## Design Decisions

1. **No free-text chat** — Use emotes + quick messages to avoid moderation issues (all-ages audience)
2. **Single mode** — no Classic/Battle/Learning presets, no betting. Only
   difficulty and the optional turn timer are configurable.
3. **1-person development** — Flutter single codebase for iOS + Android
4. **Learning is the purpose, a card game is the form** — a child picks up
   English word order by playing, not by answering questions. Reversed the
   earlier "entertainment first, not a learning app" decision (2026-08-22).
5. **Borrow proven card-game rules** — the turn structure is Rummy, the
   loophole guards come from Gin Rummy and deck-builders, the part-of-speech
   colours are the Montessori grammar symbols. All of it is play-tested by
   decades of use.
6. **Flame is kept deliberately** — the card-game feel is the point, so the
   sentence-zone reorder was hand-built inside Flame rather than swapping to
   Flutter widgets. Known cost: screen readers cannot see the Flame canvas.
8. **Paper takes the brand, furniture takes brass.** Every surface is one of
   two materials. *Paper* — the card face, sheets, dialogs — carries warm
   off-white stock, ink type, the point blue, and the part-of-speech palette;
   information lives there. *Furniture* — the table, the hand rail, the
   sentence well, screen grounds — carries deep felt, brass hairlines, and
   cream type; nothing is read there, only held. Decoration serving neither
   does not ship: a gradient describing a lit felt surface is furniture, a
   gradient on a button because it looked flat is not.

   This replaced "restraint over decoration" on 2026-08-25. That rule banned
   gradients, shadows outside the card, and anything but a near-white ground —
   and card-game materiality is *made of* those things, so it could not survive
   the goal. Ergonomics are unchanged: a 56px touch floor, 60px buttons, and
   card type sized to be read across a table.
   `test/core/design/no_legacy_theme_test.dart` now guards the new rule — hex
   literals stay out of screens, gradients and shadows stay inside the design
   package and `lib/game/`, and the card's 63:88 proportion is pinned.

9. **A card has the anatomy of a card.** Poker proportion, a corner radius of a
   twentieth of the width rather than a seventh, two shadows so it sits on a
   surface instead of floating on a page, the cut edge of the stock, grain, a
   printed frame carrying the part of speech, corner indices, and a rule
   between headword and gloss. Each is load-bearing; drop any and it slides
   back toward a rounded rectangle with text in it.

10. **The board is a table.** The sentence zone is recessed into the felt and
    the hand sits on a raised rail. Recess versus rail is the distinction a
    real table makes, and it reads before any label does.

11. **$0 operational cost** for core gameplay — grammar engine and AI are fully
    client-side.

## Development

```bash
# Run
flutter run

# Analyze
flutter analyze

# Test
flutter test

# Flutter SDK (if not in PATH)
export PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH"
FLUTTER_ALLOW_ROOT=true flutter <command>
```

## Engineering Review (2026-04-09)

### Critical Bugs — all resolved by the 2026-08-22 redesign
1. ~~**SKIP card double-advance**~~ — SKIP became JUMP and all turn advances
   go through the single `endTurn({skip})` path.
2. ~~**STEAL card stale reference**~~ — `playSteal` writes both hands in one
   atomic state update.
3. ~~**WILD card not implemented**~~ — renamed JOKER; the parser treats it as
   a wildcard token that matches any part of speech.
4. ~~**No round reset**~~ — rounds were removed entirely. Single game, won by
   emptying your hand.
5. ~~**`_processAITurns` race condition**~~ — AI driving moved into
   `GameNotifier` behind an `_isProcessingAI` guard; the UI no longer owns it.

### Additional bugs found and fixed
- **AI could never submit a sentence.** `_findBestSentence` only built up to 4
  cards while `minSentenceLength` was 5, so the AI drew every single turn.
  Replaced with a permutation search that uses the grammar engine as oracle.
- **Timer expiry froze the game.** The turn advanced to an AI but nothing
  drove the AI loop, because only the screen called it.
- **Rounds never ended.** The end condition was deck exhaustion — roughly 93
  turns.
- **The human could not play special cards at all.** `playSpecialCard` had
  zero call sites in the UI.
- **`flutter_gen` synthetic package removed in Flutter 3.44**, which broke
  compilation of every screen file.

### Architecture Issues
- `GameNotifier` mutates `state` multiple times per action → intermediate widget rebuilds
- `lastJudgment` is a side-channel outside Riverpod → breaks unidirectional data flow
- Flame `DrippleGame` duplicates Riverpod state → full card component rebuild every frame
- No separation between game logic and UI orchestration
- `CardDeck._idCounter` is global mutable state

### Performance Issues
- Flame components: full teardown/rebuild on every state change (should diff)
- `playAt()` creates unbounded `AudioPlayer` instances without disposal
- `CardComponent.render()` allocates new `TextPainter` every frame (should cache)
- Crossfade overlap: calling `crossfadeTo` mid-fade causes volume oscillation

### Multiplayer Gaps
- All models lack `toJson`/`fromJson` (Firebase needs JSON serialization)
- `TurnAction` enum duplicated in two files
- No security model (opponent hands readable in proposed Firebase structure)
- No conflict resolution for disconnections/stale turns

### Testing status (90 tests)
- Grammar engine 20, sentence parser 15, word card 5, card deck 8,
  game state 7, GameNotifier 26, AI player 8, widget 1
- Still untested: EmoteNotifier, SoundManager, HapticManager, screen widgets

### Missing for App Store
- Audio/Rive assets (placeholder only)
- App icon, splash screen
- Crash reporting, analytics
- Persistent storage (settings reset on restart)
- Privacy policy, COPPA compliance
- Settings screen strings not localized
- Accessibility (no Semantics, Flame canvas opaque to screen readers)

### Recommended Priority
1. Fix 5 critical bugs
2. Add GameNotifier + AI tests
3. Implement turn timer
4. Ship AI-only mode to store (v1 — no Firebase)
5. Firebase multiplayer as v2

## gstack

Use the `/browse` skill from gstack for all web browsing. Never use `mcp__claude-in-chrome__*` tools.

### Available gstack skills
`/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`, `/retro`, `/investigate`, `/document-release`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`, `/learn`

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
  