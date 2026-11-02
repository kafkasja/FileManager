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
                    else -> {
                        main.post { result.notImplemented() }
                        return@execute
                    }
                }
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("IO", e.toString(), null) }
            }
        }
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
            if (permitted) {
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
            override fun onReceive(c: Context, intent: Intent) = emitChanged()
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
