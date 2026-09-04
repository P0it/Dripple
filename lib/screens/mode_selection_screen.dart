import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/app_colors.dart';
import '../core/design/table_scaffold.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_typography.dart';
import '../core/design/seat_mark.dart';
import 'package:dripple_rules/engine/ai/ai_player.dart';
import '../providers/online_providers.dart';
import '../services/online_client.dart';
import 'online/join_sheet.dart';
import 'online/name_sheet.dart';
import 'online/online_messages.dart';

/// Pick an opponent, then pick how hard it plays.
///
/// The list is **furniture, not paper**. It used to be five identical slabs of
/// card stock floating on the table, each with a Material icon in brand blue
/// and a chevron — which broke the one rule the palette is organised around:
/// paper is where something is *read*, furniture is where something is *held*.
/// A menu holds; nothing on it is printed. Five sheets of stock on a table
/// also spend the material that is supposed to mean "this is a card", so by
/// the time a real card appears it is the sixth white rectangle of the
/// session.
///
/// So the rows sit in two rail-coloured panels, cream type on dark, hairlines
/// between them — the same rail the hand rests on during a game.
///
/// The two panels are the split that actually matters to a player: **on your
/// own**, and **with other people**. Flat, the five rows made picking between
/// "AI 대전" and "방 만들기" a question about the app; grouped, it is a
/// question about who is around.
///
/// Every icon is gone. See [SeatMark] for what replaced them and why.
class ModeSelectionScreen extends ConsumerWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return TableScaffold(
      appBar: AppBar(title: Text(l10n.selectMode)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          children: [
            _GroupLabel(l10n.modeGroupSolo),
            _ModePanel(children: [
              // First, and not behind anything. Someone who has never played
              // opens this screen not knowing what the game is, and the row
              // that explains it should not be below the row that starts it.
              _ModeCell(
                seats: const [Seat.you],
                title: l10n.tutorial,
                subtitle: l10n.tutorialDesc,
                onTap: () => context.push('/tutorial'),
              ),
              _ModeCell(
                seats: const [Seat.you, Seat.taken, Seat.taken, Seat.taken],
                title: l10n.aiBattle,
                subtitle: l10n.aiBattleDesc,
                onTap: () => _pickDifficulty(context, l10n),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            _GroupLabel(l10n.modeGroupFriends),
            _ModePanel(children: [
              _ModeCell(
                seats: const [Seat.you, Seat.open, Seat.open, Seat.open],
                title: l10n.createRoom,
                subtitle: l10n.createRoomDesc,
                onTap: () => _createRoom(context, ref),
              ),
              _ModeCell(
                seats: const [Seat.open, Seat.taken, Seat.taken, Seat.taken],
                title: l10n.joinRoom,
                subtitle: l10n.joinRoomDesc,
                onTap: () => _joinRoom(context, ref),
              ),
              // Matchmaking against strangers is a separate problem — who you
              // are matched with, and what they may say to you — and this game
              // is played by children. It comes after friends.
              _ModeCell(
                seats: const [Seat.open, Seat.open, Seat.open, Seat.open],
                title: l10n.onlineBattle,
                subtitle: l10n.onlineBattleDesc,
                badge: l10n.comingSoon,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDifficulty(
      BuildContext context, AppLocalizations l10n) async {
    final choice = await showModalBottomSheet<AIDifficulty>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Text(l10n.aiDifficulty,
                  style: AppTypography.onTable(AppTypography.heading)),
            ),
            _DifficultyCell(
              label: l10n.difficultyEasy,
              description: l10n.difficultyEasyDesc,
              onTap: () => Navigator.of(sheet).pop(AIDifficulty.easy),
            ),
            _DifficultyCell(
              label: l10n.difficultyMedium,
              description: l10n.difficultyMediumDesc,
              onTap: () => Navigator.of(sheet).pop(AIDifficulty.medium),
            ),
            _DifficultyCell(
              label: l10n.difficultyHard,
              description: l10n.difficultyHardDesc,
              onTap: () => Navigator.of(sheet).pop(AIDifficulty.hard),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;
    // Player count is fixed at four: JUMP and STEAL only matter with
    // opponents to point them at, and asking a child two questions before
    // the game starts is one too many.
    context.push('/game?players=4&difficulty=${choice.name}');
  }
}

/// Everything online needs a name first, and nobody is asked for one until
/// this moment.
Future<String?> _ensureName(BuildContext context, WidgetRef ref) async {
  final existing = ref.read(playerNameProvider);
  if (existing != null) return existing;
  if (!context.mounted) return null;
  return showNameSheet(context, ref);
}

Future<void> _createRoom(BuildContext context, WidgetRef ref) async {
  final name = await _ensureName(context, ref);
  if (name == null || !context.mounted) return;
  await _enterRoom(
    context,
    () => ref.read(onlineClientProvider).createRoom(name: name),
  );
}

Future<void> _joinRoom(BuildContext context, WidgetRef ref) async {
  final name = await _ensureName(context, ref);
  if (name == null || !context.mounted) return;
  final code = await showJoinSheet(context);
  if (code == null || !context.mounted) return;
  await _enterRoom(
    context,
    () => ref.read(onlineClientProvider).joinRoom(code: code, name: name),
  );
}

/// Make or join a room and walk into its lobby, saying plainly what happened
/// if the server would not have us.
Future<void> _enterRoom(
  BuildContext context,
  Future<RoomView> Function() request,
) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final room = await request();
    if (context.mounted) context.push('/lobby/${room.roomId}');
  } on OnlineError catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(messageForError(l10n, e))));
  }
}

/// The label over a group of rows. Set on the bare table, not on the panel —
/// it names the panel, so it cannot also be inside it.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs, AppSpacing.sm, 0, AppSpacing.sm),
        child: Text(
          text,
          style: AppTypography.caption.copyWith(
            color: AppColors.onTableSoft,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      );
}

/// One rail carrying a group of rows.
///
/// A single piece of furniture with hairlines cut across it, rather than a
/// stack of separate tiles with gaps. The gaps were what made five rows read
/// as five unrelated things.
class _ModePanel extends StatelessWidget {
  const _ModePanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Padding(
          // Inset past the seat mark, so the rule starts where the type does
          // and the marks read as one column down the panel.
          padding: const EdgeInsets.only(left: _ModeCell.textInset),
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppColors.trimDim,
          ),
        ));
      }
      rows.add(children[i]);
    }

    return Material(
      color: AppColors.rail,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// One mode.
class _ModeCell extends StatelessWidget {
  const _ModeCell({
    required this.seats,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  /// Who is at that table. See [SeatMark].
  final List<Seat> seats;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  static const double markSize = 32;
  static const double textInset = AppSpacing.md + markSize + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch + 16),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            SeatMark(
              seats: seats,
              ground: AppColors.rail,
              size: markSize,
              muted: !enabled,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.label.copyWith(
                      fontSize: 16,
                      color: enabled
                          ? AppColors.onTable
                          : AppColors.onTableSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.onTableSoft),
                  ),
                ],
              ),
            ),
            // No chevron. Every row in a list of choices leads somewhere, so
            // an arrow on each of them says nothing and repeats itself five
            // times; the one row that does *not* lead anywhere says so in
            // words instead — and in the same cream as the rest of the
            // furniture, because a tinted pill would make the unavailable
            // mode the loudest thing on the screen.
            if (badge case final text?)
              Text(
                text,
                style: AppTypography.caption.copyWith(
                  color: AppColors.onTableSoft,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One difficulty row inside the sheet.
class _DifficultyCell extends StatelessWidget {
  const _DifficultyCell({
    required this.label,
    required this.description,
    required this.onTap,
  });

  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch + 8),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTypography.body),
                  const SizedBox(height: 2),
                  Text(description, style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
