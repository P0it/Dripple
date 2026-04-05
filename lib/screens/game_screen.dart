import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../character/emote_bar.dart';
import '../core/theme/app_theme.dart';
import '../game/dripple_game.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'judgment_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int playerCount;

  const GameScreen({super.key, required this.playerCount});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late DrippleGame _game;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _game = DrippleGame();
    _game.onCardPlaced = _onCardPlaced;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gameProvider.notifier).startGame(
              GameConfig(playerCount: widget.playerCount),
            );
      });
    }
  }

  void _onCardPlaced(int cardIndex) {
    ref.read(gameProvider.notifier).placeCard(cardIndex);
  }

  void _onSubmit() async {
    final notifier = ref.read(gameProvider.notifier);
    final result = notifier.submitSentence();

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
    var gameState = ref.read(gameProvider);

    while (gameState.phase == GamePhase.playing &&
        gameState.currentPlayer.isAI) {
      await Future.delayed(const Duration(milliseconds: 800));

      final aiResult = await notifier.executeAITurn();
      if (!mounted) return;

      if (aiResult != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => JudgmentDialog(result: aiResult),
        );
      }

      gameState = ref.read(gameProvider);
    }

    if (gameState.phase == GamePhase.gameEnd && mounted) {
      context.go('/result');
    }
  }

  void _onDraw() {
    ref.read(gameProvider.notifier).drawCard();
    _processAITurns();
  }

  void _onUndo() {
    ref.read(gameProvider.notifier).undoPlacement();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    // Sync game state to Flame
    if (gameState.players.isNotEmpty && gameState.phase == GamePhase.playing) {
      final humanPlayer = gameState.players[0];
      _game.updateHand(humanPlayer.hand);
      _game.updateSentenceZone(humanPlayer.sentenceZone);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
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
                  !gameState.currentPlayer.isAI &&
                  gameState.currentPlayer.sentenceZone.length >= 2,
              deckCount: gameState.deck.length,
            ),
          ],
        ),
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
