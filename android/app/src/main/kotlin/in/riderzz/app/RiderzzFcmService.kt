package `in`.riderzz.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class RiderzzFcmService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val type = remoteMessage.data["type"]

        if (type == "BOOKING_BROADCAST") {
            showFullScreenBookingNotification(remoteMessage)
        } else {
            // Pass through all other notification types (customer, status updates, etc.)
            super.onMessageReceived(remoteMessage)
        }
    }

    private fun showFullScreenBookingNotification(remoteMessage: RemoteMessage) {
        val channelId = "new_booking_alert_v1"
        val channelName = "New Booking Alerts"
        val channelDescription = "Alerts with custom sound for new delivery booking requests."
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Ensure Notification Channel exists natively
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            var channel = notificationManager.getNotificationChannel(channelId)
            if (channel == null) {
                channel = NotificationChannel(
                    channelId,
                    channelName,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = channelDescription
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)
                    val soundUri = Uri.parse("android.resource://" + packageName + "/raw/booking_alert")
                    val audioAttributes = AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .build()
                    setSound(soundUri, audioAttributes)
                    lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(channel)
            }
        }

        if (isAppInForeground(this)) {
            // Do NOT build or show a native notification manually.
            // Flutter's Dart engine is running and will handle displaying the notification and deduplication.
            return
        }

        // Prepare launch intent for MainActivity to open over lock screen
        val context: Context = this
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("from_fcm_full_screen", true)
            for ((key, value) in remoteMessage.data) {
                putExtra(key, value)
            }
        }

        val notificationId = (remoteMessage.messageId?.hashCode() ?: System.currentTimeMillis().toInt()) and Int.MAX_VALUE

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            launchIntent,
            pendingIntentFlags
        )

        val notificationObj = remoteMessage.notification
        val title = notificationObj?.title ?: remoteMessage.data["title"] ?: "New Delivery Request"
        val body = notificationObj?.body ?: remoteMessage.data["body"] ?: "You have received a new booking broadcast!"

        val soundUri = Uri.parse("android.resource://" + packageName + "/raw/booking_alert")

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_overlay_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setSound(soundUri)
            .setVibrate(longArrayOf(0, 500, 200, 500, 200, 500))
            .setContentIntent(fullScreenPendingIntent)

        // Safety check for Android 14 (API 34) FullScreenIntent restrictions
        var canUseFullScreen = true
        if (Build.VERSION.SDK_INT >= 34) { // Build.VERSION_CODES.UPSIDE_DOWN_CAKE
            canUseFullScreen = notificationManager.canUseFullScreenIntent()
        }

        if (canUseFullScreen) {
            builder.setFullScreenIntent(fullScreenPendingIntent, true)
        }

        notificationManager.notify(notificationId, builder.build())
    }

    private fun isAppInForeground(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false
        val packageName = context.packageName
        for (appProcess in appProcesses) {
            if (appProcess.importance == android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND && appProcess.processName == packageName) {
                return true
            }
        }
        return false
    }
}
