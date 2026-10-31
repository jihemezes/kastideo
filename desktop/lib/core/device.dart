import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Appareil sur lequel tourne Kastideo : ordinateur, téléphone/tablette Android ou téléviseur Android TV.
class Device {
  Device._();

  static const _channel = MethodChannel('fr.jmezes.kastideo/device');

  static bool get isAndroid => Platform.isAndroid;
  static bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// Téléviseur ou boîtier Android TV (commandé à la télécommande). Peut être forcé avec KASTIDEO_TV=1 pour les essais.
  static bool isTv = Platform.environment['KASTIDEO_TV'] == '1';

  /// Écran tactile (téléphone, tablette). Faux sur ordinateur et sur téléviseur.
  static bool get isTouch => isAndroid && !isTv;

  /// Largeur (en points) en dessous de laquelle la mise en page passe en « compacte » (téléphone).
  static const compactWidth = 720.0;

  /// Architecture du processeur (arm64-v8a, armeabi-v7a, x86_64) : choisit le bon APK pour les mises à jour.
  static String abiName = '';

  /// Dossier Films de l'application sur Android (enregistrements et téléchargements par défaut).
  static String? mediaDir;

  /// Dossier des bibliothèques natives de l'application.
  static String? nativeDir;

  static Future<void> init() async {
    if (!isAndroid) return;
    try {
      isTv = (await _channel.invokeMethod<bool>('isTv')) ?? false;
      abiName = (await _channel.invokeMethod<String>('abi')) ?? '';
      mediaDir = await mediaFolder();
      nativeDir = await nativeLibraryDir();
    } catch (e) {
      debugPrint('Device.init : $e');
    }
  }

  /// Dossier de l'application visible dans l'explorateur de fichiers Android (enregistrements, téléchargements).
  static Future<String?> mediaFolder() async {
    if (!isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('mediaFolder');
    } catch (_) {
      return null;
    }
  }

  /// Dossier des bibliothèques natives (où se trouve ffmpeg, s'il est livré avec l'application).
  static Future<String?> nativeLibraryDir() async {
    if (!isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('nativeLibraryDir');
    } catch (_) {
      return null;
    }
  }

  /// Luminosité de la fenêtre (0 à 1) ; null : celle du système.
  static Future<void> setBrightness(double? level) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('setBrightness', {'level': level ?? -1.0});
    } catch (_) {}
  }

  static Future<double> brightness() async {
    if (!isAndroid) return 0.5;
    try {
      return (await _channel.invokeMethod<double>('brightness')) ?? 0.5;
    } catch (_) {
      return 0.5;
    }
  }

  /// Vrai si Android autorise Kastideo à installer des applications (mises à jour).
  static Future<bool> canInstallPackages() async {
    if (!isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('canInstall')) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Ouvre le réglage Android « Installer des applications inconnues » pour Kastideo.
  static Future<void> openInstallSettings() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('openInstallSettings');
    } catch (_) {}
  }

  /// Lance l'installation d'un APK déjà téléchargé.
  static Future<bool> installApk(String path) async {
    if (!isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('installApk', {'path': path})) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Notification du système (alertes de programmes, fin d'enregistrement).
  static Future<void> notify(String title, String body) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('notify', {'title': title, 'body': body});
    } catch (_) {}
  }

  /// Demande l'autorisation d'afficher des notifications (Android 13 et plus).
  static Future<void> requestNotifications() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('requestNotifications');
    } catch (_) {}
  }

  /// Ouvre une adresse dans une autre application (navigateur, YouTube).
  static Future<bool> openUrl(String url) async {
    if (!isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('openUrl', {'url': url})) ?? false;
    } catch (_) {
      return false;
    }
  }
}
