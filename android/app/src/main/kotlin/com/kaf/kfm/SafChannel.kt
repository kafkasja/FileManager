package com.kaf.kfm

import android.content.ContentResolver
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Point
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * `com.kaf.kfm/saf` (TASK-U2): files inside persisted SAF trees (U1 grants), through
 * DocumentsContract only (no androidx.documentfile: one query per folder, never a stat per
 * file).
 *
 * Every call takes `tree` (the tree URI) and a document id (`doc`, `parent`). Rows:
 * `{id, name, mime, size, modified, flags}` (`mime` = `vnd.android.document/directory` for
 * folders). Error codes: NOT_FOUND, PERMISSION, NO_SPACE, UNSUPPORTED, IO.
 */
class SafChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.kaf.kfm/saf")
    private val io = Executors.newFixedThreadPool(2)
    private val main = Handler(Looper.getMainLooper())
    private val resolver: ContentResolver get() = context.contentResolver

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        io.execute {
            try {
                val tree = Uri.parse(call.argument<String>("tree") ?: throw IllegalArgumentException("tree"))
                val value: Any? = when (call.method) {
                    "list" -> list(tree, str(call, "doc"))
                    "stat" -> stat(tree, str(call, "doc"))
                    "read" -> read(tree, str(call, "doc"), long(call, "start"), int(call, "length"))
                    "copyOut" -> copyOut(tree, str(call, "doc"), str(call, "path"))
                    "importFile" -> importFile(
                        tree, str(call, "parent"), str(call, "name"),
                        call.argument<String>("mime"), str(call, "path"),
                    )
                    "createDir" -> createDir(tree, str(call, "parent"), str(call, "name"))
                    "rename" -> rename(tree, str(call, "doc"), str(call, "name"))
                    "move" -> move(tree, str(call, "doc"), str(call, "from"), str(call, "to"))
                    "delete" -> delete(tree, str(call, "doc"))
                    "sha256" -> sha256(tree, str(call, "doc"))
                    "thumbnail" -> thumbnail(tree, str(call, "doc"), int(call, "size"))
                    "writeText" -> writeText(tree, str(call, "parent"), str(call, "name"), str(call, "text"))
                    "readText" -> readText(tree, str(call, "parent"), str(call, "name"))
                    else -> {
                        main.post { result.notImplemented() }
                        return@execute
                    }
                }
                main.post { result.success(value) }
            } catch (e: FileNotFoundException) {
                main.post { result.error("NOT_FOUND", e.toString(), null) }
            } catch (e: SecurityException) {
                main.post { result.error("PERMISSION", e.toString(), null) }
            } catch (e: UnsupportedOperationException) {
                main.post { result.error("UNSUPPORTED", e.toString(), null) }
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

    private fun str(call: MethodCall, key: String): String =
        call.argument<String>(key) ?: throw IllegalArgumentException(key)

    private fun int(call: MethodCall, key: String): Int =
        call.argument<Int>(key) ?: throw IllegalArgumentException(key)

    private fun long(call: MethodCall, key: String): Long =
        (call.argument<Any>(key) as? Number)?.toLong() ?: throw IllegalArgumentException(key)

    private fun docUri(tree: Uri, doc: String): Uri =
        DocumentsContract.buildDocumentUriUsingTree(tree, doc)

    private val projection = arrayOf(
        Document.COLUMN_DOCUMENT_ID,
        Document.COLUMN_DISPLAY_NAME,
        Document.COLUMN_MIME_TYPE,
        Document.COLUMN_SIZE,
        Document.COLUMN_LAST_MODIFIED,
        Document.COLUMN_FLAGS,
    )

    private fun row(c: android.database.Cursor): Map<String, Any?> = mapOf(
        "id" to c.getString(0),
        "name" to c.getString(1),
        "mime" to c.getString(2),
        "size" to if (c.isNull(3)) 0L else c.getLong(3),
        "modified" to if (c.isNull(4)) 0L else c.getLong(4),
        "flags" to if (c.isNull(5)) 0 else c.getInt(5),
    )

    /** One query on the children URI (fast); never a stat per child. */
    private fun list(tree: Uri, doc: String): List<Map<String, Any?>> {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, doc)
        val out = ArrayList<Map<String, Any?>>()
        resolver.query(children, projection, null, null, null)?.use { c ->
            while (c.moveToNext()) out.add(row(c))
        } ?: throw FileNotFoundException("no folder $doc")
        return out
    }

    private fun stat(tree: Uri, doc: String): Map<String, Any?>? = try {
        resolver.query(docUri(tree, doc), projection, null, null, null)?.use { c ->
            if (c.moveToFirst()) row(c) else null
        }
    } catch (e: FileNotFoundException) {
        null
    } catch (e: IllegalArgumentException) {
        null // externalstorage throws this for a missing document
    }

    private fun read(tree: Uri, doc: String, start: Long, length: Int): ByteArray {
        resolver.openInputStream(docUri(tree, doc))?.use { input ->
            var skipped = 0L
            while (skipped < start) {
                val n = input.skip(start - skipped)
                if (n <= 0) return ByteArray(0)
                skipped += n
            }
            val buf = ByteArray(length)
            var read = 0
            while (read < length) {
                val n = input.read(buf, read, length - read)
                if (n < 0) break
                read += n
            }
            return if (read == length) buf else buf.copyOf(read)
        } ?: throw FileNotFoundException(doc)
    }

    /** Copies the document into the app-private file [path]; returns its size and SHA-256. */
    private fun copyOut(tree: Uri, doc: String, path: String): Map<String, Any?> {
        val digest = MessageDigest.getInstance("SHA-256")
        var total = 0L
        val target = File(path)
        try {
            resolver.openInputStream(docUri(tree, doc))?.use { input ->
                target.outputStream().use { out ->
                    val buf = ByteArray(BUFFER)
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        out.write(buf, 0, n)
                        digest.update(buf, 0, n)
                        total += n
                    }
                    out.fd.sync()
                }
            } ?: throw FileNotFoundException(doc)
        } catch (e: Exception) {
            target.delete()
            throw e
        }
        return mapOf("size" to total, "sha256" to hex(digest.digest()))
    }

    /** Creates [name] in [parent] and streams the local file [path] into it. The partial
     * document is deleted when anything fails. */
    private fun importFile(tree: Uri, parent: String, name: String, mime: String?, path: String): Map<String, Any?>? {
        val created = DocumentsContract.createDocument(
            resolver, docUri(tree, parent), mime ?: "application/octet-stream", name,
        ) ?: throw IOException("createDocument refused $name")
        try {
            // Through the file descriptor so the bytes are synced before close (a pulled stick
            // must not leave a "complete" file whose tail never reached the disk).
            val pfd = resolver.openFileDescriptor(created, "w") ?: throw IOException("no descriptor")
            pfd.use { d ->
                FileOutputStream(d.fileDescriptor).use { out ->
                    File(path).inputStream().use { input ->
                        val buf = ByteArray(BUFFER)
                        while (true) {
                            val n = input.read(buf)
                            if (n < 0) break
                            out.write(buf, 0, n)
                        }
                        out.flush()
                        out.fd.sync()
                    }
                }
            }
        } catch (e: Exception) {
            try {
                DocumentsContract.deleteDocument(resolver, created)
            } catch (_: Exception) {
            }
            throw e
        }
        return stat(tree, DocumentsContract.getDocumentId(created))
    }

    private fun createDir(tree: Uri, parent: String, name: String): Map<String, Any?>? {
        val created = DocumentsContract.createDocument(
            resolver, docUri(tree, parent), Document.MIME_TYPE_DIR, name,
        ) ?: throw IOException("createDocument refused $name")
        return stat(tree, DocumentsContract.getDocumentId(created))
    }

    private fun rename(tree: Uri, doc: String, name: String): Map<String, Any?>? {
        // API < 29 answers null on failure instead of throwing.
        val renamed = DocumentsContract.renameDocument(resolver, docUri(tree, doc), name)
            ?: throw IOException("renameDocument refused $name")
        return stat(tree, DocumentsContract.getDocumentId(renamed))
    }

    /** Same-tree move; null when the provider can't (the caller copies instead). */
    private fun move(tree: Uri, doc: String, from: String, to: String): Map<String, Any?>? {
        val moved = (
            try {
                DocumentsContract.moveDocument(resolver, docUri(tree, doc), docUri(tree, from), docUri(tree, to))
            } catch (e: UnsupportedOperationException) {
                null
            } catch (e: IllegalStateException) {
                null
            }
            ) ?: return null
        return stat(tree, DocumentsContract.getDocumentId(moved))
    }

    /** True = gone; a refused delete (API < 29 answers false) throws. */
    private fun delete(tree: Uri, doc: String): Boolean = try {
        if (!DocumentsContract.deleteDocument(resolver, docUri(tree, doc))) {
            throw IOException("deleteDocument refused $doc")
        }
        true
    } catch (e: FileNotFoundException) {
        true // gone already: the goal is reached
    } catch (e: IllegalArgumentException) {
        true
    }

    private fun sha256(tree: Uri, doc: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        resolver.openInputStream(docUri(tree, doc))?.use { input ->
            val buf = ByteArray(BUFFER)
            while (true) {
                val n = input.read(buf)
                if (n < 0) break
                digest.update(buf, 0, n)
            }
        } ?: throw FileNotFoundException(doc)
        return hex(digest.digest())
    }

    /** The provider's thumbnail, else a downsampled decode (images only). */
    private fun thumbnail(tree: Uri, doc: String, size: Int): ByteArray? {
        val uri = docUri(tree, doc)
        val provided: Bitmap? = try {
            DocumentsContract.getDocumentThumbnail(resolver, uri, Point(size, size), null)
        } catch (e: Exception) {
            null
        }
        val bitmap = provided ?: decodeSampled(uri, size)
        bitmap ?: return null
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, out)
        bitmap.recycle()
        return out.toByteArray()
    }

    private fun decodeSampled(uri: Uri, size: Int): Bitmap? = try {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            null
        } else {
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= size && bounds.outHeight / (sample * 2) >= size) {
                sample *= 2
            }
            val opts = BitmapFactory.Options().apply { inSampleSize = sample }
            resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, opts) }
        }
    } catch (e: Exception) {
        null
    }

    private fun childId(tree: Uri, parent: String, name: String): String? =
        list(tree, parent).firstOrNull { it["name"] == name }?.get("id") as String?

    /** Creates or truncates [name] in [parent] and writes [text] (D4's `.index.jsonl`). */
    private fun writeText(tree: Uri, parent: String, name: String, text: String): Boolean {
        val existing = childId(tree, parent, name)
        val uri = if (existing != null) {
            docUri(tree, existing)
        } else {
            DocumentsContract.createDocument(resolver, docUri(tree, parent), "application/octet-stream", name)
                ?: throw IOException("createDocument refused $name")
        }
        resolver.openOutputStream(uri, "wt")?.use { it.write(text.toByteArray()) }
            ?: throw IOException("no output stream")
        return true
    }

    private fun readText(tree: Uri, parent: String, name: String): String? {
        val id = childId(tree, parent, name) ?: return null
        return resolver.openInputStream(docUri(tree, id))?.use { it.readBytes().toString(Charsets.UTF_8) }
    }

    private fun hex(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it) }

    companion object {
        private const val BUFFER = 1 shl 20
    }
}
