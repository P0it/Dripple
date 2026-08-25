// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Dripple';

  @override
  String get wordCardBattle => '単語カードバトル';

  @override
  String get play => 'プレイ';

  @override
  String get character => 'キャラ';

  @override
  String get ranking => 'ランキング';

  @override
  String get settings => '設定';

  @override
  String get selectMode => 'モード選択';

  @override
  String get aiBattle => 'AI対戦';

  @override
  String get aiBattleDesc => 'AIと対戦';

  @override
  String get onlineBattle => 'オンライン対戦';

  @override
  String get onlineBattleDesc => 'ランダムマッチ';

  @override
  String get friendBattle => 'フレンド対戦';

  @override
  String get friendBattleDesc => 'コード/リンクで招待';

  @override
  String get comingSoon => '準備中';

  @override
  String get playerCount => 'プレイヤー数';

  @override
  String nPlayers(int count) {
    return '$count人';
  }

  @override
  String roundIndicator(int current, int total) {
    return 'ラウンド $current/$total';
  }

  @override
  String nCards(int count) {
    return 'カード$count枚';
  }

  @override
  String get sentenceZone => '文章エリア';

  @override
  String get draw => '引く';

  @override
  String get undo => '戻す';

  @override
  String get submit => '提出';

  @override
  String get correct => '正解！';

  @override
  String get incorrect => '不正解！';

  @override
  String pointsEarned(int points) {
    return '+$pointsポイント';
  }

  @override
  String get gameOver => 'ゲーム終了！';

  @override
  String get home => 'ホーム';

  @override
  String get playAgain => 'もう一回';

  @override
  String combo(int count) {
    return 'コンボ: ${count}x';
  }

  @override
  String get pts => '点';

  @override
  String errorArticleAVowel(String word) {
    return '母音で始まる単語「$word」の前には「an」を使います';
  }

  @override
  String errorArticleAnConsonant(String word) {
    return '子音で始まる単語「$word」の前には「a」を使います';
  }

  @override
  String errorArticlePlural(String article, String noun) {
    return '「$article」は複数名詞「$noun」と一緒に使えません';
  }

  @override
  String errorArticleUncountable(String article, String noun) {
    return '「$article」は不可算名詞「$noun」と一緒に使えません';
  }

  @override
  String get errorSvAgreement => '主語と動詞の一致エラー';

  @override
  String get errorAdjOrder => '形容詞の順序が正しくありません';

  @override
  String get errorInvalidStructure => '無効な文構造です';

  @override
  String get errorEmptySentence => '文を入力してください';

  @override
  String get errorTooShort => '文には最低2つの単語が必要です';

  @override
  String get audio => 'オーディオ';

  @override
  String get soundEffects => '効果音';

  @override
  String get soundEffectsDesc => 'カード音、判定音など';

  @override
  String get sfxVolume => '効果音の音量';

  @override
  String get backgroundMusic => 'BGM';

  @override
  String get backgroundMusicDesc => 'メニューテーマ、ゲーム音楽など';

  @override
  String get musicVolume => '音楽の音量';

  @override
  String get haptics => 'ハプティクス';

  @override
  String get vibration => 'バイブレーション';

  @override
  String get vibrationDesc => 'ゲームイベント時の振動フィードバック';

  @override
  String get ok => 'OK';

  @override
  String get searchingPlayers => 'プレイヤーを検索中...';

  @override
  String get roomCode => 'ルームコード';

  @override
  String get you => 'あなた';

  @override
  String get waiting => '待機中...';

  @override
  String waitingForPlayers(int count) {
    return '$count人のプレイヤーを待っています...';
  }

  @override
  String get shareRoomCode => 'ルームコードを友達に共有してください';

  @override
  String get aiDifficulty => '難易度';

  @override
  String get difficultyEasy => 'やさしい';

  @override
  String get difficultyEasyDesc => 'のんびり — はじめてならここから';

  @override
  String get difficultyMedium => 'ふつう';

  @override
  String get difficultyMediumDesc => 'ちょうどいい相手';

  @override
  String get difficultyHard => 'むずかしい';

  @override
  String get difficultyHardDesc => 'AIが本気で勝ちにきます';

  @override
  String get turnStepDraw => '1  ひく';

  @override
  String get turnStepAction => '2  だす';

  @override
  String get cardsLeft => '枚';

  @override
  String get soundOff => '音を消す';

  @override
  String get soundOn => '音を出す';

  @override
  String get opponentThinking => 'あいてがかんがえています…';

  @override
  String get pickCardToDiscard => 'すてるカードをタップしてね';

  @override
  String get cancel => 'キャンセル';

  @override
  String get drawNewCard => 'あたらしいカード';

  @override
  String deckRemaining(int count) {
    return 'のこり$countまい';
  }

  @override
  String get discardPile => 'すてたカード';

  @override
  String get discardPileEmpty => 'ありません';

  @override
  String get takeIt => 'とる';

  @override
  String get completeSentence => 'ぶんをつくる';

  @override
  String get needTwoCards => 'カードを2まいいじょうおいてね';

  @override
  String get discardACard => 'カードをすてる';

  @override
  String get winner => 'ゆうしょう';

  @override
  String cardsLeftLabel(int count) {
    return 'のこり$countまい';
  }

  @override
  String get jumpDesc => 'つぎのひとのばんをとばします。';

  @override
  String get use => 'つかう';

  @override
  String get stealDesc => 'あいてをえらんで、かわりにわたすカードをえらんでね。';

  @override
  String get stealFromWho => 'だれからとる？';

  @override
  String get stealGiveWhat => 'どのカードをわたす？';

  @override
  String get sentenceZoneHand => 'てふだ';

  @override
  String get sentenceZoneMake => 'ぶんを つくる ところ';

  @override
  String get sentenceZoneHint => 'カードを うえに おして\nぶんを つくろう';

  @override
  String get cannotDiscardJustTaken => 'いまとったカードだから、このターンはすてられないよ';

  @override
  String get tapDeckToDraw => 'やまをタップしてカードをとってね';

  @override
  String get dragToDiscard => 'すてるカードは すてやまに ひっぱってね';

  @override
  String get pileDeck => 'やま';

  @override
  String get pileDiscard => 'すてやま';
}
