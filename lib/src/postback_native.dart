import 'package:flutter/services.dart';

import 'types.dart';

class PostbackNative {
  PostbackNative._();

  static const MethodChannel _channel =
      MethodChannel('postback_flutter/native');

  // Core SDK

  static Future<bool> configure(Map<String, dynamic> config) async {
    return await _channel.invokeMethod<bool>('configure', config) ?? false;
  }

  static Future<bool> sendEvent(Map<String, dynamic> args) async {
    return await _channel.invokeMethod<bool>('sendEvent', args) ?? false;
  }

  static Future<Map<dynamic, dynamic>?> sendTestEvent() {
    return _channel.invokeMethod<Map<dynamic, dynamic>>('sendTestEvent');
  }

  static Future<void> flush() {
    return _channel.invokeMethod<void>('flush');
  }

  static Future<void> clearData() {
    return _channel.invokeMethod<void>('clearData');
  }

  static Future<void> setCustomerUserId(String userId) {
    return _channel.invokeMethod<void>('setCustomerUserId', {'userId': userId});
  }

  static Future<Map<dynamic, dynamic>?> refreshAttribution() {
    return _channel.invokeMethod<Map<dynamic, dynamic>>('refreshAttribution');
  }

  static Future<bool> enableAppleAdsAttribution() async {
    return await _channel.invokeMethod<bool>('enableAppleAdsAttribution') ??
        false;
  }

  static Future<String?> getPostbackId() {
    return _channel.invokeMethod<String>('getPostbackId');
  }

  static Future<Map<dynamic, dynamic>?> getAttribution() {
    return _channel.invokeMethod<Map<dynamic, dynamic>>('getAttribution');
  }

  static Future<Map<String, String>> getAttributionParams() async {
    final result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('getAttributionParams');
    final params = <String, String>{};
    (result ?? const <dynamic, dynamic>{}).forEach((key, value) {
      if (key != null && value != null) {
        params[key.toString()] = value.toString();
      }
    });
    return params;
  }

  static Future<bool> isInitialized() async {
    return await _channel.invokeMethod<bool>('isInitialized') ?? false;
  }

  static Future<bool> isSdkDisabled() async {
    return await _channel.invokeMethod<bool>('isSdkDisabled') ?? false;
  }

  static Future<void> destroy() {
    return _channel.invokeMethod<void>('destroy');
  }

  // Utility

  static Future<DeviceInfo> getDeviceInfo() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
    return DeviceInfo.fromJson(result ?? const <dynamic, dynamic>{});
  }

  static Future<String?> getWebViewUserAgent() {
    return _channel.invokeMethod<String>('getWebViewUserAgent');
  }

  static Future<String?> getAdServicesToken() {
    return _channel.invokeMethod<String>('getAdServicesToken');
  }

  static Future<bool> requestTrackingAuthorization() async {
    return await _channel.invokeMethod<bool>('requestTrackingAuthorization') ??
        false;
  }
}
