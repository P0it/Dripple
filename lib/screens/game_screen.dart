import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/game_feedback.dart';
import '../core/game_icons.dart';
import '../core/theme/app_theme.dart';
import '../engine/ai/ai_player.dart';
import '../game/dripple_game.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import 'judgment_screen.dart';
import 'widgets/big_action_button.dart';
import 'widgets/special_card_sheet.dart';
import '../models/word_card.dart';

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

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => JudgmentDialog(result: result),
    );
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
                // Special card actions (JUMP / STEAL)
                if (gameState.phase == GamePhase.playing &&
                    gameState.players.isNotEmpty &&
                    !gameState.currentPlayer.isAI &&
                    gameState.turnPhase == TurnPhase.action)
                  _SpecialCardRow(
                    hand: gameState.currentPlayer.hand,
                    onTap: (handIndex) => showSpecialCardSheet(
                      context,
                      ref: ref,
                      card: gameState.currentPlayer.hand[handIndex],
                      handIndex: handIndex,
                    ),
                  ),
                // Action bar
                _ActionBar(
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
          // Turn step indicator — rounds are gone; the turn has two steps.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              gameState.turnPhase == TurnPhase.draw ? '① 뽑기' : '② 액션',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _MuteButton(),
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
          // Cards remaining per player — one card left is the danger sign.
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
                      '${p.hand.length}',
                      style: TextStyle(
                        color: p.hand.length == 1
                            ? Colors.amberAccent
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: p.hand.length == 1 ? 18 : 14,
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
  final GameState gameState;
  final bool discardMode;
  final VoidCallback onDrawFromDeck;
  final VoidCallback onDrawFromDiscard;
  final VoidCallback onSubmit;
  final VoidCallback onToggleDiscard;

  const _ActionBar({
    required this.gameState,
    required this.discardMode,
    required this.onDrawFromDeck,
    required this.onDrawFromDiscard,
    required this.onSubmit,
    required this.onToggleDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final isHumanTurn = gameState.phase == GamePhase.playing &&
        gameState.players.isNotEmpty &&
        !gameState.currentPlayer.isAI;

    if (!isHumanTurn) {
      return Container(
        height: 76,
        alignment: Alignment.center,
        child: Text(
          '상대가 생각하고 있어요...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (discardMode) {
      return Container(
        height: 76,
        color: const Color(0xFFFEF2F2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                '버릴 카드를 골라 톡 눌러요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
            BigActionButton(
              label: '취소',
              color: const Color(0xFF9CA3AF),
              onPressed: onToggleDiscard,
            ),
          ],
        ),
      );
    }

    // Turn step 1: you must draw exactly one card.
    if (gameState.turnPhase == TurnPhase.draw) {
      final top = gameState.discardTop;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            BigActionButton(
              label: '새 카드',
              sublabel: '${gameState.deck.length}장 남음',
              icon: GameIcon.deck,
              color: AppColors.primary,
              onPressed: onDrawFromDeck,
            ),
            BigActionButton(
              label: top == null ? '버린 카드' : top.word,
              sublabel: top == null ? '없어요' : '가져오기',
              icon: GameIcon.discard,
              color: const Color(0xFF3B82F6),
              onPressed: top == null ? null : onDrawFromDiscard,
            ),
          ],
        ),
      );
    }

    // Turn step 2: exactly one action.
    final canSubmit = gameState.currentPlayer.sentenceZone.length >= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BigActionButton(
            label: '문장 완성',
            sublabel: canSubmit ? null : '카드를 2장 이상 놓아요',
            icon: GameIcon.check,
            color: AppColors.primary,
            onPressed: canSubmit ? onSubmit : null,
          ),
          BigActionButton(
            label: '카드 버리기',
            icon: GameIcon.discard,
            color: const Color(0xFFF97316),
            onPressed: onToggleDiscard,
          ),
        ],
      ),
    );
  }
}

/// Sound toggle, kept on the board rather than buried in settings — a child
/// playing next to someone else needs to silence it without leaving the game.
class _MuteButton extends ConsumerStatefulWidget {
  const _MuteButton();

  @override
  ConsumerState<_MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends ConsumerState<_MuteButton> {
  @override
  Widget build(BuildContext context) {
    final sound = ref.read(gameFeedbackProvider).sound;
    final on = sound.sfxEnabled || sound.musicEnabled;

    return Semantics(
      button: true,
      label: on ? '소리 끄기' : '소리 켜기',
      child: GestureDetector(
        onTap: () {
          final next = !on;
          sound.sfxEnabled = next;
          sound.musicEnabled = next;
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
          child: GameIconView(
            on ? GameIcon.soundOn : GameIcon.soundOff,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// JUMP / STEAL cards surfaced as chips — the hand itself is drawn by Flame,
/// which has no notion of tapping a card to open a sheet.
class _SpecialCardRow extends StatelessWidget {
  final List<WordCard> hand;
  final void Function(int handIndex) onTap;

  const _SpecialCardRow({required this.hand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final entries = <int>[];
    for (int i = 0; i < hand.length; i++) {
      if (hand[i].type == CardType.jump || hand[i].type == CardType.steal) {
        entries.add(i);
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          for (final i in entries)
            ActionChip(
              avatar: GameIconView(
                hand[i].type == CardType.jump
                    ? GameIcon.jump
                    : GameIcon.steal,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(hand[i].type == CardType.jump ? 'JUMP' : 'STEAL'),
              onPressed: () => onTap(i),
            ),
        ],
      ),
    );
  }
}
