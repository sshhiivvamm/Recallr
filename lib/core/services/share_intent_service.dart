import 'package:flutter/services.dart';

/// Bridges the native Android share-intent channels to Flutter.
///
/// Two channels:
///  • MethodChannel — Flutter asks at startup for any URL that launched the app.
///  • EventChannel  — stream of URLs that arrive while the app is already open.
class ShareIntentService {
  ShareIntentService._();

  static const _method = MethodChannel('com.recallr.app/share_intent');
  static const _events = EventChannel('com.recallr.app/share_intent_stream');

  /// Returns the URL that was shared to launch the app (null if none).
  /// Call once at startup; the native side clears it after the first read.
  static Future<String?> getInitialUrl() async {
    try {
      return await _method.invokeMethod<String?>('getInitialUrl');
    } catch (_) {
      return null;
    }
  }

  /// Emits every URL shared while the app is in the foreground/background.
  static Stream<String> get urlStream {
    return _events
        .receiveBroadcastStream()
        .where((e) => e is String && (e as String).isNotEmpty)
        .cast<String>();
  }
}
