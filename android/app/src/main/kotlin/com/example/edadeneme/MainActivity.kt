package com.example.edadeneme

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.ibekazi.edaui/channel"
    private val CHANNEL_USAGE = "com.ekranhareketi/usage"
    private val KEYBOARD_CHANNEL = "keyboard_monitor_channel"
    private val REQUEST_MEDIA_PROJECTION = 1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Ekran Kaydı Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startProjection" -> {
                    val mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as android.media.projection.MediaProjectionManager
                    val captureIntent = mediaProjectionManager.createScreenCaptureIntent()
                    startActivityForResult(captureIntent, REQUEST_MEDIA_PROJECTION)
                    result.success(null)
                }
                "hideApp" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                "stopService" -> {
                    stopService(Intent(this, ScreenCaptureService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Klavye Channel
        val keyboardChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_CHANNEL)
        KeyboardAccessibilityService.channel = keyboardChannel

        keyboardChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 3. Kullanım İstatistikleri Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_USAGE).setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsageStats" -> {
                    try {
                        val filter = call.argument<String>("range") ?: "Günlük"
                        val helper = UsageStatsHelper(this)
                        val usageData = helper.getAppUsageData(filter)
                        result.success(usageData)
                    } catch (e: Exception) {
                        result.error("USAGE_ERROR", e.message, null)
                    }
                }
                "openUsageSettings" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_MEDIA_PROJECTION && resultCode == Activity.RESULT_OK && data != null) {
            val serviceIntent = Intent(this, ScreenCaptureService::class.java).apply {
                putExtra("resultCode", resultCode)
                putExtra("data", data)
            }
            startService(serviceIntent)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
