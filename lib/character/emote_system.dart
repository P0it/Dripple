import '../core/game_icons.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'character_emotion.dart';

/// Emote type corresponds to emote buttons during gameplay
enum EmoteType {
  happy,
  angry,
  taunt,
  amazed,
  shocked;

  CharacterEmotion toEmotion() {
    switch (this) {
      case EmoteType.happy:
        return CharacterEmotion.happy;
      case EmoteType.angry:
        return CharacterEmotion.sad;
      case EmoteType.taunt:
        return CharacterEmotion.taunt;
      case EmoteType.amazed:
        return CharacterEmotion.happy;
      case EmoteType.shocked:
        return CharacterEmotion.shocked;
    }
  }

  /// Vector face for this emote. Emoji were dropped because they render
  /// differently on every platform and not at all inside the Flame canvas.
  GameIcon get icon {
    switch (this) {
      case EmoteType.happy:
        return GameIcon.faceHappy;
      case EmoteType.angry:
        return GameIcon.faceAngry;
      case EmoteType.taunt:
        return GameIcon.faceSmug;
      case EmoteType.amazed:
        return GameIcon.faceExcited;
      case EmoteType.shocked:
        return GameIcon.faceShocked;
    }
  }
}

/// Emote event sent between players
class EmoteEvent {
  final String playerId;
  final EmoteType emote;
  final DateTime timestamp;

  EmoteEvent({
    required this.playerId,
    required this.emote,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Manages emote state with cooldown
class EmoteNotifier extends StateNotifier<EmoteState> {
  static const cooldownDuration = Duration(seconds: 3);
  Timer? _cooldownTimer;
  Timer? _displayTimer;

  EmoteNotifier() : super(const EmoteState());

  /// Send an emote (checks cooldown)
  EmoteEvent? sendEmote(String playerId, EmoteType emote) {
    if (state.isOnCooldown) return null;

    final event = EmoteEvent(playerId: playerId, emote: emote);

    state = EmoteState(
      lastEmote: event,
      cooldownEnd: DateTime.now().add(cooldownDuration),
    );

    // Auto-reset after cooldown
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(cooldownDuration, () {
      if (mounted) {
        state = const EmoteState();
      }
    });

    return event;
  }

  /// Receive an emote from another player (no cooldown check)
  void receiveEmote(EmoteEvent event) {
    state = EmoteState(lastEmote: event);

    // Clear after display duration
    _displayTimer?.cancel();
    _displayTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        state = const EmoteState();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _displayTimer?.cancel();
    super.dispose();
  }
}

class EmoteState {
  final EmoteEvent? lastEmote;
  final DateTime? cooldownEnd;

  const EmoteState({this.lastEmote, this.cooldownEnd});

  bool get isOnCooldown =>
      cooldownEnd != null && DateTime.now().isBefore(cooldownEnd!);

  double get cooldownProgress {
    if (cooldownEnd == null) return 0;
    final remaining = cooldownEnd!.difference(DateTime.now()).inMilliseconds;
    if (remaining <= 0) return 0;
    return remaining / EmoteNotifier.cooldownDuration.inMilliseconds;
  }
}

final emoteProvider = StateNotifierProvider<EmoteNotifier, EmoteState>((ref) {
  return EmoteNotifier();
});
