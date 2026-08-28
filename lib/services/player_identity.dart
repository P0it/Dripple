import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Who this device plays as.
///
/// There is no sign-in and nothing is collected. A player gets an id the
/// first time they go online and a name they chose themselves, both kept on
/// the device — the audience includes six-year-olds, and the least a
/// children's game can ask for is nothing.
///
/// The cost is that a new phone is a new player. That is the trade, and it is
/// the right way round until there is something worth carrying across.
class PlayerIdentity {
  static const _idKey = 'player_id';
  static const _nameKey = 'player_name';

  /// Longest name a card table can show without the seat labels colliding.
  static const maxNameLength = 12;

  final SharedPreferences _prefs;

  PlayerIdentity(this._prefs);

  static Future<PlayerIdentity> load() async =>
      PlayerIdentity(await SharedPreferences.getInstance());

  /// This device's account id, minted on first use and kept thereafter.
  ///
  /// When Firebase Auth lands this becomes the uid it hands out, and the
  /// server sees an ID token instead of this string. Nothing else changes.
  Future<String> uid() async {
    final existing = _prefs.getString(_idKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final minted = 'p_${List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join()}';
    await _prefs.setString(_idKey, minted);
    return minted;
  }

  /// The name this player chose, or null if they have not been asked yet.
  ///
  /// Nobody is asked until they first tap Online: a player who only ever
  /// plays the bots should never see a text field.
  String? get name {
    final stored = _prefs.getString(_nameKey)?.trim();
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  bool get hasName => name != null;

  Future<void> setName(String value) =>
      _prefs.setString(_nameKey, sanitize(value));

  /// Trim a typed name down to something a seat label can hold.
  ///
  /// Collapsing runs of whitespace matters more than it looks: a name of
  /// spaces reads as an empty chair, and one with a newline in it breaks the
  /// row it sits in.
  static String sanitize(String input) {
    final collapsed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.length <= maxNameLength
        ? collapsed
        : collapsed.substring(0, maxNameLength);
  }

  /// Whether a typed name is worth keeping.
  static bool isValidName(String input) => sanitize(input).isNotEmpty;
}
