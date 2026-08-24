import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' as material;

import '../../core/design/app_colors.dart';
import '../../models/word_card.dart';
import '../card_painter.dart';

/// Which pile this is.
enum PileKind {
  /// Face down. Tap to draw the top card.
  deck,

  /// Face up. Tap to take the top card, or drop a card on it to throw one away.
  discard,
}

/// A stack of cards sitting on the board.
///
/// The deck and the discard pile used to be two buttons under the board, which
/// asked a child to believe that "새 카드" was a stack of cards. In a card game
/// the deck is a thing you touch, so it is drawn as one: a face-down stack you
/// tap, and a face-up pile you tap to take from or drop onto to throw away.
class PileComponent extends PositionComponent with TapCallbacks {
  PileComponent({
    required this.kind,
    this.onTapped,
    double scale = 1,
    super.position,
  }) : super(
          size: Vector2(
            CardPainter.defaultWidth * scale,
            CardPainter.defaultHeight * scale,
          ),
        );

  final PileKind kind;
  final void Function(PileComponent pile)? onTapped;

  /// How many cards are underneath. Drives the stacked-edge effect and the
  /// count printed under the deck.
  int count = 0;

  /// The discard pile's top card, face up. Null when the pile is empty.
  WordCard? topCard;

  /// Lit while a dragged card hovers over this pile.
  bool isDropTarget = false;

  bool get isEmpty => kind == PileKind.deck ? count == 0 : topCard == null;

  /// Whether a point in the parent's coordinate space lands on this pile.
  ///
  /// Used for drop tests, which happen while the dragged card — not this
  /// component — owns the gesture, so Flame's own hit testing never runs.
  bool containsBoardPoint(Vector2 point) {
    // Generous vertically: a child aiming for a small pile with a big card
    // under their thumb will land short more often than wide.
    const slack = 16.0;
    return point.x >= position.x - slack &&
        point.x <= position.x + size.x + slack &&
        point.y >= position.y - slack &&
        point.y <= position.y + size.y + slack;
  }

  @override
  void render(ui.Canvas canvas) {
    final cardSize = ui.Size(size.x, size.y);

    if (isEmpty) {
      CardPainter.paintEmptySlot(canvas, cardSize);
    } else {
      _renderStackedEdges(canvas);
      switch (kind) {
        case PileKind.deck:
          CardPainter.paintBack(canvas, cardSize);
        case PileKind.discard:
          CardPainter.paint(canvas, topCard!, cardSize);
      }
    }

    if (isDropTarget) _renderDropHighlight(canvas);
    if (kind == PileKind.deck && count > 0) _renderCount(canvas);
  }

  /// A couple of offset edges behind the top card, so a stack reads as deep
  /// rather than as a single card.
  void _renderStackedEdges(ui.Canvas canvas) {
    final layers = count >= 10 ? 2 : (count >= 3 ? 1 : 0);
    for (var i = layers; i >= 1; i--) {
      final inset = i * 3.0;
      final rect = ui.Rect.fromLTWH(inset, -inset, size.x - inset, size.y);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(size.x * 0.14)),
        ui.Paint()..color = AppColors.border,
      );
    }
  }

  void _renderDropHighlight(ui.Canvas canvas) {
    final rrect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Radius.circular(size.x * 0.14),
    );
    canvas.drawRRect(
      rrect,
      ui.Paint()..color = AppColors.danger.withValues(alpha: 0.14),
    );
    canvas.drawRRect(
      rrect.deflate(1.5),
      ui.Paint()
        ..color = AppColors.danger
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  late final material.TextPainter _countPainter = material.TextPainter(
    textDirection: ui.TextDirection.ltr,
    textAlign: ui.TextAlign.center,
  );

  int _paintedCount = -1;

  void _renderCount(ui.Canvas canvas) {
    if (_paintedCount != count) {
      _paintedCount = count;
      _countPainter
        ..text = material.TextSpan(
          text: '$count',
          style: const material.TextStyle(
            fontFamily: 'Pretendard',
            color: material.Colors.white,
            fontSize: 13,
            fontWeight: material.FontWeight.w700,
          ),
        )
        ..layout();
    }

    _countPainter.paint(
      canvas,
      ui.Offset((size.x - _countPainter.width) / 2, size.y * 0.06),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onTapped?.call(this);
  }
}
