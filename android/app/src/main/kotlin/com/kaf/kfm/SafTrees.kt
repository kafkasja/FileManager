package com.kaf.kfm

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * SAF tree picker on `com.kaf.kfm/files` (TASK-U1; X3 reuses it for cloud folders).
 *
 * - `pickTree {uuid?}` → `{uri, treeDocumentId}` or null (cancelled). With a volume uuid the
 *   picker opens at that volume (API 29+ createOpenDocumentTreeIntent, API 26–28 initial
 *   URI, API 24–25 plain picker).
 * - `persistTree {uri}` / `releaseTree {uri}` (READ|WRITE) → bool.
 * - `persistedTrees` → the persisted tree URIs.
 * - `validateTree {uri}` → true when the grant is persisted and the tree's root document
 *   answers with FLAG_DIR_SUPPORTS_CREATE (a reformatted stick fails).
 */
class SafTrees(private val activity: Activity) {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val context: Context get() = activity.applicationContext
    private var pending: MethodChannel.Result? = null

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
        if (call.method == "pickTree") {
            pickTree(call.argument<String>("uuid"), result)
            return
        }
        io.execute {
            try {
                val value: Any? = when (call.method) {
                    "persistTree" -> persist(uriArg(call), take = true)
                    "releaseTree" -> persist(uriArg(call), take = false)
                    "persistedTrees" -> context.contentResolver.persistedUriPermissions
                        .filter { DocumentsContract.isTreeUri(it.uri) }
                        .map { it.uri.toString() }
                    "validateTree" -> validate(uriArg(call))
                    else -> throw IllegalArgumentException(call.method)
                }
                main.post { result.success(value) }
            } catch (e: IllegalArgumentException) {
                main.post { result.error("BAD_ARGS", e.toString(), null) }
            } catch (e: Exception) {
                main.post { result.error("IO", e.toString(), null) }
            }
        }
    }

    /** Forwarded from FilesChannel.onActivityResult. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_REQUEST) return false
        val r = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            r.success(null)
            return true
        }
        val docId = try {
            DocumentsContract.getTreeDocumentId(uri)
        } catch (e: Exception) {
            null
        }
        r.success(mapOf("uri" to uri.toString(), "treeDocumentId" to docId))
        return true
    }

    private fun pickTree(uuid: String?, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("IO", "a picker is already open", null)
            return
        }
        try {
            val intent = treeIntent(uuid)
            pending = result
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, PICK_REQUEST)
        } catch (e: Exception) {
            pending = null
            result.error("IO", e.toString(), null)
        }
    }

    private fun treeIntent(uuid: String?): Intent {
        if (uuid != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val storage = context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
            storage.storageVolumes.firstOrNull { it.uuid == uuid }?.let {
                return it.createOpenDocumentTreeIntent()
            }
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        if (uuid != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intent.putExtra(
                DocumentsContract.EXTRA_INITIAL_URI,
                DocumentsContract.buildDocumentUri(EXTERNAL_STORAGE_AUTHORITY, "$uuid:"),
            )
        }
        return intent
    }

    private fun uriArg(call: MethodCall): Uri =
        Uri.parse(call.argument<String>("uri") ?: throw IllegalArgumentException("uri missing"))

    private fun persist(uri: Uri, take: Boolean): Boolean {
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        return try {
            if (take) {
                context.contentResolver.takePersistableUriPermission(uri, flags)
            } else {
                context.contentResolver.releasePersistableUriPermission(uri, flags)
            }
            true
        } catch (e: SecurityException) {
            Log.w(TAG, "persist=$take failed for $uri: $e")
            false
        }
    }

    private fun validate(tree: Uri): Boolean {
        val persisted = context.contentResolver.persistedUriPermissions.any {
            it.uri == tree && it.isReadPermission && it.isWritePermission
        }
        if (!persisted) return false
        return try {
            val doc = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
            context.contentResolver.query(
                doc,
                arrayOf(DocumentsContract.Document.COLUMN_FLAGS),
                null,
                null,
                null,
            )?.use { c ->
                c.moveToFirst() && (c.getInt(0) and DocumentsContract.Document.FLAG_DIR_SUPPORTS_CREATE) != 0
            } ?: false
        } catch (e: Exception) {
            Log.w(TAG, "validate failed for $tree: $e")
            false
        }
    }

    companion object {
        private const val TAG = "kfm.saf"
        private const val PICK_REQUEST = 4102
        private const val EXTERNAL_STORAGE_AUTHORITY = "com.android.externalstorage.documents"
        private val METHODS = setOf("pickTree", "persistTree", "releaseTree", "persistedTrees", "validateTree")
    }
}
