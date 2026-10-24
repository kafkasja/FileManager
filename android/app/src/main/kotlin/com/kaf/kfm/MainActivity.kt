package com.kaf.kfm

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var filesChannel: FilesChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        filesChannel = FilesChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        filesChannel?.dispose()
        filesChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("Needed for MediaStore consent dialogs (startIntentSenderForResult)")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (filesChannel?.onActivityResult(requestCode, resultCode) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
