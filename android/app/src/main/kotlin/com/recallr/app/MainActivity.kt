package com.recallr.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL  = "com.recallr.app/share_intent"
        const val EVENT_CHANNEL   = "com.recallr.app/share_intent_stream"
        // Regex to pull the first URL out of arbitrary share text
        val URL_REGEX = Regex("""https?://[^\s]+""")
    }

    private var initialUrl: String? = null
    private var eventSink: EventChannel.EventSink? = null

    // ── Flutter engine wiring ─────────────────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // One-shot: Flutter asks once at startup
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getInitialUrl") {
                    result.success(initialUrl)
                    initialUrl = null
                } else {
                    result.notImplemented()
                }
            }

        // Stream: for shares that arrive while the app is already open
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent, isInitial = true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent, isInitial = false)
    }

    // ── Intent parsing ────────────────────────────────────────────────────────

    private fun handleIntent(intent: Intent?, isInitial: Boolean) {
        if (intent?.action != Intent.ACTION_SEND) return
        if (intent.type?.startsWith("text") != true) return

        val raw = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return
        // Prefer the first URL found in the text; fall back to the whole string
        val url = URL_REGEX.find(raw)?.value ?: raw

        if (isInitial) {
            initialUrl = url
        } else {
            eventSink?.success(url)
        }
    }
}
