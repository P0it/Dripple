import '../data/card_deck.dart';
import '../engine/ai/ai_player.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/word_card.dart';

/// How a game crosses the wire.
///
/// Two shapes, because two audiences. [GameSnapshot] is the server's own
/// copy — every hand, the deck in order — and no client ever receives it.
/// [PublicView] is what the table can see, and it is the only thing written
/// where players can read it.
///
/// Both carry card ids rather than card contents. The deck is static data in
/// [CardDeck] that every end already holds, so sending a card's meanings and
/// adjective order over the wire would be sending back what was shipped in
/// the binary.

List<String> _ids(List<WordCard> cards) => [for (final c in cards) c.id];

List<WordCard> _cards(Object? ids) => [
      for (final id in (ids as List? ?? const []))
        CardDeck.cardById(id as String) ??
            (throw FormatException('unknown card id: $id')),
    ];

/// The complete state of a game, hidden information included.
///
/// Server-side only. Writing this where a client can read it would hand
/// every player everyone else's hand.
class GameSnapshot {
  const GameSnapshot._();

  static Map<String, dynamic> encode(GameState state) => {
        'phase': state.phase.name,
        'turnPhase': state.turnPhase.name,
        'currentSeat': state.currentPlayerIndex,
        'deck': _ids(state.deck),
        'discard': _ids(state.discardPile),
        'recycleCount': state.deckRecycleCount,
        'drawnFromDiscard': state.drawnFromDiscardCardId,
        'winnerSeat': state.winnerIndex,
        'turnTimeRemaining': state.turnTimeRemaining,
        'config': {
          'playerCount': state.config.playerCount,
          'initialHandSize': state.config.initialHandSize,
          'turnTimerSeconds': state.config.turnTimerSeconds,
          'difficulty': state.config.difficulty.name,
        },
        'seats': [
          for (final p in state.players)
            {
              'id': p.id,
              'name': p.name,
              'isAI': p.isAI,
              'hand': _ids(p.hand),
              'sentence': _ids(p.sentenceZone),
              'score': p.score,
            },
        ],
      };

  static GameState decode(Map<String, dynamic> json) {
    final config = (json['config'] as Map).cast<String, dynamic>();
    return GameState(
      phase: GamePhase.values.byName(json['phase'] as String),
      turnPhase: TurnPhase.values.byName(json['turnPhase'] as String),
      currentPlayerIndex: json['currentSeat'] as int,
      deck: _cards(json['deck']),
      discardPile: _cards(json['discard']),
      deckRecycleCount: json['recycleCount'] as int? ?? 0,
      drawnFromDiscardCardId: json['drawnFromDiscard'] as String?,
      winnerIndex: json['winnerSeat'] as int?,
      turnTimeRemaining: json['turnTimeRemaining'] as int? ?? -1,
      config: GameConfig(
        playerCount: config['playerCount'] as int,
        initialHandSize: config['initialHandSize'] as int,
        turnTimerSeconds: config['turnTimerSeconds'] as int,
        difficulty: AIDifficulty.values.byName(config['difficulty'] as String),
      ),
      players: [
        for (final seat in (json['seats'] as List).cast<Map>())
          Player(
            id: seat['id'] as String,
            name: seat['name'] as String,
            isAI: seat['isAI'] as bool? ?? false,
            hand: _cards(seat['hand']),
            sentenceZone: _cards(seat['sentence']),
            score: seat['score'] as int? ?? 0,
          ),
      ],
    );
  }
}

/// What the table can see: how many cards each seat holds, the top of the
/// discard pile, whose turn it is, and the sentence being built in the open.
///
/// Deliberately not here: the deck's order and anybody's hand. A seat learns
/// its own cards from a separate, private channel and puts the two together
/// with [decode].
class PublicView {
  const PublicView._();

  static Map<String, dynamic> encode(GameState state) => {
        'phase': state.phase.name,
        'turnPhase': state.turnPhase.name,
        'currentSeat': state.currentPlayerIndex,
        'deckCount': state.deck.length,
        'discardTop': state.discardTop?.id,
        'discardCount': state.discardPile.length,
        'handCounts': [for (final p in state.players) p.hand.length],
        'recycleCount': state.deckRecycleCount,
        'drawnFromDiscard': state.drawnFromDiscardCardId,
        'winnerSeat': state.winnerIndex,
        'turnTimeRemaining': state.turnTimeRemaining,
        'config': {
          'playerCount': state.config.playerCount,
          'initialHandSize': state.config.initialHandSize,
          'turnTimerSeconds': state.config.turnTimerSeconds,
          'difficulty': state.config.difficulty.name,
        },
        'seats': [
          for (final p in state.players)
            {
              'id': p.id,
              'name': p.name,
              'isAI': p.isAI,
              // A played sentence is on the table face up, so it is public.
              'sentence': _ids(p.sentenceZone),
              'score': p.score,
            },
        ],
      };

  /// Rebuild a playable [GameState] for the seat at [viewerSeat], whose own
  /// hand is [myHandIds].
  ///
  /// Every card this seat may not see becomes a face-down placeholder. The
  /// board already draws backs for those, so nothing on screen has to know
  /// this is a reconstruction rather than the real thing.
  static GameState decode(
    Map<String, dynamic> json, {
    required int viewerSeat,
    required List<String> myHandIds,
  }) {
    final config = (json['config'] as Map).cast<String, dynamic>();
    final counts = (json['handCounts'] as List).cast<int>();
    final discardTopId = json['discardTop'] as String?;
    final discardCount = json['discardCount'] as int? ?? 0;

    return GameState(
      phase: GamePhase.values.byName(json['phase'] as String),
      turnPhase: TurnPhase.values.byName(json['turnPhase'] as String),
      currentPlayerIndex: json['currentSeat'] as int,
      deck: [
        for (var i = 0; i < (json['deckCount'] as int); i++)
          WordCard.faceDown('back_deck_$i'),
      ],
      // Only the top of the pile is face up; what is under it is not in play.
      discardPile: [
        for (var i = 0; i < discardCount - 1; i++)
          WordCard.faceDown('back_discard_$i'),
        if (discardTopId != null) CardDeck.cardById(discardTopId)!,
      ],
      deckRecycleCount: json['recycleCount'] as int? ?? 0,
      drawnFromDiscardCardId: json['drawnFromDiscard'] as String?,
      winnerIndex: json['winnerSeat'] as int?,
      turnTimeRemaining: json['turnTimeRemaining'] as int? ?? -1,
      mySeatIndex: viewerSeat,
      config: GameConfig(
        playerCount: config['playerCount'] as int,
        initialHandSize: config['initialHandSize'] as int,
        turnTimerSeconds: config['turnTimerSeconds'] as int,
        difficulty: AIDifficulty.values.byName(config['difficulty'] as String),
      ),
      players: [
        for (var seat = 0; seat < (json['seats'] as List).length; seat++)
          () {
            final s = ((json['seats'] as List)[seat] as Map)
                .cast<String, dynamic>();
            return Player(
              id: s['id'] as String,
              name: s['name'] as String,
              isAI: s['isAI'] as bool? ?? false,
              hand: seat == viewerSeat
                  ? _cards(myHandIds)
                  : [
                      for (var i = 0; i < counts[seat]; i++)
                        WordCard.faceDown('back_${seat}_$i'),
                    ],
              sentenceZone: _cards(s['sentence']),
              score: s['score'] as int? ?? 0,
            );
          }(),
      ],
    );
  }
}
