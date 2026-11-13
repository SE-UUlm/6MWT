package de.uniulm.`in`.se.sixmwt

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "six_minute_walk_test/vibration",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrateAlarm" -> {
                    try {
                        val pattern = requireNotNull(call.argument<LongArray>("pattern")) {
                            "Missing vibration pattern"
                        }
                        vibrateAlarm(pattern)
                        result.success(null)
                    } catch (exception: Exception) {
                        result.error("vibration_failed", exception.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // Vibrates with alarm usage, which Android also plays in silent and
    // vibrate-only ringer mode (unlike notification vibrations).
    private fun vibrateAlarm(pattern: LongArray) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (!vibrator.hasVibrator()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vibrator.vibrate(
                VibrationEffect.createWaveform(pattern, -1),
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM),
            )
            return
        }

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1), audioAttributes)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1, audioAttributes)
        }
    }
}
