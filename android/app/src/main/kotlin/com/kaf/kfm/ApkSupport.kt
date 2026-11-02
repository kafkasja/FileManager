package com.kaf.kfm

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.StatFs
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.ByteArrayOutputStream
import java.io.File
import java.security.MessageDigest
import java.util.UUID

/**
 * TASK-X5: reads an `.apk` before install and hands it to Android's own installer.
 * Methods are dispatched from [FilesChannel] (`inspectApk` on its io thread, the rest on
 * the main thread). KFM never installs anything itself.
 */
class ApkSupport(private val context: Context) {
    class ApkError(val code: String, message: String) : Exception(message)

    private val cacheRoot: File get() = File(context.cacheDir, "apk")

    /**
     * Inspects a plain file ([path]) in place, or a `content://` file ([uri]) through a
     * copy in `cacheDir/apk/` (`getPackageArchiveInfo` needs a path). The returned `path`
     * is what [install] and [discardCopy] take.
     */
    fun inspect(path: String?, uri: String?, sizeBytes: Long): Map<String, Any?> {
        val file: File
        var isCopy = false
        if (path != null) {
            file = File(path)
            if (!file.isFile) throw ApkError("NOT_FOUND", "no such file")
        } else if (uri != null) {
            val free = StatFs(context.cacheDir.path).availableBytes
            if (free <= sizeBytes + RESERVE_BYTES) throw ApkError("NO_SPACE", "cache has $free bytes")
            cacheRoot.mkdirs()
            file = File(cacheRoot, "${UUID.randomUUID()}.apk")
            try {
                val input = context.contentResolver.openInputStream(Uri.parse(uri))
                    ?: throw ApkError("NOT_FOUND", "cannot open uri")
                input.use { i -> file.outputStream().use { o -> i.copyTo(o) } }
            } catch (e: Exception) {
                file.delete()
                throw e
            }
            isCopy = true
        } else {
            throw ApkError("BAD_ARGS", "path or uri needed")
        }
        try {
            return describe(file) + mapOf("path" to file.path, "isCopy" to isCopy)
        } catch (e: Exception) {
            if (isCopy) file.delete()
            throw e
        }
    }

    private fun describe(file: File): Map<String, Any?> {
        val pm = context.packageManager
        val archive = archiveInfo(pm, file.path, signingFlag())
            ?: archiveInfo(pm, file.path, 0)
            ?: throw ApkError("INVALID_APK", "not a package")
        val app = archive.applicationInfo ?: throw ApkError("INVALID_APK", "no application")
        app.sourceDir = file.path
        app.publicSourceDir = file.path
        val label = try {
            app.loadLabel(pm).toString()
        } catch (e: Exception) {
            archive.packageName
        }
        val icon = try {
            val drawable = app.loadIcon(pm)
            val bitmap = Bitmap.createBitmap(ICON_PX, ICON_PX, Bitmap.Config.ARGB_8888)
            drawable.setBounds(0, 0, ICON_PX, ICON_PX)
            drawable.draw(Canvas(bitmap))
            ByteArrayOutputStream().use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                bitmap.recycle()
                out.toByteArray()
            }
        } catch (e: Exception) {
            null
        }
        val pkg = archive.packageName
        val installed = try {
            installedInfo(pm, pkg)
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
        // API 30+: other apps can be hidden from KFM, so "not found" isn't "not installed".
        val visible = installed != null || Build.VERSION.SDK_INT < Build.VERSION_CODES.R ||
            pkg == context.packageName
        val sameSigner: Boolean? = if (installed == null) {
            null
        } else {
            val a = signerDigests(archive)
            val b = signerDigests(installed)
            if (a.isEmpty() || b.isEmpty()) null else a == b
        }
        return mapOf(
            "label" to label,
            "packageName" to pkg,
            "versionName" to (archive.versionName ?: ""),
            "versionCode" to versionCode(archive),
            "iconPng" to icon,
            "installedVisible" to visible,
            "installedVersionName" to installed?.let { it.versionName ?: "" },
            "installedVersionCode" to installed?.let { versionCode(it) },
            "sameSigner" to sameSigner,
        )
    }

    /** API 24–25 have no per-app toggle: the system installer applies "Unknown sources". */
    fun canInstall(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
        context.packageManager.canRequestPackageInstalls()

    fun openPermissionSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
            .setData(Uri.parse("package:${context.packageName}"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /** Android's installer for [path] (a shared-storage file or a cache copy). */
    fun install(path: String): Boolean {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", File(path))
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, MIME)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /** Deletes a copy made by [inspect]; anything outside `cacheDir/apk/` is left alone. */
    fun discardCopy(path: String): Boolean {
        val f = File(path).canonicalFile
        if (f.parentFile != cacheRoot.canonicalFile) return false
        return f.delete()
    }

    private fun signingFlag(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }

    private fun archiveInfo(pm: PackageManager, path: String, flags: Int): PackageInfo? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getPackageArchiveInfo(path, PackageManager.PackageInfoFlags.of(flags.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageArchiveInfo(path, flags)
        }

    private fun installedInfo(pm: PackageManager, pkg: String): PackageInfo =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(signingFlag().toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(pkg, signingFlag())
        }

    private fun versionCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }

    /** SHA-256 hex digests of the signing certificates (empty when unknown). */
    private fun signerDigests(info: PackageInfo): Set<String> {
        val sigs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            info.signatures
        } ?: return emptySet()
        return sigs.map { s ->
            MessageDigest.getInstance("SHA-256").digest(s.toByteArray())
                .joinToString("") { "%02x".format(it) }
        }.toSet()
    }

    companion object {
        const val MIME = "application/vnd.android.package-archive"
        private const val ICON_PX = 96
        private const val RESERVE_BYTES = 50L * 1024 * 1024
    }
}
