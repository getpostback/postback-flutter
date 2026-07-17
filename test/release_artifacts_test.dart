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
      expect(File(relativePath).existsSync(), isTrue, reason: '$relativePath should exist');
    }
  });

  test('android permissions are packaged for consumers', () {
    final manifest = File('android/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('android.permission.ACCESS_NETWORK_STATE'));
    expect(manifest, contains('com.google.android.gms.permission.AD_ID'));
  });

  test('android wrapper declares local AAR runtime dependencies', () {
    final gradle = File('android/build.gradle').readAsStringSync();

    expect(gradle, contains('rootProject.allprojects'));
    expect(gradle, contains("implementation(name: 'postback-sdk', ext: 'aar')"));
    expect(gradle, contains('lifecycle-process:2.10.0'));
    expect(gradle, contains('play-services-ads-identifier:18.3.0'));
    expect(gradle, contains('installreferrer:installreferrer:2.2'));
  });
}
