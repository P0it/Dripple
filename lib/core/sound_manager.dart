import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All sound effects used in the game.
/// Place corresponding .mp3 files in assets/sounds/ with matching names.
/// e.g., assets/sounds/card_place.mp3
enum SoundEffect {
  cardPlace, // Card placed into sentence zone
  cardDraw, // Card drawn from deck
  cardFlip, // Card flipped/revealed
  submit, // Sentence submitted
  correct, // Correct sentence judgment
  incorrect, // Incorrect sentence judgment
  specialSkip, // SKIP card played
  specialSteal, // STEAL card played
  specialUndo, // UNDO card played
  specialWild, // WILD card played
  emote, // Emote sent
  roundStart, // New round begins
  roundEnd, // Round ends
  gameWin, // Player wins the game
  gameLose, // Player loses the game
  comboHit, // Combo multiplier activated
  turnStart, // Your turn begins
  turnTick, // Turn timer ticking (last 5 seconds)
  buttonTap, // Generic UI button tap
  countdown, // 3-2-1 countdown
  matchFound, // Online matchmaking found
}

/// Background music tracks.
/// Place corresponding .mp3 files in assets/music/ with matching names.
enum MusicTrack {
  menuTheme, // Home screen / menu
  gamePlay, // During gameplay (general)
  myTurn, // When it's the player's turn (higher tempo/energy)
  tenseMoment, // Last round or close scores
  victory, // Victory screen
  defeat, // Defeat screen
}

/// Central audio manager for all game sounds.
/// Handles sound effects (short, one-shot), background music (looping),
/// and turn-specific music transitions.
class SoundManager {
  // SFX pool — multiple players for overlapping sounds
  final Map<SoundEffect, AudioPlayer> _sfxPlayers = {};

  // BGM — single player with crossfade support
  AudioPlayer? _bgmPlayer;
  AudioPlayer? _bgmCrossfadePlayer;
  MusicTrack? _currentTrack;

  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  double _sfxVolume = 0.8;
  double _musicVolume = 0.5;

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;

  /// Toggle sound effects on/off
  set sfxEnabled(bool value) {
    _sfxEnabled = value;
    if (!value) stopAllSfx();
  }

  /// Toggle background music on/off
  set musicEnabled(bool value) {
    _musicEnabled = value;
    if (!value) {
      stopMusic();
    } else if (_currentTrack != null) {
      playMusic(_currentTrack!);
    }
  }

  /// Set sound effects volume (0.0 - 1.0)
  set sfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
  }

  /// Set music volume (0.0 - 1.0)
  set musicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
    _bgmPlayer?.setVolume(_musicVolume);
  }

  // ========== SOUND EFFECTS ==========

  /// Play a one-shot sound effect
  Future<void> play(SoundEffect effect) async {
    if (!_sfxEnabled) return;

    try {
      final player = _sfxPlayers[effect] ??= AudioPlayer()
        ..setReleaseMode(ReleaseMode.stop);
      _sfxPlayers[effect] = player;

      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sounds/${effect.name}.mp3'));
    } catch (_) {
      // Silently ignore if asset doesn't exist yet
    }
  }

  /// Play a sound effect with custom volume (for things like distant sounds)
  Future<void> playAt(SoundEffect effect, {double volume = 1.0}) async {
    if (!_sfxEnabled) return;

    try {
      // Use a fresh player for custom volume to avoid conflicts
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.release);
      await player.setVolume((_sfxVolume * volume).clamp(0.0, 1.0));
      await player.play(AssetSource('sounds/${effect.name}.mp3'));
    } catch (_) {}
  }

  /// Stop all currently playing sound effects
  void stopAllSfx() {
    for (final player in _sfxPlayers.values) {
      player.stop();
    }
  }

  // ========== BACKGROUND MUSIC ==========

  /// Play background music (loops automatically)
  Future<void> playMusic(MusicTrack track) async {
    _currentTrack = track;
    if (!_musicEnabled) return;

    try {
      // If same track is already playing, skip
      if (_bgmPlayer != null && _currentTrack == track) {
        final state = _bgmPlayer!.state;
        if (state == PlayerState.playing) return;
      }

      await _bgmPlayer?.stop();
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(_musicVolume);
      await _bgmPlayer!.play(AssetSource('music/${track.name}.mp3'));
    } catch (_) {
      // Silently ignore if asset doesn't exist yet
    }
  }

  /// Crossfade to a different music track (smooth transition)
  Future<void> crossfadeTo(MusicTrack track,
      {Duration duration = const Duration(milliseconds: 800)}) async {
    if (!_musicEnabled || _currentTrack == track) return;
    _currentTrack = track;

    try {
      // Start new track at zero volume
      _bgmCrossfadePlayer = AudioPlayer();
      await _bgmCrossfadePlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmCrossfadePlayer!.setVolume(0);
      await _bgmCrossfadePlayer!.play(AssetSource('music/${track.name}.mp3'));

      // Fade out old, fade in new over duration
      final steps = 10;
      final stepDuration = duration ~/ steps;

      for (int i = 1; i <= steps; i++) {
        await Future.delayed(stepDuration);
        final progress = i / steps;
        _bgmPlayer?.setVolume(_musicVolume * (1 - progress));
        _bgmCrossfadePlayer?.setVolume(_musicVolume * progress);
      }

      // Swap players
      await _bgmPlayer?.stop();
      await _bgmPlayer?.dispose();
      _bgmPlayer = _bgmCrossfadePlayer;
      _bgmCrossfadePlayer = null;
    } catch (_) {
      // Fallback: just switch directly
      await playMusic(track);
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    await _bgmPlayer?.stop();
    await _bgmCrossfadePlayer?.stop();
  }

  /// Pause background music (e.g., app goes to background)
  Future<void> pauseMusic() async {
    await _bgmPlayer?.pause();
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (_musicEnabled) {
      await _bgmPlayer?.resume();
    }
  }

  // ========== GAME-SPECIFIC AUDIO HELPERS ==========

  /// Called when it becomes the human player's turn
  Future<void> onMyTurnStart() async {
    await play(SoundEffect.turnStart);
    await crossfadeTo(MusicTrack.myTurn);
  }

  /// Called when the human player's turn ends
  Future<void> onMyTurnEnd() async {
    await crossfadeTo(MusicTrack.gamePlay);
  }

  /// Called when sentence is judged correct
  Future<void> onCorrectAnswer({int comboCount = 0}) async {
    if (comboCount >= 2) {
      await play(SoundEffect.comboHit);
      // Slight delay then play correct sound
      await Future.delayed(const Duration(milliseconds: 200));
    }
    await play(SoundEffect.correct);
  }

  /// Called when sentence is judged incorrect
  Future<void> onIncorrectAnswer() async {
    await play(SoundEffect.incorrect);
  }

  /// Called when a special card is played
  Future<void> onSpecialCard(String cardType) async {
    switch (cardType) {
      case 'skip':
        await play(SoundEffect.specialSkip);
      case 'steal':
        await play(SoundEffect.specialSteal);
      case 'undo':
        await play(SoundEffect.specialUndo);
      case 'wild':
        await play(SoundEffect.specialWild);
    }
  }

  /// Called when game enters the final round or scores are close
  Future<void> onTenseMoment() async {
    await crossfadeTo(MusicTrack.tenseMoment);
  }

  /// Called when game ends
  Future<void> onGameEnd({required bool isWinner}) async {
    await stopMusic();
    if (isWinner) {
      await play(SoundEffect.gameWin);
      await playMusic(MusicTrack.victory);
    } else {
      await play(SoundEffect.gameLose);
      await playMusic(MusicTrack.defeat);
    }
  }

  // ========== LIFECYCLE ==========

  /// Dispose all audio resources
  void dispose() {
    for (final player in _sfxPlayers.values) {
      player.dispose();
    }
    _sfxPlayers.clear();
    _bgmPlayer?.dispose();
    _bgmCrossfadePlayer?.dispose();
    _bgmPlayer = null;
    _bgmCrossfadePlayer = null;
  }
}

/// Global SoundManager provider
final soundManagerProvider = Provider<SoundManager>((ref) {
  final manager = SoundManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});
