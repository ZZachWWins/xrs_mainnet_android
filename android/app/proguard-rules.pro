# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Fix for R8 missing Play Core classes
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Solana / Serialization
-keep class com.solana.** { *; }
-keep class org.bitcoinj.** { *; }

# Hive
-keep class io.hive.** { *; }

# Storage / Secure Storage
-keep class com.it_solutions.flutter_secure_storage.** { *; }

# Local Auth
-keep class io.flutter.plugins.localauth.** { *; }

# Webview
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }

# Cronet (HTTP/2 + QUIC) — loaded reflectively via Play Services
-keep class org.chromium.net.** { *; }
-keep class com.google.android.gms.net.** { *; }
-dontwarn org.chromium.net.**
