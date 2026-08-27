import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/player.dart';
import 'package:dripple_rules/models/word_card.dart';
import 'package:dripple/providers/game_provider.dart';
import 'package:dripple_rules/engine/ai/ai_player.dart';

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
          _pron('p1', 'I'),
          _verb('v1', 'like'),
          _noun('n1', 'cats'),
        ]),
        Player(id: 'ai_2', name: 'AI 2', isAI: true, hand: [
          _noun('n2', 'dogs'),
          _noun('n3', 'birds'),
        ]),
      ],
      deck: [
        _noun('d1', 'apples'),
        _noun('d2', 'pears'),
        _noun('d3', 'plums'),
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
          _pron('p1', 'I'),
          _verb('v1', 'like'),
          _noun('n1', 'cats'),
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
          _noun('n1', 'dogs'),
          _noun('n2', 'birds'),
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

  test('an AI with nothing to play keeps its draw and hands the turn on',
      () async {
    // Verbs only: no sentence at any length, no special card, and nothing in
    // hand the AI can afford to lose. The old opponent was made to throw a
    // verb away here purely to hand the turn over.
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
          _verb('v1', 'like'),
          _verb('v2', 'run'),
        ]),
      ],
      deck: [for (var i = 0; i < 20; i++) _verb('deck_v$i', 'read')],
      // An article on the pile, so taking it cannot make a sentence either.
      discardPile: const [
        WordCard(id: 'x1', word: 'the', pos: PartOfSpeech.article),
      ],
    ));

    await n.runAITurns();

    expect(n.state.currentPlayerIndex, 0, reason: 'the turn was handed on');
    expect(n.state.players[1].hand.length, 3,
        reason: 'it drew a card and kept it');
    expect(n.state.discardPile.map((c) => c.id), ['x1'],
        reason: 'nothing was thrown away');
  });
}
