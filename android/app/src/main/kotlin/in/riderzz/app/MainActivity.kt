package `in`.riderzz.app

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Hosts the small, app-specific Flutter-to-Android overlay command surface. */
class MainActivity : FlutterActivity() {
    private lateinit var overlayChannel: MethodChannel
    private var sharedLocationChannel: MethodChannel? = null

    // Native buffer for timing safety
    private var pendingLocationUri: String? = null
    private var isFlutterReady: Boolean = false

    companion object {
        const val SHARED_LOCATION_CHANNEL = "com.example.riderzz_app/shared_location"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── 1. Existing Overlay Channel (100% UNTOUCHED) ──────────────────────
        overlayChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OverlayChannelHandler.CHANNEL_NAME,
        )
        OverlayChannelHandler(this, overlayChannel).register()
        OverlayManager.bindEventChannel(overlayChannel)

        // ── 2. Dedicated Shared Location Channel with Buffer Handshake ─────────
        val locationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARED_LOCATION_CHANNEL,
        )
        sharedLocationChannel = locationChannel
        locationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLocation" -> {
                    isFlutterReady = true
                    val uriToReturn = pendingLocationUri
                    pendingLocationUri = null // Consume exactly once
                    result.success(uriToReturn)
                }
                "notifyFlutterReady" -> {
                    isFlutterReady = true
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        turnScreenOnAndShowOnKeyguard()
        OverlayManager.initialize(applicationContext)

        // Buffer cold-start intent
        val uri = extractGeoUri(intent)
        if (uri != null) {
            pendingLocationUri = uri
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val uri = extractGeoUri(intent) ?: return

        if (isFlutterReady && sharedLocationChannel != null) {
            // Flutter is actively listening → push immediately
            sharedLocationChannel?.invokeMethod("onLocationReceived", uri)
        } else {
            // Flutter is still starting up → buffer the latest intent (latest wins)
            pendingLocationUri = uri
        }
    }

    private fun extractGeoUri(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action == Intent.ACTION_VIEW && intent.data?.scheme == "geo") {
            return intent.dataString
        }
        return null
    }

    private fun turnScreenOnAndShowOnKeyguard() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }

    override fun onResume() {
        super.onResume()
        OverlayManager.onHostActivityResumed()
        OverlayPermissionManager.onHostActivityResumed(this)
    }

    override fun onPause() {
        OverlayManager.onHostActivityPaused()
        super.onPause()
    }

    override fun onDestroy() {
        if (::overlayChannel.isInitialized) {
            OverlayManager.unbindEventChannel(overlayChannel)
        }
        isFlutterReady = false
        sharedLocationChannel = null
        super.onDestroy()
    }
}
