import 'postback_native.dart';
import 'types.dart';

class Postback {
  Postback._();

  static final Postback instance = Postback._();

  Future<bool> configure(
    Object config, {
    String? endpointBaseUrl,
    String? apiUrl,
    bool enableAppleAdsAttribution = true,
    bool isDebug = false,
    int? logLevel,
    String? customerUserId,
    bool autoTrackSessions = true,
    bool autoRefreshAttribution = true,
    bool eventTrackingEnabled = true,
    GoogleAdsConsent? googleAdsConsent,
  }) {
    final PostbackConfig normalizedConfig;
    if (config is PostbackConfig) {
      normalizedConfig = config;
    } else if (config is String) {
      normalizedConfig = PostbackConfig(
        apiKey: config,
        apiUrl: apiUrl ?? endpointBaseUrl ?? 'https://api.postback.sh',
        enableAppleAdsAttribution: enableAppleAdsAttribution,
        isDebug: isDebug,
        logLevel: logLevel,
        customerUserId: customerUserId,
        autoTrackSessions: autoTrackSessions,
        autoRefreshAttribution: autoRefreshAttribution,
        eventTrackingEnabled: eventTrackingEnabled,
        googleAdsConsent: googleAdsConsent,
      );
    } else {
      throw ArgumentError.value(
        config,
        'config',
        'Postback.configure requires a PostbackConfig or apiKey string.',
      );
    }

    if (normalizedConfig.apiKey.trim().isEmpty) {
      throw ArgumentError.value(
        normalizedConfig.apiKey,
        'apiKey',
        'Postback.configure requires a non-empty apiKey.',
      );
    }

    return PostbackNative.configure({
      'apiKey': normalizedConfig.apiKey,
      'apiUrl': normalizedConfig.apiUrl,
      'enableAppleAdsAttribution': normalizedConfig.enableAppleAdsAttribution,
      'isDebug': normalizedConfig.isDebug,
      'logLevel': normalizedConfig.logLevel,
      'customerUserId': normalizedConfig.customerUserId,
      'autoTrackSessions': normalizedConfig.autoTrackSessions,
      'autoRefreshAttribution': normalizedConfig.autoRefreshAttribution,
      'eventTrackingEnabled': normalizedConfig.eventTrackingEnabled,
      if (normalizedConfig.googleAdsConsent != null)
        'googleAdsConsent': normalizedConfig.googleAdsConsent!.toJson(),
    });
  }

  Future<bool> sendEvent(PostbackEventType eventType,
      {String? name, Map<String, Object?>? params}) {
    final googleAdsConsent = _googleAdsConsentValue(params);
    return PostbackNative.sendEvent({
      'eventType': postbackEventTypeValues[eventType],
      'name': name,
      'revenue': params?['revenue'] ?? params?['price'],
      'currency': params?['currency'],
      if (googleAdsConsent != null)
        'googleAdsConsent': googleAdsConsent.toJson(),
      'parameters': _eventParametersWithoutHoistedFields(params),
    });
  }

  static Map<String, Object?>? _eventParametersWithoutHoistedFields(
      Map<String, Object?>? params) {
    if (params == null) return null;
    final parameters = Map<String, Object?>.of(params)
      ..remove('revenue')
      ..remove('price')
      ..remove('currency')
      ..remove('googleAdsConsent')
      ..remove('googleAdsAdUserDataConsent');
    return parameters.isEmpty ? null : parameters;
  }

  static GoogleAdsConsent? _googleAdsConsentValue(
      Map<String, Object?>? params) {
    final raw = params?['googleAdsConsent'];
    if (raw is GoogleAdsConsent) {
      return raw;
    }
    if (raw is Map) {
      final status = _googleAdsConsentStatus(raw['adUserData']);
      if (status != null) {
        return GoogleAdsConsent(adUserData: status);
      }
    }
    final aliasStatus =
        _googleAdsConsentStatus(params?['googleAdsAdUserDataConsent']);
    return aliasStatus == null
        ? null
        : GoogleAdsConsent(adUserData: aliasStatus);
  }

  static GoogleAdsConsentStatus? _googleAdsConsentStatus(Object? value) {
    if (value is GoogleAdsConsentStatus) {
      return value;
    }
    if (value is! String) {
      return null;
    }
    switch (value.trim().toUpperCase()) {
      case 'GRANTED':
        return GoogleAdsConsentStatus.granted;
      case 'DENIED':
        return GoogleAdsConsentStatus.denied;
      case 'UNSPECIFIED':
        return GoogleAdsConsentStatus.unspecified;
      default:
        return null;
    }
  }

  Future<TestEventResult> sendTestEvent() async {
    final result = await PostbackNative.sendTestEvent();
    return TestEventResult(
      success: result?['success'] as bool? ?? false,
      message: result?['message'] as String? ?? 'Unknown error',
    );
  }

  Future<void> flush() => PostbackNative.flush();

  Future<void> clearData() => PostbackNative.clearData();

  Future<void> setCustomerUserId(String userId) =>
      PostbackNative.setCustomerUserId(userId);

  Future<AttributionResult?> refreshAttribution() async {
    final raw = await PostbackNative.refreshAttribution();
    if (raw == null) return null;
    return AttributionResult.fromJson(raw);
  }

  Future<bool> enableAppleAdsAttribution() =>
      PostbackNative.enableAppleAdsAttribution();

  Future<String?> getPostbackId() => PostbackNative.getPostbackId();

  Future<AttributionResult?> getAttribution() async {
    final raw = await PostbackNative.getAttribution();
    if (raw == null) return null;
    return AttributionResult.fromJson(raw);
  }

  Future<Map<String, String>> getAttributionParams() =>
      PostbackNative.getAttributionParams();

  Future<bool> isInitialized() => PostbackNative.isInitialized();

  Future<bool> isSdkDisabled() => PostbackNative.isSdkDisabled();

  Future<void> destroy() => PostbackNative.destroy();
}
