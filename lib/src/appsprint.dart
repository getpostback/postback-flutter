import 'appsprint_native.dart';
import 'types.dart';

class AppSprint {
  AppSprint._();

  static final AppSprint instance = AppSprint._();

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
    GoogleAdsConsent? googleAdsConsent,
  }) {
    final AppSprintConfig normalizedConfig;
    if (config is AppSprintConfig) {
      normalizedConfig = config;
    } else if (config is String) {
      normalizedConfig = AppSprintConfig(
        apiKey: config,
        apiUrl: apiUrl ?? endpointBaseUrl ?? 'https://api.appsprint.app',
        enableAppleAdsAttribution: enableAppleAdsAttribution,
        isDebug: isDebug,
        logLevel: logLevel,
        customerUserId: customerUserId,
        autoTrackSessions: autoTrackSessions,
        autoRefreshAttribution: autoRefreshAttribution,
        googleAdsConsent: googleAdsConsent,
      );
    } else {
      throw ArgumentError.value(
        config,
        'config',
        'AppSprint.configure requires an AppSprintConfig or apiKey string.',
      );
    }

    if (normalizedConfig.apiKey.trim().isEmpty) {
      throw ArgumentError.value(
        normalizedConfig.apiKey,
        'apiKey',
        'AppSprint.configure requires a non-empty apiKey.',
      );
    }

    return AppSprintNative.configure({
      'apiKey': normalizedConfig.apiKey,
      'apiUrl': normalizedConfig.apiUrl,
      'enableAppleAdsAttribution': normalizedConfig.enableAppleAdsAttribution,
      'isDebug': normalizedConfig.isDebug,
      'logLevel': normalizedConfig.logLevel,
      'customerUserId': normalizedConfig.customerUserId,
      'autoTrackSessions': normalizedConfig.autoTrackSessions,
      'autoRefreshAttribution': normalizedConfig.autoRefreshAttribution,
      if (normalizedConfig.googleAdsConsent != null)
        'googleAdsConsent': normalizedConfig.googleAdsConsent!.toJson(),
    });
  }

  Future<bool> sendEvent(AppSprintEventType eventType,
      {String? name, Map<String, Object?>? params}) {
    final googleAdsConsent = _googleAdsConsentValue(params);
    return AppSprintNative.sendEvent({
      'eventType': appSprintEventTypeValues[eventType],
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
    final result = await AppSprintNative.sendTestEvent();
    return TestEventResult(
      success: result?['success'] as bool? ?? false,
      message: result?['message'] as String? ?? 'Unknown error',
    );
  }

  Future<void> flush() => AppSprintNative.flush();

  Future<void> clearData() => AppSprintNative.clearData();

  Future<void> setCustomerUserId(String userId) =>
      AppSprintNative.setCustomerUserId(userId);

  Future<AttributionResult?> refreshAttribution() async {
    final raw = await AppSprintNative.refreshAttribution();
    if (raw == null) return null;
    return AttributionResult.fromJson(raw);
  }

  Future<bool> enableAppleAdsAttribution() =>
      AppSprintNative.enableAppleAdsAttribution();

  Future<String?> getAppSprintId() => AppSprintNative.getAppSprintId();

  Future<AttributionResult?> getAttribution() async {
    final raw = await AppSprintNative.getAttribution();
    if (raw == null) return null;
    return AttributionResult.fromJson(raw);
  }

  Future<Map<String, String>> getAttributionParams() =>
      AppSprintNative.getAttributionParams();

  Future<bool> isInitialized() => AppSprintNative.isInitialized();

  Future<bool> isSdkDisabled() => AppSprintNative.isSdkDisabled();

  Future<void> destroy() => AppSprintNative.destroy();
}
