import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/game_feedback.dart';
import '../core/theme/app_theme.dart';
import '../engine/ai/ai_player.dart';
import '../game/dripple_game.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'game/action_bar.dart';
import 'game/game_end_overlay.dart';
import 'game/opponents_bar.dart';
import 'game/scoreboard_bar.dart';
import 'judgment_screen.dart';
import 'widgets/special_card_sheet.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int playerCount;
  final AIDifficulty difficulty;

  const GameScreen({
    super.key,
    required this.playerCount,
    this.difficulty = AIDifficulty.medium,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late DrippleGame _game;
  bool _initialized = false;
  bool _discardMode = false;
  late AnimationController _overlayFadeController;
  late Animation<double> _overlayFadeAnimation;
  ProviderSubscription? _gameSubscription;

  @override
  void initState() {
    super.initState();
    _game = DrippleGame();
    _game.onCardPlaced = _onCardPlaced;
    _game.onSentenceReorder = (from, to) =>
        ref.read(gameProvider.notifier).reorderSentence(from, to);
    _game.onSentenceRemove = (index) =>
        ref.read(gameProvider.notifier).removeFromSentence(index);
    _game.onHandCardTapped = _onHandCardTapped;
    _overlayFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _overlayFadeAnimation = CurvedAnimation(
      parent: _overlayFadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _gameSubscription?.close();
    _overlayFadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Listen to game state changes and sync to Flame after frame
      _gameSubscription = ref.listenManual(gameProvider, (prev, next) {
        if (!mounted) return;
        if (next.players.isNotEmpty && next.phase == GamePhase.playing) {
          final humanPlayer = next.players[0];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _game.updateHand(humanPlayer.hand);
            _game.updateSentenceZone(humanPlayer.sentenceZone);
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
        ref.read(gameProvider.notifier).startGame(
              GameConfig(
                playerCount: widget.playerCount,
                difficulty: widget.difficulty,
              ),
            );
        ref.read(gameFeedbackProvider).playGameMusic();
      });
    }
  }

  void _onCardPlaced(int cardIndex) {
    ref.read(gameProvider.notifier).placeCard(cardIndex);
    ref.read(gameFeedbackProvider).onCardPlace();
  }

  void _onSubmit() async {
    final feedback = ref.read(gameFeedbackProvider);
    await feedback.onSubmit();

    final result = ref.read(gameProvider.notifier).submitSentence();
    if (!mounted) return;

    if (result.isCorrect) {
      await feedback.onCorrectAnswer();
    } else {
      await feedback.onIncorrectAnswer();
    }
    if (!mounted) return;

    await showJudgmentSheet(context, result);
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
    if (state.phase != GamePhase.playing || state.currentPlayer.isAI) return;

    if (_discardMode) {
      final card = state.currentPlayer.hand[handIndex];
      if (card.id == state.drawnFromDiscardCardId) {
        _showHint('이 카드는 방금 가져와서 지금은 버릴 수 없어요');
        return;
      }
      if (notifier.discardCard(handIndex)) {
        ref.read(gameFeedbackProvider).onCardPlace();
        _setDiscardMode(false);
      }
      return;
    }

    if (state.turnPhase != TurnPhase.action) return;
    notifier.placeCard(handIndex);
    ref.read(gameFeedbackProvider).onCardPlace();
  }

  void _setDiscardMode(bool value) {
    if (_discardMode == value) return;
    setState(() => _discardMode = value);
    _game.discardMode = value;
    ref.read(gameFeedbackProvider).onButtonTap();
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

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ---- Main game UI ----
            Column(
              children: [
                // Scoreboard
                ScoreboardBar(gameState: gameState),
                // Opponents area
                OpponentsBar(gameState: gameState),
                // Sentence zone label
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    AppLocalizations.of(context)!.sentenceZone,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Flame game area
                Expanded(
                  child: GameWidget(game: _game),
                ),
                // Special card actions (JUMP / STEAL)
                if (gameState.phase == GamePhase.playing &&
                    gameState.players.isNotEmpty &&
                    !gameState.currentPlayer.isAI &&
                    gameState.turnPhase == TurnPhase.action)
                  SpecialCardRow(
                    hand: gameState.currentPlayer.hand,
                    onTap: (handIndex) => showSpecialCardSheet(
                      context,
                      ref: ref,
                      card: gameState.currentPlayer.hand[handIndex],
                      handIndex: handIndex,
                    ),
                  ),
                // Action bar
                ActionBar(
                  gameState: gameState,
                  discardMode: _discardMode,
                  onDrawFromDeck: _onDrawFromDeck,
                  onDrawFromDiscard: _onDrawFromDiscard,
                  onSubmit: _onSubmit,
                  onToggleDiscard: () => _setDiscardMode(!_discardMode),
                ),
              ],
            ),
            // ---- Game-over overlay ----
            if (gameState.phase == GamePhase.gameEnd)
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



