import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/word_card.dart';
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
      n.debugSetState(n.state.copyWith(
        deck: const [],
        discardPile: const [
          WordCard(id: 'd1', word: 'cat', pos: PartOfSpeech.noun),
          WordCard(id: 'd2', word: 'dog', pos: PartOfSpeech.noun),
          WordCard(id: 'd3', word: 'run', pos: PartOfSpeech.verb),
        ],
      ));

      n.drawFromDeck();

      expect(n.state.deckRecycleCount, 1);
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
