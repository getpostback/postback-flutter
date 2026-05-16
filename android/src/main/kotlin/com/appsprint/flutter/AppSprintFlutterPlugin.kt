package com.appsprint.flutter

import android.content.Context
import com.appsprint.sdk.AppSprint
import com.appsprint.sdk.AppSprintConfig
import com.appsprint.sdk.AppSprintEventType
import com.appsprint.sdk.AppSprintNative
import com.appsprint.sdk.AttributionResult
import com.appsprint.sdk.GoogleAdsConsent
import com.appsprint.sdk.GoogleAdsConsentStatus
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class AppSprintFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var bridgeExecutor: ExecutorService = newBridgeExecutor()

    private fun newBridgeExecutor(): ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "AppSprintFlutterBridge").apply { isDaemon = true }
    }

    private fun sdk(): AppSprint = AppSprint.shared(context)

    private fun runAsync(result: MethodChannel.Result, errorCode: String, block: () -> Unit) {
        bridgeExecutor.execute {
            try {
                block()
            } catch (e: Exception) {
                result.error(errorCode, e.message, null)
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (bridgeExecutor.isShutdown) {
            bridgeExecutor = newBridgeExecutor()
        }
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "appsprint_flutter/native")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            // Core SDK

            "configure" -> {
                val apiKey = (call.argument<String>("apiKey") ?: "").trim()
                if (apiKey.isEmpty()) {
                    result.error("CONFIGURE_ERROR", "AppSprint.configure requires a non-empty apiKey.", null)
                    return
                }
                runAsync(result, "CONFIGURE_ERROR") {
                    val config = AppSprintConfig(
                        apiKey = apiKey,
                        apiUrl = call.argument<String>("apiUrl")
                            ?: call.argument<String>("endpointBaseUrl")
                            ?: "https://api.appsprint.app",
                        enableAppleAdsAttribution = call.argument<Boolean>("enableAppleAdsAttribution") ?: true,
                        isDebug = call.argument<Boolean>("isDebug") ?: false,
                        logLevel = call.argument<Int>("logLevel") ?: if (call.argument<Boolean>("isDebug") == true) 0 else 2,
                        customerUserId = call.argument<String>("customerUserId"),
                        autoTrackSessions = call.argument<Boolean>("autoTrackSessions") ?: true,
                        autoRefreshAttribution = call.argument<Boolean>("autoRefreshAttribution") ?: true,
                        googleAdsConsent = googleAdsConsentFrom(call.argument<Map<String, Any?>>("googleAdsConsent")),
                    )
                    sdk().configure(config)
                    result.success(true)
                }
            }

            "sendEvent" -> {
                val eventTypeStr = call.argument<String>("eventType") ?: "custom"
                runAsync(result, "SEND_EVENT_ERROR") {
                    val type = AppSprintEventType.entries.find { it.wireValue == eventTypeStr } ?: AppSprintEventType.CUSTOM
                    val name = call.argument<String>("name")
                    val params = mutableMapOf<String, Any?>()
                    call.argument<Map<String, Any?>>("parameters")?.forEach { (k, v) -> params[k] = v }
                    val revenue = numberArgument(call, "revenue")
                    val currency = call.argument<String>("currency")
                    call.argument<Map<String, Any?>>("googleAdsConsent")?.let { params["googleAdsConsent"] = it }
                    if (revenue != null) params["revenue"] = revenue
                    if (currency != null) params["currency"] = currency
                    sdk().sendEvent(type, name, if (params.isNotEmpty()) params else null)
                    result.success(true)
                }
            }

            "sendTestEvent" -> {
                runAsync(result, "TEST_EVENT_ERROR") {
                    val r = sdk().sendTestEvent()
                    result.success(mapOf("success" to r.success, "message" to r.message))
                }
            }

            "flush" -> {
                runAsync(result, "FLUSH_ERROR") {
                    sdk().flush()
                    result.success(null)
                }
            }

            "clearData" -> {
                runAsync(result, "CLEAR_DATA_ERROR") {
                    sdk().clearData()
                    result.success(null)
                }
            }

            "setCustomerUserId" -> {
                val userId = call.argument<String>("userId") ?: ""
                runAsync(result, "SET_USER_ID_ERROR") {
                    sdk().setCustomerUserId(userId)
                    result.success(null)
                }
            }

            "refreshAttribution" -> {
                runAsync(result, "REFRESH_ATTRIBUTION_ERROR") {
                    result.success(sdk().refreshAttribution()?.let { attributionToMap(it) })
                }
            }

            "enableAppleAdsAttribution" -> {
                runAsync(result, "APPLE_ADS_ERROR") {
                    result.success(sdk().enableAppleAdsAttribution())
                }
            }

            "getAppSprintId" -> result.success(sdk().getAppSprintId())

            "getAttribution" -> {
                val attr = sdk().getAttribution()
                if (attr == null) {
                    result.success(null)
                    return
                }
                result.success(attributionToMap(attr))
            }

            "getAttributionParams" -> result.success(sdk().getAttributionParams())

            "isInitialized" -> result.success(sdk().isInitialized())

            "isSdkDisabled" -> result.success(sdk().isSdkDisabled())

            "destroy" -> {
                runAsync(result, "DESTROY_ERROR") {
                    sdk().destroy()
                    result.success(null)
                }
            }

            // Utility

            "getDeviceInfo" -> {
                runAsync(result, "DEVICE_INFO_ERROR") {
                    val deviceInfo = AppSprintNative(context).getDeviceInfo(includeAdvertisingId = true)
                    result.success(mapOf(
                        "deviceModel" to deviceInfo.deviceModel,
                        "screenWidth" to deviceInfo.screenWidth,
                        "screenHeight" to deviceInfo.screenHeight,
                        "nativeScreenWidth" to deviceInfo.nativeScreenWidth,
                        "nativeScreenHeight" to deviceInfo.nativeScreenHeight,
                        "screenScale" to deviceInfo.screenScale,
                        "hardwareConcurrency" to deviceInfo.hardwareConcurrency,
                        "processorCount" to deviceInfo.processorCount,
                        "maxTouchPoints" to deviceInfo.maxTouchPoints,
                        "memoryGb" to deviceInfo.memoryGb,
                        "lowPowerMode" to deviceInfo.lowPowerMode,
                        "batteryState" to deviceInfo.batteryState,
                        "batteryLevelBucket" to deviceInfo.batteryLevelBucket,
                        "preferredLanguages" to deviceInfo.preferredLanguages,
                        "timezoneOffsetMinutes" to deviceInfo.timezoneOffsetMinutes,
                        "deviceManufacturer" to deviceInfo.deviceManufacturer,
                        "deviceBrand" to deviceInfo.deviceBrand,
                        "deviceProduct" to deviceInfo.deviceProduct,
                        "deviceHardware" to deviceInfo.deviceHardware,
                        "gpuVendor" to deviceInfo.gpuVendor,
                        "gpuRenderer" to deviceInfo.gpuRenderer,
                        "connectionType" to deviceInfo.connectionType,
                        "networkType" to deviceInfo.networkType,
                        "carrierName" to deviceInfo.carrierName,
                        "carrierCountryCode" to deviceInfo.carrierCountryCode,
                        "mobileCountryCode" to deviceInfo.mobileCountryCode,
                        "mobileNetworkCode" to deviceInfo.mobileNetworkCode,
                        "sdkPlatform" to deviceInfo.sdkPlatform,
                        "sdkVersion" to deviceInfo.sdkVersion,
                        "locale" to deviceInfo.locale,
                        "timezone" to deviceInfo.timezone,
                        "osVersion" to deviceInfo.osVersion,
                        "appVersion" to deviceInfo.appVersion,
                        "gaid" to deviceInfo.gaid,
                    ).filterValues { it != null })
                }
            }

            "getAdServicesToken" -> result.success(null) // iOS only

            "requestTrackingAuthorization" -> result.success(AppSprintNative(context).requestTrackingAuthorization())

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        bridgeExecutor.shutdown()
    }

    private fun numberArgument(call: MethodCall, key: String): Double? {
        val value = call.argument<Any>(key) ?: return null
        return when (value) {
            is Number -> value.toDouble().takeIf { it.isFinite() }
            is String -> value.trim().toDoubleOrNull()?.takeIf { it.isFinite() }
            else -> null
        }
    }

    private fun googleAdsConsentFrom(value: Map<String, Any?>?): GoogleAdsConsent? {
        val status = googleAdsConsentStatus(value?.get("adUserData")) ?: return null
        return GoogleAdsConsent(status)
    }

    private fun googleAdsConsentStatus(value: Any?): GoogleAdsConsentStatus? {
        val normalized = (value as? String)?.trim()?.uppercase(java.util.Locale.US) ?: return null
        return GoogleAdsConsentStatus.entries.firstOrNull {
            it.wireValue == normalized || it.name == normalized
        }
    }

    private fun attributionToMap(attr: AttributionResult): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "isAttributed" to attr.isAttributed,
            "source" to attr.source,
            "confidence" to attr.confidence,
        )
        attr.matchType?.let { map["matchType"] = it }
        attr.campaignName?.let { map["campaignName"] = it }
        attr.link?.let { map["link"] = mapOf("id" to it.id, "name" to it.name) }
        attr.appleAds?.let {
            map["appleAds"] = mutableMapOf<String, Any?>("campaignId" to it.campaignId).apply {
                it.orgId?.let { value -> put("orgId", value) }
                it.adGroupId?.let { value -> put("adGroupId", value) }
                it.keywordId?.let { value -> put("keywordId", value) }
                it.adId?.let { value -> put("adId", value) }
                it.countryOrRegion?.let { value -> put("countryOrRegion", value) }
                it.claimType?.let { value -> put("claimType", value) }
                it.clickDate?.let { value -> put("clickDate", value) }
                it.impressionDate?.let { value -> put("impressionDate", value) }
                it.conversionType?.let { value -> put("conversionType", value) }
                it.supplyPlacement?.let { value -> put("supplyPlacement", value) }
            }
        }
        attr.utmSource?.let { map["utmSource"] = it }
        attr.utmMedium?.let { map["utmMedium"] = it }
        attr.utmCampaign?.let { map["utmCampaign"] = it }
        attr.utmContent?.let { map["utmContent"] = it }
        attr.utmTerm?.let { map["utmTerm"] = it }
        return map
    }
}
