package com.example.edadeneme

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.*
import android.util.DisplayMetrics
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.ktx.Firebase
import com.google.firebase.storage.ktx.storage
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.firestore.FieldValue
import org.tensorflow.lite.Interpreter
import java.io.*
import java.text.SimpleDateFormat
import java.util.*
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import android.view.WindowManager

class ScreenCaptureService : Service() {

    private lateinit var mediaProjectionManager: MediaProjectionManager
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private lateinit var tflite: Interpreter
    private val timer = Timer()

    private val SCREENSHOT_INTERVAL_MS = 20000L // 20 saniye

    private var parentId: String = ""
    private var childId: String = ""

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startForegroundService()
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        tflite = Interpreter(loadModelFile())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val resultCode = intent?.getIntExtra("resultCode", Activity.RESULT_CANCELED) ?: return START_NOT_STICKY
        val data = intent.getParcelableExtra<Intent>("data") ?: return START_NOT_STICKY

        parentId = intent.getStringExtra("parentId") ?: return START_NOT_STICKY
        childId = intent.getStringExtra("childId") ?: return START_NOT_STICKY

        mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)

        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                stopSelf()
            }
        }, null)

        startScreenCapture()
        return START_STICKY
    }

    private fun startScreenCapture() {
        val metrics = DisplayMetrics()
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        wm.defaultDisplay.getRealMetrics(metrics)

        val screenDensity = metrics.densityDpi
        val screenWidth = metrics.widthPixels
        val screenHeight = metrics.heightPixels

        imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)

        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            screenWidth,
            screenHeight,
            screenDensity,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            null
        )

        timer.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                takeScreenshot()
            }
        }, 0, SCREENSHOT_INTERVAL_MS)
    }

    private fun takeScreenshot() {
        val image = imageReader?.acquireLatestImage() ?: return
        val planes = image.planes
        val buffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * image.width

        val bitmap = Bitmap.createBitmap(
            image.width + rowPadding / pixelStride,
            image.height,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
        image.close()

        val (isSafe, predictedPair) = isSafeContent(bitmap)
        if (isSafe) return

        val predictedClass = predictedPair.first
        val confidence = predictedPair.second

        val timestamp = System.currentTimeMillis()
        val fileName = "screenshot_$timestamp.png"

        uploadToFirebase(bitmap, fileName, timestamp, predictedClass, confidence)
    }

    private fun uploadToFirebase(bitmap: Bitmap, fileName: String, timestamp: Long, predictedClass: String, confidence: Float) {
        val firestore = Firebase.firestore
        val storageRef = Firebase.storage.reference
            .child("imageAnalysis/$parentId/$childId/$fileName")

        val baos = ByteArrayOutputStream()
        val resized = Bitmap.createScaledBitmap(bitmap, 540, 960, true)
    resized.compress(Bitmap.CompressFormat.JPEG, 50, baos)
        val data = baos.toByteArray()

        storageRef.putBytes(data)
            .addOnSuccessListener {
                storageRef.downloadUrl.addOnSuccessListener { uri ->
                    val entry = mapOf(
                        "image" to uri.toString(),
                        "result" to predictedClass,
                        "confidence" to confidence,
                        "timestamp" to FieldValue.serverTimestamp()
                    )
                    firestore.collection("parents")
                        .document(parentId)
                        .collection("children")
                        .document(childId)
                        .collection("imageAnalysis")
                        .add(entry)
                    Log.d("NSFW", "Firestore'a kaydedildi: $predictedClass ($confidence)")
                }
            }
            .addOnFailureListener {
                Log.e("Firebase", "Yükleme hatası", it)
            }
    }

    private fun loadModelFile(): MappedByteBuffer {
        val fileDescriptor = assets.openFd("saved_model.tflite")
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, fileDescriptor.startOffset, fileDescriptor.declaredLength)
    }

    private fun isSafeContent(bitmap: Bitmap): Pair<Boolean, Pair<String, Float>> {
        val resizedBitmap = Bitmap.createScaledBitmap(bitmap, 224, 224, true)
        val input = Array(1) { Array(224) { Array(224) { FloatArray(3) } } }
        for (y in 0 until 224) {
            for (x in 0 until 224) {
                val pixel = resizedBitmap.getPixel(x, y)
                input[0][y][x][0] = (pixel shr 16 and 0xFF) / 255.0f
                input[0][y][x][1] = (pixel shr 8 and 0xFF) / 255.0f
                input[0][y][x][2] = (pixel and 0xFF) / 255.0f
            }
        }

        val output = Array(1) { FloatArray(5) }
        tflite.run(input, output)

        val classes = listOf("drawings", "hentai", "neutral", "porn", "sexy")
        val maxScore = output[0].maxOrNull() ?: 0f
        val predictedIndex = output[0].indexOfFirst { it == maxScore }
        val predicted = classes[predictedIndex]

        Log.d("NSFW", "Predicted: $predicted - Score: $maxScore")

        val isSafe = predicted == "neutral" || predicted == "drawings" || maxScore < 0.6f
        return Pair(isSafe, Pair(predicted, maxScore))
    }

private fun startForegroundService() {
    val channelId = "ScreenCaptureChannel"
    val channelName = "Ekran Kaydı Servisi"

    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_MIN // Mümkün olan en düşük görünürlük
        ).apply {
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_SECRET
        }
        manager.createNotificationChannel(channel)
    }

    val notification = NotificationCompat.Builder(this, channelId)
        .setSmallIcon(android.R.drawable.stat_notify_more) // ✅ Sadece simge (dilersen değiştir)
        .setPriority(NotificationCompat.PRIORITY_MIN) // Sessiz
        .setOngoing(true)
        .build()

    startForeground(1, notification)
}


    override fun onDestroy() {
        super.onDestroy()
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        timer.cancel()
    }
}
