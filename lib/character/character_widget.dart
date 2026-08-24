import 'package:flutter/material.dart';

import '../core/design/app_colors.dart';
import '../core/game_icons.dart';
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

/// Placeholder face, drawn in the same visual language as the brand mark,
/// until Rive assets exist.
///
/// The old version filled the circle and the face with the same colour, so
/// the face was invisible. Emotion is now carried by the face shape alone —
/// the icons already differ per emotion, and a second colour system competing
/// with the part-of-speech palette would teach a child nothing.
class _PlaceholderCharacter extends StatelessWidget {
  const _PlaceholderCharacter({required this.emotion, required this.size});

  final CharacterEmotion emotion;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.pointTint,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: GameIconView(
          _emotionIcon,
          size: size * 0.55,
          color: AppColors.point,
        ),
      ),
    );
  }

  GameIcon get _emotionIcon => switch (emotion) {
        CharacterEmotion.idle => GameIcon.faceIdle,
        CharacterEmotion.happy => GameIcon.faceHappy,
        CharacterEmotion.sad => GameIcon.faceSad,
        CharacterEmotion.taunt => GameIcon.faceSmug,
        CharacterEmotion.shocked => GameIcon.faceShocked,
        CharacterEmotion.celebrate => GameIcon.faceCelebrate,
      };
}
