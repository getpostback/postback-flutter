# Changelog

## 1.1.3

- Updated vendored native SDKs to iOS v1.1.3 and Android v1.1.2.
- Exposed `sdkWebViewUserAgent` through `getDeviceInfo()` and added a direct `getWebViewUserAgent()` diagnostic helper.

## 1.1.2

- Updated vendored native SDKs to iOS v1.1.2 and Android v1.1.1.
- Exposed the native `colorScheme` diagnostic field through `getDeviceInfo()`.

## 1.1.1

- Updated the vendored iOS SDK to v1.1.1 with reliability improvements for iOS attribution payloads.

## 1.1.0

- Updated vendored native SDKs to iOS v1.1.0 and Android v1.1.0.
- Exposed additional platform-safe `getDeviceInfo()` fields for attribution quality and rollout debugging.

## 1.0.1

- Added Google Ads consent configuration and event payload parity.
- Updated vendored native binaries with iOS v1.0.1 and Android v1.0.2.
- Picked up iOS customer-user-id retry/backoff parity.
- Completed `getDeviceInfo()` parity for app version, GAID, IDFV/IDFA, AdServices token, and ATT status where platform-available.
- Exposed full Apple Ads attribution fields returned by the backend.
- Fixed attribution-param null stringification and corrected release metadata/docs.
- Excluded internal agent notes from the pub.dev package.

## 1.0.0

- Updated vendored iOS and Android SDKs to 1.0.0.
- Added session auto-tracking and attribution auto-refresh configuration.
- Added `refreshAttribution()` for manual attribution refresh parity.
- Declared Android network-state permission and package metadata for release quality checks.

## 0.1.0

- Initial scaffold for the AppSprint Flutter SDK.
- Added Dart API, Android bridge, and iOS bridge.
