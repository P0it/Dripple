import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';

/// Ask for the code a friend read out.
///
/// Uppercased as it is typed and spaced out, because the code exists to be
/// said across a room and copied down by somebody who is six.
Future<String?> showJoinSheet(BuildContext context) => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _JoinSheet(),
    );

class _JoinSheet extends StatefulWidget {
  const _JoinSheet();

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _code => _controller.text.replaceAll(RegExp(r'[^A-Z0-9]'), '');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.enterRoomCode, style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: AppTypography.display
                  .copyWith(letterSpacing: 6, color: AppColors.point),
              inputFormatters: [UpperCaseFormatter()],
              decoration: const InputDecoration(counterText: ''),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) =>
                  _code.length == 6 ? Navigator.of(context).pop(_code) : null,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _code.length == 6
                  ? () => Navigator.of(context).pop(_code)
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: AppColors.point,
              ),
              child: Text(l10n.join),
            ),
          ],
        ),
      ),
    );
  }
}

/// Room codes have no lower case, so neither does the field.
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
