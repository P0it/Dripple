import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'emote_system.dart';

/// Emote bar with 5 character expression buttons.
/// These are custom character face variations, NOT standard emoji.
/// Currently using emoji placeholders until Rive character emote assets are ready.
class EmoteBar extends ConsumerWidget {
  final String playerId;

  const EmoteBar({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emoteState = ref.watch(emoteProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: EmoteType.values.map((emote) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _EmoteButton(
              emote: emote,
              isOnCooldown: emoteState.isOnCooldown,
              onPressed: () {
                ref.read(emoteProvider.notifier).sendEmote(playerId, emote);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmoteButton extends StatelessWidget {
  final EmoteType emote;
  final bool isOnCooldown;
  final VoidCallback onPressed;

  const _EmoteButton({
    required this.emote,
    required this.isOnCooldown,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOnCooldown ? null : onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isOnCooldown ? 0.4 : 1.0,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              emote.label,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// Emote bubble that appears above a character when they emote
class EmoteBubble extends StatelessWidget {
  final EmoteType emote;

  const EmoteBubble({super.key, required this.emote});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          emote.label,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}
