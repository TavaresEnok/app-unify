package com.example.unified

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.net.ConnectivityManager
import android.net.NetworkCapabilities

// FragmentActivity: exigida pela digital (local_auth / BiometricPrompt).
class MainActivity: FlutterFragmentActivity() {
    private var invoicePdfChannel: InvoicePdfChannel? = null
    private val CHANNEL = "br.com.ajust.app_provedor/wifi_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        invoicePdfChannel?.dispose()
        invoicePdfChannel = InvoicePdfChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getWifiDetails") {
                val wifiDetails = getWifiDetails()
                if (wifiDetails != null) {
                    result.success(wifiDetails)
                } else {
                    result.error("UNAVAILABLE", "Wifi details not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        invoicePdfChannel?.dispose()
        invoicePdfChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun getWifiDetails(): Map<String, Any>? {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val connectivityManager = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        val wifiInfo: WifiInfo? = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val currentNetwork = connectivityManager.activeNetwork
                val caps = connectivityManager.getNetworkCapabilities(currentNetwork)
                if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                    (caps.transportInfo as? WifiInfo) ?: @Suppress("DEPRECATION") wifiManager.connectionInfo
                } else {
                    null
                }
            } else {
                @Suppress("DEPRECATION") wifiManager.connectionInfo
            }
        } catch (_: SecurityException) {
            null
        }

        if (wifiInfo == null) return null

        val info = hashMapOf<String, Any>()
        info["frequency"] = wifiInfo.frequency
        info["rssi"] = wifiInfo.rssi
        info["linkSpeed"] = wifiInfo.linkSpeed

        // DNS Servers (Android M+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val activeNetwork = connectivityManager.activeNetwork
            if (activeNetwork != null) {
                val linkProps = connectivityManager.getLinkProperties(activeNetwork)
                if (linkProps != null) {
                    val dnsList = linkProps.dnsServers.mapNotNull { it.hostAddress }
                    info["dnsServers"] = dnsList
                }
            }
        }

        return info
    }
}
