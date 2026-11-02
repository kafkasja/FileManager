package com.kaf.kfm

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * N5b: `kfm/share_service` — Dart starts/updates/stops [ShareService];
 * the service calls `stopRequested` back when the notification's Stop is
 * tapped or KFM is swiped away.
 */
class ShareServiceChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "kfm/share_service")
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
        ShareService.onStopRequested = {
            main.post { channel.invokeMethod("stopRequested", null) }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "show" -> {
                try {
                    if (ShareService.running) {
                        ShareService.update(
                            context,
                            call.argument<String>("title") ?: "",
                            call.argument<String>("text") ?: "",
                            call.argument<String>("stop") ?: "",
                        )
                        result.success(null)
                        return
                    }
                    val intent = Intent(context, ShareService::class.java)
                        .putExtra(ShareService.EXTRA_TITLE, call.argument<String>("title"))
                        .putExtra(ShareService.EXTRA_TEXT, call.argument<String>("text"))
                        .putExtra(ShareService.EXTRA_STOP, call.argument<String>("stop"))
                        .putExtra(ShareService.EXTRA_CHANNEL, call.argument<String>("channel"))
                    ContextCompat.startForegroundService(context, intent)
                    result.success(null)
                } catch (e: Exception) {
                    // e.g. ForegroundServiceStartNotAllowedException: Dart
                    // falls back to stop-on-background (rule 8).
                    result.error("start_failed", e.toString(), null)
                }
            }
            "stop" -> {
                stopService()
                result.success(null)
            }
            // N12: "<S> wants to send you files" (high importance).
            "showOffer" -> {
                try {
                    ShareService.showOffer(
                        context,
                        call.argument<String>("channel") ?: "",
                        call.argument<String>("title") ?: "",
                        call.argument<String>("text") ?: "",
                    )
                    result.success(null)
                } catch (e: Exception) {
                    result.error("notify_failed", e.toString(), null)
                }
            }
            "cancelOffer" -> {
                ShareService.cancelOffer(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun stopService() {
        context.stopService(Intent(context, ShareService::class.java))
    }

    /** The engine goes away (activity finished): the Dart server is gone too. */
    fun dispose() {
        channel.setMethodCallHandler(null)
        ShareService.onStopRequested = null
        stopService()
    }
}
