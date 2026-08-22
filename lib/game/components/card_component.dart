import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' as material;

import '../../models/word_card.dart';
import '../card_painter.dart';

/// One card on the board.
///
/// Painting lives in [CardPainter] so the same look can be rendered outside a
/// running game loop.
class CardComponent extends PositionComponent
    with DragCallbacks, TapCallbacks {
  final WordCard card;

  /// Fires when a drag finishes, with the component's dropped position.
  /// The parent decides what the drop meant.
  final void Function(CardComponent component, Vector2 dropPosition)?
      onDragEnded;

  /// Fires on a plain tap. Used for card selection, e.g. choosing a discard.
  final void Function(CardComponent component)? onTapped;

  bool isDragging = false;

  /// Draws the card as a discard candidate.
  bool markedForDiscard = false;

  Vector2 _originalPosition = Vector2.zero();
  int _restingPriority = 0;

  static const double cardWidth = CardPainter.defaultWidth;
  static const double cardHeight = CardPainter.defaultHeight;

  CardComponent({
    required this.card,
    this.onDragEnded,
    this.onTapped,
    super.position,
  }) : super(size: Vector2(cardWidth, cardHeight));

  @override
  void render(ui.Canvas canvas) {
    CardPainter.paint(
      canvas,
      card,
      ui.Size(size.x, size.y),
      highlighted: isDragging,
      warned: markedForDiscard,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onTapped?.call(this);
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

    onDragEnded?.call(this, position.clone());

    // Snap back; the parent repositions us on the next state update if the
    // drop actually changed anything.
    add(MoveEffect.to(
      _originalPosition,
      EffectController(duration: 0.15, curve: material.Curves.easeOut),
    ));
  }
}
