/// Valid sentence structure templates.
/// Patterns use: S=Subject, V=Verb, O=Object, Art=Article, Adj=Adjective, Adv=Adverb
class SentenceTemplates {
  /// All valid sentence patterns
  static const List<List<String>> validPatterns = [
    // SV: "I run", "they run"
    ['S', 'V'],
    // SVO: "I like cats"
    ['S', 'V', 'O'],
    // SVC: "I am happy" (S + linking verb + adjective)
    ['S', 'V', 'Adj'],
    // S V Adv: "I run fast"
    ['S', 'V', 'Adv'],
    // Art S V: "the cat runs"
    ['Art', 'S', 'V'],
    // Art Adj S V: "the big cat runs"
    ['Art', 'Adj', 'S', 'V'],
    // S V Art O: "I like the cat"
    ['S', 'V', 'Art', 'O'],
    // S V Art Adj O: "I like the big cat"
    ['S', 'V', 'Art', 'Adj', 'O'],
    // Art S V O: "the cat likes dogs"
    ['Art', 'S', 'V', 'O'],
    // Art S V Art O: "the cat likes the dog"
    ['Art', 'S', 'V', 'Art', 'O'],
    // Art Adj S V O: "the big cat likes dogs"
    ['Art', 'Adj', 'S', 'V', 'O'],
    // Art Adj S V Art O: "the big cat likes the dog"
    ['Art', 'Adj', 'S', 'V', 'Art', 'O'],
    // Art Adj S V Art Adj O: "the big cat likes the small dog"
    ['Art', 'Adj', 'S', 'V', 'Art', 'Adj', 'O'],
    // S V Adj O: "I like big cats" — not standard but common
    ['S', 'V', 'Adj', 'O'],
    // SVC with article: "the cat is happy"
    ['Art', 'S', 'V', 'Adj'],
    // Art Adj S V Adj: "the big cat is happy"
    ['Art', 'Adj', 'S', 'V', 'Adj'],
    // S V Adv Adj: "I am very happy"
    ['S', 'V', 'Adv', 'Adj'],
    // Art S V Adv Adj: "the cat is very happy"
    ['Art', 'S', 'V', 'Adv', 'Adj'],
    // Multiple adjectives
    ['Art', 'Adj', 'Adj', 'S', 'V'],
    ['Art', 'Adj', 'Adj', 'S', 'V', 'O'],
    ['S', 'V', 'Art', 'Adj', 'Adj', 'O'],
  ];

  /// Check if a pattern matches any valid template
  static bool isValidPattern(List<String> pattern) {
    for (final template in validPatterns) {
      if (_matches(pattern, template)) return true;
    }
    return false;
  }

  static bool _matches(List<String> pattern, List<String> template) {
    if (pattern.length != template.length) return false;
    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i] != template[i]) return false;
    }
    return true;
  }
}
