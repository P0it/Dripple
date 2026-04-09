import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  specialJoker, // JOKER card played
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

  // SharedPreferences keys
  static const _keySfxEnabled = 'sound_sfx_enabled';
  static const _keyMusicEnabled = 'sound_music_enabled';
  static const _keySfxVolume = 'sound_sfx_volume';
  static const _keyMusicVolume = 'sound_music_volume';

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;

  /// Load persisted settings from SharedPreferences.
  /// Call this once at app startup before runApp.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sfxEnabled = prefs.getBool(_keySfxEnabled) ?? true;
      _musicEnabled = prefs.getBool(_keyMusicEnabled) ?? true;
      _sfxVolume = prefs.getDouble(_keySfxVolume) ?? 0.8;
      _musicVolume = prefs.getDouble(_keyMusicVolume) ?? 0.5;
    } catch (e) {
      debugPrint('SoundManager.init: failed to load prefs: $e');
    }
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySfxEnabled, _sfxEnabled);
      await prefs.setBool(_keyMusicEnabled, _musicEnabled);
      await prefs.setDouble(_keySfxVolume, _sfxVolume);
      await prefs.setDouble(_keyMusicVolume, _musicVolume);
    } catch (e) {
      debugPrint('SoundManager._savePrefs: $e');
    }
  }

  /// Toggle sound effects on/off
  set sfxEnabled(bool value) {
    _sfxEnabled = value;
    if (!value) stopAllSfx();
    _savePrefs();
  }

  /// Toggle background music on/off
  set musicEnabled(bool value) {
    _musicEnabled = value;
    if (!value) {
      stopMusic();
    } else if (_currentTrack != null) {
      playMusic(_currentTrack!);
    }
    _savePrefs();
  }

  /// Set sound effects volume (0.0 - 1.0)
  set sfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
    _savePrefs();
  }

  /// Set music volume (0.0 - 1.0)
  set musicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
    _bgmPlayer?.setVolume(_musicVolume);
    _savePrefs();
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
    } catch (e) {
      // Log asset errors during development
      debugPrint('SoundManager.play($effect): $e');
    }
  }

  /// Play a sound effect with custom volume (for things like distant sounds).
  /// Reuses the pooled player and restores volume after playback.
  Future<void> playAt(SoundEffect effect, {double volume = 1.0}) async {
    if (!_sfxEnabled) return;

    try {
      final player = _sfxPlayers[effect] ??= AudioPlayer()
        ..setReleaseMode(ReleaseMode.stop);
      _sfxPlayers[effect] = player;

      await player.setVolume((_sfxVolume * volume).clamp(0.0, 1.0));
      await player.play(AssetSource('sounds/${effect.name}.mp3'));
    } catch (e) {
      debugPrint('SoundManager.playAt($effect): $e');
    }
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
    if (!_musicEnabled) {
      _currentTrack = track;
      return;
    }

    try {
      // If same track is already playing, skip
      if (_bgmPlayer != null && _currentTrack == track) {
        final state = _bgmPlayer!.state;
        if (state == PlayerState.playing) return;
      }
      _currentTrack = track;

      await _bgmPlayer?.stop();
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(_musicVolume);
      await _bgmPlayer!.play(AssetSource('music/${track.name}.mp3'));
    } catch (e) {
      debugPrint('SoundManager.playMusic($track): $e');
    }
  }

  /// Crossfade to a different music track (smooth transition).
  /// Cancels any in-progress crossfade before starting a new one.
  int _crossfadeGeneration = 0;

  Future<void> crossfadeTo(MusicTrack track,
      {Duration duration = const Duration(milliseconds: 800)}) async {
    if (!_musicEnabled || _currentTrack == track) return;
    _currentTrack = track;

    // Cancel any in-progress crossfade by incrementing generation
    final generation = ++_crossfadeGeneration;

    try {
      // Stop and dispose any previous crossfade player
      await _bgmCrossfadePlayer?.stop();
      await _bgmCrossfadePlayer?.dispose();

      // Start new track at zero volume
      _bgmCrossfadePlayer = AudioPlayer();
      await _bgmCrossfadePlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmCrossfadePlayer!.setVolume(0);
      await _bgmCrossfadePlayer!.play(AssetSource('music/${track.name}.mp3'));

      // Fade out old, fade in new over duration
      final steps = 10;
      final stepDuration = duration ~/ steps;

      for (int i = 1; i <= steps; i++) {
        // Abort if a newer crossfade has started
        if (_crossfadeGeneration != generation) return;

        await Future.delayed(stepDuration);
        final progress = i / steps;
        await _bgmPlayer?.setVolume(_musicVolume * (1 - progress));
        await _bgmCrossfadePlayer?.setVolume(_musicVolume * progress);
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
  Future<void> onCorrectAnswer() async {
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
      case 'joker':
        await play(SoundEffect.specialJoker);
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
