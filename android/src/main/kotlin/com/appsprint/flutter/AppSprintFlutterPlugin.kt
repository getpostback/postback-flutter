package com.appsprint.flutter

import android.content.Context
import com.appsprint.sdk.AppSprint
import com.appsprint.sdk.AppSprintConfig
import com.appsprint.sdk.AppSprintEventType
import com.appsprint.sdk.AttributionResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class AppSprintFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private fun sdk(): AppSprint = AppSprint.shared(context)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
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
                thread(start = true) {
                    try {
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
                        )
                        sdk().configure(config)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CONFIGURE_ERROR", e.message, null)
                    }
                }
            }

            "sendEvent" -> {
                val eventTypeStr = call.argument<String>("eventType") ?: "custom"
                thread(start = true) {
                    try {
                        val type = AppSprintEventType.entries.find { it.wireValue == eventTypeStr } ?: AppSprintEventType.CUSTOM
                        val name = call.argument<String>("name")
                        val params = mutableMapOf<String, Any?>()
                        call.argument<Map<String, Any?>>("parameters")?.forEach { (k, v) -> params[k] = v }
                        val revenue = numberArgument(call, "revenue")
                        val currency = call.argument<String>("currency")
                        if (revenue != null) params["revenue"] = revenue
                        if (currency != null) params["currency"] = currency
                        sdk().sendEvent(type, name, if (params.isNotEmpty()) params else null)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SEND_EVENT_ERROR", e.message, null)
                    }
                }
            }

            "sendTestEvent" -> {
                thread(start = true) {
                    try {
                        val r = sdk().sendTestEvent()
                        result.success(mapOf("success" to r.success, "message" to r.message))
                    } catch (e: Exception) {
                        result.error("TEST_EVENT_ERROR", e.message, null)
                    }
                }
            }

            "flush" -> {
                thread(start = true) {
                    try {
                        sdk().flush()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("FLUSH_ERROR", e.message, null)
                    }
                }
            }

            "clearData" -> {
                thread(start = true) {
                    try {
                        sdk().clearData()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("CLEAR_DATA_ERROR", e.message, null)
                    }
                }
            }

            "setCustomerUserId" -> {
                val userId = call.argument<String>("userId") ?: ""
                thread(start = true) {
                    try {
                        sdk().setCustomerUserId(userId)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SET_USER_ID_ERROR", e.message, null)
                    }
                }
            }

            "refreshAttribution" -> {
                thread(start = true) {
                    try {
                        result.success(sdk().refreshAttribution()?.let { attributionToMap(it) })
                    } catch (e: Exception) {
                        result.error("REFRESH_ATTRIBUTION_ERROR", e.message, null)
                    }
                }
            }

            "enableAppleAdsAttribution" -> {
                thread(start = true) {
                    try {
                        result.success(sdk().enableAppleAdsAttribution())
                    } catch (e: Exception) {
                        result.error("APPLE_ADS_ERROR", e.message, null)
                    }
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
                thread(start = true) {
                    try {
                        sdk().destroy()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("DESTROY_ERROR", e.message, null)
                    }
                }
            }

            // Utility

            "getDeviceInfo" -> {
                result.success(mapOf(
                    "deviceModel" to android.os.Build.MODEL,
                    "screenWidth" to context.resources.displayMetrics.widthPixels,
                    "screenHeight" to context.resources.displayMetrics.heightPixels,
                    "locale" to java.util.Locale.getDefault().toLanguageTag(),
                    "timezone" to java.util.TimeZone.getDefault().id,
                    "osVersion" to android.os.Build.VERSION.RELEASE,
                ))
            }

            "getAdServicesToken" -> result.success(null) // iOS only

            "requestTrackingAuthorization" -> result.success(false) // iOS only

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun numberArgument(call: MethodCall, key: String): Double? {
        val value = call.argument<Any>(key) ?: return null
        return when (value) {
            is Number -> value.toDouble().takeIf { it.isFinite() }
            is String -> value.trim().toDoubleOrNull()?.takeIf { it.isFinite() }
            else -> null
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
                it.adGroupId?.let { value -> put("adGroupId", value) }
                it.keywordId?.let { value -> put("keywordId", value) }
                it.countryOrRegion?.let { value -> put("countryOrRegion", value) }
                it.conversionType?.let { value -> put("conversionType", value) }
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
