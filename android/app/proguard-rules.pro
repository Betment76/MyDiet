# Flutter / Play Core (deferred components — optional dependency)
-dontwarn com.google.android.play.core.**

# Flutter
-keep class io.flutter.** { *; }

# Yandex AppMetrica
-keep class com.yandex.metrica.** { *; }
-keep class io.appmetrica.analytics.** { *; }
-dontwarn com.yandex.metrica.**
-dontwarn io.appmetrica.analytics.**

# Yandex Mobile Ads
-keep class com.yandex.mobile.ads.** { *; }
-dontwarn com.yandex.mobile.ads.**

# RuStore Review
-keep class ru.rustore.sdk.** { *; }
-dontwarn ru.rustore.sdk.**
