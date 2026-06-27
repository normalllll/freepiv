package io.github.normalllll.freepiv.download

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import okhttp3.Call
import okhttp3.OkHttpClient
import okhttp3.Request

object DownloadBridge {
    private const val METHOD_CHANNEL = "freepiv/download_engine"
    private const val EVENT_CHANNEL = "freepiv/download_engine/events"
    private const val DOWNLOAD_PERMISSION_REQUEST_CODE = 4109
    private const val PERMISSION_PREFS = "freepiv_download_permissions"

    @Volatile
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    private fun runOnMainThread(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            mainHandler.post { block() }
        }
    }

    fun attach(activity: Activity, messenger: BinaryMessenger) {
        this.activity = activity
        val appContext = activity.applicationContext
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> result.success(null)
                "prepareForDownload" -> prepareForDownload(result)
                "start" -> {
                    val jobs = (call.argument<List<Map<String, Any?>>>("jobs") ?: emptyList()).mapNotNull(::nativeJobFromMap)
                    val missingPermissions = missingRequiredDownloadPermissions(appContext)
                    if (missingPermissions.isNotEmpty()) {
                        result.error("permission_denied", "Download permissions are not granted: ${missingPermissions.joinToString()}", missingPermissions)
                        return@setMethodCallHandler
                    }
                    try {
                        DownloadForegroundService.enqueue(appContext, jobs)
                        result.success(null)
                    } catch (error: Throwable) {
                        result.error("start_failed", error.message ?: error.toString(), null)
                    }
                }
                "cancel" -> {
                    val jobId = call.argument<String>("jobId")
                    if (jobId != null) {
                        DownloadForegroundService.cancel(appContext, jobId)
                    }
                    result.success(null)
                }
                "sync" -> result.success(DownloadForegroundService.snapshots())
                "saveFile" -> {
                    val job = nativeJobFromMap(call.argument<Map<String, Any?>>("job"))
                    val path = call.argument<String>("path")
                    val bytesWritten = call.argument<Number>("bytesWritten")?.toLong() ?: 0L
                    if (job == null || path == null) {
                        result.error("bad_args", "saveFile requires job and path", null)
                        return@setMethodCallHandler
                    }
                    DownloadForegroundService.backgroundExecutor.execute {
                        try {
                            val saved = AndroidMediaSaver.saveFile(appContext, job, File(path), bytesWritten)
                            success(result, saved)
                        } catch (error: Throwable) {
                            error(result, "save_failed", error.message ?: error.toString(), null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )
    }

    fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != DOWNLOAD_PERMISSION_REQUEST_CODE) {
            return false
        }

        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("permission_unavailable", "Download permission result arrived without an active Activity.", null)
            return true
        }

        val missingPermissions = missingRequiredDownloadPermissions(currentActivity)
        if (missingPermissions.isEmpty()) {
            result.success(mapOf("granted" to true))
            return true
        }

        if (missingPermissions.any { isPermanentlyDenied(currentActivity, it) }) {
            openAppSettings(currentActivity)
            result.error(
                "permission_denied_permanent",
                "Download permission was permanently denied. App settings were opened.",
                missingPermissions,
            )
            return true
        }

        result.error("permission_denied", "Download permission was denied: ${missingPermissions.joinToString()}", missingPermissions)
        return true
    }

    private fun prepareForDownload(result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("permission_unavailable", "Download permission requires an active Activity.", null)
            return
        }

        val missingPermissions = missingRequiredDownloadPermissions(currentActivity)
        if (missingPermissions.isEmpty()) {
            result.success(mapOf("granted" to true))
            return
        }

        if (missingPermissions.any { isPermanentlyDenied(currentActivity, it) }) {
            openAppSettings(currentActivity)
            result.error(
                "permission_denied_permanent",
                "Download permission was permanently denied. App settings were opened.",
                missingPermissions,
            )
            return
        }

        if (pendingPermissionResult != null) {
            result.error("permission_unavailable", "Another download permission request is already running.", missingPermissions)
            return
        }

        markPermissionsRequested(currentActivity, missingPermissions)
        pendingPermissionResult = result
        currentActivity.requestPermissions(missingPermissions.toTypedArray(), DOWNLOAD_PERMISSION_REQUEST_CODE)
    }

    private fun missingRequiredDownloadPermissions(context: Context): List<String> {
        return requiredDownloadPermissions().filterNot { hasPermission(context, it) }
    }

    private fun requiredDownloadPermissions(): List<String> {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            permissions += Manifest.permission.WRITE_EXTERNAL_STORAGE
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions += Manifest.permission.POST_NOTIFICATIONS
        }
        return permissions
    }

    private fun hasPermission(context: Context, permission: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        return context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun isPermanentlyDenied(activity: Activity, permission: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }
        return wasPermissionRequested(activity, permission) && !activity.shouldShowRequestPermissionRationale(permission)
    }

    private fun markPermissionsRequested(context: Context, permissions: List<String>) {
        val prefs = context.getSharedPreferences(PERMISSION_PREFS, Context.MODE_PRIVATE)
        prefs.edit().apply {
            for (permission in permissions) {
                putBoolean(permission, true)
            }
        }.apply()
    }

    private fun wasPermissionRequested(context: Context, permission: String): Boolean {
        val prefs = context.getSharedPreferences(PERMISSION_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(permission, false)
    }

    private fun openAppSettings(activity: Activity) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", activity.packageName, null))
        activity.startActivity(intent)
    }

    fun emit(event: Map<String, Any?>) {
        runOnMainThread {
            eventSink?.success(event)
        }
    }

    fun success(result: MethodChannel.Result, value: Any?) {
        runOnMainThread {
            result.success(value)
        }
    }

    fun error(result: MethodChannel.Result, code: String, message: String?, details: Any?) {
        runOnMainThread {
            result.error(code, message, details)
        }
    }
}

class DownloadForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification())

        when (intent?.action) {
            ACTION_CANCEL -> intent.getStringExtra(EXTRA_JOB_ID)?.let(::cancelJob)
            ACTION_CANCEL_ALL -> calls.keys.toList().forEach(::cancelJob)
            else -> drainPendingJobs().forEach(::startJob)
        }

        updateNotification()
        return START_NOT_STICKY
    }

    private fun startJob(job: NativeDownloadJob) {
        val existing = states[job.id]
        if (existing?.status == "running") {
            return
        }

        val state = NativeTaskState(jobId = job.id, status = "running", saveState = "none")
        states[job.id] = state
        backgroundExecutor.execute {
            downloadAndSave(job, state)
        }
    }

    private fun downloadAndSave(job: NativeDownloadJob, state: NativeTaskState) {
        val tempDirectory = File(cacheDir, "downloads").apply { mkdirs() }
        val partialFile = File(tempDirectory, "${job.id}.tmp")
        val client = OkHttpClient.Builder().build()
        val requestBuilder = Request.Builder().url(job.url)
            .header("Referer", job.headers["Referer"] ?: "https://www.pixiv.net/")
            .header("User-Agent", job.headers["User-Agent"] ?: "freepiv")
        for ((key, value) in job.headers) {
            requestBuilder.header(key, value)
        }

        val call = client.newCall(requestBuilder.build())
        calls[job.id] = call
        try {
            val response = call.execute()
            if (!response.isSuccessful) {
                throw IllegalStateException("Download failed with HTTP ${response.code}")
            }

            val body = response.body ?: throw IllegalStateException("Download response has no body")
            state.totalBytes = body.contentLength().takeIf { it > 0 }
            FileOutputStream(partialFile).use { output ->
                body.byteStream().use { input ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var lastEmit = 0L
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) {
                            break
                        }
                        output.write(buffer, 0, read)
                        state.receivedBytes += read.toLong()
                        state.progress = progressOf(state.receivedBytes, state.totalBytes)
                        val now = System.currentTimeMillis()
                        if (now - lastEmit >= 350L || state.progress >= 1.0) {
                            lastEmit = now
                            emitProgress(state)
                            updateNotification()
                        }
                    }
                }
            }

            state.status = "downloaded"
            state.saveState = "saving"
            state.localPath = partialFile.absolutePath
            state.progress = 1.0
            DownloadBridge.emit(
                mapOf(
                    "type" to "completed",
                    "jobId" to job.id,
                    "localPath" to partialFile.absolutePath,
                    "bytesWritten" to state.receivedBytes,
                ),
            )
            updateNotification()

            try {
                val saved = AndroidMediaSaver.saveFile(applicationContext, job, partialFile, state.receivedBytes)
                state.saveState = "saved"
                state.localPath = saved["path"] as? String
                state.galleryAssetId = saved["galleryAssetId"] as? String
                state.error = null
                partialFile.delete()
                DownloadBridge.emit(
                    mapOf(
                        "type" to "saved",
                        "jobId" to job.id,
                        "path" to state.localPath,
                        "galleryAssetId" to state.galleryAssetId,
                    ),
                )
            } catch (error: Throwable) {
                state.saveState = "failed"
                state.error = error.message ?: error.toString()
                DownloadBridge.emit(mapOf("type" to "saveFailed", "jobId" to job.id, "localPath" to partialFile.absolutePath, "error" to state.error))
            }
        } catch (error: Throwable) {
            if (call.isCanceled()) {
                state.status = "cancelled"
                state.error = null
                partialFile.delete()
                DownloadBridge.emit(mapOf("type" to "cancelled", "jobId" to job.id))
            } else {
                state.status = "failed"
                state.error = error.message ?: error.toString()
                partialFile.delete()
                DownloadBridge.emit(mapOf("type" to "failed", "jobId" to job.id, "error" to state.error))
            }
        } finally {
            calls.remove(job.id)
            updateNotification()
            stopIfIdle()
        }
    }

    private fun cancelJob(jobId: String) {
        calls[jobId]?.cancel()
        val state = states[jobId]
        if (state != null) {
            state.status = "cancelled"
            state.error = null
            DownloadBridge.emit(mapOf("type" to "cancelled", "jobId" to jobId))
        }
        updateNotification()
        stopIfIdle()
    }

    private fun emitProgress(state: NativeTaskState) {
        DownloadBridge.emit(
            mapOf(
                "type" to "progress",
                "jobId" to state.jobId,
                "receivedBytes" to state.receivedBytes,
                "totalBytes" to state.totalBytes,
                "progress" to state.progress,
            ),
        )
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(CHANNEL_ID, "Downloads", NotificationManager.IMPORTANCE_LOW)
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val running = states.values.count { it.status == "running" }
        val completed = states.values.count { it.saveState == "saved" }
        val failed = states.values.count { it.status == "failed" || it.saveState == "failed" }
        val total = states.size.coerceAtLeast(1)
        val overall = (states.values.sumOf { it.progress } / total).coerceIn(0.0, 1.0)
        val content = "Running $running / Saved $completed / Failed $failed"
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val cancelIntent = PendingIntent.getService(
            this,
            0,
            Intent(this, DownloadForegroundService::class.java).setAction(ACTION_CANCEL_ALL),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        return builder
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle("Downloading images")
            .setContentText(content)
            .setOngoing(running > 0)
            .setOnlyAlertOnce(true)
            .setProgress(100, (overall * 100).toInt(), running > 0 && states.values.any { it.totalBytes == null })
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", cancelIntent)
            .build()
    }

    private fun updateNotification() {
        if (!hasActiveWork()) {
            clearNotification()
            return
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun stopIfIdle() {
        if (hasActiveWork()) {
            return
        }
        clearNotification()
        stopSelf()
    }

    private fun hasActiveWork(): Boolean {
        return calls.isNotEmpty() || states.values.any { it.status == "running" || it.saveState == "saving" }
    }

    private fun clearNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.cancel(NOTIFICATION_ID)
    }

    companion object {
        const val ACTION_CANCEL = "io.github.normalllll.freepiv.download.CANCEL"
        const val ACTION_CANCEL_ALL = "io.github.normalllll.freepiv.download.CANCEL_ALL"
        const val EXTRA_JOB_ID = "jobId"
        private const val CHANNEL_ID = "freepiv_downloads"
        private const val NOTIFICATION_ID = 4108

        val backgroundExecutor = Executors.newFixedThreadPool(3)
        private val pendingJobs = mutableListOf<NativeDownloadJob>()
        private val calls = ConcurrentHashMap<String, Call>()
        private val states = ConcurrentHashMap<String, NativeTaskState>()

        fun enqueue(context: Context, jobs: List<NativeDownloadJob>) {
            synchronized(pendingJobs) {
                pendingJobs.addAll(jobs)
            }
            val intent = Intent(context, DownloadForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun cancel(context: Context, jobId: String) {
            calls[jobId]?.cancel()
            val intent = Intent(context, DownloadForegroundService::class.java).setAction(ACTION_CANCEL).putExtra(EXTRA_JOB_ID, jobId)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun snapshots(): List<Map<String, Any?>> {
            return states.values.map { it.toMap() }
        }

        private fun drainPendingJobs(): List<NativeDownloadJob> {
            synchronized(pendingJobs) {
                val jobs = pendingJobs.toList()
                pendingJobs.clear()
                return jobs
            }
        }
    }
}

object AndroidMediaSaver {
    fun saveFile(context: Context, job: NativeDownloadJob, source: File, bytesWritten: Long): Map<String, Any?> {
        ensureCanSave(context)
        if (!source.exists()) {
            throw IllegalStateException("Downloaded file does not exist: ${source.absolutePath}")
        }
        if (source.length() <= 0L) {
            throw IllegalStateException("Downloaded file is empty: ${source.absolutePath}")
        }

        val resolver = context.contentResolver
        val displayName = safeFilename(job.filename)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeTypeFor(job.filename))
            put(MediaStore.MediaColumns.SIZE, source.length())
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/freepiv")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            } else {
                @Suppress("DEPRECATION")
                val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "freepiv")
                if (!directory.exists() && !directory.mkdirs()) {
                    throw IllegalStateException("Could not create download directory: ${directory.absolutePath}")
                }
                @Suppress("DEPRECATION")
                put(MediaStore.Images.Media.DATA, uniqueDestination(directory, displayName).absolutePath)
            }
        }

        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: throw IllegalStateException("Could not create MediaStore item")
        try {
            resolver.openOutputStream(uri)?.use { output ->
                FileInputStream(source).use { input -> input.copyTo(output) }
            } ?: throw IllegalStateException("Could not open MediaStore output stream")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
            return mapOf("path" to uri.toString(), "galleryAssetId" to uri.toString(), "bytesWritten" to bytesWritten)
        } catch (error: Throwable) {
            resolver.delete(uri, null, null)
            throw error
        }
    }

    private fun ensureCanSave(context: Context) {
        if (Environment.getExternalStorageState() != Environment.MEDIA_MOUNTED) {
            throw IllegalStateException("External storage is not writable.")
        }
        if (Build.VERSION.SDK_INT in Build.VERSION_CODES.M..Build.VERSION_CODES.P &&
            context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
        ) {
            throw SecurityException("WRITE_EXTERNAL_STORAGE permission is not granted.")
        }
    }

    private fun mimeTypeFor(filename: String): String {
        return when (filename.substringAfterLast('.', "").lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            else -> "image/jpeg"
        }
    }

    private fun uniqueDestination(directory: File, filename: String): File {
        val dotIndex = filename.lastIndexOf('.')
        val baseName = if (dotIndex > 0) filename.substring(0, dotIndex) else filename
        val extension = if (dotIndex > 0 && dotIndex < filename.length - 1) filename.substring(dotIndex) else ""
        var candidate = File(directory, filename)
        var index = 1
        while (candidate.exists()) {
            candidate = File(directory, "$baseName ($index)$extension")
            index += 1
        }
        return candidate
    }
}

data class NativeDownloadJob(
    val id: String,
    val illustId: Int,
    val url: String,
    val filename: String,
    val headers: Map<String, String>,
)

data class NativeTaskState(
    val jobId: String,
    var status: String,
    var saveState: String,
    var receivedBytes: Long = 0L,
    var totalBytes: Long? = null,
    var progress: Double = 0.0,
    var localPath: String? = null,
    var galleryAssetId: String? = null,
    var error: String? = null,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "jobId" to jobId,
            "status" to status,
            "saveState" to saveState,
            "receivedBytes" to receivedBytes,
            "totalBytes" to totalBytes,
            "progress" to progress,
            "localPath" to localPath,
            "galleryAssetId" to galleryAssetId,
            "error" to error,
        )
    }
}

private fun nativeJobFromMap(map: Map<String, Any?>?): NativeDownloadJob? {
    if (map == null) {
        return null
    }
    val id = map["id"] as? String ?: return null
    val url = map["url"] as? String ?: return null
    val filename = map["filename"] as? String ?: "download"
    val headers = (map["headers"] as? Map<*, *>)?.mapNotNull { (key, value) ->
        if (key == null || value == null) null else key.toString() to value.toString()
    }?.toMap() ?: emptyMap()

    return NativeDownloadJob(
        id = id,
        illustId = (map["illustId"] as? Number)?.toInt() ?: 0,
        url = url,
        filename = filename,
        headers = headers,
    )
}

private fun progressOf(receivedBytes: Long, totalBytes: Long?): Double {
    if (totalBytes == null || totalBytes <= 0L) {
        return 0.0
    }
    return (receivedBytes.toDouble() / totalBytes.toDouble()).coerceIn(0.0, 1.0)
}

private fun safeFilename(filename: String): String {
    val sanitized = filename.replace(Regex("""[\\/\u0000]"""), "_").trim()
    return sanitized.ifEmpty { "download" }
}
