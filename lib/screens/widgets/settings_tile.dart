import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';

/// One row in a settings or lobby list.
///
/// Both screens were building their own row shape with slightly different
/// padding and dividers. This is the one shape they share.
///
/// The row is set **on the ink**, not on paper. Paper is where the game prints
/// things — cards, and sheets a player reads. A list of switches is neither:
/// it is the table's own controls, and putting them on a sheet of stock made
/// them read as a document about the settings rather than as the settings.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Full-width content under the label — a slider, for instance.
  final Widget? below;

  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.trimDim))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.onTable(AppTypography.body),
                      ),
                      if (subtitle case final text?) ...[
                        const SizedBox(height: 2),
                        Text(
                          text,
                          style: AppTypography.onTable(AppTypography.caption),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing case final widget?) widget,
              ],
            ),
            if (below case final widget?) widget,
          ],
        ),
      ),
    );
  }
}

/// A titled group of [SettingsTile]s.
///
/// There is no container. This was a sheet of stock with a radius, a border
/// and a drop shadow — a card floating on the table — and two of those groups
/// stacked read as a web page imitating a settings app. What names a group is
/// its title and the space above it, which is what names a group on any
/// printed page too.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: Text(
              title,
              style: AppTypography.onTable(AppTypography.caption)
                  .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.6),
            ),
          ),
          // A rule above the first row, so a group reads as a block even
          // before its rows have anything under them.
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.trimDim,
          ),
          Column(children: tiles),
        ],
      ),
    );
  }
}
