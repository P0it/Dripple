import 'dart:math' as math;
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
/// running game loop. What lives here is everything that makes the card behave
/// like an object: it rests crooked, it tilts as you swing it, it rises and
/// its shadow spreads while you hold it, and it lands rather than arrives.
///
/// The mixin order is load-bearing. Each callback mixin registers its own
/// gesture recognizer as the component mounts, and a tap that never moves is
/// settled by an arena sweep that awards the win to whichever recognizer
/// registered first. Mixins mount right to left, so listing [TapCallbacks]
/// first puts taps in the arena ahead of drags — the other way round, a drag
/// recognizer wins every stationary press and `onTapUp` is never delivered.
/// Dragging is unaffected either way: the drag accepts as soon as the pointer
/// moves, well before any sweep.
class CardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
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

  /// The largest angle a card tips to while being swung, in radians (~8°).
  static const double _maxTilt = 0.14;

  /// How crooked a resting card sits, in radians (~1.2°).
  static const double _maxJitter = 0.021;

  CardComponent({
    required this.card,
    this.onDragEnded,
    this.onTapped,
    super.position,
  })  : _jitter = _jitterFor(card.id),
        super(size: Vector2(cardWidth, cardHeight));

  /// Cards laid on a table are never in a grid. Each takes a small rotation
  /// derived from its own id, so the angle is stable across every frame and
  /// every rebuild while the hand as a whole stops reading as CSS.
  final double _jitter;

  static double _jitterFor(String id) {
    final n = id.hashCode.abs() % 1000;
    return (n / 1000 * 2 - 1) * _maxJitter;
  }

  /// 0 resting, 1 held. Drives scale and both shadow layers together, which is
  /// the difference between a card rising off a table and a sticker growing.
  double _lift = 0;

  /// Current and target tip, driven by drag velocity.
  double _tilt = 0;
  double _tiltTarget = 0;

  /// 0 while dealing in, 1 once seated.
  double _enter = 1;

  /// Runs 0 → 1 across a settle, driving a single scale breath so the card
  /// lands rather than arrives.
  double _pulse = 0;

  @override
  void update(double dt) {
    super.update(dt);

    // Framerate-independent approach: `1 - exp(-rate * dt)` rather than
    // `rate * dt`, so a dropped frame does not overshoot.
    double approach(double current, double target, double rate) =>
        current + (target - current) * (1 - math.exp(-rate * dt));

    _lift = approach(_lift, isDragging ? 1 : 0, 14);
    _enter = approach(_enter, 1, 11);

    if (!isDragging) _tiltTarget = 0;
    _tilt = approach(_tilt, _tiltTarget, 12);
    // The swing itself decays even while the drag continues, so a card held
    // still hangs straight instead of staying tipped.
    _tiltTarget *= math.exp(-7 * dt);

    if (_pulse > 0) _pulse = math.max(0, _pulse - dt / 0.20);
  }

  @override
  void render(ui.Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // A settle breath: nothing at the ends, a little in the middle.
    final breath = 1 + 0.035 * math.sin(math.pi * (1 - _pulse));
    final scale = (0.78 + 0.22 * _enter) * (1 + 0.05 * _lift) * breath;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    // The crook straightens as the card is picked up — you square a card in
    // your hand without thinking about it.
    canvas.rotate(_jitter * (1 - _lift));

    if (_tilt.abs() > 0.0005) {
      final m = material.Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..rotateY(_tilt)
        // A touch of X with it, so the swing arcs instead of shearing.
        ..rotateX(-_tilt.abs() * 0.28);
      canvas.transform(m.storage);
    }

    canvas.translate(-cx, -cy);

    CardPainter.paint(
      canvas,
      card,
      ui.Size(size.x, size.y),
      highlighted: isDragging,
      warned: markedForDiscard,
      lift: _lift,
    );

    canvas.restore();
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
    _tiltTarget =
        (_tiltTarget * 0.55 + event.localDelta.x * 0.035).clamp(-_maxTilt, _maxTilt);
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
    _pulse = 1;
    add(
      MoveEffect.to(
        target,
        EffectController(
          duration: 0.20,
          curve: material.Curves.easeOutCubic,
        ),
        onComplete: () => isSettling = false,
      ),
    );
  }

  /// Deals the card in from [from] — the deck, usually — arriving small and
  /// growing into its slot.
  void dealIn(Vector2 from, Vector2 target) {
    position = from.clone();
    _enter = 0;
    settleTo(target);
  }
}
