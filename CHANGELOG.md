# Changelog

## Unreleased

## 1.1.12 - 2026-07-14

- The iOS-only `AppSprintAppleAds` facade now registers all installs and enables automatic session and event tracking, so ASO keys collect first-party analytics for organic users as well as Apple Ads users.
- Updates the vendored iOS SDK to v1.1.11 with API-key scope isolation and compile-time macOS exclusion for the ASO facade.

## 1.1.11

- Updates the vendored iOS SDK to v1.1.10 so AppSprintSDK dSYMs are included for App Store Connect upload validation.

## 1.1.10

- Updates the vendored Android SDK to v1.1.4 so optional cellular-network subtype probes cannot crash startup on newer Android versions that deny telephony access.

## 1.1.9

- Updates the vendored native SDKs to iOS v1.1.9 and Android v1.1.3 so attribution params use `appsprintId` only.
- Removes legacy competitor-name fixtures from SDK tests.

## 1.1.8

- Adds `AppSprintAppleAds`, an iOS-only Apple Ads ROAS facade that configures the native SDK with Apple Ads attribution enabled and event/session tracking disabled.
- Returns a clear unsupported-platform error when the Apple Ads facade is used on Android.
- Updates the vendored iOS SDK to v1.1.8.

## 1.1.7

- Updated the vendored iOS SDK to v1.1.7 so the core AppSprint API is no longer declared as an iOS tracking domain and ATT denial cannot block install or event delivery.
- iOS connectivity failures now fail fast and retry through the SDK queue instead of hanging behind `waitsForConnectivity`.

## 1.1.6

- Updated the vendored iOS SDK to v1.1.6 so iOS install registration treats the retained WKWebView user-agent as a critical attribution signal and defers early attempts while WebKit is still unavailable.

## 1.1.5

- Updated the vendored iOS SDK to v1.1.5 so install registration uses the retained WKWebView user-agent probe and nested diagnostic event payloads are preserved.

## 1.1.4

- Updated the vendored iOS SDK to v1.1.4 so install registration reliably includes the SDK WebView user-agent during app launch.

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
