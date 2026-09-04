import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';
import '../core/design/seat_mark.dart';
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
                    Expanded(
                      child: SingleChildScrollView(
                        child: _SeatList(room: room, l10n: l10n),
                      ),
                    ),
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

/// Who is in the room, as one picture and then as a list.
///
/// This was a bare `ListTile` column standing directly on the table with its
/// type set in **ink** — `AppColors.textPrimary` is #1B1D21 and the table is
/// #15181C, so every player's name was being drawn in near-black on
/// near-black. Paper type on a furniture ground is the failure mode the
/// two-material palette exists to prevent, and the lobby had it outright.
///
/// So the list is a rail panel now, exactly like the mode list, and the row
/// marks come from the same seat vocabulary: a chair somebody is in is
/// filled, an empty one is a ring, and yours takes the brand blue.
///
/// Above the rows the whole room is drawn once, live. It is the same picture
/// the player pressed to get here — 방 만들기 shows you and three empty
/// chairs — and watching those chairs fill is the entire content of a lobby.
class _SeatList extends StatelessWidget {
  const _SeatList({required this.room, required this.l10n});

  final RoomView room;
  final AppLocalizations l10n;

  /// The room as [SeatMark] wants it: clockwise from *your* chair, because on
  /// a board you are always at the near edge. Before the server has seated
  /// you the list is shown in its own order — there is no near edge yet.
  List<Seat> get _seats {
    Seat kindOf(int i) => room.seats[i].isEmpty
        ? Seat.open
        : (i == room.yourSeat ? Seat.you : Seat.taken);

    final n = room.seats.length;
    final from = (room.yourSeat >= 0 && room.yourSeat < n) ? room.yourSeat : 0;
    return [for (var k = 0; k < n; k++) kindOf((from + k) % n)];
  }

  @override
  Widget build(BuildContext context) {
    final taken = room.seats.where((s) => !s.isEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.roomSeats,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.onTableSoft,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                '$taken/${room.seats.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.onTableSoft,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        // A plain column, not a ListView. A room holds four chairs, and a
        // scrolling viewport given less height than that quietly drops the
        // last one — which is the single worst thing a lobby can do, because
        // an empty chair that is not drawn is indistinguishable from a room
        // that has no room left. A short screen scrolls the whole panel
        // instead; see the SingleChildScrollView this sits in.
        Material(
          color: AppColors.rail,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: SeatMark(
                    seats: _seats,
                    ground: AppColors.rail,
                    size: 72,
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.trimDim),
              for (var i = 0; i < room.seats.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: _seatRowInset),
                    child: Divider(
                        height: 1, thickness: 1, color: AppColors.trimDim),
                  ),
                _SeatRow(
                  seat: room.seats[i],
                  isMe: i == room.yourSeat && !room.seats[i].isEmpty,
                  isHost: room.seats[i].uid == room.hostUid &&
                      !room.seats[i].isEmpty,
                  l10n: l10n,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

const double _seatRowInset = AppSpacing.md + 16 + AppSpacing.md;

/// One chair in the list.
class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.seat,
    required this.isMe,
    required this.isHost,
    required this.l10n,
  });

  final SeatView seat;
  final bool isMe;
  final bool isHost;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final kind = seat.isEmpty ? Seat.open : (isMe ? Seat.you : Seat.taken);

    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          SeatPip(seat: kind),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              seat.isEmpty ? l10n.emptySeat : seat.name,
              style: AppTypography.body.copyWith(
                color: seat.isEmpty
                    ? AppColors.onTableSoft
                    : AppColors.onTable,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          // Two facts about one chair, so they read as one trailing group
          // rather than as a column the empty rows leave holes in.
          if (isMe) _SeatTag(l10n.you, accent: true),
          if (isMe && isHost) const SizedBox(width: AppSpacing.xs),
          if (isHost) _SeatTag(l10n.hostLabel),
        ],
      ),
    );
  }
}

class _SeatTag extends StatelessWidget {
  const _SeatTag(this.text, {this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.caption.copyWith(
          color: accent ? AppColors.pointOnTable : AppColors.onTableSoft,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
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
        // Furniture, like everything else standing on the table. This was
        // ink too, and invisible for the same reason the seat names were.
        child: Text(l10n.waitingForHost,
            textAlign: TextAlign.center,
            style: AppTypography.onTable(AppTypography.label)),
      );
    }

    final enough = room.seats.where((s) => !s.isEmpty).length >= 2;
    return Column(
      children: [
        if (!enough)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(l10n.needTwoPlayers,
                textAlign: TextAlign.center,
                style: AppTypography.onTable(AppTypography.caption)),
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
