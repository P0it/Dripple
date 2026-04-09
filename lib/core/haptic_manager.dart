import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Haptic feedback intensity levels
enum HapticIntensity {
  light, // Subtle tap — button press, card hover
  medium, // Standard tap — card placed, card drawn
  heavy, // Strong tap — submit, special card
  success, // Double pulse — correct answer, combo
  error, // Short buzz — incorrect answer
  warning, // Quick triple — turn timer running out
}

/// Manages haptic (vibration) feedback for game events.
/// Provides different vibration patterns for different game situations.
class HapticManager {
  bool _enabled = true;
  bool? _hasVibrator;

  static const _keyHapticEnabled = 'haptic_enabled';

  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    _savePrefs();
  }

  /// Load persisted settings from SharedPreferences.
  /// Call this once at app startup before runApp.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_keyHapticEnabled) ?? true;
    } catch (e) {
      debugPrint('HapticManager.init: failed to load prefs: $e');
    }
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHapticEnabled, _enabled);
    } catch (e) {
      debugPrint('HapticManager._savePrefs: $e');
    }
  }

  /// Check if device supports vibration
  Future<bool> get hasVibrator async {
    _hasVibrator ??= (await Vibration.hasVibrator()) == true;
    return _hasVibrator!;
  }

  /// Check if device supports custom vibration patterns
  Future<bool> get hasAmplitudeControl async {
    return (await Vibration.hasAmplitudeControl()) == true;
  }

  /// Trigger haptic feedback at specified intensity
  Future<void> trigger(HapticIntensity intensity) async {
    if (!enabled) return;
    if (!await hasVibrator) return;

    switch (intensity) {
      case HapticIntensity.light:
        await HapticFeedback.lightImpact();

      case HapticIntensity.medium:
        await HapticFeedback.mediumImpact();

      case HapticIntensity.heavy:
        await HapticFeedback.heavyImpact();

      case HapticIntensity.success:
        // Double pulse pattern: buzz-pause-buzz
        if (await hasAmplitudeControl) {
          await Vibration.vibrate(pattern: [0, 40, 80, 40], intensities: [0, 200, 0, 200]);
        } else {
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.mediumImpact();
        }

      case HapticIntensity.error:
        // Short sharp buzz
        if (await hasAmplitudeControl) {
          await Vibration.vibrate(duration: 100, amplitude: 255);
        } else {
          await HapticFeedback.heavyImpact();
        }

      case HapticIntensity.warning:
        // Quick triple pulse for urgency (turn timer)
        if (await hasAmplitudeControl) {
          await Vibration.vibrate(
            pattern: [0, 30, 60, 30, 60, 30],
            intensities: [0, 150, 0, 150, 0, 150],
          );
        } else {
          for (int i = 0; i < 3; i++) {
            await HapticFeedback.lightImpact();
            if (i < 2) await Future.delayed(const Duration(milliseconds: 80));
          }
        }
    }
  }

  // ========== GAME-SPECIFIC HAPTIC HELPERS ==========

  /// Button tap feedback
  Future<void> onButtonTap() async {
    await trigger(HapticIntensity.light);
  }

  /// Card picked up / drag started
  Future<void> onCardPickUp() async {
    await trigger(HapticIntensity.light);
  }

  /// Card placed into sentence zone
  Future<void> onCardPlace() async {
    await trigger(HapticIntensity.medium);
  }

  /// Card drawn from deck
  Future<void> onCardDraw() async {
    await trigger(HapticIntensity.medium);
  }

  /// Sentence submitted
  Future<void> onSubmit() async {
    await trigger(HapticIntensity.heavy);
  }

  /// Correct answer — satisfying double pulse
  Future<void> onCorrectAnswer() async {
    await trigger(HapticIntensity.success);
  }

  /// Combo hit — extra-satisfying feedback
  Future<void> onComboHit(int comboCount) async {
    // Stronger feedback for higher combos
    await trigger(HapticIntensity.success);
    if (comboCount >= 3) {
      await Future.delayed(const Duration(milliseconds: 150));
      await trigger(HapticIntensity.heavy);
    }
  }

  /// Incorrect answer — sharp error feedback
  Future<void> onIncorrectAnswer() async {
    await trigger(HapticIntensity.error);
  }

  /// Special card played — strong impact
  Future<void> onSpecialCard() async {
    await trigger(HapticIntensity.heavy);
  }

  /// Card stolen by opponent — surprise jolt
  Future<void> onCardStolen() async {
    await trigger(HapticIntensity.error);
  }

  /// Turn timer warning (last 5 seconds)
  Future<void> onTimerWarning() async {
    await trigger(HapticIntensity.warning);
  }

  /// Game win — celebration pulse
  Future<void> onGameWin() async {
    if (!enabled) return;
    if (!await hasVibrator) return;

    // Victory celebration: escalating pulses
    if (await hasAmplitudeControl) {
      await Vibration.vibrate(
        pattern: [0, 50, 80, 50, 80, 80, 100, 150],
        intensities: [0, 100, 0, 150, 0, 200, 0, 255],
      );
    } else {
      await trigger(HapticIntensity.success);
      await Future.delayed(const Duration(milliseconds: 200));
      await trigger(HapticIntensity.heavy);
    }
  }

  /// Game lose — somber single buzz
  Future<void> onGameLose() async {
    if (!enabled) return;
    if (!await hasVibrator) return;

    if (await hasAmplitudeControl) {
      await Vibration.vibrate(duration: 200, amplitude: 100);
    } else {
      await trigger(HapticIntensity.medium);
    }
  }

  /// Emote received from opponent
  Future<void> onEmoteReceived() async {
    await trigger(HapticIntensity.light);
  }

  /// Your turn started
  Future<void> onMyTurnStart() async {
    await trigger(HapticIntensity.medium);
  }

  /// Round ended
  Future<void> onRoundEnd() async {
    await trigger(HapticIntensity.heavy);
  }

  /// Online match found
  Future<void> onMatchFound() async {
    await trigger(HapticIntensity.success);
  }
}

/// Global HapticManager provider
final hapticManagerProvider = Provider<HapticManager>((ref) {
  return HapticManager();
});
