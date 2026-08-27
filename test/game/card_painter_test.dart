import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dripple/data/card_deck.dart';
import 'package:dripple/game/card_painter.dart';
import 'package:dripple/game/board_layout.dart';
import 'package:dripple/models/word_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      final bytes =
          await rootBundle.load('assets/fonts/Pretendard-$weight.ttf');
      await (FontLoader('Pretendard')..addFont(Future.value(bytes))).load();
    }
  });

  _fitTests();

  test('a seven-card hand stays on one line with a readable sliver', () {
    // The hand no longer wraps — it overlaps — so the constraint moved. What
    // has to hold is that every card still shows enough of itself to be
    // picked out and picked up, and a thumb needs something to land on.
    //
    // Everything printed on the face is flush left — the part-of-speech tick
    // at 9% in, the word under it — so the visible sliver of a covered card
    // is the part that carries its identity. A quarter of the card leaves
    // room for the tick and the first characters of the word, and is also
    // comfortably above the 44pt Apple touch minimum at these widths.
    for (final width in [360.0, 390.0, 430.0]) {
      final step = HandFan.step(width, 7);
      expect(step, greaterThan(BoardLayout.cardWidth * 0.25),
          reason: 'seven cards on a ${width.toInt()}pt screen');

      final slots = HandFan.positions(width, 7, 400);
      expect(slots.first.dx, greaterThanOrEqualTo(0));
      expect(slots.last.dx + BoardLayout.cardWidth,
          lessThanOrEqualTo(width + 0.01));
    }
  });

  /// Painting into a recorder catches the failures that actually happen here:
  /// a null deref, a bad clip, an unbalanced save/restore.
  void paintCard(WordCard card,
      {bool highlighted = false,
      bool warned = false,
      String locale = 'ko'}) {
    final recorder = ui.PictureRecorder();
    CardPainter.paint(
      Canvas(recorder),
      card,
      const Size(CardPainter.defaultWidth, CardPainter.defaultHeight),
      highlighted: highlighted,
      warned: warned,
      locale: locale,
    );
    recorder.endRecording().dispose();
  }

  test('paints a word card in every state', () {
    const card = WordCard(
      id: 'w',
      word: 'cat',
      pos: PartOfSpeech.noun,
      meanings: {'ko': '고양이'},
    );
    expect(() => paintCard(card), returnsNormally);
    expect(() => paintCard(card, highlighted: true), returnsNormally);
    expect(() => paintCard(card, warned: true), returnsNormally);
  });

  test('paints every part of speech', () {
    for (final pos in PartOfSpeech.values) {
      expect(
        () => paintCard(WordCard(id: pos.name, word: pos.name, pos: pos)),
        returnsNormally,
        reason: 'part of speech $pos',
      );
    }
  });

  test('paints every special card', () {
    for (final t in [CardType.jump, CardType.steal, CardType.joker]) {
      expect(
        () => paintCard(WordCard(id: t.name, word: t.name, type: t)),
        returnsNormally,
        reason: 'card type $t',
      );
    }
  });

  test('paints a card with no meaning for the locale', () {
    const card = WordCard(id: 'x', word: 'the', pos: PartOfSpeech.article);
    expect(() => paintCard(card), returnsNormally);
  });

  test('paints a card with no part of speech at all', () {
    const card = WordCard(id: 'z', word: 'hm');
    expect(() => paintCard(card), returnsNormally);
  });

  group('the gloss belongs to the player, not to the deck', () {
    const cat = WordCard(
      id: 'w',
      word: 'cat',
      pos: PartOfSpeech.noun,
      meanings: {'ko': '고양이', 'ja': '猫', 'en': 'cat'},
    );

    test('prints the learner\'s own language', () {
      expect(CardPainter.showsGloss(cat, 'ko'), isTrue);
      expect(CardPainter.showsGloss(cat, 'ja'), isTrue);
    });

    test('prints nothing in English, because there is nothing to teach', () {
      // `meanings['en']` of an English word is that same word. An English
      // player was reading "cat" glossed as "cat" — or, before the locale was
      // wired through at all, reading Korean.
      expect(CardPainter.showsGloss(cat, 'en'), isFalse);
    });

    test('prints nothing for a locale the deck has no entry for', () {
      expect(CardPainter.showsGloss(cat, 'fr'), isFalse);
      const bare = WordCard(id: 'x', word: 'the', pos: PartOfSpeech.article);
      expect(CardPainter.showsGloss(bare, 'ko'), isFalse);
    });

    test('every deck card is silent in English and speaks in Korean', () {
      final deck = CardDeck().generate().where((c) => !c.isSpecial);
      expect(deck, isNotEmpty);
      for (final card in deck) {
        expect(CardPainter.showsGloss(card, 'en'), isFalse,
            reason: '"${card.word}" glosses itself in English');
      }
      expect(deck.where((c) => CardPainter.showsGloss(c, 'ko')), isNotEmpty);
    });

    test('paints in every locale without throwing', () {
      for (final locale in ['ko', 'ja', 'en', 'fr']) {
        expect(() => paintCard(cat, locale: locale), returnsNormally,
            reason: 'locale $locale');
      }
    });
  });

  test('paints a long word without throwing', () {
    const card = WordCard(
      id: 'y',
      word: 'extraordinary',
      pos: PartOfSpeech.adjective,
    );
    expect(() => paintCard(card), returnsNormally);
  });
}

/// Words are the one thing on a card that must never spill over the edge.
///
/// Measured against the real deck with the real font loaded: a curated deck
/// is the actual constraint, and the test binding's fallback face has
/// different metrics, so an unloaded run would prove nothing.
void _fitTests() {
  test('every word in the deck fits inside a card', () {
    // The same numbers the painter uses: the face's side margins are 9.1%
    // each, and the headword is set at 22.7% of the width.
    const cardWidth = CardPainter.defaultWidth;
    const maxWidth = cardWidth * (1 - 0.091 * 2);
    const maxFontSize = cardWidth * 0.227;

    final labels = {
      for (final card in CardDeck().generate())
        card.isSpecial ? card.type.name.toUpperCase() : card.word,
    };
    expect(labels, isNotEmpty);

    for (final label in labels) {
      TextPainter build(double fontSize) => TextPainter(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

      final size = CardPainter.fitFontSize(build, maxWidth, maxFontSize);
      expect(build(size).width, lessThanOrEqualTo(maxWidth),
          reason: '"$label" overflows at ${size}px');
      expect(size, greaterThanOrEqualTo(maxFontSize * 0.5),
          reason: '"$label" shrank to the floor — it will be clipping');
    }
  });
}
