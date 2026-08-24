// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dripple';

  @override
  String get wordCardBattle => 'Word Card Battle';

  @override
  String get play => 'PLAY';

  @override
  String get character => 'Character';

  @override
  String get ranking => 'Ranking';

  @override
  String get settings => 'Settings';

  @override
  String get selectMode => 'Select Mode';

  @override
  String get aiBattle => 'AI Battle';

  @override
  String get aiBattleDesc => 'Play against AI opponents';

  @override
  String get onlineBattle => 'Online Battle';

  @override
  String get onlineBattleDesc => 'Random matchmaking';

  @override
  String get friendBattle => 'Friend Battle';

  @override
  String get friendBattleDesc => 'Invite via code/link';

  @override
  String get comingSoon => 'COMING SOON';

  @override
  String get playerCount => 'Player Count';

  @override
  String nPlayers(int count) {
    return '$count Players';
  }

  @override
  String roundIndicator(int current, int total) {
    return 'Round $current/$total';
  }

  @override
  String nCards(int count) {
    return '$count cards';
  }

  @override
  String get sentenceZone => 'Sentence Zone';

  @override
  String get draw => 'Draw';

  @override
  String get undo => 'Undo';

  @override
  String get submit => 'Submit';

  @override
  String get correct => 'Correct!';

  @override
  String get incorrect => 'Incorrect!';

  @override
  String pointsEarned(int points) {
    return '+$points points';
  }

  @override
  String get gameOver => 'Game Over!';

  @override
  String get home => 'Home';

  @override
  String get playAgain => 'Play Again';

  @override
  String combo(int count) {
    return 'Combo: ${count}x';
  }

  @override
  String get pts => 'pts';

  @override
  String errorArticleAVowel(String word) {
    return 'Use \"an\" before words starting with a vowel sound: \"$word\"';
  }

  @override
  String errorArticleAnConsonant(String word) {
    return 'Use \"a\" before words starting with a consonant sound: \"$word\"';
  }

  @override
  String errorArticlePlural(String article, String noun) {
    return '\"$article\" cannot be used with plural noun \"$noun\"';
  }

  @override
  String errorArticleUncountable(String article, String noun) {
    return '\"$article\" cannot be used with uncountable noun \"$noun\"';
  }

  @override
  String get errorSvAgreement => 'Subject-verb agreement error';

  @override
  String get errorAdjOrder => 'Incorrect adjective order';

  @override
  String get errorInvalidStructure => 'Invalid sentence structure';

  @override
  String get errorEmptySentence => 'Sentence cannot be empty';

  @override
  String get errorTooShort => 'Sentence must have at least 2 words';

  @override
  String get audio => 'Audio';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get soundEffectsDesc => 'Card sounds, judgment sounds, etc.';

  @override
  String get sfxVolume => 'SFX Volume';

  @override
  String get backgroundMusic => 'Background Music';

  @override
  String get backgroundMusicDesc => 'Menu theme, gameplay music, etc.';

  @override
  String get musicVolume => 'Music Volume';

  @override
  String get haptics => 'Haptics';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationDesc => 'Haptic feedback on game events';

  @override
  String get ok => 'OK';

  @override
  String get searchingPlayers => 'Searching for players...';

  @override
  String get roomCode => 'Room Code';

  @override
  String get you => 'You';

  @override
  String get waiting => 'Waiting...';

  @override
  String waitingForPlayers(int count) {
    return 'Waiting for $count players to join...';
  }

  @override
  String get shareRoomCode => 'Share the room code with your friends';

  @override
  String get aiDifficulty => 'Difficulty';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyEasyDesc => 'Relaxed — good for a first game';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyMediumDesc => 'A fair match';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyHardDesc => 'The AI plays to win';

  @override
  String get turnStepDraw => '1  Draw';

  @override
  String get turnStepAction => '2  Play';

  @override
  String get cardsLeft => 'left';

  @override
  String get soundOff => 'Mute';

  @override
  String get soundOn => 'Unmute';

  @override
  String get opponentThinking => 'Thinking…';

  @override
  String get pickCardToDiscard => 'Tap the card you want to throw away';

  @override
  String get cancel => 'Cancel';

  @override
  String get drawNewCard => 'New card';

  @override
  String deckRemaining(int count) {
    return '$count left';
  }

  @override
  String get discardPile => 'Thrown away';

  @override
  String get discardPileEmpty => 'Nothing here';

  @override
  String get takeIt => 'Take it';

  @override
  String get completeSentence => 'Make a sentence';

  @override
  String get needTwoCards => 'Put down two or more cards';

  @override
  String get discardACard => 'Throw a card away';

  @override
  String get winner => 'Winner';

  @override
  String cardsLeftLabel(int count) {
    return '$count cards left';
  }

  @override
  String get jumpDesc => 'Skips the next player\'s turn.';

  @override
  String get use => 'Use it';

  @override
  String get stealDesc => 'Pick someone, then pick a card to give them.';

  @override
  String get stealFromWho => 'Who do you take from?';

  @override
  String get stealGiveWhat => 'Which card do you give?';
}
