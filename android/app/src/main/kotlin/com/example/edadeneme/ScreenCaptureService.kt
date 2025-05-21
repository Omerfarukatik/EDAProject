package com.example.edadeneme
import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.MediaScannerConnection
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Environment
import android.util.DisplayMetrics
import android.util.Log
import androidx.core.app.NotificationCompat
import org.tensorflow.lite.Interpreter
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.*
import android.graphics.PixelFormat
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import java.io.FileInputStream
import android.hardware.display.DisplayManager
import android.view.WindowManager
import android.os.IBinder

class ScreenCaptureService : Service() {

    private lateinit var mediaProjectionManager: MediaProjectionManager
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private lateinit var tflite: Interpreter

    private val SCREENSHOT_INTERVAL_MS = 5000L // 5 saniyede bir
    private val timer = Timer()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startForegroundService()
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        tflite = Interpreter(loadModelFile()) // Model dosyasını yükle
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val resultCode = intent?.getIntExtra("resultCode", Activity.RESULT_CANCELED) ?: return START_NOT_STICKY
        val data = intent.getParcelableExtra<Intent>("data") ?: return START_NOT_STICKY

        mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)

        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                super.onStop()
                Log.d("ScreenCaptureService", "MediaProjection stopped.")
                stopSelf()
            }
        }, null)

        startScreenCapture()
        return START_NOT_STICKY
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

        // Ekran görüntüsünü periyodik al
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

        // NSFW ANALİZİ YAP
        if (isSafeContent(bitmap)) {
            Log.d("Screenshot", "SAFE içerik. Kayıt yapılmadı.")
            return // SAFE içerikse kaydetmeden çık
        }

        val now = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val fileName = "screenshot_$now.png"

        val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
        val file = File(picturesDir, fileName)

        try {
            val outputStream: OutputStream = FileOutputStream(file)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            outputStream.flush()
            outputStream.close()

            // Galeriye bildir
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(file.absolutePath),
                arrayOf("image/png"),
                null
            )

            Log.d("Screenshot", "NSFW içerik kaydedildi: ${file.absolutePath}")
        } catch (e: Exception) {
            Log.e("Screenshot", "Kaydedilemedi: ${e.message}")
        }
    }

    private fun loadModelFile(): MappedByteBuffer {
        val fileDescriptor = assets.openFd("saved_model.tflite")
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }

    private fun isSafeContent(bitmap: Bitmap): Boolean {
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
        val scores = output[0]

        val classes = listOf("drawings", "hentai", "neutral", "porn", "sexy")
        val maxScore = scores.maxOrNull() ?: 0f
        val maxIndex = scores.indexOfFirst { it == maxScore }
        val detectedClass = classes[maxIndex]

        Log.d("NSFWAnalysis", "Tahmin edilen sınıf: $detectedClass, Skor: $maxScore")

        return detectedClass == "neutral" || detectedClass == "drawings"
    }

    private fun startForegroundService() {
        val channelId = "ScreenCaptureChannel"
        val channelName = "Ekran Kaydı Servisi"

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Ekran görüntüsü alınıyor"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Ekran kaydı aktif")
            .setContentText("🟢 Ekran görüntüsü alınıyor...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
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
        Log.d("ScreenCaptureService", "MediaProjection durdu.")
    }
}
