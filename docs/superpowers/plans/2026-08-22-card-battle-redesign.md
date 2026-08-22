# Dripple 카드 배틀 재설계 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dripple을 러미(Rummy) 방식 턴 구조의 4인 카드 대전 게임으로 재설계하고, 작동하지 않는 AI·턴 진행·문법 범위·특수카드 UI를 전면 재구현한다.

**Architecture:** 문법 검증을 21개 하드코딩 패턴 배열에서 재귀 청크 파서로 교체하고, 그 파서를 AI 탐색의 오라클로 재사용한다. 게임 상태는 "뽑기 → 액션 1회" 2단계 턴 페이즈를 갖고, AI 진행 트리거 소유권을 UI에서 `GameNotifier`로 옮겨 턴 정지 버그를 구조적으로 제거한다. 렌더링은 Flame을 유지하고 문장존 재배열을 Flame 내부에 직접 구현한다.

**Tech Stack:** Flutter / Dart, Riverpod (StateNotifier), Flame, flutter_test

**Spec:** `docs/superpowers/specs/2026-08-22-dripple-card-battle-redesign.md`

## Global Constraints

- Flutter SDK가 PATH에 없으면: `export PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH"` 후 `FLUTTER_ALLOW_ROOT=true flutter <command>`
- 모든 작업 후 `flutter analyze` 경고 0개를 유지한다.
- 기존 `test/engine/grammar/grammar_engine_test.dart`의 21개 테스트는 **전부 계속 통과해야 한다**. 회귀 방지선이다.
- 플레이어 수 기본값 4, 초기 손패 7장, 턴 타이머 기본 0(비활성).
- 카드 매수 총 110장: 대명사 12 / 관사 10 / 명사 26 / 동사 26 / 형용사 12 / 부사 6 / 전치사 8 / 특수 10(JOKER 4, JUMP 3, STEAL 3).
- 문장 최소·최대 길이 규칙 없음. 문법 엔진이 요구하는 2장이 자연 하한.
- 접속사, 시제 변화, 의문문, 부정문은 범위 밖.
- 커밋 메시지는 영어, `feat:` / `fix:` / `refactor:` / `test:` 접두어 사용.

---

### Task 1: 재귀 청크 문법 파서

21개 패턴 하드코딩을 재귀하강 파서로 교체한다. 전치사구가 열리면서 덱의 전치사 카드가 사용 가능해진다.

**Files:**
- Create: `lib/engine/grammar/sentence_parser.dart`
- Modify: `lib/engine/grammar/rules/structure_rule.dart` (전체 재작성)
- Delete: `lib/engine/grammar/sentence_templates.dart`
- Test: `test/engine/grammar/sentence_parser_test.dart`

**Interfaces:**
- Consumes: `WordCard`, `PartOfSpeech`, `CardType` (`lib/models/word_card.dart`)
- Produces: `SentenceParser.parse(List<WordCard>) -> bool`

문법:
```
S     := NP VP
NP    := Pronoun | (Art)? (Adj)* Noun
AdjP  := (Adv)* Adj+
PP    := Prep NP
VP    := Verb (NP | AdjP)? (Adv)? (PP)*
```

- [ ] **Step 1: Write the failing test**

`test/engine/grammar/sentence_parser_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/engine/grammar/sentence_parser.dart';

WordCard _c(String word, PartOfSpeech pos) =>
    WordCard(id: 'p_$word', word: word, pos: pos);
WordCard _joker() =>
    WordCard.special('p_joker', CardType.joker);

void main() {
  final parser = SentenceParser();

  group('SentenceParser', () {
    test('SV: "they run"', () {
      expect(parser.parse([
        _c('they', PartOfSpeech.pronoun),
        _c('run', PartOfSpeech.verb),
      ]), true);
    });

    test('SVO: "I like cats"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('like', PartOfSpeech.verb),
        _c('cats', PartOfSpeech.noun),
      ]), true);
    });

    test('Art+Adj+N subject: "the big cat runs"', () {
      expect(parser.parse([
        _c('the', PartOfSpeech.article),
        _c('big', PartOfSpeech.adjective),
        _c('cat', PartOfSpeech.noun),
        _c('runs', PartOfSpeech.verb),
      ]), true);
    });

    test('SVC: "I am happy"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('am', PartOfSpeech.verb),
        _c('happy', PartOfSpeech.adjective),
      ]), true);
    });

    test('SVC with adverb: "I am very happy"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('am', PartOfSpeech.verb),
        _c('very', PartOfSpeech.adverb),
        _c('happy', PartOfSpeech.adjective),
      ]), true);
    });

    test('SV+Adv: "I run fast"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('run', PartOfSpeech.verb),
        _c('fast', PartOfSpeech.adverb),
      ]), true);
    });

    test('prepositional phrase: "I like the cat in the box"', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('like', PartOfSpeech.verb),
        _c('the', PartOfSpeech.article),
        _c('cat', PartOfSpeech.noun),
        _c('in', PartOfSpeech.preposition),
        _c('the', PartOfSpeech.article),
        _c('box', PartOfSpeech.noun),
      ]), true);
    });

    test('two prepositional phrases', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('sit', PartOfSpeech.verb),
        _c('on', PartOfSpeech.preposition),
        _c('the', PartOfSpeech.article),
        _c('chair', PartOfSpeech.noun),
        _c('with', PartOfSpeech.preposition),
        _c('you', PartOfSpeech.pronoun),
      ]), true);
    });

    test('joker acts as any part of speech', () {
      expect(parser.parse([
        _joker(),
        _c('run', PartOfSpeech.verb),
      ]), true);
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _joker(),
      ]), true);
    });

    test('rejects verb-first sentence', () {
      expect(parser.parse([
        _c('run', PartOfSpeech.verb),
        _c('I', PartOfSpeech.pronoun),
      ]), false);
    });

    test('rejects sentence with no verb', () {
      expect(parser.parse([
        _c('the', PartOfSpeech.article),
        _c('big', PartOfSpeech.adjective),
        _c('cat', PartOfSpeech.noun),
      ]), false);
    });

    test('rejects dangling preposition', () {
      expect(parser.parse([
        _c('I', PartOfSpeech.pronoun),
        _c('run', PartOfSpeech.verb),
        _c('in', PartOfSpeech.preposition),
      ]), false);
    });

    test('rejects single card', () {
      expect(parser.parse([_c('I', PartOfSpeech.pronoun)]), false);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/grammar/sentence_parser_test.dart`
Expected: FAIL — `sentence_parser.dart` 파일이 없어 컴파일 에러.

- [ ] **Step 3: Write the parser**

`lib/engine/grammar/sentence_parser.dart`:

```dart
import '../../models/word_card.dart';

/// Recursive-descent parser for the sentence grammar.
///
///   S     := NP VP
///   NP    := Pronoun | (Art)? (Adj)* Noun
///   AdjP  := (Adv)* Adj+
///   PP    := Prep NP
///   VP    := Verb (NP | AdjP)? (Adv)? (PP)*
///
/// Every `_parseX` returns the set of positions the parse could end at,
/// which is how optional and repeated elements are explored without
/// committing to a single path. JOKER cards match any part of speech.
class SentenceParser {
  /// True if [cards] form a complete, fully-consumed sentence.
  bool parse(List<WordCard> cards) {
    if (cards.length < 2) return false;

    for (final npEnd in _parseNP(cards, 0)) {
      for (final vpEnd in _parseVP(cards, npEnd)) {
        if (vpEnd == cards.length) return true;
      }
    }
    return false;
  }

  bool _is(List<WordCard> c, int i, PartOfSpeech pos) {
    if (i < 0 || i >= c.length) return false;
    if (c[i].type == CardType.joker) return true;
    return c[i].pos == pos;
  }

  /// NP := Pronoun | (Art)? (Adj)* Noun
  List<int> _parseNP(List<WordCard> c, int i) {
    final out = <int>{};

    if (_is(c, i, PartOfSpeech.pronoun)) out.add(i + 1);

    final starts = <int>[i];
    if (_is(c, i, PartOfSpeech.article)) starts.add(i + 1);

    for (final s in starts) {
      var k = s;
      while (true) {
        if (_is(c, k, PartOfSpeech.noun)) out.add(k + 1);
        if (_is(c, k, PartOfSpeech.adjective)) {
          k++;
        } else {
          break;
        }
      }
    }
    return out.toList();
  }

  /// AdjP := (Adv)* Adj+
  List<int> _parseAdjP(List<WordCard> c, int i) {
    final out = <int>{};

    final starts = <int>{i};
    var k = i;
    while (_is(c, k, PartOfSpeech.adverb)) {
      k++;
      starts.add(k);
    }

    for (final s in starts) {
      var j = s;
      while (_is(c, j, PartOfSpeech.adjective)) {
        j++;
        out.add(j);
      }
    }
    return out.toList();
  }

  /// PP := Prep NP
  List<int> _parsePP(List<WordCard> c, int i) {
    if (!_is(c, i, PartOfSpeech.preposition)) return const [];
    return _parseNP(c, i + 1);
  }

  /// VP := Verb (NP | AdjP)? (Adv)? (PP)*
  List<int> _parseVP(List<WordCard> c, int i) {
    if (!_is(c, i, PartOfSpeech.verb)) return const [];

    // Verb consumed.
    final afterVerb = <int>{i + 1};

    // Optional complement: NP or AdjP.
    final afterComplement = <int>{...afterVerb};
    for (final e in afterVerb) {
      afterComplement.addAll(_parseNP(c, e));
      afterComplement.addAll(_parseAdjP(c, e));
    }

    // Optional trailing adverb.
    final afterAdverb = <int>{...afterComplement};
    for (final e in afterComplement) {
      if (_is(c, e, PartOfSpeech.adverb)) afterAdverb.add(e + 1);
    }

    // Zero or more prepositional phrases. Positions strictly increase,
    // so the worklist always terminates.
    final result = <int>{...afterAdverb};
    final queue = <int>[...afterAdverb];
    while (queue.isNotEmpty) {
      final e = queue.removeLast();
      for (final p in _parsePP(c, e)) {
        if (result.add(p)) queue.add(p);
      }
    }

    return result.toList();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/engine/grammar/sentence_parser_test.dart`
Expected: PASS (13 tests)

- [ ] **Step 5: Replace StructureRule with the parser**

`lib/engine/grammar/rules/structure_rule.dart` 전체를 다음으로 교체:

```dart
import '../../../models/word_card.dart';
import '../grammar_engine.dart';
import '../sentence_parser.dart';

/// Validates that the sentence forms a complete structure (S := NP VP).
class StructureRule extends GrammarRule {
  final SentenceParser _parser;

  StructureRule({SentenceParser? parser})
      : _parser = parser ?? SentenceParser();

  @override
  List<ValidationError> validate(List<WordCard> sentence) {
    if (_parser.parse(sentence)) return const [];

    final display = sentence.map((c) => c.word).join(' ');
    return [
      ValidationError(
        code: 'invalid_structure',
        message: 'Not a complete sentence: $display',
        localizedMessages: {
          'ko': '완전한 문장이 아닙니다: $display',
          'ja': '完全な文ではありません: $display',
        },
      ),
    ];
  }
}
```

- [ ] **Step 6: Delete the template file**

```bash
rm lib/engine/grammar/sentence_templates.dart
```

- [ ] **Step 7: Run the full grammar suite (regression gate)**

Run: `flutter test test/engine/grammar/`
Expected: PASS — 기존 21개 + 신규 13개 = 34개 전부 통과.

만약 `"I am happy"` 또는 `"big red ball"` 계열 테스트가 실패하면 `_parseAdjP`가 VP 보어로 연결되지 않은 것이므로 Step 3의 `afterComplement` 블록을 확인한다.

- [ ] **Step 8: Verify analyze is clean and commit**

```bash
flutter analyze
git add lib/engine/grammar test/engine/grammar
git commit -m "refactor: replace hardcoded sentence templates with recursive chunk parser"
```

---

### Task 2: 카드 타입 정리 및 품사 시각 속성

`CardType`에서 `skip`/`undo`를 제거하고 `jump`를 도입한다. 몬테소리 문법 기호에 따른 품사별 색·도형을 파생 속성으로 노출한다.

**Files:**
- Modify: `lib/models/word_card.dart`
- Test: `test/models/word_card_test.dart`

**Interfaces:**
- Produces:
  - `enum CardType { word, jump, steal, joker }`
  - `WordCard.posColor -> int` (ARGB 정수)
  - `WordCard.posShape -> PosShape`
  - `enum PosShape { triangleLarge, triangleSmall, triangleMedium, circle, circleSmall, crescent, none }`

- [ ] **Step 1: Write the failing test**

`test/models/word_card_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/word_card.dart';

void main() {
  group('CardType', () {
    test('has exactly word, jump, steal, joker', () {
      expect(CardType.values.length, 4);
      expect(CardType.values.contains(CardType.jump), true);
      expect(CardType.values.contains(CardType.steal), true);
      expect(CardType.values.contains(CardType.joker), true);
    });
  });

  group('Montessori part-of-speech symbols', () {
    WordCard c(PartOfSpeech pos) =>
        WordCard(id: 'x', word: 'w', pos: pos);

    test('noun is black large triangle', () {
      expect(c(PartOfSpeech.noun).posShape, PosShape.triangleLarge);
      expect(c(PartOfSpeech.noun).posColor, 0xFF1F2937);
    });

    test('verb is red circle', () {
      expect(c(PartOfSpeech.verb).posShape, PosShape.circle);
      expect(c(PartOfSpeech.verb).posColor, 0xFFDC2626);
    });

    test('preposition is green crescent', () {
      expect(c(PartOfSpeech.preposition).posShape, PosShape.crescent);
      expect(c(PartOfSpeech.preposition).posColor, 0xFF16A34A);
    });

    test('special cards have no part-of-speech shape', () {
      expect(WordCard.special('j', CardType.joker).posShape, PosShape.none);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/word_card_test.dart`
Expected: FAIL — `CardType.jump`, `PosShape`, `posColor` 미정의.

- [ ] **Step 3: Implement**

`lib/models/word_card.dart`에서 enum 교체:

```dart
enum CardType { word, jump, steal, joker }

/// Montessori grammar symbol shapes.
enum PosShape {
  triangleLarge,   // noun
  triangleMedium,  // adjective
  triangleSmall,   // article
  trianglePronoun, // pronoun
  circle,          // verb
  circleSmall,     // adverb
  crescent,        // preposition
  none,            // special cards
}
```

`WordCard` 클래스 본문에 추가:

```dart
  /// Montessori grammar symbol shape for this card's part of speech.
  PosShape get posShape {
    if (isSpecial) return PosShape.none;
    switch (pos) {
      case PartOfSpeech.noun:
        return PosShape.triangleLarge;
      case PartOfSpeech.adjective:
        return PosShape.triangleMedium;
      case PartOfSpeech.article:
        return PosShape.triangleSmall;
      case PartOfSpeech.pronoun:
        return PosShape.trianglePronoun;
      case PartOfSpeech.verb:
        return PosShape.circle;
      case PartOfSpeech.adverb:
        return PosShape.circleSmall;
      case PartOfSpeech.preposition:
        return PosShape.crescent;
      default:
        return PosShape.none;
    }
  }

  /// ARGB colour for this card's part of speech (Montessori convention).
  int get posColor {
    if (isSpecial) return 0xFF8B5CF6;
    switch (pos) {
      case PartOfSpeech.noun:
        return 0xFF1F2937; // black
      case PartOfSpeech.adjective:
        return 0xFF1E3A8A; // navy
      case PartOfSpeech.article:
        return 0xFF7DD3FC; // light blue
      case PartOfSpeech.pronoun:
        return 0xFF7C3AED; // purple
      case PartOfSpeech.verb:
        return 0xFFDC2626; // red
      case PartOfSpeech.adverb:
        return 0xFFF97316; // orange
      case PartOfSpeech.preposition:
        return 0xFF16A34A; // green
      default:
        return 0xFF6B7280;
    }
  }
```

`PartOfSpeech` enum에서 `conjunction`을 제거한다 (덱에서 접속사가 빠지므로).

- [ ] **Step 4: Fix all compile errors from the enum change**

`CardType.skip` / `CardType.undo` 참조를 모두 찾아 수정한다:

```bash
grep -rn "CardType.skip\|CardType.undo\|PartOfSpeech.conjunction" lib/ test/
```

이 시점에는 다음 파일들이 깨진다 — 각 파일의 해당 분기를 **일단 삭제**한다 (Task 7에서 JUMP/STEAL 로직을 새로 쓴다):
- `lib/providers/game_provider.dart` — `playSpecialCard`의 `skip`/`undo` case
- `lib/engine/ai/ai_player.dart` — `_tryPlaySpecial`의 `skip`/`undo` case
- `lib/game/components/card_component.dart` — `cardColor`, `_specialIcon`의 case (`jump`는 `⏭`, `steal`은 `🫳`)
- `lib/data/card_deck.dart` — `_specialCards()` 및 `_conjunctions()`

- [ ] **Step 5: Run tests**

Run: `flutter test test/models/word_card_test.dart && flutter analyze`
Expected: 테스트 PASS, analyze 경고 0.

- [ ] **Step 6: Commit**

```bash
git add lib/models/word_card.dart test/models/word_card_test.dart lib/ 
git commit -m "refactor: unify SKIP into JUMP, drop UNDO, add Montessori part-of-speech symbols"
```

---

### Task 3: 카드 덱 재구성

덱을 110장으로 재구성하고, 전역 가변 ID 카운터를 인스턴스 소유로 바꾸며, 초기 손패 보장 헬퍼를 추가한다.

**Files:**
- Modify: `lib/data/card_deck.dart`
- Test: `test/data/card_deck_test.dart`

**Interfaces:**
- Produces:
  - `CardDeck()` — 인스턴스 생성자 (기존 static 유지 불가)
  - `CardDeck.generate() -> List<WordCard>` (인스턴스 메서드)
  - `CardDeck.dealGuaranteedHands({required List<WordCard> deck, required int playerCount, required int handSize}) -> (List<List<WordCard>> hands, List<WordCard> remainingDeck)`

- [ ] **Step 1: Write the failing test**

`test/data/card_deck_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/data/card_deck.dart';
import 'package:dripple/models/word_card.dart';

void main() {
  group('CardDeck composition', () {
    test('generates 110 cards', () {
      expect(CardDeck().generate().length, 110);
    });

    test('has the specified part-of-speech distribution', () {
      final deck = CardDeck().generate();
      int countPos(PartOfSpeech p) =>
          deck.where((c) => c.type == CardType.word && c.pos == p).length;

      expect(countPos(PartOfSpeech.pronoun), 12);
      expect(countPos(PartOfSpeech.article), 10);
      expect(countPos(PartOfSpeech.noun), 26);
      expect(countPos(PartOfSpeech.verb), 26);
      expect(countPos(PartOfSpeech.adjective), 12);
      expect(countPos(PartOfSpeech.adverb), 6);
      expect(countPos(PartOfSpeech.preposition), 8);
    });

    test('has 4 jokers, 3 jumps, 3 steals', () {
      final deck = CardDeck().generate();
      expect(deck.where((c) => c.type == CardType.joker).length, 4);
      expect(deck.where((c) => c.type == CardType.jump).length, 3);
      expect(deck.where((c) => c.type == CardType.steal).length, 3);
    });

    test('contains no conjunctions', () {
      final deck = CardDeck().generate();
      expect(deck.any((c) => c.word == 'and' || c.word == 'but'), false);
    });

    test('all card ids are unique', () {
      final deck = CardDeck().generate();
      expect(deck.map((c) => c.id).toSet().length, deck.length);
    });

    test('two independent decks do not share ids', () {
      final a = CardDeck().generate();
      final b = CardDeck().generate();
      // Independent instances restart their counters, so ids collide by
      // design; what matters is that each deck is internally unique.
      expect(a.map((c) => c.id).toSet().length, a.length);
      expect(b.map((c) => c.id).toSet().length, b.length);
    });
  });

  group('Guaranteed opening hands', () {
    test('every hand has at least one verb and one subject-capable card', () {
      for (var trial = 0; trial < 50; trial++) {
        final deck = CardDeck().generate()..shuffle();
        final (hands, _) = CardDeck.dealGuaranteedHands(
          deck: deck,
          playerCount: 4,
          handSize: 7,
        );
        expect(hands.length, 4);
        for (final hand in hands) {
          expect(hand.length, 7);
          expect(hand.any((c) => c.isVerb), true,
              reason: 'hand without a verb: ${hand.map((c) => c.word)}');
          expect(hand.any((c) => c.canBeSubject), true,
              reason: 'hand without a subject: ${hand.map((c) => c.word)}');
        }
      }
    });

    test('dealt cards are removed from the remaining deck', () {
      final deck = CardDeck().generate()..shuffle();
      final (hands, rest) = CardDeck.dealGuaranteedHands(
        deck: deck,
        playerCount: 4,
        handSize: 7,
      );
      expect(rest.length, 110 - 28);
      final dealtIds = hands.expand((h) => h).map((c) => c.id).toSet();
      expect(rest.any((c) => dealtIds.contains(c.id)), false);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/card_deck_test.dart`
Expected: FAIL — `CardDeck()` 생성자 및 `dealGuaranteedHands` 미정의.

- [ ] **Step 3: Convert CardDeck to an instance and adjust composition**

`lib/data/card_deck.dart`에서:

1. `static int _idCounter = 0;` → `int _idCounter = 0;` (인스턴스 필드)
2. `static String _nextId()` → `String _nextId() => 'card_${_idCounter++}';`
3. `static void resetIds()` 삭제
4. `static List<WordCard> generateDeck()` → `List<WordCard> generate()`
5. 모든 `static List<WordCard> _pronouns()` 등에서 `static` 제거
6. `_conjunctions()` 메서드와 `generate()` 안의 호출 삭제

매수를 스펙에 맞춘다 (기존 → 목표):
- 대명사 8 → **12**: 기존 8장에 `I`, `you`(단수), `he`, `we` 각 1장씩 중복 추가
- 관사 7 → **10**: `a` 1장, `an` 1장, `the` 1장 추가
- 명사 30 → **26**: 사용 빈도가 낮은 명사 4장 제거 (단수·복수 짝은 깨지 않게 2쌍 제거)
- 동사 24 → **26**: `am`, `are` 추가 (`is`가 이미 있는지 확인하고 없으면 `is`도 포함해 조정), `can` 추가
- 형용사 14 → **12**: `adjOrder`가 중복되는 2장 제거
- 부사 4 → **6**: `very`, `slowly` 추가
- 전치사 4 → **8**: `in` / `on` / `under` / `with` 각 2장
- 특수 13 → **10**: JOKER 4, JUMP 3, STEAL 3

be동사 카드는 `SubjectVerbAgreementRule._beVerbMap`이 이미 처리하므로 `person`/`number` 없이 `word`만 정확하면 된다:

```dart
  List<WordCard> _verbs() => [
        // ... existing verbs ...
        WordCard(
          id: _nextId(), word: 'am', pos: PartOfSpeech.verb,
          person: 1, number: 'singular',
          meanings: {'ko': '~이다', 'ja': '~です', 'en': 'am'},
        ),
        WordCard(
          id: _nextId(), word: 'are', pos: PartOfSpeech.verb,
          person: 2, number: 'plural',
          meanings: {'ko': '~이다', 'ja': '~です', 'en': 'are'},
        ),
      ];
```

전치사:

```dart
  List<WordCard> _prepositions() => [
        for (final w in ['in', 'in', 'on', 'on', 'under', 'under', 'with', 'with'])
          WordCard(
            id: _nextId(), word: w, pos: PartOfSpeech.preposition,
            meanings: _prepMeanings[w]!,
          ),
      ];

  static const _prepMeanings = {
    'in': {'ko': '~안에', 'ja': '~の中に', 'en': 'in'},
    'on': {'ko': '~위에', 'ja': '~の上に', 'en': 'on'},
    'under': {'ko': '~아래에', 'ja': '~の下に', 'en': 'under'},
    'with': {'ko': '~와 함께', 'ja': '~と一緒に', 'en': 'with'},
  };
```

특수:

```dart
  List<WordCard> _specialCards() => [
        for (int i = 0; i < 4; i++) WordCard.special(_nextId(), CardType.joker),
        for (int i = 0; i < 3; i++) WordCard.special(_nextId(), CardType.jump),
        for (int i = 0; i < 3; i++) WordCard.special(_nextId(), CardType.steal),
      ];
```

- [ ] **Step 4: Implement guaranteed dealing**

`CardDeck`에 static 메서드로 추가:

```dart
  /// Deal [playerCount] hands of [handSize] cards, guaranteeing every hand
  /// contains at least one verb and at least one subject-capable card.
  ///
  /// Without this an opening hand can be unplayable, which for a 6–10 year
  /// old reads as the game being broken. Mirrors Scrabble's "redraw if you
  /// have no vowels" tournament rule.
  ///
  /// Returns the hands and the remaining deck.
  static (List<List<WordCard>>, List<WordCard>) dealGuaranteedHands({
    required List<WordCard> deck,
    required int playerCount,
    required int handSize,
  }) {
    final pool = List<WordCard>.from(deck);
    final hands = <List<WordCard>>[];

    WordCard? takeWhere(bool Function(WordCard) test) {
      final idx = pool.indexWhere(test);
      if (idx < 0) return null;
      return pool.removeAt(idx);
    }

    for (int p = 0; p < playerCount; p++) {
      final hand = <WordCard>[];

      final verb = takeWhere((c) => c.isVerb);
      if (verb != null) hand.add(verb);

      final subject = takeWhere((c) => c.canBeSubject);
      if (subject != null) hand.add(subject);

      while (hand.length < handSize && pool.isNotEmpty) {
        hand.add(pool.removeLast());
      }

      hand.shuffle();
      hands.add(hand);
    }

    return (hands, pool);
  }
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/data/card_deck_test.dart`
Expected: PASS (8 tests)

매수 테스트가 실패하면 실패 메시지의 실제 개수를 보고 Step 3의 카드 목록을 조정한다.

- [ ] **Step 6: Update call sites**

```bash
grep -rn "CardDeck.generateDeck\|CardDeck.resetIds" lib/ test/
```

`lib/providers/game_provider.dart`의 `CardDeck.generateDeck()` 호출을 `CardDeck().generate()`로 바꾼다 (Task 4에서 이 파일을 크게 고치므로 컴파일만 통과하면 된다).

- [ ] **Step 7: Commit**

```bash
flutter analyze
git add lib/data/card_deck.dart test/data/card_deck_test.dart lib/providers/game_provider.dart
git commit -m "feat: rebuild deck to 110 cards with prepositions, instance-scoped ids, guaranteed opening hands"
```

---

### Task 4: 게임 상태 구조 변경

러미 턴 구조를 표현할 수 있도록 `GameState` / `GameConfig`를 재정의한다. 라운드 개념을 제거한다.

**Files:**
- Modify: `lib/models/game_state.dart`
- Test: `test/models/game_state_test.dart`

**Interfaces:**
- Produces:
  - `enum GamePhase { setup, playing, gameEnd }`
  - `enum TurnPhase { draw, action }`
  - `GameState` 필드: `phase`, `turnPhase`, `players`, `deck`, `discardPile`, `currentPlayerIndex`, `config`, `turnTimeRemaining`, `deckRecycleCount`, `drawnFromDiscardCardId`, `winnerIndex`
  - `GameState.discardTop -> WordCard?`
  - `GameConfig` 필드: `playerCount`(기본 4), `initialHandSize`(기본 7), `turnTimerSeconds`(기본 0), `difficulty`
  - `GameState.ranking` — 남은 손패 수 오름차순

- [ ] **Step 1: Write the failing test**

`test/models/game_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';

WordCard _w(String id) => WordCard(id: id, word: id, pos: PartOfSpeech.noun);

void main() {
  group('GameConfig defaults', () {
    test('4 players, 7 cards, timer off', () {
      const c = GameConfig();
      expect(c.playerCount, 4);
      expect(c.initialHandSize, 7);
      expect(c.turnTimerSeconds, 0);
    });
  });

  group('GamePhase', () {
    test('has no roundEnd phase', () {
      expect(GamePhase.values.length, 3);
      expect(GamePhase.values.map((e) => e.name).contains('roundEnd'), false);
    });
  });

  group('GameState', () {
    test('discardTop returns the last discarded card', () {
      final s = GameState(discardPile: [_w('a'), _w('b')]);
      expect(s.discardTop?.id, 'b');
    });

    test('discardTop is null when the pile is empty', () {
      expect(const GameState().discardTop, null);
    });

    test('ranking sorts by fewest cards remaining', () {
      final s = GameState(players: [
        Player(id: 'a', name: 'A', hand: [_w('1'), _w('2')]),
        Player(id: 'b', name: 'B', hand: []),
        Player(id: 'c', name: 'C', hand: [_w('3')]),
      ]);
      expect(s.ranking.map((p) => p.id).toList(), ['b', 'c', 'a']);
    });

    test('copyWith can clear drawnFromDiscardCardId', () {
      final s = const GameState().copyWith(drawnFromDiscardCardId: 'x');
      expect(s.drawnFromDiscardCardId, 'x');
      expect(s.clearDrawnFromDiscard().drawnFromDiscardCardId, null);
    });

    test('turnPhase defaults to draw', () {
      expect(const GameState().turnPhase, TurnPhase.draw);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/game_state_test.dart`
Expected: FAIL — `TurnPhase`, `discardPile`, `discardTop` 등 미정의.

- [ ] **Step 3: Rewrite game_state.dart**

`lib/models/game_state.dart` 전체:

```dart
import 'package:equatable/equatable.dart';
import 'player.dart';
import 'word_card.dart';
import '../engine/ai/ai_player.dart';

enum GamePhase { setup, playing, gameEnd }

/// A turn is always "draw exactly one card, then take exactly one action".
enum TurnPhase { draw, action }

class GameConfig extends Equatable {
  final int playerCount;
  final int initialHandSize;
  /// 0 disables the countdown. Off by default — this is a children's game.
  final int turnTimerSeconds;
  final AIDifficulty difficulty;

  const GameConfig({
    this.playerCount = 4,
    this.initialHandSize = 7,
    this.turnTimerSeconds = 0,
    this.difficulty = AIDifficulty.medium,
  });

  @override
  List<Object?> get props =>
      [playerCount, initialHandSize, turnTimerSeconds, difficulty];
}

class GameState extends Equatable {
  final GamePhase phase;
  final TurnPhase turnPhase;
  final List<Player> players;
  final List<WordCard> deck;
  /// Face-up discard pile. The last element is the top card.
  final List<WordCard> discardPile;
  final int currentPlayerIndex;
  final GameConfig config;
  /// Seconds left on the current human turn. -1 means inactive.
  final int turnTimeRemaining;
  /// How many times the discard pile has been recycled into the deck.
  /// Two recycles followed by exhaustion ends the game (anti-stalling).
  final int deckRecycleCount;
  /// Id of the card taken from the discard pile this turn. Rummy forbids
  /// discarding it again on the same turn, which would otherwise let two
  /// players shuffle one card back and forth forever.
  final String? drawnFromDiscardCardId;
  final int? winnerIndex;

  const GameState({
    this.phase = GamePhase.setup,
    this.turnPhase = TurnPhase.draw,
    this.players = const [],
    this.deck = const [],
    this.discardPile = const [],
    this.currentPlayerIndex = 0,
    this.config = const GameConfig(),
    this.turnTimeRemaining = -1,
    this.deckRecycleCount = 0,
    this.drawnFromDiscardCardId,
    this.winnerIndex,
  });

  Player get currentPlayer {
    if (players.isEmpty || currentPlayerIndex >= players.length) {
      return const Player(id: '', name: '');
    }
    return players[currentPlayerIndex];
  }

  WordCard? get discardTop =>
      discardPile.isEmpty ? null : discardPile.last;

  bool get isGameOver => phase == GamePhase.gameEnd;

  /// Players ordered by fewest cards remaining — the win condition is
  /// emptying your hand, so this is the standing.
  List<Player> get ranking =>
      List<Player>.from(players)
        ..sort((a, b) => a.hand.length.compareTo(b.hand.length));

  GameState copyWith({
    GamePhase? phase,
    TurnPhase? turnPhase,
    List<Player>? players,
    List<WordCard>? deck,
    List<WordCard>? discardPile,
    int? currentPlayerIndex,
    GameConfig? config,
    int? turnTimeRemaining,
    int? deckRecycleCount,
    String? drawnFromDiscardCardId,
    int? winnerIndex,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      turnPhase: turnPhase ?? this.turnPhase,
      players: players ?? this.players,
      deck: deck ?? this.deck,
      discardPile: discardPile ?? this.discardPile,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      config: config ?? this.config,
      turnTimeRemaining: turnTimeRemaining ?? this.turnTimeRemaining,
      deckRecycleCount: deckRecycleCount ?? this.deckRecycleCount,
      drawnFromDiscardCardId:
          drawnFromDiscardCardId ?? this.drawnFromDiscardCardId,
      winnerIndex: winnerIndex ?? this.winnerIndex,
    );
  }

  /// copyWith cannot set a nullable field back to null, so clearing the
  /// discard-draw marker needs its own method.
  GameState clearDrawnFromDiscard() => GameState(
        phase: phase,
        turnPhase: turnPhase,
        players: players,
        deck: deck,
        discardPile: discardPile,
        currentPlayerIndex: currentPlayerIndex,
        config: config,
        turnTimeRemaining: turnTimeRemaining,
        deckRecycleCount: deckRecycleCount,
        drawnFromDiscardCardId: null,
        winnerIndex: winnerIndex,
      );

  @override
  List<Object?> get props => [
        phase,
        turnPhase,
        players,
        deck,
        discardPile,
        currentPlayerIndex,
        config,
        turnTimeRemaining,
        deckRecycleCount,
        drawnFromDiscardCardId,
        winnerIndex,
      ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/game_state_test.dart`
Expected: PASS (7 tests). `lib/providers/game_provider.dart`와 `lib/screens/game_screen.dart`는 아직 컴파일되지 않는다 — Task 5–6, 12에서 고친다.

- [ ] **Step 5: Commit**

```bash
git add lib/models/game_state.dart test/models/game_state_test.dart
git commit -m "feat: restructure GameState for rummy turn phases and discard pile"
```

---

### Task 5: 턴 규칙 — 뽑기 단계

`GameNotifier`를 새 상태 구조 위에 재작성하고 뽑기 단계를 구현한다. 이 태스크가 끝나면 프로젝트가 다시 컴파일된다.

**Files:**
- Modify: `lib/providers/game_provider.dart` (전면 재작성)
- Test: `test/providers/game_provider_draw_test.dart`

**Interfaces:**
- Consumes: `CardDeck().generate()`, `CardDeck.dealGuaranteedHands`, `GameState`, `TurnPhase`
- Produces:
  - `GameNotifier.startGame(GameConfig)`
  - `GameNotifier.drawFromDeck()`
  - `GameNotifier.drawFromDiscard()`
  - `gameProvider` (`StateNotifierProvider<GameNotifier, GameState>`)

- [ ] **Step 1: Write the failing test**

`test/providers/game_provider_draw_test.dart`:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/providers/game_provider.dart';

GameNotifier _notifier() => GameNotifier(random: Random(42), autoRunAI: false);

void main() {
  group('startGame', () {
    test('deals 7 cards to 4 players and opens one discard card', () {
      final n = _notifier();
      n.startGame(const GameConfig());

      expect(n.state.players.length, 4);
      for (final p in n.state.players) {
        expect(p.hand.length, 7);
      }
      expect(n.state.discardPile.length, 1);
      expect(n.state.deck.length, 110 - 28 - 1);
      expect(n.state.phase, GamePhase.playing);
      expect(n.state.turnPhase, TurnPhase.draw);
    });

    test('player 0 is human, the rest are AI', () {
      final n = _notifier();
      n.startGame(const GameConfig());
      expect(n.state.players[0].isAI, false);
      expect(n.state.players.skip(1).every((p) => p.isAI), true);
    });
  });

  group('drawFromDeck', () {
    test('adds one card to hand and moves to the action phase', () {
      final n = _notifier();
      n.startGame(const GameConfig());
      final before = n.state.deck.length;

      n.drawFromDeck();

      expect(n.state.players[0].hand.length, 8);
      expect(n.state.deck.length, before - 1);
      expect(n.state.turnPhase, TurnPhase.action);
    });

    test('is a no-op during the action phase', () {
      final n = _notifier();
      n.startGame(const GameConfig());
      n.drawFromDeck();
      final handSize = n.state.players[0].hand.length;

      n.drawFromDeck();

      expect(n.state.players[0].hand.length, handSize);
    });

    test('recycles the discard pile when the deck runs out', () {
      final n = _notifier();
      n.startGame(const GameConfig());
      // Drain the deck, leaving a discard pile to recycle.
      n.debugSetState(n.state.copyWith(
        deck: const [],
        discardPile: [
          WordCard(id: 'd1', word: 'cat', pos: PartOfSpeech.noun),
          WordCard(id: 'd2', word: 'dog', pos: PartOfSpeech.noun),
          WordCard(id: 'd3', word: 'run', pos: PartOfSpeech.verb),
        ],
      ));

      n.drawFromDeck();

      expect(n.state.deckRecycleCount, 1);
      // Top discard card stays; the other two became the deck, one of which
      // was immediately drawn.
      expect(n.state.discardPile.length, 1);
      expect(n.state.discardPile.single.id, 'd3');
      expect(n.state.deck.length, 1);
      expect(n.state.players[0].hand.length, 8);
    });
  });

  group('drawFromDiscard', () {
    test('takes the top discard card and marks it undiscardable', () {
      final n = _notifier();
      n.startGame(const GameConfig());
      final top = n.state.discardTop!;

      n.drawFromDiscard();

      expect(n.state.players[0].hand.any((c) => c.id == top.id), true);
      expect(n.state.discardPile, isEmpty);
      expect(n.state.drawnFromDiscardCardId, top.id);
      expect(n.state.turnPhase, TurnPhase.action);
    });

    test('is a no-op when the discard pile is empty', () {
      final n = _notifier();
      n.startGame(const GameConfig());
      n.debugSetState(n.state.copyWith(discardPile: const []));

      n.drawFromDiscard();

      expect(n.state.turnPhase, TurnPhase.draw);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/game_provider_draw_test.dart`
Expected: FAIL — 컴파일 에러 (`autoRunAI`, `drawFromDeck`, `debugSetState` 미정의).

- [ ] **Step 3: Rewrite game_provider.dart — skeleton plus the draw phase**

`lib/providers/game_provider.dart`를 다음으로 교체한다. 액션·특수카드·AI는 Task 6–10에서 채운다.

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/word_card.dart';
import '../data/card_deck.dart';
import '../engine/grammar/grammar_engine.dart';
import '../engine/ai/ai_player.dart';

/// Outcome of a sentence submission, surfaced to the UI for the judgment
/// dialog.
class JudgmentResult {
  final bool isCorrect;
  final List<ValidationError> errors;
  final String playerName;
  final List<WordCard> sentence;

  const JudgmentResult({
    required this.isCorrect,
    this.errors = const [],
    required this.playerName,
    required this.sentence,
  });
}

class GameNotifier extends StateNotifier<GameState> {
  final GrammarEngine _grammarEngine;
  final Random _random;
  AIPlayer _aiPlayer;

  /// Disabled in tests so turns can be stepped deterministically.
  final bool autoRunAI;

  Timer? _turnTimer;
  int _timerGeneration = 0;
  bool _isProcessingAI = false;

  GameNotifier({
    GrammarEngine? grammarEngine,
    AIPlayer? aiPlayer,
    Random? random,
    this.autoRunAI = true,
  })  : _grammarEngine = grammarEngine ?? GrammarEngine(),
        _aiPlayer = aiPlayer ?? AIPlayer(),
        _random = random ?? Random(),
        super(const GameState());

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  bool get isProcessingAI => _isProcessingAI;

  /// Test-only escape hatch for setting up specific board states.
  void debugSetState(GameState s) => state = s;

  // -------------------------------------------------------------------------
  // Setup
  // -------------------------------------------------------------------------

  void startGame(GameConfig config) {
    _isProcessingAI = false;
    _aiPlayer = AIPlayer(difficulty: config.difficulty);

    final deck = CardDeck().generate()..shuffle(_random);
    final (hands, remaining) = CardDeck.dealGuaranteedHands(
      deck: deck,
      playerCount: config.playerCount,
      handSize: config.initialHandSize,
    );

    final players = <Player>[
      Player(id: 'human_0', name: 'You', hand: hands[0]),
      for (int i = 1; i < config.playerCount; i++)
        Player(id: 'ai_$i', name: 'AI $i', isAI: true, hand: hands[i]),
    ];

    final workingDeck = List<WordCard>.from(remaining);
    // Open one card face up to seed the discard pile.
    final opener = workingDeck.removeLast();

    state = GameState(
      phase: GamePhase.playing,
      turnPhase: TurnPhase.draw,
      players: players,
      deck: workingDeck,
      discardPile: [opener],
      currentPlayerIndex: 0,
      config: config,
    );

    _startTurnTimer();
  }

  // -------------------------------------------------------------------------
  // Draw phase
  // -------------------------------------------------------------------------

  void drawFromDeck() {
    if (state.phase != GamePhase.playing) return;
    if (state.turnPhase != TurnPhase.draw) return;

    var working = state;
    if (working.deck.isEmpty) {
      working = _recycleDiscardIntoDeck(working);
      if (working.deck.isEmpty) {
        // Nothing left to draw: skip straight to the action phase.
        state = working.copyWith(turnPhase: TurnPhase.action);
        return;
      }
    }

    final newDeck = List<WordCard>.from(working.deck);
    final drawn = newDeck.removeLast();

    final players = List<Player>.from(working.players);
    final me = players[working.currentPlayerIndex];
    players[working.currentPlayerIndex] =
        me.copyWith(hand: [...me.hand, drawn]);

    state = working.copyWith(
      players: players,
      deck: newDeck,
      turnPhase: TurnPhase.action,
    );
  }

  void drawFromDiscard() {
    if (state.phase != GamePhase.playing) return;
    if (state.turnPhase != TurnPhase.draw) return;
    if (state.discardPile.isEmpty) return;

    final newPile = List<WordCard>.from(state.discardPile);
    final taken = newPile.removeLast();

    final players = List<Player>.from(state.players);
    final me = players[state.currentPlayerIndex];
    players[state.currentPlayerIndex] =
        me.copyWith(hand: [...me.hand, taken]);

    state = state.copyWith(
      players: players,
      discardPile: newPile,
      turnPhase: TurnPhase.action,
      drawnFromDiscardCardId: taken.id,
    );
  }

  /// Shuffle the discard pile (minus its top card) back into the deck.
  GameState _recycleDiscardIntoDeck(GameState s) {
    if (s.discardPile.length <= 1) return s;

    final pile = List<WordCard>.from(s.discardPile);
    final top = pile.removeLast();
    pile.shuffle(_random);

    return s.copyWith(
      deck: pile,
      discardPile: [top],
      deckRecycleCount: s.deckRecycleCount + 1,
    );
  }

  // -------------------------------------------------------------------------
  // Turn timer
  // -------------------------------------------------------------------------

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;

    final seconds = state.config.turnTimerSeconds;
    if (seconds <= 0 || state.currentPlayer.isAI) {
      if (state.turnTimeRemaining != -1) {
        state = state.copyWith(turnTimeRemaining: -1);
      }
      return;
    }

    state = state.copyWith(turnTimeRemaining: seconds);
    final generation = ++_timerGeneration;

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || generation != _timerGeneration) return;
      if (state.phase != GamePhase.playing) {
        _turnTimer?.cancel();
        return;
      }
      final next = state.turnTimeRemaining - 1;
      if (next <= 0) {
        _turnTimer?.cancel();
        _forfeitTurn();
      } else {
        state = state.copyWith(turnTimeRemaining: next);
      }
    });
  }

  void _cancelTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
    _timerGeneration++;
    if (state.turnTimeRemaining != -1) {
      state = state.copyWith(turnTimeRemaining: -1);
    }
  }

  /// Timer expiry: return sentence-zone cards to hand and end the turn.
  void _forfeitTurn() {
    if (state.phase != GamePhase.playing) return;
    final me = state.currentPlayer;
    if (me.sentenceZone.isNotEmpty) {
      _updateCurrentPlayer(me.copyWith(
        hand: [...me.hand, ...me.sentenceZone],
        sentenceZone: const [],
      ));
    }
    endTurn();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _updateCurrentPlayer(Player updated) {
    final players = List<Player>.from(state.players);
    players[state.currentPlayerIndex] = updated;
    state = state.copyWith(players: players);
  }

  /// Implemented in Task 6.
  void endTurn() {}
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
```

`Player.copyWith`가 `hand`/`sentenceZone`/`score`만 받으므로 그대로 쓸 수 있다.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/providers/game_provider_draw_test.dart`
Expected: PASS (7 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/providers/game_provider.dart test/providers/game_provider_draw_test.dart
git commit -m "feat: implement rummy draw phase with discard pile and deck recycling"
```

---

### Task 6: 턴 규칙 — 액션 단계와 승리 판정

문장 완성, 버리기, 턴 종료, 승리 판정을 구현한다.

**Files:**
- Modify: `lib/providers/game_provider.dart`
- Test: `test/providers/game_provider_action_test.dart`

**Interfaces:**
- Consumes: `GameNotifier.drawFromDeck()`, `GrammarEngine.validate`
- Produces:
  - `GameNotifier.placeCard(int handIndex)`
  - `GameNotifier.removeFromSentence(int sentenceIndex)`
  - `GameNotifier.reorderSentence(int from, int to)`
  - `GameNotifier.submitSentence() -> JudgmentResult`
  - `GameNotifier.discardCard(int handIndex) -> bool`
  - `GameNotifier.endTurn()`

- [ ] **Step 1: Write the failing test**

`test/providers/game_provider_action_test.dart`:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/providers/game_provider.dart';

WordCard _pron(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.pronoun, person: 1, number: 'singular');
WordCard _verb(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.verb, person: 1, number: 'plural');
WordCard _noun(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.noun, person: 3, number: 'plural');

/// A board where player 0 holds exactly "I like cats" plus one spare noun.
GameNotifier _board({List<WordCard>? hand, List<WordCard>? discard}) {
  final n = GameNotifier(random: Random(1), autoRunAI: false);
  n.debugSetState(GameState(
    phase: GamePhase.playing,
    turnPhase: TurnPhase.action,
    players: [
      Player(
        id: 'human_0',
        name: 'You',
        hand: hand ??
            [_pron('c1', 'I'), _verb('c2', 'like'), _noun('c3', 'cats'),
             _noun('c4', 'dogs')],
      ),
      const Player(id: 'ai_1', name: 'AI 1', isAI: true),
    ],
    deck: [_noun('d1', 'birds')],
    discardPile: discard ?? [_noun('x1', 'fish')],
  ));
  return n;
}

void main() {
  group('sentence zone editing', () {
    test('placeCard moves a card from hand to the sentence zone', () {
      final n = _board();
      n.placeCard(0);
      expect(n.state.players[0].hand.length, 3);
      expect(n.state.players[0].sentenceZone.single.id, 'c1');
    });

    test('removeFromSentence returns any card, not just the last', () {
      final n = _board();
      n.placeCard(0);
      n.placeCard(0); // now 'like'
      n.removeFromSentence(0); // remove 'I'
      expect(n.state.players[0].sentenceZone.single.id, 'c2');
      expect(n.state.players[0].hand.any((c) => c.id == 'c1'), true);
    });

    test('reorderSentence moves a card to a new index', () {
      final n = _board();
      n.placeCard(1); // like
      n.placeCard(0); // I
      expect(n.state.players[0].sentenceZone.map((c) => c.id).toList(),
          ['c2', 'c1']);

      n.reorderSentence(1, 0);

      expect(n.state.players[0].sentenceZone.map((c) => c.id).toList(),
          ['c1', 'c2']);
    });
  });

  group('submitSentence', () {
    test('valid sentence leaves the hand and ends the turn', () {
      final n = _board();
      n.placeCard(0); // I
      n.placeCard(0); // like
      n.placeCard(0); // cats

      final result = n.submitSentence();

      expect(result.isCorrect, true);
      expect(n.state.players[0].hand.length, 1);
      expect(n.state.players[0].sentenceZone, isEmpty);
      expect(n.state.currentPlayerIndex, 1);
      expect(n.state.turnPhase, TurnPhase.draw);
    });

    test('invalid sentence returns cards and does NOT end the turn', () {
      final n = _board();
      n.placeCard(1); // like
      n.placeCard(0); // I  -> "like I"

      final result = n.submitSentence();

      expect(result.isCorrect, false);
      expect(n.state.players[0].hand.length, 4);
      expect(n.state.players[0].sentenceZone, isEmpty);
      expect(n.state.currentPlayerIndex, 0, reason: 'turn must not advance');
      expect(n.state.turnPhase, TurnPhase.action);
    });

    test('emptying the hand wins the game immediately', () {
      final n = _board(hand: [
        _pron('c1', 'I'), _verb('c2', 'like'), _noun('c3', 'cats'),
      ]);
      n.placeCard(0);
      n.placeCard(0);
      n.placeCard(0);

      n.submitSentence();

      expect(n.state.phase, GamePhase.gameEnd);
      expect(n.state.winnerIndex, 0);
    });
  });

  group('discardCard', () {
    test('moves a card to the top of the discard pile and ends the turn', () {
      final n = _board();
      final ok = n.discardCard(3); // dogs

      expect(ok, true);
      expect(n.state.discardTop!.id, 'c4');
      expect(n.state.players[0].hand.length, 3);
      expect(n.state.currentPlayerIndex, 1);
    });

    test('refuses to discard the card taken from the discard pile', () {
      final n = _board();
      n.debugSetState(n.state.copyWith(drawnFromDiscardCardId: 'c4'));

      final ok = n.discardCard(3);

      expect(ok, false);
      expect(n.state.players[0].hand.length, 4);
      expect(n.state.currentPlayerIndex, 0);
    });

    test('is a no-op during the draw phase', () {
      final n = _board();
      n.debugSetState(n.state.copyWith(turnPhase: TurnPhase.draw));
      expect(n.discardCard(0), false);
    });
  });

  group('stalling guard', () {
    test('exhausting the deck after two recycles ends the game', () {
      final n = _board();
      n.debugSetState(n.state.copyWith(
        deck: const [],
        discardPile: [_noun('x1', 'fish')],
        deckRecycleCount: 2,
        turnPhase: TurnPhase.draw,
      ));

      n.drawFromDeck();

      expect(n.state.phase, GamePhase.gameEnd);
      // Player 1 holds no cards, so they win on fewest-cards.
      expect(n.state.winnerIndex, 1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/game_provider_action_test.dart`
Expected: FAIL — `placeCard`, `submitSentence`, `discardCard` 등 미정의.

- [ ] **Step 3: Implement the action phase**

`lib/providers/game_provider.dart`의 `endTurn()` 스텁을 삭제하고, `_updateCurrentPlayer` 위에 다음을 추가한다:

```dart
  // -------------------------------------------------------------------------
  // Sentence zone editing (free-form — a child who gets stuck must be able
  // to back out of any arrangement, not just undo the last card)
  // -------------------------------------------------------------------------

  void placeCard(int handIndex) {
    if (state.phase != GamePhase.playing) return;
    final me = state.currentPlayer;
    if (handIndex < 0 || handIndex >= me.hand.length) return;

    final card = me.hand[handIndex];
    // JUMP and STEAL are actions, not words.
    if (card.type == CardType.jump || card.type == CardType.steal) return;

    final hand = List<WordCard>.from(me.hand)..removeAt(handIndex);
    _updateCurrentPlayer(
      me.copyWith(hand: hand, sentenceZone: [...me.sentenceZone, card]),
    );
  }

  void removeFromSentence(int sentenceIndex) {
    if (state.phase != GamePhase.playing) return;
    final me = state.currentPlayer;
    if (sentenceIndex < 0 || sentenceIndex >= me.sentenceZone.length) return;

    final zone = List<WordCard>.from(me.sentenceZone);
    final card = zone.removeAt(sentenceIndex);
    _updateCurrentPlayer(
      me.copyWith(hand: [...me.hand, card], sentenceZone: zone),
    );
  }

  void reorderSentence(int from, int to) {
    if (state.phase != GamePhase.playing) return;
    final me = state.currentPlayer;
    final zone = List<WordCard>.from(me.sentenceZone);
    if (from < 0 || from >= zone.length) return;
    if (to < 0 || to >= zone.length) return;
    if (from == to) return;

    final card = zone.removeAt(from);
    zone.insert(to, card);
    _updateCurrentPlayer(me.copyWith(sentenceZone: zone));
  }

  // -------------------------------------------------------------------------
  // Action phase
  // -------------------------------------------------------------------------

  /// Validate the sentence zone. On success the cards leave the hand for
  /// good and the turn ends. On failure the cards return to hand and the
  /// turn continues — failure must not cost a child their turn.
  JudgmentResult submitSentence() {
    final me = state.currentPlayer;
    final submitted = List<WordCard>.from(me.sentenceZone);

    if (state.phase != GamePhase.playing ||
        state.turnPhase != TurnPhase.action) {
      return JudgmentResult(
        isCorrect: false, playerName: me.name, sentence: submitted,
      );
    }

    final result = _grammarEngine.validate(submitted);

    if (!result.isValid) {
      _updateCurrentPlayer(me.copyWith(
        hand: [...me.hand, ...submitted],
        sentenceZone: const [],
      ));
      return JudgmentResult(
        isCorrect: false,
        errors: result.errors,
        playerName: me.name,
        sentence: submitted,
      );
    }

    _updateCurrentPlayer(me.copyWith(sentenceZone: const []));

    final judgment = JudgmentResult(
      isCorrect: true, playerName: me.name, sentence: submitted,
    );

    if (state.currentPlayer.hand.isEmpty) {
      _endGame(winnerIndex: state.currentPlayerIndex);
    } else {
      endTurn();
    }
    return judgment;
  }

  /// Discard one card face up. Returns false if the discard is illegal.
  bool discardCard(int handIndex) {
    if (state.phase != GamePhase.playing) return false;
    if (state.turnPhase != TurnPhase.action) return false;

    final me = state.currentPlayer;
    if (handIndex < 0 || handIndex >= me.hand.length) return false;

    final card = me.hand[handIndex];
    // Rummy: the card you just took from the pile cannot go straight back.
    if (card.id == state.drawnFromDiscardCardId) return false;

    final hand = List<WordCard>.from(me.hand)..removeAt(handIndex);
    final players = List<Player>.from(state.players);
    players[state.currentPlayerIndex] = me.copyWith(hand: hand);

    state = state.copyWith(
      players: players,
      discardPile: [...state.discardPile, card],
    );

    if (hand.isEmpty) {
      _endGame(winnerIndex: state.currentPlayerIndex);
    } else {
      endTurn();
    }
    return true;
  }

  // -------------------------------------------------------------------------
  // Turn advance / game end
  // -------------------------------------------------------------------------

  /// Advance to [skip]+1 players ahead. JUMP passes skip: 1.
  void endTurn({int skip = 0}) {
    if (state.phase != GamePhase.playing) return;
    _cancelTurnTimer();

    // Any cards left staged in the sentence zone go back to hand.
    final me = state.currentPlayer;
    var working = state;
    if (me.sentenceZone.isNotEmpty) {
      final players = List<Player>.from(working.players);
      players[working.currentPlayerIndex] = me.copyWith(
        hand: [...me.hand, ...me.sentenceZone],
        sentenceZone: const [],
      );
      working = working.copyWith(players: players);
    }

    final next =
        (working.currentPlayerIndex + 1 + skip) % working.players.length;

    state = working
        .clearDrawnFromDiscard()
        .copyWith(currentPlayerIndex: next, turnPhase: TurnPhase.draw);

    _startTurnTimer();
    if (autoRunAI) unawaited(_runAITurnsIfNeeded());
  }

  void _endGame({required int winnerIndex}) {
    _cancelTurnTimer();
    state = state.copyWith(
      phase: GamePhase.gameEnd,
      winnerIndex: winnerIndex,
    );
  }

  /// Anti-stalling: after two recycles the deck running dry ends the game,
  /// and the player holding the fewest cards wins.
  void _endGameOnExhaustion() {
    final ranking = state.ranking;
    final winnerId = ranking.first.id;
    _endGame(
      winnerIndex: state.players.indexWhere((p) => p.id == winnerId),
    );
  }

  /// Implemented in Task 10.
  Future<void> _runAITurnsIfNeeded() async {}
```

`drawFromDeck`의 재활용 실패 분기를 스톨링 종료로 교체한다:

```dart
    var working = state;
    if (working.deck.isEmpty) {
      if (working.deckRecycleCount >= 2) {
        _endGameOnExhaustion();
        return;
      }
      working = _recycleDiscardIntoDeck(working);
      if (working.deck.isEmpty) {
        _endGameOnExhaustion();
        return;
      }
    }
```

파일 상단에 `import 'dart:async';`가 이미 있는지 확인한다 (`unawaited` 사용).

- [ ] **Step 4: Run tests**

Run: `flutter test test/providers/`
Expected: PASS — draw 7개 + action 10개.

- [ ] **Step 5: Commit**

```bash
flutter analyze
git add lib/providers/game_provider.dart test/providers/game_provider_action_test.dart
git commit -m "feat: implement action phase, free sentence-zone editing, win and stalling conditions"
```

---

### Task 7: 특수카드 JUMP / STEAL

**Files:**
- Modify: `lib/providers/game_provider.dart`
- Test: `test/providers/game_provider_special_test.dart`

**Interfaces:**
- Consumes: `GameNotifier.endTurn({int skip})`
- Produces:
  - `GameNotifier.playJump(int handIndex) -> bool`
  - `GameNotifier.playSteal(int handIndex, {required int targetPlayerIndex, required int giveCardIndex}) -> bool`

- [ ] **Step 1: Write the failing test**

`test/providers/game_provider_special_test.dart`:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/providers/game_provider.dart';

WordCard _noun(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.noun, person: 3, number: 'plural');

GameNotifier _board() {
  final n = GameNotifier(random: Random(7), autoRunAI: false);
  n.debugSetState(GameState(
    phase: GamePhase.playing,
    turnPhase: TurnPhase.action,
    players: [
      Player(id: 'human_0', name: 'You', hand: [
        WordCard.special('j1', CardType.jump),
        WordCard.special('s1', CardType.steal),
        _noun('c1', 'cats'),
      ]),
      Player(id: 'ai_1', name: 'AI 1', isAI: true, hand: [_noun('a1', 'dogs')]),
      Player(id: 'ai_2', name: 'AI 2', isAI: true, hand: [_noun('b1', 'birds')]),
      Player(id: 'ai_3', name: 'AI 3', isAI: true, hand: [_noun('e1', 'fish')]),
    ],
    deck: [_noun('d1', 'apples')],
    discardPile: [_noun('x1', 'water')],
  ));
  return n;
}

void main() {
  group('JUMP', () {
    test('skips the next player', () {
      final n = _board();
      expect(n.playJump(0), true);
      expect(n.state.currentPlayerIndex, 2, reason: 'player 1 is skipped');
      expect(n.state.players[0].hand.any((c) => c.id == 'j1'), false);
      expect(n.state.turnPhase, TurnPhase.draw);
    });

    test('is rejected during the draw phase', () {
      final n = _board();
      n.debugSetState(n.state.copyWith(turnPhase: TurnPhase.draw));
      expect(n.playJump(0), false);
    });

    test('is rejected when the card is not a JUMP', () {
      final n = _board();
      expect(n.playJump(2), false);
    });
  });

  group('STEAL', () {
    test('exchanges one card with the target and preserves hand sizes', () {
      final n = _board();
      // Hand after removing the STEAL card: [jump, cats] -> give index 1.
      expect(
        n.playSteal(1, targetPlayerIndex: 2, giveCardIndex: 1),
        true,
      );

      final me = n.state.players[0];
      final target = n.state.players[2];

      expect(me.hand.length, 2, reason: 'STEAL spent, one given, one taken');
      expect(target.hand.length, 1, reason: 'one taken, one received');
      expect(me.hand.any((c) => c.id == 'b1'), true);
      expect(target.hand.any((c) => c.id == 'c1'), true);
      expect(n.state.currentPlayerIndex, 1);
    });

    test('is rejected when targeting yourself', () {
      final n = _board();
      expect(
        n.playSteal(1, targetPlayerIndex: 0, giveCardIndex: 1),
        false,
      );
    });

    test('is rejected when the target has no cards', () {
      final n = _board();
      final players = List<Player>.from(n.state.players);
      players[2] = players[2].copyWith(hand: const []);
      n.debugSetState(n.state.copyWith(players: players));

      expect(
        n.playSteal(1, targetPlayerIndex: 2, giveCardIndex: 1),
        false,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/game_provider_special_test.dart`
Expected: FAIL — `playJump` / `playSteal` 미정의.

- [ ] **Step 3: Implement**

`lib/providers/game_provider.dart`의 액션 섹션에 추가:

```dart
  /// JUMP: skip the next player's turn. Costs the turn's single action.
  bool playJump(int handIndex) {
    if (state.phase != GamePhase.playing) return false;
    if (state.turnPhase != TurnPhase.action) return false;

    final me = state.currentPlayer;
    if (handIndex < 0 || handIndex >= me.hand.length) return false;
    if (me.hand[handIndex].type != CardType.jump) return false;

    final hand = List<WordCard>.from(me.hand)..removeAt(handIndex);
    _updateCurrentPlayer(me.copyWith(hand: hand));

    if (hand.isEmpty) {
      _endGame(winnerIndex: state.currentPlayerIndex);
      return true;
    }
    endTurn(skip: 1);
    return true;
  }

  /// STEAL: take one random card from [targetPlayerIndex] and give them one
  /// card of your choosing. Opponent hands are hidden, so the player picks
  /// the victim, not the card.
  ///
  /// [giveCardIndex] indexes the hand *after* the STEAL card is removed.
  bool playSteal(
    int handIndex, {
    required int targetPlayerIndex,
    required int giveCardIndex,
  }) {
    if (state.phase != GamePhase.playing) return false;
    if (state.turnPhase != TurnPhase.action) return false;
    if (targetPlayerIndex == state.currentPlayerIndex) return false;
    if (targetPlayerIndex < 0 ||
        targetPlayerIndex >= state.players.length) return false;

    final me = state.currentPlayer;
    if (handIndex < 0 || handIndex >= me.hand.length) return false;
    if (me.hand[handIndex].type != CardType.steal) return false;

    final target = state.players[targetPlayerIndex];
    if (target.hand.isEmpty) return false;

    final handAfterSteal = List<WordCard>.from(me.hand)..removeAt(handIndex);
    if (giveCardIndex < 0 || giveCardIndex >= handAfterSteal.length) {
      return false;
    }

    final stolenIndex = _random.nextInt(target.hand.length);
    final stolen = target.hand[stolenIndex];
    final given = handAfterSteal[giveCardIndex];

    final myHand = List<WordCard>.from(handAfterSteal)
      ..removeAt(giveCardIndex)
      ..add(stolen);
    final targetHand = List<WordCard>.from(target.hand)
      ..removeAt(stolenIndex)
      ..add(given);

    final players = List<Player>.from(state.players);
    players[state.currentPlayerIndex] = me.copyWith(hand: myHand);
    players[targetPlayerIndex] = target.copyWith(hand: targetHand);

    state = state.copyWith(players: players);

    if (myHand.isEmpty) {
      _endGame(winnerIndex: state.currentPlayerIndex);
      return true;
    }
    endTurn();
    return true;
  }
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/providers/`
Expected: PASS — 24개 전부.

- [ ] **Step 5: Commit**

```bash
flutter analyze
git add lib/providers/game_provider.dart test/providers/game_provider_special_test.dart
git commit -m "feat: implement JUMP and STEAL special card actions"
```

---

### Task 8: AI 문장 탐색 재작성

AI가 문장을 만들지 못하는 근본 원인(하드코딩 패턴 4개, 최대 4장)을 파서 기반 탐색으로 교체한다.

**Files:**
- Modify: `lib/engine/ai/ai_player.dart` (전면 재작성)
- Test: `test/engine/ai/ai_player_test.dart`

**Interfaces:**
- Consumes: `GrammarEngine.validate`, `GameState`, `Player`
- Produces:
  - `enum AIDifficulty { easy, medium, hard }` (유지)
  - `enum AIActionType { submitSentence, discard, playJump, playSteal }`
  - `AIAction` — `type`, `cards`, `specialCard`, `targetPlayerIndex`, `giveCardIndex`, `discardIndex`
  - `AIPlayer.findSentence(List<WordCard> hand) -> List<WordCard>?`
  - `AIPlayer.decideAction(Player me, GameState state) -> AIAction`

탐색 전략: 손패에서 문법적 다양성을 유지한 **후보 8장**을 뽑고, 길이를 내림차순으로 훑으며 순열을 검증한다. 8P7 = 40,320회 검증이 상한이라 Dart에서 즉시 끝난다.

- [ ] **Step 1: Write the failing test**

`test/engine/ai/ai_player_test.dart`:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/engine/ai/ai_player.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';

WordCard _pron(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.pronoun, person: 1, number: 'singular');
WordCard _verb(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.verb, person: 1, number: 'plural');
WordCard _noun(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.noun, person: 3, number: 'plural');
WordCard _art(String id) => WordCard(
    id: id, word: 'the', pos: PartOfSpeech.article);
WordCard _prep(String id) => WordCard(
    id: id, word: 'in', pos: PartOfSpeech.preposition);

void main() {
  group('findSentence', () {
    test('finds a sentence in a hand that contains one', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final found = ai.findSentence([
        _noun('n1', 'cats'),
        _pron('p1', 'I'),
        _verb('v1', 'like'),
      ]);
      expect(found, isNotNull);
      expect(found!.length, greaterThanOrEqualTo(2));
      expect(found.map((c) => c.word).join(' '), 'I like cats');
    });

    test('hard difficulty prefers the longest sentence available', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final found = ai.findSentence([
        _pron('p1', 'I'),
        _verb('v1', 'like'),
        _art('a1'),
        _noun('n1', 'cats'),
        _prep('r1'),
        _art('a2'),
        _noun('n2', 'boxes'),
      ]);
      expect(found, isNotNull);
      expect(found!.length, greaterThan(3));
    });

    test('easy difficulty caps sentence length at 3', () {
      final ai = AIPlayer(difficulty: AIDifficulty.easy, random: Random(1));
      final found = ai.findSentence([
        _pron('p1', 'I'),
        _verb('v1', 'like'),
        _art('a1'),
        _noun('n1', 'cats'),
        _prep('r1'),
        _art('a2'),
        _noun('n2', 'boxes'),
      ]);
      expect(found, isNotNull);
      expect(found!.length, lessThanOrEqualTo(3));
    });

    test('returns null when no sentence is possible', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      expect(
        ai.findSentence([_art('a1'), _art('a2'), _prep('r1')]),
        null,
      );
    });

    test('returns cards that are the same instances as the hand', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_pron('p1', 'I'), _verb('v1', 'like'), _noun('n1', 'cats')];
      final found = ai.findSentence(hand)!;
      for (final c in found) {
        expect(hand.any((h) => identical(h, c)), true);
      }
    });
  });

  group('decideAction', () {
    GameState _state(List<WordCard> aiHand) => GameState(
          phase: GamePhase.playing,
          turnPhase: TurnPhase.action,
          currentPlayerIndex: 1,
          players: [
            Player(id: 'human_0', name: 'You', hand: [_noun('h1', 'cats')]),
            Player(id: 'ai_1', name: 'AI 1', isAI: true, hand: aiHand),
          ],
        );

    test('submits a sentence when one exists', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_pron('p1', 'I'), _verb('v1', 'like'), _noun('n1', 'cats')];
      final action = ai.decideAction(_state(hand).players[1], _state(hand));
      expect(action.type, AIActionType.submitSentence);
      expect(action.cards!.length, 3);
    });

    test('discards when no sentence is possible', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [_art('a1'), _art('a2'), _prep('r1')];
      final action = ai.decideAction(_state(hand).players[1], _state(hand));
      expect(action.type, AIActionType.discard);
      expect(action.discardIndex, inInclusiveRange(0, hand.length - 1));
    });

    test('plays JUMP when holding one and no sentence is possible', () {
      final ai = AIPlayer(difficulty: AIDifficulty.hard, random: Random(1));
      final hand = [
        _art('a1'),
        WordCard.special('j1', CardType.jump),
      ];
      final action = ai.decideAction(_state(hand).players[1], _state(hand));
      expect(action.type, AIActionType.playJump);
      expect(action.specialCard!.id, 'j1');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/engine/ai/ai_player_test.dart`
Expected: FAIL — `findSentence`, `decideAction`, `AIActionType.submitSentence` 미정의.

- [ ] **Step 3: Rewrite ai_player.dart**

`lib/engine/ai/ai_player.dart` 전체:

```dart
import 'dart:math';
import '../../models/word_card.dart';
import '../../models/player.dart';
import '../../models/game_state.dart';
import '../grammar/grammar_engine.dart';

/// How hard the AI plays.
///
/// - [easy]   – sentences up to 3 cards, discards at random 30 % of the time.
/// - [medium] – sentences up to 5 cards, discards at random 10 % of the time.
/// - [hard]   – no length cap, always plays the longest sentence it finds.
enum AIDifficulty { easy, medium, hard }

enum AIActionType { submitSentence, discard, playJump, playSteal }

class AIAction {
  final AIActionType type;
  /// For [AIActionType.submitSentence]: the cards in sentence order.
  final List<WordCard>? cards;
  final WordCard? specialCard;
  final int? targetPlayerIndex;
  /// Index into the hand *after* the STEAL card is removed.
  final int? giveCardIndex;
  final int? discardIndex;

  const AIAction({
    required this.type,
    this.cards,
    this.specialCard,
    this.targetPlayerIndex,
    this.giveCardIndex,
    this.discardIndex,
  });
}

/// Rule-based opponent.
///
/// Sentence search runs the real grammar engine over permutations of a
/// bounded candidate pool. The pool cap (8) keeps the worst case at
/// 8P7 = 40,320 validations, which is instant, while the diversity rule
/// below keeps the pool grammatically useful.
class AIPlayer {
  static const int _maxCandidates = 8;

  final GrammarEngine _engine;
  final Random _random;
  final AIDifficulty difficulty;

  AIPlayer({
    GrammarEngine? engine,
    Random? random,
    this.difficulty = AIDifficulty.medium,
  })  : _engine = engine ?? GrammarEngine(),
        _random = random ?? Random();

  int get _maxSentenceLength => switch (difficulty) {
        AIDifficulty.easy => 3,
        AIDifficulty.medium => 5,
        AIDifficulty.hard => 7,
      };

  double get _randomDiscardChance => switch (difficulty) {
        AIDifficulty.easy => 0.30,
        AIDifficulty.medium => 0.10,
        AIDifficulty.hard => 0.0,
      };

  /// Decide what to do in the action phase of the AI's turn.
  AIAction decideAction(Player me, GameState state) {
    if (_random.nextDouble() >= _randomDiscardChance) {
      final sentence = findSentence(me.hand);
      if (sentence != null) {
        return AIAction(
          type: AIActionType.submitSentence,
          cards: sentence,
        );
      }
    }

    final special = _tryPlaySpecial(me, state);
    if (special != null) return special;

    return AIAction(
      type: AIActionType.discard,
      discardIndex: _pickDiscardIndex(me.hand),
    );
  }

  /// Find a valid sentence in [hand], or null. Returns the actual card
  /// instances from [hand] so callers can remove them by identity or id.
  List<WordCard>? findSentence(List<WordCard> hand) {
    final pool = _candidatePool(hand);
    if (pool.length < 2) return null;

    final maxLen = min(_maxSentenceLength, pool.length);

    // Longest first: a longer sentence always empties the hand faster.
    for (int len = maxLen; len >= 2; len--) {
      final found = _searchPermutations(pool, len);
      if (found != null) return found;
    }
    return null;
  }

  /// Depth-first walk over ordered selections of exactly [len] cards.
  List<WordCard>? _searchPermutations(List<WordCard> pool, int len) {
    final used = List<bool>.filled(pool.length, false);
    final current = <WordCard>[];

    List<WordCard>? walk() {
      if (current.length == len) {
        return _engine.validate(current).isValid
            ? List<WordCard>.from(current)
            : null;
      }
      for (int i = 0; i < pool.length; i++) {
        if (used[i]) continue;
        used[i] = true;
        current.add(pool[i]);
        final result = walk();
        if (result != null) return result;
        current.removeLast();
        used[i] = false;
      }
      return null;
    }

    return walk();
  }

  /// Pick up to [_maxCandidates] cards, spreading them across parts of
  /// speech first so the pool can actually form a sentence. Taking the
  /// first 8 cards of a hand would often yield eight nouns.
  List<WordCard> _candidatePool(List<WordCard> hand) {
    final usable = hand
        .where((c) => c.type == CardType.word || c.type == CardType.joker)
        .toList();
    if (usable.length <= _maxCandidates) return usable;

    final buckets = <String, List<WordCard>>{};
    for (final card in usable) {
      final key = card.type == CardType.joker ? 'joker' : card.pos!.name;
      buckets.putIfAbsent(key, () => []).add(card);
    }

    final pool = <WordCard>[];
    // Round-robin across buckets until the pool is full.
    var added = true;
    while (pool.length < _maxCandidates && added) {
      added = false;
      for (final bucket in buckets.values) {
        if (pool.length >= _maxCandidates) break;
        if (bucket.isNotEmpty) {
          pool.add(bucket.removeAt(0));
          added = true;
        }
      }
    }
    return pool;
  }

  /// Use a special card when no sentence is available.
  AIAction? _tryPlaySpecial(Player me, GameState state) {
    final jump = me.hand.where((c) => c.type == CardType.jump).firstOrNull;
    final steal = me.hand.where((c) => c.type == CardType.steal).firstOrNull;

    if (steal != null) {
      // Target whoever is closest to winning — the fewest cards left.
      int? bestIdx;
      int bestCount = 1 << 30;
      for (int i = 0; i < state.players.length; i++) {
        if (i == state.currentPlayerIndex) continue;
        final count = state.players[i].hand.length;
        if (count > 0 && count < bestCount) {
          bestCount = count;
          bestIdx = i;
        }
      }
      if (bestIdx != null) {
        final handAfter = List<WordCard>.from(me.hand)
          ..removeWhere((c) => c.id == steal.id);
        if (handAfter.isNotEmpty) {
          return AIAction(
            type: AIActionType.playSteal,
            specialCard: steal,
            targetPlayerIndex: bestIdx,
            giveCardIndex: _pickDiscardIndex(handAfter),
          );
        }
      }
    }

    if (jump != null) {
      return AIAction(type: AIActionType.playJump, specialCard: jump);
    }

    return null;
  }

  /// Index of the least useful card to part with.
  int _pickDiscardIndex(List<WordCard> hand) {
    int usefulness(WordCard c) {
      if (c.type == CardType.joker) return 10;
      if (c.type == CardType.jump || c.type == CardType.steal) return 9;
      if (c.isVerb) return 8;
      if (c.canBeSubject) return 7;
      if (c.isArticle) return 4;
      if (c.isAdjective) return 3;
      return 2; // adverbs, prepositions
    }

    var bestIdx = 0;
    var bestScore = usefulness(hand[0]);
    for (int i = 1; i < hand.length; i++) {
      final s = usefulness(hand[i]);
      if (s < bestScore) {
        bestScore = s;
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/engine/ai/ai_player_test.dart`
Expected: PASS (8 tests)

`hard difficulty prefers the longest sentence` 가 실패하면 `_maxSentenceLength`의 hard 값이 7인지, `findSentence`가 길이를 내림차순으로 도는지 확인한다.

- [ ] **Step 5: Commit**

```bash
flutter analyze
git add lib/engine/ai/ai_player.dart test/engine/ai/ai_player_test.dart
git commit -m "fix: rewrite AI sentence search so the AI can actually submit sentences"
```

---

### Task 9: AI 턴 진행 소유권 이전

AI 진행 트리거를 `game_screen.dart`에서 `GameNotifier`로 옮긴다. 이것이 "턴이 멈추는" 버그의 근본 수정이다.

**Files:**
- Modify: `lib/providers/game_provider.dart`
- Test: `test/providers/game_provider_ai_turn_test.dart`

**Interfaces:**
- Consumes: `AIPlayer.decideAction`, `GameNotifier.drawFromDeck/discardCard/submitSentence/playJump/playSteal`
- Produces:
  - `GameNotifier.aiTurnDelay` (기본 `Duration(milliseconds: 700)`, 테스트에서 0)
  - `GameNotifier.runAITurns() -> Future<List<JudgmentResult>>`
  - `_runAITurnsIfNeeded()` 실제 구현

- [ ] **Step 1: Write the failing test**

`test/providers/game_provider_ai_turn_test.dart`:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/models/player.dart';
import 'package:dripple/models/word_card.dart';
import 'package:dripple/providers/game_provider.dart';
import 'package:dripple/engine/ai/ai_player.dart';

WordCard _pron(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.pronoun, person: 1, number: 'singular');
WordCard _verb(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.verb, person: 1, number: 'plural');
WordCard _noun(String id, String w) => WordCard(
    id: id, word: w, pos: PartOfSpeech.noun, person: 3, number: 'plural');

void main() {
  test('AI turns run to completion and control returns to the human', () async {
    final n = GameNotifier(
      random: Random(3),
      aiPlayer: AIPlayer(difficulty: AIDifficulty.hard, random: Random(3)),
      aiTurnDelay: Duration.zero,
      autoRunAI: false,
    );

    n.debugSetState(GameState(
      phase: GamePhase.playing,
      turnPhase: TurnPhase.draw,
      currentPlayerIndex: 1,
      players: [
        Player(id: 'human_0', name: 'You', hand: [_noun('h1', 'cats')]),
        Player(id: 'ai_1', name: 'AI 1', isAI: true, hand: [
          _pron('p1', 'I'), _verb('v1', 'like'), _noun('n1', 'cats'),
        ]),
        Player(id: 'ai_2', name: 'AI 2', isAI: true, hand: [
          _noun('n2', 'dogs'), _noun('n3', 'birds'),
        ]),
      ],
      deck: [
        _noun('d1', 'apples'), _noun('d2', 'pears'), _noun('d3', 'plums'),
      ],
      discardPile: [_noun('x1', 'water')],
    ));

    await n.runAITurns();

    expect(n.state.currentPlayerIndex, 0,
        reason: 'AI loop must hand control back to the human');
    expect(n.state.turnPhase, TurnPhase.draw);
  });

  test('AI actually plays sentences instead of only drawing', () async {
    final n = GameNotifier(
      random: Random(5),
      aiPlayer: AIPlayer(difficulty: AIDifficulty.hard, random: Random(5)),
      aiTurnDelay: Duration.zero,
      autoRunAI: false,
    );

    n.debugSetState(GameState(
      phase: GamePhase.playing,
      turnPhase: TurnPhase.draw,
      currentPlayerIndex: 1,
      players: [
        Player(id: 'human_0', name: 'You', hand: [_noun('h1', 'cats')]),
        Player(id: 'ai_1', name: 'AI 1', isAI: true, hand: [
          _pron('p1', 'I'), _verb('v1', 'like'), _noun('n1', 'cats'),
        ]),
      ],
      deck: [_noun('d1', 'apples')],
      discardPile: [_noun('x1', 'water')],
    ));

    final results = await n.runAITurns();

    expect(results.any((r) => r.isCorrect), true,
        reason: 'the AI held "I like cats" and must have submitted it');
  });

  test('turn timer expiry still advances into the AI loop', () async {
    final n = GameNotifier(
      random: Random(9),
      aiPlayer: AIPlayer(difficulty: AIDifficulty.hard, random: Random(9)),
      aiTurnDelay: Duration.zero,
    );

    n.debugSetState(GameState(
      phase: GamePhase.playing,
      turnPhase: TurnPhase.action,
      currentPlayerIndex: 0,
      players: [
        Player(id: 'human_0', name: 'You', hand: [_noun('h1', 'cats')]),
        Player(id: 'ai_1', name: 'AI 1', isAI: true, hand: [
          _noun('n1', 'dogs'), _noun('n2', 'birds'),
        ]),
      ],
      deck: [_noun('d1', 'apples'), _noun('d2', 'pears')],
      discardPile: [_noun('x1', 'water')],
    ));

    n.endTurn();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(n.state.currentPlayerIndex, 0,
        reason: 'the AI must have taken its turn without any UI involvement');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/game_provider_ai_turn_test.dart`
Expected: FAIL — `aiTurnDelay`, `runAITurns` 미정의.

- [ ] **Step 3: Implement**

`GameNotifier` 생성자에 필드를 추가한다:

```dart
  final Duration aiTurnDelay;

  GameNotifier({
    GrammarEngine? grammarEngine,
    AIPlayer? aiPlayer,
    Random? random,
    this.autoRunAI = true,
    this.aiTurnDelay = const Duration(milliseconds: 700),
  })  : _grammarEngine = grammarEngine ?? GrammarEngine(),
        _aiPlayer = aiPlayer ?? AIPlayer(),
        _random = random ?? Random(),
        super(const GameState());
```

`_runAITurnsIfNeeded` 스텁을 실제 구현으로 교체한다:

```dart
  Future<void> _runAITurnsIfNeeded() async {
    if (state.phase != GamePhase.playing) return;
    if (!state.currentPlayer.isAI) return;
    await runAITurns();
  }

  /// Drive every consecutive AI turn until control returns to a human or
  /// the game ends.
  ///
  /// This lives in the notifier, not the screen. When the UI owned it, any
  /// turn advance the UI did not initiate — a timer expiry, a JUMP — left
  /// nobody to run the AI and the game froze.
  Future<List<JudgmentResult>> runAITurns() async {
    if (_isProcessingAI) return const [];
    _isProcessingAI = true;

    final results = <JudgmentResult>[];
    try {
      // The bound is a safety net against a rule bug spinning forever.
      var guard = 0;
      while (state.phase == GamePhase.playing &&
          state.currentPlayer.isAI &&
          guard++ < 200) {
        if (aiTurnDelay > Duration.zero) {
          await Future<void>.delayed(aiTurnDelay);
        }
        if (!mounted) break;
        final result = _executeOneAITurn();
        if (result != null) results.add(result);
      }
    } finally {
      _isProcessingAI = false;
    }
    return results;
  }

  /// One complete AI turn: mandatory draw, then a single action.
  JudgmentResult? _executeOneAITurn() {
    final startIndex = state.currentPlayerIndex;

    // --- Draw phase ---
    if (state.turnPhase == TurnPhase.draw) {
      final top = state.discardTop;
      final wantsDiscard = top != null &&
          _aiPlayer.findSentence([...state.currentPlayer.hand, top]) != null &&
          _aiPlayer.findSentence(state.currentPlayer.hand) == null;
      if (wantsDiscard) {
        drawFromDiscard();
      } else {
        drawFromDeck();
      }
    }
    if (state.phase != GamePhase.playing) return null;
    if (state.currentPlayerIndex != startIndex) return null;

    // --- Action phase ---
    final me = state.currentPlayer;
    final action = _aiPlayer.decideAction(me, state);

    switch (action.type) {
      case AIActionType.submitSentence:
        for (final card in action.cards!) {
          final idx =
              state.currentPlayer.hand.indexWhere((c) => c.id == card.id);
          if (idx >= 0) placeCard(idx);
        }
        return submitSentence();

      case AIActionType.playJump:
        final idx = me.hand.indexWhere((c) => c.id == action.specialCard!.id);
        if (idx >= 0 && playJump(idx)) return null;
        break;

      case AIActionType.playSteal:
        final idx = me.hand.indexWhere((c) => c.id == action.specialCard!.id);
        if (idx >= 0 &&
            playSteal(
              idx,
              targetPlayerIndex: action.targetPlayerIndex!,
              giveCardIndex: action.giveCardIndex!,
            )) {
          return null;
        }
        break;

      case AIActionType.discard:
        if (discardCard(action.discardIndex!)) return null;
        break;
    }

    // Fallback: the chosen action was rejected. Discard any legal card so
    // the turn always ends and the loop cannot spin.
    final hand = state.currentPlayer.hand;
    for (int i = 0; i < hand.length; i++) {
      if (discardCard(i)) return null;
    }
    endTurn();
    return null;
  }
```

`startGame` 끝에도 AI 시작 처리를 추가한다 (플레이어 0이 항상 사람이므로 실제로는 no-op이지만, 향후 시작 플레이어가 바뀔 때를 대비):

```dart
    _startTurnTimer();
    if (autoRunAI) unawaited(_runAITurnsIfNeeded());
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/providers/`
Expected: PASS — 27개 전부.

- [ ] **Step 5: Commit**

```bash
flutter analyze
git add lib/providers/game_provider.dart test/providers/game_provider_ai_turn_test.dart
git commit -m "fix: move AI turn driving from UI into GameNotifier so turns cannot stall"
```

---

### Task 10: Flame — 문장존 재배열과 품사 기호

**Files:**
- Modify: `lib/game/components/card_component.dart`
- Modify: `lib/game/dripple_game.dart`
- Test: 수동 확인 (Flame 컴포넌트는 위젯 테스트 대상 밖)

**Interfaces:**
- Consumes: `WordCard.posColor`, `WordCard.posShape`
- Produces:
  - `DrippleGame.onCardPlaced` (`void Function(int handIndex)`) — 유지
  - `DrippleGame.onSentenceReorder` (`void Function(int from, int to)`)
  - `DrippleGame.onSentenceRemove` (`void Function(int index)`)

- [ ] **Step 1: Draw the part-of-speech symbol on each card**

`lib/game/components/card_component.dart`의 `render`에서 단어 텍스트 위에 기호를 그린다. `cardColor` getter를 교체한다:

```dart
  ui.Color get cardColor {
    switch (card.type) {
      case CardType.jump:
        return const ui.Color(0xFFFBBF24);
      case CardType.steal:
        return const ui.Color(0xFFEF4444);
      case CardType.joker:
        return const ui.Color(0xFF8B5CF6);
      case CardType.word:
        return material.Colors.white;
    }
  }
```

`render` 안, 단어 텍스트를 그리기 직전에 추가:

```dart
    // Montessori grammar symbol — a child who cannot yet read the word can
    // still see the sentence's shape.
    if (card.posShape != PosShape.none) {
      _paintPosSymbol(canvas);
    }
```

그리고 메서드를 추가:

```dart
  void _paintPosSymbol(ui.Canvas canvas) {
    final paint = ui.Paint()..color = ui.Color(card.posColor);
    final cx = size.x / 2;
    const topY = 14.0;

    switch (card.posShape) {
      case PosShape.triangleLarge:
      case PosShape.triangleMedium:
      case PosShape.triangleSmall:
      case PosShape.trianglePronoun:
        final half = switch (card.posShape) {
          PosShape.triangleLarge => 11.0,
          PosShape.triangleMedium => 9.0,
          PosShape.trianglePronoun => 9.0,
          _ => 7.0,
        };
        final path = ui.Path()
          ..moveTo(cx, topY - half)
          ..lineTo(cx - half, topY + half)
          ..lineTo(cx + half, topY + half)
          ..close();
        canvas.drawPath(path, paint);
      case PosShape.circle:
        canvas.drawCircle(ui.Offset(cx, topY), 10, paint);
      case PosShape.circleSmall:
        canvas.drawCircle(ui.Offset(cx, topY), 6, paint);
      case PosShape.crescent:
        canvas.drawCircle(ui.Offset(cx, topY), 9, paint);
        canvas.drawCircle(
          ui.Offset(cx + 4, topY - 2),
          8,
          ui.Paint()..color = cardColor,
        );
      case PosShape.none:
        break;
    }
  }
```

`_specialIcon`의 case를 `CardType.jump` → `'⏭'`, `CardType.steal` → `'🫳'`, `CardType.joker` → `'🌟'`로 정리하고 `skip`/`undo` case를 삭제한다.

- [ ] **Step 2: Add reorder callbacks to the game**

`lib/game/dripple_game.dart`에서:

```dart
typedef OnCardPlaced = void Function(int handIndex);
typedef OnSentenceReorder = void Function(int from, int to);
typedef OnSentenceRemove = void Function(int index);
```

필드 추가:

```dart
  OnCardPlaced? onCardPlaced;
  OnSentenceReorder? onSentenceReorder;
  OnSentenceRemove? onSentenceRemove;
```

`_diffUpdateComponents`에서 문장존 컴포넌트를 만들 때 드래그를 켠다. `withDrag` 파라미터를 `isSentenceZone`로 바꾸고 신규 컴포넌트 생성 분기를 다음으로 교체한다:

```dart
        final cardId = card.id;
        final comp = CardComponent(
          card: card,
          position: targetPos,
          onDragEnded: (component, dropPosition) {
            if (isSentenceZone) {
              final from = _sentenceZone.indexWhere((c) => c.id == cardId);
              if (from < 0) return;
              // Dragged clear of the zone — send it back to hand.
              if ((dropPosition.y - _sentenceZoneY).abs() >
                  CardComponent.cardHeight) {
                onSentenceRemove?.call(from);
                return;
              }
              final to = _indexAtX(dropPosition.x, _sentenceZone.length);
              if (to != from) onSentenceReorder?.call(from, to);
            } else {
              // Hand card lifted toward the sentence zone.
              if (dropPosition.y < _handY - CardComponent.cardHeight * 0.5) {
                final idx = _hand.indexWhere((c) => c.id == cardId);
                if (idx >= 0) onCardPlaced?.call(idx);
              }
            }
          },
        );
```

인덱스 계산 헬퍼 추가:

```dart
  /// Which slot an x-coordinate lands in, for a row of [count] cards.
  int _indexAtX(double x, int count) {
    if (count <= 1) return 0;
    const step = CardComponent.cardWidth + 8;
    final totalWidth = count * step - 8;
    final startX = (size.x - totalWidth) / 2;
    final raw = ((x - startX) / step).round();
    return raw.clamp(0, count - 1);
  }
```

`updateSentenceZone`의 `_diffUpdateComponents` 호출에서 `withDrag: false` → `isSentenceZone: true`, `updateHand`에서는 `isSentenceZone: false`로 바꾼다.

- [ ] **Step 3: Simplify CardComponent's drag contract**

`CardComponent`의 `onDragToSentenceZone` 콜백을 위치를 함께 넘기는 형태로 교체한다:

```dart
  final void Function(CardComponent component, Vector2 dropPosition)?
      onDragEnded;
```

생성자 파라미터를 `this.onDragEnded`로 바꾸고, `onDragEnd`를 다음으로 교체:

```dart
  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    priority = 0;

    final dropPosition = position.clone();
    onDragEnded?.call(this, dropPosition);

    // Snap back; the parent repositions us on the next state update if the
    // drop actually changed anything.
    add(MoveEffect.to(
      _originalPosition,
      EffectController(duration: 0.15, curve: material.Curves.easeOut),
    ));
  }
```

`_dragSuccess` 필드는 더 이상 쓰이지 않으므로 삭제한다.

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze`
Expected: `lib/game/` 관련 경고 0. `lib/screens/game_screen.dart`는 Task 11에서 고치므로 아직 에러가 남아 있을 수 있다.

- [ ] **Step 5: Commit**

```bash
git add lib/game/
git commit -m "feat: sentence zone drag-reorder and Montessori part-of-speech symbols in Flame"
```

---

### Task 11: 게임 화면 재구성

라운드 오버레이를 제거하고 뽑기/액션 2단계 UI, 버린 더미, 특수카드 시트, 손패 장수 표시를 붙인다.

**Files:**
- Modify: `lib/screens/game_screen.dart`
- Create: `lib/screens/widgets/special_card_sheet.dart`
- Test: `test/widget_test.dart` (기존 trivial 테스트 갱신)

**Interfaces:**
- Consumes: `GameNotifier`의 전 공개 메서드, `GameState.turnPhase`, `GameState.discardTop`
- Produces: `showSpecialCardSheet(BuildContext context, {required WidgetRef ref, required WordCard card, required int handIndex}) -> Future<void>`

- [ ] **Step 1: Create the special card sheet**

`lib/screens/widgets/special_card_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_state.dart';
import '../../models/word_card.dart';
import '../../providers/game_provider.dart';

/// Bottom sheet for playing a JUMP or STEAL card.
///
/// Before this existed the human player had no way to play special cards at
/// all — only the AI could.
Future<void> showSpecialCardSheet(
  BuildContext context, {
  required WidgetRef ref,
  required WordCard card,
  required int handIndex,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final state = ref.read(gameProvider);
      final notifier = ref.read(gameProvider.notifier);

      if (card.type == CardType.jump) {
        return _JumpSheet(
          onConfirm: () {
            notifier.playJump(handIndex);
            Navigator.of(sheetContext).pop();
          },
        );
      }

      return _StealSheet(
        state: state,
        handIndex: handIndex,
        onConfirm: (targetIndex, giveIndex) {
          notifier.playSteal(
            handIndex,
            targetPlayerIndex: targetIndex,
            giveCardIndex: giveIndex,
          );
          Navigator.of(sheetContext).pop();
        },
      );
    },
  );
}

class _JumpSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  const _JumpSheet({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⏭ JUMP',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('다음 사람의 차례를 건너뜁니다.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onConfirm, child: const Text('사용하기')),
        ],
      ),
    );
  }
}

class _StealSheet extends StatefulWidget {
  final GameState state;
  final int handIndex;
  final void Function(int targetIndex, int giveIndex) onConfirm;

  const _StealSheet({
    required this.state,
    required this.handIndex,
    required this.onConfirm,
  });

  @override
  State<_StealSheet> createState() => _StealSheetState();
}

class _StealSheetState extends State<_StealSheet> {
  int? _target;
  int? _give;

  @override
  Widget build(BuildContext context) {
    final me = widget.state.currentPlayer;
    // playSteal indexes the hand after the STEAL card is removed.
    final handAfter = List<WordCard>.from(me.hand)
      ..removeAt(widget.handIndex);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🫳 STEAL',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('상대를 고르고, 대신 줄 카드를 고르세요.'),
          const SizedBox(height: 16),
          const Text('누구에게서 가져올까요?'),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < widget.state.players.length; i++)
                if (i != widget.state.currentPlayerIndex &&
                    widget.state.players[i].hand.isNotEmpty)
                  ChoiceChip(
                    label: Text(
                      '${widget.state.players[i].name} '
                      '(${widget.state.players[i].hand.length})',
                    ),
                    selected: _target == i,
                    onSelected: (_) => setState(() => _target = i),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('어떤 카드를 줄까요?'),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < handAfter.length; i++)
                ChoiceChip(
                  label: Text(handAfter[i].word),
                  selected: _give == i,
                  onSelected: (_) => setState(() => _give = i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: (_target != null && _give != null)
                  ? () => widget.onConfirm(_target!, _give!)
                  : null,
              child: const Text('사용하기'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Rewire game_screen.dart**

`lib/screens/game_screen.dart`에서 다음을 수행한다:

1. `_RoundEndOverlay` 클래스와 그 사용처를 삭제한다. `GamePhase.roundEnd` 참조를 전부 제거한다.
2. `_processAITurns()` 메서드와 그 호출을 전부 삭제한다. AI는 이제 notifier가 돌린다.
3. `_onDraw`를 뽑기 두 가지로 나눈다:

```dart
  void _onDrawFromDeck() {
    ref.read(gameProvider.notifier).drawFromDeck();
    ref.read(gameFeedbackProvider).onCardDraw();
  }

  void _onDrawFromDiscard() {
    ref.read(gameProvider.notifier).drawFromDiscard();
    ref.read(gameFeedbackProvider).onCardDraw();
  }
```

4. `_onSubmit`을 단순화한다 (AI 처리 제거):

```dart
  void _onSubmit() async {
    final feedback = ref.read(gameFeedbackProvider);
    await feedback.onSubmit();

    final result = ref.read(gameProvider.notifier).submitSentence();
    if (!mounted) return;

    if (result.isCorrect) {
      await feedback.onCorrectAnswer();
    } else {
      await feedback.onIncorrectAnswer();
    }
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => JudgmentDialog(result: result),
    );
  }
```

5. `_onUndo`를 삭제하고 Flame 콜백을 연결한다 (`initState` 안):

```dart
    _game.onCardPlaced = _onCardPlaced;
    _game.onSentenceReorder = (from, to) =>
        ref.read(gameProvider.notifier).reorderSentence(from, to);
    _game.onSentenceRemove = (index) =>
        ref.read(gameProvider.notifier).removeFromSentence(index);
```

6. `_ActionBar`를 턴 페이즈에 따라 바꾼다. 기존 `_ActionBar` 위젯을 다음으로 교체한다:

```dart
class _ActionBar extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onDrawFromDeck;
  final VoidCallback onDrawFromDiscard;
  final VoidCallback onSubmit;
  final VoidCallback onDiscard;

  const _ActionBar({
    required this.gameState,
    required this.onDrawFromDeck,
    required this.onDrawFromDiscard,
    required this.onSubmit,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final isHumanTurn = gameState.phase == GamePhase.playing &&
        gameState.players.isNotEmpty &&
        !gameState.currentPlayer.isAI;

    if (!isHumanTurn) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('상대의 차례입니다...'),
      );
    }

    if (gameState.turnPhase == TurnPhase.draw) {
      final top = gameState.discardTop;
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilledButton.icon(
              onPressed: onDrawFromDeck,
              icon: const Icon(Icons.layers),
              label: Text('덱에서 뽑기 (${gameState.deck.length})'),
            ),
            FilledButton.icon(
              onPressed: top == null ? null : onDrawFromDiscard,
              icon: const Icon(Icons.download),
              label: Text(top == null ? '버린 더미 없음' : '"${top.word}" 가져오기'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FilledButton(
            onPressed: gameState.currentPlayer.sentenceZone.length >= 2
                ? onSubmit
                : null,
            child: const Text('문장 완성'),
          ),
          OutlinedButton(
            onPressed: onDiscard,
            child: const Text('카드 버리기'),
          ),
        ],
      ),
    );
  }
}
```

그리고 `build`의 호출부도 함께 바꾼다 (기존 호출은 `onSubmit`/`onDraw`/`onUndo`/`canSubmit`/`deckCount`를 넘기고 있어 컴파일되지 않는다):

```dart
                _ActionBar(
                  gameState: gameState,
                  onDrawFromDeck: _onDrawFromDeck,
                  onDrawFromDiscard: _onDrawFromDiscard,
                  onSubmit: _onSubmit,
                  onDiscard: _onDiscard,
                ),
```

7. 버리기는 손패에서 카드를 하나 골라야 하므로 다이얼로그를 띄운다:

```dart
  Future<void> _onDiscard() async {
    final state = ref.read(gameProvider);
    final hand = state.currentPlayer.hand;
    final blockedId = state.drawnFromDiscardCardId;

    final index = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('버릴 카드를 고르세요'),
        children: [
          for (int i = 0; i < hand.length; i++)
            SimpleDialogOption(
              onPressed: hand[i].id == blockedId
                  ? null
                  : () => Navigator.of(dialogContext).pop(i),
              child: Text(
                hand[i].id == blockedId
                    ? '${hand[i].word} (이번 턴에 가져온 카드)'
                    : hand[i].word,
              ),
            ),
        ],
      ),
    );

    if (index == null || !mounted) return;
    ref.read(gameProvider.notifier).discardCard(index);
    ref.read(gameFeedbackProvider).onButtonTap();
  }
```

8. `_ScoreboardBar`에서 점수 대신 손패 장수를 보여준다. `Text('${p.score}')`를 다음으로 교체:

```dart
                    Text(
                      '${p.hand.length}',
                      style: TextStyle(
                        color: p.hand.length == 1
                            ? Colors.amberAccent
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: p.hand.length == 1 ? 18 : 14,
                      ),
                    ),
```

9. `_GameEndOverlay`에서 `gameState.ranking.first`가 승자다 (손패 최소 기준). 기존 로직이 점수 기준이면 수정한다.

10. 손패의 특수카드 탭 처리는 액션바 아래 별도 행으로 노출한다:

```dart
                if (gameState.phase == GamePhase.playing &&
                    !gameState.currentPlayer.isAI &&
                    gameState.turnPhase == TurnPhase.action)
                  _SpecialCardRow(
                    hand: gameState.currentPlayer.hand,
                    onTap: (handIndex) => showSpecialCardSheet(
                      context,
                      ref: ref,
                      card: gameState.currentPlayer.hand[handIndex],
                      handIndex: handIndex,
                    ),
                  ),
```

그리고 위젯을 추가한다:

```dart
class _SpecialCardRow extends StatelessWidget {
  final List<WordCard> hand;
  final void Function(int handIndex) onTap;

  const _SpecialCardRow({required this.hand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final entries = <int>[];
    for (int i = 0; i < hand.length; i++) {
      if (hand[i].type == CardType.jump || hand[i].type == CardType.steal) {
        entries.add(i);
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          for (final i in entries)
            ActionChip(
              label: Text(
                hand[i].type == CardType.jump ? '⏭ JUMP' : '🫳 STEAL',
              ),
              onPressed: () => onTap(i),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Update the widget test**

`test/widget_test.dart`를 다음으로 교체:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dripple/models/game_state.dart';
import 'package:dripple/providers/game_provider.dart';

void main() {
  testWidgets('game starts with 4 players in the draw phase', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(gameProvider.notifier).startGame(const GameConfig());
    final state = container.read(gameProvider);

    expect(state.players.length, 4);
    expect(state.phase, GamePhase.playing);
    expect(state.turnPhase, TurnPhase.draw);
    expect(state.currentPlayer.isAI, false);
  });
}
```

- [ ] **Step 4: Run the full suite**

Run: `flutter test && flutter analyze`
Expected: 전부 PASS, 경고 0.

컴파일 에러가 남으면 `grep -rn "roundEnd\|totalRounds\|currentRound\|minSentenceLength\|_processAITurns" lib/` 로 남은 참조를 찾아 제거한다. `lib/screens/result_screen.dart`와 `lib/screens/mode_selection_screen.dart`도 확인 대상이다.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/ test/widget_test.dart
git commit -m "feat: rebuild game screen for two-phase turns, discard pile, and special card actions"
```

---

### Task 12: 문서 갱신 및 최종 검증

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update CLAUDE.md**

다음을 반영한다:

- "Design Spec" 줄에 새 스펙 경로를 추가: `docs/superpowers/specs/2026-08-22-dripple-card-battle-redesign.md`
- Project Overview: "멀티플레이 영어 단어 카드 배틀 게임" → **"6~10세 대상 영어 학습을 목적으로 하는 카드 배틀 게임 (러미 방식)"**
- Design Decisions 4번 "Entertainment first — board game, not a learning app" → **"학습이 목적, 카드 게임이 형태 — 아이가 게임을 하다 보면 영어 어순이 익혀진다"**
- Design Decisions 2번의 게임 모드 프리셋(Classic/Battle/Learning)과 베팅 시스템 항목을 **삭제**
- "Next Steps"에서 게임 모드 프리셋·베팅 항목 삭제
- "Engineering Review (2026-04-09)"의 Critical Bugs 5개를 **해결됨으로 표시하고**, 어느 태스크가 고쳤는지 한 줄씩 적는다:
  - SKIP 이중 진행 → `endTurn(skip:)` 단일 경로로 통합
  - STEAL 참조 오염 → `playSteal` 원자적 갱신
  - WILD 미구현 → JOKER가 파서 와일드카드로 동작
  - 라운드 리셋 없음 → 라운드 개념 자체를 제거, 단판 승부
  - `_processAITurns` 경쟁 상태 → AI 진행이 notifier 소유, `_isProcessingAI` 가드
- Testing Gaps 항목을 갱신한다 (파서 13, 카드 8, 상태 7, provider 27, AI 8 추가)
- 새 게임 규칙 요약을 "Game Rules" 절로 추가한다:

```markdown
## Game Rules

4인 (사람 1 + AI 3), 초기 손패 7장, 단판. 먼저 손패를 다 비우면 승리.

턴: ① 덱 또는 버린 더미에서 1장 뽑기(필수) → ② 액션 1회(문장 완성 / JUMP / STEAL / 버리기)

- 문장 최소·최대 길이 제한 없음 (문법상 2장이 하한)
- 문장 제출 실패는 액션을 소모하지 않는다
- 버린 더미에서 가져온 카드는 그 턴에 버릴 수 없다
- 덱 소진 시 버린 더미를 섞어 재사용, 2회 재활용 후 소진되면 손패 최소인 사람 승
- 특수카드: JOKER(만능 단어) / JUMP(다음 사람 건너뛰기) / STEAL(카드 강제 교환)
```

- [ ] **Step 2: Full verification**

```bash
flutter analyze
flutter test
```

Expected: analyze 경고 0, 전체 테스트 PASS.

테스트 총계 기대값: 문법 21(기존) + 파서 13 + 카드모델 5 + 덱 8 + 상태 7 + provider draw 7 + provider action 10 + provider special 6 + provider AI 3 + AI player 8 + widget 1 = **89개**

숫자가 어긋나면 각 태스크에서 테스트를 추가·조정했다는 뜻이므로, 총계보다 **실패 0건**을 기준으로 판단한다.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for the rummy card battle redesign"
```

- [ ] **Step 4: Manual smoke test**

```bash
flutter run
```

확인 항목:
1. 게임 시작 시 4명, 각자 7장, 버린 더미에 1장 공개
2. "덱에서 뽑기" / "버린 더미 가져오기" 두 버튼이 나오고, 뽑으면 액션 단계로 넘어감
3. 손패 카드를 위로 드래그하면 문장존에 놓임
4. 문장존 카드를 좌우로 끌면 순서가 바뀌고, 아래로 끌면 손패로 돌아감
5. 유효한 문장을 제출하면 카드가 사라지고 AI 차례로 넘어감
6. **AI가 실제로 문장을 제출한다** (기존 버그의 핵심 확인 지점)
7. 잘못된 문장을 제출해도 턴이 넘어가지 않음
8. JUMP / STEAL 칩이 보이고 실제로 동작함
9. 손패를 다 비우면 승리 화면이 뜸
10. 상단에 각 플레이어의 남은 카드 수가 보이고, 1장이면 강조됨
