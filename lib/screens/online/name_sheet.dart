import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../providers/online_providers.dart';
import '../../services/player_identity.dart';

/// Ask for a name, once, at the moment it first matters.
///
/// A player who only ever plays the bots is never asked, which is why this is
/// a sheet raised from the online entry rather than a step on first launch.
/// Nothing else is collected, so this is the whole of signing up.
Future<String?> showNameSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NameSheet(ref: ref),
  );
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.ref.read(playerNameProvider) ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = PlayerIdentity.sanitize(_controller.text);
    if (name.isEmpty) return;
    await widget.ref.read(playerIdentityProvider).setName(name);
    widget.ref.read(playerNameProvider.notifier).state = name;
    if (mounted) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      // Sit above the keyboard rather than behind it.
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.chooseName, style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: PlayerIdentity.maxNameLength,
              textInputAction: TextInputAction.done,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: l10n.chooseNameHint,
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed:
                  PlayerIdentity.isValidName(_controller.text) ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: AppColors.point,
              ),
              child: Text(l10n.chooseNameSave),
            ),
          ],
        ),
      ),
    );
  }
}
