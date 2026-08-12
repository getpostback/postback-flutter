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

  test('iOS package links full attribution dependencies without a prompt API', () {
    final podspec = File('ios/postback_flutter.podspec').readAsStringSync();
    final binary = latin1.decode(File(
            'ios/PostbackSDK.xcframework/ios-arm64/PostbackSDK.framework/PostbackSDK')
        .readAsBytesSync());

    expect(podspec, contains('AppTrackingTransparency'));
    expect(podspec, contains("'Network'"));
    expect(podspec, contains("'WebKit'"));
    for (final framework in <String>[
      'AdSupport',
      'CoreTelephony',
      'Metal',
      'WebKit',
    ]) {
      expect(
        binary,
        contains('/System/Library/Frameworks/$framework.framework/$framework'),
        reason: 'release binary must link $framework',
      );
    }
    expect(binary, contains('/usr/lib/swift/libswiftNetwork.dylib'));
    expect(podspec, contains("'Security'"));
    expect(podspec, contains("s.weak_frameworks = 'AdServices', 'AppTrackingTransparency', 'AdSupport', 'StoreKit'"));
    expect(binary, contains('AppTrackingTransparency.framework'));
    expect(binary,
        contains('/System/Library/Frameworks/Security.framework/Security'));
    expect(binary,
        contains('/System/Library/Frameworks/StoreKit.framework/StoreKit'));
    expect(binary, contains('ATTrackingManager'));
    expect(binary, isNot(contains('requestTrackingAuthorization')));
  });

  test('iOS binary distribution does not embed a privacy manifest', () {
    for (final slice in <String>['ios-arm64', 'ios-arm64_x86_64-simulator']) {
      expect(
        File('ios/PostbackSDK.xcframework/$slice/PostbackSDK.framework/PrivacyInfo.xcprivacy')
            .existsSync(),
        isFalse,
      );
    }
  });

  test('iOS wrapper keeps the native signal collector out of its public bridge', () {
    final swiftInterface = File(
      'ios/PostbackSDK.xcframework/ios-arm64/PostbackSDK.framework/Modules/'
      'PostbackSDK.swiftmodule/arm64-apple-ios.swiftinterface',
    ).readAsStringSync();
    final bridge =
        File('ios/Classes/PostbackFlutterPlugin.swift').readAsStringSync();

    expect(swiftInterface, isNot(contains('PostbackNative')));
    expect(swiftInterface, isNot(contains('DeviceInfo')));
    expect(swiftInterface, isNot(contains('InstallType')));
    expect(bridge, isNot(contains('PostbackNative')));
    expect(bridge, isNot(contains('getDeviceInfo')));
    expect(bridge, isNot(contains('getWebViewUserAgent')));
    expect(bridge, isNot(contains('getAdServicesToken')));
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
    expect(bridge, isNot(contains('PostbackNative')));
    expect(bridge, isNot(contains('getDeviceInfo')));
    expect(bridge, isNot(contains('getWebViewUserAgent')));
    expect(bridge, isNot(contains('getAdServicesToken')));
  });
}
