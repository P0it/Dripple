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
  ///
  /// The parent decides what the drop meant and returns true if it acted on
  /// it. A handled drop must not snap back: the parent is about to move this
  /// card somewhere new, and a snap-back effect would keep overwriting
  /// `position` for the length of its run and win.
  final bool Function(CardComponent component, Vector2 dropPosition)?
      onDragEnded;

  /// Fires on a plain tap. Used for card selection, e.g. choosing a discard.
  final void Function(CardComponent component)? onTapped;

  bool isDragging = false;

  /// True while a settle animation owns [position].
  bool isSettling = false;

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

    final handled = onDragEnded?.call(this, position.clone()) ?? false;
    if (handled) return; // the parent settles us into the new slot

    settleTo(_originalPosition);
  }

  /// Animates the card into [target], cancelling any settle already running so
  /// two effects never fight over [position].
  void settleTo(Vector2 target) {
    for (final effect in children.whereType<MoveEffect>().toList()) {
      effect.removeFromParent();
    }
    isSettling = true;
    add(
      MoveEffect.to(
        target,
        EffectController(
          duration: 0.18,
          curve: material.Curves.easeOutCubic,
        ),
        onComplete: () => isSettling = false,
      ),
    );
  }
}
