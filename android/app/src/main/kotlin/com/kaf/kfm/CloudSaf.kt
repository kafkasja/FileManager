package com.kaf.kfm

import android.Manifest
import android.content.ContentResolver
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import android.provider.MediaStore
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream
import java.io.SyncFailedException
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/**
 * Cloud destinations on `com.kaf.kfm/files` (TASK-X3): writes files into a folder that a cloud
 * app (Google Drive, OneDrive, Dropbox, …) exposes through its DocumentsProvider. The cloud app
 * uploads them; KFM never talks to a cloud itself.
 *
 * Copies and read-back hashes run on this class's own single-thread executor ([copyIo]), never
 * on FilesChannel's `io`: a 1 GB upload must not stall queries, moves and the indexer.
 *
 * - `cloudTreeLabel {tree}` → `{authority, name}` (the picked folder's display name).
 * - `cloudCreate {tree, name, mime}` → the new document's URI (the provider may rename it).
 * - `cloudCopy {source, doc, jobKey}` → `{sha256, bytes}` of the bytes read from [source]
 *   (a `content://` URI or an absolute path) and written to `doc` through its file
 *   descriptor, fsync'ed before it is closed. MediaStore items are opened
 *   with `setRequireOriginal` when ACCESS_MEDIA_LOCATION is granted (API 29+), so GPS isn't
 *   redacted. Stops between 1 MiB chunks on `cloudCancel` (error CANCELLED). On any failure
 *   the document is deleted (best effort: Dart deletes it again and records a failure).
 * - `cloudHash {doc}` → `{sha256, bytes}` read back through the provider.
 * - `cloudStat {doc}` → size, or null when the document is gone.
 * - `cloudDelete {doc}` → true (also when already gone).
 * - `cloudCancel {jobKey}` → sets the flag, returns at once.
 *
 * Progress: `com.kaf.kfm/files/progress` emits `{jobKey, bytes}` at most every 250 ms.
 * Error codes: NOT_FOUND, PERMISSION, NO_SPACE, CANCELLED, BAD_ARGS, IO.
 */
class CloudSaf(private val context: Context, messenger: BinaryMessenger) {
    private val copyIo = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val resolver: ContentResolver get() = context.contentResolver
    private val cancelled = ConcurrentHashMap.newKeySet<String>()
    private val progressChannel = EventChannel(messenger, "com.kaf.kfm/files/progress")

    @Volatile
    private var progressSink: EventChannel.EventSink? = null

    @Volatile
    private var disposed = false

    init {
        progressChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                progressSink = events
            }

            override fun onCancel(arguments: Any?) {
                progressSink = null
            }
        })
    }

    fun handles(method: String): Boolean = method in METHODS

    /** Running copies stop at their next chunk; the partial document is cleaned up by Dart on
     * the next start (the row is still `uploading`). */
    fun dispose() {
        disposed = true
        progressChannel.setStreamHandler(null)
        progressSink = null
        copyIo.shutdownNow()
    }

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "cloudCancel") {
            call.argument<String>("jobKey")?.let { cancelled.add(it) }
            result.success(true)
            return
        }
        copyIo.execute {
            try {
                val value: Any? = when (call.method) {
                    "cloudTreeLabel" -> treeLabel(uri(call, "tree"))
                    "cloudCreate" -> create(uri(call, "tree"), str(call, "name"), call.argument<String>("mime"))
                    "cloudCopy" -> copy(str(call, "source"), uri(call, "doc"), str(call, "jobKey"))
                    "cloudHash" -> hash(uri(call, "doc"))
                    "cloudStat" -> stat(uri(call, "doc"))
                    "cloudDelete" -> delete(uri(call, "doc"))
                    else -> throw IllegalArgumentException(call.method)
                }
                main.post { result.success(value) }
            } catch (e: CancelledException) {
                main.post { result.error("CANCELLED", "cancelled", null) }
            } catch (e: FileNotFoundException) {
                main.post { result.error("NOT_FOUND", e.toString(), null) }
            } catch (e: SecurityException) {
                main.post { result.error("PERMISSION", e.toString(), null) }
            } catch (e: IllegalArgumentException) {
                main.post { result.error("BAD_ARGS", e.toString(), null) }
            } catch (e: IOException) {
                val code = if (e.message?.contains("ENOSPC") == true ||
                    e.message?.contains("No space") == true
                ) "NO_SPACE" else "IO"
                main.post { result.error(code, e.toString(), null) }
            } catch (e: Exception) {
                main.post { result.error("IO", e.toString(), null) }
            }
        }
    }

    private class CancelledException : Exception()

    private fun str(call: MethodCall, key: String): String =
        call.argument<String>(key) ?: throw IllegalArgumentException(key)

    private fun uri(call: MethodCall, key: String): Uri = Uri.parse(str(call, key))

    private fun treeRoot(tree: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

    private fun treeLabel(tree: Uri): Map<String, Any?> {
        val name = try {
            resolver.query(treeRoot(tree), arrayOf(Document.COLUMN_DISPLAY_NAME), null, null, null)
                ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }
        } catch (e: Exception) {
            Log.w(TAG, "no label for $tree: $e")
            null
        }
        return mapOf("authority" to tree.authority, "name" to name)
    }

    private fun create(tree: Uri, name: String, mime: String?): String {
        val created = DocumentsContract.createDocument(
            resolver, treeRoot(tree), mime ?: "application/octet-stream", name,
        ) ?: throw IOException("createDocument refused $name")
        return created.toString()
    }

    private fun openSource(source: String): InputStream {
        if (!source.startsWith("content://")) {
            val file = File(source)
            if (!file.isFile) throw FileNotFoundException(source)
            return file.inputStream()
        }
        var uri = Uri.parse(source)
        if (uri.authority == MediaStore.AUTHORITY && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            context.checkSelfPermission(Manifest.permission.ACCESS_MEDIA_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            uri = MediaStore.setRequireOriginal(uri)
        }
        return resolver.openInputStream(uri) ?: throw FileNotFoundException(source)
    }

    /** [jobKey] is unique per attempt (Dart), so a cancel that arrives before the copy
     * starts still stops it. */
    private fun copy(source: String, doc: Uri, jobKey: String): Map<String, Any?> {
        val digest = MessageDigest.getInstance("SHA-256")
        var total = 0L
        var lastEmit = 0L
        try {
            openSource(source).use { input ->
                val pfd = resolver.openFileDescriptor(doc, "w")
                    ?: throw IOException("no file descriptor")
                // Closing the stream closes the descriptor; a provider that reports a failed
                // write on close throws here, so the copy fails.
                ParcelFileDescriptor.AutoCloseOutputStream(pfd).use { out ->
                    val buf = ByteArray(CHUNK)
                    while (true) {
                        if (disposed || cancelled.remove(jobKey)) throw CancelledException()
                        val n = input.read(buf)
                        if (n < 0) break
                        out.write(buf, 0, n)
                        digest.update(buf, 0, n)
                        total += n
                        val now = SystemClock.elapsedRealtime()
                        if (now - lastEmit >= PROGRESS_MS) {
                            lastEmit = now
                            emit(jobKey, total)
                        }
                    }
                    out.flush()
                    // The bytes must be on the provider's storage before the read-back and
                    // before any original is deleted (power loss after a "done" copy).
                    try {
                        pfd.fileDescriptor.sync()
                    } catch (e: SyncFailedException) {
                        // Pipe-backed providers can't fsync; their close() reports the result.
                        Log.w(TAG, "fsync not supported for $doc: $e")
                    }
                }
            }
        } catch (e: Exception) {
            try {
                DocumentsContract.deleteDocument(resolver, doc)
            } catch (d: Exception) {
                Log.w(TAG, "partial document not deleted: $d")
            }
            throw e
        } finally {
            cancelled.remove(jobKey)
        }
        emit(jobKey, total)
        return mapOf("sha256" to hex(digest.digest()), "bytes" to total)
    }

    private fun emit(jobKey: String, bytes: Long) {
        main.post { progressSink?.success(mapOf("jobKey" to jobKey, "bytes" to bytes)) }
    }

    private fun hash(doc: Uri): Map<String, Any?> {
        val digest = MessageDigest.getInstance("SHA-256")
        var total = 0L
        (resolver.openInputStream(doc) ?: throw FileNotFoundException(doc.toString())).use { input ->
            val buf = ByteArray(CHUNK)
            while (true) {
                if (disposed) throw CancelledException()
                val n = input.read(buf)
                if (n < 0) break
                digest.update(buf, 0, n)
                total += n
            }
        }
        return mapOf("sha256" to hex(digest.digest()), "bytes" to total)
    }

    private fun stat(doc: Uri): Long? = try {
        resolver.query(doc, arrayOf(Document.COLUMN_SIZE), null, null, null)?.use { c ->
            if (c.moveToFirst() && !c.isNull(0)) c.getLong(0) else null
        }
    } catch (e: FileNotFoundException) {
        null
    } catch (e: IllegalArgumentException) {
        null
    }

    private fun delete(doc: Uri): Boolean = try {
        if (!DocumentsContract.deleteDocument(resolver, doc)) {
            throw IOException("deleteDocument refused $doc")
        }
        true
    } catch (e: FileNotFoundException) {
        true
    } catch (e: IllegalArgumentException) {
        true
    }

    private fun hex(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it) }

    companion object {
        private const val TAG = "kfm.cloud"
        private const val CHUNK = 1024 * 1024
        private const val PROGRESS_MS = 250L
        private val METHODS = setOf(
            "cloudTreeLabel", "cloudCreate", "cloudCopy", "cloudHash", "cloudStat", "cloudDelete",
            "cloudCancel",
        )
    }
}
