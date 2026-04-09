/// Character emotion states driven by game events.
/// When Rive assets are ready, these map to State Machine inputs.
enum CharacterEmotion {
  idle,
  happy,
  sad,
  taunt,
  shocked,
  celebrate;

  /// Map game events to emotions
  static CharacterEmotion fromGameEvent(GameEvent event) {
    switch (event) {
      case GameEvent.correctAnswer:
        return CharacterEmotion.happy;
      case GameEvent.wrongAnswer:
        return CharacterEmotion.sad;
      case GameEvent.opponentCorrect:
        return CharacterEmotion.shocked;
      case GameEvent.cardStolen:
        return CharacterEmotion.shocked;
      case GameEvent.gameWin:
        return CharacterEmotion.celebrate;
      case GameEvent.gameLose:
        return CharacterEmotion.sad;
      case GameEvent.emoteHappy:
        return CharacterEmotion.happy;
      case GameEvent.emoteTaunt:
        return CharacterEmotion.taunt;
      case GameEvent.emoteShocked:
        return CharacterEmotion.shocked;
      case GameEvent.none:
        return CharacterEmotion.idle;
    }
  }
}

enum GameEvent {
  none,
  correctAnswer,
  wrongAnswer,
  opponentCorrect,
  cardStolen,
  gameWin,
  gameLose,
  emoteHappy,
  emoteTaunt,
  emoteShocked,
}
