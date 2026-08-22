import 'dart:ui' as ui;
import 'package:flame/game.dart';
import '../models/word_card.dart';
import 'card_row_layout.dart';
import 'components/card_component.dart';

typedef OnCardPlaced = void Function(int handIndex);
typedef OnSentenceReorder = void Function(int from, int to);
typedef OnSentenceRemove = void Function(int index);
typedef OnHandCardTapped = void Function(int handIndex);

class DrippleGame extends FlameGame {
  List<WordCard> _hand = [];
  List<WordCard> _sentenceZone = [];
  final List<CardComponent> _handComponents = [];
  final List<CardComponent> _sentenceComponents = [];

  OnCardPlaced? onCardPlaced;
  OnSentenceReorder? onSentenceReorder;
  OnSentenceRemove? onSentenceRemove;
  OnHandCardTapped? onHandCardTapped;

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

  double get _sentenceZoneY => size.y * 0.30;
  double get _handY => size.y * 0.74;

  @override
  ui.Color backgroundColor() => const ui.Color(0xFFF0FDF4);

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
        // Existing card — just reposition
        final comp = existingMap[card.id]!;
        comp.position = targetPos;
        // Overlapping cards must stack left-to-right, like a fanned hand.
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
              if (from < 0) return;
              // Dragged clear of the zone — send it back to hand.
              final zoneReach = CardRowLayout.blockHeight(
                      size.x, _sentenceZone.length) /
                  2 +
                  CardComponent.cardHeight * 0.6;
              if ((dropPosition.y - _sentenceZoneY).abs() > zoneReach) {
                onSentenceRemove?.call(from);
                return;
              }
              final to = CardRowLayout.indexAt(
                ui.Offset(dropPosition.x, dropPosition.y),
                size.x,
                _sentenceZone.length,
                _sentenceZoneY,
              );
              if (to != from) onSentenceReorder?.call(from, to);
            } else {
              // Hand card lifted toward the sentence zone.
              final handReach =
                  CardRowLayout.blockHeight(size.x, _hand.length) / 2;
              if (dropPosition.y < _handY - handReach) {
                final idx = _hand.indexWhere((c) => c.id == cardId);
                if (idx >= 0) onCardPlaced?.call(idx);
              }
            }
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

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
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
