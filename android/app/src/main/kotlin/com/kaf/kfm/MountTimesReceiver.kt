package com.kaf.kfm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.os.storage.StorageVolume

/**
 * U2 (h): remembers when each volume was mounted, also while KFM isn't running (the
 * ACTION_MEDIA_* broadcasts are exempt from the manifest-receiver limits). On start, Dart
 * walks a mounted card whose last walk is older than its mount time
 * (`MediaIndexer.walkRootIfStale`). Keys: `uuid:<uuid>` and `path:<root>`; an unmount removes
 * them. Missed broadcasts (KFM force-stopped) fall back to the boot time ([mountedAtMs]).
 */
class MountTimesReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        @Suppress("DEPRECATION")
        val volume = intent.getParcelableExtra<StorageVolume>(StorageVolume.EXTRA_STORAGE_VOLUME)
        val keys = listOfNotNull(
            volume?.uuid?.let { "uuid:$it" },
            intent.data?.path?.takeIf { it.isNotEmpty() }?.let { "path:$it" },
        )
        if (keys.isEmpty()) return
        val edit = prefs(context).edit()
        if (intent.action == Intent.ACTION_MEDIA_MOUNTED) {
            val now = System.currentTimeMillis()
            for (k in keys) edit.putLong(k, now)
        } else {
            for (k in keys) edit.remove(k)
        }
        edit.apply()
    }

    companion object {
        private const val PREFS = "kfm_mount_times"

        private fun prefs(context: Context) =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        /** When the volume was mounted (ms since epoch): the recorded time, else the boot time. */
        fun mountedAtMs(context: Context, uuid: String?, path: String?): Long {
            val boot = System.currentTimeMillis() - SystemClock.elapsedRealtime()
            val p = prefs(context)
            val recorded = listOfNotNull(uuid?.let { "uuid:$it" }, path?.let { "path:$it" })
                .map { p.getLong(it, 0L) }
                .maxOrNull() ?: 0L
            // A record from before the last boot is stale (unmount missed).
            return if (recorded >= boot) recorded else boot
        }
    }
}
