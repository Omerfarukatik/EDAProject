package com.example.edadeneme

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.ibekazi.edaui/channel"
    private val CHANNEL_USAGE = "com.ekranhareketi/usage"
    private val KEYBOARD_CHANNEL = "keyboard_monitor_channel"
    private val REQUEST_MEDIA_PROJECTION = 1

    // Bu iki değişken MediaProjection sırasında parent/child id'yi saklamak için
    private var projectionParentId: String? = null
    private var projectionChildId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. FirebaseUsageService Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "firebase_usage_channel").setMethodCallHandler { call, result ->
            when (call.method) {
                "startUsageService" -> {
                    val parentId = call.argument<String>("parentId")
                    val childId = call.argument<String>("childId")
                    if (parentId != null && childId != null) {
                        val intent = Intent(this, FirebaseUsageService::class.java).apply {
                            putExtra("parentId", parentId)
                            putExtra("childId", childId)
                        }
                        ContextCompat.startForegroundService(this, intent)
                        result.success(null)
                    } else {
                        result.error("MISSING_ARGS", "parentId veya childId eksik", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Ekran Kaydı Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startProjection" -> {
                    val parentId = call.argument<String>("parentId")
                    val childId = call.argument<String>("childId")

                    if (parentId == null || childId == null) {
                        result.error("ARGS_MISSING", "parentId veya childId eksik", null)
                        return@setMethodCallHandler
                    }

                    // onActivityResult'ta kullanılmak üzere saklanıyor
                    projectionParentId = parentId
                    projectionChildId = childId

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

        // 3. Klavye Channel
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

        // 4. Kullanım İstatistikleri Channel
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
            val parentId = projectionParentId
            val childId = projectionChildId

            if (parentId != null && childId != null) {
                val serviceIntent = Intent(this, ScreenCaptureService::class.java).apply {
                    putExtra("resultCode", resultCode)
                    putExtra("data", data)
                    putExtra("parentId", parentId)
                    putExtra("childId", childId)
                }
                ContextCompat.startForegroundService(this, serviceIntent)
            }
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
