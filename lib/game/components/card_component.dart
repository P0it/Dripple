import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' as material;

import 'package:dripple_rules/models/word_card.dart';
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

  /// Fires while a finger runs along the fan without having lifted anything
  /// yet, with the finger's x in board coordinates.
  ///
  /// A fanned hand overlaps, so most of a card is behind the next one. This is
  /// how you read it: you run a thumb along the hand and each card in turn
  /// comes up out of it. Setting this is also what puts a card into
  /// scrub-first mode — a card without it (one already laid out in the open,
  /// where there is nothing to uncover) drags the moment you press it.
  final void Function(CardComponent origin, double boardX)? onScrub;

  /// Fires when a scrub ends without anything being lifted.
  final void Function()? onScrubEnd;

  /// Asks the board which card the finger actually settled on, so a drag that
  /// starts on one card and slides along the fan lifts the one you stopped at
  /// rather than the one you happened to touch first.
  final CardComponent? Function(CardComponent origin)? resolveLift;

  bool isDragging = false;

  /// True while a settle animation owns [position].
  bool isSettling = false;

  /// Draws the card as a discard candidate.
  bool markedForDiscard = false;

  /// Which language the gloss under the word is printed in. English prints no
  /// gloss at all — see [CardPainter].
  String locale = 'ko';

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
    this.onScrub,
    this.onScrubEnd,
    this.resolveLift,
    super.position,
  })  : _jitter = _jitterFor(card.id),
        super(size: Vector2(cardWidth, cardHeight));

  /// Cards laid on a table are never in a grid. Each takes a small rotation
  /// derived from its own id, so the angle is stable across every frame and
  /// every rebuild while the hand as a whole stops reading as CSS.
  final double _jitter;

  /// Where the card is meant to sit, in radians. The fan sets this so the row
  /// splays; a card pushed forward into a sentence goes back to near-square,
  /// keeping only its own crook. Changes are eased rather than snapped, so a
  /// card leaving the fan rotates as it travels.
  late double _angleTarget = _jitter;
  late double _angle = _jitter;

  set restingAngle(double radians) => _angleTarget = radians + _jitter * 0.5;

  /// Resting jitter alone — what a card laid flat on the table takes.
  double get squareAngle => _jitter;

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

  /// Set while a thumb is resting on this card in the fan. The card comes up
  /// out of the hand and over its neighbours — which is the whole trick, since
  /// what hides it is the card in front, not anything geometric.
  bool _peeking = false;
  double _peek = 0;
  int _peekRestore = 0;

  /// How far a peeked card rises out of the fan, as a fraction of its height,
  /// and how much bigger it gets. The rise is for feel; the priority change is
  /// what actually uncovers it.
  static const double _peekRise = 0.34;
  static const double _peekGrow = 0.16;

  bool get isPeeking => _peeking;

  /// How far off the table the card is drawn, 0 to 1. Reading it and holding
  /// it look the same, which is what makes one become the other without a hop.
  double get _raised => math.max(_peek, _lift);

  double get _raise => size.y * _peekRise * _raised;

  /// Where the card *looks* like it is, which is what a drop has to be judged
  /// against — the finger is on the card the player can see, not on the slot
  /// the component still nominally occupies.
  Vector2 get visualCentre => Vector2(
        position.x + size.x / 2,
        position.y + size.y / 2 - _raise,
      );

  /// The card's top-left as drawn, for the same reason.
  Vector2 get visualPosition => Vector2(position.x, position.y - _raise);

  set peeking(bool value) {
    if (_peeking == value) return;
    _peeking = value;
    if (value) {
      _peekRestore = priority;
      priority = 900;
    } else {
      priority = _peekRestore;
    }
  }

  /// The size the card is easing toward. A sentence line shrinks its cards to
  /// stay on one line, so a card crossing into one changes size; snapping it
  /// mid-flight reads as a glitch rather than as the same card.
  Vector2? _sizeTarget;

  void resizeTo(Vector2 target) {
    if ((target - size).length < 0.01) {
      _sizeTarget = null;
      return;
    }
    _sizeTarget = target.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Framerate-independent approach: `1 - exp(-rate * dt)` rather than
    // `rate * dt`, so a dropped frame does not overshoot.
    double approach(double current, double target, double rate) =>
        current + (target - current) * (1 - math.exp(-rate * dt));

    _lift = approach(_lift, isDragging ? 1 : 0, 14);
    _peek = approach(_peek, _peeking ? 1 : 0, 16);
    _enter = approach(_enter, 1, 11);
    _angle = approach(_angle, _angleTarget, 10);

    final wanted = _sizeTarget;
    if (wanted != null) {
      size.setValues(
        approach(size.x, wanted.x, 14),
        approach(size.y, wanted.y, 14),
      );
      if ((wanted - size).length < 0.15) {
        size.setFrom(wanted);
        _sizeTarget = null;
      }
    }

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
    final scale = (0.78 + 0.22 * _enter) * (1 + _peekGrow * _raised) * breath;

    canvas.save();
    canvas.translate(cx, cy - _raise);
    canvas.scale(scale);
    // The lean straightens as the card is picked up or read — you square a
    // card in your hand without thinking about it.
    canvas.rotate(_angle * (1 - _lift) * (1 - _peek));

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
      lift: _raised,
      locale: locale,
    );

    canvas.restore();
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onTapped?.call(this);
  }

  /// How far up a finger has to travel before the gesture stops being a read
  /// and becomes a play. Short enough that pulling a card out feels immediate,
  /// long enough that running a thumb sideways never plays anything.
  static const double _liftThreshold = 16;

  /// Where the finger is, in board coordinates.
  Vector2 _finger = Vector2.zero();

  /// How far the finger has travelled since the press, while still reading.
  final Vector2 _scrubTotal = Vector2.zero();

  /// The card the gesture actually picked up. Usually this one; the card the
  /// thumb settled on if the finger slid along the fan first.
  CardComponent? _lifted;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _originalPosition = position.clone();
    _scrubTotal.setZero();
    _lifted = null;

    if (onScrub == null) {
      // Nothing is covering this card, so there is nothing to read — the
      // press is already a pick-up.
      _lifted = this;
      _beginLift();
      return;
    }

    _finger = event.canvasPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _finger += event.canvasDelta;

    final lifted = _lifted;
    if (lifted != null) {
      lifted._moveBy(event.canvasDelta);
      return;
    }

    _scrubTotal.add(event.canvasDelta);
    if (-_scrubTotal.y >= _liftThreshold) {
      final chosen = resolveLift?.call(this) ?? this;
      _lifted = chosen;
      chosen._beginLift();
      return;
    }

    onScrub?.call(this, _finger.x);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    var lifted = _lifted;
    _lifted = null;

    if (lifted == null) {
      // A card sitting somewhere other than its slot was dragged by something
      // that did not go through the threshold — a synthetic drag in a test, or
      // a flick that outran it. Wherever it ended up is still a drop.
      if ((position - _originalPosition).length > 1) {
        lifted = this;
      } else {
        onScrubEnd?.call();
        return;
      }
    }

    lifted._endLift();
  }

  void _beginLift() {
    // No hop between reading and picking up: a lifted card is raised and
    // enlarged by exactly as much as a peeked one, so the handoff is invisible
    // and the card simply keeps following the finger.
    _originalPosition = position.clone();
    peeking = false;
    isDragging = true;
    _restingPriority = priority;
    priority = 1000; // above the fan while dragging
  }

  void _moveBy(Vector2 delta) {
    position += delta;
    _tiltTarget =
        (_tiltTarget * 0.55 + delta.x * 0.035).clamp(-_maxTilt, _maxTilt);
  }

  void _endLift() {
    isDragging = false;
    priority = _restingPriority;

    final handled = onDragEnded?.call(this, visualPosition) ?? false;
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
