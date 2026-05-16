import Flutter
import UIKit
import AppSprintSDK

public class AppSprintFlutterPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "appsprint_flutter/native", binaryMessenger: registrar.messenger())
    let instance = AppSprintFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    // MARK: - Core SDK

    case "configure":
      guard let args = call.arguments as? [String: Any],
            let apiKey = args["apiKey"] as? String, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        result(FlutterError(code: "CONFIGURE_ERROR", message: "AppSprint.configure requires a non-empty apiKey.", details: nil))
        return
      }
      Task { @MainActor in
        let enableAppleAds = args["enableAppleAdsAttribution"] as? Bool ?? true
        let isDebug = args["isDebug"] as? Bool ?? false
        let logLevelRaw = args["logLevel"] as? Int
        let customerUserId = args["customerUserId"] as? String
        let autoTrackSessions = args["autoTrackSessions"] as? Bool ?? true
        let autoRefreshAttribution = args["autoRefreshAttribution"] as? Bool ?? true
        let googleAdsConsent = Self.googleAdsConsent(from: args["googleAdsConsent"])

        let logLevel: AppSprintLogLevel
        if let raw = logLevelRaw, let level = AppSprintLogLevel(rawValue: raw) {
          logLevel = level
        } else {
          logLevel = isDebug ? .debug : .warn
        }

        var sdkConfig = AppSprintConfig(
          apiKey: apiKey,
          enableAppleAdsAttribution: enableAppleAds,
          isDebug: isDebug,
          logLevel: logLevel,
          customerUserId: customerUserId,
          autoTrackSessions: autoTrackSessions,
          autoRefreshAttribution: autoRefreshAttribution,
          googleAdsConsent: googleAdsConsent
        )

        let apiUrl = (args["apiUrl"] as? String) ?? (args["endpointBaseUrl"] as? String)
        if let urlString = apiUrl, let url = URL(string: urlString) {
          sdkConfig = AppSprintConfig(
            apiKey: apiKey,
            apiURL: url,
            enableAppleAdsAttribution: enableAppleAds,
            isDebug: isDebug,
            logLevel: logLevel,
            customerUserId: customerUserId,
            autoTrackSessions: autoTrackSessions,
            autoRefreshAttribution: autoRefreshAttribution,
            googleAdsConsent: googleAdsConsent
          )
        }

        await AppSprint.shared.configure(sdkConfig)
        result(true)
      }

    case "sendEvent":
      guard let args = call.arguments as? [String: Any],
            let eventTypeStr = args["eventType"] as? String else {
        result(FlutterError(code: "SEND_EVENT_ERROR", message: "eventType is required", details: nil))
        return
      }
      Task { @MainActor in
        let type = AppSprintEventType(rawValue: eventTypeStr) ?? .custom
        let name = args["name"] as? String
        var params: [String: Any]? = args["parameters"] as? [String: Any]

        if let rev = Self.numberValue(args["revenue"] ?? args["price"]) {
          if params == nil { params = [:] }
          params?["revenue"] = rev
        }
        if let cur = args["currency"] as? String {
          if params == nil { params = [:] }
          params?["currency"] = cur
        }
        if let googleAdsConsent = args["googleAdsConsent"] as? [String: Any] {
          if params == nil { params = [:] }
          params?["googleAdsConsent"] = googleAdsConsent
        }

        await AppSprint.shared.sendEvent(type, name: name, params: params)
        result(true)
      }

    case "sendTestEvent":
      Task { @MainActor in
        let r = await AppSprint.shared.sendTestEvent()
        result(["success": r.success, "message": r.message])
      }

    case "flush":
      Task { @MainActor in
        await AppSprint.shared.flush()
        result(nil)
      }

    case "clearData":
      Task { @MainActor in
        AppSprint.shared.clearData()
        result(nil)
      }

    case "setCustomerUserId":
      guard let args = call.arguments as? [String: Any],
            let userId = args["userId"] as? String else {
        result(FlutterError(code: "SET_USER_ID_ERROR", message: "userId is required", details: nil))
        return
      }
      Task { @MainActor in
        await AppSprint.shared.setCustomerUserId(userId)
        result(nil)
      }

    case "refreshAttribution":
      Task { @MainActor in
        guard let attr = await AppSprint.shared.refreshAttribution() else {
          result(nil)
          return
        }
        result(Self.attributionToDictionary(attr))
      }

    case "enableAppleAdsAttribution":
      Task { @MainActor in
        result(AppSprint.shared.enableAppleAdsAttribution())
      }

    case "getAppSprintId":
      Task { @MainActor in
        result(AppSprint.shared.getAppSprintId())
      }

    case "getAttribution":
      Task { @MainActor in
        guard let attr = AppSprint.shared.getAttribution() else {
          result(nil)
          return
        }
        result(Self.attributionToDictionary(attr))
      }

    case "getAttributionParams":
      Task { @MainActor in
        result(AppSprint.shared.getAttributionParams())
      }

    case "isInitialized":
      Task { @MainActor in
        result(AppSprint.shared.isInitialized)
      }

    case "isSdkDisabled":
      Task { @MainActor in
        result(AppSprint.shared.isSdkDisabled())
      }

    case "destroy":
      Task { @MainActor in
        AppSprint.shared.destroy()
        result(nil)
      }

    // MARK: - Utility

    case "getDeviceInfo":
      Task { @MainActor in
        let info = AppSprintNative.getDeviceInfo()
        var dict: [String: Any] = [:]
        if let m = info.deviceModel { dict["deviceModel"] = m }
        if let w = info.screenWidth { dict["screenWidth"] = w }
        if let h = info.screenHeight { dict["screenHeight"] = h }
        if let w = info.nativeScreenWidth { dict["nativeScreenWidth"] = w }
        if let h = info.nativeScreenHeight { dict["nativeScreenHeight"] = h }
        if let scale = info.screenScale { dict["screenScale"] = scale }
        if let concurrency = info.hardwareConcurrency { dict["hardwareConcurrency"] = concurrency }
        if let count = info.processorCount { dict["processorCount"] = count }
        if let touch = info.maxTouchPoints { dict["maxTouchPoints"] = touch }
        if let memory = info.memoryGb { dict["memoryGb"] = memory }
        if let lowPower = info.lowPowerMode { dict["lowPowerMode"] = lowPower }
        if let state = info.batteryState { dict["batteryState"] = state }
        if let bucket = info.batteryLevelBucket { dict["batteryLevelBucket"] = bucket }
        if let languages = info.preferredLanguages { dict["preferredLanguages"] = languages }
        if let offset = info.timezoneOffsetMinutes { dict["timezoneOffsetMinutes"] = offset }
        if let value = info.deviceManufacturer { dict["deviceManufacturer"] = value }
        if let value = info.deviceBrand { dict["deviceBrand"] = value }
        if let value = info.deviceProduct { dict["deviceProduct"] = value }
        if let value = info.deviceHardware { dict["deviceHardware"] = value }
        if let value = info.gpuVendor { dict["gpuVendor"] = value }
        if let value = info.gpuRenderer { dict["gpuRenderer"] = value }
        if let value = info.connectionType { dict["connectionType"] = value }
        if let value = info.networkType { dict["networkType"] = value }
        if let value = info.carrierName { dict["carrierName"] = value }
        if let value = info.carrierCountryCode { dict["carrierCountryCode"] = value }
        if let value = info.mobileCountryCode { dict["mobileCountryCode"] = value }
        if let value = info.mobileNetworkCode { dict["mobileNetworkCode"] = value }
        if let value = info.sdkPlatform { dict["sdkPlatform"] = value }
        if let value = info.sdkVersion { dict["sdkVersion"] = value }
        if let l = info.locale { dict["locale"] = l }
        if let t = info.timezone { dict["timezone"] = t }
        if let o = info.osVersion { dict["osVersion"] = o }
        if let appVersion = info.appVersion { dict["appVersion"] = appVersion }
        if let v = info.idfv { dict["idfv"] = v }
        if let a = info.idfa { dict["idfa"] = a }
        if let tk = info.adServicesToken { dict["adServicesToken"] = tk }
        if let attStatus = info.attStatus { dict["attStatus"] = attStatus.rawValue }
        result(dict)
      }

    case "getAdServicesToken":
      let token = AppSprintNative.getAdServicesToken()
      result(token as Any)

    case "requestTrackingAuthorization":
      Task {
        let authorized = await AppSprintNative.requestTrackingAuthorization()
        result(authorized)
      }

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
