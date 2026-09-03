import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';
import '../core/design/table_scaffold.dart';
import '../providers/online_game_provider.dart';
import '../providers/online_providers.dart';
import '../services/online_client.dart';
import 'online/online_messages.dart';

/// The room before the cards come out: who is here, what the code is, and the
/// one button that deals.
///
/// A lobby is mostly waiting, so the screen's job is to make the waiting
/// legible — an empty chair reads as a chair nobody has taken yet, not as a
/// thing that has gone wrong.
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  OnlineGameNotifier? _notifier;
  OnlineState _state = const OnlineState();

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final notifier = OnlineGameNotifier(
      client: ref.read(onlineClientProvider),
      roomId: widget.roomId,
    );
    notifier.addListener((s) {
      if (mounted) setState(() => _state = s);
    });
    await notifier.start();
    if (!mounted) {
      notifier.dispose();
      return;
    }
    setState(() => _notifier = notifier);
  }

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _notifier?.startGame();
    final room = _state.room;
    if (!mounted || room == null) return;
    if (room.isPlaying) {
      context.pushReplacement('/online/${widget.roomId}');
    }
  }

  Future<void> _leave() async {
    await _notifier?.leave();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final room = _state.room;

    // A game the host already dealt: follow them to the table.
    if (room != null && room.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement('/online/${widget.roomId}');
      });
    }

    return TableScaffold(
      appBar: AppBar(
        title: Text(l10n.friendBattle),
        actions: [
          TextButton(onPressed: _leave, child: Text(l10n.leaveRoom)),
        ],
      ),
      body: SafeArea(
        child: room == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CodeCard(code: room.code, l10n: l10n),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(child: _SeatList(room: room, l10n: l10n)),
                    if (_state.error != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          messageForError(l10n, _state.error!),
                          textAlign: TextAlign.center,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.danger),
                        ),
                      ),
                    _StartRow(
                      room: room,
                      l10n: l10n,
                      busy: _state.busy,
                      onStart: _start,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The code, large enough to read out across a table.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.l10n});

  final String code;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(l10n.roomCode, style: AppTypography.label),
            const SizedBox(height: AppSpacing.md),
            SelectableText(
              code,
              style: AppTypography.display
                  .copyWith(letterSpacing: 6, color: AppColors.point),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.shareRoomCode,
                textAlign: TextAlign.center, style: AppTypography.caption),
          ],
        ),
      );
}

class _SeatList extends StatelessWidget {
  const _SeatList({required this.room, required this.l10n});

  final RoomView room;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => ListView.separated(
        itemCount: room.seats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final seat = room.seats[i];
          final isMe = i == room.yourSeat && !seat.isEmpty;
          return ListTile(
            leading: Icon(
              seat.isEmpty ? Icons.chair_outlined : Icons.person,
              color: seat.isEmpty ? AppColors.textSecondary : AppColors.point,
            ),
            title: Text(
              seat.isEmpty ? l10n.emptySeat : seat.name,
              style: AppTypography.body.copyWith(
                color: seat.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: isMe ? Text(l10n.you, style: AppTypography.caption) : null,
            trailing: seat.uid == room.hostUid && !seat.isEmpty
                ? Text(l10n.hostLabel, style: AppTypography.caption)
                : null,
          );
        },
      );
}

/// The deal button for the host, and an explanation for everyone else.
class _StartRow extends StatelessWidget {
  const _StartRow({
    required this.room,
    required this.l10n,
    required this.busy,
    required this.onStart,
  });

  final RoomView room;
  final AppLocalizations l10n;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    if (!room.amHost) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(l10n.waitingForHost,
            textAlign: TextAlign.center, style: AppTypography.label),
      );
    }

    final enough = room.seats.where((s) => !s.isEmpty).length >= 2;
    return Column(
      children: [
        if (!enough)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(l10n.needTwoPlayers,
                textAlign: TextAlign.center, style: AppTypography.caption),
          ),
        FilledButton(
          onPressed: enough && !busy ? onStart : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            backgroundColor: AppColors.point,
          ),
          child: Text(l10n.startGame),
        ),
      ],
    );
  }
}
