import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/design/felt_scaffold.dart';
import '../core/game_feedback.dart';
import '../core/tutorial_prefs.dart';
import 'package:dripple_rules/engine/ai/ai_player.dart';
import '../game/dripple_game.dart';
import 'package:dripple_rules/models/game_state.dart';
import 'package:dripple_rules/models/word_card.dart';
import '../providers/game_provider.dart';
import '../tutorial/tutorial_controller.dart';
import '../tutorial/tutorial_script.dart';
import 'tutorial/tutorial_overlay.dart';
import 'game/action_bar.dart';
import 'game/game_end_overlay.dart';
import 'game/opponents_bar.dart';
import 'judgment_screen.dart';
import 'widgets/special_card_sheet.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int playerCount;
  final AIDifficulty difficulty;

  /// Runs the scripted one-player lesson instead of a game: a dealt board
  /// nobody can get stuck on, with the coach marks over it.
  final bool tutorial;

  const GameScreen({
    super.key,
    required this.playerCount,
    this.difficulty = AIDifficulty.medium,
    this.tutorial = false,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late DrippleGame _game;
  bool _initialized = false;
  late AnimationController _overlayFadeController;
  TutorialController? _tutorial;
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _submitKey = GlobalKey();
  final GlobalKey _overlayKey = GlobalKey();
  late Animation<double> _overlayFadeAnimation;
  ProviderSubscription? _gameSubscription;

  @override
  void initState() {
    super.initState();
    _game = DrippleGame();
    if (widget.tutorial) {
      _tutorial = TutorialController()..addListener(_onTutorialStep);
    }
    _game.onCardPlaced = _onCardPlaced;
    _game.onDrawFromDeck = _onDrawFromDeck;
    _game.onDrawFromDiscard = _onDrawFromDiscard;
    _game.onDiscardCard = _onDiscardCard;
    _game.onSentenceReorder = (from, to) =>
        ref.read(gameProvider.notifier).reorderSentence(from, to);
    _game.onSentenceRemove = (index) =>
        ref.read(gameProvider.notifier).removeFromSentence(index);
    _game.onHandCardTapped = _onHandCardTapped;
    _game.onHandReorder = (from, to) =>
        ref.read(gameProvider.notifier).reorderHand(from, to);
    _overlayFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _overlayFadeAnimation = CurvedAnimation(
      parent: _overlayFadeController,
      curve: Curves.easeIn,
    );
  }

  /// A step change moves the coach mark, which is measured against the board
  /// as it stands after this frame.
  void _onTutorialStep() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tutorial?.removeListener(_onTutorialStep);
    _tutorial?.dispose();
    _gameSubscription?.close();
    _overlayFadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _game.locale = Localizations.localeOf(context).languageCode;
    _game.labels = ZoneLabels(
      hand: l10n.sentenceZoneHand,
      hint: l10n.sentenceZoneHint,
      deck: l10n.pileDeck,
      discard: l10n.pileDiscard,
    );
    if (!_initialized) {
      _initialized = true;
      // Listen to game state changes and sync to Flame after frame
      _gameSubscription = ref.listenManual(gameProvider, (prev, next) {
        if (!mounted) return;
        if (next.players.isNotEmpty && next.phase == GamePhase.playing) {
          final humanPlayer = next.players[0];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _game.updatePiles(
              deckCount: next.deck.length,
              discardTop: next.discardTop,
            );
            _game.updateHand(humanPlayer.hand);
            _game.updateSentenceZone(humanPlayer.sentenceZone);
            // After the board has been told, not before: a step that ends on
            // a gesture moves the coach mark, and the mark is measured
            // against where the cards now are.
            _tutorial?.syncState(next);
          });
        }
        // Trigger fade-in animation whenever an overlay phase is entered
        const overlayPhases = {GamePhase.gameEnd};
        final enteringOverlay = overlayPhases.contains(next.phase) &&
            !overlayPhases.contains(prev?.phase);
        if (enteringOverlay) {
          _overlayFadeController.forward(from: 0);
        } else if (!overlayPhases.contains(next.phase)) {
          _overlayFadeController.reverse();
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.tutorial) {
          ref.read(gameProvider.notifier).startTutorial();
        } else {
          ref.read(gameProvider.notifier).startGame(
                GameConfig(
                  playerCount: widget.playerCount,
                  difficulty: widget.difficulty,
                ),
              );
        }
        ref.read(gameFeedbackProvider).playGameMusic();
      });
    }
  }

  void _onCardPlaced(int cardIndex, int insertAt) {
    ref.read(gameProvider.notifier).placeCard(cardIndex, insertAt: insertAt);
    ref.read(gameFeedbackProvider).onCardPlace();
  }

  void _onSubmit() async {
    final feedback = ref.read(gameFeedbackProvider);
    await feedback.onSubmit();

    final result = ref.read(gameProvider.notifier).submitSentence();
    if (!mounted) return;

    if (result.isCorrect) {
      _game.playSuccessSweep();
      _tutorial?.onSentenceAccepted();
      await feedback.onCorrectAnswer();
    } else {
      _tutorial?.onSentenceRejected();
      await feedback.onIncorrectAnswer();
    }
    if (!mounted) return;

    await showJudgmentSheet(context, result);
  }

  /// End the turn without spending a card.
  ///
  /// Only a sentence empties a hand, so being made to throw a card away to
  /// finish a turn left a player drawing one and discarding one forever at the
  /// same hand size. Passing keeps the draw, and a hand that grows is the one
  /// that eventually holds a long sentence.
  void _onPass() {
    if (ref.read(gameProvider.notifier).passTurn()) {
      ref.read(gameFeedbackProvider).onButtonTap();
    }
  }

  void _onDrawFromDeck() {
    ref.read(gameProvider.notifier).drawFromDeck();
    ref.read(gameFeedbackProvider).onCardDraw();
  }

  void _onDrawFromDiscard() {
    ref.read(gameProvider.notifier).drawFromDiscard();
    ref.read(gameFeedbackProvider).onCardDraw();
  }

  /// Tapping a hand card either stages it into the sentence, or — while the
  /// discard picker is open — throws it away. A modal list of card names was
  /// the earlier design and read as an interruption; picking the actual card
  /// on the board is the same gesture a child already uses to play one.
  void _onHandCardTapped(int handIndex) {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.read(gameProvider);
    if (!state.isMyTurn) return;

    if (state.turnPhase != TurnPhase.action) return;

    // A JUMP or STEAL card is used, not played into a sentence. Tapping the
    // card itself is how you use it — the chip row that used to sit under the
    // board was a second place to find the same card.
    final card = state.currentPlayer.hand[handIndex];
    if (card.type == CardType.jump || card.type == CardType.steal) {
      showSpecialCardSheet(
        context,
        ref: ref,
        card: card,
        handIndex: handIndex,
      );
      return;
    }

    notifier.placeCard(handIndex);
    ref.read(gameFeedbackProvider).onCardPlace();
  }

  /// A card dragged onto the discard pile. This replaced a mode: you used to
  /// press a button, watch the hand turn red, then pick a card — two taps and
  /// a state to be in. Dragging onto the pile is one gesture, and it is the
  /// gesture the sentence zone already taught.
  void _onDiscardCard(int handIndex) {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.read(gameProvider);
    if (!state.isMyTurn) return;
    if (state.turnPhase != TurnPhase.action) return;

    final card = state.currentPlayer.hand[handIndex];
    if (card.id == state.drawnFromDiscardCardId) {
      _showHint(AppLocalizations.of(context)!.cannotDiscardJustTaken);
      return;
    }
    if (notifier.discardCard(handIndex)) {
      ref.read(gameFeedbackProvider).onCardPlace();
    }
  }

  void _showHint(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Where a coach mark's target is, in the overlay's own coordinates.
  ///
  /// The board is a canvas, so its furniture cannot be found by widget key
  /// the way the submit button can. It hands out rectangles in board
  /// coordinates instead, and the board's own box converts them.
  Rect? _spotRect(TutorialSpot spot) {
    final overlayBox =
        _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) return null;

    Rect? fromWidget(GlobalKey key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      final topLeft = overlayBox.globalToLocal(box.localToGlobal(Offset.zero));
      return topLeft & box.size;
    }

    Rect? fromBoard(Rect? boardRect) {
      if (boardRect == null) return null;
      final box =
          _boardKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      final topLeft =
          overlayBox.globalToLocal(box.localToGlobal(boardRect.topLeft));
      return topLeft & boardRect.size;
    }

    return switch (spot) {
      TutorialSpot.none => null,
      TutorialSpot.deck => fromBoard(_game.deckRect),
      TutorialSpot.discard => fromBoard(_game.discardRect),
      TutorialSpot.hand => fromBoard(_game.handRect),
      TutorialSpot.sentence => fromBoard(_game.sentenceRect),
      TutorialSpot.submit => fromWidget(_submitKey),
    };
  }

  /// The step whose target has already been measured against a laid-out
  /// board. The first build of a step runs before anything has a size, so
  /// one extra frame is asked for and then the matter is closed.
  String? _measuredStep;

  void _remeasureIfNeeded(TutorialStep step) {
    if (_measuredStep == step.id) return;
    _measuredStep = step.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _leaveTutorial() {
    ref.read(gameFeedbackProvider).onButtonTap();
    if (mounted) context.go('/home');
  }

  void _finishTutorial() {
    ref.read(gameFeedbackProvider).onButtonTap();
    unawaited(TutorialPrefs.markCompleted());
    if (!mounted) return;
    // Landing on the mode list with home behind it, which is the stack a
    // player who had walked there themselves would be standing on.
    context.go('/home');
    context.push('/mode-select');
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final tutorial = _tutorial;
    if (tutorial != null) _remeasureIfNeeded(tutorial.step);

    return FeltScaffold(
      body: SafeArea(
        child: Stack(
          key: _overlayKey,
          children: [
            // ---- Main game UI ----
            Column(
              children: [
                // There is one row of players, not two. The strip that used to
                // sit above this one carried every player's card count — which
                // is the same number this row already prints under each
                // opponent — plus a step pill saying "draw" or "action", which
                // the action bar at the foot says in words you can act on. The
                // only things up there with no double were the clock and the
                // mute, so they moved into this row and the strip went.
                OpponentsBar(gameState: gameState),
                // The zone labels used to be one line of text above the whole
                // board, which named neither band it sat over. They are drawn
                // on the bands themselves now.
                // Flame game area
                Expanded(
                  child: GameWidget(key: _boardKey, game: _game),
                ),
                // Drawing, discarding and using a special card all happen on
                // the board now. Submitting is the one thing with no object
                // to touch, so it is the one thing left down here.
                ActionBar(
                  gameState: gameState,
                  onSubmit: _onSubmit,
                  // One player has nobody to hand a turn to, so the lesson
                  // has no Pass button to explain.
                  onPass: widget.tutorial ? null : _onPass,
                  submitKey: _submitKey,
                ),
              ],
            ),
            // ---- The lesson ----
            if (tutorial != null && gameState.phase == GamePhase.playing)
              Positioned.fill(
                child: TutorialOverlay(
                  step: tutorial.step,
                  hole: _spotRect(tutorial.step.spot),
                  isLastStep: tutorial.isLastStep,
                  isRetrying: tutorial.isRetrying,
                  onNext: tutorial.next,
                  onFinish: _finishTutorial,
                  onQuit: _leaveTutorial,
                ),
              ),
            // ---- Game-over overlay ----
            if (tutorial == null && gameState.phase == GamePhase.gameEnd)
              GameEndOverlay(
                gameState: gameState,
                fadeAnimation: _overlayFadeAnimation,
                onDismiss: () {
                  if (mounted) context.go('/result');
                },
              ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Game-end overlay
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------



