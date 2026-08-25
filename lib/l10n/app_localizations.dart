import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dripple'**
  String get appTitle;

  /// No description provided for @wordCardBattle.
  ///
  /// In en, this message translates to:
  /// **'Word Card Battle'**
  String get wordCardBattle;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get play;

  /// No description provided for @character.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get character;

  /// No description provided for @ranking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @selectMode.
  ///
  /// In en, this message translates to:
  /// **'Select Mode'**
  String get selectMode;

  /// No description provided for @aiBattle.
  ///
  /// In en, this message translates to:
  /// **'AI Battle'**
  String get aiBattle;

  /// No description provided for @aiBattleDesc.
  ///
  /// In en, this message translates to:
  /// **'Play against AI opponents'**
  String get aiBattleDesc;

  /// No description provided for @onlineBattle.
  ///
  /// In en, this message translates to:
  /// **'Online Battle'**
  String get onlineBattle;

  /// No description provided for @onlineBattleDesc.
  ///
  /// In en, this message translates to:
  /// **'Random matchmaking'**
  String get onlineBattleDesc;

  /// No description provided for @friendBattle.
  ///
  /// In en, this message translates to:
  /// **'Friend Battle'**
  String get friendBattle;

  /// No description provided for @friendBattleDesc.
  ///
  /// In en, this message translates to:
  /// **'Invite via code/link'**
  String get friendBattleDesc;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get comingSoon;

  /// No description provided for @playerCount.
  ///
  /// In en, this message translates to:
  /// **'Player Count'**
  String get playerCount;

  /// No description provided for @nPlayers.
  ///
  /// In en, this message translates to:
  /// **'{count} Players'**
  String nPlayers(int count);

  /// No description provided for @roundIndicator.
  ///
  /// In en, this message translates to:
  /// **'Round {current}/{total}'**
  String roundIndicator(int current, int total);

  /// No description provided for @nCards.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String nCards(int count);

  /// No description provided for @sentenceZone.
  ///
  /// In en, this message translates to:
  /// **'Sentence Zone'**
  String get sentenceZone;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect!'**
  String get incorrect;

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} points'**
  String pointsEarned(int points);

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over!'**
  String get gameOver;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @combo.
  ///
  /// In en, this message translates to:
  /// **'Combo: {count}x'**
  String combo(int count);

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pts;

  /// No description provided for @errorArticleAVowel.
  ///
  /// In en, this message translates to:
  /// **'Use \"an\" before words starting with a vowel sound: \"{word}\"'**
  String errorArticleAVowel(String word);

  /// No description provided for @errorArticleAnConsonant.
  ///
  /// In en, this message translates to:
  /// **'Use \"a\" before words starting with a consonant sound: \"{word}\"'**
  String errorArticleAnConsonant(String word);

  /// No description provided for @errorArticlePlural.
  ///
  /// In en, this message translates to:
  /// **'\"{article}\" cannot be used with plural noun \"{noun}\"'**
  String errorArticlePlural(String article, String noun);

  /// No description provided for @errorArticleUncountable.
  ///
  /// In en, this message translates to:
  /// **'\"{article}\" cannot be used with uncountable noun \"{noun}\"'**
  String errorArticleUncountable(String article, String noun);

  /// No description provided for @errorSvAgreement.
  ///
  /// In en, this message translates to:
  /// **'Subject-verb agreement error'**
  String get errorSvAgreement;

  /// No description provided for @errorAdjOrder.
  ///
  /// In en, this message translates to:
  /// **'Incorrect adjective order'**
  String get errorAdjOrder;

  /// No description provided for @errorInvalidStructure.
  ///
  /// In en, this message translates to:
  /// **'Invalid sentence structure'**
  String get errorInvalidStructure;

  /// No description provided for @errorEmptySentence.
  ///
  /// In en, this message translates to:
  /// **'Sentence cannot be empty'**
  String get errorEmptySentence;

  /// No description provided for @errorTooShort.
  ///
  /// In en, this message translates to:
  /// **'Sentence must have at least 2 words'**
  String get errorTooShort;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @soundEffectsDesc.
  ///
  /// In en, this message translates to:
  /// **'Card sounds, judgment sounds, etc.'**
  String get soundEffectsDesc;

  /// No description provided for @sfxVolume.
  ///
  /// In en, this message translates to:
  /// **'SFX Volume'**
  String get sfxVolume;

  /// No description provided for @backgroundMusic.
  ///
  /// In en, this message translates to:
  /// **'Background Music'**
  String get backgroundMusic;

  /// No description provided for @backgroundMusicDesc.
  ///
  /// In en, this message translates to:
  /// **'Menu theme, gameplay music, etc.'**
  String get backgroundMusicDesc;

  /// No description provided for @musicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music Volume'**
  String get musicVolume;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback on game events'**
  String get vibrationDesc;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @searchingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Searching for players...'**
  String get searchingPlayers;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Room Code'**
  String get roomCode;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get waiting;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {count} players to join...'**
  String waitingForPlayers(int count);

  /// No description provided for @shareRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Share the room code with your friends'**
  String get shareRoomCode;

  /// No description provided for @aiDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get aiDifficulty;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyEasyDesc.
  ///
  /// In en, this message translates to:
  /// **'Relaxed — good for a first game'**
  String get difficultyEasyDesc;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyMediumDesc.
  ///
  /// In en, this message translates to:
  /// **'A fair match'**
  String get difficultyMediumDesc;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyHardDesc.
  ///
  /// In en, this message translates to:
  /// **'The AI plays to win'**
  String get difficultyHardDesc;

  /// No description provided for @turnStepDraw.
  ///
  /// In en, this message translates to:
  /// **'1  Draw'**
  String get turnStepDraw;

  /// No description provided for @turnStepAction.
  ///
  /// In en, this message translates to:
  /// **'2  Play'**
  String get turnStepAction;

  /// No description provided for @cardsLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get cardsLeft;

  /// No description provided for @soundOff.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get soundOff;

  /// No description provided for @soundOn.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get soundOn;

  /// No description provided for @opponentThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get opponentThinking;

  /// No description provided for @pickCardToDiscard.
  ///
  /// In en, this message translates to:
  /// **'Tap the card you want to throw away'**
  String get pickCardToDiscard;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @drawNewCard.
  ///
  /// In en, this message translates to:
  /// **'New card'**
  String get drawNewCard;

  /// No description provided for @deckRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String deckRemaining(int count);

  /// No description provided for @discardPile.
  ///
  /// In en, this message translates to:
  /// **'Thrown away'**
  String get discardPile;

  /// No description provided for @discardPileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get discardPileEmpty;

  /// No description provided for @takeIt.
  ///
  /// In en, this message translates to:
  /// **'Take it'**
  String get takeIt;

  /// No description provided for @completeSentence.
  ///
  /// In en, this message translates to:
  /// **'Make a sentence'**
  String get completeSentence;

  /// No description provided for @needTwoCards.
  ///
  /// In en, this message translates to:
  /// **'Put down two or more cards'**
  String get needTwoCards;

  /// No description provided for @discardACard.
  ///
  /// In en, this message translates to:
  /// **'Throw a card away'**
  String get discardACard;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @cardsLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} cards left'**
  String cardsLeftLabel(int count);

  /// No description provided for @jumpDesc.
  ///
  /// In en, this message translates to:
  /// **'Skips the next player\'s turn.'**
  String get jumpDesc;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get use;

  /// No description provided for @stealDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick someone, then pick a card to give them.'**
  String get stealDesc;

  /// No description provided for @stealFromWho.
  ///
  /// In en, this message translates to:
  /// **'Who do you take from?'**
  String get stealFromWho;

  /// No description provided for @stealGiveWhat.
  ///
  /// In en, this message translates to:
  /// **'Which card do you give?'**
  String get stealGiveWhat;

  /// No description provided for @sentenceZoneHand.
  ///
  /// In en, this message translates to:
  /// **'My cards'**
  String get sentenceZoneHand;

  /// No description provided for @sentenceZoneMake.
  ///
  /// In en, this message translates to:
  /// **'Build your sentence here'**
  String get sentenceZoneMake;

  /// No description provided for @sentenceZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Push cards up\nto build a sentence'**
  String get sentenceZoneHint;

  /// No description provided for @cannotDiscardJustTaken.
  ///
  /// In en, this message translates to:
  /// **'You just took that card — you can\'t throw it away this turn'**
  String get cannotDiscardJustTaken;

  /// No description provided for @tapDeckToDraw.
  ///
  /// In en, this message translates to:
  /// **'Tap the deck to take a card'**
  String get tapDeckToDraw;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
