import 'package:dripple/l10n/app_localizations.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/design/table_scaffold.dart';
import '../../game/dripple_game.dart';
import '../../providers/online_game_provider.dart';
import '../../services/online_client.dart';
import 'package:dripple_rules/models/game_state.dart';
import '../../providers/online_providers.dart';
import '../game/action_bar.dart';
import '../game/game_end_overlay.dart';
import '../game/opponents_bar.dart';
import 'online_messages.dart';

/// The table, played against people.
///
/// It is deliberately a separate screen from the local one rather than a mode
/// of it: the local screen also carries the tutorial, and threading a second
/// source of truth through that was going to break the thing that teaches
/// people the game. What is shared is everything that matters — the Flame
/// board, the opponents row, the action bar, the end overlay — so an online
/// table and a local one are the same table.
class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen>
    with SingleTickerProviderStateMixin {
  late final DrippleGame _game;
  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  OnlineGameNotifier? _notifier;
  RemoveListener? _removeListener;
  OnlineState _state = const OnlineState();
  bool _labelled = false;

  @override
  void initState() {
    super.initState();
    _game = DrippleGame();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _wireBoard();
    _connect();
  }

  /// Every gesture on the board goes to the notifier. The ones that only move
  /// cards inside this hand are answered instantly; the rest are requests.
  void _wireBoard() {
    _game.onCardPlaced = (int handIndex, int insertAt) =>
        _notifier?.placeCard(handIndex, insertAt: insertAt);
    _game.onSentenceReorder = (from, to) => _notifier?.reorderSentence(from, to);
    _game.onSentenceRemove = (index) => _notifier?.removeFromSentence(index);
    _game.onHandReorder = (from, to) => _notifier?.reorderHand(from, to);
    _game.onDrawFromDeck = () => _notifier?.drawFromDeck();
    _game.onDrawFromDiscard = () => _notifier?.drawFromDiscard();
    _game.onDiscardCard = _onDiscard;
    _game.onHandCardTapped = _onHandCardTapped;
  }

  Future<void> _connect() async {
    final notifier = OnlineGameNotifier(
      client: ref.read(onlineClientProvider),
      roomId: widget.roomId,
    );
    _removeListener = notifier.addListener(_onServerState);
    await notifier.start();
    if (!mounted) {
      notifier.dispose();
      return;
    }
    setState(() => _notifier = notifier);
  }

  void _onServerState(OnlineState next) {
    if (!mounted) return;
    setState(() => _state = next);

    final game = next.game;
    if (game == null || game.players.isEmpty) return;

    // Tell the board after the frame, the way the local screen does: the
    // cards' positions are measured against a board that has settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _game.updatePiles(
        deckCount: game.deck.length,
        discardTop: game.discardTop,
      );
      _game.updateHand(game.me.hand);
      _game.updateSentenceZone(game.me.sentenceZone);
      // Same rule as the offline board: the felt asks for a sentence only
      // while one can be pushed forward.
      _game.canBuild = game.isMyTurn && game.turnPhase == TurnPhase.action;
    });

    if (next.room?.isFinished ?? false) _fadeController.forward();
    final judgment = next.judgment;
    if (judgment != null && !judgment.isCorrect) _showJudgment(judgment);
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
    _labelled = true;
  }

  @override
  void dispose() {
    _removeListener?.call();
    _notifier?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------

  void _onHandCardTapped(int handIndex) {
    // Special cards are used rather than played into a sentence, and choosing
    // a target needs a sheet. Until that sheet is online-aware, tapping a
    // card puts it in the sentence like any other.
    _notifier?.placeCard(handIndex);
  }

  void _onDiscard(int handIndex) {
    final game = _state.game;
    if (game == null || handIndex >= game.me.hand.length) return;
    _notifier?.discard(game.me.hand[handIndex]);
  }

  void _showJudgment(Judgment judgment) {
    final l10n = AppLocalizations.of(context)!;
    final reason = judgment.messages.isEmpty
        ? l10n.errorGeneric
        : judgment.messages.first;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(reason)));
    _notifier?.clearJudgment();
  }

  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = _state.game;

    if (game == null || !_labelled) {
      return const TableScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return TableScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                OpponentsBar(gameState: game),
                _TurnBanner(state: _state, l10n: l10n),
                Expanded(child: GameWidget(game: _game)),
                ActionBar(
                  gameState: game,
                  onSubmit: () => _notifier?.submitStaged(),
                  onPass: () => _notifier?.pass(),
                ),
              ],
            ),
            if (_state.room?.isFinished ?? false)
              GameEndOverlay(
                gameState: game,
                fadeAnimation: _fade,
                onDismiss: () {
                  if (mounted) context.go('/');
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Whose move it is, and whether the game can still hear us.
///
/// Online the board can look perfectly playable while being none of your
/// business, so the one thing that must always be on screen is whose turn it
/// is. A lost connection goes in the same place, because it is the same
/// question: can I do anything right now?
class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.state, required this.l10n});

  final OnlineState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final error = state.error;
    final offline = error != null && error.isOffline;
    final game = state.game;

    final String text;
    final Color colour;
    if (offline) {
      text = l10n.connectionLost;
      colour = AppColors.danger;
    } else if (error != null) {
      text = messageForError(l10n, error);
      colour = AppColors.danger;
    } else if (game != null && game.isMyTurn) {
      text = l10n.yourTurnBanner;
      colour = AppColors.pointOnTable;
    } else {
      final name = game == null ? '' : game.currentPlayer.name;
      text = l10n.seatTurnBanner(name);
      colour = AppColors.onTableSoft;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(text,
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(color: colour)),
    );
  }
}
