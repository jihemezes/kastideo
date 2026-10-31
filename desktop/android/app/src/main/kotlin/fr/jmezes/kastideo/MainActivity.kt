package fr.jmezes.kastideo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
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
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("device", e.message, null)
                }
            }
        acquireMulticast()
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
