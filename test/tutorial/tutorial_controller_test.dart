import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/models/game_state.dart';
import 'package:dripple/providers/game_provider.dart';
import 'package:dripple/tutorial/tutorial_controller.dart';

/// Walks the lesson the way the screen does: every change to the board is
/// handed to the controller, and nothing else is.
class _Lesson {
  _Lesson()
      : notifier = GameNotifier(autoRunAI: false),
        controller = TutorialController() {
    notifier.startTutorial();
    controller.syncState(notifier.state);
  }

  final GameNotifier notifier;
  final TutorialController controller;

  String get step => controller.step.id;
  GameState get state => notifier.state;

  void sync() => controller.syncState(notifier.state);

  void act(void Function(GameNotifier n) action) {
    action(notifier);
    sync();
  }

  int handIndexOf(String word) =>
      state.players[0].hand.indexWhere((c) => c.word == word);
}

void main() {
  group('the scripted board', () {
    test('deals a hand that is out of order and a deck that fixes it', () {
      final n = GameNotifier(autoRunAI: false)..startTutorial();

      expect(n.state.players, hasLength(1));
      expect(n.state.players[0].isAI, isFalse);
      expect(n.state.players[0].hand.map((c) => c.word).toList(),
          ['runs', 'the', 'cat']);
      expect(n.state.deck.last.word, 'big');
      expect(n.state.discardTop!.word, 'dog');
      expect(n.state.turnPhase, TurnPhase.draw);
    });

    test('the drawn hand can make a sentence the lesson asks for', () {
      final n = GameNotifier(autoRunAI: false)..startTutorial();
      n.drawFromDeck();

      // "the cat runs", in that order.
      for (final word in ['the', 'cat', 'runs']) {
        n.placeCard(n.state.players[0].hand.indexWhere((c) => c.word == word));
      }
      expect(n.submitSentence().isCorrect, isTrue);
    });
  });

  group('walking the lesson', () {
    test('reaches the end by doing what each step asks', () {
      final lesson = _Lesson();

      expect(lesson.step, 'welcome');
      lesson.controller.next();
      expect(lesson.step, 'deck');
      lesson.controller.next();
      expect(lesson.step, 'discard');
      lesson.controller.next();
      expect(lesson.step, 'draw');

      // Drawing is what ends the draw step — not a button.
      lesson.act((n) => n.drawFromDeck());
      expect(lesson.step, 'sort');

      // Sorting the hand ends the sort step.
      lesson.act((n) => n.reorderHand(0, 2));
      expect(lesson.step, 'build');

      lesson.act((n) => n.placeCard(lesson.handIndexOf('the')));
      expect(lesson.step, 'build', reason: 'one card is not a sentence yet');
      lesson.act((n) => n.placeCard(lesson.handIndexOf('cat')));
      expect(lesson.step, 'reorder');

      lesson.controller.next();
      expect(lesson.step, 'submit');
    });

    test('the sort step can be skipped, because sorting changes nothing', () {
      final lesson = _Lesson();
      for (var i = 0; i < 3; i++) {
        lesson.controller.next();
      }
      lesson.act((n) => n.drawFromDeck());
      expect(lesson.step, 'sort');
      expect(lesson.controller.step.skippable, isTrue);
      lesson.controller.next();
      expect(lesson.step, 'build');
    });

    test('playing a card is not mistaken for sorting the hand', () {
      final lesson = _Lesson();
      for (var i = 0; i < 3; i++) {
        lesson.controller.next();
      }
      lesson.act((n) => n.drawFromDeck());
      expect(lesson.step, 'sort');

      lesson.act((n) => n.placeCard(0));
      expect(lesson.step, 'sort',
          reason: 'the hand lost a card — that is playing, not tidying');
    });

    test('a rejected sentence sends the lesson back to building', () {
      final lesson = _Lesson();
      lesson.act((n) => n.drawFromDeck());
      for (final word in ['runs', 'the']) {
        lesson.act((n) => n.placeCard(lesson.handIndexOf(word)));
      }

      final result = lesson.notifier.submitSentence();
      expect(result.isCorrect, isFalse);
      lesson.controller.onSentenceRejected();

      expect(lesson.step, 'build');
      expect(lesson.controller.isRetrying, isTrue);
      expect(lesson.controller.isFinished, isFalse);
      expect(lesson.state.players[0].sentenceZone, isEmpty,
          reason: 'the cards come back, as they do in the game');
    });

    test('an accepted sentence ends the lesson from wherever it happened', () {
      final lesson = _Lesson();
      lesson.act((n) => n.drawFromDeck());
      for (final word in ['the', 'cat', 'runs']) {
        lesson.act((n) => n.placeCard(lesson.handIndexOf(word)));
      }

      expect(lesson.notifier.submitSentence().isCorrect, isTrue);
      lesson.controller.onSentenceAccepted();

      expect(lesson.step, 'done');
      expect(lesson.controller.isLastStep, isTrue);
      expect(lesson.controller.isFinished, isTrue);
    });
  });

  group('the steps themselves', () {
    test('every step that asks for a gesture is either skippable or ends '
        'on the board changing', () {
      final controller = TutorialController();
      // The lesson must never sit on a step with no way forward: a step is
      // passed by a button, by a gesture the board reports, or both.
      for (var i = 0; i < 20 && !controller.isLastStep; i++) {
        final step = controller.step;
        expect(
          step.done != null || !step.waitsForPlayer,
          isTrue,
          reason: '${step.id} waits for the player but reports nothing',
        );
        controller.next();
      }
      expect(controller.step.id, 'done');
    });

    test('the covered steps are the ones that ask for nothing', () {
      final controller = TutorialController();
      final covered = <String>[];
      for (var i = 0; i < 20; i++) {
        if (controller.step.dim) covered.add(controller.step.id);
        if (controller.isLastStep) break;
        controller.next();
      }
      expect(covered, ['welcome', 'deck', 'discard', 'done']);
    });
  });
}
