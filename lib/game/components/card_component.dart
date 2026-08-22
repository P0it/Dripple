import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' as material;
import '../../models/word_card.dart';

class CardComponent extends PositionComponent with DragCallbacks {
  final WordCard card;

  /// Called when a drag finishes, with the component's dropped position.
  /// The parent decides what the drop meant.
  final void Function(CardComponent component, Vector2 dropPosition)?
      onDragEnded;

  bool isDragging = false;
  Vector2 _originalPosition = Vector2.zero();
  int _restingPriority = 0;

  static const double cardWidth = 80;
  static const double cardHeight = 110;

  // Cached TextPainters — only created once, reused every frame
  late final material.TextPainter _wordPainter;
  late final material.TextPainter? _iconPainter;

  CardComponent({
    required this.card,
    this.onDragEnded,
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
      case CardType.jump:
        return const ui.Color(0xFFFBBF24);
      case CardType.steal:
        return const ui.Color(0xFFEF4444);
      case CardType.joker:
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

    // Montessori grammar symbol — a child who cannot yet read the word can
    // still see the sentence's shape.
    if (card.posShape != PosShape.none) {
      _paintPosSymbol(canvas);
    }

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

  void _paintPosSymbol(ui.Canvas canvas) {
    final paint = ui.Paint()..color = ui.Color(card.posColor);
    final cx = size.x / 2;
    const topY = 16.0;

    switch (card.posShape) {
      case PosShape.triangleLarge:
      case PosShape.triangleMedium:
      case PosShape.triangleSmall:
      case PosShape.trianglePronoun:
        final half = switch (card.posShape) {
          PosShape.triangleLarge => 11.0,
          PosShape.triangleMedium => 9.0,
          PosShape.trianglePronoun => 9.0,
          _ => 7.0,
        };
        final path = ui.Path()
          ..moveTo(cx, topY - half)
          ..lineTo(cx - half, topY + half)
          ..lineTo(cx + half, topY + half)
          ..close();
        canvas.drawPath(path, paint);
      case PosShape.circle:
        canvas.drawCircle(ui.Offset(cx, topY), 10, paint);
      case PosShape.circleSmall:
        canvas.drawCircle(ui.Offset(cx, topY), 6, paint);
      case PosShape.crescent:
        canvas.drawCircle(ui.Offset(cx, topY), 9, paint);
        canvas.drawCircle(
          ui.Offset(cx + 4, topY - 2),
          8,
          ui.Paint()..color = cardColor,
        );
      case PosShape.none:
        break;
    }
  }

  String _specialIcon(CardType type) {
    switch (type) {
      case CardType.jump:
        return '⏭';
      case CardType.steal:
        return '🫳';
      case CardType.joker:
        return '🌟';
      default:
        return '';
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    isDragging = true;
    _originalPosition = position.clone();
    _restingPriority = priority;
    priority = 1000; // lift above the fan while dragging
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    priority = _restingPriority;

    final dropPosition = position.clone();
    onDragEnded?.call(this, dropPosition);

    // Snap back; the parent repositions us on the next state update if the
    // drop actually changed anything.
    add(MoveEffect.to(
      _originalPosition,
      EffectController(duration: 0.15, curve: material.Curves.easeOut),
    ));
  }
}
