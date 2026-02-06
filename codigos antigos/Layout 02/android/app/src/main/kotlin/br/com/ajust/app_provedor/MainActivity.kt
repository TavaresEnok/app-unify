package br.com.ajust.app_provedor

import android.content.Context
import android.net.ConnectivityManager
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "br.com.ajust.app_provedor/wifi_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getWifiDetails" -> {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo: WifiInfo = wifiManager.connectionInfo

                        val connectivityManager = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                        val linkProperties = connectivityManager.getLinkProperties(connectivityManager.activeNetwork)
                        val dnsServers = linkProperties?.dnsServers?.map { it.hostAddress } ?: listOf<String>()

                        val frequency = wifiInfo.frequency
                        val rssi = wifiInfo.rssi

                        result.success(mapOf(
                            "frequency" to frequency,
                            "rssi" to rssi,
                            "dnsServers" to dnsServers
                        ))
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                result.error("UNAVAILABLE", "Falha ao acessar API nativa do WiFi.", e.toString())
            }
        }
    }
}