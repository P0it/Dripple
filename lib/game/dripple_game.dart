import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart' as material;
import '../core/design/app_colors.dart';
import '../core/design/materials.dart';
import '../models/word_card.dart';
import 'board_layout.dart';
import 'components/card_component.dart';
import 'components/sweep_component.dart';
import 'components/pile_component.dart';

typedef OnCardPlaced = void Function(int handIndex, int insertAt);
typedef OnSentenceReorder = void Function(int from, int to);
typedef OnSentenceRemove = void Function(int index);
typedef OnHandCardTapped = void Function(int handIndex);
typedef OnDiscardCard = void Function(int handIndex);

/// The words printed on the board.
///
/// Localised strings live in the widget tree and Flame's canvas has no
/// `BuildContext`, so the screen hands them down. The defaults keep the
/// board readable in tests and previews.
///
/// There is no label for the sentence any more. A label names a container, and
/// the sentence stopped being one — it is just the cards you have pushed
/// forward. What is left is the rail's name and, while nothing is pushed
/// forward yet, one line of felt text saying how.
class ZoneLabels {
  const ZoneLabels({
    this.hand = '내 카드',
    this.hint = '카드를 위로 밀어\n문장을 만들어요',
    this.deck = '덱',
    this.discard = '버림',
  });

  final String hand;
  final String hint;

  /// The two piles carry their names on the felt. A pile with no name is a
  /// rectangle of card backs; a named one is a place you can be told to put a
  /// card, which is the whole of how a card is thrown away here.
  final String deck;
  final String discard;
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

  /// Piles are drawn at full card size, because that is what they are made
  /// of. They used to be shrunk to 62% to squeeze into the strip above the
  /// sentence band; that band is gone, and a deck that is smaller than the
  /// cards it deals reads as a button with a picture of a deck on it.
  static const double _pileScale = 1.0;

  /// Piles sit at the top of the table, clear of everything. They are the
  /// only fixed furniture on the board, so they do not move when the hand
  /// does.
  double get _pileY => size.y * 0.05;

  /// The card a thumb is currently resting on in the fan.
  CardComponent? _peeked;

  /// A finger running along the fan. The card under it comes up out of the
  /// hand, which is how an overlapping hand is read.
  void _onScrub(CardComponent origin, double boardX) {
    final index =
        HandFan.indexUnder(boardX, size.x, _handComponents.length, _handY);
    final comp = index < 0 ? null : _handComponents[index];
    if (identical(comp, _peeked)) return;
    _peeked?.peeking = false;
    _peeked = comp;
    comp?.peeking = true;
  }

  void _endScrub() {
    _peeked?.peeking = false;
    _peeked = null;
  }

  /// The card the thumb settled on, which is the one the player means to
  /// play — not whichever card the press happened to land on first.
  CardComponent? _resolveLift(CardComponent origin) {
    final chosen = _peeked;
    _peeked = null;
    return chosen;
  }

  /// Where each card was standing when its component was last torn down.
  ///
  /// A card that moves between the hand and the sentence zone is a *removal*
  /// in one list and an *addition* in the other, so without this the new
  /// component has no idea the card was already on the board and flies in from
  /// the deck. Entries live exactly one frame — both list updates happen
  /// inside a single widget build, and anything not claimed by the next tick
  /// belongs to a card that left the board.
  final Map<String, Vector2> _lastSeen = {};

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

  /// Centre of the deck in board coordinates, or null before the piles exist.
  @material.visibleForTesting
  Vector2? get debugDeckCentre {
    final deck = _deck;
    if (deck == null) return null;
    return Vector2(
      deck.position.x + deck.size.x / 2,
      deck.position.y + deck.size.y / 2,
    );
  }

  /// The discard pile itself, so a test can see the states it lights up in.
  @material.visibleForTesting
  PileComponent? get debugDiscardPile => _discard;

  /// Centre of the discard pile in board coordinates, or null before the
  /// piles exist.
  @material.visibleForTesting
  Vector2? get debugDiscardCentre {
    final discard = _discard;
    if (discard == null) return null;
    return Vector2(
      discard.position.x + discard.size.x / 2,
      discard.position.y + discard.size.y / 2,
    );
  }

  @material.visibleForTesting
  List<CardComponent> get debugHandComponents =>
      List.unmodifiable(_handComponents);

  /// The two rows' anchors, so a test can ask the board where things go
  /// instead of restating the fractions and drifting out of step with them.
  @material.visibleForTesting
  double get debugSentenceY => _sentenceZoneY;

  @material.visibleForTesting
  double get debugHandY => _handY;

  /// Where a pushed-forward card sits, and where the fan rests.
  ///
  /// Far enough apart that a card clears the fan completely — that gap is the
  /// whole signal that the card is in play — and close enough that the two
  /// still read as one hand rather than as two places.
  double get _sentenceZoneY => size.y * 0.45;
  double get _handY => size.y * 0.80;

  /// A hand card dropped above this line is being played; a played card
  /// dropped below it is being taken back. One line, both directions, so the
  /// gesture never depends on hitting a box.
  double get _midlineY => (_sentenceZoneY + _handY) / 2;

  /// Transparent: [FeltScaffold] paints the table under the whole screen, and
  /// two radials meeting at the widget's edge would show a seam. The board
  /// draws only what is *on* the table.
  @override
  ui.Color backgroundColor() => const ui.Color(0x00000000);

  /// The board is a table, and there is one hand on it.
  ///
  /// The sentence used to sit in a recess with a dashed border and a
  /// placeholder, which is the anatomy of a form field: it read as *the place
  /// you submit to* rather than as the cards you are playing. There is no
  /// container now. Cards pushed forward simply lie on the felt, clear of the
  /// fan, and the gap between them and the rail is the only thing saying they
  /// are in play — which is exactly what the gap says at a real table.
  @override
  void render(ui.Canvas canvas) {
    _renderHandRail(canvas);
    if (_sentenceZone.isEmpty && _hand.isNotEmpty) _renderHint(canvas);
    super.render(canvas);
  }

  /// Padding between the rail's edge and the cards on it.
  static const double _bandInset = 10;

  void _renderHandRail(ui.Canvas canvas) {
    if (_hand.isEmpty) return;

    // The rail is measured from the fan rather than from the screen: a leaning
    // card's corner swings outside its own box, and a rail sized to the screen
    // leaves the ends of the fan hanging off the ledge.
    final slots = HandFan.positions(size.x, _hand.length, _handY);
    final margin = HandFan.leanMargin + _bandInset;
    final band = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTRB(
        math.max(BoardLayout.edgePadding, slots.first.dx - margin),
        _handY - BoardLayout.cardHeight / 2 - _bandInset,
        math.min(size.x - BoardLayout.edgePadding,
            slots.last.dx + BoardLayout.cardWidth + margin),
        _handY + BoardLayout.cardHeight / 2 + HandFan.arcRise + _bandInset,
      ),
      const ui.Radius.circular(18),
    );

    Materials.raised(canvas, band, AppColors.rail);
    Materials.hairline(
      canvas,
      band.deflate(1),
      color: AppColors.brass,
      opacity: 0.35,
    );
    _drawRailLabel(canvas, _handLabel, band);
  }

  /// One line of felt text where the sentence will be. No box, no dashes, no
  /// arrow — it explains the gesture and then gets out of the way the moment
  /// the first card is pushed forward.
  void _renderHint(ui.Canvas canvas) {
    _dropHint.paint(
      canvas,
      ui.Offset(
        size.x / 2 - _dropHint.width / 2,
        _sentenceZoneY - _dropHint.height / 2,
      ),
    );
  }

  /// The rail's name rides just above it, or just below when the rail sits
  /// close enough to the top edge that there is no room.
  void _drawRailLabel(
    ui.Canvas canvas,
    material.TextPainter painter,
    ui.RRect band,
  ) {
    const gap = 6.0;
    final above = band.top - gap - painter.height;
    painter.paint(
      canvas,
      ui.Offset(band.left + 8, above >= 0 ? above : band.bottom + gap),
    );
  }

  ZoneLabels _labels = const ZoneLabels();

  set labels(ZoneLabels value) {
    _labels = value;
    _handLabelPainter = null;
    _dropHintPainter = null;
    _deck?.label = value.deck;
    _discard?.label = value.discard;
  }

  static const _labelStyle = material.TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    fontWeight: material.FontWeight.w700,
    letterSpacing: 1.2,
  );

  material.TextPainter? _handLabelPainter;
  material.TextPainter? _dropHintPainter;

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
    // Priorities are about to be reassigned from the row order, which would
    // strand a peeked card's saved priority. Nothing is being read while the
    // hand is changing under it anyway.
    if (!isSentenceZone) _endScrub();

    final newIds = newCards.map((c) => c.id).toSet();

    // Remove components no longer in the list
    existingComponents.removeWhere((comp) {
      if (!newIds.contains(comp.card.id)) {
        _lastSeen[comp.card.id] = comp.position.clone();
        comp.removeFromParent();
        return true;
      }
      return false;
    });

    // Build a lookup for existing components
    final existingMap = {
      for (final c in existingComponents) c.card.id: c
    };

    // Add new components and reposition all. The two rows are laid out by
    // different rules — a held card only has to be identifiable, a played one
    // has to be readable — so the layout is picked here rather than shared.
    final count = newCards.length;
    final slots = isSentenceZone
        ? SentenceLine.positions(size.x, count, yPosition)
        : HandFan.positions(size.x, count, yPosition);
    final cardSize = isSentenceZone
        ? SentenceLine.cardSize(size.x, count)
        : ui.Size(BoardLayout.cardWidth, BoardLayout.cardHeight);

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
        _dress(comp, i, count, isSentenceZone, cardSize);
        updatedComponents.add(comp);
      } else {
        // New card — create component. Resolve the index by card id at drag
        // time so a reorder cannot leave a stale index behind.
        final cardId = card.id;
        final comp = CardComponent(
          card: card,
          position: targetPos,
          // Only the fan hides cards behind one another, so only the fan reads
          // by scrubbing. A card already in the open is picked up on contact.
          onScrub: isSentenceZone ? null : _onScrub,
          onScrubEnd: isSentenceZone ? null : _endScrub,
          resolveLift: isSentenceZone ? null : _resolveLift,
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
              // Dropped back down past the midline — the card is being taken
              // out of play and returned to the fan.
              if (_centreOf(component).y > _midlineY) {
                onSentenceRemove?.call(from);
                return true;
              }
              final to = SentenceLine.indexAt(
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
            // away. Checked before the play test because the pile sits above
            // the midline and would otherwise read as a play.
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

            // Pushed forward past the midline — the card is being played.
            // Where it landed decides where in the sentence it goes: a child
            // who drops a card in front of `cats` means it to read before
            // `cats`.
            if (_centreOf(component).y < _midlineY) {
              final idx = _hand.indexWhere((c) => c.id == cardId);
              if (idx >= 0) {
                onCardPlaced?.call(
                  idx,
                  SentenceLine.insertionIndexAt(
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
        _dress(comp, i, count, isSentenceZone, cardSize);
        updatedComponents.add(comp);
        add(comp);

        // Where the card is coming from: the slot it just left if it was
        // already on the board, otherwise the deck — because that is literally
        // where a new card comes from.
        final origin = _lastSeen.remove(cardId) ??
            (isSentenceZone ? null : _deck?.position.clone());
        if (origin != null) comp.dealIn(origin, targetPos);
      }
    }

    existingComponents
      ..clear()
      ..addAll(updatedComponents);
  }

  /// Runs a light across the sentence well.
  ///
  /// Called when a sentence parses. The board says so a beat before the
  /// judgment sheet does, which is where the player is already looking.
  void playSuccessSweep() {
    final height = BoardLayout.cardHeight + 24;
    add(
      SweepComponent(
        bounds: ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(
            center: ui.Offset(size.x / 2, _sentenceZoneY),
            width: size.x,
            height: height,
          ),
          const ui.Radius.circular(4),
        ),
      ),
    );
  }

  /// Everything about a card that follows from *where in the row it is*: how
  /// far it leans, and how big it is.
  ///
  /// Both are eased inside the component rather than assigned, so a card
  /// crossing between the fan and the line rotates square and changes size on
  /// the way over instead of snapping at either end.
  void _dress(
    CardComponent comp,
    int index,
    int count,
    bool isSentenceZone,
    ui.Size cardSize,
  ) {
    comp.restingAngle =
        isSentenceZone ? 0 : HandFan.lean(index, count);
    comp.resizeTo(Vector2(cardSize.width, cardSize.height));
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
      label: _labels.deck,
      scale: _pileScale,
      onTapped: (_) => onDrawFromDeck?.call(),
    );
    _discard = PileComponent(
      kind: PileKind.discard,
      label: _labels.discard,
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
    _lastSeen.clear();

    final discard = _discard;
    if (discard == null) return;

    CardComponent? dragging;
    for (final comp in _handComponents) {
      if (comp.isDragging) {
        dragging = comp;
        break;
      }
    }

    // A hand card in the air is the moment to say the pile will take it.
    // Until then the board is silent about throwing a card away, which is how
    // a player ends up believing that completing a sentence is the only move
    // they have and that a turn they cannot finish cannot be ended.
    final inviting = dragging != null;
    if (discard.isInviting != inviting) discard.isInviting = inviting;

    final over = dragging != null &&
        discard.containsBoardPoint(_centreOf(dragging));
    if (discard.isDropTarget != over) discard.isDropTarget = over;
  }

  /// Where a card *looks* like it is. A held card is drawn raised off the
  /// table, so judging a drop against its nominal slot puts the decision line
  /// a card-third away from where the player sees it.
  Vector2 _centreOf(CardComponent card) => card.visualCentre;

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
