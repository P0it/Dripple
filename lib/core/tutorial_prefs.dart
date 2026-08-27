import 'package:shared_preferences/shared_preferences.dart';

/// Whether the lesson has been played.
///
/// Only used to decide whether the front door offers it. The lesson stays
/// available from the mode list forever — a child who wants to be shown again
/// should not have to have forgotten first.
abstract final class TutorialPrefs {
  static const _key = 'tutorial_completed';

  /// Falls back to "not yet played" if the store cannot be reached. Offering
  /// the lesson one time too many is a smaller failure than a front door that
  /// throws.
  static Future<bool> isCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Nothing to do: the lesson still played, it just will not be
      // remembered.
    }
  }
}
