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
    this.nativeScreenWidth,
    this.nativeScreenHeight,
    this.screenScale,
    this.hardwareConcurrency,
    this.processorCount,
    this.maxTouchPoints,
    this.memoryGb,
    this.lowPowerMode,
    this.batteryState,
    this.batteryLevelBucket,
    this.preferredLanguages,
    this.timezoneOffsetMinutes,
    this.deviceManufacturer,
    this.deviceBrand,
    this.deviceProduct,
    this.deviceHardware,
    this.gpuVendor,
    this.gpuRenderer,
    this.connectionType,
    this.networkType,
    this.carrierName,
    this.carrierCountryCode,
    this.mobileCountryCode,
    this.mobileNetworkCode,
    this.sdkPlatform,
    this.sdkVersion,
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
      nativeScreenWidth: (json['nativeScreenWidth'] as num?)?.toInt(),
      nativeScreenHeight: (json['nativeScreenHeight'] as num?)?.toInt(),
      screenScale: (json['screenScale'] as num?)?.toDouble(),
      hardwareConcurrency: (json['hardwareConcurrency'] as num?)?.toInt(),
      processorCount: (json['processorCount'] as num?)?.toInt(),
      maxTouchPoints: (json['maxTouchPoints'] as num?)?.toInt(),
      memoryGb: (json['memoryGb'] as num?)?.toInt(),
      lowPowerMode: json['lowPowerMode'] as bool?,
      batteryState: json['batteryState'] as String?,
      batteryLevelBucket: json['batteryLevelBucket'] as String?,
      preferredLanguages: (json['preferredLanguages'] as List<dynamic>?)
          ?.whereType<String>()
          .toList(),
      timezoneOffsetMinutes: (json['timezoneOffsetMinutes'] as num?)?.toInt(),
      deviceManufacturer: json['deviceManufacturer'] as String?,
      deviceBrand: json['deviceBrand'] as String?,
      deviceProduct: json['deviceProduct'] as String?,
      deviceHardware: json['deviceHardware'] as String?,
      gpuVendor: json['gpuVendor'] as String?,
      gpuRenderer: json['gpuRenderer'] as String?,
      connectionType: json['connectionType'] as String?,
      networkType: json['networkType'] as String?,
      carrierName: json['carrierName'] as String?,
      carrierCountryCode: json['carrierCountryCode'] as String?,
      mobileCountryCode: json['mobileCountryCode'] as String?,
      mobileNetworkCode: json['mobileNetworkCode'] as String?,
      sdkPlatform: json['sdkPlatform'] as String?,
      sdkVersion: json['sdkVersion'] as String?,
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
  final int? nativeScreenWidth;
  final int? nativeScreenHeight;
  final double? screenScale;
  final int? hardwareConcurrency;
  final int? processorCount;
  final int? maxTouchPoints;
  final int? memoryGb;
  final bool? lowPowerMode;
  final String? batteryState;
  final String? batteryLevelBucket;
  final List<String>? preferredLanguages;
  final int? timezoneOffsetMinutes;
  final String? deviceManufacturer;
  final String? deviceBrand;
  final String? deviceProduct;
  final String? deviceHardware;
  final String? gpuVendor;
  final String? gpuRenderer;
  final String? connectionType;
  final String? networkType;
  final String? carrierName;
  final String? carrierCountryCode;
  final String? mobileCountryCode;
  final String? mobileNetworkCode;
  final String? sdkPlatform;
  final String? sdkVersion;
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
