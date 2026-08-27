import 'package:test/test.dart';
import 'package:dripple_rules/data/card_deck.dart';
import 'package:dripple_rules/engine/game_engine.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/word_card.dart';
import 'package:dripple_rules/wire/wire.dart';

GameState _playedGame() {
  final engine = GameNotifier(autoRunAI: false);
  engine.startGame(const GameConfig(playerCount: 4, turnTimerSeconds: 30));
  engine.drawFromDeck();
  return engine.state;
}

/// Every string anywhere in an encoded payload.
///
/// Leak checks compare ids exactly rather than searching the payload's text:
/// `card_2` is a substring of `card_20`, so a text search reports a leak that
/// is not there and — worse — depends on how the deck happened to shuffle.
Set<String> _everyString(Object? node) {
  if (node is String) return {node};
  if (node is Map) {
    return {
      for (final entry in node.entries) ..._everyString(entry.value),
    };
  }
  if (node is Iterable) {
    return {for (final item in node) ..._everyString(item)};
  }
  return const {};
}

void main() {
  group('GameSnapshot — the server\'s own copy', () {
    test('survives a round trip unchanged', () {
      final before = _playedGame();
      final after = GameSnapshot.decode(GameSnapshot.encode(before));
      expect(after, equals(before));
      for (var i = 0; i < before.players.length; i++) {
        expect(after.players[i].hand, equals(before.players[i].hand));
        expect(after.players[i].sentenceZone,
            equals(before.players[i].sentenceZone));
      }
      expect(after.deck, equals(before.deck));
      expect(after.discardPile, equals(before.discardPile));
    });

    test('carries the rummy discard lock', () {
      final engine = GameNotifier(autoRunAI: false);
      engine.startGame(const GameConfig(playerCount: 2));
      engine.drawFromDiscard();
      final after = GameSnapshot.decode(GameSnapshot.encode(engine.state));
      expect(after.drawnFromDiscardCardId,
          equals(engine.state.drawnFromDiscardCardId));
      expect(after.drawnFromDiscardCardId, isNotNull);
    });

    test('is written as card ids, not card contents', () {
      final json = GameSnapshot.encode(_playedGame());
      expect(json.toString(), isNot(contains('meanings')));
      expect(json.toString(), isNot(contains('adjOrder')));
    });
  });

  group('PublicView — what everyone may see', () {
    test('never contains another player\'s card ids', () {
      final state = _playedGame();
      final leaked = _everyString(PublicView.encode(state));
      for (var i = 0; i < state.players.length; i++) {
        for (final card in state.players[i].hand) {
          expect(leaked, isNot(contains(card.id)),
              reason: 'seat $i leaked ${card.id}');
        }
      }
    });

    test('never contains the deck order', () {
      final state = _playedGame();
      final leaked = _everyString(PublicView.encode(state));
      for (final card in state.deck) {
        expect(leaked, isNot(contains(card.id)));
      }
    });

    test('keeps what the table can actually see', () {
      final state = _playedGame();
      final public = PublicView.encode(state);
      expect(public['deckCount'], equals(state.deck.length));
      expect(public['discardTop'], equals(state.discardTop?.id));
      expect(public['handCounts'],
          equals(state.players.map((p) => p.hand.length).toList()));
      expect(public['currentSeat'], equals(state.currentPlayerIndex));
      expect(public['turnPhase'], equals(state.turnPhase.name));
    });
  });

  group('PublicView.decode — a seat\'s view of the table', () {
    test('gives me my real cards and everyone else face-down ones', () {
      final state = _playedGame();
      const mySeat = 2;
      final myHand = state.players[mySeat].hand.map((c) => c.id).toList();

      final view = PublicView.decode(
        PublicView.encode(state),
        viewerSeat: mySeat,
        myHandIds: myHand,
      );

      expect(view.players[mySeat].hand, equals(state.players[mySeat].hand));
      for (var i = 0; i < state.players.length; i++) {
        if (i == mySeat) continue;
        expect(view.players[i].hand.length,
            equals(state.players[i].hand.length),
            reason: 'seat $i should show the right number of backs');
        expect(view.players[i].hand.every((c) => c.isFaceDown), isTrue,
            reason: 'seat $i should be face down');
      }
    });

    test('face-down cards are distinguishable from one another', () {
      final state = _playedGame();
      final view = PublicView.decode(
        PublicView.encode(state),
        viewerSeat: 0,
        myHandIds: state.players[0].hand.map((c) => c.id).toList(),
      );
      final backs = view.players[1].hand.map((c) => c.id).toList();
      expect(backs.toSet().length, equals(backs.length));
    });

    test('the deck is the right height without being readable', () {
      final state = _playedGame();
      final view = PublicView.decode(
        PublicView.encode(state),
        viewerSeat: 0,
        myHandIds: state.players[0].hand.map((c) => c.id).toList(),
      );
      expect(view.deck.length, equals(state.deck.length));
      expect(view.deck.every((c) => c.isFaceDown), isTrue);
      expect(view.discardTop?.id, equals(state.discardTop?.id));
    });

    test('carries the seat names and who is a bot', () {
      final state = _playedGame();
      final view = PublicView.decode(
        PublicView.encode(state),
        viewerSeat: 0,
        myHandIds: state.players[0].hand.map((c) => c.id).toList(),
      );
      expect(view.players.map((p) => p.name),
          equals(state.players.map((p) => p.name)));
      expect(view.players.map((p) => p.isAI),
          equals(state.players.map((p) => p.isAI)));
    });
  });

  group('a face-down card', () {
    test('is not a real card and says so', () {
      final back = WordCard.faceDown('back_1_0');
      expect(back.isFaceDown, isTrue);
      expect(CardDeck().generate().any((c) => c.id == back.id), isFalse);
    });

    test('a real card is not face down', () {
      expect(CardDeck().generate().first.isFaceDown, isFalse);
    });
  });
}
