import '../../models/word_card.dart';

/// Recursive-descent parser for the sentence grammar.
///
///   S     := NP VP
///   NP    := Pronoun | (Art)? (Adj)* Noun
///   AdjP  := (Adv)* Adj+
///   PP    := Prep NP
///   VP    := Verb (NP | AdjP)? (Adv)? (PP)*
///
/// Every `_parseX` returns the set of positions the parse could end at,
/// which is how optional and repeated elements are explored without
/// committing to a single path. JOKER cards match any part of speech.
class SentenceParser {
  /// True if [cards] form a complete, fully-consumed sentence.
  bool parse(List<WordCard> cards) {
    if (cards.length < 2) return false;

    for (final npEnd in _parseNP(cards, 0)) {
      for (final vpEnd in _parseVP(cards, npEnd)) {
        if (vpEnd == cards.length) return true;
      }
    }
    return false;
  }

  bool _is(List<WordCard> c, int i, PartOfSpeech pos) {
    if (i < 0 || i >= c.length) return false;
    if (c[i].type == CardType.joker) return true;
    return c[i].pos == pos;
  }

  /// NP := Pronoun | (Art)? (Adj)* Noun
  ///
  /// In object position ([object] true) subject-only pronouns are rejected,
  /// so "cats like I" does not parse.
  List<int> _parseNP(List<WordCard> c, int i, {bool object = false}) {
    final out = <int>{};

    if (_is(c, i, PartOfSpeech.pronoun) && (!object || c[i].canBeObject)) {
      out.add(i + 1);
    }

    // Two branches: with a leading article, and without one.
    final hasArticle = _is(c, i, PartOfSpeech.article);
    final starts = <int, bool>{i: false};
    if (hasArticle) starts[i + 1] = true;

    for (final entry in starts.entries) {
      var k = entry.key;
      final articleSeen = entry.value;
      while (true) {
        if (_is(c, k, PartOfSpeech.noun) &&
            (articleSeen || !_needsDeterminer(c, k))) {
          out.add(k + 1);
        }
        if (_is(c, k, PartOfSpeech.adjective)) {
          k++;
        } else {
          break;
        }
      }
    }
    return out.toList();
  }

  /// A singular countable noun cannot stand bare in English — "tree wants"
  /// is wrong, "the tree wants" is right. Plurals ("cats run") and
  /// uncountables ("water is cold") are fine without one.
  ///
  /// JOKER cards carry no grammar metadata, so they are never forced.
  bool _needsDeterminer(List<WordCard> c, int i) {
    final card = c[i];
    if (card.type == CardType.joker) return false;
    return card.isSingular && card.countable == true;
  }

  /// AdjP := (Adv)* Adj+
  List<int> _parseAdjP(List<WordCard> c, int i) {
    final out = <int>{};

    final starts = <int>{i};
    var k = i;
    while (_is(c, k, PartOfSpeech.adverb)) {
      k++;
      starts.add(k);
    }

    for (final s in starts) {
      var j = s;
      while (_is(c, j, PartOfSpeech.adjective)) {
        j++;
        out.add(j);
      }
    }
    return out.toList();
  }

  /// PP := Prep NP
  List<int> _parsePP(List<WordCard> c, int i) {
    if (!_is(c, i, PartOfSpeech.preposition)) return const [];
    return _parseNP(c, i + 1, object: true);
  }

  /// VP := Verb (NP | AdjP)? (Adv)? (PP)*
  List<int> _parseVP(List<WordCard> c, int i) {
    if (!_is(c, i, PartOfSpeech.verb)) return const [];

    // Verb consumed.
    final afterVerb = <int>{i + 1};

    // The verb's own valency decides which complements are legal, so
    // "apples run a friend" and "they read small" both fail while
    // "I read books" and "I am happy" pass.
    final verb = c[i];
    final joker = verb.type == CardType.joker;
    final allowsBare = joker || verb.allowsFrame(VerbFrame.intransitive);
    final allowsObject = joker || verb.allowsFrame(VerbFrame.transitive);
    final allowsAdjective = joker || verb.allowsFrame(VerbFrame.linking);

    final afterComplement = <int>{};
    if (allowsBare) afterComplement.addAll(afterVerb);
    for (final e in afterVerb) {
      if (allowsObject) {
        afterComplement.addAll(_parseNP(c, e, object: true));
      }
      if (allowsAdjective) {
        afterComplement.addAll(_parseAdjP(c, e));
      }
    }

    // Optional trailing adverb.
    final afterAdverb = <int>{...afterComplement};
    for (final e in afterComplement) {
      if (_is(c, e, PartOfSpeech.adverb)) afterAdverb.add(e + 1);
    }

    // Zero or more prepositional phrases. Positions strictly increase,
    // so the worklist always terminates.
    final result = <int>{...afterAdverb};
    final queue = <int>[...afterAdverb];
    while (queue.isNotEmpty) {
      final e = queue.removeLast();
      for (final p in _parsePP(c, e)) {
        if (result.add(p)) queue.add(p);
      }
    }

    return result.toList();
  }
}
