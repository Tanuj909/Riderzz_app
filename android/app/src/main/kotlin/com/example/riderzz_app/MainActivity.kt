package com.example.riderzz_app

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Hosts the small, app-specific Flutter-to-Android overlay command surface. */
class MainActivity : FlutterActivity() {
    private lateinit var overlayChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        overlayChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OverlayChannelHandler.CHANNEL_NAME,
        )
        OverlayChannelHandler(this, overlayChannel).register()
        OverlayManager.bindEventChannel(overlayChannel)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        turnScreenOnAndShowOnKeyguard()
        OverlayManager.initialize(applicationContext)
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
        super.onDestroy()
    }
}
