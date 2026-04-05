import 'dart:ui' as ui;
import 'package:flame/game.dart';
import '../models/word_card.dart';
import 'components/card_component.dart';

/// Callback interface for game events
typedef OnCardPlaced = void Function(int cardIndex);
typedef OnCardDrawn = void Function();

class DrippleGame extends FlameGame {
  List<WordCard> _hand = [];
  List<WordCard> _sentenceZone = [];
  final List<CardComponent> _handComponents = [];
  final List<CardComponent> _sentenceComponents = [];

  OnCardPlaced? onCardPlaced;
  OnCardDrawn? onCardDrawn;

  double get _sentenceZoneY => size.y * 0.4;
  double get _handY => size.y * 0.72;

  @override
  ui.Color backgroundColor() => const ui.Color(0xFFF0FDF4);

  void updateHand(List<WordCard> hand) {
    _hand = hand;
    _rebuildHand();
  }

  void updateSentenceZone(List<WordCard> sentenceZone) {
    _sentenceZone = sentenceZone;
    _rebuildSentenceZone();
  }

  void _rebuildHand() {
    for (final comp in _handComponents) {
      comp.removeFromParent();
    }
    _handComponents.clear();

    if (_hand.isEmpty) return;

    final totalWidth = _hand.length * (CardComponent.cardWidth + 8) - 8;
    final startX = (size.x - totalWidth) / 2;

    for (int i = 0; i < _hand.length; i++) {
      final card = _hand[i];
      final cardIndex = i;
      final comp = CardComponent(
        card: card,
        position: Vector2(
          startX + i * (CardComponent.cardWidth + 8),
          _handY,
        ),
        onDragToSentenceZone: (_) {
          onCardPlaced?.call(cardIndex);
        },
      );
      _handComponents.add(comp);
      add(comp);
    }
  }

  void _rebuildSentenceZone() {
    for (final comp in _sentenceComponents) {
      comp.removeFromParent();
    }
    _sentenceComponents.clear();

    if (_sentenceZone.isEmpty) {
      // Draw placeholder slots
      return;
    }

    final totalWidth =
        _sentenceZone.length * (CardComponent.cardWidth + 8) - 8;
    final startX = (size.x - totalWidth) / 2;

    for (int i = 0; i < _sentenceZone.length; i++) {
      final card = _sentenceZone[i];
      final comp = CardComponent(
        card: card,
        position: Vector2(
          startX + i * (CardComponent.cardWidth + 8),
          _sentenceZoneY,
        ),
      );
      _sentenceComponents.add(comp);
      add(comp);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_hand.isNotEmpty) _rebuildHand();
    if (_sentenceZone.isNotEmpty) _rebuildSentenceZone();
  }
}
