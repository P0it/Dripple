/// Sound effect manager for game events.
/// Uses a simple interface that can be backed by any audio package
/// (e.g., audioplayers, flame_audio, just_audio).
///
/// Sound assets should be placed in assets/sounds/
///
/// To implement:
/// 1. Add audioplayers (or flame_audio) to pubspec.yaml
/// 2. Place .mp3/.wav files in assets/sounds/
/// 3. Register assets in pubspec.yaml under flutter: assets:
/// 4. Implement play methods
enum SoundEffect {
  cardPlace,
  cardDraw,
  submit,
  correct,
  incorrect,
  specialCard,
  emote,
  roundEnd,
  gameWin,
  gameLose,
  buttonTap,
}

class SoundManager {
  bool enabled = true;

  /// Play a sound effect
  Future<void> play(SoundEffect effect) async {
    if (!enabled) return;
    // TODO: Implement with audio package
    // Example with audioplayers:
    // final player = AudioPlayer();
    // await player.play(AssetSource('sounds/${effect.name}.mp3'));
  }

  /// Play background music
  Future<void> playBgm() async {
    if (!enabled) return;
    // TODO: Implement background music loop
  }

  /// Stop background music
  Future<void> stopBgm() async {
    // TODO: Stop background music
  }

  void dispose() {
    // TODO: Dispose audio resources
  }
}
