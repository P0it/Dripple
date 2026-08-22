import 'package:flutter/material.dart';

import '../../core/game_icons.dart';

/// Large, high-contrast button sized for small hands.
///
/// Children aged 6-10 miss standard 36px material buttons often enough that
/// it reads as the game being broken, so the tap target here is 64px tall
/// with a chunky pressed state.
class BigActionButton extends StatefulWidget {
  final String label;
  final String? sublabel;
  final GameIcon? icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool selected;

  const BigActionButton({
    super.key,
    required this.label,
    this.sublabel,
    this.icon,
    required this.color,
    this.onPressed,
    this.selected = false,
  });

  @override
  State<BigActionButton> createState() => _BigActionButtonState();
}

class _BigActionButtonState extends State<BigActionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final base = enabled ? widget.color : const Color(0xFFD1D5DB);
    final shadow = Color.lerp(base, Colors.black, 0.28)!;
    final lift = _down || !enabled ? 0.0 : 4.0;

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
          padding: EdgeInsets.only(top: lift, bottom: 4 - lift),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(18),
              border: widget.selected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  offset: Offset(0, 4 - lift),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  GameIconView(widget.icon!, size: 26, color: Colors.white),
                  const SizedBox(width: 10),
                ],
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.sublabel != null)
                      Text(
                        widget.sublabel!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
