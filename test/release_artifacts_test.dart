import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('required binary artifacts are present', () {
    const requiredPaths = <String>[
      'android/libs/postback-sdk.aar',
      'ios/PostbackSDK.xcframework/ios-arm64/PostbackSDK.framework/PostbackSDK',
      'ios/PostbackSDK.xcframework/ios-arm64/dSYMs/PostbackSDK.framework.dSYM/Contents/Resources/DWARF/PostbackSDK',
      'ios/PostbackSDK.xcframework/ios-arm64_x86_64-simulator/PostbackSDK.framework/PostbackSDK',
      'ios/PostbackSDK.xcframework/ios-arm64_x86_64-simulator/dSYMs/PostbackSDK.framework.dSYM/Contents/Resources/DWARF/PostbackSDK',
    ];

    for (final relativePath in requiredPaths) {
      expect(File(relativePath).existsSync(), isTrue,
          reason: '$relativePath should exist');
    }
  });

  test('android permissions are packaged for consumers', () {
    final manifest =
        File('android/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('android.permission.ACCESS_NETWORK_STATE'));
    expect(manifest, contains('com.google.android.gms.permission.AD_ID'));
  });

  test('iOS package supports opportunistic IDFA without an ATT dependency', () {
    final podspec = File('ios/postback_flutter.podspec').readAsStringSync();
    final binary = latin1.decode(File(
            'ios/PostbackSDK.xcframework/ios-arm64/PostbackSDK.framework/PostbackSDK')
        .readAsBytesSync());

    expect(podspec, isNot(contains('AppTrackingTransparency')));
    expect(podspec, contains("'AdSupport'"));
    expect(podspec, contains("'Security'"));
    expect(podspec, contains("s.weak_frameworks = 'AdServices', 'StoreKit'"));
    expect(binary,
        contains('/System/Library/Frameworks/AdSupport.framework/AdSupport'));
    expect(binary, isNot(contains('AppTrackingTransparency.framework')));
    expect(binary,
        contains('/System/Library/Frameworks/Security.framework/Security'));
    expect(binary,
        contains('/System/Library/Frameworks/StoreKit.framework/StoreKit'));
    expect(binary, isNot(contains('ATTrackingManager')));
    expect(binary, isNot(contains('requestTrackingAuthorization')));
  });

  test('iOS privacy manifest declares tracking without tracking domains', () {
    final manifest = File(
            'ios/PostbackSDK.xcframework/ios-arm64/PostbackSDK.framework/PrivacyInfo.xcprivacy')
        .readAsStringSync();

    expect(
        manifest,
        matches(RegExp(r'<key>NSPrivacyTracking</key>\s*<true\s*/>',
            multiLine: true)));
    expect(manifest, isNot(contains('NSPrivacyTrackingDomains')));
  });

  test('iOS package exposes its signal bundle without carrier metadata', () {
    final swiftInterface = File(
      'ios/PostbackSDK.xcframework/ios-arm64/PostbackSDK.framework/Modules/'
      'PostbackSDK.swiftmodule/arm64-apple-ios.swiftinterface',
    ).readAsStringSync();
    final bridge =
        File('ios/Classes/PostbackFlutterPlugin.swift').readAsStringSync();

    const expectedFields = <String>[
      'deviceModel',
      'screenWidth',
      'screenHeight',
      'nativeScreenWidth',
      'nativeScreenHeight',
      'screenScale',
      'hardwareConcurrency',
      'processorCount',
      'maxTouchPoints',
      'memoryGb',
      'lowPowerMode',
      'batteryState',
      'batteryLevelBucket',
      'preferredLanguages',
      'timezoneOffsetMinutes',
      'deviceManufacturer',
      'deviceBrand',
      'deviceProduct',
      'deviceHardware',
      'gpuVendor',
      'gpuRenderer',
      'connectionType',
      'networkType',
      'installType',
      'isVPN',
      'isLowDataMode',
      'isExpensiveNetwork',
      'colorScheme',
      'sdkPlatform',
      'sdkVersion',
      'sdkWebViewUserAgent',
      'locale',
      'timezone',
      'osVersion',
      'appVersion',
      'idfa',
      'idfv',
    ];

    for (final field in expectedFields) {
      expect(swiftInterface, contains('public let $field:'));
      expect(bridge, contains('dict["$field"] ='));
    }

    const deprecatedCarrierFields = <String>[
      'carrierName',
      'carrierCountryCode',
      'mobileCountryCode',
      'mobileNetworkCode',
    ];

    for (final field in deprecatedCarrierFields) {
      expect(swiftInterface, contains('public var $field:'));
      expect(bridge, isNot(contains('dict["$field"] =')));
    }
    expect(
        swiftInterface,
        contains(
            'deprecated, message: "Carrier identity is not collected or transmitted by the iOS SDK."'));
  });

  test('android wrapper declares local AAR runtime dependencies', () {
    final gradle = File('android/build.gradle').readAsStringSync();
    final bridge = File(
            'android/src/main/kotlin/sh/postback/flutter/PostbackFlutterPlugin.kt')
        .readAsStringSync();

    expect(gradle, contains('rootProject.allprojects'));
    expect(
        gradle, contains("implementation(name: 'postback-sdk', ext: 'aar')"));
    expect(gradle, contains('lifecycle-process:2.10.0'));
    expect(gradle, contains('play-services-ads-identifier:18.3.0'));
    expect(gradle, contains('installreferrer:installreferrer:2.2'));
    expect(bridge, contains('getDeviceInfo(includeAdvertisingId = true)'));
    expect(bridge, contains('"carrierName" to deviceInfo.carrierName'));
    expect(bridge,
        contains('"carrierCountryCode" to deviceInfo.carrierCountryCode'));
    expect(bridge,
        contains('"mobileCountryCode" to deviceInfo.mobileCountryCode'));
    expect(bridge,
        contains('"mobileNetworkCode" to deviceInfo.mobileNetworkCode'));
    expect(bridge, contains('"gaid" to deviceInfo.gaid'));
    expect(bridge, contains('"installReferrer" to deviceInfo.installReferrer'));
    expect(
        bridge,
        contains(
            '"referrerClickTimestamp" to deviceInfo.referrerClickTimestamp'));
    expect(
        bridge,
        contains(
            '"referrerInstallBeginTimestamp" to deviceInfo.referrerInstallBeginTimestamp'));
  });
}
