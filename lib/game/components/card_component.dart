import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' as material;
import '../../models/word_card.dart';

class CardComponent extends PositionComponent with DragCallbacks {
  final WordCard card;
  final void Function(CardComponent)? onDragToSentenceZone;
  final void Function(CardComponent)? onTap;

  bool isDragging = false;
  Vector2 _originalPosition = Vector2.zero();
  bool _dragSuccess = false;

  static const double cardWidth = 80;
  static const double cardHeight = 110;

  // Cached TextPainters — only created once, reused every frame
  late final material.TextPainter _wordPainter;
  late final material.TextPainter? _iconPainter;

  CardComponent({
    required this.card,
    this.onDragToSentenceZone,
    this.onTap,
    super.position,
  }) : super(size: Vector2(cardWidth, cardHeight)) {
    // Pre-build text painters
    _wordPainter = material.TextPainter(
      text: material.TextSpan(
        text: card.word,
        style: material.TextStyle(
          color: card.isSpecial ? material.Colors.white : material.Colors.black87,
          fontSize: card.word.length > 6 ? 12 : 14,
          fontWeight: material.FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: ui.TextAlign.center,
    )..layout(maxWidth: cardWidth - 8);

    if (card.isSpecial) {
      _iconPainter = material.TextPainter(
        text: material.TextSpan(
          text: _specialIcon(card.type),
          style: const material.TextStyle(fontSize: 20),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
    } else {
      _iconPainter = null;
    }
  }

  ui.Color get cardColor {
    switch (card.type) {
      case CardType.skip:
        return const ui.Color(0xFFFBBF24);
      case CardType.steal:
        return const ui.Color(0xFFEF4444);
      case CardType.undo:
        return const ui.Color(0xFF3B82F6);
      case CardType.wild:
        return const ui.Color(0xFF8B5CF6);
      case CardType.word:
        return material.Colors.white;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final rrect = ui.RRect.fromRectAndRadius(
      size.toRect(),
      const ui.Radius.circular(8),
    );

    // Shadow
    final shadowPaint = ui.Paint()
      ..color = material.Colors.black26
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    canvas.drawRRect(rrect.shift(const ui.Offset(2, 2)), shadowPaint);

    // Background
    final bgPaint = ui.Paint()..color = cardColor;
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = ui.Paint()
      ..color = isDragging ? const ui.Color(0xFF22C55E) : material.Colors.black12
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = isDragging ? 3 : 1;
    canvas.drawRRect(rrect, borderPaint);

    // Word text (cached)
    _wordPainter.paint(
      canvas,
      ui.Offset(
        (size.x - _wordPainter.width) / 2,
        (size.y - _wordPainter.height) / 2,
      ),
    );

    // Special card icon (cached)
    if (_iconPainter case final painter?) {
      painter.paint(canvas, ui.Offset((size.x - painter.width) / 2, 8));
    }
  }

  String _specialIcon(CardType type) {
    switch (type) {
      case CardType.skip:
        return '⏭';
      case CardType.steal:
        return '🫳';
      case CardType.undo:
        return '↩';
      case CardType.wild:
        return '🌟';
      default:
        return '';
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    isDragging = true;
    _dragSuccess = false;
    _originalPosition = position.clone();
    priority = 100;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    priority = 0;

    // Use relative threshold (20% of screen height approximated by original Y)
    final threshold = _originalPosition.y * 0.15;
    if (_originalPosition.y - position.y > threshold) {
      _dragSuccess = true;
      onDragToSentenceZone?.call(this);
    }

    // Only animate back if the drop was NOT successful
    // (successful drops will be removed by parent rebuild)
    if (!_dragSuccess) {
      add(MoveEffect.to(
        _originalPosition,
        EffectController(duration: 0.2, curve: material.Curves.easeOut),
      ));
    }
  }
}
