import 'package:appsprint_flutter/appsprint_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('appsprint_flutter/native');
  final calls = <MethodCall>[];
  final responseMap = <String, dynamic>{};

  setUp(() {
    calls.clear();
    responseMap
      ..clear()
      ..addAll({
        'configure': true,
        'sendEvent': true,
        'enableAppleAdsAttribution': true,
        'sendTestEvent': {'success': true, 'message': 'ok'},
        'getAttributionParams': {
          'appsprintId': 'app_123',
          'appstackId': 'app_123',
          'gclid': 'gclid_123',
        },
        'getDeviceInfo': {
          'deviceModel': 'iPhone15,2',
          'screenScale': 3,
          'hardwareConcurrency': 6,
          'preferredLanguages': ['en-US', 'fr-FR'],
          'gpuRenderer': 'Apple GPU',
          'connectionType': 'cellular',
          'networkType': '5g',
          'sdkVersion': '1.1.1',
          'locale': 'en-US',
          'gaid': '38400000-8cf0-11bd-b23e-10b96e40000d',
        },
      });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return responseMap[call.method];
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('configure delegates to native channel', () async {
    final configured = await AppSprint.instance.configure(
      const AppSprintConfig(
        apiKey: 'test-key',
        isDebug: true,
        googleAdsConsent:
            GoogleAdsConsent(adUserData: GoogleAdsConsentStatus.granted),
      ),
    );

    expect(configured, true);
    expect(calls.single.method, 'configure');
    expect(calls.single.arguments, {
      'apiKey': 'test-key',
      'apiUrl': 'https://api.appsprint.app',
      'enableAppleAdsAttribution': true,
      'isDebug': true,
      'logLevel': 0,
      'customerUserId': null,
      'autoTrackSessions': true,
      'autoRefreshAttribution': true,
      'googleAdsConsent': {'adUserData': 'GRANTED'},
    });
  });

  test('configure accepts Appstack-style apiKey and options', () async {
    final configured = await AppSprint.instance.configure(
      'test-key',
      endpointBaseUrl: 'https://edge.example.com',
      isDebug: true,
      autoTrackSessions: false,
      autoRefreshAttribution: false,
    );

    expect(configured, true);
    expect(calls.single.method, 'configure');
    expect(calls.single.arguments, {
      'apiKey': 'test-key',
      'apiUrl': 'https://edge.example.com',
      'enableAppleAdsAttribution': true,
      'isDebug': true,
      'logLevel': 0,
      'customerUserId': null,
      'autoTrackSessions': false,
      'autoRefreshAttribution': false,
    });
  });

  test('configure rejects empty apiKey before native call', () async {
    expect(
      () => AppSprint.instance.configure(const AppSprintConfig(apiKey: '   ')),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'AppSprint.configure requires a non-empty apiKey.',
        ),
      ),
    );

    expect(calls, isEmpty);
  });

  test('sendEvent delegates mapped event type and params', () async {
    final sent = await AppSprint.instance.sendEvent(
      AppSprintEventType.purchase,
      name: 'checkout',
      params: {'revenue': 4.99, 'currency': 'USD', 'source': 'test'},
    );

    expect(sent, true);
    expect(calls.single.method, 'sendEvent');
    expect(calls.single.arguments, {
      'eventType': 'purchase',
      'name': 'checkout',
      'revenue': 4.99,
      'currency': 'USD',
      'parameters': {'source': 'test'},
    });
  });

  test('sendEvent accepts price as revenue fallback', () async {
    await AppSprint.instance.sendEvent(
      AppSprintEventType.purchase,
      name: 'checkout',
      params: {'price': 5, 'currency': 'EUR'},
    );

    expect(calls.single.method, 'sendEvent');
    expect(calls.single.arguments, {
      'eventType': 'purchase',
      'name': 'checkout',
      'revenue': 5,
      'currency': 'EUR',
      'parameters': null,
    });
  });

  test('sendEvent hoists Google Ads consent', () async {
    final sent = await AppSprint.instance.sendEvent(
      AppSprintEventType.purchase,
      name: 'checkout',
      params: {
        'googleAdsConsent':
            const GoogleAdsConsent(adUserData: GoogleAdsConsentStatus.denied),
        'sku': 'pro',
      },
    );

    expect(sent, true);
    expect(calls.single.method, 'sendEvent');
    expect(calls.single.arguments, {
      'eventType': 'purchase',
      'name': 'checkout',
      'revenue': null,
      'currency': null,
      'googleAdsConsent': {'adUserData': 'DENIED'},
      'parameters': {'sku': 'pro'},
    });
  });

  test('event vocabulary includes Appstack parity events', () {
    expect(appSprintEventTypeValues[AppSprintEventType.sessionStart],
        'session_start');
    expect(appSprintEventTypeValues[AppSprintEventType.addPaymentInfo],
        'add_payment_info');
    expect(appSprintEventTypeValues[AppSprintEventType.achieveLevel],
        'achieve_level');
  });

  test('sendEvent preserves zero revenue and strips hoisted fields', () async {
    await AppSprint.instance.sendEvent(
      AppSprintEventType.startTrial,
      name: 'trial_start',
      params: {'revenue': 0, 'currency': 'USD', 'plan': 'free'},
    );

    expect(calls.single.method, 'sendEvent');
    expect(calls.single.arguments, {
      'eventType': 'start_trial',
      'name': 'trial_start',
      'revenue': 0,
      'currency': 'USD',
      'parameters': {'plan': 'free'},
    });
  });

  test('public API returns typed values', () async {
    responseMap['getAttribution'] = {
      'isAttributed': true,
      'source': 'tracking_link',
      'matchType': 'ip_user_agent',
      'link': {'id': 'link_123', 'name': 'spring'},
      'utmSource': 'newsletter',
    };
    responseMap['getAppSprintId'] = 'app_123';

    final testResult = await AppSprint.instance.sendTestEvent();
    final attribution = await AppSprint.instance.getAttribution();
    final attributionParams = await AppSprint.instance.getAttributionParams();
    final appSprintId = await AppSprint.instance.getAppSprintId();
    final deviceInfo = await AppSprintNative.getDeviceInfo();

    expect(testResult.success, true);
    expect(testResult.message, 'ok');
    expect(attribution?.isAttributed, true);
    expect(attribution?.source, 'tracking_link');
    expect(attribution?.matchType, 'ip_user_agent');
    expect(attribution?.link?['name'], 'spring');
    expect(attributionParams['gclid'], 'gclid_123');
    expect(appSprintId, 'app_123');
    expect(deviceInfo.deviceModel, 'iPhone15,2');
    expect(deviceInfo.screenScale, 3);
    expect(deviceInfo.hardwareConcurrency, 6);
    expect(deviceInfo.preferredLanguages, ['en-US', 'fr-FR']);
    expect(deviceInfo.gpuRenderer, 'Apple GPU');
    expect(deviceInfo.connectionType, 'cellular');
    expect(deviceInfo.networkType, '5g');
    expect(deviceInfo.sdkVersion, '1.1.1');
    expect(deviceInfo.locale, 'en-US');
    expect(deviceInfo.gaid, '38400000-8cf0-11bd-b23e-10b96e40000d');
  });

  test('refreshAttribution returns updated native attribution', () async {
    responseMap['refreshAttribution'] = {
      'isAttributed': true,
      'source': 'apple_ads',
      'matchType': 'apple_ads',
      'appleAds': {'campaignId': '123'},
    };

    final attribution = await AppSprint.instance.refreshAttribution();

    expect(calls.single.method, 'refreshAttribution');
    expect(attribution?.source, 'apple_ads');
    expect(attribution?.appleAds?['campaignId'], '123');
  });

  test('native utility API surface matches documented wrapper methods',
      () async {
    await AppSprintNative.getAdServicesToken();
    await AppSprintNative.requestTrackingAuthorization();
    await AppSprint.instance.refreshAttribution();
    await AppSprint.instance.enableAppleAdsAttribution();
    await AppSprint.instance.destroy();

    expect(
        calls.map((call) => call.method),
        containsAll(<String>[
          'getAdServicesToken',
          'requestTrackingAuthorization',
          'refreshAttribution',
          'enableAppleAdsAttribution',
          'destroy',
        ]));
  });
}
