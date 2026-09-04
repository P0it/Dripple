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
  String get modeGroupSolo => 'Alone';

  @override
  String get modeGroupFriends => 'With friends';

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

  @override
  String get sentenceZoneHand => 'My cards';

  @override
  String get sentenceZoneMake => 'Build your sentence here';

  @override
  String get sentenceZoneHint =>
      'Push cards up to build a sentence\nthe button below finishes it';

  @override
  String get cannotDiscardJustTaken =>
      'You just took that card — you can\'t throw it away this turn';

  @override
  String get tapDeckToDraw => 'Tap the deck to take a card';

  @override
  String get dragToDiscard =>
      'Drag a card onto the discard pile to throw it away';

  @override
  String get passTurn => 'Pass';

  @override
  String get passTurnSub => 'Keep your cards';

  @override
  String get pileDeck => 'Deck';

  @override
  String get pileDiscard => 'Discard';

  @override
  String get tutorial => 'Learn to play';

  @override
  String get tutorialDesc => 'One minute, on your own';

  @override
  String get tutorialWelcome =>
      'Cards make sentences. Let\'s build one together — it takes a minute.';

  @override
  String get tutorialDeck =>
      'This is the deck. Everyone takes a card from here.';

  @override
  String get tutorialDiscard =>
      'Cards nobody wants land here, face up. You may take the top one instead.';

  @override
  String get tutorialDraw => 'Your turn starts with one card. Tap the deck.';

  @override
  String get tutorialSort =>
      'These are your cards. Slide one sideways to tidy your hand.';

  @override
  String get tutorialBuild =>
      'Push a card up here to play it. Push up two or more.';

  @override
  String get tutorialReorder =>
      'Wrong order? Drag a card along the line to move it. Tap it to take it back.';

  @override
  String get tutorialSubmit => 'Looks right? Press Complete sentence.';

  @override
  String get tutorialDone => 'That\'s the whole game. Ready for a real one?';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialQuit => 'Leave';

  @override
  String get tutorialPlayForReal => 'Play for real';

  @override
  String get tutorialTryAgain =>
      'Not a sentence yet — change the order, or take a card back and try another.';

  @override
  String get tutorialFirstTime => 'First time? Learn to play';

  @override
  String get chooseName => 'What should we call you?';

  @override
  String get chooseNameHint => 'Your name at the table';

  @override
  String get chooseNameSave => 'That\'s me';

  @override
  String get createRoom => 'Make a room';

  @override
  String get createRoomDesc => 'Play with friends who have your code';

  @override
  String get joinRoom => 'Join a room';

  @override
  String get joinRoomDesc => 'Type the code a friend gave you';

  @override
  String get enterRoomCode => 'Room code';

  @override
  String get join => 'Join';

  @override
  String get startGame => 'Start';

  @override
  String get leaveRoom => 'Leave';

  @override
  String get emptySeat => 'Empty seat';

  @override
  String get seatLeft => 'Left the game';

  @override
  String get hostLabel => 'Host';

  @override
  String get waitingForHost => 'Waiting for the host to start';

  @override
  String get needTwoPlayers => 'Two players are needed to start';

  @override
  String get yourTurnBanner => 'Your turn';

  @override
  String seatTurnBanner(String name) {
    return '$name\'s turn';
  }

  @override
  String get connectionLost => 'No connection to the game';

  @override
  String get errorNotYourTurn => 'It\'s not your turn yet';

  @override
  String get errorRoomFull => 'That room is full';

  @override
  String get errorNoSuchRoom => 'No room with that code';

  @override
  String get errorAlreadyStarted => 'That game has already started';

  @override
  String get errorOffline => 'Can\'t reach the game right now';

  @override
  String get errorGeneric => 'That didn\'t work';
}
