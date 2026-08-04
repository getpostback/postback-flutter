import Flutter
import UIKit
import PostbackSDK

public class PostbackFlutterPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "postback_flutter/native", binaryMessenger: registrar.messenger())
    let instance = PostbackFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    // MARK: - Core SDK

    case "configure":
      guard let args = call.arguments as? [String: Any],
            let apiKey = args["apiKey"] as? String, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        result(FlutterError(code: "CONFIGURE_ERROR", message: "Postback.configure requires a non-empty apiKey.", details: nil))
        return
      }
      Task { @MainActor in
        let enableAppleAds = args["enableAppleAdsAttribution"] as? Bool ?? true
        let isDebug = args["isDebug"] as? Bool ?? false
        let logLevelRaw = args["logLevel"] as? Int
        let customerUserId = args["customerUserId"] as? String
        let autoTrackSessions = args["autoTrackSessions"] as? Bool ?? true
        let autoRefreshAttribution = args["autoRefreshAttribution"] as? Bool ?? true
        let eventTrackingEnabled = args["eventTrackingEnabled"] as? Bool ?? true
        let googleAdsConsent = Self.googleAdsConsent(from: args["googleAdsConsent"])

        let logLevel: PostbackLogLevel
        if let raw = logLevelRaw, let level = PostbackLogLevel(rawValue: raw) {
          logLevel = level
        } else {
          logLevel = isDebug ? .debug : .warn
        }

        var sdkConfig = PostbackConfig(
          apiKey: apiKey,
          enableAppleAdsAttribution: enableAppleAds,
          isDebug: isDebug,
          logLevel: logLevel,
          customerUserId: customerUserId,
          autoTrackSessions: autoTrackSessions,
          autoRefreshAttribution: autoRefreshAttribution,
          eventTrackingEnabled: eventTrackingEnabled,
          googleAdsConsent: googleAdsConsent
        )

        let apiUrl = (args["apiUrl"] as? String) ?? (args["endpointBaseUrl"] as? String)
        if let urlString = apiUrl, let url = URL(string: urlString) {
          sdkConfig = PostbackConfig(
            apiKey: apiKey,
            apiURL: url,
            enableAppleAdsAttribution: enableAppleAds,
            isDebug: isDebug,
            logLevel: logLevel,
            customerUserId: customerUserId,
            autoTrackSessions: autoTrackSessions,
            autoRefreshAttribution: autoRefreshAttribution,
            eventTrackingEnabled: eventTrackingEnabled,
            googleAdsConsent: googleAdsConsent
          )
        }

        await Postback.shared.configure(sdkConfig)
        result(true)
      }

    case "sendEvent":
      guard let args = call.arguments as? [String: Any],
            let eventTypeStr = args["eventType"] as? String else {
        result(FlutterError(code: "SEND_EVENT_ERROR", message: "eventType is required", details: nil))
        return
      }
      let type = PostbackEventType(rawValue: eventTypeStr) ?? .custom
      let normalizedName = Self.normalizedEventName(args["name"] as? String)
      guard type != .custom || normalizedName != nil else {
        result(false)
        return
      }

      Task { @MainActor in
        var params: [String: Any]? = args["parameters"] as? [String: Any]
        let normalizedCurrency = Self.normalizedCurrency((args["currency"] as? String) ?? (params?["currency"] as? String))
        params?.removeValue(forKey: "currency")

        if let rev = Self.numberValue(args["revenue"] ?? args["price"]) {
          if params == nil { params = [:] }
          params?["revenue"] = rev
        }
        if let cur = normalizedCurrency {
          if params == nil { params = [:] }
          params?["currency"] = cur
        }
        if let googleAdsConsent = args["googleAdsConsent"] as? [String: Any] {
          if params == nil { params = [:] }
          params?["googleAdsConsent"] = googleAdsConsent
        }

        await Postback.shared.sendEvent(type, name: normalizedName, params: params)
        result(true)
      }

    case "sendTestEvent":
      Task { @MainActor in
        let r = await Postback.shared.sendTestEvent()
        result(["success": r.success, "message": r.message])
      }

    case "flush":
      Task { @MainActor in
        await Postback.shared.flush()
        result(nil)
      }

    case "clearData":
      Task { @MainActor in
        Postback.shared.clearData()
        result(nil)
      }

    case "setCustomerUserId":
      guard let args = call.arguments as? [String: Any],
            let userId = args["userId"] as? String else {
        result(FlutterError(code: "SET_USER_ID_ERROR", message: "userId is required", details: nil))
        return
      }
      Task { @MainActor in
        await Postback.shared.setCustomerUserId(userId)
        result(nil)
      }

    case "refreshAttribution":
      Task { @MainActor in
        guard let attr = await Postback.shared.refreshAttribution() else {
          result(nil)
          return
        }
        result(Self.attributionToDictionary(attr))
      }

    case "enableAppleAdsAttribution":
      Task { @MainActor in
        result(Postback.shared.enableAppleAdsAttribution())
      }

    case "getPostbackId":
      Task { @MainActor in
        result(Postback.shared.getPostbackId())
      }

    case "getAttribution":
      Task { @MainActor in
        guard let attr = Postback.shared.getAttribution() else {
          result(nil)
          return
        }
        result(Self.attributionToDictionary(attr))
      }

    case "getAttributionParams":
      Task { @MainActor in
        result(Postback.shared.getAttributionParams())
      }

    case "isInitialized":
      Task { @MainActor in
        result(Postback.shared.isInitialized)
      }

    case "isSdkDisabled":
      Task { @MainActor in
        result(Postback.shared.isSdkDisabled())
      }

    case "destroy":
      Task { @MainActor in
        Postback.shared.destroy()
        result(nil)
      }

    // MARK: - Utility

    case "getDeviceInfo":
      Task { @MainActor in
        let info = PostbackNative.getDeviceInfo()
        var dict: [String: Any] = [:]
        if let value = info.sdkPlatform { dict["sdkPlatform"] = value }
        if let value = info.sdkVersion { dict["sdkVersion"] = value }
        if let o = info.osVersion { dict["osVersion"] = o }
        if let appVersion = info.appVersion { dict["appVersion"] = appVersion }
        result(dict)
      }

    case "getAdServicesToken":
      let token = PostbackNative.getAdServicesToken()
      result(token as Any)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func numberValue(_ value: Any?) -> Double? {
    switch value {
    case let double as Double:
      return double
    case let float as Float:
      return Double(float)
    case let int as Int:
      return Double(int)
    case let number as NSNumber:
      return number.doubleValue
    case let string as String:
      return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
    default:
      return nil
    }
  }

  private static func normalizedEventName(_ name: String?) -> String? {
    guard let normalized = name?.trimmingCharacters(in: .whitespacesAndNewlines),
          !normalized.isEmpty,
          normalized.utf16.count <= 255,
          !normalized.contains("\u{0}") else {
      return nil
    }
    return normalized
  }

  private static func normalizedCurrency(_ currency: String?) -> String? {
    guard let normalized = currency?.trimmingCharacters(in: .whitespacesAndNewlines),
          normalized.utf8.count == 3,
          normalized.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) }) else {
      return nil
    }
    return normalized.uppercased()
  }

  private static func googleAdsConsent(from value: Any?) -> GoogleAdsConsent? {
    guard let dict = value as? [String: Any],
          let status = googleAdsConsentStatus(from: dict["adUserData"]) else {
      return nil
    }
    return GoogleAdsConsent(adUserData: status)
  }

  private static func googleAdsConsentStatus(from value: Any?) -> GoogleAdsConsentStatus? {
    guard let raw = value as? String else {
      return nil
    }
    return GoogleAdsConsentStatus(rawValue: raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
  }

  private static func attributionToDictionary(_ attr: AttributionResult) -> [String: Any] {
    var dict: [String: Any] = [
      "isAttributed": attr.isAttributed,
      "source": attr.source,
      "confidence": attr.confidence,
    ]
    if let matchType = attr.matchType { dict["matchType"] = matchType }
    if let campaignName = attr.campaignName { dict["campaignName"] = campaignName }
    if let link = attr.link {
      dict["link"] = ["id": link.id, "name": link.name]
    }
    if let appleAds = attr.appleAds {
      var apple: [String: Any] = ["campaignId": appleAds.campaignId]
      if let orgId = appleAds.orgId { apple["orgId"] = orgId }
      if let adGroupId = appleAds.adGroupId { apple["adGroupId"] = adGroupId }
      if let keywordId = appleAds.keywordId { apple["keywordId"] = keywordId }
      if let adId = appleAds.adId { apple["adId"] = adId }
      if let country = appleAds.countryOrRegion { apple["countryOrRegion"] = country }
      if let claimType = appleAds.claimType { apple["claimType"] = claimType }
      if let clickDate = appleAds.clickDate { apple["clickDate"] = clickDate }
      if let impressionDate = appleAds.impressionDate { apple["impressionDate"] = impressionDate }
      if let conversion = appleAds.conversionType { apple["conversionType"] = conversion }
      if let supplyPlacement = appleAds.supplyPlacement { apple["supplyPlacement"] = supplyPlacement }
      dict["appleAds"] = apple
    }
    if let utmSource = attr.utmSource { dict["utmSource"] = utmSource }
    if let utmMedium = attr.utmMedium { dict["utmMedium"] = utmMedium }
    if let utmCampaign = attr.utmCampaign { dict["utmCampaign"] = utmCampaign }
    if let utmContent = attr.utmContent { dict["utmContent"] = utmContent }
    if let utmTerm = attr.utmTerm { dict["utmTerm"] = utmTerm }
    return dict
  }
}
