import 'package:equatable/equatable.dart';
import 'word_card.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final bool isAI;
  final List<WordCard> hand;
  final List<WordCard> sentenceZone;
  final int score;
  final int comboCount;

  const Player({
    required this.id,
    required this.name,
    this.isAI = false,
    this.hand = const [],
    this.sentenceZone = const [],
    this.score = 0,
    this.comboCount = 0,
  });

  Player copyWith({
    List<WordCard>? hand,
    List<WordCard>? sentenceZone,
    int? score,
    int? comboCount,
  }) {
    return Player(
      id: id,
      name: name,
      isAI: isAI,
      hand: hand ?? this.hand,
      sentenceZone: sentenceZone ?? this.sentenceZone,
      score: score ?? this.score,
      comboCount: comboCount ?? this.comboCount,
    );
  }

  @override
  List<Object?> get props => [id, name, isAI, hand, sentenceZone, score, comboCount];
}
