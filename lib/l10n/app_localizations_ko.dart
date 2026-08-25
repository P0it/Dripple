// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Dripple';

  @override
  String get wordCardBattle => '단어 카드 배틀';

  @override
  String get play => '플레이';

  @override
  String get character => '캐릭터';

  @override
  String get ranking => '랭킹';

  @override
  String get settings => '설정';

  @override
  String get selectMode => '모드 선택';

  @override
  String get aiBattle => 'AI 대전';

  @override
  String get aiBattleDesc => 'AI 상대와 대전';

  @override
  String get onlineBattle => '온라인 대전';

  @override
  String get onlineBattleDesc => '랜덤 매칭';

  @override
  String get friendBattle => '친구 대전';

  @override
  String get friendBattleDesc => '코드/링크로 초대';

  @override
  String get comingSoon => '준비 중';

  @override
  String get playerCount => '플레이어 수';

  @override
  String nPlayers(int count) {
    return '$count명';
  }

  @override
  String roundIndicator(int current, int total) {
    return '라운드 $current/$total';
  }

  @override
  String nCards(int count) {
    return '카드 $count장';
  }

  @override
  String get sentenceZone => '문장 영역';

  @override
  String get draw => '뽑기';

  @override
  String get undo => '되돌리기';

  @override
  String get submit => '제출';

  @override
  String get correct => '정답!';

  @override
  String get incorrect => '오답!';

  @override
  String pointsEarned(int points) {
    return '+$points점';
  }

  @override
  String get gameOver => '게임 종료!';

  @override
  String get home => '홈';

  @override
  String get playAgain => '다시 하기';

  @override
  String combo(int count) {
    return '콤보: ${count}x';
  }

  @override
  String get pts => '점';

  @override
  String errorArticleAVowel(String word) {
    return '모음으로 시작하는 단어 \"$word\" 앞에는 \"an\"을 사용하세요';
  }

  @override
  String errorArticleAnConsonant(String word) {
    return '자음으로 시작하는 단어 \"$word\" 앞에는 \"a\"를 사용하세요';
  }

  @override
  String errorArticlePlural(String article, String noun) {
    return '\"$article\"는 복수 명사 \"$noun\"와 함께 사용할 수 없습니다';
  }

  @override
  String errorArticleUncountable(String article, String noun) {
    return '\"$article\"는 불가산 명사 \"$noun\"와 함께 사용할 수 없습니다';
  }

  @override
  String get errorSvAgreement => '주어-동사 일치 오류';

  @override
  String get errorAdjOrder => '형용사 순서가 올바르지 않습니다';

  @override
  String get errorInvalidStructure => '잘못된 문장 구조입니다';

  @override
  String get errorEmptySentence => '문장을 입력해주세요';

  @override
  String get errorTooShort => '문장은 최소 2개의 단어가 필요합니다';

  @override
  String get audio => '오디오';

  @override
  String get soundEffects => '효과음';

  @override
  String get soundEffectsDesc => '카드 소리, 판정 소리 등';

  @override
  String get sfxVolume => '효과음 볼륨';

  @override
  String get backgroundMusic => '배경 음악';

  @override
  String get backgroundMusicDesc => '메뉴 테마, 게임 음악 등';

  @override
  String get musicVolume => '음악 볼륨';

  @override
  String get haptics => '햅틱';

  @override
  String get vibration => '진동';

  @override
  String get vibrationDesc => '게임 이벤트 시 햅틱 피드백';

  @override
  String get ok => '확인';

  @override
  String get searchingPlayers => '플레이어 검색 중...';

  @override
  String get roomCode => '방 코드';

  @override
  String get you => '나';

  @override
  String get waiting => '대기 중...';

  @override
  String waitingForPlayers(int count) {
    return '$count명의 플레이어를 기다리는 중...';
  }

  @override
  String get shareRoomCode => '방 코드를 친구에게 공유하세요';

  @override
  String get aiDifficulty => '난이도';

  @override
  String get difficultyEasy => '쉬움';

  @override
  String get difficultyEasyDesc => '느긋하게 — 처음이라면 여기부터';

  @override
  String get difficultyMedium => '보통';

  @override
  String get difficultyMediumDesc => '해볼 만한 상대';

  @override
  String get difficultyHard => '어려움';

  @override
  String get difficultyHardDesc => 'AI가 이기려고 둡니다';

  @override
  String get turnStepDraw => '1  뽑기';

  @override
  String get turnStepAction => '2  내기';

  @override
  String get cardsLeft => '장';

  @override
  String get soundOff => '소리 끄기';

  @override
  String get soundOn => '소리 켜기';

  @override
  String get opponentThinking => '상대가 생각하고 있어요…';

  @override
  String get pickCardToDiscard => '버릴 카드를 톡 눌러요';

  @override
  String get cancel => '취소';

  @override
  String get drawNewCard => '새 카드';

  @override
  String deckRemaining(int count) {
    return '$count장 남음';
  }

  @override
  String get discardPile => '버린 카드';

  @override
  String get discardPileEmpty => '없어요';

  @override
  String get takeIt => '가져오기';

  @override
  String get completeSentence => '문장 완성';

  @override
  String get needTwoCards => '카드를 2장 이상 놓아요';

  @override
  String get discardACard => '카드 버리기';

  @override
  String get winner => '우승';

  @override
  String cardsLeftLabel(int count) {
    return '$count장 남음';
  }

  @override
  String get jumpDesc => '다음 사람의 차례를 건너뜁니다.';

  @override
  String get use => '사용하기';

  @override
  String get stealDesc => '상대를 고르고, 대신 줄 카드를 고르세요.';

  @override
  String get stealFromWho => '누구에게서 가져올까요?';

  @override
  String get stealGiveWhat => '어떤 카드를 줄까요?';

  @override
  String get sentenceZoneHand => '내 카드';

  @override
  String get sentenceZoneMake => '문장 만드는 곳';

  @override
  String get sentenceZoneHint => '카드를 위로 밀어\n문장을 만들어요';

  @override
  String get cannotDiscardJustTaken => '방금 가져온 카드예요. 이번 턴에는 못 버려요';

  @override
  String get tapDeckToDraw => '덱을 눌러 카드를 한 장 가져와요';
}
