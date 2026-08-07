package com.example.riderzz_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
import kotlin.math.max

private const val LOG_TAG = "RiderzzOverlay"
private const val OVERLAY_PREFS = "riderzz_overlay"
private const val PREF_X = "position_x"
private const val PREF_Y = "position_y"
private const val PREF_PERMISSION_SUPPRESSED = "permission_prompt_suppressed"

/** Handles the four public Flutter commands and the lifecycle signal. */
class OverlayChannelHandler(
    private val activity: MainActivity,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "com.example.riderzz_app/overlay"
    }

    fun register() = channel.setMethodCallHandler(this)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "showOverlay" -> {
                OverlayManager.requestOverlay()
                result.success(null)
            }
            "hideOverlay" -> {
                OverlayManager.hideOverlay()
                result.success(null)
            }
            "isOverlayVisible" -> result.success(OverlayService.isOverlayVisible())
            "isOverlayPermissionGranted" -> result.success(OverlayPermissionManager.isGranted(activity))
            "requestOverlayPermission" -> {
                result.success(OverlayPermissionManager.openSettings(activity))
            }
            "suppressOverlayPermissionPrompt" -> {
                OverlayPermissionManager.suppressFuturePrompts(activity)
                result.success(null)
            }
            "onAppLifecycle" -> {
                val state = call.argument<String>("state")
                if (state == "background") OverlayManager.onFlutterBackgrounded()
                if (state == "foreground") OverlayManager.onFlutterForegrounded()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}

/** Owns Android's special overlay permission and the one-time-denial policy. */
object OverlayPermissionManager {
    private var waitingForSettingsResult = false

    fun isGranted(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)

    fun mayPrompt(context: Context): Boolean =
        !context.getSharedPreferences(OVERLAY_PREFS, Context.MODE_PRIVATE)
            .getBoolean(PREF_PERMISSION_SUPPRESSED, false)

    fun suppressFuturePrompts(context: Context) {
        context.getSharedPreferences(OVERLAY_PREFS, Context.MODE_PRIVATE)
            .edit().putBoolean(PREF_PERMISSION_SUPPRESSED, true).apply()
        Log.i(LOG_TAG, "Overlay permission prompt suppressed by user")
    }

    /** Opens the system's per-app overlay settings page; no runtime dialog exists for this permission. */
    fun openSettings(activity: MainActivity): Boolean {
        if (isGranted(activity)) return true
        return try {
            waitingForSettingsResult = true
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${activity.packageName}"),
            )
            activity.startActivity(intent)
            Log.i(LOG_TAG, "Opened overlay permission settings")
            true
        } catch (error: Exception) {
            waitingForSettingsResult = false
            Log.e(LOG_TAG, "Unable to open overlay permission settings", error)
            false
        }
    }

    fun onHostActivityResumed(activity: MainActivity) {
        if (!waitingForSettingsResult) return
        waitingForSettingsResult = false
        if (!isGranted(activity)) suppressFuturePrompts(activity)
        Log.i(LOG_TAG, "Overlay permission settings returned: granted=${isGranted(activity)}")
    }
}

/**
 * Serializes lifecycle transitions and starts/stops [OverlayService]. The
 * service is the only component that adds a view to WindowManager.
 */
object OverlayManager {
    private const val BACKGROUND_DEBOUNCE_MS = 300L
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var appContext: Context
    private var hostActivityVisible = false
    private var flutterRequestedBackground = false
    private var eventChannel: MethodChannel? = null

    private val showRunnable = Runnable {
        if (!flutterRequestedBackground || hostActivityVisible) return@Runnable
        requestOverlay()
    }

    fun initialize(context: Context) {
        appContext = context.applicationContext
    }

    fun bindEventChannel(channel: MethodChannel) {
        eventChannel = channel
    }

    fun unbindEventChannel(channel: MethodChannel) {
        if (eventChannel === channel) eventChannel = null
    }

    fun onHostActivityResumed() {
        hostActivityVisible = true
        flutterRequestedBackground = false
        mainHandler.removeCallbacks(showRunnable)
        hideOverlay()
        Log.d(LOG_TAG, "Host activity resumed; overlay hidden")
    }

    fun onHostActivityPaused() {
        hostActivityVisible = false
        Log.d(LOG_TAG, "Host activity paused; awaiting Flutter lifecycle debounce")
    }

    fun onFlutterBackgrounded() {
        flutterRequestedBackground = true
        mainHandler.removeCallbacks(showRunnable)
        mainHandler.postDelayed(showRunnable, BACKGROUND_DEBOUNCE_MS)
        Log.d(LOG_TAG, "Flutter background signal; debouncing overlay")
    }

    fun onFlutterForegrounded() {
        flutterRequestedBackground = false
        mainHandler.removeCallbacks(showRunnable)
        hideOverlay()
        Log.d(LOG_TAG, "Flutter foreground signal; overlay hidden")
    }

    fun requestOverlay() {
        check(::appContext.isInitialized) { "OverlayManager must be initialized" }
        if (OverlayService.isOverlayVisible()) return
        if (!OverlayPermissionManager.isGranted(appContext)) {
            if (OverlayPermissionManager.mayPrompt(appContext)) emit("permissionRequired")
            Log.i(LOG_TAG, "Overlay not shown: permission is unavailable")
            return
        }
        try {
            val intent = Intent(appContext, OverlayService::class.java)
                .setAction(OverlayService.ACTION_SHOW)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                appContext.startForegroundService(intent)
            } else {
                appContext.startService(intent)
            }
            Log.i(LOG_TAG, "Requested native overlay service")
        } catch (error: Exception) {
            Log.e(LOG_TAG, "Unable to start overlay service", error)
            emit("overlayError", error.javaClass.simpleName)
        }
    }

    fun hideOverlay() {
        if (!::appContext.isInitialized) return
        appContext.stopService(Intent(appContext, OverlayService::class.java))
    }

    fun emit(method: String, arguments: Any? = null) {
        mainHandler.post {
            try {
                eventChannel?.invokeMethod(method, arguments)
            } catch (error: Exception) {
                Log.w(LOG_TAG, "Unable to emit $method to Flutter", error)
            }
        }
    }
}

/** Foreground service which owns exactly one native [WindowManager] overlay view. */
class OverlayService : Service() {
    companion object {
        const val ACTION_SHOW = "com.example.riderzz_app.overlay.SHOW"
        private const val NOTIFICATION_CHANNEL = "riderzz_overlay"
        private const val NOTIFICATION_ID = 1042

        @Volatile private var visible = false
        fun isOverlayVisible(): Boolean = visible
    }

    private lateinit var windowManager: WindowManager
    private lateinit var preferences: SharedPreferences
    private var overlayView: OverlayView? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_SHOW) showIfNeeded()
        return START_NOT_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        preferences = getSharedPreferences(OVERLAY_PREFS, MODE_PRIVATE)
        startAsForegroundService()
    }

    private fun showIfNeeded() {
        if (visible) return
        if (!OverlayPermissionManager.isGranted(this)) {
            Log.i(LOG_TAG, "Overlay permission was revoked before service attachment")
            stopSelf()
            return
        }
        try {
            val size = dp(64)
            val position = boundedPosition(
                preferences.getInt(PREF_X, dp(16)),
                preferences.getInt(PREF_Y, screenHeight() / 2),
                size,
            )
            layoutParams = WindowManager.LayoutParams(
                size,
                size,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = position.first
                y = position.second
            }
            overlayView = OverlayView(this) { x, y, tapped ->
                if (tapped) {
                    ActivityLauncher(this).bringRiderzzToFront()
                    stopSelf()
                } else {
                    val bounded = boundedPosition(x, y, size)
                    layoutParams?.x = bounded.first
                    layoutParams?.y = bounded.second
                    preferences.edit().putInt(PREF_X, bounded.first).putInt(PREF_Y, bounded.second).apply()
                    overlayView?.let { windowManager.updateViewLayout(it, layoutParams) }
                }
            }
            windowManager.addView(overlayView, layoutParams)
            visible = true
            Log.i(LOG_TAG, "Native overlay attached at ${position.first}, ${position.second}")
        } catch (error: Exception) {
            Log.e(LOG_TAG, "Unable to attach overlay view", error)
            OverlayManager.emit("overlayError", error.javaClass.simpleName)
            stopSelf()
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        val view = overlayView ?: return
        val params = layoutParams ?: return
        val bounded = boundedPosition(params.x, params.y, params.width)
        params.x = bounded.first
        params.y = bounded.second
        windowManager.updateViewLayout(view, params)
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // A swiped-away task cannot preserve its Flutter navigation state.
        // Remove the icon rather than exposing a stale recovery affordance.
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        overlayView?.let {
            try {
                windowManager.removeView(it)
            } catch (error: Exception) {
                Log.w(LOG_TAG, "Overlay view was already removed", error)
            }
        }
        overlayView = null
        layoutParams = null
        visible = false
        Log.i(LOG_TAG, "Native overlay service stopped")
        super.onDestroy()
    }

    private fun startAsForegroundService() {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "Riderzz floating icon",
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
        val launchIntent = (packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification: Notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
            .setSmallIcon(R.drawable.ic_overlay_notification)
            .setContentTitle("Riderzz is ready")
            .setContentText("Tap the floating icon to return to Riderzz")
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun boundedPosition(x: Int, y: Int, size: Int): Pair<Int, Int> = Pair(
        x.coerceIn(0, max(0, screenWidth() - size)),
        y.coerceIn(0, max(0, screenHeight() - size)),
    )

    private fun screenWidth(): Int = resources.displayMetrics.widthPixels
    private fun screenHeight(): Int = resources.displayMetrics.heightPixels
    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}

/** Native draggable Riderzz bubble; it does not depend on a Flutter engine. */
class OverlayView(
    context: Context,
    private val onInteraction: (x: Int, y: Int, tapped: Boolean) -> Unit,
) : FrameLayout(context) {
    private var downRawX = 0f
    private var downRawY = 0f
    private var initialX = 0
    private var initialY = 0
    private var moved = false
    private val touchSlop = dp(8)

    init {
        elevation = dp(8).toFloat()
        outlineProvider = object : android.view.ViewOutlineProvider() {
            override fun getOutline(view: View, outline: android.graphics.Outline) {
                outline.setOval(0, 0, view.width, view.height)
            }
        }
        clipToOutline = true
        addView(ImageView(context).apply {
            setImageResource(R.drawable.ic_floating_icon)
            scaleType = ImageView.ScaleType.CENTER_CROP
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        })
        setOnTouchListener(::handleTouch)
    }

    private fun handleTouch(view: View, event: MotionEvent): Boolean {
        val params = layoutParams as? WindowManager.LayoutParams ?: return false
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downRawX = event.rawX
                downRawY = event.rawY
                initialX = params.x
                initialY = params.y
                moved = false
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val x = initialX + (event.rawX - downRawX).toInt()
                val y = initialY + (event.rawY - downRawY).toInt()
                if (abs(event.rawX - downRawX) > touchSlop || abs(event.rawY - downRawY) > touchSlop) moved = true
                onInteraction(x, y, false)
                return true
            }
            MotionEvent.ACTION_UP -> {
                if (!moved) onInteraction(params.x, params.y, true)
                return true
            }
        }
        return false
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}

/** Restores the existing Riderzz task, or creates its normal launcher task if needed. */
class ActivityLauncher(private val context: Context) {
    fun bringRiderzzToFront() {
        try {
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
            context.startActivity(intent)
            Log.i(LOG_TAG, "Requested Riderzz foreground task")
        } catch (error: Exception) {
            Log.e(LOG_TAG, "Unable to restore Riderzz", error)
        }
    }
}
