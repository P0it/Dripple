# 온라인 멀티플레이 — 1단계 설계: 계정과 실시간 대전

2026-08-26

## 문제

멀티플레이는 문 앞까지만 와 있다. `lib/services/auth_service.dart`와
`lib/services/multiplayer_service.dart`에 추상 인터페이스가 있지만 구현은 no-op조차
없고, `lib/screens/lobby_screen.dart`는 방 코드가 `'ABC-123'` 리터럴로 박힌 정적
위젯이며 어떤 라우트도 그곳으로 가지 않는다. `pubspec.yaml`에는 firebase 패키지가
한 줄도 없다.

요청된 범위 — 로그인, 친구 추가·관리, 접속자 목록, 초대, 레벨·계급, 리더보드 — 는
서로 독립적인 다섯 개 서브시스템이다. 한 번에 다 만들면 어느 것도 완성되지 않는다.

## 결정

**1단계는 계정과 실시간 대전만 만든다.** 나머지 넷은 전부 "온라인 판이 존재한다"를
전제로 얹히는 기능이다. 초대할 방이 없으면 친구 목록도, 집계할 판이 없으면
리더보드도 의미가 없다.

**서버가 덱을 소유한다.** 참가자 중 한 명이 덱을 섞고 모두의 손패를 들고 있는
구조는 카드게임으로서 결함이다. 그렇다고 Firebase Realtime DB만으로는 섞을 수 없다
— DB는 코드를 실행하지 않는다. 섞는 주체는 참가자이거나 서버이거나 둘 중
하나인데, 참가자는 위의 이유로 안 된다. 따라서 진짜 서버 코드를 둔다.

이것은 `$0 운영비` 원칙과 충돌하지 않는다. 그 조건은 오프라인 코어 게임플레이에
걸린 것이고, `2026-04-05-dripple-design.md`도 "서버는 온라인 멀티플레이에만
쓴다"고 이미 적어두었다.

**서버는 Dart로 쓰고 규칙 코드를 앱과 공유한다.** 문법 엔진을 TypeScript로 다시
쓰면 같은 규칙의 두 구현을 영원히 함께 고쳐야 하고, 두 판정이 어긋나는 날이 반드시
온다. `lib/engine/`, `lib/models/`, `lib/data/`에는 Flutter import가 하나도 없다 —
`dart:math`와 `package:equatable`뿐이다. 경계는 이미 존재하고, 패키지가 아닐 뿐이다.

**행동은 HTTP로, 판의 변화는 RTDB 구독으로.** 내 차례에 하는 행동은 서버로 요청을
보내 즉시 성공/실패를 받는다 — 문장이 왜 틀렸는지가 그 응답에 실려 오므로 제출의
감각이 지금과 같다. 판의 변화는 RTDB 구독으로 네 기기에 밀어넣어진다.

**문장 조립은 로컬이고 제출만 서버로 간다.** `placeCard`·`reorderSentence`·
`removeFromSentence`는 순수한 UI 상태다. 서버로 가는 행동은 여섯 개뿐이다.

```
draw(from: deck|discard)
submit(cardIds: [...])
discard(cardId)
pass()
jump(cardId)
steal(cardId, targetSeat, giveCardId)
```

**서버는 상태를 메모리에 들고 있지 않는다.** Cloud Run은 요청이 없으면 0으로
내려가므로 in-memory 방 상태는 사라진다. 매 요청마다 RTDB에서 방의 완전한
상태(비공개 포함)를 읽고, 규칙을 적용하고, 되쓴다. 동시 요청은 `meta/version`
비교로 거른다 — 버전이 어긋나면 409를 돌려주고 클라이언트가 재시도한다.

턴 타이머도 같은 이유로 서버가 돌릴 수 없다. `public/turnDeadline`에 시각을
적어두고, 어떤 요청이 들어오든 서버가 먼저 "지난 마감이 있는가"를 확인해 몰수
처리한다. 아무도 행동하지 않는 경우 — AI 좌석 차례, 상대의 시간 초과 — 를 위해
클라이언트가 마감을 관측하면 `POST /rooms/{id}/tick`을 보낸다. 버전 기반이라 여러
클라이언트가 동시에 보내도 안전하다.

**로그인은 익명 인증과 닉네임뿐이다.** 6-10세 아동이 대상에 포함되므로 이메일도
개인정보도 수집하지 않는다. 닉네임은 온라인을 처음 누를 때 받는다 — AI 대전만 하는
사람에게는 아무것도 묻지 않는다. 기기를 바꾸면 계정을 잃는 것이 유일한 대가다.

**인원은 2~4인 그대로 시작한다.** `GameConfig.playerCount`가 이미 가변이라 빈 자리를
메우는 개념이 필요 없다.

**판 도중 이탈한 좌석은 AI가 이어받는다.** 남은 사람들의 판이 깨지지 않고, 나갔던
사람이 같은 uid로 돌아오면 자기 자리를 되찾는다.

## 구조

```
┌─────────────┐   ①행동 HTTP(+Firebase ID token)   ┌──────────────────┐
│  Flutter 앱 │ ─────────────────────────────────▶ │ Cloud Run (Dart) │
│             │ ◀───────────────────────────────── │  규칙 = 앱과 동일 │
└─────────────┘   ②판정 결과 / 오류                 └────────┬─────────┘
       ▲                                                     │ ③상태 쓰기
       │ ④public + 내 손패 구독                              ▼
       └────────────────────────────────────────  Firebase Realtime DB
```

### RTDB 구조

```
users/{uid}            name, createdAt
codes/{ABC123}         roomId
rooms/{roomId}/
  meta                 status(lobby|playing|finished), code, maxPlayers,
                       version, createdAt, updatedAt
  seats/{i}            uid, name, kind(human|ai|empty), ready, connected
  public               phase, turnPhase, currentSeat, deckCount,
                       discardTop, handCounts[], recycleCount,
                       winnerSeat, turnDeadline, lastEvent
  private/hands/{uid}  [cardId…]
  private/deck         [cardId…]
  private/discard      [cardId…]
```

카드는 id만 오간다. 덱은 `lib/data/card_deck.dart`의 정적 데이터라 내용을 실어 나를
이유가 없다.

### 보안 규칙

클라이언트는 사실상 write 권한이 없다. 방 생성·참가·행동은 전부 HTTP다. read는
`meta`/`seats`/`public`이 방 참가자에게, `private/hands/{uid}`가 본인에게만 열린다.
`private/deck`은 아무도 읽을 수 없다 — 서버만 서비스 계정으로 접근한다.

유일한 예외는 `seats/{i}/connected`로, 본인만 write할 수 있다. RTDB `onDisconnect`로
접속 끊김을 표시하기 위한 것이며 게임 상태에 영향을 주지 않는다.

이 규칙 아래에서 "덱은 시스템이 섞는다"가 문자 그대로 참이 된다.

### 남의 손패

서버는 남의 손패를 `hidden` 자리표시자 카드 N장으로 내려준다. 화면은 이미 뒷면을
그리므로 UI 코드가 바뀌지 않는다.

## 앱에서 바뀌는 것

`isAI` 분기가 "내가 아님"으로 바뀐다. 지금 네 곳이 `isAI`로 판단한다:
`lib/screens/game_screen.dart`(입력 게이트 두 곳), `lib/screens/game/action_bar.dart`,
`lib/screens/game/opponents_bar.dart`(상대 목록을 `p.isAI`로 고른다). 온라인에서는
`player.id != myUid`가 기준이어야 하고, 오프라인 동작은 그대로여야 한다.

`GameNotifier`는 온라인에서도 문장 존 조작을 계속 맡되 `autoRunAI: false`로 돈다 —
AI는 서버가 돌린다.

로비의 l10n 키(`roomCode`, `waiting`, `shareRoomCode`, `nPlayers`, `you`)는 세 언어
모두 이미 있다.

## 범위 밖

랜덤 매치메이킹, 친구 목록, 접속자 목록, 레벨·계급, 리더보드, 관전. 초대는 방 코드
공유라는 최소 형태로만 들어간다.

이후 순서는 ②소셜(친구 코드·presence·초대) → ③진행도(XP·레벨·계급) →
④리더보드 → ⑤랜덤 매치메이킹. 리더보드가 뒤에 오는 것은 서버 권위가 먼저 서
있어야 집계를 신뢰할 수 있기 때문이다.
