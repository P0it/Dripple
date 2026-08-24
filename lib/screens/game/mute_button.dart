import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/game_feedback.dart';
import '../../core/game_icons.dart';


/// Sound toggle, kept on the board rather than buried in settings — a child
/// playing next to someone else needs to silence it without leaving the game.

/// Sound toggle, kept on the board rather than buried in settings — a child
/// playing next to someone else needs to silence it without leaving the game.
class MuteButton extends ConsumerStatefulWidget {
  const MuteButton({super.key});

  @override
  ConsumerState<MuteButton> createState() => MuteButtonState();
}

class MuteButtonState extends ConsumerState<MuteButton> {
  @override
  Widget build(BuildContext context) {
    final sound = ref.read(gameFeedbackProvider).sound;
    final on = sound.sfxEnabled || sound.musicEnabled;

    return Semantics(
      button: true,
      label: on ? '소리 끄기' : '소리 켜기',
      child: GestureDetector(
        onTap: () {
          final next = !on;
          sound.sfxEnabled = next;
          sound.musicEnabled = next;
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
          child: GameIconView(
            on ? GameIcon.soundOn : GameIcon.soundOff,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// JUMP / STEAL cards surfaced as chips — the hand itself is drawn by Flame,
/// which has no notion of tapping a card to open a sheet.

/// JUMP / STEAL cards surfaced as chips — the hand itself is drawn by Flame,
/// which has no notion of tapping a card to open a sheet.
