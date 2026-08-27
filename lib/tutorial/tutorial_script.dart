import 'package:dripple/l10n/app_localizations.dart';

import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/word_card.dart';

/// What a step points at.
///
/// The board is a Flame canvas, so a step cannot name its target with a widget
/// key the way a coach mark normally would. It names a place instead, and the
/// screen asks the board where that place currently is.
enum TutorialSpot { none, deck, discard, hand, sentence, submit }

/// One thing the lesson says, and what has to happen before it stops saying it.
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.spot,
    required this.dim,
    required this.text,
    this.done,
    this.skippable = false,
  });

  final String id;
  final TutorialSpot spot;

  /// Whether the rest of the screen is covered while this step is up.
  ///
  /// A step that only points at something covers: with one bright place left,
  /// there is nowhere else for a six-year-old to look. A step that asks for a
  /// gesture must not — a hand cannot aim at a target it cannot see, and a
  /// card that misses has to be able to find its way back.
  final bool dim;

  final String Function(AppLocalizations) text;

  /// What ends this step, given the board now and the board when the step
  /// began. Null means the step ends only when the player presses Next.
  final bool Function(GameState now, GameState atEntry)? done;

  /// Whether Next is offered alongside [done]. For a step that asks for
  /// something optional, so nobody is trapped by a gesture they cannot make.
  final bool skippable;

  bool get waitsForPlayer => done != null;
}

List<String> _ids(List<WordCard> cards) => [for (final c in cards) c.id];

bool _sameCards(List<WordCard> a, List<WordCard> b) {
  if (a.length != b.length) return false;
  final x = _ids(a)..sort();
  final y = _ids(b)..sort();
  for (var i = 0; i < x.length; i++) {
    if (x[i] != y[i]) return false;
  }
  return true;
}

/// The hand holds the same cards in a different order — a player sorting,
/// rather than a player playing.
bool _handWasSorted(GameState now, GameState atEntry) {
  final before = atEntry.currentPlayer.hand;
  final after = now.currentPlayer.hand;
  if (!_sameCards(before, after)) return false;
  return !_listEquals(_ids(before), _ids(after));
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The lesson, in order.
///
/// Four things get taught, and they are the four things the board never says
/// out loud: which pile is which, that a hand can be sorted, that a card is
/// played by pushing it forward, and that what is pushed forward can be
/// rearranged. Turn order and the special cards are left for the first real
/// game, where an opponent makes them mean something.
final List<TutorialStep> tutorialScript = [
  TutorialStep(
    id: 'welcome',
    spot: TutorialSpot.none,
    dim: true,
    text: (l) => l.tutorialWelcome,
  ),
  TutorialStep(
    id: 'deck',
    spot: TutorialSpot.deck,
    dim: true,
    text: (l) => l.tutorialDeck,
  ),
  TutorialStep(
    id: 'discard',
    spot: TutorialSpot.discard,
    dim: true,
    text: (l) => l.tutorialDiscard,
  ),
  TutorialStep(
    id: 'draw',
    spot: TutorialSpot.deck,
    dim: false,
    text: (l) => l.tutorialDraw,
    done: (now, _) => now.turnPhase == TurnPhase.action,
  ),
  TutorialStep(
    id: 'sort',
    spot: TutorialSpot.hand,
    dim: false,
    text: (l) => l.tutorialSort,
    done: _handWasSorted,
    // Sorting changes nothing in the rules, so nobody is held here for it.
    skippable: true,
  ),
  TutorialStep(
    id: 'build',
    spot: TutorialSpot.sentence,
    dim: false,
    text: (l) => l.tutorialBuild,
    done: (now, _) => now.currentPlayer.sentenceZone.length >= 2,
  ),
  TutorialStep(
    id: 'reorder',
    spot: TutorialSpot.sentence,
    dim: false,
    text: (l) => l.tutorialReorder,
  ),
  TutorialStep(
    id: 'submit',
    spot: TutorialSpot.submit,
    dim: false,
    text: (l) => l.tutorialSubmit,
  ),
  TutorialStep(
    id: 'done',
    spot: TutorialSpot.none,
    dim: true,
    text: (l) => l.tutorialDone,
  ),
];
