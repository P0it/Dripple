# Dripple

## Project Overview

Dripple is a multiplayer English word card battle game built with Flutter. Players compete by arranging word cards into grammatically correct sentences. Entertainment-first board game inspired by Duolingo's visual style.

**Design Spec:** `docs/superpowers/specs/2026-04-05-dripple-design.md`

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
- **Grammar Engine:** Custom rule-based (Dart) — $0 operational cost
- **AI Player:** Custom rule-based (Dart) — offline capable

## Architecture

- All game logic runs on client (offline AI battles work without internet)
- Server only for online multiplayer (Firebase Realtime DB)
- Grammar validation is rule-based (no LLM dependency)
- Character animations via Rive State Machine

## Project Structure

```
lib/
├── main.dart / app.dart          # Entry point + routing
├── core/
│   ├── theme/app_theme.dart      # Design system (Duolingo-inspired green gradient)
│   ├── sound_manager.dart        # SFX + BGM with crossfade
│   ├── haptic_manager.dart       # Vibration patterns
│   └── game_feedback.dart        # Unified audio + haptic controller
├── models/                       # WordCard, Player, GameState
├── engine/
│   ├── grammar/                  # 5 validation rules + sentence templates
│   └── ai/                       # Rule-based AI player
├── data/card_deck.dart           # Curated card deck (60+ cards)
├── game/                         # Flame components (card drag, hand fan)
├── character/                    # Character widget, emotions, emote system
├── screens/                      # Home, ModeSelect, Game, Judgment, Result, Lobby, Settings
├── providers/                    # Riverpod state management
└── services/                     # Auth, Multiplayer, Ad service interfaces
```

## Current Status

### Completed (Phase 1-8)
- [x] Flutter project + all dependencies
- [x] Data models (WordCard, Player, GameState)
- [x] Card deck (60+ curated cards with multilingual meanings)
- [x] Grammar engine (5 rules: article, number, SV agreement, adj order, structure)
- [x] 21 unit tests passing
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
- [ ] Game mode presets (Classic / Battle / Learning)
  - Classic: special cards ON, betting OFF
  - Battle: special cards ON, betting ON (chip system)
  - Learning: special cards OFF, betting OFF, no timer
- [ ] Betting/chip system for Battle mode
- [ ] Room creation (title, password, mode selection)
- [ ] Online multiplayer (Firebase Realtime DB implementation)
- [ ] Friends list + online presence
- [ ] Quick messages (preset phrases instead of free chat)
- [ ] Rive character assets (2-3 characters for launch)
- [ ] Audio assets (kenney.nl Casino Audio + freesound.org + pixabay.com)
- [ ] AdMob integration
- [ ] App store submission

## Design Decisions

1. **No free-text chat** — Use emotes + quick messages to avoid moderation issues (all-ages audience)
2. **Preset game modes** instead of complex room options — keeps UX simple
3. **1-person development** — Flutter single codebase for iOS + Android
4. **Entertainment first** — Board game, not a learning app
5. **$0 operational cost** for core gameplay — grammar engine and AI are fully client-side
6. **Duolingo-level UX** — Rive animations, haptic feedback, polished audio

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

### Critical Bugs (must fix before launch)
1. **SKIP card double-advance** — `_advanceTurn()` called twice, second call can modify ended game (`game_provider.dart:192`)
2. **STEAL card stale reference** — state mutation order causes wrong player reference (`game_provider.dart:208`)
3. **WILD card not implemented** — exists in enum/deck but does nothing (`game_provider.dart:239`)
4. **No round reset** — next round starts with leftover cards, no re-deal (`game_provider.dart:292`)
5. **`_processAITurns` race condition** — Draw button fires-and-forgets, rapid taps cause concurrent AI loops (`game_screen.dart:115`)

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

### Testing Gaps
- Only grammar engine tested (20 tests)
- Zero tests for: GameNotifier, AI Player, CardDeck, EmoteNotifier, game flow integration
- Widget test is trivial (checks text exists)

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
