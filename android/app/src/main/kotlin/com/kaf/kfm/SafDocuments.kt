package com.kaf.kfm

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors

/**
 * Single-document SAF pickers on `com.kaf.kfm/files` (TASK-X6 backup & restore).
 *
 * - `createDocument {name, mime}` → content uri or null (cancelled): the system "Save as" picker.
 * - `openDocument {mimes}` → content uri or null: the system file picker.
 * - `writeDocument {uri, srcPath}` / `readDocument {uri, destPath}` → stream copy on [io]; files go
 *   through the cache dir, never as one big channel message.
 *
 * One picker at a time; a second one fails with IO. A result after activity recreation is dropped.
 */
class SafDocuments(private val activity: Activity) {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val context: Context get() = activity.applicationContext
    private var pending: MethodChannel.Result? = null
    private var pendingCode = 0

    fun handles(method: String): Boolean = method in METHODS

    fun dispose() {
        pending?.let { r ->
            pending = null
            try {
                r.error("INTERRUPTED", "activity destroyed while the picker was open", null)
            } catch (e: Exception) {
                Log.w(TAG, "could not answer: $e")
            }
        }
        io.shutdown()
    }

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "createDocument" -> {
                val name = call.argument<String>("name")
                if (name == null) {
                    result.error("BAD_ARGS", "name missing", null)
                    return
                }
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
                    .addCategory(Intent.CATEGORY_OPENABLE)
                    .setType(call.argument<String>("mime") ?: "application/octet-stream")
                    .putExtra(Intent.EXTRA_TITLE, name)
                start(intent, CREATE_REQUEST, result)
            }
            "openDocument" -> {
                val mimes = call.argument<List<String>>("mimes") ?: listOf("*/*")
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
                    .addCategory(Intent.CATEGORY_OPENABLE)
                    .setType("*/*")
                    .putExtra(Intent.EXTRA_MIME_TYPES, mimes.toTypedArray())
                start(intent, OPEN_REQUEST, result)
            }
            "writeDocument", "readDocument" -> io.execute {
                try {
                    val uri = Uri.parse(call.argument<String>("uri") ?: throw IllegalArgumentException("uri"))
                    if (call.method == "writeDocument") {
                        val src = File(call.argument<String>("srcPath") ?: throw IllegalArgumentException("srcPath"))
                        val out = context.contentResolver.openOutputStream(uri, "wt")
                            ?: throw IOException("cannot open $uri for writing")
                        out.use { o -> FileInputStream(src).use { it.copyTo(o) } }
                    } else {
                        val dest = File(call.argument<String>("destPath") ?: throw IllegalArgumentException("destPath"))
                        val input = context.contentResolver.openInputStream(uri)
                            ?: throw IOException("cannot open $uri for reading")
                        input.use { i -> FileOutputStream(dest).use { i.copyTo(it) } }
                    }
                    main.post { result.success(true) }
                } catch (e: IllegalArgumentException) {
                    main.post { result.error("BAD_ARGS", e.toString(), null) }
                } catch (e: SecurityException) {
                    main.post { result.error("PERMISSION_DENIED", e.toString(), null) }
                } catch (e: Exception) {
                    main.post { result.error("IO", e.toString(), null) }
                }
            }
            else -> result.notImplemented()
        }
    }

    /** Forwarded from FilesChannel.onActivityResult. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != CREATE_REQUEST && requestCode != OPEN_REQUEST) return false
        val r = pending
        if (r == null || pendingCode != requestCode) {
            Log.w(TAG, "document picker result after recreation dropped")
            return true
        }
        pending = null
        val uri = data?.data
        r.success(if (resultCode == Activity.RESULT_OK && uri != null) uri.toString() else null)
        return true
    }

    private fun start(intent: Intent, code: Int, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("IO", "a system request is already in progress", null)
            return
        }
        try {
            pending = result
            pendingCode = code
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, code)
        } catch (e: Exception) {
            pending = null
            result.error("IO", e.toString(), null)
        }
    }

    companion object {
        private const val TAG = "kfm.safdocs"
        private const val CREATE_REQUEST = 4103
        private const val OPEN_REQUEST = 4104
        private val METHODS = setOf("createDocument", "openDocument", "writeDocument", "readDocument")
    }
}
