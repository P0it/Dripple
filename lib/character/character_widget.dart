import '../core/game_icons.dart';
import 'package:flutter/material.dart';
import 'character_emotion.dart';

/// Character display widget.
/// Currently uses a placeholder avatar. When Rive assets are ready,
/// replace with RiveAnimation widget driven by StateMachineController.
///
/// To integrate Rive:
/// 1. Place .riv files in assets/rive/
/// 2. Replace _PlaceholderCharacter with:
///    RiveAnimation.asset(
///      'assets/rive/character_$characterId.riv',
///      stateMachines: ['StateMachine'],
///      onInit: (artboard) { ... },
///    )
/// 3. On emotion change, set State Machine input:
///    _controller.findInput('isHappy')?.value = true;
class CharacterWidget extends StatefulWidget {
  final String characterId;
  final CharacterEmotion emotion;
  final double size;

  const CharacterWidget({
    super.key,
    required this.characterId,
    this.emotion = CharacterEmotion.idle,
    this.size = 80,
  });

  @override
  State<CharacterWidget> createState() => _CharacterWidgetState();
}

class _CharacterWidgetState extends State<CharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(CharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emotion != oldWidget.emotion &&
        widget.emotion != CharacterEmotion.idle) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) => Transform.scale(
        scale: _bounceAnimation.value,
        child: child,
      ),
      child: _PlaceholderCharacter(
        emotion: widget.emotion,
        size: widget.size,
      ),
    );
  }
}

/// Placeholder character using Flutter widgets until Rive assets are ready
class _PlaceholderCharacter extends StatelessWidget {
  final CharacterEmotion emotion;
  final double size;

  const _PlaceholderCharacter({
    required this.emotion,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _bgColor.withAlpha(77),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: GameIconView(
          _emotionIcon,
          size: size * 0.55,
          color: _bgColor,
        ),
      ),
    );
  }

  Color get _bgColor {
    switch (emotion) {
      case CharacterEmotion.idle:
        return const Color(0xFF86EFAC);
      case CharacterEmotion.happy:
        return const Color(0xFF22C55E);
      case CharacterEmotion.sad:
        return const Color(0xFF93C5FD);
      case CharacterEmotion.taunt:
        return const Color(0xFFFBBF24);
      case CharacterEmotion.shocked:
        return const Color(0xFFF97316);
      case CharacterEmotion.celebrate:
        return const Color(0xFFA855F7);
    }
  }

  GameIcon get _emotionIcon {
    switch (emotion) {
      case CharacterEmotion.idle:
        return GameIcon.faceIdle;
      case CharacterEmotion.happy:
        return GameIcon.faceHappy;
      case CharacterEmotion.sad:
        return GameIcon.faceSad;
      case CharacterEmotion.taunt:
        return GameIcon.faceSmug;
      case CharacterEmotion.shocked:
        return GameIcon.faceShocked;
      case CharacterEmotion.celebrate:
        return GameIcon.faceCelebrate;
    }
  }
}
