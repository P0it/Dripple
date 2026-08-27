import 'dart:math';

/// Room codes people read aloud and type on a phone.
///
/// The alphabet drops both halves of every confusable pair — I and 1, O and
/// 0, S and 5 — rather than folding one onto the other. Keeping one of each
/// pair only moves the problem: the code's whole job is to survive being said
/// across a room to a six-year-old, and a character that can never appear can
/// never be misheard.
///
/// 30 characters over 6 places is about 7×10^8 codes, so collisions are rare;
/// the store rejects one outright rather than trusting that.
class RoomCode {
  static const alphabet = 'ABCDEFGHJKLMNPQRTUVWXYZ2346789';
  static const length = 6;

  static String generate(Random random) => String.fromCharCodes([
        for (var i = 0; i < length; i++)
          alphabet.codeUnitAt(random.nextInt(alphabet.length)),
      ]);

  /// What someone typed, as a code to look up. Case and punctuation are the
  /// user's business, not the room's — "abc-def" finds ABCDEF.
  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}
