import 'dart:ui' as ui;
import 'package:flame/game.dart';
import '../models/word_card.dart';
import 'components/card_component.dart';

typedef OnCardPlaced = void Function(int handIndex);
typedef OnSentenceReorder = void Function(int from, int to);
typedef OnSentenceRemove = void Function(int index);

class DrippleGame extends FlameGame {
  List<WordCard> _hand = [];
  List<WordCard> _sentenceZone = [];
  final List<CardComponent> _handComponents = [];
  final List<CardComponent> _sentenceComponents = [];

  OnCardPlaced? onCardPlaced;
  OnSentenceReorder? onSentenceReorder;
  OnSentenceRemove? onSentenceRemove;

  double get _sentenceZoneY => size.y * 0.4;
  double get _handY => size.y * 0.72;

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
    final step = _stepFor(newCards.length);
    final totalWidth = newCards.isEmpty
        ? 0.0
        : (newCards.length - 1) * step + CardComponent.cardWidth;
    final startX = newCards.isEmpty ? 0.0 : (size.x - totalWidth) / 2;

    final updatedComponents = <CardComponent>[];

    for (int i = 0; i < newCards.length; i++) {
      final card = newCards[i];
      final targetX = startX + i * step;
      final targetPos = Vector2(targetX, yPosition);

      if (existingMap.containsKey(card.id)) {
        // Existing card — just reposition
        final comp = existingMap[card.id]!;
        comp.position = targetPos;
        // Overlapping cards must stack left-to-right, like a fanned hand.
        comp.priority = i;
        updatedComponents.add(comp);
      } else {
        // New card — create component. Resolve the index by card id at drag
        // time so a reorder cannot leave a stale index behind.
        final cardId = card.id;
        final comp = CardComponent(
          card: card,
          position: targetPos,
          onDragEnded: (component, dropPosition) {
            if (isSentenceZone) {
              final from = _sentenceZone.indexWhere((c) => c.id == cardId);
              if (from < 0) return;
              // Dragged clear of the zone — send it back to hand.
              if ((dropPosition.y - _sentenceZoneY).abs() >
                  CardComponent.cardHeight) {
                onSentenceRemove?.call(from);
                return;
              }
              final to = _indexAtX(dropPosition.x, _sentenceZone.length);
              if (to != from) onSentenceReorder?.call(from, to);
            } else {
              // Hand card lifted toward the sentence zone.
              if (dropPosition.y < _handY - CardComponent.cardHeight * 0.5) {
                final idx = _hand.indexWhere((c) => c.id == cardId);
                if (idx >= 0) onCardPlaced?.call(idx);
              }
            }
          },
        );
        comp.priority = i;
        updatedComponents.add(comp);
        add(comp);
      }
    }

    existingComponents
      ..clear()
      ..addAll(updatedComponents);
  }

  /// Horizontal distance between adjacent cards.
  ///
  /// A full hand at full spacing is wider than a phone screen, so cards
  /// overlap once they would run off the edge — the way a real hand of
  /// cards fans. Always leaves [_edgePadding] on both sides so the first
  /// and last card stay reachable.
  double _stepFor(int count) {
    const preferred = CardComponent.cardWidth + 8;
    if (count <= 1) return preferred;

    final available = size.x - _edgePadding * 2 - CardComponent.cardWidth;
    if (available <= 0) return preferred;

    final fitted = available / (count - 1);
    return fitted < preferred ? fitted : preferred;
  }

  static const double _edgePadding = 12;

  /// Which slot an x-coordinate lands in, for a row of [count] cards.
  int _indexAtX(double x, int count) {
    if (count <= 1) return 0;
    final step = _stepFor(count);
    final totalWidth = (count - 1) * step + CardComponent.cardWidth;
    final startX = (size.x - totalWidth) / 2;
    final raw = ((x - startX) / step).round();
    return raw.clamp(0, count - 1);
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
