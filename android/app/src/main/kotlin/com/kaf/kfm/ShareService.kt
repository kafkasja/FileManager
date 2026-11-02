package com.kaf.kfm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * N5b: keeps "Share this device" running while KFM is in the background.
 * The share server itself lives in Dart (main engine); this service only
 * keeps the process alive, holds a Wi-Fi + CPU lock and shows the ongoing
 * "Sharing with … · Stop" notification. Texts come from Dart (l10n).
 *
 * Stops on: Dart `stop` (Stop on the share screen / leaving it), the
 * notification's Stop button (Dart is told, then the service ends), or
 * KFM being swiped away from Recents ([onTaskRemoved]).
 */
class ShareService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                // From the notification: Dart stops the server; the
                // service ends either way.
                onStopRequested?.invoke()
                stopEverything()
                return START_NOT_STICKY
            }
            else -> {
                val title = intent?.getStringExtra(EXTRA_TITLE) ?: ""
                val text = intent?.getStringExtra(EXTRA_TEXT) ?: ""
                val stop = intent?.getStringExtra(EXTRA_STOP) ?: ""
                val channelName = intent?.getStringExtra(EXTRA_CHANNEL) ?: title
                ensureChannel(channelName)
                ServiceCompat.startForeground(
                    this,
                    NOTIFICATION_ID,
                    buildNotification(this, title, text, stop),
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
                    } else {
                        0
                    },
                )
                running = true
                acquireLocks()
            }
        }
        // Not sticky: a restarted service without the Dart server would
        // show a notification for nothing.
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // User decision 2026-11-02: swiping KFM away stops sharing.
        onStopRequested?.invoke()
        stopEverything()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        releaseLocks()
        running = false
        super.onDestroy()
    }

    private fun stopEverything() {
        releaseLocks()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        running = false
        stopSelf()
    }

    private fun ensureChannel(name: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_LOW).apply {
                setShowBadge(false)
            },
        )
    }

    private fun acquireLocks() {
        // Clients keep downloading with the screen off: CPU + Wi-Fi stay up
        // only while sharing runs (the notification says so).
        if (wakeLock == null) {
            wakeLock = getSystemService(PowerManager::class.java)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "kfm:sharing")
                .apply { setReferenceCounted(false); acquire() }
        }
        if (wifiLock == null) {
            @Suppress("DEPRECATION")
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                WifiManager.WIFI_MODE_FULL_LOW_LATENCY
            } else {
                WifiManager.WIFI_MODE_FULL_HIGH_PERF
            }
            wifiLock = (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager)
                .createWifiLock(mode, "kfm:sharing")
                .apply { setReferenceCounted(false); acquire() }
        }
    }

    private fun releaseLocks() {
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
        wifiLock?.takeIf { it.isHeld }?.release()
        wifiLock = null
    }

    companion object {
        const val ACTION_STOP = "com.kaf.kfm.share.STOP"
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_STOP = "stop"
        const val EXTRA_CHANNEL = "channel"
        const val CHANNEL_ID = "sharing"
        private const val NOTIFICATION_ID = 5002

        @Volatile
        var running = false
            private set

        /** Set by [ShareServiceChannel] while the Flutter engine is attached. */
        @Volatile
        var onStopRequested: (() -> Unit)? = null

        fun buildNotification(context: Context, title: String, text: String, stop: String): Notification {
            val open = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            }
            val openPending = open?.let {
                PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            }
            val stopPending = PendingIntent.getService(
                context,
                1,
                Intent(context, ShareService::class.java).setAction(ACTION_STOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            return NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_share)
                .setContentTitle(title)
                .setContentText(text)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                .setContentIntent(openPending)
                .addAction(0, stop, stopPending)
                .build()
        }

        /**
         * Updates the text while running. Never `startForegroundService`
         * from the background (Android 12+ forbids it): just re-notify.
         */
        fun update(context: Context, title: String, text: String, stop: String) {
            context.getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, buildNotification(context, title, text, stop))
        }
    }
}
