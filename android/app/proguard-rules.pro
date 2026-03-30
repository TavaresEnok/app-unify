# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Flutter models and data classes
# Adjust the package name to match your app's package name
-keep class com.example.unified.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Squareup (OkHttp / Retrofit / Picasso used by many plugins)
-keep class com.squareup.okhttp.** { *; }
-keep interface com.squareup.okhttp.** { *; }
-dontwarn com.squareup.okhttp.**

# Encryption / Security
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keepnames class javax.crypto.** { *; }
-keepnames class java.security.spec.** { *; }

# WebView
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }

# Charts
-keep class com.github.fl_chart.** { *; }

# Lottie
-keep class com.airbnb.lottie.** { *; }

# Connection / Network
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-keep class com.example.flutter_internet_speed_test.** { *; }

# Keep generic Dart/Flutter names just in case
-keep class dev.flutter.** { *; }

# Prevent warnings for common issues
# Prevent warnings for common issues
-dontwarn java.nio.file.*
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn sun.misc.Unsafe
-dontwarn com.google.protobuf.**

# Play Core and Deferred Components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
