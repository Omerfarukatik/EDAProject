package com.example.edadeneme

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.util.*

class UsageStatsHelper(private val context: Context) {

    fun getAppUsageData(range: String): Map<String, Any> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis

        // Zaman filtresi
        when (range.lowercase()) {
            "günlük" -> calendar.add(Calendar.DAY_OF_YEAR, -1)
            "haftalık" -> calendar.add(Calendar.DAY_OF_YEAR, -7)
            "aylık" -> calendar.add(Calendar.DAY_OF_YEAR, -30)
            else -> calendar.add(Calendar.DAY_OF_YEAR, -1)
        }

        val startTime = calendar.timeInMillis
        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        val appStartTimes = mutableMapOf<String, Long>()
        val appDurations = mutableMapOf<String, Long>()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val packageName = event.packageName

            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    appStartTimes[packageName] = event.timeStamp
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val startTimeForApp = appStartTimes[packageName]
                    if (startTimeForApp != null) {
                        val duration = event.timeStamp - startTimeForApp
                        val existingDuration = appDurations.getOrDefault(packageName, 0L)
                        appDurations[packageName] = existingDuration + duration
                        appStartTimes.remove(packageName)
                    }
                }
            }
        }

        var totalDuration: Long = 0
        val appList = mutableListOf<Map<String, Any>>()

        for ((packageName, durationMs) in appDurations) {
            val pm = context.packageManager

            // Uygulama adını güvenli şekilde al veya tahmin et
            val appName = try {
                val appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                val label = pm.getApplicationLabel(appInfo)
                if (!label.isNullOrBlank()) label.toString() else guessAppNameFromPackage(packageName)
            } catch (e: Exception) {
                guessAppNameFromPackage(packageName)
            }

            // Uygulama ikonunu Base64'e çevir
            val iconBase64 = try {
                val drawable = pm.getApplicationIcon(packageName)
                if (drawable is BitmapDrawable) {
                    val bitmap = drawable.bitmap
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    val byteArray = stream.toByteArray()
                    Base64.encodeToString(byteArray, Base64.NO_WRAP)
                } else {
                    ""
                }
            } catch (e: Exception) {
                ""
            }

            totalDuration += durationMs

            appList.add(
                mapOf(
                    "appName" to appName,
                    "duration" to durationMs,
                    "icon" to iconBase64
                )
            )
        }

        return mapOf(
            "totalTime" to totalDuration,
            "apps" to appList
        )
    }

    // Paket adından anlamlı ad üretici
    private fun guessAppNameFromPackage(packageName: String): String {
        val parts = packageName.split(".")
        return if (parts.isNotEmpty()) {
            val raw = parts.last()
            raw.replaceFirstChar { it.uppercaseChar() }
        } else {
            packageName
}
}
}