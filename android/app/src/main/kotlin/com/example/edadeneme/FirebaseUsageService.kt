package com.example.edadeneme

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Base64
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.*

class FirebaseUsageService : Service() {
    private val firestore = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()
    private var serviceJob: Job? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val parentId = intent?.getStringExtra("parentId") ?: return START_NOT_STICKY
        val childId = intent.getStringExtra("childId") ?: return START_NOT_STICKY

        serviceJob = CoroutineScope(Dispatchers.IO).launch {
            while (true) {
                try {
                    val usageData = UsageStatsHelper(applicationContext).getAppUsageData("Günlük")
                    val apps = usageData["apps"] as? List<Map<String, Any>> ?: emptyList()
                    val now = Date()

                    for (app in apps) {
                        val appName = app["appName"] as? String ?: continue
                        val duration = (app["duration"] as? Number)?.toLong() ?: 0L
                        val iconBase64 = app["icon"] as? String ?: ""

                        val entry = hashMapOf(
                            "appName" to appName,
                            "duration_minutes" to (duration / 60000).toInt(),
                            "timestamp" to now,
                            "icon" to iconBase64
                        )

                        firestore.collection("parents")
                            .document(parentId)
                            .collection("children")
                            .document(childId)
                            .collection("screentime")
                            .add(entry)
                    }
                    //delay(15 * 60 * 1000) // 15 dakika bekle
                    delay(10* 1000) //10 saniye
                } catch (e: Exception) {
                    Log.e("FirebaseUsageService", "Veri gönderimi hatası", e)
                }
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceJob?.cancel()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
