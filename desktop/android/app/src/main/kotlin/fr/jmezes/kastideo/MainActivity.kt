package fr.jmezes.kastideo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.Bitmap
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Size
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Pont entre Flutter et Android : détection du téléviseur, dossiers, luminosité, notifications,
/// installation des mises à jour (APK) et verrou multicast pour la recherche des appareils Cast.
class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private var pendingGallery: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fr.jmezes.kastideo/device")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "isTv" -> result.success(isTelevision())
                        "abi" -> result.success(Build.SUPPORTED_ABIS.firstOrNull() ?: "")
                        "mediaFolder" -> {
                            val dir = getExternalFilesDir(Environment.DIRECTORY_MOVIES) ?: filesDir
                            dir.mkdirs()
                            result.success(dir.absolutePath)
                        }
                        "nativeLibraryDir" -> result.success(applicationInfo.nativeLibraryDir)
                        "brightness" -> {
                            val value = window.attributes.screenBrightness
                            result.success(if (value < 0) 0.5 else value.toDouble())
                        }
                        "setBrightness" -> {
                            val level = (call.argument<Double>("level") ?: -1.0).toFloat()
                            val params = window.attributes
                            params.screenBrightness = if (level < 0) -1f else level.coerceIn(0.02f, 1f)
                            window.attributes = params
                            result.success(null)
                        }
                        "canInstall" -> result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()
                        )
                        "openInstallSettings" -> {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(null)
                        }
                        "installApk" -> {
                            val path = call.argument<String>("path") ?: ""
                            result.success(installApk(path))
                        }
                        "openUrl" -> {
                            val url = call.argument<String>("url") ?: ""
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            result.success(true)
                        }
                        "notify" -> {
                            notify(call.argument<String>("title") ?: "", call.argument<String>("body") ?: "")
                            result.success(null)
                        }
                        "requestNotifications" -> {
                            if (Build.VERSION.SDK_INT >= 33 &&
                                checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                            ) {
                                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1001)
                            }
                            result.success(null)
                        }
                        "galleryStatus" -> result.success(galleryStatus())
                        "galleryRequest" -> requestGallery(result)
                        "galleryAlbums" -> inBackground(result) { galleryAlbums() }
                        "galleryVideos" -> {
                            val albums = call.argument<List<String>>("albums") ?: emptyList()
                            inBackground(result) { galleryVideos(albums) }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("device", e.message, null)
                }
            }
        acquireMulticast()
    }

    // MARK: Galerie (vidéos du téléphone, lues avec MediaStore)

    private fun galleryPermissions(): Array<String> = when {
        Build.VERSION.SDK_INT >= 34 -> arrayOf(
            android.Manifest.permission.READ_MEDIA_VIDEO,
            "android.permission.READ_MEDIA_VISUAL_USER_SELECTED"
        )
        Build.VERSION.SDK_INT >= 33 -> arrayOf(android.Manifest.permission.READ_MEDIA_VIDEO)
        else -> arrayOf(android.Manifest.permission.READ_EXTERNAL_STORAGE)
    }

    private fun granted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    /// granted : toutes les vidéos ; limited : seulement celles choisies (Android 14) ; denied : aucune.
    private fun galleryStatus(): String {
        if (Build.VERSION.SDK_INT >= 34) {
            if (granted(android.Manifest.permission.READ_MEDIA_VIDEO)) return "granted"
            if (granted("android.permission.READ_MEDIA_VISUAL_USER_SELECTED")) return "limited"
            return "denied"
        }
        return if (granted(galleryPermissions()[0])) "granted" else "denied"
    }

    private fun requestGallery(result: MethodChannel.Result) {
        pendingGallery?.success(galleryStatus())
        pendingGallery = result
        requestPermissions(galleryPermissions(), 1002)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1002) {
            pendingGallery?.success(galleryStatus())
            pendingGallery = null
        }
    }

    private fun inBackground(result: MethodChannel.Result, work: () -> Any?) {
        Thread {
            try {
                val value = work()
                runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                runOnUiThread { result.error("gallery", e.message, null) }
            }
        }.start()
    }

    private fun videoCollection(): Uri =
        if (Build.VERSION.SDK_INT >= 29) MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        else MediaStore.Video.Media.EXTERNAL_CONTENT_URI

    private fun galleryAlbums(): List<Map<String, Any>> {
        if (galleryStatus() == "denied") return emptyList()
        val counts = LinkedHashMap<String, Pair<String, Int>>()
        val projection = arrayOf(MediaStore.Video.Media.BUCKET_ID, MediaStore.Video.Media.BUCKET_DISPLAY_NAME)
        contentResolver.query(videoCollection(), projection, null, null, null)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_ID)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_DISPLAY_NAME)
            while (cursor.moveToNext()) {
                val id = cursor.getString(idCol) ?: continue
                val name = cursor.getString(nameCol) ?: "?"
                val old = counts[id]
                counts[id] = Pair(name, (old?.second ?: 0) + 1)
            }
        }
        return counts.map { mapOf("id" to it.key, "name" to it.value.first, "count" to it.value.second) }
            .sortedBy { (it["name"] as String).lowercase() }
    }

    private fun galleryVideos(albums: List<String>): List<Map<String, Any?>> {
        if (galleryStatus() == "denied") return emptyList()
        val thumbs = File(cacheDir, "galerie").apply { mkdirs() }
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Video.Media.DATE_TAKEN,
            MediaStore.Video.Media.DATE_ADDED,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.DATA
        )
        var selection: String? = null
        var args: Array<String>? = null
        if (albums.isNotEmpty()) {
            selection = MediaStore.Video.Media.BUCKET_ID + " IN (" + albums.joinToString(",") { "?" } + ")"
            args = albums.toTypedArray()
        }
        val list = ArrayList<Map<String, Any?>>()
        contentResolver.query(videoCollection(), projection, selection, args, MediaStore.Video.Media.DATE_ADDED + " DESC")?.use { c ->
            val idCol = c.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
            val nameCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
            val bucketCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_DISPLAY_NAME)
            val takenCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_TAKEN)
            val addedCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
            val durCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val dataCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            while (c.moveToNext()) {
                val id = c.getLong(idCol)
                val uri = Uri.withAppendedPath(videoCollection(), id.toString())
                val taken = c.getLong(takenCol)
                val date = if (taken > 0) taken else c.getLong(addedCol) * 1000
                list.add(
                    mapOf(
                        "id" to id.toString(),
                        "name" to (c.getString(nameCol) ?: ""),
                        "bucket" to (c.getString(bucketCol) ?: ""),
                        "date" to date,
                        "duration" to c.getLong(durCol),
                        "path" to (c.getString(dataCol) ?: ""),
                        "uri" to uri.toString(),
                        "thumb" to thumbnail(uri, id, thumbs)
                    )
                )
            }
        }
        list.sortByDescending { (it["date"] as Long) }
        return list
    }

    /// Miniature JPEG gardée dans le cache de l'application (vide si Android n'en fournit pas).
    private fun thumbnail(uri: Uri, id: Long, folder: File): String {
        val file = File(folder, "$id.jpg")
        if (file.exists() && file.length() > 0) return file.absolutePath
        return try {
            val bitmap: Bitmap? = if (Build.VERSION.SDK_INT >= 29) {
                contentResolver.loadThumbnail(uri, Size(480, 480), null)
            } else {
                @Suppress("DEPRECATION")
                MediaStore.Video.Thumbnails.getThumbnail(contentResolver, id, MediaStore.Video.Thumbnails.MINI_KIND, null)
            }
            if (bitmap == null) "" else {
                file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 80, it) }
                file.absolutePath
            }
        } catch (_: Exception) {
            ""
        }
    }

    private fun isTelevision(): Boolean {
        val ui = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        if (ui.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) return true
        val pm = packageManager
        return pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
            pm.hasSystemFeature("android.hardware.type.television") ||
            (!pm.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN) && pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK_ONLY))
    }

    /// Ouvre l'installateur d'Android pour l'APK téléchargé (l'utilisateur confirme).
    private fun installApk(path: String): Boolean {
        val file = File(path)
        if (!file.exists()) return false
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    private fun notify(title: String, body: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel("kastideo", "Kastideo", NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
        val open = PendingIntentHelper.open(this)
        val notification = NotificationCompat.Builder(this, "kastideo")
            .setSmallIcon(R.drawable.ic_stat)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()
        manager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
    }

    /// Android filtre les paquets multicast tant qu'un verrou n'est pas tenu : nécessaire pour trouver les Chromecast.
    private fun acquireMulticast() {
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            multicastLock = wifi.createMulticastLock("kastideo-mdns").apply {
                setReferenceCounted(false)
                acquire()
            }
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        try {
            multicastLock?.release()
        } catch (_: Exception) {
        }
        super.onDestroy()
    }
}

object PendingIntentHelper {
    fun open(context: Context): android.app.PendingIntent {
        val intent = Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return android.app.PendingIntent.getActivity(
            context, 0, intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
    }
}
