package com.kaf.kfm

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.mtp.MtpDevice
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * `com.kaf.kfm/mtp` + `com.kaf.kfm/mtp/events` (TASK-U1): cameras over USB (PTP/MTP, still
 * image interface class 6). Detection and USB permission only; read-only browsing is U2.
 *
 * `list` rows: `{deviceName, product?, manufacturer?, hasPermission, model?, supported?}`.
 * `model`/`supported` come from opening the device once (only with permission; `supported`
 * false = MtpDevice.open failed, e.g. another app holds the camera).
 * Events (while listened): `{changed: true}` on attach, detach and permission answers.
 */
class MtpChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.kaf.kfm/mtp")
    private val events = EventChannel(messenger, "com.kaf.kfm/mtp/events")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val usb = context.getSystemService(Context.USB_SERVICE) as UsbManager?
    private var sink: EventChannel.EventSink? = null
    private var receiver: BroadcastReceiver? = null

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                this@MtpChannel.sink = sink
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
        io.execute { closeAll() }
        io.shutdown()
    }

    /** MainActivity.onNewIntent: a camera attached while KFM runs (manifest filter). */
    fun onNewIntent(intent: Intent) {
        if (intent.action == UsbManager.ACTION_USB_DEVICE_ATTACHED) emitChanged()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        io.execute {
            try {
                val value: Any? = when (call.method) {
                    "list" -> list()
                    "requestPermission" -> requestPermission(call.argument<String>("deviceName"))
                    "storages" -> storages(device(call))
                    "children" -> children(device(call), int(call, "storage"), int(call, "parent"))
                    "info" -> info(device(call), int(call, "handle"))
                    "importTo" -> importTo(device(call), int(call, "handle"), call.argument<String>("path")!!)
                    "delete" -> device(call).deleteObject(int(call, "handle"))
                    "thumbnail" -> device(call).getThumbnail(int(call, "handle"))
                    "canDelete" -> canDelete(device(call))
                    else -> {
                        main.post { result.notImplemented() }
                        return@execute
                    }
                }
                main.post { result.success(value) }
            } catch (e: java.io.FileNotFoundException) {
                main.post { result.error("NOT_FOUND", e.toString(), null) }
            } catch (e: SecurityException) {
                main.post { result.error("PERMISSION", e.toString(), null) }
            } catch (e: Exception) {
                main.post { result.error("IO", e.toString(), null) }
            }
        }
    }

    // ---- U2: read-only browsing ----

    /** Open MtpDevices by device name (closed on detach and dispose). */
    private val open = HashMap<String, MtpDevice>()

    private fun int(call: MethodCall, key: String): Int =
        (call.argument<Any>(key) as? Number)?.toInt() ?: throw IllegalArgumentException(key)

    private fun device(call: MethodCall): MtpDevice {
        val name = call.argument<String>("deviceName") ?: throw IllegalArgumentException("deviceName")
        open[name]?.let { return it }
        val manager = usb ?: throw IllegalStateException("no USB")
        val d = cameras().firstOrNull { it.deviceName == name }
            ?: throw java.io.FileNotFoundException("camera gone: $name")
        if (!manager.hasPermission(d)) throw SecurityException("no USB permission")
        val connection = manager.openDevice(d) ?: throw IllegalStateException("openDevice failed")
        val mtp = MtpDevice(d)
        if (!mtp.open(connection)) {
            connection.close()
            throw IllegalStateException("MtpDevice.open failed")
        }
        open[name] = mtp
        return mtp
    }

    private fun closeAll() {
        for (d in open.values) {
            try {
                d.close()
            } catch (e: Exception) {
                Log.w(TAG, "close: $e")
            }
        }
        open.clear()
    }

    private fun storages(d: MtpDevice): List<Map<String, Any?>> =
        (d.storageIds ?: IntArray(0)).map { id ->
            val info = d.getStorageInfo(id)
            mapOf(
                "id" to id,
                "description" to info?.description,
                "free" to info?.freeSpace,
                "total" to info?.maxCapacity,
            )
        }

    private fun objectRow(d: MtpDevice, handle: Int, info: android.mtp.MtpObjectInfo): Map<String, Any?> = mapOf(
        "handle" to handle,
        "storage" to info.storageId,
        "parent" to info.parent,
        "name" to info.name,
        "folder" to (info.format == android.mtp.MtpConstants.FORMAT_ASSOCIATION),
        "size" to info.compressedSizeLong,
        "modified" to info.dateModified,
        "created" to info.dateCreated,
        "width" to info.imagePixWidth,
        "height" to info.imagePixHeight,
    )

    /** [parent] -1 = the storage root. */
    private fun children(d: MtpDevice, storage: Int, parent: Int): List<Map<String, Any?>> {
        val handles = d.getObjectHandles(storage, 0, parent) ?: return emptyList()
        return handles.toList().mapNotNull { h -> d.getObjectInfo(h)?.let { objectRow(d, h, it) } }
    }

    /** The object plus its folder names from the storage root (`path`). */
    private fun info(d: MtpDevice, handle: Int): Map<String, Any?>? {
        val info = d.getObjectInfo(handle) ?: return null
        val names = ArrayList<String>()
        var parent = info.parent
        var depth = 0
        while (parent != 0 && parent != -1 && depth < 32) {
            val p = d.getObjectInfo(parent) ?: break
            names.add(0, p.name)
            parent = p.parent
            depth++
        }
        return objectRow(d, handle, info) + ("path" to names.joinToString("/"))
    }

    private fun importTo(d: MtpDevice, handle: Int, path: String): Boolean {
        val ok = d.importFile(handle, path)
        if (!ok) java.io.File(path).delete()
        return ok
    }

    private fun canDelete(d: MtpDevice): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            d.deviceInfo?.isOperationSupported(android.mtp.MtpConstants.OPERATION_DELETE_OBJECT) == true
        } else {
            false
        }

    private fun cameras(): List<UsbDevice> =
        usb?.deviceList?.values?.filter {
            VolumesChannel.hasInterface(it, UsbConstants.USB_CLASS_STILL_IMAGE)
        } ?: emptyList()

    private fun list(): List<Map<String, Any?>> {
        val manager = usb ?: return emptyList()
        return cameras().map { d ->
            val permitted = manager.hasPermission(d)
            var model: String? = null
            var supported: Boolean? = null
            val cached = open[d.deviceName]
            if (permitted && cached != null) {
                supported = true
                model = cached.deviceInfo?.model
            } else if (permitted) {
                val mtp = MtpDevice(d)
                val connection = try {
                    manager.openDevice(d)
                } catch (e: Exception) {
                    null
                }
                supported = connection != null && try {
                    mtp.open(connection)
                } catch (e: Exception) {
                    false
                }
                if (supported) {
                    model = mtp.deviceInfo?.model
                    mtp.close()
                } else {
                    connection?.close()
                }
            }
            mapOf(
                "deviceName" to d.deviceName,
                "product" to d.productName,
                "manufacturer" to d.manufacturerName,
                "hasPermission" to permitted,
                "model" to model,
                "supported" to supported,
            )
        }
    }

    /** True when the system prompt was requested (or permission is already there). */
    private fun requestPermission(deviceName: String?): Boolean {
        val manager = usb ?: return false
        val device = cameras().firstOrNull { it.deviceName == deviceName } ?: return false
        if (manager.hasPermission(device)) return true
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        // Immutable: the answer isn't read from the extras; Dart re-lists (hasPermission).
        val intent = PendingIntent.getBroadcast(
            context,
            0,
            Intent(ACTION_PERMISSION).setPackage(context.packageName),
            flags,
        )
        main.post { manager.requestPermission(device, intent) }
        return true
    }

    private fun startWatching() {
        if (receiver != null || usb == null) return
        val r = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                if (intent.action == UsbManager.ACTION_USB_DEVICE_DETACHED) io.execute { closeAll() }
                emitChanged()
            }
        }
        ContextCompat.registerReceiver(
            context,
            r,
            IntentFilter().apply {
                addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
                addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
            },
            ContextCompat.RECEIVER_EXPORTED,
        )
        try {
            ContextCompat.registerReceiver(
                context,
                permissionReceiver,
                IntentFilter(ACTION_PERMISSION),
                ContextCompat.RECEIVER_NOT_EXPORTED,
            )
        } catch (e: Exception) {
            Log.w(TAG, "permission receiver: $e")
        }
        receiver = r
    }

    private val permissionReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context, intent: Intent) = emitChanged()
    }

    private fun stopWatching() {
        val r = receiver ?: return
        for (x in listOf(r, permissionReceiver)) {
            try {
                context.unregisterReceiver(x)
            } catch (e: Exception) {
                Log.w(TAG, "unregister: $e")
            }
        }
        receiver = null
    }

    private fun emitChanged() {
        main.post { sink?.success(mapOf("changed" to true)) }
    }

    companion object {
        private const val TAG = "kfm.mtp"
        private const val ACTION_PERMISSION = "com.kaf.kfm.USB_PERMISSION"
    }
}
