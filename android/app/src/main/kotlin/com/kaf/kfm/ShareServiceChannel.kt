package com.kaf.kfm

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * N5b + X8: `kfm/share_service`. Dart (`AndroidPresencePort`) sends what
 * the one foreground service shows ([Presence]: sharing and/or jobs) and
 * the dismissible notices; button taps, the Android 15 time limit and a
 * notification tap come back as `action` (`pause`, `resume`, `cancel`,
 * `stopSharing`, `timeout`, `open`).
 */
class ShareServiceChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "kfm/share_service")

    init {
        channel.setMethodCallHandler(this)
        ShareService.onAction = { key -> channel.invokeMethod("action", key) }
    }

    @Suppress("UNCHECKED_CAST")
    private fun actionsOf(call: MethodCall): List<Pair<String, String>> =
        (call.argument<List<Map<String, String>>>("actions") ?: emptyList()).mapNotNull {
            val key = it["key"] ?: return@mapNotNull null
            key to (it["label"] ?: "")
        }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "presence" -> {
                val p = Presence(
                    sharing = call.argument<Boolean>("sharing") ?: false,
                    jobs = call.argument<Boolean>("jobs") ?: false,
                    channelId = call.argument<String>("channelId") ?: "sharing",
                    channelName = call.argument<String>("channelName") ?: "",
                    channelDescription = call.argument<String>("channelDescription") ?: "",
                    title = call.argument<String>("title") ?: "",
                    text = call.argument<String>("text") ?: "",
                    percent = call.argument<Int>("percent") ?: -1,
                    actions = actionsOf(call),
                )
                try {
                    ShareService.presence = p
                    val live = ShareService.instance
                    if (live != null && ShareService.running) {
                        if (!live.apply(p)) {
                            result.error("start_failed", "foreground service refused", null)
                            return
                        }
                    } else {
                        ContextCompat.startForegroundService(context, Intent(context, ShareService::class.java))
                    }
                    result.success(null)
                } catch (e: Exception) {
                    // e.g. ForegroundServiceStartNotAllowedException: Dart
                    // falls back (sharing: stop-on-background; jobs run
                    // while the process lives).
                    ShareService.presence = null
                    result.error("start_failed", e.toString(), null)
                }
            }
            "stop" -> {
                stopService()
                result.success(null)
            }
            "notice" -> {
                try {
                    ShareService.showNotice(
                        context,
                        slot = call.argument<String>("slot") ?: "ended",
                        channelId = call.argument<String>("channelId") ?: "transfer_results",
                        channelName = call.argument<String>("channelName") ?: "",
                        channelDescription = call.argument<String>("channelDescription") ?: "",
                        title = call.argument<String>("title") ?: "",
                        text = call.argument<String>("text") ?: "",
                        percent = call.argument<Int>("percent") ?: -1,
                        actions = actionsOf(call),
                    )
                    result.success(null)
                } catch (e: Exception) {
                    result.error("notify_failed", e.toString(), null)
                }
            }
            "cancelNotice" -> {
                ShareService.cancelNotice(context, call.argument<String>("slot") ?: "ended")
                result.success(null)
            }
            "takeOpen" -> {
                val open = ShareService.pendingOpen
                ShareService.pendingOpen = false
                result.success(open)
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

    /** A notification tap while KFM runs: open Transfers. */
    fun openTransfers() {
        channel.invokeMethod("action", ShareService.KEY_OPEN)
    }

    private fun stopService() {
        ShareService.presence = null
        context.stopService(Intent(context, ShareService::class.java))
    }

    /** The engine goes away (activity finished): the Dart side is gone too. */
    fun dispose() {
        channel.setMethodCallHandler(null)
        ShareService.onAction = null
        stopService()
    }
}
