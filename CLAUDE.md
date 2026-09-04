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
 (2) Take at most one action
       - complete a sentence  (cards leave your hand for good)
       - play JUMP or STEAL
       - discard one card face up
       - or pass, keeping everything you drew
```

- No minimum or maximum sentence length. The grammar engine's 2-card floor is
  the only bound; longer sentences empty the hand faster, so the structure
  rewards them without a rule.
- A failed submission does **not** cost the action. Cards return to hand.
- **Discarding is optional, and passing is a real move.** Only a completed
  sentence takes cards out of a hand for good, so a player forced to discard
  in order to end a turn draws one and throws one away forever at the same
  hand size and can never finish. Passing keeps the draw; the hand grows, and
  a bigger hand is what a long sentence is made of. Passing is offered only
  after the draw — passing before it would end a turn in which nothing
  happened.
- A card taken from the discard pile cannot be discarded on the same turn
  (Gin Rummy rule — otherwise two players trade one card forever).
- Deck empty: shuffle the discard pile back in. After two recycles, the player
  holding the fewest cards wins (anti-stalling).
- Opening hands are guaranteed at least one verb and one subject-capable card.
- Special cards: **JOKER** (wildcard word) / **JUMP** (skip the next player) /
  **STEAL** (forced card exchange with a chosen player).

**The gloss belongs to the player, not to the deck.** A card prints its
meaning in the app's own locale, which has to be injected — the painter's
`ko` default is not a policy, and while nothing overrode it every player in
the world read Korean. English prints no gloss at all: `meanings['en']` of an
English word is that same word, so there is nothing to teach and the headword
drops to the card's foot alone.

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
packages/dripple_rules/           # The rules, as a package with no Flutter
│   ├── models/                   #   WordCard, Player, GameState
│   ├── engine/grammar/           #   parser + 5 rules
│   ├── engine/ai/                #   the bot
│   ├── engine/game_engine.dart   #   turn logic (GameNotifier)
│   ├── data/card_deck.dart       #   the deck; ids are positional
│   └── wire/wire.dart            #   GameSnapshot (private) / PublicView
server/                           # The authority for online games
│   ├── bin/server.dart           #   entrypoint
│   └── lib/src/                  #   rooms, seats, actions, HTTP
lib/
├── main.dart / app.dart          # Entry point + routing
├── core/
│   ├── design/                   # Design system — the only place a colour lives
│   │   ├── app_colors.dart       #   palette by material: paper vs furniture
│   │   ├── materials.dart        #   grain, ground, recess, rail, card shadows
│   │   ├── table_scaffold.dart   #   the table every screen stands on
│   │   ├── app_typography.dart   #   Pretendard, three weights, ink by default
│   │   ├── app_spacing.dart      #   4pt grid, three radii, 56px touch floor
│   │   └── app_theme.dart        #   ThemeData assembled from the tokens
│   ├── brand/dripple_mark.dart   # The two-card mark, drawn not bundled
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
- [x] AI plays by the same rules the human has, passing included — but
      narrowly: only when its worst card is one it needs, its hand is under
      the difficulty ceiling (easy 6 / medium 5 / hard 4), and the deck still
      holds more than a full deal. Measured over 60 all-AI games, unrestricted
      passing dropped games won by emptying a hand from 59/60 to 41/60; the
      shipped rule holds 48/60. A passed card leaves the deck without reaching
      the discard pile, so a recycle never brings it back.
- [x] Special card UI for the human player (JUMP / STEAL)
- [x] Free sentence-zone reordering inside Flame
- [x] 90 unit tests passing
- [x] Hand cards can be slid along the rail to sort them (cosmetic; the rules
      never read hand order)
- [x] Tutorial mode — a scripted one-player board with coach marks over the
      deck, the discard pile, the rail, the sentence line and the submit
      button (`lib/tutorial/`, `lib/screens/tutorial/`)
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
- [x] Shared rules package — app and server run the same grammar engine
- [x] Game server (Dart) — owns the deck and every hand; HTTP actions
- [x] Online play with friends by room code — make, join, deal, play
- [ ] Firebase project: RTDB store, anonymous auth, Cloud Run deploy
- [ ] Push updates (RTDB subscription) in place of polling
- [ ] Friends list + online presence
- [ ] Levels / ranks, then a leaderboard
- [ ] Random matchmaking
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
8. **Paper takes the brand, furniture takes cream.** Every surface is one of
   two materials. *Paper* — the card face, sheets, dialogs — carries warm
   off-white stock, ink type, and the part-of-speech palette; information
   lives there. *Furniture* — the table, the hand rail, the sentence well,
   screen grounds — carries a neutral dark ground, cream hairlines and type,
   and the brand blue for whatever is live; nothing is read there, only held. Decoration serving neither
   does not ship: a gradient describing a lit surface is furniture, a
   gradient on a button because it looked flat is not.

   This replaced "restraint over decoration" on 2026-08-25. That rule banned
   gradients, shadows outside the card, and anything but a near-white ground —
   and card-game materiality is *made of* those things, so it could not survive
   the goal. Ergonomics are unchanged: a 56px touch floor, 60px buttons, and
   card type sized to be read across a table.
   The furniture was green felt with brass trim until this was taken apart in
   two steps, and the order matters because the first step was wrong on its
   own.

   **Brass went first (2026-08-26).** A casino table is green *and* gold, and
   the gold was laying a yellow cast over every rule and pill. What replaced
   it is not another accent but the absence of one: `AppColors.trim` is the
   same cream the furniture already sets type in.

   **Then the felt went (2026-09-01),** because taking the gold off a green
   table lit by a radial with a vignette still leaves a card room. The ground
   is `#15181C` now, hueless, with one soft wash of light near the top and no
   vignette at all — a vignette is a spotlight and a spotlight is the casino
   again.

   What that cost: green is the complement of warm card stock, so it flattered
   the cards more than any other ground could. What it bought is the same idea
   by subtraction — a ground with no hue means the only colours on the screen
   are printed on the cards. And it freed the brand blue, which on green was
   unusable as an accent (blue and green sit at the same luminance in opposed
   hues, which is why brass had the job); on a neutral ground it rings the
   player who is up and draws the clock.

   `test/core/design/no_legacy_theme_test.dart` now guards the new rule — hex
   literals stay out of screens, gradients and shadows stay inside the design
   package and `lib/game/`, and the card's 63:88 proportion is pinned.

9. **A card has the anatomy of a card, and everything on it is flush left.**
   Poker proportion, a corner radius of a twentieth of the width rather than a
   seventh, two shadows so it sits on a surface instead of floating on a page,
   the cut edge of the stock, and grain. On the face there are exactly three
   marks, all hanging off the left margin: a short part-of-speech tick at the
   top left, the headword at the bottom left, and the gloss under it.

   Left alignment is the load-bearing part. A fanned hand overlaps, and what
   stays visible of a covered card is its left edge. Centre the word and only
   the top card is readable; hang everything off the left margin and all seven
   are. That single move retired three earlier devices on 2026-08-26 — the
   printed frame (a tick a third of the card wide says the same thing without
   tinting the paper, and the paper is the one thing here that has to stay
   white), both corner indices, and the dictionary rule between headword and
   gloss.

   The bottom-right index went for a second reason. A playing card repeats its
   rank at both corners because you might pick it up either way round; ours is
   always upright, so that block had no job — and its `n.` / `adj.`
   abbreviation was English grammar metalanguage, which is the last thing a
   six-year-old or a beginner abroad can read.

10. **The board is a table, and there is one hand on it.** The sentence used
    to sit in its own recess with a dashed border and a placeholder, which is
    the anatomy of a form field — it read as *the place you submit to* rather
    than as the cards you are playing. There is no container now. The hand is
    one overlapping fan on a rail; cards you are playing are pushed forward
    onto the bare table, and the gap is the only thing saying they are in play,
    which is exactly what the gap says at a real table.

    The two rows are laid out by different rules because they have different
    jobs (`lib/game/board_layout.dart`). A held card only has to be
    *identifiable*, so `HandFan` overlaps; a played card has to be *read*, so
    `SentenceLine` never overlaps and shrinks its cards instead.

    **Both of them shrink before they let a word be cut.** The fan spends
    overlap first and shrinks second, but it does shrink: `HandFan.minVisible`
    is the least of a covered card that stays showing, and it is measured
    rather than chosen — the widest label in the deck needs 82% of a card, so
    the floor is 85% and the cards give up size until the spread reaches it.
    `CardPainter.wordMaxWidth` is the other half of the same number: holding
    the headword to 73% of the width costs the two longest words a little type
    size and buys every card in a seven-card hand being readable while
    covered, on every screen down to 360pt. The floor was a flat 18pt before
    this — 21% of a card — and half the deck's words were losing their last
    letters.

    **The row opens for a card while it is still in the air.** Whichever row
    the held card is over lays itself out with an empty place where the card
    would land if it were let go now, and closes again when it is put down.
    Rearranging on release gave a player carrying a card nothing to aim at:
    the row stood still and the landing place was a guess that only resolved
    after the fact. On a table you push the cards either side apart with the
    one in your hand, and the space that opens *is* the aim. Pushed past the
    midline the sentence opens and the fan closes up behind, which is the same
    statement in two rows.

    **Sorting the hand is not a turn action.** Nothing in the rules reads the
    order of a hand, so sliding cards along the rail is allowed at any moment,
    including while somebody else is taking their turn — which is most of the
    time a player spends working a sentence out. `reorderHand` therefore acts
    on `GameState.me` rather than on `currentPlayer` and carries no turn
    guard; online it is answered on the device and never sent, alongside the
    staged sentence, and survives each reply from the authority because a
    reply is the truth about *what* is in the hand and says nothing about how
    the player has arranged it.

    **The felt only asks for a sentence when it will accept one.** The line
    of text on the empty space used to be drawn whenever the space was empty
    and the hand was not — so it sat there while an opponent was thinking and
    through the player's own draw step, both states in which pushing a card
    forward is refused. A board that asks for a move it will not accept is
    worse than a silent one: it leaves the space unreadable, because a player
    cannot tell whether it is somewhere to try an order out ahead of their
    turn or somewhere to submit an answer when in the state they are looking
    at it is neither. `DrippleGame.canBuild` is set from the same predicate
    that gates the gesture, and the line names the space and says what
    finishes it rather than only naming the gesture.

    **The fan takes one gesture, and it is the direct one.** Press a card and
    it comes up under your finger; drag it sideways and the hand reorders,
    push it forward past the midline and it is played. Arranging the hand is
    not a convenience — a player tries an order in the fan and *then* pushes
    the finished sentence forward, which means the row above reads as the
    answer whether or not it has a container round it.

    A modal version of this shipped on 2026-08-26 and was removed on
    2026-09-03: a press put the hand into a "read" state where sliding along
    the rail raised each card in turn, and only an upward pull of 16px became
    a pick-up. Sideways was therefore never a drag, so the hand could not be
    reordered without first pulling a card out of the fan, and nothing on
    screen said the exit was upward. What paid for that gesture was a card you
    could not identify while covered, and rule 9's left-aligned face removed
    the debt.

    This repealed the older "cards never overlap — a child who cannot read the
    card cannot play it" rule, which was right while a card carried its
    identity only in the word across its middle. The word is not across the
    middle any more: it sits at the bottom left, inside the sliver a covered
    card still shows. The ban went with the thing that made it necessary.

12. **The lesson is a mode, not a layer over the game.** A guided first turn
    laid over a real game is a test, not a lesson: hands are dealt at random,
    so there is no promise a playable sentence is in one, and a beginner asked
    to find a sentence that may not exist learns only that the game is broken.
    The tutorial deals its own one-player board — `runs the cat` in hand, `big`
    on top of the deck — so every instruction can be followed.

    Coach marks cover the board only while they are pointing at something. A
    step that asks for a gesture rings its target and covers nothing: a hand
    cannot aim at what it cannot see, and a card that misses has to be able to
    find its way home. Because the board is a Flame canvas, `DrippleGame`
    hands out `deckRect` / `discardRect` / `handRect` / `sentenceRect` in board
    coordinates and the Flutter overlay above converts them — a widget key
    cannot find something drawn on a canvas.

12. **The server owns the deck, and no player does.** Realtime DB stores; it
    does not run code, so a shuffle has to happen either on a player's device
    or on a server. A player holding the shuffle and everyone else's hand is
    not a card game, so there is a server — written in Dart against
    `packages/dripple_rules`, because a second implementation of English
    grammar would drift from the first and the day they disagreed would be
    undebuggable.

    It keeps nothing between requests: it reads a room, applies one action,
    writes it back against the version it read. Cloud Run scales to nothing
    when idle, and a game living in memory would die with the instance. Turn
    deadlines are timestamps for the same reason — there is no clock running,
    so an expired turn is noticed by whatever request touches the room next.

    Two encodings, not one. `GameSnapshot` is the server's own copy and never
    leaves it; `PublicView` is what the table can see. Both are tested for
    what they must not contain.

13. **Building a sentence is local; only the finished one is sent.** Laying
    cards out and reordering them moves cards inside one hand and changes
    nothing anybody else can see. The board draws the same either way.

14. **No sign-in, and nothing collected.** An id is minted on the device on
    first use and a name is asked for only when somebody first taps Online.
    A new phone is a new player. That is the trade, and it is the right way
    round for a game six-year-olds play.

11. **$0 operational cost** for core gameplay — grammar engine and AI are fully
    client-side.

## Development

```bash
# Run
flutter run

# Analyze
flutter analyze

# Test — three packages
flutter test
(cd packages/dripple_rules && dart test)
(cd server && dart test)

# Run the game server locally (in memory, trusts every token)
(cd server && dart run bin/server.dart --insecure-local)

# Point the app at a server other than localhost:8080
flutter run --dart-define=DRIPPLE_SERVER=http://192.168.0.10:8080

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

### Testing status (335 tests)
- `packages/dripple_rules` 166 — grammar, parser, deck, models, turn logic,
  wire format. Runs with `dart test`, no Flutter.
- `server` 42 — rooms, seating, turn authority, expiry, redaction, HTTP.
- app 127 — screens, Flame board, tutorial, and the online client and
  provider driven against the real server rather than a mock of it.
- Still untested: EmoteNotifier, SoundManager, HapticManager

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
  