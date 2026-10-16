package com.example.six_minute_walk_test

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "six_minute_walk_test/platform_metadata",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCommitHash" -> result.success(BuildConfig.GIT_COMMIT.ifEmpty { null })
                "getAndroidId" -> {
                    try {
                        result.success(Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID))
                    } catch (exception: Exception) {
                        result.error("metadata_unavailable", exception.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
