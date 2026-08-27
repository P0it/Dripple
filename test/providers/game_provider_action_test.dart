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
            [
              _pron('c1', 'I'),
              _verb('c2', 'like'),
              _noun('c3', 'cats'),
              _noun('c4', 'dogs'),
            ],
      ),
      const Player(id: 'ai_1', name: 'AI 1', isAI: true),
    ],
    deck: [_noun('d1', 'birds')],
    discardPile: discard ?? [_noun('x1', 'fish')],
  ));
  return n;
}

void main() {
  _passing();

  group('sentence zone editing', () {
    test('placeCard moves a card from hand to the sentence zone', () {
      final n = _board();
      n.placeCard(0);
      expect(n.state.players[0].hand.length, 3);
      expect(n.state.players[0].sentenceZone.single.id, 'c1');
    });

    test('placeCard honours the index the card was dropped on', () {
      final n = _board();
      n.placeCard(0); // c1
      n.placeCard(0, insertAt: 0); // c2 in front of it
      expect(n.state.players[0].sentenceZone.map((c) => c.id).toList(),
          ['c2', 'c1']);
    });

    test('placeCard clamps an index past the end of the sentence', () {
      final n = _board();
      n.placeCard(0, insertAt: 99);
      n.placeCard(0, insertAt: -3);
      expect(n.state.players[0].sentenceZone.map((c) => c.id).toList(),
          ['c2', 'c1']);
    });

    test('removeFromSentence returns any card, not just the last', () {
      final n = _board();
      n.placeCard(0);
      n.placeCard(0);
      n.removeFromSentence(0);
      expect(n.state.players[0].sentenceZone.single.id, 'c2');
      expect(n.state.players[0].hand.any((c) => c.id == 'c1'), true);
    });

    test('reorderSentence moves a card to a new index', () {
      final n = _board();
      n.placeCard(1);
      n.placeCard(0);
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
      n.placeCard(0);
      n.placeCard(0);
      n.placeCard(0);

      final result = n.submitSentence();

      expect(result.isCorrect, true);
      expect(n.state.players[0].hand.length, 1);
      expect(n.state.players[0].sentenceZone, isEmpty);
      expect(n.state.currentPlayerIndex, 1);
      expect(n.state.turnPhase, TurnPhase.draw);
    });

    test('invalid sentence returns cards and does NOT end the turn', () {
      final n = _board();
      n.placeCard(1);
      n.placeCard(0);

      final result = n.submitSentence();

      expect(result.isCorrect, false);
      expect(n.state.players[0].hand.length, 4);
      expect(n.state.players[0].sentenceZone, isEmpty);
      expect(n.state.currentPlayerIndex, 0, reason: 'turn must not advance');
      expect(n.state.turnPhase, TurnPhase.action);
    });

    test('emptying the hand wins the game immediately', () {
      final n = _board(hand: [
        _pron('c1', 'I'),
        _verb('c2', 'like'),
        _noun('c3', 'cats'),
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
      final ok = n.discardCard(3);

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
      expect(n.state.winnerIndex, 1);
    });
  });
}

// ---------------------------------------------------------------------------
// Passing
// ---------------------------------------------------------------------------

void _passing() {
  group('passTurn', () {
    test('ends the turn without spending a card', () {
      final n = _board();
      final before = n.state.players[0].hand.length;
      final pile = n.state.discardPile.length;

      expect(n.passTurn(), isTrue);

      expect(n.state.players[0].hand.length, before,
          reason: 'passing costs nothing');
      expect(n.state.discardPile.length, pile);
      expect(n.state.currentPlayerIndex, 1);
      expect(n.state.turnPhase, TurnPhase.draw);
    });

    test('is refused before the draw', () {
      final n = _board();
      n.debugSetState(n.state.copyWith(turnPhase: TurnPhase.draw));

      expect(n.passTurn(), isFalse,
          reason: 'a turn where nothing happened has not happened');
      expect(n.state.currentPlayerIndex, 0);
    });

    test('returns staged cards to the hand', () {
      final n = _board();
      n.placeCard(0);
      expect(n.state.players[0].sentenceZone, isNotEmpty);
      final total = n.state.players[0].hand.length +
          n.state.players[0].sentenceZone.length;

      expect(n.passTurn(), isTrue);
      expect(n.state.players[0].hand.length, total);
      expect(n.state.players[0].sentenceZone, isEmpty);
    });

    test('drawing then passing grows the hand, which discarding never does',
        () {
      // The loop the pass button exists for: draw one, throw one away, and
      // the hand is the size it was. Only a hand that grows can reach a
      // sentence long enough to empty it.
      final n = _board();
      n.debugSetState(n.state.copyWith(turnPhase: TurnPhase.draw));
      final before = n.state.players[0].hand.length;

      n.drawFromDeck();
      expect(n.state.players[0].hand.length, before + 1);
      n.passTurn();
      expect(n.state.players[0].hand.length, before + 1);
    });
  });
}
