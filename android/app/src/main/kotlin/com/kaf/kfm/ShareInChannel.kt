package com.kaf.kfm

import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.system.ErrnoException
import android.system.OsConstants
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

/**
 * `com.kaf.kfm/share_in` + `com.kaf.kfm/share_in/events` (TASK-X1): files shared into KFM
 * from other apps (ACTION_SEND / ACTION_SEND_MULTIPLE).
 *
 * Each item is resolved right away (senders may revoke access quickly): a MediaStore item
 * → `{kind: media, id, uri}`; anything else is copied into `<filesDir>/shared_in/<receivedAtMs>/`
 * → `{kind: copy, path}`; a failure → `{kind: failed, error: noAccess|noSpace|ioError|cancelled}`.
 * Never matched by name + size.
 *
 * The latest finished batch is kept until Dart calls `takePending` (cold start safe):
 * `{id, receivedAtMs, items, notFiles}`. Events: `{type: started, batchId, count}`,
 * `{type: progress, batchId, index, bytes, total}` (files > 50 MB), `{type: ready, batchId}`.
 */
class ShareInChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.kaf.kfm/share_in")
    private val events = EventChannel(messenger, "com.kaf.kfm/share_in/events")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private var sink: EventChannel.EventSink? = null
    @Volatile private var pending: Map<String, Any?>? = null
    @Volatile private var cancelled: String? = null

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                this@ShareInChannel.sink = sink
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        sink = null
        io.shutdown()
    }

    /** True when [intent] was a share (handled here). */
    fun handle(intent: Intent?): Boolean {
        val action = intent?.action ?: return false
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) return false
        val uris = streamUris(intent)
        val receivedAt = System.currentTimeMillis()
        val batchId = "share-$receivedAt"
        emit(mapOf("type" to "started", "batchId" to batchId, "count" to uris.size))
        io.execute {
            val items = uris.mapIndexed { index, uri -> resolve(batchId, receivedAt, index, uri) }
            pending = mapOf(
                "id" to batchId,
                "receivedAtMs" to receivedAt,
                "items" to items,
                "notFiles" to uris.isEmpty(),
            )
            emit(mapOf("type" to "ready", "batchId" to batchId))
        }
        return true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takePending" -> {
                val p = pending
                pending = null
                result.success(p)
            }
            "cancel" -> {
                cancelled = call.argument<String>("batchId")
                result.success(null)
            }
            "root" -> result.success(root().absolutePath)
            "copyItem" -> {
                val batchId = call.argument<String>("batchId") ?: ""
                val receivedAt = call.argument<Number>("receivedAtMs")?.toLong()
                    ?: System.currentTimeMillis()
                val uri = Uri.parse(call.argument<String>("uri") ?: "")
                io.execute {
                    val item = copy(batchId, receivedAt, 0, uri)
                    main.post { result.success(item) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun root() = File(context.filesDir, "shared_in")

    private fun emit(event: Map<String, Any?>) {
        main.post { sink?.success(event) }
    }

    @Suppress("DEPRECATION")
    private fun streamUris(intent: Intent): List<Uri> {
        val out = LinkedHashSet<Uri>()
        if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let { out.addAll(it) }
        } else {
            intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)?.let { out.add(it) }
        }
        val clip = intent.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) clip.getItemAt(i).uri?.let { out.add(it) }
        }
        return out.filter { it.scheme == "content" || it.scheme == "file" }
    }

    private fun resolve(batchId: String, receivedAt: Long, index: Int, uri: Uri): Map<String, Any?> {
        mediaId(uri)?.let { return mapOf("kind" to "media", "id" to it, "uri" to uri.toString()) }
        return copy(batchId, receivedAt, index, uri)
    }

    /** The MediaStore id behind [uri], or null (then it is copied). */
    private fun mediaId(uri: Uri): Long? = try {
        when {
            uri.authority == MediaStore.AUTHORITY -> ContentUris.parseId(uri).takeIf { it >= 0 }
            DocumentsContract.isDocumentUri(context, uri) -> {
                val docId = DocumentsContract.getDocumentId(uri)
                val parts = docId.split(':')
                if (uri.authority == "com.android.providers.media.documents" && parts.size == 2 &&
                    parts[0] in setOf("image", "video", "audio")
                ) {
                    parts[1].toLongOrNull()
                } else if (Build.VERSION.SDK_INT >= 29) {
                    MediaStore.getMediaUri(context, uri)?.let { ContentUris.parseId(it) }
                } else {
                    null
                }
            }
            else -> null
        }
    } catch (e: Exception) {
        null // not a MediaStore item: copy it
    }

    private fun copy(batchId: String, receivedAt: Long, index: Int, uri: Uri): Map<String, Any?> {
        val resolver = context.contentResolver
        var name: String? = null
        var size = -1L
        try {
            resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
                ?.use { c ->
                    if (c.moveToFirst()) {
                        val n = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        val s = c.getColumnIndex(OpenableColumns.SIZE)
                        if (n >= 0 && !c.isNull(n)) name = c.getString(n)
                        if (s >= 0 && !c.isNull(s)) size = c.getLong(s)
                    }
                }
        } catch (e: Exception) {
            // Some providers don't answer queries; the stream may still open.
        }
        val dir = File(root(), receivedAt.toString())
        val target = uniqueFile(dir, sanitize(name ?: uri.lastPathSegment ?: "shared"))
        val part = File(dir, target.name + ".part")
        try {
            dir.mkdirs()
            val input = resolver.openInputStream(uri) ?: throw IOException("no stream")
            input.use { inp ->
                part.outputStream().use { out ->
                    val buf = ByteArray(256 * 1024)
                    var done = 0L
                    var lastEmit = 0L
                    val big = size > BIG_FILE
                    while (true) {
                        if (cancelled == batchId) throw CancelledException()
                        val n = inp.read(buf)
                        if (n < 0) break
                        out.write(buf, 0, n)
                        done += n
                        if (big && done - lastEmit >= PROGRESS_STEP) {
                            lastEmit = done
                            emit(mapOf("type" to "progress", "batchId" to batchId, "index" to index,
                                "bytes" to done, "total" to size))
                        }
                    }
                    out.fd.sync()
                }
            }
            if (!part.renameTo(target)) throw IOException("rename failed")
            return mapOf("kind" to "copy", "path" to target.absolutePath, "uri" to uri.toString())
        } catch (e: Exception) {
            part.delete()
            val error = when {
                e is CancelledException -> "cancelled"
                e is SecurityException -> "noAccess"
                isNoSpace(e) -> "noSpace"
                else -> "ioError"
            }
            Log.w(TAG, "share-in copy failed ($error)", e)
            return mapOf("kind" to "failed", "error" to error, "uri" to uri.toString())
        }
    }

    private fun isNoSpace(e: Throwable): Boolean {
        var t: Throwable? = e
        while (t != null) {
            if (t is ErrnoException && t.errno == OsConstants.ENOSPC) return true
            if (t.message?.contains("ENOSPC") == true) return true
            t = t.cause
        }
        return false
    }

    private fun sanitize(raw: String): String {
        val cleaned = raw.map { c -> if (c < ' ' || c in "/\\:*?\"<>|") '_' else c }
            .joinToString("").trim().trimStart('.')
        val name = cleaned.ifEmpty { "shared" }
        return if (name.length > 120) name.takeLast(120) else name
    }

    private fun uniqueFile(dir: File, name: String): File {
        var f = File(dir, name)
        if (!f.exists()) return f
        val dot = name.lastIndexOf('.')
        val base = if (dot > 0) name.substring(0, dot) else name
        val ext = if (dot > 0) name.substring(dot) else ""
        var i = 1
        while (f.exists()) {
            f = File(dir, "$base ($i)$ext")
            i++
        }
        return f
    }

    private class CancelledException : Exception()

    companion object {
        private const val TAG = "KFM-ShareIn"
        private const val BIG_FILE = 50L * 1024 * 1024
        private const val PROGRESS_STEP = 4L * 1024 * 1024
    }
}
