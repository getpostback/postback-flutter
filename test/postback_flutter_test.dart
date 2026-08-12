import 'package:postback_flutter/postback_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('postback_flutter/native');
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
          'postbackId': 'app_123',
          'gclid': 'gclid_123',
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
    final configured = await Postback.instance.configure(
      const PostbackConfig(
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
      'apiUrl': 'https://api.postback.sh',
      'enableAppleAdsAttribution': true,
      'isDebug': true,
      'logLevel': 0,
      'customerUserId': null,
      'autoTrackSessions': true,
      'autoRefreshAttribution': true,
      'eventTrackingEnabled': true,
      'googleAdsConsent': {'adUserData': 'GRANTED'},
    });
  });

  test('configure accepts apiKey overload and endpointBaseUrl options',
      () async {
    final configured = await Postback.instance.configure(
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
      'eventTrackingEnabled': true,
    });
  });

  test('configure rejects empty apiKey before native call', () async {
    expect(
      () => Postback.instance.configure(const PostbackConfig(apiKey: '   ')),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'Postback.configure requires a non-empty apiKey.',
        ),
      ),
    );

    expect(calls, isEmpty);
  });

  test('sendEvent delegates mapped event type and params', () async {
    final sent = await Postback.instance.sendEvent(
      PostbackEventType.purchase,
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
    await Postback.instance.sendEvent(
      PostbackEventType.purchase,
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
    final sent = await Postback.instance.sendEvent(
      PostbackEventType.purchase,
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

  test('event vocabulary includes alternate event name spellings', () {
    expect(postbackEventTypeValues[PostbackEventType.sessionStart],
        'session_start');
    expect(postbackEventTypeValues[PostbackEventType.addPaymentInfo],
        'add_payment_info');
    expect(postbackEventTypeValues[PostbackEventType.achieveLevel],
        'achieve_level');
  });

  test('sendEvent preserves zero revenue and strips hoisted fields', () async {
    await Postback.instance.sendEvent(
      PostbackEventType.startTrial,
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

  test('sendEvent ignores custom events without a valid name', () async {
    expect(
      await Postback.instance.sendEvent(PostbackEventType.custom),
      false,
    );
    expect(
      await Postback.instance.sendEvent(
        PostbackEventType.custom,
        name: '   ',
      ),
      false,
    );
    expect(
      await Postback.instance.sendEvent(
        PostbackEventType.custom,
        name: 'n' * 256,
      ),
      false,
    );
    expect(
      await Postback.instance.sendEvent(
        PostbackEventType.custom,
        name: '😀' * 128,
      ),
      false,
    );
    expect(
      await Postback.instance.sendEvent(
        PostbackEventType.custom,
        name: 'checkout\u0000complete',
      ),
      false,
    );
    expect(calls, isEmpty);
  });

  test('sendEvent trims custom names and accepts the 255 UTF-16 unit boundary',
      () async {
    final boundaryName = '${'😀' * 127}x';
    expect(boundaryName.length, 255);

    expect(
      await Postback.instance.sendEvent(
        PostbackEventType.custom,
        name: '  $boundaryName  ',
      ),
      true,
    );

    expect(calls.single.method, 'sendEvent');
    expect(calls.single.arguments, {
      'eventType': 'custom',
      'name': boundaryName,
      'revenue': null,
      'currency': null,
      'parameters': null,
    });
  });

  test('sendEvent omits an invalid optional name from built-in events',
      () async {
    expect(
      await Postback.instance.sendEvent(
        PostbackEventType.purchase,
        name: 'n' * 256,
      ),
      true,
    );

    expect(calls.single.method, 'sendEvent');
    expect(calls.single.arguments, {
      'eventType': 'purchase',
      'name': null,
      'revenue': null,
      'currency': null,
      'parameters': null,
    });

    await Postback.instance.sendEvent(
      PostbackEventType.login,
      name: 'opened\u0000home',
    );
    expect(calls[1].arguments, {
      'eventType': 'login',
      'name': null,
      'revenue': null,
      'currency': null,
      'parameters': null,
    });
  });

  test('sendEvent only forwards normalized three-letter ASCII currency codes',
      () async {
    await Postback.instance.sendEvent(
      PostbackEventType.purchase,
      params: {'revenue': 2.5, 'currency': ' usd '},
    );
    await Postback.instance.sendEvent(
      PostbackEventType.purchase,
      params: {'revenue': 3.5, 'currency': 'éur'},
    );

    expect(calls, hasLength(2));
    expect(calls[0].arguments, {
      'eventType': 'purchase',
      'name': null,
      'revenue': 2.5,
      'currency': 'USD',
      'parameters': null,
    });
    expect(calls[1].arguments, {
      'eventType': 'purchase',
      'name': null,
      'revenue': 3.5,
      'currency': null,
      'parameters': null,
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
    responseMap['getPostbackId'] = 'app_123';

    final testResult = await Postback.instance.sendTestEvent();
    final attribution = await Postback.instance.getAttribution();
    final attributionParams = await Postback.instance.getAttributionParams();
    final postbackId = await Postback.instance.getPostbackId();

    expect(testResult.success, true);
    expect(testResult.message, 'ok');
    expect(attribution?.isAttributed, true);
    expect(attribution?.source, 'tracking_link');
    expect(attribution?.matchType, 'ip_user_agent');
    expect(attribution?.link?['name'], 'spring');
    expect(attributionParams['gclid'], 'gclid_123');
    expect(postbackId, 'app_123');
  });

  test('refreshAttribution returns updated native attribution', () async {
    responseMap['refreshAttribution'] = {
      'isAttributed': true,
      'source': 'apple_ads',
      'matchType': 'apple_ads',
      'appleAds': {'campaignId': '123'},
    };

    final attribution = await Postback.instance.refreshAttribution();

    expect(calls.single.method, 'refreshAttribution');
    expect(attribution?.source, 'apple_ads');
    expect(attribution?.appleAds?['campaignId'], '123');
  });

  test('public API surface matches documented wrapper methods', () async {
    await Postback.instance.refreshAttribution();
    await Postback.instance.enableAppleAdsAttribution();
    await Postback.instance.destroy();

    expect(
        calls.map((call) => call.method),
        containsAll(<String>[
          'refreshAttribution',
          'enableAppleAdsAttribution',
          'destroy',
        ]));
  });
}
