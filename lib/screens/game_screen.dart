import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../character/emote_bar.dart';
import '../core/game_feedback.dart';
import '../core/theme/app_theme.dart';
import '../engine/ai/ai_player.dart';
import '../game/dripple_game.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import 'judgment_screen.dart';

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
  bool _isDrawing = false;
  late AnimationController _overlayFadeController;
  late Animation<double> _overlayFadeAnimation;
  ProviderSubscription? _gameSubscription;

  @override
  void initState() {
    super.initState();
    _game = DrippleGame();
    _game.onCardPlaced = _onCardPlaced;
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
        const overlayPhases = {GamePhase.roundEnd, GamePhase.gameEnd};
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

    final notifier = ref.read(gameProvider.notifier);
    final result = notifier.submitSentence();

    if (!mounted) return;

    // Trigger feedback based on result
    if (result.isCorrect) {
      // Use scoreEarned from result to avoid post-await stale state
      await feedback.onCorrectAnswer();
    } else {
      await feedback.onIncorrectAnswer();
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => JudgmentDialog(result: result),
    );

    // Process AI turns
    await _processAITurns();
  }

  Future<void> _processAITurns() async {
    final notifier = ref.read(gameProvider.notifier);
    if (notifier.isProcessingAI) return; // Guard against concurrent calls

    final results = await notifier.processAITurns();

    for (final aiResult in results) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => JudgmentDialog(result: aiResult),
      );
    }

    if (!mounted) return;
    final gameState = ref.read(gameProvider);
    if (gameState.phase == GamePhase.gameEnd) {
      final isWinner = gameState.ranking.first.id == 'human_0';
      if (isWinner) {
        await ref.read(gameFeedbackProvider).onGameWin();
      } else {
        await ref.read(gameFeedbackProvider).onGameLose();
      }
      // Navigation is handled by the gameEnd overlay; nothing more to do here.
    }
  }

  Future<void> _onDraw() async {
    if (_isDrawing) return;
    _isDrawing = true;
    try {
      ref.read(gameProvider.notifier).drawCard();
      ref.read(gameFeedbackProvider).onCardDraw();
      await _processAITurns();
    } finally {
      _isDrawing = false;
    }
  }

  void _onUndo() {
    ref.read(gameProvider.notifier).undoPlacement();
    ref.read(gameFeedbackProvider).onButtonTap();
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
                _ScoreboardBar(gameState: gameState),
                // Opponents area
                _OpponentsBar(gameState: gameState),
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
                // Emote bar
                EmoteBar(
                  playerId: gameState.players.isNotEmpty
                      ? gameState.players[0].id
                      : 'human_0',
                ),
                // Action bar
                _ActionBar(
                  onSubmit: _onSubmit,
                  onDraw: _onDraw,
                  onUndo: _onUndo,
                  canSubmit: gameState.phase == GamePhase.playing &&
                      gameState.players.isNotEmpty &&
                      !gameState.currentPlayer.isAI &&
                      gameState.currentPlayer.sentenceZone.length >= 2,
                  deckCount: gameState.deck.length,
                ),
              ],
            ),
            // ---- Round-end overlay ----
            if (gameState.phase == GamePhase.roundEnd)
              _RoundEndOverlay(
                gameState: gameState,
                fadeAnimation: _overlayFadeAnimation,
                onContinue: () {
                  ref.read(gameProvider.notifier).continueToNextRound();
                },
              ),
            // ---- Game-over overlay ----
            if (gameState.phase == GamePhase.gameEnd)
              _GameEndOverlay(
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
// Round-end overlay
// ---------------------------------------------------------------------------

class _RoundEndOverlay extends StatelessWidget {
  final GameState gameState;
  final Animation<double> fadeAnimation;
  final VoidCallback onContinue;

  const _RoundEndOverlay({
    required this.gameState,
    required this.fadeAnimation,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        color: Colors.black.withAlpha(179), // ~70% opacity
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Round ${gameState.currentRound} Complete!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Score list sorted by rank
                  ...gameState.ranking.map((p) => _ScoreRow(player: p)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      child: const Text('Next Round'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game-end overlay
// ---------------------------------------------------------------------------

class _GameEndOverlay extends StatefulWidget {
  final GameState gameState;
  final Animation<double> fadeAnimation;
  final VoidCallback onDismiss;

  const _GameEndOverlay({
    required this.gameState,
    required this.fadeAnimation,
    required this.onDismiss,
  });

  @override
  State<_GameEndOverlay> createState() => _GameEndOverlayState();
}

class _GameEndOverlayState extends State<_GameEndOverlay> {
  bool _dismissed = false;

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  void initState() {
    super.initState();
    // Auto-navigate after 1.5 s if the player does not tap first.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.gameState.ranking.first;
    final isHumanWinner = winner.id == 'human_0';

    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: widget.fadeAnimation,
        child: Container(
          color: Colors.black.withAlpha(204), // ~80% opacity
          child: Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Game Over!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isHumanWinner
                            ? AppColors.correctGreen
                            : AppColors.incorrectRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isHumanWinner ? 'You win!' : '${winner.name} wins!',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Final scores sorted by rank
                    ...widget.gameState.ranking.map((p) => _ScoreRow(player: p)),
                    const SizedBox(height: 16),
                    Text(
                      'Tap anywhere to continue',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared score row used by both overlays
// ---------------------------------------------------------------------------

class _ScoreRow extends StatelessWidget {
  final Player player;

  const _ScoreRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    player.isAI ? AppColors.textSecondary : AppColors.primary,
                child: Text(
                  player.name[0],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                player.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            '${player.score} pts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreboardBar extends StatelessWidget {
  final GameState gameState;

  const _ScoreboardBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Round indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppLocalizations.of(context)!.roundIndicator(gameState.currentRound, gameState.totalRounds),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const Spacer(),
          // Turn timer - only shown during a human turn
          if (gameState.turnTimeRemaining >= 0 &&
              gameState.phase == GamePhase.playing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TurnTimerWidget(
                secondsRemaining: gameState.turnTimeRemaining,
                totalSeconds: gameState.config.turnTimerSeconds,
              ),
            ),
          // Player scores
          ...gameState.players.map((p) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: p.isAI ? Colors.white24 : Colors.white,
                      child: Text(
                        p.name[0],
                        style: TextStyle(
                          fontSize: 12,
                          color: p.isAI ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${p.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Circular countdown arc displayed in the scoreboard bar during human turns.
class _TurnTimerWidget extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;

  const _TurnTimerWidget({
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsRemaining <= 5;
    final arcColor = isUrgent ? AppColors.incorrectRed : Colors.white;
    final fraction = totalSeconds > 0
        ? (secondsRemaining / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _CountdownArcPainter(
          fraction: fraction,
          arcColor: arcColor,
          trackColor: Colors.white24,
        ),
        child: Center(
          child: Text(
            '$secondsRemaining',
            style: TextStyle(
              color: arcColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownArcPainter extends CustomPainter {
  final double fraction;
  final Color arcColor;
  final Color trackColor;

  const _CountdownArcPainter({
    required this.fraction,
    required this.arcColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    const strokeWidth = 3.0;
    const startAngle = -1.5707963267948966; // -pi/2 (12 o'clock)

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track (full circle)
    canvas.drawArc(rect, 0, 6.283185307179586, false, trackPaint);

    // Remaining time arc (sweeps clockwise from 12 o'clock)
    if (fraction > 0) {
      canvas.drawArc(rect, startAngle, fraction * 6.283185307179586, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_CountdownArcPainter old) =>
      old.fraction != fraction ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor;
}

class _OpponentsBar extends StatelessWidget {
  final GameState gameState;

  const _OpponentsBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final opponents = gameState.players.where((p) => p.isAI).toList();
    if (opponents.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opponents.map((opp) {
          final isCurrentTurn =
              gameState.currentPlayer.id == opp.id;
          return Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isCurrentTurn ? AppColors.primary : Colors.grey.shade300,
                child: Icon(
                  Icons.smart_toy,
                  color: isCurrentTurn ? Colors.white : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                opp.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isCurrentTurn ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.nCards(opp.hand.length),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onDraw;
  final VoidCallback onUndo;
  final bool canSubmit;
  final int deckCount;

  const _ActionBar({
    required this.onSubmit,
    required this.onDraw,
    required this.onUndo,
    required this.canSubmit,
    required this.deckCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Draw pile
          _ActionButton(
            icon: Icons.add_card,
            label: '${AppLocalizations.of(context)!.draw} ($deckCount)',
            onPressed: deckCount > 0 ? onDraw : null,
            color: AppColors.cardUndo,
          ),
          // Undo
          _ActionButton(
            icon: Icons.undo,
            label: AppLocalizations.of(context)!.undo,
            onPressed: onUndo,
            color: Colors.grey,
          ),
          // Submit
          SizedBox(
            width: 120,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: canSubmit ? onSubmit : null,
              icon: const Icon(Icons.check_circle, size: 20),
              label: Text(AppLocalizations.of(context)!.submit),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.correctGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: label,
          icon: Icon(icon, color: color),
          style: IconButton.styleFrom(
            backgroundColor: color.withAlpha(26),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
