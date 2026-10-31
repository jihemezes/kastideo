# Kastideo pour Android et Android TV

Un seul APK fonctionne sur téléphone, tablette et Android TV. Il est construit par GitHub Actions
(workflow `.github/workflows/android.yml`) à chaque tag `vX.Y.Z-androidN`, puis publié en pré-version.

## 1. Créer la clé de signature (une seule fois)

Android refuse d'installer une application non signée, et refuse une mise à jour signée par une autre clé.
Une clé personnelle suffit : **aucun compte payant, aucune inscription**.

Sur le Mac, depuis `~/Documents/kastideo` :

```
bash scripts/android-keygen.sh
```

Le script (Java requis : `brew install --cask temurin@17`) :

1. crée `~/kastideo-android-key/kastideo-release.jks` avec des mots de passe aléatoires ;
2. enregistre les 4 secrets dans GitHub si la commande `gh` est installée et connectée ;
3. sinon, affiche où saisir les 4 secrets à la main (GitHub > Settings > Secrets and variables > Actions) :
   `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

**Sauvegardez le dossier `~/kastideo-android-key/`** (gestionnaire de mots de passe, disque externe) :
sans cette clé, personne ne pourra plus mettre Kastideo à jour sans le désinstaller d'abord.
Elle ne doit jamais être ajoutée à Git (`*.jks` est ignoré).

## 2. Publier une version

```
git tag v1.9.0-android1
git push origin v1.9.0-android1
```

Fichiers publiés : `Kastideo-<version>-android-arm64-v8a.apk` (presque tous les appareils récents),
`-armeabi-v7a.apk` (anciens appareils 32 bits), `-x86_64.apk` et `-universal.apk`.

## 3. Installer un APK sans désactiver la sécurité d'Android

Android n'impose pas de couper ses protections : il demande l'autorisation **« Installer des applications
inconnues » pour l'application qui ouvre l'APK** (navigateur, gestionnaire de fichiers, Downloader), et
uniquement pour elle. Play Protect peut afficher « développeur inconnu » : **Plus de détails > Installer quand même**.

Sur Android TV : application gratuite **Downloader** (saisir l'adresse de l'APK), ou clé USB, ou `adb install`.
Détails pas à pas : page d'aide « Kastideo sur Android et Android TV ».

## 4. Mises à jour

Kastideo interroge GitHub (pré-versions `-android`) et propose la nouvelle version. « Installer » télécharge
l'APK de la bonne architecture, puis Android demande de confirmer.

## 5. Limites de cette première version

- Cast : mode direct uniquement (pas de conversion ffmpeg sur Android).
- Enregistrements : l'application doit rester ouverte (pas de service en arrière-plan).
- Non publiée sur Google Play (une inscription développeur unique à 25 $ permettrait de le faire plus tard).


## Page de téléchargement et QR code

Scannez ce code avec le téléphone : il ouvre la page des dernières versions (`.../releases/latest`) où se trouve l'APK.

![QR code](android-qr.png)

Sur Android TV : installez **Downloader**, ouvrez-le et saisissez `github.com/jihemezes/kastideo/releases/latest`.
