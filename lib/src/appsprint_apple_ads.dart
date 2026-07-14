import 'dart:io' show Platform;

import 'appsprint.dart';
import 'types.dart';

class AppSprintAppleAds {
  AppSprintAppleAds._();

  static Future<bool> configure(
    String apiKey, {
    String? apiUrl,
    bool isDebug = false,
  }) {
    _assertIos();
    return AppSprint.instance.configure(
      buildConfig(apiKey, apiUrl: apiUrl, isDebug: isDebug),
    );
  }

  static Future<String?> getAppSprintId() {
    _assertIos();
    return AppSprint.instance.getAppSprintId();
  }

  static Future<Map<String, String>> getAttributionParams() {
    _assertIos();
    return AppSprint.instance.getAttributionParams();
  }

  static Future<AttributionResult?> getAttribution() {
    _assertIos();
    return AppSprint.instance.getAttribution();
  }

  static Future<AttributionResult?> refreshAttribution() {
    _assertIos();
    return AppSprint.instance.refreshAttribution();
  }

  static AppSprintConfig buildConfig(
    String apiKey, {
    String? apiUrl,
    bool isDebug = false,
  }) {
    return AppSprintConfig(
      apiKey: apiKey,
      apiUrl: apiUrl ?? 'https://api.appsprint.app',
      enableAppleAdsAttribution: true,
      isDebug: isDebug,
      customerUserId: null,
      autoTrackSessions: true,
      autoRefreshAttribution: false,
      eventTrackingEnabled: true,
    );
  }

  static void _assertIos() {
    if (!Platform.isIOS) {
      throw UnsupportedError(
        'AppSprintAppleAds is only supported on iOS.',
      );
    }
  }
}
