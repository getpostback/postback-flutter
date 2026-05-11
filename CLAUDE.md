# CLAUDE.md — appsprint-flutter

## What This Is

**Flutter bridge SDK** for AppSprint attribution. A thin Dart wrapper that delegates all work to pre-compiled native binaries (iOS XCFramework + Android AAR) via Flutter method channels.

This is a **bridge SDK** — it contains no attribution logic. All logic lives in the core iOS and Android SDKs.

**Code sensitivity: LOW** — only contains bridge code and type definitions. Repo can stay private.

---

## Build & Test

```bash
flutter pub get                      # Install dependencies
flutter analyze                      # Lint/analyze Dart code
flutter test                         # Run unit tests
flutter pub publish --dry-run        # Validate pub.dev readiness
```

---

## Architecture

```
lib/                                 # Dart public API
├── appsprint_flutter.dart          # Barrel export
└── src/
    ├── appsprint.dart              # Singleton class — validates config, delegates to native
    ├── appsprint_native.dart       # MethodChannel bridge to native platforms
    └── types.dart                  # Enums, config, result types

ios/                                 # iOS native bridge
├── Classes/
│   └── AppSprintFlutterPlugin.swift # FlutterPlugin — calls AppSprintSDK
├── appsprint_flutter.podspec       # CocoaPods spec
└── AppSprintSDK.xcframework/       # Pre-built iOS SDK binary (VENDORED)

android/                             # Android native bridge
├── src/main/kotlin/com/appsprint/flutter/
│   └── AppSprintFlutterPlugin.kt   # FlutterPlugin + MethodCallHandler — calls AAR
├── libs/appsprint-sdk.aar          # Pre-built Android SDK binary (VENDORED)
└── build.gradle                    # Android build config

test/                                # Tests
├── appsprint_flutter_test.dart     # Unit tests (mocked MethodChannel)
└── release_artifacts_test.dart     # Binary presence validation
```

### Key Patterns

- **Thin bridge:** Dart validates `apiKey` then passes everything to native via MethodChannel
- **Single method channel:** `appsprint_flutter/native` for all Dart → Native calls
- **Zero dependencies:** Only Flutter SDK dependencies
- **Pub.dev ready:** Passes `flutter pub publish --dry-run`
- **Prebuilt validation:** Tests verify AAR and XCFramework binaries exist

### Native Binaries (Vendored)

- `ios/AppSprintSDK.xcframework` — Built from `appsprint-ios` via `build-xcframework.sh`
- `android/libs/appsprint-sdk.aar` — Built from `appsprint-android` via Gradle

Update these with `make vendor-all` from the `SDKs/` directory.

---

## API Endpoints

The SDK doesn't talk to the API directly — it delegates to the native plugins which handle all networking.

---

## Platform Details

- **Dart 3.3.0+**, Flutter 3.22.0+
- **iOS native:** Swift plugin, requires iOS 14.0+
- **Android native:** Kotlin plugin, requires API 24+, compileSdk 35
- **Dependencies:** None beyond Flutter SDK
- **Dev dependencies:** flutter_test, flutter_lints

---

## CI/CD

- `ci.yml` — Analyze + test + dry-run publish on push to main and PRs
- `release.yml` — Analyze, test, publish to pub.dev on `v*` tags (manual — no OIDC support)

### pub.dev Publishing

- **Package:** `appsprint_flutter` on pub.dev
- **Publisher:** `appsprint.app` (verified domain)
- **Auth:** Manual `flutter pub publish` — pub.dev does not support OIDC yet
- **CI:** `release.yml` runs analysis + tests but publish step requires manual auth
- Consumers install via: `appsprint_flutter: ^x.y.z` in `pubspec.yaml`

---

## Commits

- **Do not add `Co-Authored-By` lines** to commit messages. Only the person committing should be attributed.

---

## Anti-Patterns

- **No attribution logic in this repo.** All logic belongs in the core iOS/Android SDKs.
- **No additional Dart/Flutter dependencies.** Keep dependencies at zero.
- **Do not modify vendored binaries** (xcframework, AAR) directly — rebuild from core SDKs.
- **Do not add platform-specific logic** to the Dart layer.
- **Keep the method channel contract stable** — changes require updating both Dart and native sides.
