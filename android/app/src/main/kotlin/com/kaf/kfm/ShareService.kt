package com.kaf.kfm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * What the ongoing notification shows and which foreground-service types it
 * needs (TASK-X8). Built in Dart (all texts in KFM's language); Kotlin only
 * displays it.
 */
data class Presence(
    /** N5b sharing: `connectedDevice`. */
    val sharing: Boolean,
    /** Transfers / local jobs / incoming uploads: `dataSync`. */
    val jobs: Boolean,
    val channelId: String,
    val channelName: String,
    val channelDescription: String,
    val title: String,
    val text: String,
    /** 0..100, -1 = no progress bar. */
    val percent: Int,
    /** Button key (sent back to Dart) and label. */
    val actions: List<Pair<String, String>>,
)

/**
 * N5b + X8: keeps KFM alive in the background while sharing ("Sharing
 * with … · Stop", type `connectedDevice`) and/or while transfers, local
 * copies or incoming uploads run (progress bar, Pause/Resume/Cancel, type
 * `dataSync`): one service, one notification. Dart (`BackgroundPresence`)
 * decides what shows and when the service ends; the Dart side lives in the
 * main engine, so this only keeps the process alive, holds a Wi-Fi + CPU
 * lock and shows the notification.
 *
 * Ends on: Dart `stop` (nothing left to keep alive), KFM swiped away from
 * Recents ([onTaskRemoved]), or Android 15's `dataSync` time limit
 * ([onTimeout]: jobs pause in Dart; sharing alone carries on).
 */
class ShareService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private var lowLatencyLock: WifiManager.WifiLock? = null
    private var types = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val p = presence
        if (p == null || !apply(p)) {
            // Asked to stop meanwhile, or refused: never leave a started
            // foreground service without its notification.
            stopEverything()
        }
        // Not sticky: a restarted service without the Dart side would show
        // a notification for nothing.
        return START_NOT_STICKY
    }

    /** Shows [p]; changes the service types when they change. */
    fun apply(p: Presence): Boolean {
        ensureChannel(this, p.channelId, p.channelName, p.channelDescription, NotificationManager.IMPORTANCE_LOW)
        val wanted = typesOf(p)
        val notification = buildOngoing(this, p)
        if (running && wanted == types) {
            getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, notification)
            return true
        }
        return try {
            ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, wanted)
            types = wanted
            running = true
            acquireLocks()
            true
        } catch (e: Exception) {
            // e.g. ForegroundServiceStartNotAllowedException, or Android
            // 15's dataSync limit used up: Dart's jobs still run while the
            // process lives (rule 8: logged, the share screen falls back).
            Log.w(TAG, "startForeground refused: $e")
            if (running) {
                getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, notification)
                true
            } else {
                false
            }
        }
    }

    /**
     * Android 15+: the `dataSync` time limit (6 h a day) ran out. A few
     * seconds to stop: Dart pauses the jobs ("Paused, open KFM to
     * continue"); sharing alone keeps the service as `connectedDevice`.
     */
    override fun onTimeout(startId: Int, fgsType: Int) {
        Log.w(TAG, "foreground service timeout, type $fgsType")
        dispatchAction(this, KEY_TIMEOUT)
        val p = presence
        if (p != null && p.sharing && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val sharingOnly = p.copy(jobs = false, percent = -1, actions = p.actions.filter { it.first == KEY_STOP_SHARING })
            presence = sharingOnly
            try {
                ServiceCompat.startForeground(
                    this,
                    NOTIFICATION_ID,
                    buildOngoing(this, sharingOnly),
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                )
                types = ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
                return
            } catch (e: Exception) {
                Log.w(TAG, "sharing could not continue after the timeout: $e")
                dispatchAction(this, KEY_STOP_SHARING)
            }
        }
        presence = null
        stopEverything()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // User decision 2026-11-02: swiping KFM away stops sharing (and the
        // Dart engine with the jobs goes too; they resume next start).
        dispatchAction(this, KEY_STOP_SHARING)
        presence = null
        stopEverything()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        releaseLocks()
        running = false
        types = 0
        if (instance === this) instance = null
        super.onDestroy()
    }

    private fun stopEverything() {
        releaseLocks()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        running = false
        types = 0
        stopSelf()
    }

    private fun acquireLocks() {
        // Transfers and clients keep going with the screen off: CPU + Wi-Fi
        // stay up only while the service runs (the notification says so).
        if (wakeLock == null) {
            wakeLock = getSystemService(PowerManager::class.java)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "kfm:background")
                .apply { setReferenceCounted(false); acquire() }
        }
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        // E1: HIGH_PERF keeps Wi-Fi out of power save with the screen off
        // (phones throttle it then: a 312 MB send crawled); LOW_LATENCY
        // (API 29+) only works while KFM is on screen, so both are held.
        if (wifiLock == null) {
            @Suppress("DEPRECATION")
            wifiLock = wifi.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "kfm:background")
                .apply { setReferenceCounted(false); acquire() }
        }
        if (lowLatencyLock == null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            lowLatencyLock = wifi.createWifiLock(WifiManager.WIFI_MODE_FULL_LOW_LATENCY, "kfm:foreground")
                .apply { setReferenceCounted(false); acquire() }
        }
    }

    private fun releaseLocks() {
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
        wifiLock?.takeIf { it.isHeld }?.release()
        wifiLock = null
        lowLatencyLock?.takeIf { it.isHeld }?.release()
        lowLatencyLock = null
    }

    companion object {
        private const val TAG = "KfmShareService"
        const val ACTION_JOB = "com.kaf.kfm.JOB_ACTION"
        const val EXTRA_KEY = "key"
        const val EXTRA_OPEN = "kfm_open"
        const val KEY_STOP_SHARING = "stopSharing"
        const val KEY_TIMEOUT = "timeout"
        const val KEY_OPEN = "open"
        private const val NOTIFICATION_ID = 5002

        /** X8: dismissible notices (one slot each). */
        private const val ENDED_NOTIFICATION_ID = 5004
        private const val PAUSED_NOTIFICATION_ID = 5005

        /** N12: "Incoming files" (offers to this device). */
        const val OFFER_CHANNEL_ID = "incoming_files"
        private const val OFFER_NOTIFICATION_ID = 5003

        @Volatile
        var running = false
            private set

        /** The live service (main thread). */
        @Volatile
        var instance: ShareService? = null
            private set

        /** What should show; null = stop. */
        @Volatile
        var presence: Presence? = null

        /** Set by [ShareServiceChannel] while the Flutter engine is attached. */
        @Volatile
        var onAction: ((String) -> Unit)? = null

        /** A notification tap started KFM: Dart asks for it once it runs. */
        @Volatile
        var pendingOpen = false

        private val main = Handler(Looper.getMainLooper())

        fun typesOf(p: Presence): Int {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return 0
            var t = 0
            if (p.sharing) t = t or ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            if (p.jobs) t = t or ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            return t
        }

        /** A button or the time limit: Dart handles it; without Dart, Stop still stops. */
        fun dispatchAction(context: Context, key: String) {
            val handler = onAction
            if (handler != null) {
                main.post { handler(key) }
            } else if (key == KEY_STOP_SHARING || key == "cancel") {
                presence = null
                context.stopService(Intent(context, ShareService::class.java))
            }
        }

        /**
         * Same id: a language switch renames the channel (Android keeps
         * the user's importance choice).
         */
        fun ensureChannel(context: Context, id: String, name: String, description: String, importance: Int) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || name.isEmpty()) return
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(id, name, importance).apply {
                    if (description.isNotEmpty()) this.description = description
                    setShowBadge(false)
                },
            )
        }

        private fun openIntent(context: Context, transfers: Boolean, requestCode: Int): PendingIntent? {
            val open = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                if (transfers) putExtra(EXTRA_OPEN, "transfers")
            } ?: return null
            return PendingIntent.getActivity(
                context,
                requestCode,
                open,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }

        private fun actionIntent(context: Context, key: String): PendingIntent = PendingIntent.getBroadcast(
            context,
            100 + Math.floorMod(key.hashCode(), 1000),
            Intent(context, JobActionReceiver::class.java).setAction(ACTION_JOB).putExtra(EXTRA_KEY, key),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        fun buildOngoing(context: Context, p: Presence): Notification {
            val b = NotificationCompat.Builder(context, p.channelId)
                .setSmallIcon(R.drawable.ic_stat_share)
                .setContentTitle(p.title)
                .setContentText(p.text)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setCategory(if (p.jobs) NotificationCompat.CATEGORY_PROGRESS else NotificationCompat.CATEGORY_SERVICE)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                // Jobs: a tap opens Transfers; sharing alone: just KFM.
                .setContentIntent(openIntent(context, p.jobs, if (p.jobs) 3 else 0))
            if (p.percent in 0..100) b.setProgress(100, p.percent, false)
            for ((key, label) in p.actions) b.addAction(0, label, actionIntent(context, key))
            return b.build()
        }

        private fun slotId(slot: String) = if (slot == "paused") PAUSED_NOTIFICATION_ID else ENDED_NOTIFICATION_ID

        /** X8: a dismissible notice ("Paused …" / "Sent 3 files to PC"). */
        fun showNotice(
            context: Context,
            slot: String,
            channelId: String,
            channelName: String,
            channelDescription: String,
            title: String,
            text: String,
            percent: Int,
            actions: List<Pair<String, String>>,
        ) {
            ensureChannel(context, channelId, channelName, channelDescription, NotificationManager.IMPORTANCE_LOW)
            val b = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.drawable.ic_stat_share)
                .setContentTitle(title)
                .setContentText(text)
                .setOnlyAlertOnce(true)
                .setAutoCancel(true)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setContentIntent(openIntent(context, true, 4))
            if (percent in 0..100) b.setProgress(100, percent, false)
            for ((key, label) in actions) b.addAction(0, label, actionIntent(context, key))
            context.getSystemService(NotificationManager::class.java).notify(slotId(slot), b.build())
        }

        fun cancelNotice(context: Context, slot: String) {
            context.getSystemService(NotificationManager::class.java).cancel(slotId(slot))
        }

        /**
         * N12: a heads-up "<S> wants to send you files". A tap opens KFM,
         * whose prompter shows the offer dialog. Denied notifications only
         * lose this hint (the offer waits or expires).
         */
        fun showOffer(context: Context, channelName: String, title: String, text: String) {
            ensureChannel(context, OFFER_CHANNEL_ID, channelName, "", NotificationManager.IMPORTANCE_HIGH)
            val notification = NotificationCompat.Builder(context, OFFER_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_share)
                .setContentTitle(title)
                .setContentText(text)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setAutoCancel(true)
                .setContentIntent(openIntent(context, false, 2))
                .build()
            context.getSystemService(NotificationManager::class.java).notify(OFFER_NOTIFICATION_ID, notification)
        }

        fun cancelOffer(context: Context) {
            context.getSystemService(NotificationManager::class.java)
                .cancel(OFFER_NOTIFICATION_ID)
        }
    }
}

/** X8: Pause / Resume / Cancel / Stop on KFM's notifications. */
class JobActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ShareService.ACTION_JOB) return
        val key = intent.getStringExtra(ShareService.EXTRA_KEY) ?: return
        ShareService.dispatchAction(context, key)
    }
}
