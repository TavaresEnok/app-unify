# ============================================================
# Flutter Core
# ============================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class dev.flutter.** { *; }

# App package
-keep class com.example.unified.** { *; }

# ============================================================
# Firebase
# ============================================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }

# ============================================================
# flutter_plus plugins (connectivity, battery, device_info, etc.)
# ============================================================
-keep class dev.fluttercommunity.plus.** { *; }
-keep class io.flutter.plugins.connectivity.** { *; }
-keep class io.flutter.plugins.deviceinfo.** { *; }
-keep class io.flutter.plugins.packageinfo.** { *; }
-keep class io.flutter.plugins.battery.** { *; }

# ============================================================
# network_info_plus
# ============================================================
-keep class dev.fluttercommunity.plus.network_info.** { *; }
-keep class io.flutter.plugins.networkinfo.** { *; }

# ============================================================
# permission_handler
# ============================================================
-keep class com.baseflow.permissionhandler.** { *; }

# ============================================================
# flutter_internet_speed_test
# ============================================================
-keep class com.shaz.flutter_internet_speed_test.** { *; }
-keep class com.example.flutter_internet_speed_test.** { *; }
-keep class * extends io.flutter.plugin.common.FlutterPlugin { *; }

# ============================================================
# lan_scanner
# ============================================================
-keep class com.eugenesqr.lan_scanner.** { *; }
-keep class com.midfield_systems.android_udid.** { *; }

# ============================================================
# dart_ping / network (ICMP)
# ============================================================
-keep class com.namit.dart_ping.** { *; }
-keep class net.cachapa.** { *; }

# ============================================================
# Kotlin Coroutines (usados internamente pelos plugins)
# ============================================================
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory { *; }
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler { *; }
-keepclassmembers class kotlin.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ============================================================
# OkHttp / Retrofit (usados por plugins de rede)
# ============================================================
-keep class com.squareup.okhttp3.** { *; }
-keep interface com.squareup.okhttp3.** { *; }
-keep class com.squareup.okhttp.** { *; }
-keep interface com.squareup.okhttp.** { *; }
-dontwarn com.squareup.okhttp3.**
-dontwarn com.squareup.okhttp.**
-dontwarn okhttp3.**
-dontwarn okio.**

# ============================================================
# Encryption / Security
# ============================================================
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keepnames class javax.crypto.** { *; }
-keepnames class java.security.spec.** { *; }

# ============================================================
# local_auth (biometria)
# ============================================================
-keep class io.flutter.plugins.localauth.** { *; }

# ============================================================
# shared_preferences
# ============================================================
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ============================================================
# Reflection (necessário para Flutter plugin registration)
# ============================================================
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Manter todas as classes que extendem FlutterPlugin
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * extends io.flutter.plugin.common.MethodCallHandler { *; }

# ============================================================
# Suprimir warnings comuns
# ============================================================
-dontwarn java.nio.file.*
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn sun.misc.Unsafe
-dontwarn com.google.protobuf.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
