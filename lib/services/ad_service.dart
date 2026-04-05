/// Abstract ad service interface.
/// Implement with Google AdMob (google_mobile_ads package) for production.
///
/// Setup steps:
/// 1. Add google_mobile_ads to pubspec.yaml
/// 2. Configure AdMob app ID in AndroidManifest.xml and Info.plist
/// 3. Implement this interface with AdMob SDK
///
/// Ad placement plan:
/// - Banner ad: Home screen bottom
/// - Rewarded ad: After game ends, offer bonus coins for watching
/// - Interstitial: Between games (every 3rd game)
abstract class AdService {
  /// Initialize the ad SDK
  Future<void> initialize();

  /// Load and show a banner ad
  Future<void> showBanner();

  /// Hide the banner ad
  Future<void> hideBanner();

  /// Load and show a rewarded ad. Returns true if user completed watching.
  Future<bool> showRewarded();

  /// Show an interstitial ad
  Future<void> showInterstitial();

  /// Dispose all ad resources
  void dispose();
}

/// No-op ad service for development and testing
class NoOpAdService implements AdService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> showBanner() async {}

  @override
  Future<void> hideBanner() async {}

  @override
  Future<bool> showRewarded() async => false;

  @override
  Future<void> showInterstitial() async {}

  @override
  void dispose() {}
}

/// AdMob implementation stub.
/// ```dart
/// class AdMobService implements AdService {
///   BannerAd? _bannerAd;
///
///   @override
///   Future<void> initialize() async {
///     await MobileAds.instance.initialize();
///   }
///
///   @override
///   Future<bool> showRewarded() async {
///     final completer = Completer<bool>();
///     RewardedAd.load(
///       adUnitId: 'ca-app-pub-xxxxx/yyyyy',
///       request: const AdRequest(),
///       rewardedAdLoadCallback: RewardedAdLoadCallback(
///         onAdLoaded: (ad) {
///           ad.show(onUserEarnedReward: (_, reward) {
///             completer.complete(true);
///           });
///         },
///         onAdFailedToLoad: (_) => completer.complete(false),
///       ),
///     );
///     return completer.future;
///   }
/// }
/// ```
