package com.kaf.kfm

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * `com.kaf.kfm/files`: MediaStore and storage operations that plugins don't cover (TASK-F3).
 * Every call runs on a background thread and replies on the main thread.
 *
 * Error codes (mapped to FileOpFailure in Dart): NOT_FOUND, NEEDS_CONSENT, NOT_ALLOWED,
 * TARGET_EXISTS, CROSS_VOLUME, PERMISSION_DENIED, BAD_ARGS, IO, INTERRUPTED.
 */
class FilesChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.kaf.kfm/files")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val context: Context get() = activity.applicationContext
    /** The Dart call waiting for the one system dialog that can be open (TASK-H1). */
    private var pendingResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        // The engine may outlive this activity one day (N1, cached engine): never leave
        // a Dart future hanging. Today the engine dies too, so this reply goes nowhere.
        pendingResult?.let { r ->
            pendingResult = null
            try {
                r.error("INTERRUPTED", "activity destroyed while a system dialog was open", null)
            } catch (e: Exception) {
                Log.w(TAG, "could not answer an interrupted request: $e")
            }
        }
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    /** Forwarded from MainActivity.onActivityResult. Returns true if handled. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != CONSENT_REQUEST) return false
        val r = pendingResult
        if (r == null) {
            // Result for a request made by a previous activity/engine. The system already
            // applied (or skipped) the change; Dart reconciles from the file state.
            Log.w(TAG, "system dialog result after recreation, granted=${resultCode == Activity.RESULT_OK}")
            return true
        }
        pendingResult = null
        r.success(resultCode == Activity.RESULT_OK)
        return true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestWriteConsent" -> {
                requestWriteConsent(call, result)
                return
            }
            "openMediaManagementSettings" -> {
                openMediaManagementSettings(result)
                return
            }
            "trashMedia" -> {
                trashMedia(call, result)
                return
            }
            "deleteMedia" -> {
                deleteMedia(call, result)
                return
            }
        }
        io.execute {
            try {
                val value: Any? = when (call.method) {
                    "sdkInt" -> Build.VERSION.SDK_INT
                    "queryMedia" -> queryMedia(call)
                    "statMedia" -> statMedia(call.longArg("id"))
                    "moveMedia" -> moveMedia(call.longArg("id"), call.stringArg("targetDir"), call.stringArg("displayName"))
                    "renameMedia" -> renameMedia(call.longArg("id"), call.stringArg("displayName"))
                    "copyMedia" -> copyMedia(call.longArg("id"), call.stringArg("targetDir"), call.stringArg("displayName"))
                    "scanPaths" -> scanPaths(call.argument<List<String>>("paths") ?: emptyList())
                    "storageVolumes" -> storageVolumes()
                    "hasAllFilesAccess" -> canUseFiles()
                    "listTrashed" -> listTrashed()
                    "canManageMedia" -> Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                        MediaStore.canManageMedia(context)
                    else -> {
                        main.post { result.notImplemented() }
                        return@execute
                    }
                }
                main.post { result.success(value) }
            } catch (e: FilesError) {
                main.post { result.error(e.code, e.message, null) }
            } catch (e: SecurityException) {
                main.post { result.error("PERMISSION_DENIED", e.toString(), null) }
            } catch (e: Exception) {
                main.post { result.error("IO", e.toString(), null) }
            }
        }
    }

    // ---- query ----

    private val filesUri: Uri = MediaStore.Files.getContentUri("external")

    private val projection = arrayOf(
        MediaStore.Files.FileColumns._ID,
        MediaStore.Files.FileColumns.DISPLAY_NAME,
        MediaStore.Files.FileColumns.MIME_TYPE,
        MediaStore.Files.FileColumns.MEDIA_TYPE,
        MediaStore.Files.FileColumns.SIZE,
        MediaStore.Files.FileColumns.DATE_MODIFIED,
        COL_DATE_TAKEN,
        COL_WIDTH,
        COL_HEIGHT,
        COL_DURATION,
        @Suppress("DEPRECATION") MediaStore.Files.FileColumns.DATA,
    )

    /**
     * One page of media, newest `date_modified` first, keyset-paged by (date_modified, _id).
     * Args: kinds (image/video/audio), root?, modifiedAfter? (s), minSize?, afterModified?, afterId?, limit.
     */
    private fun queryMedia(call: MethodCall): List<Map<String, Any?>> {
        val kinds = call.argument<List<String>>("kinds") ?: listOf("image", "video", "audio")
        val mediaTypes = kinds.mapNotNull {
            when (it) {
                "image" -> MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
                "video" -> MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                "audio" -> MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO
                else -> null
            }
        }
        if (mediaTypes.isEmpty()) return emptyList()
        val limit = call.argument<Int>("limit") ?: 500

        val where = StringBuilder("${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (${mediaTypes.joinToString(",")})")
        val args = mutableListOf<String>()
        call.argument<String>("root")?.let {
            @Suppress("DEPRECATION")
            where.append(" AND ${MediaStore.Files.FileColumns.DATA} LIKE ? ESCAPE '\\'")
            args.add(escapeLike(it.trimEnd('/')) + "/%")
        }
        call.argument<Number>("modifiedAfter")?.let {
            // Inclusive: DATE_MODIFIED has 1 s resolution; the F5 index dedupes by id.
            where.append(" AND ${MediaStore.Files.FileColumns.DATE_MODIFIED} >= ?")
            args.add(it.toLong().toString())
        }
        call.argument<Number>("minSize")?.let {
            where.append(" AND ${MediaStore.Files.FileColumns.SIZE} >= ?")
            args.add(it.toLong().toString())
        }
        val afterModified = call.argument<Number>("afterModified")?.toLong()
        val afterId = call.argument<Number>("afterId")?.toLong()
        if (afterModified != null && afterId != null) {
            val mod = MediaStore.Files.FileColumns.DATE_MODIFIED
            val id = MediaStore.Files.FileColumns._ID
            where.append(" AND ($mod < ? OR ($mod = ? AND $id < ?))")
            args.add(afterModified.toString())
            args.add(afterModified.toString())
            args.add(afterId.toString())
        }
        val order = "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC, ${MediaStore.Files.FileColumns._ID} DESC"
        return query(where.toString(), args.toTypedArray(), order, limit).use { readAll(it) }
    }

    private fun statMedia(id: Long): Map<String, Any?>? =
        query("${MediaStore.Files.FileColumns._ID} = ?", arrayOf(id.toString()), null, 1)
            .use { readAll(it).firstOrNull() }

    private fun query(where: String, args: Array<String>, order: String?, limit: Int): Cursor {
        val resolver = context.contentResolver
        val cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bundle = Bundle().apply {
                putString(android.content.ContentResolver.QUERY_ARG_SQL_SELECTION, where)
                putStringArray(android.content.ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, args)
                if (order != null) putString(android.content.ContentResolver.QUERY_ARG_SQL_SORT_ORDER, order)
                putInt(android.content.ContentResolver.QUERY_ARG_LIMIT, limit)
            }
            resolver.query(filesUri, projection, bundle, null)
        } else {
            val sort = (order ?: MediaStore.Files.FileColumns._ID) + " LIMIT $limit"
            resolver.query(filesUri, projection, where, args, sort)
        }
        return cursor ?: throw FilesError("IO", "MediaStore query returned null")
    }

    private fun readAll(c: Cursor, withExpires: Boolean = false): List<Map<String, Any?>> {
        val out = ArrayList<Map<String, Any?>>(c.count)
        val iId = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
        val iName = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
        val iMime = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)
        val iType = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE)
        val iSize = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
        val iMod = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
        val iTaken = c.getColumnIndex(COL_DATE_TAKEN)
        val iW = c.getColumnIndex(COL_WIDTH)
        val iH = c.getColumnIndex(COL_HEIGHT)
        val iDur = c.getColumnIndex(COL_DURATION)
        @Suppress("DEPRECATION")
        val iData = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA)
        val iExpires = if (withExpires) c.getColumnIndex(MediaStore.MediaColumns.DATE_EXPIRES) else -1
        while (c.moveToNext()) {
            val path = c.getString(iData) ?: continue
            val id = c.getLong(iId)
            val mediaType = c.getInt(iType)
            out.add(
                mapOf(
                    "id" to id,
                    "uri" to ContentUris.withAppendedId(collectionFor(mediaType), id).toString(),
                    "path" to path,
                    "name" to (c.getString(iName) ?: File(path).name),
                    "mime" to c.getString(iMime),
                    "mediaType" to mediaTypeName(mediaType),
                    "size" to c.getLong(iSize),
                    "modified" to c.getLong(iMod),
                    "taken" to c.longOrNull(iTaken)?.takeIf { it > 0 },
                    "width" to c.longOrNull(iW)?.toInt()?.takeIf { it > 0 },
                    "height" to c.longOrNull(iH)?.toInt()?.takeIf { it > 0 },
                    "duration" to c.longOrNull(iDur)?.takeIf { it > 0 },
                    "expires" to c.longOrNull(iExpires),
                ),
            )
        }
        return out
    }

    // ---- write ----

    private fun moveMedia(id: Long, targetDir: String, displayName: String): Map<String, Any?> {
        val old = statMedia(id) ?: throw FilesError("NOT_FOUND", "media $id not found")
        val oldPath = old["path"] as String
        if (volumeRoot(oldPath) != volumeRoot(targetDir)) {
            throw FilesError("CROSS_VOLUME", "move across volumes")
        }
        if (File(targetDir, displayName).exists()) throw FilesError("TARGET_EXISTS", displayName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val updated = tryUpdate(id, old, ContentValues().apply {
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath(targetDir))
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            })
            if (updated != null) return updated
        }
        return legacyRename(oldPath, File(targetDir, displayName))
    }

    private fun renameMedia(id: Long, displayName: String): Map<String, Any?> {
        val old = statMedia(id) ?: throw FilesError("NOT_FOUND", "media $id not found")
        val oldFile = File(old["path"] as String)
        val target = File(oldFile.parentFile, displayName)
        if (target.exists()) throw FilesError("TARGET_EXISTS", displayName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val updated = tryUpdate(id, old, ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            })
            if (updated != null) return updated
        }
        return legacyRename(oldFile.path, target)
    }

    /**
     * MediaStore update (keeps the id). Returns null when the caller should fall back to a
     * direct file rename (allowed with legacy storage or All files access).
     */
    private fun tryUpdate(id: Long, old: Map<String, Any?>, values: ContentValues): Map<String, Any?>? {
        val uri = Uri.parse(old["uri"] as String)
        try {
            val rows = context.contentResolver.update(uri, values, null, null)
            if (rows == 0) throw FilesError("NOT_FOUND", "media $id not updated")
            return statMedia(id) ?: throw FilesError("NOT_FOUND", "media $id gone after update")
        } catch (e: SecurityException) {
            if (canUseFiles()) return null
            throw FilesError("NEEDS_CONSENT", e.toString())
        } catch (e: IllegalArgumentException) {
            // e.g. a photo moved outside DCIM/Pictures on API 30+.
            if (canUseFiles()) return null
            throw FilesError("NOT_ALLOWED", e.toString())
        }
    }

    /** Direct rename + media scan. The MediaStore id changes. */
    private fun legacyRename(oldPath: String, target: File): Map<String, Any?> {
        if (!canUseFiles()) throw FilesError("NOT_ALLOWED", "no direct file access")
        target.parentFile?.mkdirs()
        if (!File(oldPath).renameTo(target)) throw FilesError("IO", "rename failed: $oldPath")
        scanPaths(listOf(oldPath, target.path))
        return statByPath(target.path) ?: throw FilesError("IO", "not indexed after move: ${target.path}")
    }

    private fun copyMedia(id: Long, targetDir: String, displayName: String): Map<String, Any?> {
        val src = statMedia(id) ?: throw FilesError("NOT_FOUND", "media $id not found")
        val target = File(targetDir, displayName)
        if (target.exists()) throw FilesError("TARGET_EXISTS", displayName)
        if (canUseFiles()) {
            val srcFile = File(src["path"] as String)
            target.parentFile?.mkdirs()
            srcFile.copyTo(target)
            target.setLastModified(srcFile.lastModified())
            scanPaths(listOf(target.path))
            return statByPath(target.path) ?: throw FilesError("IO", "not indexed after copy: ${target.path}")
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) throw FilesError("NOT_ALLOWED", "no write access")
        val collection = collectionForName(src["mediaType"] as String)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, src["mime"] as String?)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath(targetDir))
            put(MediaStore.MediaColumns.IS_PENDING, 1)
            (src["taken"] as Long?)?.let { put(COL_DATE_TAKEN, it) }
        }
        val resolver = context.contentResolver
        val newUri = try {
            resolver.insert(collection, values)
        } catch (e: IllegalArgumentException) {
            throw FilesError("NOT_ALLOWED", e.toString())
        } ?: throw FilesError("IO", "insert failed")
        try {
            resolver.openInputStream(Uri.parse(src["uri"] as String)).use { input ->
                resolver.openOutputStream(newUri).use { output ->
                    if (input == null || output == null) throw FilesError("IO", "stream open failed")
                    input.copyTo(output)
                }
            }
            resolver.update(newUri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
        } catch (e: Exception) {
            resolver.delete(newUri, null, null) // no partial file left behind
            throw if (e is FilesError) e else FilesError("IO", e.toString())
        }
        return statMedia(ContentUris.parseId(newUri)) ?: throw FilesError("IO", "copy not found")
    }

    /** Returns path → MediaStore id (null when the scanner didn't index it, e.g. deleted). */
    private fun scanPaths(paths: List<String>): Map<String, Long?> {
        if (paths.isEmpty()) return emptyMap()
        val result = HashMap<String, Long?>()
        val latch = CountDownLatch(paths.size)
        MediaScannerConnection.scanFile(context, paths.toTypedArray(), null) { path, uri ->
            synchronized(result) { result[path] = uri?.let { runCatching { ContentUris.parseId(it) }.getOrNull() } }
            latch.countDown()
        }
        latch.await(30, TimeUnit.SECONDS)
        return result
    }

    private fun statByPath(path: String): Map<String, Any?>? {
        @Suppress("DEPRECATION")
        val col = MediaStore.Files.FileColumns.DATA
        return query("$col = ?", arrayOf(path), null, 1).use { readAll(it).firstOrNull() }
    }

    // ---- consent ----

    private fun requestWriteConsent(call: MethodCall, result: MethodChannel.Result) {
        val uris = call.uris()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R || uris.isEmpty()) {
            // API ≤29 relies on legacy storage; nothing to ask.
            result.success(true)
            return
        }
        if (pendingResult != null) {
            result.error("IO", "consent request already in progress", null)
            return
        }
        launchRequest(result) { MediaStore.createWriteRequest(context.contentResolver, uris) }
    }

    /**
     * Shows one system dialog for a MediaStore request (skipped by the system when the app
     * holds Media management) and replies true when the user allowed it.
     */
    private fun launchRequest(result: MethodChannel.Result, create: () -> android.app.PendingIntent) {
        if (pendingResult != null) {
            result.error("IO", "a system request is already in progress", null)
            return
        }
        try {
            val intent = create()
            pendingResult = result
            activity.startIntentSenderForResult(intent.intentSender, CONSENT_REQUEST, null, 0, 0, 0)
        } catch (e: Exception) {
            pendingResult = null
            result.error("IO", e.toString(), null)
        }
    }

    // ---- trash (TASK-D3) ----

    /** API 30+: move to (value=true) or out of (false) the system trash. One dialog per call. */
    private fun trashMedia(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            result.error("UNSUPPORTED", "no system trash below API 30", null)
            return
        }
        val uris = call.uris()
        val value = call.argument<Boolean>("value") ?: true
        if (uris.isEmpty()) {
            result.success(true)
            return
        }
        launchRequest(result) { MediaStore.createTrashRequest(context.contentResolver, uris, value) }
    }

    /**
     * Permanent delete. API 30+: one system dialog per call. Below: direct delete (legacy
     * storage), on the background thread.
     */
    private fun deleteMedia(call: MethodCall, result: MethodChannel.Result) {
        val uris = call.uris()
        if (uris.isEmpty()) {
            result.success(true)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Rows this app created (e.g. a swipe copy being undone) can be
            // deleted directly; only other apps' files need the dialog.
            io.execute {
                val others = mutableListOf<Uri>()
                try {
                    for (uri in uris) {
                        if (isOwnedByUs(uri)) {
                            context.contentResolver.delete(uri, null, null)
                        } else {
                            others.add(uri)
                        }
                    }
                } catch (e: SecurityException) {
                    main.post { result.error("PERMISSION_DENIED", e.toString(), null) }
                    return@execute
                } catch (e: Exception) {
                    main.post { result.error("IO", e.toString(), null) }
                    return@execute
                }
                main.post {
                    if (others.isEmpty()) {
                        result.success(true)
                    } else {
                        launchRequest(result) {
                            MediaStore.createDeleteRequest(context.contentResolver, others)
                        }
                    }
                }
            }
            return
        }
        io.execute {
            try {
                for (uri in uris) {
                    val row = statMedia(ContentUris.parseId(uri)) ?: continue
                    File(row["path"] as String).delete()
                    context.contentResolver.delete(uri, null, null)
                }
                main.post { result.success(true) }
            } catch (e: SecurityException) {
                main.post { result.error("PERMISSION_DENIED", e.toString(), null) }
            } catch (e: Exception) {
                main.post { result.error("IO", e.toString(), null) }
            }
        }
    }

    private fun isOwnedByUs(uri: Uri): Boolean =
        context.contentResolver.query(
            uri,
            arrayOf(MediaStore.MediaColumns.OWNER_PACKAGE_NAME),
            null,
            null,
            null,
        )?.use { c -> c.moveToFirst() && c.getString(0) == context.packageName } ?: false

    /** API 30+: everything in the system trash this app can see. */
    private fun listTrashed(): List<Map<String, Any?>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return emptyList()
        val bundle = Bundle().apply {
            putInt(MediaStore.QUERY_ARG_MATCH_TRASHED, MediaStore.MATCH_ONLY)
            putString(
                android.content.ContentResolver.QUERY_ARG_SQL_SELECTION,
                "${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (" +
                    "${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE}," +
                    "${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}," +
                    "${MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO})",
            )
            putString(
                android.content.ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                "${MediaStore.MediaColumns.DATE_EXPIRES} DESC",
            )
        }
        val cols = projection + MediaStore.MediaColumns.DATE_EXPIRES
        val cursor = context.contentResolver.query(filesUri, cols, bundle, null)
            ?: throw FilesError("IO", "trash query returned null")
        return cursor.use { readAll(it, withExpires = true) }
    }

    /** "Media management apps" special access page for this app (API 31+). */
    private fun openMediaManagementSettings(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            result.success(false)
            return
        }
        try {
            val intent = Intent(android.provider.Settings.ACTION_REQUEST_MANAGE_MEDIA)
                .setData(Uri.parse("package:${context.packageName}"))
            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("IO", e.toString(), null)
        }
    }

    // ---- volumes ----

    private fun storageVolumes(): List<Map<String, Any?>> {
        val primary = Environment.getExternalStorageDirectory().path
        val out = mutableListOf<Map<String, Any?>>(
            mapOf("path" to primary, "label" to null, "removable" to false, "primary" to true),
        )
        // getExternalFilesDirs gives <volume>/Android/data/<pkg>/files for each mounted volume.
        for (dir in context.getExternalFilesDirs(null).drop(1)) {
            val root = dir?.path?.substringBefore("/Android/data/") ?: continue
            out.add(mapOf("path" to root, "label" to null, "removable" to true, "primary" to false))
        }
        return out
    }

    // ---- helpers ----

    private fun canUseFiles(): Boolean = when {
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q -> true
        Build.VERSION.SDK_INT == Build.VERSION_CODES.Q -> Environment.isExternalStorageLegacy()
        else -> Environment.isExternalStorageManager()
    }

    private fun volumeRoot(path: String): String =
        VOLUME_ROOT.find(path)?.value?.trimEnd('/') ?: throw FilesError("BAD_ARGS", "not on a storage volume: $path")

    private fun relativePath(dir: String): String {
        val rel = dir.trimEnd('/').removePrefix(volumeRoot(dir)).trimStart('/')
        if (rel.isEmpty()) throw FilesError("NOT_ALLOWED", "media can't live in the volume root")
        return "$rel/"
    }

    private fun collectionFor(mediaType: Int): Uri = when (mediaType) {
        MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        else -> filesUri
    }

    private fun collectionForName(name: String): Uri = when (name) {
        "image" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        "video" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        else -> throw FilesError("BAD_ARGS", "not media: $name")
    }

    private fun mediaTypeName(mediaType: Int): String = when (mediaType) {
        MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE -> "image"
        MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO -> "video"
        MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO -> "audio"
        else -> "other"
    }

    private fun escapeLike(s: String) = s.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")

    private fun Cursor.longOrNull(index: Int): Long? =
        if (index < 0 || isNull(index)) null else getLong(index)

    /** Collection-specific content URIs (Images/Video/Audio): MediaStore's
     *  write/trash/delete requests reject generic Files URIs. */
    private fun MethodCall.uris(): List<Uri> =
        argument<List<String>>("uris")?.map { Uri.parse(it) } ?: emptyList()

    private fun MethodCall.longArg(name: String): Long =
        argument<Number>(name)?.toLong() ?: throw FilesError("BAD_ARGS", "missing $name")

    private fun MethodCall.stringArg(name: String): String =
        argument<String>(name) ?: throw FilesError("BAD_ARGS", "missing $name")

    private class FilesError(val code: String, message: String) : Exception(message)

    companion object {
        private const val TAG = "kfm.files"
        private const val CONSENT_REQUEST = 4101
        // Column names exist in the files table on every supported API level.
        private const val COL_DATE_TAKEN = "datetaken"
        private const val COL_WIDTH = "width"
        private const val COL_HEIGHT = "height"
        private const val COL_DURATION = "duration"
        private val VOLUME_ROOT = Regex("^/storage/(emulated/\\d+|[^/]+)(/|$)")
    }
}
