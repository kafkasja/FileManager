package com.kaf.kfm

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var filesChannel: FilesChannel? = null
    private var geocoderChannel: GeocoderChannel? = null
    private var shareServiceChannel: ShareServiceChannel? = null
    private var volumesChannel: VolumesChannel? = null
    private var mtpChannel: MtpChannel? = null
    private var safChannel: SafChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        filesChannel = FilesChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        geocoderChannel = GeocoderChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        shareServiceChannel = ShareServiceChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        volumesChannel = VolumesChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger, this)
        mtpChannel = MtpChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        safChannel = SafChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
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
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /** U1: a camera attached while KFM runs (singleTop; X1's singleTask too). */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        mtpChannel?.onNewIntent(intent)
    }

    @Deprecated("Needed for MediaStore consent dialogs and the SAF tree picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (filesChannel?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
