import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/design/app_colors.dart';

/// Which ground the player asked for.
///
/// Three states rather than two, and [system] is the default: a phone already
/// knows whether it is night, and a game that ignores that has to be told
/// twice.
enum ThemeChoice { system, day, night }

/// The chosen ground, remembered.
///
/// The choice is a preference like the sound and the vibration, and those are
/// already persisted — a setting that forgets is a setting that has to be made
/// every time.
///
/// The notifier does two things at once, and it has to: it holds the choice
/// for the widget tree, and it pushes the resolved ground into [AppColors],
/// which is where the canvases read it from. Flame components and
/// `CustomPainter`s paint outside the tree and cannot see a provider.
class ThemeNotifier extends StateNotifier<ThemeChoice> {
  ThemeNotifier() : super(ThemeChoice.system) {
    _load();
  }

  static const _key = 'theme_choice';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == null) return;
      final choice = ThemeChoice.values.asNameMap()[saved];
      if (choice != null) state = choice;
    } catch (_) {
      // The system ground is a fine place to be if the store is unreachable.
    }
  }

  Future<void> choose(ThemeChoice choice) async {
    state = choice;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, choice.name);
    } catch (_) {
      // The choice still applies to this run; it just will not be remembered.
    }
  }

  /// Which ground [choice] means, given what the phone is currently doing.
  static AppMode resolve(ThemeChoice choice, Brightness platform) =>
      switch (choice) {
        ThemeChoice.day => AppMode.day,
        ThemeChoice.night => AppMode.night,
        ThemeChoice.system =>
          platform == Brightness.light ? AppMode.day : AppMode.night,
      };
}

final themeChoiceProvider =
    StateNotifierProvider<ThemeNotifier, ThemeChoice>((ref) => ThemeNotifier());
