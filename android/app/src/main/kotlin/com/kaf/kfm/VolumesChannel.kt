package com.kaf.kfm

import android.app.usage.StorageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

/**
 * `com.kaf.kfm/volumes` + `com.kaf.kfm/volumes/events` (TASK-U1): the storage volumes and
 * their live state. The only volume source of the app.
 *
 * `list` rows: `{uuid?, primary, removable, description, state, mounted, path?, totalBytes?,
 * freeBytes?, usbMassStorage}` (`usbMassStorage` = a USB mass-storage device is attached
 * now; Dart uses it to tell a USB drive from an SD card).
 *
 * Events (while listened): `{uuid?, state}` for every volume state change (API 30+
 * StorageVolumeCallback, API 24–29 ACTION_MEDIA_* receiver) and `{usbMassStorage: true}`
 * when a USB device with a mass-storage interface (class 8) is attached.
 */
class VolumesChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.kaf.kfm/volumes")
    private val events = EventChannel(messenger, "com.kaf.kfm/volumes/events")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val storage = context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
    private val usb = context.getSystemService(Context.USB_SERVICE) as UsbManager?

    private var sink: EventChannel.EventSink? = null
    private var volumeCallback: Any? = null
    private var mediaReceiver: BroadcastReceiver? = null
    private var usbReceiver: BroadcastReceiver? = null

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                this@VolumesChannel.sink = sink
                startWatching()
            }

            override fun onCancel(arguments: Any?) {
                stopWatching()
                sink = null
            }
        })
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        stopWatching()
        sink = null
        events.setStreamHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        io.execute {
            try {
                val value: Any? = when (call.method) {
                    "list" -> list()
                    "sdkInt" -> Build.VERSION.SDK_INT
                    else -> {
                        main.post { result.notImplemented() }
                        return@execute
                    }
                }
                main.post { result.success(value) }
            } catch (e: SecurityException) {
                main.post { result.error("PERMISSION_DENIED", e.toString(), null) }
            } catch (e: Exception) {
                main.post { result.error("IO", e.toString(), null) }
            }
        }
    }

    // ---- list ----

    private fun list(): List<Map<String, Any?>> {
        val usbAttached = massStorageAttached()
        return storage.storageVolumes.map { v -> row(v, usbAttached) }
    }

    private fun row(v: StorageVolume, usbAttached: Boolean): Map<String, Any?> {
        val state = v.state
        val mounted = state == Environment.MEDIA_MOUNTED || state == Environment.MEDIA_MOUNTED_READ_ONLY
        val path = if (mounted) rootPath(v) else null
        var total: Long? = null
        var free: Long? = null
        if (path != null) {
            try {
                val fs = StatFs(path)
                total = fs.totalBytes
                free = fs.availableBytes
            } catch (e: Exception) {
                Log.w(TAG, "StatFs failed for $path: $e")
            }
        }
        if (total == null && mounted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val uuid = if (v.isPrimary) StorageManager.UUID_DEFAULT else v.uuid?.let(::parseUuid)
            if (uuid != null) {
                try {
                    val stats = context.getSystemService(StorageStatsManager::class.java)
                    total = stats.getTotalBytes(uuid)
                    free = stats.getFreeBytes(uuid)
                } catch (e: Exception) {
                    Log.w(TAG, "StorageStatsManager failed: $e")
                }
            }
        }
        return mapOf(
            "uuid" to v.uuid,
            "primary" to v.isPrimary,
            "removable" to v.isRemovable,
            "description" to v.getDescription(context),
            "state" to state,
            "mounted" to mounted,
            "path" to path,
            "totalBytes" to total,
            "freeBytes" to free,
            "usbMassStorage" to usbAttached,
        )
    }

    /** Null when unknown. API 30+: getDirectory() (null when unmounted). */
    private fun rootPath(v: StorageVolume): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) return v.directory?.path
        if (v.isPrimary) return Environment.getExternalStorageDirectory().path
        val uuid = v.uuid ?: return null
        val direct = File("/storage/$uuid")
        if (direct.exists()) return direct.path
        // <volume>/Android/data/<pkg>/files for each mounted volume.
        for (dir in context.getExternalFilesDirs(null)) {
            if (dir == null) continue
            val owner = try {
                storage.getStorageVolume(dir)
            } catch (e: Exception) {
                null
            }
            if (owner?.uuid == uuid) return dir.path.substringBefore("/Android/data/")
        }
        return null
    }

    private fun parseUuid(s: String): UUID? = try {
        UUID.fromString(s)
    } catch (e: IllegalArgumentException) {
        null // FAT-style ids (1234-ABCD) aren't UUIDs.
    }

    private fun massStorageAttached(): Boolean =
        usb?.deviceList?.values?.any { hasInterface(it, UsbConstants.USB_CLASS_MASS_STORAGE) } ?: false

    // ---- events ----

    private fun startWatching() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (volumeCallback == null) {
                val cb = object : StorageManager.StorageVolumeCallback() {
                    override fun onStateChanged(volume: StorageVolume) {
                        emit(mapOf("uuid" to volume.uuid, "state" to volume.state))
                    }
                }
                storage.registerStorageVolumeCallback(context.mainExecutor, cb)
                volumeCallback = cb
            }
        } else if (mediaReceiver == null) {
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context, intent: Intent) {
                    @Suppress("DEPRECATION")
                    val volume = intent.getParcelableExtra<StorageVolume>(StorageVolume.EXTRA_STORAGE_VOLUME)
                    emit(mapOf("uuid" to volume?.uuid, "state" to (volume?.state ?: intent.action)))
                }
            }
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_MEDIA_MOUNTED)
                addAction(Intent.ACTION_MEDIA_UNMOUNTED)
                addAction(Intent.ACTION_MEDIA_EJECT)
                addAction(Intent.ACTION_MEDIA_REMOVED)
                addAction(Intent.ACTION_MEDIA_BAD_REMOVAL)
                // Without the scheme nothing arrives.
                addDataScheme("file")
            }
            ContextCompat.registerReceiver(context, receiver, filter, ContextCompat.RECEIVER_EXPORTED)
            mediaReceiver = receiver
        }
        if (usbReceiver == null && usb != null) {
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context, intent: Intent) {
                    @Suppress("DEPRECATION")
                    val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE) ?: return
                    if (hasInterface(device, UsbConstants.USB_CLASS_MASS_STORAGE)) {
                        emit(mapOf("usbMassStorage" to true))
                    }
                }
            }
            ContextCompat.registerReceiver(
                context,
                receiver,
                IntentFilter(UsbManager.ACTION_USB_DEVICE_ATTACHED),
                ContextCompat.RECEIVER_EXPORTED,
            )
            usbReceiver = receiver
        }
    }

    private fun stopWatching() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            (volumeCallback as? StorageManager.StorageVolumeCallback)?.let {
                try {
                    storage.unregisterStorageVolumeCallback(it)
                } catch (e: Exception) {
                    Log.w(TAG, "unregister callback: $e")
                }
            }
        }
        volumeCallback = null
        for (r in listOfNotNull(mediaReceiver, usbReceiver)) {
            try {
                context.unregisterReceiver(r)
            } catch (e: Exception) {
                Log.w(TAG, "unregister receiver: $e")
            }
        }
        mediaReceiver = null
        usbReceiver = null
    }

    private fun emit(event: Map<String, Any?>) {
        main.post { sink?.success(event) }
    }

    companion object {
        private const val TAG = "kfm.volumes"

        fun hasInterface(device: UsbDevice, usbClass: Int): Boolean {
            if (device.deviceClass == usbClass) return true
            for (i in 0 until device.interfaceCount) {
                if (device.getInterface(i).interfaceClass == usbClass) return true
            }
            return false
        }
    }
}
