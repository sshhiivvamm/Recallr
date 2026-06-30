# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Isar — keep generated schema and native FFI bindings
-keep class dev.isar.** { *; }
-keep class com.isar.** { *; }
-keepclassmembers class * {
    @dev.isar.annotations.* *;
}

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# webview_flutter
-keep class io.flutter.plugins.webviewflutter.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# OkHttp (used by metadata_fetch / http)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
