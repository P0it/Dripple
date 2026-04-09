import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sound_manager.dart';
import 'haptic_manager.dart';

/// Unified feedback controller that coordinates audio + haptics
/// for all game events. This is the single entry point for all
/// sensory feedback in the game.
///
/// Usage in widgets:
/// ```dart
/// final feedback = ref.read(gameFeedbackProvider);
/// feedback.onCardPlace();
/// ```
class GameFeedback {
  final SoundManager sound;
  final HapticManager haptic;

  GameFeedback({required this.sound, required this.haptic});

  // ========== UI FEEDBACK ==========

  /// Generic button tap
  Future<void> onButtonTap() async {
    await Future.wait([
      sound.play(SoundEffect.buttonTap),
      haptic.onButtonTap(),
    ]);
  }

  // ========== CARD INTERACTIONS ==========

  /// Card picked up (drag started)
  Future<void> onCardPickUp() async {
    await haptic.onCardPickUp();
  }

  /// Card placed into sentence zone
  Future<void> onCardPlace() async {
    await Future.wait([
      sound.play(SoundEffect.cardPlace),
      haptic.onCardPlace(),
    ]);
  }

  /// Card drawn from deck
  Future<void> onCardDraw() async {
    await Future.wait([
      sound.play(SoundEffect.cardDraw),
      haptic.onCardDraw(),
    ]);
  }

  /// Card flipped/revealed
  Future<void> onCardFlip() async {
    await sound.play(SoundEffect.cardFlip);
  }

  // ========== TURN EVENTS ==========

  /// Human player's turn starts
  Future<void> onMyTurnStart() async {
    await Future.wait([
      sound.onMyTurnStart(),
      haptic.onMyTurnStart(),
    ]);
  }

  /// Human player's turn ends
  Future<void> onMyTurnEnd() async {
    await sound.onMyTurnEnd();
  }

  /// Turn timer warning (last 5 seconds)
  Future<void> onTimerWarning() async {
    await Future.wait([
      sound.play(SoundEffect.turnTick),
      haptic.onTimerWarning(),
    ]);
  }

  // ========== SUBMISSION ==========

  /// Sentence submitted for validation
  Future<void> onSubmit() async {
    await Future.wait([
      sound.play(SoundEffect.submit),
      haptic.onSubmit(),
    ]);
  }

  /// Correct sentence
  Future<void> onCorrectAnswer() async {
    await Future.wait([
      sound.onCorrectAnswer(),
      haptic.onCorrectAnswer(),
    ]);
  }

  /// Incorrect sentence
  Future<void> onIncorrectAnswer() async {
    await Future.wait([
      sound.onIncorrectAnswer(),
      haptic.onIncorrectAnswer(),
    ]);
  }

  // ========== SPECIAL CARDS ==========

  /// Special card played
  Future<void> onSpecialCard(String cardType) async {
    await Future.wait([
      sound.onSpecialCard(cardType),
      haptic.onSpecialCard(),
    ]);
  }

  /// Your card was stolen by opponent
  Future<void> onCardStolen() async {
    await Future.wait([
      sound.play(SoundEffect.specialSteal),
      haptic.onCardStolen(),
    ]);
  }

  // ========== EMOTES ==========

  /// Emote sent by player
  Future<void> onEmoteSent() async {
    await sound.play(SoundEffect.emote);
  }

  /// Emote received from opponent
  Future<void> onEmoteReceived() async {
    await Future.wait([
      sound.play(SoundEffect.emote),
      haptic.onEmoteReceived(),
    ]);
  }

  // ========== ROUND / GAME EVENTS ==========

  /// New round starts
  Future<void> onRoundStart() async {
    await sound.play(SoundEffect.roundStart);
  }

  /// Round ends
  Future<void> onRoundEnd() async {
    await Future.wait([
      sound.play(SoundEffect.roundEnd),
      haptic.onRoundEnd(),
    ]);
  }

  /// Tense moment (final round / close scores)
  Future<void> onTenseMoment() async {
    await sound.onTenseMoment();
  }

  /// Game ends — player wins
  Future<void> onGameWin() async {
    await Future.wait([
      sound.onGameEnd(isWinner: true),
      haptic.onGameWin(),
    ]);
  }

  /// Game ends — player loses
  Future<void> onGameLose() async {
    await Future.wait([
      sound.onGameEnd(isWinner: false),
      haptic.onGameLose(),
    ]);
  }

  // ========== ONLINE MULTIPLAYER ==========

  /// Countdown before game starts (3-2-1)
  Future<void> onCountdown() async {
    await Future.wait([
      sound.play(SoundEffect.countdown),
      haptic.onButtonTap(),
    ]);
  }

  /// Match found in online queue
  Future<void> onMatchFound() async {
    await Future.wait([
      sound.play(SoundEffect.matchFound),
      haptic.onMatchFound(),
    ]);
  }

  // ========== SCREEN MUSIC ==========

  /// Play menu/home screen BGM
  Future<void> playMenuMusic() async {
    await sound.playMusic(MusicTrack.menuTheme);
  }

  /// Play gameplay BGM
  Future<void> playGameMusic() async {
    await sound.playMusic(MusicTrack.gamePlay);
  }

  /// Stop all music
  Future<void> stopMusic() async {
    await sound.stopMusic();
  }

  /// Pause music (app goes to background)
  Future<void> pauseMusic() async {
    await sound.pauseMusic();
  }

  /// Resume music (app comes to foreground)
  Future<void> resumeMusic() async {
    await sound.resumeMusic();
  }
}

/// Global GameFeedback provider — single source for all sensory feedback
final gameFeedbackProvider = Provider<GameFeedback>((ref) {
  return GameFeedback(
    sound: ref.read(soundManagerProvider),
    haptic: ref.read(hapticManagerProvider),
  );
});
