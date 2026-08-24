import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart' as material;
import '../core/design/app_colors.dart';
import '../core/design/materials.dart';
import '../models/word_card.dart';
import 'card_painter.dart';
import 'card_row_layout.dart';
import 'components/card_component.dart';
import 'components/pile_component.dart';

typedef OnCardPlaced = void Function(int handIndex, int insertAt);
typedef OnSentenceReorder = void Function(int from, int to);
typedef OnSentenceRemove = void Function(int index);
typedef OnHandCardTapped = void Function(int handIndex);
typedef OnDiscardCard = void Function(int handIndex);

/// The words printed on the two bands of the board.
///
/// Localised strings live in the widget tree and Flame's canvas has no
/// `BuildContext`, so the screen hands them down. The defaults keep the
/// board readable in tests and previews.
class ZoneLabels {
  const ZoneLabels({
    this.sentence = '문장 만드는 곳',
    this.hand = '내 카드',
    this.hint = '여기에 카드를 올려\n문장을 만들어요',
  });

  final String sentence;
  final String hand;
  final String hint;
}

class DrippleGame extends FlameGame {
  List<WordCard> _hand = [];
  List<WordCard> _sentenceZone = [];
  final List<CardComponent> _handComponents = [];
  final List<CardComponent> _sentenceComponents = [];

  OnCardPlaced? onCardPlaced;
  OnSentenceReorder? onSentenceReorder;
  OnSentenceRemove? onSentenceRemove;
  OnHandCardTapped? onHandCardTapped;

  /// The deck was tapped.
  void Function()? onDrawFromDeck;

  /// The discard pile was tapped.
  void Function()? onDrawFromDiscard;

  /// A hand card was dragged onto the discard pile.
  OnDiscardCard? onDiscardCard;

  PileComponent? _deck;
  PileComponent? _discard;

  /// Piles are drawn smaller than a hand card. They sit in the strip above
  /// the sentence band, which is the only space the board has, and a pile is
  /// a place rather than something you read.
  static const double _pileScale = 0.62;

  /// Piles sit clear above the sentence band. The band is the card block
  /// plus [_bandInset] on each side, so half of *that* is what has to be
  /// cleared — halving the card height alone leaves the piles overlapping
  /// the band by the inset.
  double get _pileY =>
      _sentenceZoneY -
      (CardRowLayout.cardHeight + _bandInset * 2) / 2 -
      CardPainter.defaultHeight * _pileScale -
      8;

  /// When true the hand is a discard picker: cards are marked and a tap
  /// throws the card away instead of playing it.
  bool _discardMode = false;

  set discardMode(bool value) {
    if (_discardMode == value) return;
    _discardMode = value;
    for (final comp in _handComponents) {
      comp.markedForDiscard = value;
    }
  }

  bool get discardMode => _discardMode;

  @material.visibleForTesting
  List<WordCard> get debugSentenceZone => List.unmodifiable(_sentenceZone);

  @material.visibleForTesting
  List<CardComponent> get debugSentenceComponents =>
      List.unmodifiable(_sentenceComponents);

  @material.visibleForTesting
  List<CardComponent> get debugHandComponents =>
      List.unmodifiable(_handComponents);

  double get _sentenceZoneY => size.y * 0.30;
  double get _handY => size.y * 0.74;

  /// Transparent: [FeltScaffold] paints the table under the whole screen, and
  /// two radials meeting at the widget's edge would show a seam. The board
  /// draws only what is *on* the table.
  @override
  ui.Color backgroundColor() => const ui.Color(0x00000000);

  /// The board is a table, not two bands on a page.
  ///
  /// The sentence zone is a recess cut into the felt and the hand is a raised
  /// rail — the same distinction a real table makes, and a stronger read than
  /// the blue-tint-versus-white-tray it replaces. You put cards *into* a hole
  /// and take them *from* a ledge, and the shading says so before any label
  /// does. Give both the same treatment and the distinction is gone again.
  @override
  void render(ui.Canvas canvas) {
    _renderSentenceWell(canvas);
    _renderHandRail(canvas);
    super.render(canvas);
  }

  /// Padding between a band's edge and the cards inside it.
  static const double _bandInset = 10;

  ui.RRect _band(double centerY, int cardCount, {double minHeight = 0}) {
    final content = math.max(
      CardRowLayout.blockHeight(size.x, cardCount),
      minHeight,
    );
    return ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
        center: ui.Offset(size.x / 2, centerY),
        width: size.x - CardRowLayout.edgePadding * 2,
        height: content + _bandInset * 2,
      ),
      const ui.Radius.circular(18),
    );
  }

  void _renderSentenceWell(ui.Canvas canvas) {
    final band = _band(
      _sentenceZoneY,
      _sentenceZone.length,
      minHeight: CardRowLayout.cardHeight,
    );

    Materials.recess(canvas, band, AppColors.well);
    // Dashed while empty, so it asks for a card; a solid hairline once it has
    // one, so it stops asking and just frames what is there.
    Materials.hairline(
      canvas,
      band.deflate(1),
      color: AppColors.brass,
      width: _sentenceZone.isEmpty ? 1.5 : 1,
      dashed: _sentenceZone.isEmpty,
      opacity: _sentenceZone.isEmpty ? 0.7 : 0.4,
    );
    _drawBandLabel(canvas, _sentenceLabel, band);

    // The hint would sit under the cards once there are any; it is only there
    // to explain an empty target.
    if (_sentenceZone.isEmpty) {
      _dropHint.paint(
        canvas,
        ui.Offset(
          band.center.dx - _dropHint.width / 2,
          band.center.dy - _dropHint.height / 2,
        ),
      );
    }
  }

  void _renderHandRail(ui.Canvas canvas) {
    if (_hand.isEmpty) return;
    final band = _band(_handY, _hand.length);

    Materials.raised(canvas, band, AppColors.rail);
    Materials.hairline(
      canvas,
      band.deflate(1),
      color: AppColors.brass,
      opacity: 0.35,
    );
    _drawBandLabel(canvas, _handLabel, band);
  }

  /// Labels ride just above their band, or just below it when the band sits
  /// close enough to the top edge that there is no room.
  void _drawBandLabel(
    ui.Canvas canvas,
    material.TextPainter painter,
    ui.RRect band,
  ) {
    const gap = 6.0;
    final above = band.top - gap - painter.height;
    painter.paint(
      canvas,
      ui.Offset(band.left + 4, above >= 0 ? above : band.bottom + gap),
    );
  }

  ZoneLabels _labels = const ZoneLabels();

  set labels(ZoneLabels value) {
    _labels = value;
    _sentenceLabelPainter = null;
    _handLabelPainter = null;
    _dropHintPainter = null;
  }

  static const _labelStyle = material.TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: material.FontWeight.w700,
    letterSpacing: 1.2,
  );

  material.TextPainter? _sentenceLabelPainter;
  material.TextPainter? _handLabelPainter;
  material.TextPainter? _dropHintPainter;

  material.TextPainter get _sentenceLabel => _sentenceLabelPainter ??= _text(
        _labels.sentence,
        _labelStyle.copyWith(color: AppColors.brass),
      );

  material.TextPainter get _handLabel => _handLabelPainter ??= _text(
        _labels.hand,
        _labelStyle.copyWith(color: AppColors.onFeltSoft),
      );

  material.TextPainter get _dropHint => _dropHintPainter ??= _text(
        _labels.hint,
        const material.TextStyle(
          fontFamily: 'Pretendard',
          color: AppColors.onFeltSoft,
          fontSize: 15,
          fontWeight: material.FontWeight.w600,
          height: 1.4,
        ),
      );

  static material.TextPainter _text(String value, material.TextStyle style) =>
      material.TextPainter(
        text: material.TextSpan(text: value, style: style),
        textDirection: ui.TextDirection.ltr,
        textAlign: ui.TextAlign.center,
      )..layout();

  /// Update hand cards using diff — only add/remove changed cards
  void updateHand(List<WordCard> hand) {
    if (_listsEqual(_hand, hand)) return; // Skip if no change
    _hand = hand;
    _diffUpdateComponents(
      newCards: hand,
      existingComponents: _handComponents,
      yPosition: _handY,
      isSentenceZone: false,
    );
  }

  /// Update sentence zone using diff
  void updateSentenceZone(List<WordCard> sentenceZone) {
    if (_listsEqual(_sentenceZone, sentenceZone)) return;
    _sentenceZone = sentenceZone;
    _diffUpdateComponents(
      newCards: sentenceZone,
      existingComponents: _sentenceComponents,
      yPosition: _sentenceZoneY,
      isSentenceZone: true,
    );
  }

  /// Diff-based component update: only remove/add what changed
  void _diffUpdateComponents({
    required List<WordCard> newCards,
    required List<CardComponent> existingComponents,
    required double yPosition,
    required bool isSentenceZone,
  }) {
    final newIds = newCards.map((c) => c.id).toSet();

    // Remove components no longer in the list
    existingComponents.removeWhere((comp) {
      if (!newIds.contains(comp.card.id)) {
        comp.removeFromParent();
        return true;
      }
      return false;
    });

    // Build a lookup for existing components
    final existingMap = {
      for (final c in existingComponents) c.card.id: c
    };

    // Add new components and reposition all
    final slots = CardRowLayout.positions(size.x, newCards.length, yPosition);

    final updatedComponents = <CardComponent>[];

    for (int i = 0; i < newCards.length; i++) {
      final card = newCards[i];
      final slot = slots[i];
      final targetPos = Vector2(slot.dx, slot.dy);

      if (existingMap.containsKey(card.id)) {
        // Existing card — glide to its new slot. Assigning `position`
        // directly would lose a race with any effect still running on the
        // component, so every move goes through the one settle path.
        final comp = existingMap[card.id]!;
        if (!comp.isDragging) comp.settleTo(targetPos);
        comp.priority = i;
        comp.markedForDiscard = !isSentenceZone && _discardMode;
        updatedComponents.add(comp);
      } else {
        // New card — create component. Resolve the index by card id at drag
        // time so a reorder cannot leave a stale index behind.
        final cardId = card.id;
        final comp = CardComponent(
          card: card,
          position: targetPos,
          onTapped: (component) {
            if (isSentenceZone) {
              final idx = _sentenceZone.indexWhere((c) => c.id == cardId);
              if (idx >= 0) onSentenceRemove?.call(idx);
              return;
            }
            final idx = _hand.indexWhere((c) => c.id == cardId);
            if (idx >= 0) onHandCardTapped?.call(idx);
          },
          onDragEnded: (component, dropPosition) {
            if (isSentenceZone) {
              final from = _sentenceZone.indexWhere((c) => c.id == cardId);
              if (from < 0) return false;
              // Dragged clear of the zone — send it back to hand.
              final zoneReach =
                  CardRowLayout.blockHeight(size.x, _sentenceZone.length) / 2 +
                      CardComponent.cardHeight * 0.6;
              if ((dropPosition.y - _sentenceZoneY).abs() > zoneReach) {
                onSentenceRemove?.call(from);
                return true;
              }
              final to = CardRowLayout.indexAt(
                ui.Offset(dropPosition.x, dropPosition.y),
                size.x,
                _sentenceZone.length,
                _sentenceZoneY,
              );
              if (to == from) return false;
              onSentenceReorder?.call(from, to);
              return true;
            }
            // Dropped on the discard pile — that is how a card is thrown
            // away. Checked before the sentence test because the pile sits
            // above the sentence band and would otherwise read as a play.
            final discard = _discard;
            if (discard != null &&
                discard.containsBoardPoint(_centreOf(component))) {
              discard.isDropTarget = false;
              final idx = _hand.indexWhere((c) => c.id == cardId);
              if (idx >= 0) {
                onDiscardCard?.call(idx);
                return true;
              }
            }

            // Hand card lifted toward the sentence zone. Where it landed
            // decides where in the sentence it goes — a child who drops a
            // card in front of `cats` means it to read before `cats`.
            final handReach =
                CardRowLayout.blockHeight(size.x, _hand.length) / 2;
            if (dropPosition.y < _handY - handReach) {
              final idx = _hand.indexWhere((c) => c.id == cardId);
              if (idx >= 0) {
                onCardPlaced?.call(
                  idx,
                  CardRowLayout.insertionIndexAt(
                    ui.Offset(dropPosition.x, dropPosition.y),
                    size.x,
                    _sentenceZone.length,
                    _sentenceZoneY,
                  ),
                );
                return true;
              }
            }
            return false;
          },
        );
        comp.priority = i;
        comp.markedForDiscard = !isSentenceZone && _discardMode;
        updatedComponents.add(comp);
        add(comp);
      }
    }

    existingComponents
      ..clear()
      ..addAll(updatedComponents);
  }

  bool _listsEqual(List<WordCard> a, List<WordCard> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  /// Tells the board how deep the deck is and what is face up on the discard
  /// pile. Both are drawn on the board rather than described in buttons.
  void updatePiles({required int deckCount, WordCard? discardTop}) {
    _ensurePiles();
    _deck!.count = deckCount;
    _discard!.topCard = discardTop;
  }

  void _ensurePiles() {
    if (_deck != null) return;
    _deck = PileComponent(
      kind: PileKind.deck,
      scale: _pileScale,
      onTapped: (_) => onDrawFromDeck?.call(),
    );
    _discard = PileComponent(
      kind: PileKind.discard,
      scale: _pileScale,
      onTapped: (_) {
        if (_discard!.isEmpty) return;
        onDrawFromDiscard?.call();
      },
    );
    _layoutPiles();
    addAll([_deck!, _discard!]);
  }

  void _layoutPiles() {
    final deck = _deck;
    final discard = _discard;
    if (deck == null || discard == null) return;

    const gap = 18.0;
    final w = deck.size.x;
    final centreX = size.x / 2;
    deck.position = Vector2(centreX - gap / 2 - w, _pileY);
    discard.position = Vector2(centreX + gap / 2, _pileY);
  }

  /// Lights the discard pile while a hand card hovers over it, so the drop
  /// target is visible before the finger lifts.
  @override
  void update(double dt) {
    super.update(dt);
    final discard = _discard;
    if (discard == null) return;

    CardComponent? dragging;
    for (final comp in _handComponents) {
      if (comp.isDragging) {
        dragging = comp;
        break;
      }
    }

    final over = dragging != null &&
        discard.containsBoardPoint(_centreOf(dragging));
    if (discard.isDropTarget != over) discard.isDropTarget = over;
  }

  Vector2 _centreOf(CardComponent card) => Vector2(
        card.position.x + card.size.x / 2,
        card.position.y + card.size.y / 2,
      );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutPiles();
    if (_hand.isNotEmpty) {
      _diffUpdateComponents(
        newCards: _hand,
        existingComponents: _handComponents,
        yPosition: _handY,
        isSentenceZone: false,
      );
    }
    if (_sentenceZone.isNotEmpty) {
      _diffUpdateComponents(
        newCards: _sentenceZone,
        existingComponents: _sentenceComponents,
        yPosition: _sentenceZoneY,
        isSentenceZone: true,
      );
    }
  }
}
