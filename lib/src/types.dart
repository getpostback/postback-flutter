enum PostbackEventType {
  sessionStart,
  login,
  signUp,
  register,
  purchase,
  subscribe,
  startTrial,
  addPaymentInfo,
  addToCart,
  addToWishlist,
  initiateCheckout,
  viewContent,
  viewItem,
  search,
  share,
  tutorialComplete,
  achieveLevel,
  levelStart,
  levelComplete,
  custom,
}

const Map<PostbackEventType, String> postbackEventTypeValues = {
  PostbackEventType.sessionStart: 'session_start',
  PostbackEventType.login: 'login',
  PostbackEventType.signUp: 'sign_up',
  PostbackEventType.register: 'register',
  PostbackEventType.purchase: 'purchase',
  PostbackEventType.subscribe: 'subscribe',
  PostbackEventType.startTrial: 'start_trial',
  PostbackEventType.addPaymentInfo: 'add_payment_info',
  PostbackEventType.addToCart: 'add_to_cart',
  PostbackEventType.addToWishlist: 'add_to_wishlist',
  PostbackEventType.initiateCheckout: 'initiate_checkout',
  PostbackEventType.viewContent: 'view_content',
  PostbackEventType.viewItem: 'view_item',
  PostbackEventType.search: 'search',
  PostbackEventType.share: 'share',
  PostbackEventType.tutorialComplete: 'tutorial_complete',
  PostbackEventType.achieveLevel: 'achieve_level',
  PostbackEventType.levelStart: 'level_start',
  PostbackEventType.levelComplete: 'level_complete',
  PostbackEventType.custom: 'custom',
};

enum GoogleAdsConsentStatus {
  granted,
  denied,
  unspecified,
}

const Map<GoogleAdsConsentStatus, String> googleAdsConsentStatusValues = {
  GoogleAdsConsentStatus.granted: 'GRANTED',
  GoogleAdsConsentStatus.denied: 'DENIED',
  GoogleAdsConsentStatus.unspecified: 'UNSPECIFIED',
};

class GoogleAdsConsent {
  const GoogleAdsConsent({required this.adUserData});

  final GoogleAdsConsentStatus adUserData;

  Map<String, Object?> toJson() => {
        'adUserData': googleAdsConsentStatusValues[adUserData],
      };
}

class PostbackConfig {
  const PostbackConfig({
    required this.apiKey,
    this.apiUrl = 'https://api.postback.sh',
    this.enableAppleAdsAttribution = true,
    this.isDebug = false,
    int? logLevel,
    this.customerUserId,
    this.autoTrackSessions = true,
    this.autoRefreshAttribution = true,
    this.eventTrackingEnabled = true,
    this.googleAdsConsent,
  })  : logLevel = logLevel ?? (isDebug ? 0 : 2),
        assert(logLevel == null || (logLevel >= 0 && logLevel <= 3),
            'logLevel must be between 0 and 3.');

  final String apiKey;
  final String apiUrl;
  final bool enableAppleAdsAttribution;
  final bool isDebug;
  final int logLevel;
  final String? customerUserId;
  final bool autoTrackSessions;
  final bool autoRefreshAttribution;
  final bool eventTrackingEnabled;
  final GoogleAdsConsent? googleAdsConsent;
}

class AttributionResult {
  const AttributionResult({
    required this.isAttributed,
    this.source,
    this.matchType,
    this.link,
    this.appleAds,
    this.confidence,
    this.campaignName,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.utmTerm,
  });

  factory AttributionResult.fromJson(Map<dynamic, dynamic> json) {
    final isAttributed =
        json['isAttributed'] as bool? ?? json['source'] != 'organic';
    return AttributionResult(
      isAttributed: isAttributed,
      source: json['source'] as String? ?? (isAttributed ? null : 'organic'),
      matchType: json['matchType'] as String?,
      link: (json['link'] as Map?)?.cast<dynamic, dynamic>(),
      appleAds: (json['appleAds'] as Map?)?.cast<dynamic, dynamic>(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      campaignName: json['campaignName'] as String?,
      utmSource: json['utmSource'] as String?,
      utmMedium: json['utmMedium'] as String?,
      utmCampaign: json['utmCampaign'] as String?,
      utmContent: json['utmContent'] as String?,
      utmTerm: json['utmTerm'] as String?,
    );
  }

  final bool isAttributed;
  final String? source;
  final String? matchType;
  final Map<dynamic, dynamic>? link;
  final Map<dynamic, dynamic>? appleAds;
  final double? confidence;
  final String? campaignName;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmContent;
  final String? utmTerm;
}

class TestEventResult {
  const TestEventResult({required this.success, required this.message});
  final bool success;
  final String message;
}
