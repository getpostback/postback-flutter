# Changelog

All notable changes to the Postback Flutter SDK are documented here.

## 2.0.0 - 2026-08-12

### Changed

- Vendored the public iOS full attribution-context collector while keeping its raw diagnostics internal to the binary.
- Removed the public raw-device diagnostic helpers from the Flutter channel; the supported customer API remains the high-level `Postback` integration surface.
- IDFA is collected only when ATT is already authorized; Postback never requests authorization.
- Carrier and SIM identity remain excluded on iOS.
- Removed the embedded iOS privacy manifest; disclosure is maintained in the Postback website policy and host-app declarations.

## 1.1.0 - 2026-08-12

### Changed

- Vendored the production-safe iOS framework, which enforces a compile-time boundary that omits IDFA/IDFV and the experimental fingerprint bundle. The iOS bridge exposes only install lifecycle plus safe SDK, app, and OS metadata; shared nullable fields remain source-compatible for Android consumers.
- Removed unused iOS AdSupport, CoreTelephony, Metal, Network, and WebKit link declarations and aligned the packaged privacy manifest with `NSPrivacyTracking = false`.
- Preserved install lifecycle classification and added one-shot missing-install recovery to `sendTestEvent()`: re-register once, retry once, and never loop.

## 1.0.2 - 2026-08-04

### Changed

- Removed the iOS ATT request helper and IDFA/IDFV bridge fields.
- Vendored the privacy-safe Postback iOS SDK while retaining Apple Ads attribution through AdServices.

## 1.0.1 - 2026-08-01

### Fixed

- Align custom event names and currency validation with the native SDKs and Edge contract.

## 1.0.0 - 2026-07-17

### Added

- Initial Postback Flutter release with install attribution, event tracking, native iOS and Android bridges, and bundled Postback 1.0.0 native SDKs.
