package io.github.normalllll.freepiv

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.github.normalllll.freepiv.download.DownloadBridge
import android.view.KeyEvent
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var readerChannel: MethodChannel? = null
    private var readerVolumeEnabled = false
    private val capturedVolumeKeys = mutableSetOf<Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DownloadBridge.attach(this, flutterEngine.dartExecutor.binaryMessenger)
        FanboxLoginBridge.attach(this, flutterEngine.dartExecutor.binaryMessenger)
        readerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "freepiv/reader_volume_keys").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "setEnabled") {
                    readerVolumeEnabled = call.arguments == true && hasWindowFocus()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode != KeyEvent.KEYCODE_VOLUME_UP && event.keyCode != KeyEvent.KEYCODE_VOLUME_DOWN) {
            return super.dispatchKeyEvent(event)
        }
        // Retain ownership of an already captured press through its key-up,
        // even if a dialog or lifecycle change disables capture in between.
        if (event.action == KeyEvent.ACTION_UP && capturedVolumeKeys.remove(event.keyCode)) return true
        // A fresh down also clears a key-up lost while the Activity was paused.
        if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) capturedVolumeKeys.remove(event.keyCode)
        if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount > 0 && capturedVolumeKeys.contains(event.keyCode)) return true
        if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0 && readerVolumeEnabled && hasWindowFocus()) {
            capturedVolumeKeys.add(event.keyCode)
            readerChannel?.invokeMethod("turn", if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) 1 else -1)
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) readerVolumeEnabled = false
        readerChannel?.invokeMethod("focus", hasFocus)
    }

    override fun onPause() {
        readerVolumeEnabled = false
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        readerVolumeEnabled = false
        capturedVolumeKeys.clear()
        readerChannel?.setMethodCallHandler(null)
        readerChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (DownloadBridge.onRequestPermissionsResult(requestCode, permissions, grantResults)) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
