import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/game_icons.dart';

/// Large button sized for small hands.
///
/// Children aged 6-10 miss a standard 36px material button often enough that
/// it reads as the game being broken, so the target here is 60px tall.
///
/// The press used to be a bevelled lift with an offset shadow. The size is
/// what makes it hittable; the bevel was decoration, and it was the last
/// plastic-looking thing on the board. Pressing now darkens and settles the
/// fill instead.
class BigActionButton extends StatefulWidget {
  const BigActionButton({
    super.key,
    required this.label,
    this.sublabel,
    this.icon,
    required this.color,
    this.onPressed,
    this.selected = false,
  });

  final String label;
  final String? sublabel;
  final GameIcon? icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  State<BigActionButton> createState() => _BigActionButtonState();
}

class _BigActionButtonState extends State<BigActionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fill = !enabled
        ? AppColors.divider
        : _down
            ? Color.lerp(widget.color, Colors.black, 0.14)!
            : widget.color;
    final foreground = enabled ? Colors.white : AppColors.textDisabled;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.sublabel == null
          ? widget.label
          : '${widget.label}, ${widget.sublabel}',
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: AppSpacing.buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: widget.selected
                ? Border.all(color: AppColors.textPrimary, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon case final icon?) ...[
                GameIconView(icon, size: 22, color: foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: AppTypography.label
                        .copyWith(fontSize: 17, color: foreground),
                  ),
                  if (widget.sublabel case final sub?)
                    Text(
                      sub,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: foreground.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
