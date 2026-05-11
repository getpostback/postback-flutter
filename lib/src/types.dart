enum AppSprintEventType {
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

const Map<AppSprintEventType, String> appSprintEventTypeValues = {
  AppSprintEventType.sessionStart: 'session_start',
  AppSprintEventType.login: 'login',
  AppSprintEventType.signUp: 'sign_up',
  AppSprintEventType.register: 'register',
  AppSprintEventType.purchase: 'purchase',
  AppSprintEventType.subscribe: 'subscribe',
  AppSprintEventType.startTrial: 'start_trial',
  AppSprintEventType.addPaymentInfo: 'add_payment_info',
  AppSprintEventType.addToCart: 'add_to_cart',
  AppSprintEventType.addToWishlist: 'add_to_wishlist',
  AppSprintEventType.initiateCheckout: 'initiate_checkout',
  AppSprintEventType.viewContent: 'view_content',
  AppSprintEventType.viewItem: 'view_item',
  AppSprintEventType.search: 'search',
  AppSprintEventType.share: 'share',
  AppSprintEventType.tutorialComplete: 'tutorial_complete',
  AppSprintEventType.achieveLevel: 'achieve_level',
  AppSprintEventType.levelStart: 'level_start',
  AppSprintEventType.levelComplete: 'level_complete',
  AppSprintEventType.custom: 'custom',
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

class AppSprintConfig {
  const AppSprintConfig({
    required this.apiKey,
    this.apiUrl = 'https://api.appsprint.app',
    this.enableAppleAdsAttribution = true,
    this.isDebug = false,
    int? logLevel,
    this.customerUserId,
    this.autoTrackSessions = true,
    this.autoRefreshAttribution = true,
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

class DeviceInfo {
  const DeviceInfo({
    this.deviceModel,
    this.screenWidth,
    this.screenHeight,
    this.locale,
    this.timezone,
    this.osVersion,
    this.appVersion,
    this.gaid,
    this.idfv,
    this.idfa,
    this.adServicesToken,
    this.attStatus,
  });
  factory DeviceInfo.fromJson(Map<dynamic, dynamic> json) {
    return DeviceInfo(
      deviceModel: json['deviceModel'] as String?,
      screenWidth: (json['screenWidth'] as num?)?.toInt(),
      screenHeight: (json['screenHeight'] as num?)?.toInt(),
      locale: json['locale'] as String?,
      timezone: json['timezone'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      gaid: json['gaid'] as String?,
      idfv: json['idfv'] as String?,
      idfa: json['idfa'] as String?,
      adServicesToken: json['adServicesToken'] as String?,
      attStatus: json['attStatus'] as String?,
    );
  }
  final String? deviceModel;
  final int? screenWidth;
  final int? screenHeight;
  final String? locale;
  final String? timezone;
  final String? osVersion;
  final String? appVersion;
  final String? gaid;
  final String? idfv;
  final String? idfa;
  final String? adServicesToken;
  final String? attStatus;
}

class TestEventResult {
  const TestEventResult({required this.success, required this.message});
  final bool success;
  final String message;
}
