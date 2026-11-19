package com.example.faktur_gen

import android.content.Intent
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    // The in-app updater downloads the APK into cacheDir and hands it to the
    // system installer through the FileProvider.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "faktur/native").setMethodCallHandler { call, result ->
            when (call.method) {
                "supportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                "installApk" -> {
                    val path = call.argument<String>("path")
                    // The FileProvider only shares cacheDir.
                    if (path != null && File(path).canonicalFile.startsWith(cacheDir.canonicalFile)) {
                        try {
                            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", File(path))
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_PATH", "APK must be in the app cache", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
