# Changelog

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
