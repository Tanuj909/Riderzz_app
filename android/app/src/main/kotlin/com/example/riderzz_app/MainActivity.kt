package com.example.riderzz_app

import android.os.Bundle
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
        OverlayManager.initialize(applicationContext)
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
