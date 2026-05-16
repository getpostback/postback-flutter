# AppSprint for Flutter

Mobile attribution and event tracking for Flutter apps, backed by the native iOS and Android AppSprint SDKs. The Dart layer is a thin pass-through to the same engines as our standalone iOS and Android SDKs, so behavior matches across platforms.

## Requirements

- Flutter 3.22 or later
- Dart 3.3 or later
- iOS 14.0 or later
- Android 7.0 (API 24) or later

## Install

Add the package to `pubspec.yaml`:

```yaml
dependencies:
  appsprint_flutter: ^1.1.0
```

Fetch dependencies:

```bash
flutter pub get
```

The Flutter plugin manages the iOS pod and the Android AAR for you. No extra repository setup needed.

## Configure

Call `configure` once in `main()`, before `runApp`. It returns a future that resolves after local state is restored; install registration runs in the background:

```dart
import 'package:flutter/material.dart';
import 'package:appsprint_flutter/appsprint_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppSprint.instance.configure(
    const AppSprintConfig(apiKey: 'YOUR_API_KEY'),
  );

  runApp(const MyApp());
}
```

If you prefer the named-argument form for parity with web SDKs:

```dart
await AppSprint.instance.configure(
  'YOUR_API_KEY',
  endpointBaseUrl: 'https://api.appsprint.app',
);
```

### Configuration options

| Option | Type | Default | What it does |
|---|---|---|---|
| `apiKey` | `String` | required | Your AppSprint app key. |
| `apiUrl` | `String` | `https://api.appsprint.app` | Override for staging or self-hosted environments. |
| `endpointBaseUrl` | `String` | alias for `apiUrl` | Accepted for compatibility. |
| `enableAppleAdsAttribution` | `bool` | `true` | iOS only. Fetches Apple AdServices at install time. |
| `customerUserId` | `String?` | `null` | Your internal user ID. Persists across launches and replays if the first send fails. |
| `autoTrackSessions` | `bool` | `true` | Fires `session_start` on `configure()` and on foreground, debounced to one event per 30 minutes. |
| `autoRefreshAttribution` | `bool` | `true` | Refreshes attribution from the backend on `configure()` and on foreground. |
| `isDebug` | `bool` | `false` | Forces debug-level logging on the native side. |
| `logLevel` | `int` | `2` | `0 = debug`, `1 = info`, `2 = warn`, `3 = error`. |

## Track events

```dart
import 'package:appsprint_flutter/appsprint_flutter.dart';

await AppSprint.instance.sendEvent(AppSprintEventType.login);
await AppSprint.instance.sendEvent(AppSprintEventType.signUp);

await AppSprint.instance.sendEvent(
  AppSprintEventType.purchase,
  params: {
    'revenue': 9.99,
    'currency': 'USD',
  },
);

await AppSprint.instance.sendEvent(
  AppSprintEventType.custom,
  name: 'onboarding_step',
  params: {
    'screen': 'welcome',
    'step': 1,
  },
);
```

`sendEvent` resolves once the native side has queued the event locally. The actual HTTP send happens on the next flush trigger.

### Built-in event types

`session_start`, `login`, `sign_up`, `register`, `purchase`, `subscribe`, `start_trial`, `add_payment_info`, `add_to_cart`, `add_to_wishlist`, `initiate_checkout`, `view_content`, `view_item`, `search`, `share`, `tutorial_complete`, `achieve_level`, `level_start`, `level_complete`, `custom`.

### Revenue events

Pass `revenue` (or `price` as an alias) plus `currency`. Currency must be a 3-letter ISO code; anything else is dropped on the native side before the request goes out.

```dart
await AppSprint.instance.sendEvent(
  AppSprintEventType.subscribe,
  params: {
    'revenue': 4.99,
    'currency': 'EUR',
    'plan': 'monthly',
  },
);
```

### Custom events

```dart
await AppSprint.instance.sendEvent(
  AppSprintEventType.custom,
  name: 'level_skip',
  params: {'level': 12},
);
```

Use `name` to label custom events. Keep the name stable so your dashboard groups them correctly.

## Read attribution

Once an install registers, attribution is cached on the native side. You can read it any time:

```dart
final attribution = await AppSprint.instance.getAttribution();
final appsprintId = await AppSprint.instance.getAppSprintId();
final params = await AppSprint.instance.getAttributionParams();
```

`AttributionResult.source` is one of `apple_ads`, `tracking_link`, or `organic`.

### Forward to RevenueCat or Superwall

`getAttributionParams()` returns a flat `Map<String, String>` shaped for partner SDKs:

```dart
final params = await AppSprint.instance.getAttributionParams();
await Purchases.setAttributes(params);
```

### Manual refresh

If you need the latest server-side resolution, call `refreshAttribution()`:

```dart
final updated = await AppSprint.instance.refreshAttribution();
debugPrint('source = ${updated?.source}');
```

## App Tracking Transparency (iOS only)

```dart
final authorized = await AppSprintNative.requestTrackingAuthorization();
```

The helper waits for the app to reach foreground-active before showing the system prompt, so calling it from `main()` or `initState()` is safe.

Add `NSUserTrackingUsageDescription` to `ios/Runner/Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier helps us deliver personalized ads.</string>
```

If you use SKAdNetwork postbacks, also add `NSAdvertisingAttributionReportEndpoint`.

`AppSprintNative.requestTrackingAuthorization()` resolves `true` on Android without prompting; ATT is iOS-only.

## Google Advertising ID (Android only)

The native Android SDK reads GAID during install registration, off the main thread, honoring Limit Ad Tracking and dropping the all-zero ID. The plugin declares `INTERNET`, `ACCESS_NETWORK_STATE`, and `com.google.android.gms.permission.AD_ID`. If your app cannot collect advertising IDs (children's apps, regional policies), remove the permission in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:tools="http://schemas.android.com/tools" ...>
    <uses-permission
        android:name="com.google.android.gms.permission.AD_ID"
        tools:node="remove" />
</manifest>
```

## What happens behind the scenes

- `configure()` resolves after local-state restore. Install registration runs in the background and retries with backoff on transient failures.
- Events queue locally on native storage and survive app restarts.
- iOS uses connectivity-aware networking, so transient offline windows queue inside the OS rather than failing fast.
- A rejected API key (`401` or `403`) disables the SDK. Future events drop until `clearData()` is called.
- Late identity updates (`setCustomerUserId`, iOS Apple Ads opt-in) retry automatically on the next `configure()` or foreground. If the cached install is no longer recognized, the SDK self-heals by re-registering.

## Privacy

The vendored iOS framework ships a `PrivacyInfo.xcprivacy` manifest declaring `UserDefaults` access plus `DeviceID`, `ProductInteraction`, `UserID`, `CoarseLocation`, and `OtherDataTypes` collection, all marked `Tracking: true`, with `api.appsprint.app` listed as a tracking domain.

For Android, include advertising ID collection, device IDs, approximate location/network-derived country, device or other identifiers, app activity, and (if you set `customerUserId`) user ID in your Play Console Data safety answers.

Don't pass raw PII through `params` or `customerUserId`. Both persist to native storage for retry durability. Use hashed or opaque identifiers instead (SHA-256 of an email, RevenueCat or Superwall `app_user_id`, your internal user UUID).

## Local development

```dart
await AppSprint.instance.configure(
  const AppSprintConfig(
    apiKey: 'YOUR_DEV_KEY',
    apiUrl: 'http://localhost:3000',
    isDebug: true,
  ),
);
```

On Android emulator, use `http://10.0.2.2:3000` to reach the host machine's localhost.

`isDebug: true` raises native log level to `debug`. iOS logs flow into Console.app; Android logs flow into `logcat` under the `AppSprint` tag.

## Public API reference

### `AppSprint`

```dart
import 'package:appsprint_flutter/appsprint_flutter.dart';
```

- `AppSprint.instance.configure(config)` initializes the SDK.
- `sendEvent(eventType, {name, params})` enqueues an event.
- `flush()` drains the queue immediately.
- `refreshAttribution()` fetches the latest attribution from the backend.
- `setCustomerUserId(userId)` updates the customer user ID.
- `getAttribution()` returns the cached attribution.
- `getAttributionParams()` returns the partner-ready payload.
- `getAppSprintId()` returns the SDK install identifier.
- `enableAppleAdsAttribution()` re-enables Apple Ads at runtime on iOS; returns `false` on Android.
- `sendTestEvent()` posts a diagnostic event and resolves to `{ success, message }`.
- `isInitialized()` reports whether `configure()` resolved.
- `isSdkDisabled()` reports whether a rejected API key disabled the SDK.
- `clearData()` wipes local state.
- `destroy()` removes native lifecycle observers.

### `AppSprintNative`

```dart
import 'package:appsprint_flutter/appsprint_flutter.dart';
```

- `getDeviceInfo()` returns the attribution device signal payload.
- `getAdServicesToken()` returns Apple's AdServices token on iOS; `null` on Android.
- `requestTrackingAuthorization()` shows the ATT prompt on iOS; resolves `true` on Android.

## Support

Issues and feature requests on the [GitHub repo](https://github.com/getappsprint/appsprint-flutter). Direct support at support@appsprint.app.

## License

MIT
