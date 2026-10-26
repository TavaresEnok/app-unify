package com.example.unified

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.net.ConnectivityManager
import android.net.NetworkCapabilities

class MainActivity: FlutterActivity() {
    private val CHANNEL = "br.com.ajust.app_provedor/wifi_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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

    private fun getWifiDetails(): Map<String, Any>? {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val connectivityManager = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        
        val networkKey = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
             val currentNetwork = connectivityManager.activeNetwork
             val caps = connectivityManager.getNetworkCapabilities(currentNetwork)
             if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                 wifiManager.connectionInfo
             } else {
                 null
             }
        } else {
             wifiManager.connectionInfo
        }

        if (networkKey == null) return null

        val info = hashMapOf<String, Any>()
        info["frequency"] = networkKey.frequency
        info["rssi"] = networkKey.rssi
        info["linkSpeed"] = networkKey.linkSpeed
        
        // DNS Servers (Android M+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val activeNetwork = connectivityManager.activeNetwork
            if (activeNetwork != null) {
                val linkProps = connectivityManager.getLinkProperties(activeNetwork)
                if (linkProps != null) {
                    val dnsList = linkProps.dnsServers.map { it.hostAddress }
                    info["dnsServers"] = dnsList
                }
            }
        }

        return info
    }
}
