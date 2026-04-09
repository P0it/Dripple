import 'dart:ui' as ui;
import 'package:flame/game.dart';
import '../models/word_card.dart';
import 'components/card_component.dart';

typedef OnCardPlaced = void Function(int cardIndex);

class DrippleGame extends FlameGame {
  List<WordCard> _hand = [];
  List<WordCard> _sentenceZone = [];
  final List<CardComponent> _handComponents = [];
  final List<CardComponent> _sentenceComponents = [];

  OnCardPlaced? onCardPlaced;

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
      withDrag: true,
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
      withDrag: false,
    );
  }

  /// Diff-based component update: only remove/add what changed
  void _diffUpdateComponents({
    required List<WordCard> newCards,
    required List<CardComponent> existingComponents,
    required double yPosition,
    required bool withDrag,
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
    final totalWidth = newCards.length * (CardComponent.cardWidth + 8) - 8;
    final startX = newCards.isEmpty ? 0.0 : (size.x - totalWidth) / 2;

    final updatedComponents = <CardComponent>[];

    for (int i = 0; i < newCards.length; i++) {
      final card = newCards[i];
      final targetX = startX + i * (CardComponent.cardWidth + 8);
      final targetPos = Vector2(targetX, yPosition);

      if (existingMap.containsKey(card.id)) {
        // Existing card — just reposition
        final comp = existingMap[card.id]!;
        comp.position = targetPos;
        updatedComponents.add(comp);
      } else {
        // New card — create component. Use card ID to resolve index at drag time
        // to avoid stale index after hand reorder.
        final cardId = card.id;
        final comp = CardComponent(
          card: card,
          position: targetPos,
          onDragToSentenceZone: withDrag
              ? (_) {
                  final idx = _hand.indexWhere((c) => c.id == cardId);
                  if (idx >= 0) onCardPlaced?.call(idx);
                }
              : null,
        );
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
        withDrag: true,
      );
    }
    if (_sentenceZone.isNotEmpty) {
      _diffUpdateComponents(
        newCards: _sentenceZone,
        existingComponents: _sentenceComponents,
        yPosition: _sentenceZoneY,
        withDrag: false,
      );
    }
  }
}
