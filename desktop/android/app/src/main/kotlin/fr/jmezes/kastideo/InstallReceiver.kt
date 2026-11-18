package fr.jmezes.kastideo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.util.Log

/// Résultat de l'installation d'une mise à jour : affiche la confirmation d'Android quand elle est demandée.
class InstallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                @Suppress("DEPRECATION")
                val confirm = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                confirm?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (confirm != null) context.startActivity(confirm)
            }
            PackageInstaller.STATUS_SUCCESS -> Log.i("Kastideo", "Mise à jour installée")
            else -> Log.w("Kastideo", "Installation échouée ($status) : ${intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)}")
        }
    }

    companion object {
        const val ACTION = "fr.jmezes.kastideo.INSTALL_RESULT"
    }
}
