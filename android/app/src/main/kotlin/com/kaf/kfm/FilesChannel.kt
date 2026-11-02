package com.kaf.kfm

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.MediaMetadataRetriever
import android.media.ThumbnailUtils
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import androidx.exifinterface.media.ExifInterface
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
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
    /** C5: EXIF batches run here, so they never delay moves/trash calls on [io]. */
    private val exifIo = Executors.newSingleThreadExecutor()
    /** H7: file thumbnails while scrolling; two threads, apart from [io] (moves, trash). */
    private val thumbIo = Executors.newFixedThreadPool(2)
    /** B10: file details sheet lookups; never queued behind moves or EXIF batches. */
    private val detailsIo = Executors.newSingleThreadExecutor()
    /** X2: copies of originals for location removal; big videos never stall [io]. */
    private val privacyIo = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val context: Context get() = activity.applicationContext
    /** The Dart call waiting for the one system dialog that can be open (TASK-H1). */
    private var pendingResult: MethodChannel.Result? = null
    /** U1 (shared with X3): SAF tree picker and persisted grants. */
    private val safTrees = SafTrees(activity)

    /** N7: Files-table changes (non-media files) while the share server runs. */
    private val changesChannel = EventChannel(messenger, "kfm/files_changes")
    private val observerIo = Executors.newSingleThreadExecutor()
    private var filesObserver: ContentObserver? = null
    private var changesSink: EventChannel.EventSink? = null

    init {
        channel.setMethodCallHandler(this)
        changesChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                changesSink = events
                startObservingFiles()
            }

            override fun onCancel(arguments: Any?) {
                stopObservingFiles()
                changesSink = null
            }
        })
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
        safTrees.dispose()
        stopObservingFiles()
        changesSink = null
        changesChannel.setStreamHandler(null)
        observerIo.shutdown()
        io.shutdown()
        exifIo.shutdown()
        thumbIo.shutdown()
        detailsIo.shutdown()
        privacyIo.shutdown()
    }

    /** Forwarded from MainActivity.onActivityResult. Returns true if handled. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (safTrees.onActivityResult(requestCode, resultCode, data)) return true
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
        if (safTrees.handles(call.method)) {
            safTrees.onMethodCall(call, result)
            return
        }
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
            "fileThumbnail" -> {
                val path = call.argument<String>("path")
                val size = call.argument<Number>("size")?.toInt() ?: 256
                if (path == null) {
                    result.error("BAD_ARGS", "path missing", null)
                    return
                }
                thumbIo.execute {
                    val bytes = fileThumbnail(path, size)
                    main.post { result.success(bytes) }
                }
                return
            }
            "fileDetails", "appInfo", "openAppDetails" -> {
                detailsIo.execute {
                    try {
                        val value: Any? = when (call.method) {
                            "fileDetails" -> fileDetails(
                                call.stringArg("path"),
                                call.argument<Number>("id")?.toLong(),
                            )
                            "appInfo" -> appInfo(call.stringArg("package"))
                            else -> openAppDetails(call.stringArg("package"))
                        }
                        main.post { result.success(value) }
                    } catch (e: FilesError) {
                        main.post { result.error(e.code, e.message, null) }
                    } catch (e: Exception) {
                        main.post { result.error("IO", e.toString(), null) }
                    }
                }
                return
            }
            "copyOriginal" -> {
                privacyIo.execute {
                    try {
                        val value = copyOriginal(
                            call.argument<String>("contentUri"),
                            call.stringArg("path"),
                            call.stringArg("outPath"),
                        )
                        main.post { result.success(value) }
                    } catch (e: FilesError) {
                        main.post { result.error(e.code, e.message, null) }
                    } catch (e: SecurityException) {
                        main.post { result.error("PERMISSION_DENIED", e.toString(), null) }
                    } catch (e: Exception) {
                        main.post { result.error("IO", e.toString(), null) }
                    }
                }
                return
            }
            "readExif", "readExifPaths" -> {
                exifIo.execute {
                    try {
                        val value = if (call.method == "readExif") {
                            readExif(call.argument<List<Number>>("ids").orEmpty().map { it.toLong() })
                        } else {
                            readExifPaths(call.argument<List<String>>("paths").orEmpty())
                        }
                        main.post { result.success(value) }
                    } catch (e: Exception) {
                        main.post { result.error("IO", e.toString(), null) }
                    }
                }
                return
            }
        }
        io.execute {
            try {
                val value: Any? = when (call.method) {
                    "sdkInt" -> Build.VERSION.SDK_INT
                    // N1: default share name ("Galaxy S22 Ultra" style when the
                    // model already starts with the maker, else "Maker Model").
                    "deviceModel" -> deviceModel()
                    "queryMedia" -> queryMedia(call)
                    "statMedia" -> statMedia(call.longArg("id"))
                    "statMediaByPath" -> statMediaByPath(call.stringArg("path"))
                    "freeBytes" -> freeBytes(call.stringArg("path"))
                    "storageSpace" -> storageSpace()
                    "moveMedia" -> moveMedia(call.longArg("id"), call.stringArg("targetDir"), call.stringArg("displayName"))
                    "renameMedia" -> renameMedia(call.longArg("id"), call.stringArg("displayName"))
                    "copyMedia" -> copyMedia(call.longArg("id"), call.stringArg("targetDir"), call.stringArg("displayName"))
                    "importMedia" -> importMedia(
                        call.stringArg("stagedPath"),
                        call.stringArg("targetDir"),
                        call.stringArg("displayName"),
                        call.argument<String>("mime"),
                    )
                    "scanPaths" -> scanPaths(call.argument<List<String>>("paths") ?: emptyList())
                    "hasAllFilesAccess" -> canUseFiles()
                    "listTrashed" -> listTrashed()
                    "openWith" -> openWith(
                        call.argument<String>("contentUri"),
                        call.argument<String>("path"),
                        call.argument<String>("mime"),
                    )
                    "shareFile" -> shareFile(
                        call.stringArg("path"),
                        call.stringArg("mime"),
                        call.argument<String>("subject"),
                    )
                    "shareFiles" -> shareFiles(
                        call.argument<List<Map<String, Any?>>>("items").orEmpty(),
                    )
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

    // ---- Files-table observer (TASK-N7 live sync) ----

    /**
     * Observes `MediaStore.Files` (descendants). Each change is sent as
     * `{type: insert|update|delete, path?, mediaType?}`; pending rows are skipped (they
     * report again when published). A row that can't be found (deleted, or hidden from
     * this app) comes without a path: Dart reconciles the shared folders instead.
     */
    private fun startObservingFiles() {
        if (filesObserver != null) return
        val observer = object : ContentObserver(main) {
            // API < 30 entry point (API 30+ calls the one with flags).
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                reportFilesChange(uri, 0)
            }

            override fun onChange(selfChange: Boolean, uri: Uri?, flags: Int) {
                reportFilesChange(uri, flags)
            }
        }
        try {
            context.contentResolver.registerContentObserver(
                MediaStore.Files.getContentUri("external"), true, observer,
            )
            filesObserver = observer
        } catch (e: Exception) {
            changesSink?.error("IO", e.toString(), null)
        }
    }

    private fun stopObservingFiles() {
        filesObserver?.let { context.contentResolver.unregisterContentObserver(it) }
        filesObserver = null
    }

    private fun reportFilesChange(uri: Uri?, flags: Int) {
        val type = when {
            flags and android.content.ContentResolver.NOTIFY_DELETE != 0 -> "delete"
            flags and android.content.ContentResolver.NOTIFY_INSERT != 0 -> "insert"
            else -> "update"
        }
        val id = uri?.lastPathSegment?.toLongOrNull()
        try {
            observerIo.execute {
                val event: Map<String, Any?> = (
                    try {
                        describeFilesChange(type, id)
                    } catch (e: Exception) {
                        Log.w(TAG, "files change lookup failed: $e")
                        mapOf("type" to type)
                    }
                    ) ?: return@execute
                main.post { changesSink?.success(event) }
            }
        } catch (e: java.util.concurrent.RejectedExecutionException) {
            // Disposed meanwhile.
        }
    }

    /** Null = skip (pending row). */
    private fun describeFilesChange(type: String, id: Long?): Map<String, Any?>? {
        if (id == null) return mapOf("type" to type)
        if (type == "delete") return mapOf("type" to type, "id" to id)
        val resolver = context.contentResolver
        @Suppress("DEPRECATION")
        val dataCol = MediaStore.Files.FileColumns.DATA
        val typeCol = MediaStore.Files.FileColumns.MEDIA_TYPE
        val pendingCol = "is_pending"
        val withPending = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        val cols = if (withPending) arrayOf(dataCol, typeCol, pendingCol) else arrayOf(dataCol, typeCol)
        val where = "${MediaStore.Files.FileColumns._ID} = ?"
        val args = arrayOf(id.toString())
        val cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bundle = Bundle().apply {
                putString(android.content.ContentResolver.QUERY_ARG_SQL_SELECTION, where)
                putStringArray(android.content.ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, args)
                putInt(MediaStore.QUERY_ARG_MATCH_PENDING, MediaStore.MATCH_INCLUDE)
            }
            resolver.query(MediaStore.Files.getContentUri("external"), cols, bundle, null)
        } else {
            resolver.query(MediaStore.Files.getContentUri("external"), cols, where, args, null)
        }
        cursor?.use { c ->
            if (!c.moveToFirst()) return mapOf("type" to type, "id" to id)
            if (withPending && c.getInt(c.getColumnIndexOrThrow(pendingCol)) != 0) return null
            return mapOf(
                "type" to type,
                "id" to id,
                "path" to c.getString(c.getColumnIndexOrThrow(dataCol)),
                "mediaType" to c.getInt(c.getColumnIndexOrThrow(typeCol)),
            )
        }
        return mapOf("type" to type, "id" to id)
    }

    // ---- EXIF (TASK-C5) ----

    /**
     * Per MediaStore image id: `{id, lat?, lng?, frontCamera, locationReadable}` or
     * `{id, error}`. With ACCESS_MEDIA_LOCATION (API 29+) the original is opened, so
     * GPS isn't stripped; without it `locationReadable` is false.
     */
    private fun readExif(ids: List<Long>): List<Map<String, Any?>> {
        val original = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            context.checkSelfPermission(Manifest.permission.ACCESS_MEDIA_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        return ids.map { id ->
            try {
                var uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                if (original && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    uri = MediaStore.setRequireOriginal(uri)
                }
                val exif = context.contentResolver.openInputStream(uri)?.use { ExifInterface(it) }
                    ?: throw FilesError("NOT_FOUND", "no stream")
                exifRow(id, exif, original)
            } catch (e: Exception) {
                mapOf("id" to id, "error" to e.toString())
            }
        }
    }

    /** `path:` images (All files access): read straight from the file. */
    private fun readExifPaths(paths: List<String>): List<Map<String, Any?>> = paths.map { path ->
        try {
            exifRow(path, ExifInterface(path), true)
        } catch (e: Exception) {
            mapOf("id" to path, "error" to e.toString())
        }
    }

    private fun exifRow(id: Any, exif: ExifInterface, locationReadable: Boolean): Map<String, Any?> {
        val latLng = exif.latLong?.takeIf { ll ->
            val lat = ll[0]
            val lng = ll[1]
            // (0, 0) is what many cameras write without a GPS fix.
            !lat.isNaN() && !lng.isNaN() && lat in -90.0..90.0 && lng in -180.0..180.0 &&
                !(lat == 0.0 && lng == 0.0)
        }
        val lens = exif.getAttribute(ExifInterface.TAG_LENS_MODEL)
        fun text(tag: String): String? = exif.getAttribute(tag)?.trim()?.trimEnd('\u0000')?.takeIf { it.isNotBlank() }
        fun positive(tag: String): Double? =
            exif.getAttributeDouble(tag, -1.0).takeIf { it > 0 && !it.isNaN() && !it.isInfinite() }
        return mapOf(
            "id" to id,
            "lat" to latLng?.get(0),
            "lng" to latLng?.get(1),
            "frontCamera" to (lens?.contains("front", ignoreCase = true) == true),
            "locationReadable" to locationReadable,
            // B10 (file details): optional extras, ignored by C5.
            "make" to text(ExifInterface.TAG_MAKE),
            "model" to text(ExifInterface.TAG_MODEL),
            "software" to text(ExifInterface.TAG_SOFTWARE),
            "lens" to lens?.trim()?.takeIf { it.isNotBlank() },
            "iso" to exif.getAttributeInt(ExifInterface.TAG_PHOTOGRAPHIC_SENSITIVITY, 0).takeIf { it > 0 },
            "exposure" to positive(ExifInterface.TAG_EXPOSURE_TIME),
            "fNumber" to positive(ExifInterface.TAG_F_NUMBER),
            "focalLength" to positive(ExifInterface.TAG_FOCAL_LENGTH),
            "description" to text(ExifInterface.TAG_IMAGE_DESCRIPTION),
            "userComment" to text(ExifInterface.TAG_USER_COMMENT),
        )
    }

    // ---- file details (TASK-B10) ----

    /**
     * What MediaStore knows about the file at [path] (row [id] when it's a `ms:` file):
     * `{exists, mediaId?, dateAdded? (epoch s), mime?, owner?, relativePath?, downloadUri?,
     * refererUri?}`. Every column is optional; API 29+ columns are skipped below it.
     */
    private fun fileDetails(path: String, id: Long?): Map<String, Any?> {
        val out = mutableMapOf<String, Any?>("exists" to File(path).exists())
        val q = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        val projection = mutableListOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DATE_ADDED,
            MediaStore.Files.FileColumns.MIME_TYPE,
        )
        if (q) {
            projection += MediaStore.Files.FileColumns.OWNER_PACKAGE_NAME
            projection += MediaStore.Files.FileColumns.RELATIVE_PATH
        }
        @Suppress("DEPRECATION")
        val dataCol = MediaStore.Files.FileColumns.DATA
        val (where, args) = if (id != null) {
            "${MediaStore.Files.FileColumns._ID} = ?" to arrayOf(id.toString())
        } else {
            "$dataCol = ?" to arrayOf(path)
        }
        val files = MediaStore.Files.getContentUri("external")
        var rowId: Long? = null
        try {
            context.contentResolver.query(files, projection.toTypedArray(), where, args, null)?.use { c ->
                if (c.moveToFirst()) {
                    rowId = c.longOrNull(c.getColumnIndex(MediaStore.Files.FileColumns._ID))
                    out["mediaId"] = rowId
                    c.longOrNull(c.getColumnIndex(MediaStore.Files.FileColumns.DATE_ADDED))
                        ?.takeIf { it > 0 }?.let { out["dateAdded"] = it }
                    out["mime"] = c.stringOrNull(MediaStore.Files.FileColumns.MIME_TYPE)
                    if (q) {
                        out["owner"] = c.stringOrNull(MediaStore.Files.FileColumns.OWNER_PACKAGE_NAME)
                        out["relativePath"] = c.stringOrNull(MediaStore.Files.FileColumns.RELATIVE_PATH)
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "fileDetails: files query failed: $e")
            out["error"] = e.toString()
        }
        val found = rowId
        if (q && found != null) {
            try {
                val dl = arrayOf(MediaStore.DownloadColumns.DOWNLOAD_URI, MediaStore.DownloadColumns.REFERER_URI)
                context.contentResolver.query(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI, dl,
                    "${MediaStore.Downloads._ID} = ?", arrayOf(found.toString()), null,
                )?.use { c ->
                    if (c.moveToFirst()) {
                        out["downloadUri"] = c.stringOrNull(MediaStore.DownloadColumns.DOWNLOAD_URI)
                        out["refererUri"] = c.stringOrNull(MediaStore.DownloadColumns.REFERER_URI)
                    }
                }
            } catch (e: Exception) {
                // Not a download, or the collection isn't readable: no "Downloaded from".
                Log.d(TAG, "fileDetails: downloads query failed: $e")
            }
        }
        return out
    }

    private fun Cursor.stringOrNull(column: String): String? {
        val i = getColumnIndex(column)
        return if (i < 0 || isNull(i)) null else getString(i)?.takeIf { it.isNotBlank() }
    }

    /**
     * `{label, icon? (PNG, 48 dp)}` for an installed package this app can see (launcher
     * `<queries>` on API 30+), or null when it isn't visible or installed.
     */
    private fun appInfo(pkg: String): Map<String, Any?>? {
        val pm = context.packageManager
        val info = try {
            @Suppress("DEPRECATION")
            pm.getApplicationInfo(pkg, 0)
        } catch (e: PackageManager.NameNotFoundException) {
            return null
        }
        val label = pm.getApplicationLabel(info).toString()
        val icon = try {
            val px = (48 * context.resources.displayMetrics.density).toInt().coerceAtLeast(48)
            val drawable = pm.getApplicationIcon(info)
            val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
            val canvas = android.graphics.Canvas(bitmap)
            drawable.setBounds(0, 0, px, px)
            drawable.draw(canvas)
            ByteArrayOutputStream().use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                bitmap.recycle()
                out.toByteArray()
            }
        } catch (e: Exception) {
            null
        }
        return mapOf("label" to label, "icon" to icon)
    }

    /** The system "App info" page of [pkg]. False when it can't be opened. */
    private fun openAppDetails(pkg: String): Boolean {
        val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", pkg, null))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    // ---- file thumbnails (TASK-H7) ----

    /**
     * A square JPEG thumbnail ([size] px) made from the file itself, for files MediaStore
     * doesn't know (`path:` rows: dot-folders, `.nomedia`, ...) or can't thumbnail. Images,
     * videos and audio cover art; null for anything else or a file that doesn't decode.
     * Never throws.
     */
    private fun fileThumbnail(path: String, size: Int): ByteArray? {
        val file = File(path)
        if (!file.isFile) return null
        val ext = path.substringAfterLast('.', "").lowercase()
        val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: return null
        return try {
            val bitmap = when {
                mime.startsWith("image/") -> imageBitmap(file, size)
                mime.startsWith("video/") -> videoBitmap(file, size)
                mime.startsWith("audio/") -> audioBitmap(file, size)
                else -> null
            } ?: return null
            val square = scaleShortSide(bitmap, size)
            ByteArrayOutputStream().use { out ->
                square.compress(Bitmap.CompressFormat.JPEG, 80, out)
                if (square !== bitmap) square.recycle()
                bitmap.recycle()
                out.toByteArray()
            }
        } catch (e: Exception) {
            Log.w(TAG, "no thumbnail for $path: $e")
            null
        } catch (e: OutOfMemoryError) {
            Log.w(TAG, "no thumbnail for $path (out of memory)")
            null
        }
    }

    private fun imageBitmap(file: File, size: Int): Bitmap? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Applies the EXIF rotation; uses the embedded EXIF thumbnail when it's big enough.
            return ThumbnailUtils.createImageThumbnail(file, Size(size, size), CancellationSignal())
        }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val decoded = BitmapFactory.decodeFile(
            file.path,
            BitmapFactory.Options().apply {
                inSampleSize = sampleSize(minOf(bounds.outWidth, bounds.outHeight), size)
            },
        ) ?: return null
        val degrees = try {
            ExifInterface(file.path).rotationDegrees
        } catch (e: Exception) {
            0
        }
        if (degrees == 0) return decoded
        val rotated = Bitmap.createBitmap(
            decoded, 0, 0, decoded.width, decoded.height,
            Matrix().apply { postRotate(degrees.toFloat()) }, true,
        )
        if (rotated !== decoded) decoded.recycle()
        return rotated
    }

    private fun videoBitmap(file: File, size: Int): Bitmap? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ThumbnailUtils.createVideoThumbnail(file, Size(size, size), CancellationSignal())
        } else {
            @Suppress("DEPRECATION")
            ThumbnailUtils.createVideoThumbnail(file.path, MediaStore.Video.Thumbnails.MINI_KIND)
        }

    private fun audioBitmap(file: File, size: Int): Bitmap? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return ThumbnailUtils.createAudioThumbnail(file, Size(size, size), CancellationSignal())
        }
        val art = MediaMetadataRetriever().run {
            try {
                setDataSource(file.path)
                embeddedPicture
            } finally {
                release()
            }
        } ?: return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(art, 0, art.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        return BitmapFactory.decodeByteArray(
            art, 0, art.size,
            BitmapFactory.Options().apply {
                inSampleSize = sampleSize(minOf(bounds.outWidth, bounds.outHeight), size)
            },
        )
    }

    /** Largest power of 2 that keeps the short side at least [target] px. */
    private fun sampleSize(shortSide: Int, target: Int): Int {
        var sample = 1
        while (shortSide / (sample * 2) >= target) sample *= 2
        return sample
    }

    /**
     * Scaled so the short side is [size] (never up), aspect ratio kept. Not
     * cropped: the viewer shows the thumbnail under the full image with
     * BoxFit.contain, so a square crop would peek out above/below it.
     */
    private fun scaleShortSide(src: Bitmap, size: Int): Bitmap {
        val side = minOf(src.width, src.height)
        if (side <= size) return src
        val s = size.toFloat() / side
        return Bitmap.createScaledBitmap(
            src, maxOf(1, (src.width * s).toInt()), maxOf(1, (src.height * s).toInt()), true,
        )
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
            // Inclusive: 1 s resolution; the F5 index dedupes by id. DATE_ADDED
            // too: files copied in with their old modified time (from a PC, a
            // backup, a zip) are new to the index all the same.
            where.append(
                " AND (${MediaStore.Files.FileColumns.DATE_MODIFIED} >= ?" +
                    " OR ${MediaStore.Files.FileColumns.DATE_ADDED} >= ?)",
            )
            args.add(it.toLong().toString())
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

    /**
     * N9: publishes a fully written app-private file ([stagedPath]) as [displayName] in
     * [targetDir] through a MediaStore insert (API 29+ without direct file access). Images,
     * videos and audio go to their collection; anything else, or media the collection refuses
     * under `Download/`, goes to `MediaStore.Downloads`. IS_PENDING hides it until the copy is
     * complete; on failure the row is deleted. MediaStore renames on a name clash. Returns the
     * new row; the staged file is left for the caller to delete.
     */
    private fun importMedia(stagedPath: String, targetDir: String, displayName: String, mimeArg: String?): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) throw FilesError("NOT_ALLOWED", "no write access")
        val staged = File(stagedPath)
        if (!staged.isFile) throw FilesError("NOT_FOUND", "staged file missing")
        if (!targetDir.startsWith(Environment.getExternalStorageDirectory().path)) {
            throw FilesError("NOT_ALLOWED", "only the primary volume")
        }
        val mime = mimeArg
            ?: MimeTypeMap.getSingleton().getMimeTypeFromExtension(File(displayName).extension.lowercase())
            ?: "application/octet-stream"
        val rel = relativePath(targetDir)
        val downloads = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        val primary = when {
            mime.startsWith("image/") -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            mime.startsWith("video/") -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            mime.startsWith("audio/") -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            else -> downloads
        }
        val collections = if (primary != downloads && rel.startsWith("Download/", ignoreCase = true)) {
            listOf(primary, downloads)
        } else {
            listOf(primary)
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, rel)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val resolver = context.contentResolver
        var newUri: Uri? = null
        var refused: Exception? = null
        for (collection in collections) {
            try {
                newUri = resolver.insert(collection, values)
                if (newUri != null) break
            } catch (e: IllegalArgumentException) {
                refused = e // e.g. "Primary directory Download not allowed for images"
            }
        }
        val uri = newUri ?: throw FilesError("NOT_ALLOWED", refused?.toString() ?: "insert failed")
        try {
            staged.inputStream().use { input ->
                resolver.openOutputStream(uri).use { output ->
                    if (output == null) throw FilesError("IO", "stream open failed")
                    input.copyTo(output)
                }
            }
            resolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null) // no partial file left behind
            if (e is FilesError) throw e
            val noSpace = e.toString().contains("ENOSPC") || e.toString().contains("No space")
            throw FilesError(if (noSpace) "NO_SPACE" else "IO", e.toString())
        }
        return statMedia(ContentUris.parseId(uri)) ?: throw FilesError("IO", "import not found")
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

    /**
     * B4: the image/video/audio row at [path], or null (non-media rows are `path:` files).
     * Shared storage is case-insensitive while `_data = ?` is not: a miss retries with LIKE
     * (case-insensitive for ASCII, wildcards escaped). The row carries the stored path.
     */
    private fun statMediaByPath(path: String): Map<String, Any?>? {
        val type = MediaStore.Files.FileColumns.MEDIA_TYPE
        val media = listOf(
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE,
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO,
            MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO,
        ).joinToString(",")
        @Suppress("DEPRECATION")
        val col = MediaStore.Files.FileColumns.DATA
        query("$col = ? AND $type IN ($media)", arrayOf(path), null, 1)
            .use { readAll(it).firstOrNull() }
            ?.let { return it }
        return query("$col LIKE ? ESCAPE '\\' AND $type IN ($media)", arrayOf(escapeLike(path)), null, 1)
            .use { readAll(it).firstOrNull() }
    }

    /** B4: free bytes on the volume holding [path]; null when the path can't be measured. */
    /** C1: total/free bytes of the primary volume. */
    private fun storageSpace(): Map<String, Long> {
        val stat = StatFs(Environment.getExternalStorageDirectory().path)
        return mapOf("totalBytes" to stat.totalBytes, "freeBytes" to stat.availableBytes)
    }

    private fun freeBytes(path: String): Long? = try {
        StatFs(path).availableBytes
    } catch (e: IllegalArgumentException) {
        null
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

    // ---- helpers ----

    private fun deviceModel(): String {
        val maker = Build.MANUFACTURER.orEmpty().trim()
        val model = Build.MODEL.orEmpty().trim()
        if (model.isEmpty()) return maker
        return if (maker.isEmpty() || model.startsWith(maker, ignoreCase = true)) model
        else "${maker.replaceFirstChar { it.uppercase() }} $model"
    }

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

    // ---- open with (TASK-B1) ----

    /**
     * Android "Open with" chooser for a MediaStore item ([contentUri]) or a plain file ([path],
     * shared through the FileProvider). False when no app can open it.
     */
    private fun openWith(contentUri: String?, path: String?, mime: String?): Boolean {
        val uri = when {
            contentUri != null -> Uri.parse(contentUri)
            path != null -> FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", File(path))
            else -> throw FilesError("IO", "openWith: no uri or path")
        }
        val type = mime
            ?: path?.let { MimeTypeMap.getSingleton().getMimeTypeFromExtension(File(it).extension.lowercase()) }
            ?: "*/*"
        val view = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, type)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        @Suppress("DEPRECATION")
        if (context.packageManager.queryIntentActivities(view, 0).isEmpty()) return false
        val chooser = Intent.createChooser(view, null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(chooser)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    // ---- share a log export (TASK-H5) ----

    /**
     * Share sheet for an app file (only `filesDir/logs/export/` is served by the
     * FileProvider). No result is needed, so the dialog slot isn't used.
     */
    private fun shareFile(path: String, mime: String, subject: String?): Boolean {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", File(path))
        val send = Intent(Intent.ACTION_SEND)
            .setType(mime)
            .putExtra(Intent.EXTRA_STREAM, uri)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (subject != null) send.putExtra(Intent.EXTRA_SUBJECT, subject)
        send.clipData = ClipData.newRawUri(subject ?: "", uri)
        val chooser = Intent.createChooser(send, null)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return try {
            context.startActivity(chooser)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    // ---- remove location info (TASK-X2) ----

    /**
     * Copies the file's bytes to [outPath] for location removal (done in Dart). A MediaStore
     * item ([contentUri]) is read through the resolver; with ACCESS_MEDIA_LOCATION on API 29+
     * the original is opened (`setRequireOriginal`), otherwise Android may already have
     * redacted its location. Other files are read from [path]. Returns
     * `{original: bool}` (true = the location was readable, so the copy has it).
     */
    private fun copyOriginal(contentUri: String?, path: String, outPath: String): Map<String, Any?> {
        val out = File(outPath)
        out.parentFile?.mkdirs()
        val granted = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            context.checkSelfPermission(Manifest.permission.ACCESS_MEDIA_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        val input = if (contentUri != null) {
            var uri = Uri.parse(contentUri)
            if (granted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                uri = MediaStore.setRequireOriginal(uri)
            }
            try {
                context.contentResolver.openInputStream(uri)
            } catch (e: java.io.FileNotFoundException) {
                null
            } ?: throw FilesError("NOT_FOUND", "no stream for $contentUri")
        } else {
            val file = File(path)
            if (!file.isFile) throw FilesError("NOT_FOUND", "no file at $path")
            file.inputStream()
        }
        try {
            input.use { src -> out.outputStream().use { dst -> src.copyTo(dst, 256 * 1024) } }
        } catch (e: Exception) {
            out.delete()
            throw e
        }
        return mapOf("original" to (granted || contentUri == null))
    }

    /**
     * Android share sheet (ACTION_SEND / ACTION_SEND_MULTIPLE) for [items]
     * (`{contentUri?, path?, mime?}`): MediaStore items by their URI, files (stripped copies
     * in the cache, shared storage) through the FileProvider. False when no app can receive.
     */
    private fun shareFiles(items: List<Map<String, Any?>>): Boolean {
        if (items.isEmpty()) return false
        val uris = ArrayList<Uri>(items.size)
        val mimes = mutableListOf<String>()
        for (item in items) {
            val contentUri = item["contentUri"] as String?
            val path = item["path"] as String?
            val uri = when {
                contentUri != null -> Uri.parse(contentUri)
                path != null -> FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", File(path))
                else -> throw FilesError("BAD_ARGS", "shareFiles: no uri or path")
            }
            uris.add(uri)
            mimes.add(
                (item["mime"] as String?)
                    ?: path?.let { MimeTypeMap.getSingleton().getMimeTypeFromExtension(File(it).extension.lowercase()) }
                    ?: ANY_MIME,
            )
        }
        val send = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, uris[0])
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
        }
        send.type = commonMime(mimes)
        send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val clip = ClipData.newRawUri("", uris[0])
        for (i in 1 until uris.size) clip.addItem(ClipData.Item(uris[i]))
        send.clipData = clip
        val chooser = Intent.createChooser(send, null)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return try {
            context.startActivity(chooser)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /** One MIME when all match, `image/` + wildcard for mixed images, else [ANY_MIME]. */
    private fun commonMime(mimes: List<String>): String {
        val distinct = mimes.distinct()
        if (distinct.size == 1) return distinct[0]
        val tops = distinct.map { it.substringBefore('/') }.distinct()
        return if (tops.size == 1 && tops[0] != "*") "${tops[0]}/*" else ANY_MIME
    }

    private class FilesError(val code: String, message: String) : Exception(message)

    companion object {
        private const val TAG = "kfm.files"
        private const val CONSENT_REQUEST = 4101
        private const val ANY_MIME = "*/*"
        // Column names exist in the files table on every supported API level.
        private const val COL_DATE_TAKEN = "datetaken"
        private const val COL_WIDTH = "width"
        private const val COL_HEIGHT = "height"
        private const val COL_DURATION = "duration"
        private val VOLUME_ROOT = Regex("^/storage/(emulated/\\d+|[^/]+)(/|$)")
    }
}
