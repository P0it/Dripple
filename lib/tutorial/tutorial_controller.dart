import 'package:flutter/foundation.dart';

import 'package:dripple_rules/models/game_state.dart';
import 'tutorial_script.dart';

/// Where the lesson is up to.
///
/// It watches the board rather than driving it. Every step the player is asked
/// to *do* ends because the game state says it happened — not because the
/// tutorial intercepted the tap — so the gesture being taught is the real one,
/// with the real board underneath it.
class TutorialController extends ChangeNotifier {
  TutorialController({List<TutorialStep>? script})
      : _script = script ?? tutorialScript;

  final List<TutorialStep> _script;

  int _index = 0;

  /// The board as it stood when the current step began. A step that ends on
  /// the player *changing* something has nothing to compare against without
  /// it.
  GameState? _entry;

  /// The last board seen, so a step entered by pressing Next still knows what
  /// it started from.
  GameState? _latest;

  /// Set once the sentence has been accepted, so a failed submission does not
  /// end the lesson. Failure costs nothing in the game either.
  bool _finished = false;

  /// Set when a submission was turned down, so the lesson can say why the
  /// cards came back.
  bool _retrying = false;

  int get index => _index;
  TutorialStep get step => _script[_index];
  bool get isLastStep => _index == _script.length - 1;
  bool get isFinished => _finished;
  bool get isRetrying => _retrying;

  /// Whether the step is waiting on the player and offers no way past.
  bool get blocksOnGesture => step.waitsForPlayer && !step.skippable;

  /// The board changed. Ends the current step if it was waiting for this.
  void syncState(GameState state) {
    if (state.phase != GamePhase.playing) return;
    _latest = state;
    final entry = _entry ??= state;
    final done = step.done;
    if (done == null) return;
    if (done(state, entry)) next();
  }

  /// The sentence parsed. That is the end of the lesson whatever step it
  /// happened on — a player who worked it out early has already learnt it.
  void onSentenceAccepted() {
    _finished = true;
    if (_index == _script.length - 1) return;
    _index = _script.length - 1;
    _entry = _latest;
    _retrying = false;
    notifyListeners();
  }

  /// The sentence did not parse and the cards went back to the hand.
  ///
  /// The lesson goes back to building rather than ending, because in the game
  /// a rejected sentence costs nothing either — the cards return and the turn
  /// carries on. A tutorial that punished the same mistake would be teaching
  /// the opposite of the rule.
  void onSentenceRejected() {
    if (_finished) return;
    final buildAt = _script.indexWhere((s) => s.id == 'build');
    if (buildAt < 0) return;
    _retrying = true;
    _index = buildAt;
    _entry = _latest;
    notifyListeners();
  }

  void next() {
    if (isLastStep) return;
    _index++;
    // The step that follows starts from the board as it stands right now —
    // not from whatever the next change happens to be. Waiting for that
    // change would make a step compare a board against itself, and a step
    // that ends when something changes would then never end.
    _entry = _latest;
    _retrying = false;
    notifyListeners();
  }
}
