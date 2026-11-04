package com.kaf.kfm

import android.app.ActivityManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.lang.ref.WeakReference

class MainActivity : FlutterActivity() {
    companion object {
        /** The live instance (main thread only). */
        private var live: WeakReference<MainActivity>? = null
    }

    private var filesChannel: FilesChannel? = null
    private var geocoderChannel: GeocoderChannel? = null
    private var shareServiceChannel: ShareServiceChannel? = null
    private var volumesChannel: VolumesChannel? = null
    private var mtpChannel: MtpChannel? = null
    private var safChannel: SafChannel? = null
    private var shareInChannel: ShareInChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        filesChannel = FilesChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        geocoderChannel = GeocoderChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        shareServiceChannel = ShareServiceChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        volumesChannel = VolumesChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger, this)
        mtpChannel = MtpChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        safChannel = SafChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        shareInChannel = ShareInChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    /** X1: a share that started KFM. Not on a recreation or a Recents relaunch. */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Turning the phone crossfades instead of rotating a snapshot of the
        // old screen: the default animation squeezed a playing video for a
        // moment (S22, 2026-11-04).
        window.attributes = window.attributes.apply {
            rotationAnimation = WindowManager.LayoutParams.ROTATION_ANIMATION_CROSSFADE
        }
        val fromHistory = ((intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        // One instance only (see the manifest): Recents can still restore a second KFM task
        // (e.g. one left over from a build with taskAffinity="", or a dead duplicate) and
        // start a MainActivity in it, ignoring launchMode. Hand the launch to the live
        // instance and drop this task. finish() in onCreate skips onStart, so this
        // instance's Flutter engine never runs Dart.
        val other = live?.get()
        if (other != null && other !== this && !other.isFinishing && !other.isDestroyed &&
            other.taskId != taskId
        ) {
            if (savedInstanceState == null && !fromHistory) intent?.let { other.onNewIntent(it) }
            appTask(other.taskId)?.moveToFront()
            finishAndRemoveTask()
            return
        }
        live = WeakReference(this)
        // No other instance is alive: any other KFM task in Recents is an empty duplicate.
        removeOtherTasks()
        if (savedInstanceState == null && !fromHistory) takeShare(intent)
    }

    override fun onDestroy() {
        if (live?.get() === this) live = null
        super.onDestroy()
    }

    private fun appTasks(): List<ActivityManager.AppTask> =
        getSystemService(ActivityManager::class.java)?.appTasks ?: emptyList()

    @Suppress("DEPRECATION")
    private fun idOf(task: ActivityManager.AppTask): Int? = try {
        val info = task.taskInfo
        if (Build.VERSION.SDK_INT >= 29) info.taskId else info.persistentId
    } catch (e: IllegalArgumentException) {
        null // the task went away meanwhile
    }

    private fun appTask(id: Int) = appTasks().firstOrNull { idOf(it) == id }

    private fun removeOtherTasks() {
        for (task in appTasks()) {
            val id = idOf(task) ?: continue
            if (id != taskId) {
                try {
                    task.finishAndRemoveTask()
                } catch (e: IllegalArgumentException) {
                    // already gone
                }
            }
        }
    }

    /** X1: hands a share to [ShareInChannel] once, then forgets it. */
    private fun takeShare(intent: Intent?) {
        if (shareInChannel?.handle(intent) == true) {
            setIntent(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER))
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        filesChannel?.dispose()
        filesChannel = null
        geocoderChannel?.dispose()
        geocoderChannel = null
        shareServiceChannel?.dispose()
        shareServiceChannel = null
        volumesChannel?.dispose()
        volumesChannel = null
        mtpChannel?.dispose()
        mtpChannel = null
        safChannel?.dispose()
        safChannel = null
        shareInChannel?.dispose()
        shareInChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /** U1: a camera attached while KFM runs; X1: a share while KFM runs (singleTask). */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        mtpChannel?.onNewIntent(intent)
        takeShare(intent)
    }

    @Deprecated("Needed for MediaStore consent dialogs and the SAF tree picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (filesChannel?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
