import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../version.dart';
import 'log.dart';

/// Façon dont Kastideo est installé : elle décide de la mise à jour proposée.
enum InstallKind {
  /// Windows, installé avec Kastideo-…-setup.exe : nouvel installateur lancé en silencieux.
  windowsSetup,

  /// Windows, dossier portable (zip) : fichiers remplacés après la fermeture.
  windowsPortable,

  /// Linux, AppImage : nouveau fichier téléchargé à côté de l'ancien.
  appImage,

  /// Linux, paquet .deb (/opt/kastideo) : installé par apt (mot de passe demandé).
  deb,

  /// Autre (construction locale) : lien vers la page de la version.
  other,
}

/// Version publiée sur GitHub.
class ReleaseInfo {
  ReleaseInfo({required this.tag, required this.version, required this.notes, required this.url, required this.assets});
  final String tag;
  final String version;
  final String notes;
  final String url;

  /// Nom du fichier → adresse de téléchargement.
  final Map<String, String> assets;
}

enum UpdateState { idle, checking, upToDate, available, downloading, installing, failed }

/// « 1.2.0-desktop7 » → [1, 2, 0, 7] (comparaison des versions des aperçus Windows / Linux).
List<int> versionParts(String v) {
  final m = RegExp(r'(\d+)\.(\d+)\.(\d+)(?:-desktop(\d+))?').firstMatch(v);
  if (m == null) return const [0, 0, 0, 0];
  return [for (var i = 1; i <= 4; i++) int.tryParse(m.group(i) ?? '') ?? 0];
}

int compareVersions(String a, String b) {
  final x = versionParts(a), y = versionParts(b);
  for (var i = 0; i < 4; i++) {
    if (x[i] != y[i]) return x[i].compareTo(y[i]);
  }
  return 0;
}

/// Mises à jour intégrées (comme Sparkle sur Mac) : pré-versions « -desktopN » publiées sur GitHub.
class UpdateService extends ChangeNotifier {
  UpdateService();

  static const repo = 'jihemezes/kastideo';
  static const releasesPage = 'https://github.com/$repo/releases';

  SharedPreferences? _prefs;
  UpdateState state = UpdateState.idle;
  ReleaseInfo? latest;
  String? error;
  double? progress;
  DateTime? lastCheck;
  Timer? _timer;

  /// L'utilisateur a vu la proposition (bandeau refermé) pendant cette séance.
  bool dismissed = false;

  String get current => kVersion;
  bool get isDevBuild => !current.contains('.');

  bool get autoCheck => _prefs?.getBool('updates.auto') ?? true;
  String? get skipped => _prefs?.getString('updates.skip');

  Future<void> start() async {
    _prefs = await SharedPreferences.getInstance();
    // Première recherche peu après le lancement, puis toutes les 12 heures.
    _timer = Timer(const Duration(seconds: 20), () {
      if (autoCheck) check();
      _timer = Timer.periodic(const Duration(hours: 12), (_) {
        if (autoCheck) check();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void setAutoCheck(bool value) {
    _prefs?.setBool('updates.auto', value);
    notifyListeners();
  }

  void dismiss() {
    dismissed = true;
    notifyListeners();
  }

  void skip(ReleaseInfo release) {
    _prefs?.setString('updates.skip', release.version);
    dismissed = true;
    notifyListeners();
  }

  /// Une version plus récente que celle-ci, non ignorée (sauf recherche manuelle).
  bool get hasUpdate => state == UpdateState.available && latest != null;
  bool get shouldPropose => hasUpdate && !dismissed && skipped != latest!.version;

  // MARK: Recherche

  Future<void> check({bool manual = false}) async {
    if (state == UpdateState.checking || state == UpdateState.downloading || state == UpdateState.installing) return;
    if (isDevBuild) {
      state = UpdateState.upToDate;
      error = null;
      notifyListeners();
      return;
    }
    state = UpdateState.checking;
    error = null;
    if (manual) dismissed = false;
    notifyListeners();
    try {
      final release = await _fetchLatest();
      lastCheck = DateTime.now();
      if (release != null && compareVersions(release.version, current) > 0) {
        latest = release;
        state = UpdateState.available;
        if (manual && skipped == release.version) _prefs?.remove('updates.skip');
        PlaybackLog.shared.note('Mise à jour disponible : ${release.version} (installée : $current)');
      } else {
        latest = release;
        state = UpdateState.upToDate;
      }
    } catch (e) {
      error = '$e';
      state = UpdateState.failed;
      PlaybackLog.shared.note('Recherche de mise à jour impossible : $e');
    }
    notifyListeners();
  }

  Future<ReleaseInfo?> _fetchLatest() async {
    final client = HttpClient()..userAgent = 'Kastideo/$current';
    try {
      // KASTIDEO_UPDATE_URL : autre adresse pour les essais (serveur local).
      final url = Platform.environment['KASTIDEO_UPDATE_URL'] ?? 'https://api.github.com/repos/$repo/releases?per_page=30';
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close().timeout(const Duration(seconds: 20));
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) throw HttpException('GitHub : code HTTP ${response.statusCode}');
      final list = jsonDecode(body) as List;
      ReleaseInfo? best;
      for (final r in list.whereType<Map>()) {
        final tag = r['tag_name'] as String? ?? '';
        if (r['draft'] == true || !tag.contains('-desktop')) continue;
        final version = tag.startsWith('v') ? tag.substring(1) : tag;
        if (best != null && compareVersions(version, best.version) <= 0) continue;
        best = ReleaseInfo(
          tag: tag,
          version: version,
          notes: r['body'] as String? ?? '',
          url: r['html_url'] as String? ?? releasesPage,
          assets: {
            for (final a in (r['assets'] as List? ?? const []).whereType<Map>())
              if (a['name'] is String && a['browser_download_url'] is String) a['name'] as String: a['browser_download_url'] as String,
          },
        );
      }
      return best;
    } finally {
      client.close(force: true);
    }
  }

  // MARK: Installation

  static String get executable => Platform.resolvedExecutable;
  static String get appDirectory => File(executable).parent.path;

  static InstallKind get installKind {
    if (Platform.isWindows) {
      return File('$appDirectory${Platform.pathSeparator}unins000.exe').existsSync() ? InstallKind.windowsSetup : InstallKind.windowsPortable;
    }
    if (Platform.isLinux) {
      if ((Platform.environment['APPIMAGE'] ?? '').isNotEmpty) return InstallKind.appImage;
      if (executable.startsWith('/opt/kastideo/')) return InstallKind.deb;
    }
    return InstallKind.other;
  }

  static String _linuxArch() {
    try {
      final m = Process.runSync('uname', ['-m']).stdout.toString().trim();
      return m == 'aarch64' || m == 'arm64' ? 'aarch64' : 'x86_64';
    } catch (_) {
      return 'x86_64';
    }
  }

  /// Fichier de la version qui correspond à cette installation (null : page de la version).
  String? assetFor(ReleaseInfo r) {
    String? find(bool Function(String name) test) => r.assets.keys.where(test).firstOrNull;
    switch (installKind) {
      case InstallKind.windowsSetup:
        return find((n) => n.endsWith('-windows-x64-setup.exe')) ?? find((n) => n.endsWith('-windows-x64.zip'));
      case InstallKind.windowsPortable:
        return find((n) => n.endsWith('-windows-x64.zip'));
      case InstallKind.appImage:
        final arch = _linuxArch();
        return find((n) => n.endsWith('-linux-$arch.AppImage'));
      case InstallKind.deb:
        final arch = _linuxArch() == 'aarch64' ? 'arm64' : 'amd64';
        // libmpv2 : Ubuntu 24.04 / Zorin OS 18 ; sinon Ubuntu 22.04 / Zorin OS 17.
        final mpv2 = ['/usr/lib/x86_64-linux-gnu/libmpv.so.2', '/usr/lib/aarch64-linux-gnu/libmpv.so.2'].any((p) => File(p).existsSync());
        return find((n) => n.endsWith('_ubuntu${mpv2 ? '24.04' : '22.04'}_$arch.deb')) ?? find((n) => n.endsWith('_$arch.deb'));
      case InstallKind.other:
        return null;
    }
  }

  Future<File> _download(String url, File target) async {
    final client = HttpClient()..userAgent = 'Kastideo/$current';
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) throw HttpException('code HTTP ${response.statusCode}');
      final total = response.contentLength;
      var received = 0;
      final part = File('${target.path}.part');
      final sink = part.openWrite();
      var lastNotify = DateTime.now();
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && DateTime.now().difference(lastNotify).inMilliseconds > 200) {
          progress = received / total;
          lastNotify = DateTime.now();
          notifyListeners();
        }
      }
      await sink.flush();
      await sink.close();
      if (total > 0 && received < total) throw const HttpException('téléchargement interrompu');
      if (await target.exists()) await target.delete();
      return await part.rename(target.path);
    } finally {
      client.close(force: true);
    }
  }

  /// Télécharge et installe la version, puis relance Kastideo. [beforeExit] arrête proprement la lecture.
  /// Renvoie un message d'erreur, ou null si Kastideo va se fermer pour s'installer.
  Future<String?> install(ReleaseInfo release, {required Future<void> Function() beforeExit}) async {
    final name = assetFor(release);
    if (name == null) return 'no-asset';
    state = UpdateState.downloading;
    progress = 0;
    error = null;
    notifyListeners();
    try {
      final kind = installKind;
      final tmp = await Directory.systemTemp.createTemp('kastideo-update-');
      final sep = Platform.pathSeparator;
      PlaybackLog.shared.note('Téléchargement de la mise à jour : $name');
      if (kind == InstallKind.appImage) {
        final current = File(Platform.environment['APPIMAGE']!);
        final target = File('${current.parent.path}/$name');
        final file = await _download(release.assets[name]!, File('${tmp.path}/$name'));
        state = UpdateState.installing;
        notifyListeners();
        await file.copy(target.path);
        await Process.run('chmod', ['755', target.path]);
        if (target.path != current.path) {
          try {
            await current.delete();
          } catch (_) {}
        }
        await beforeExit();
        await Process.start(target.path, const [], mode: ProcessStartMode.detached);
        exit(0);
      }
      final file = await _download(release.assets[name]!, File('${tmp.path}$sep$name'));
      state = UpdateState.installing;
      notifyListeners();
      switch (kind) {
        case InstallKind.windowsSetup:
          final allUsers = appDirectory.toLowerCase().contains('program files');
          await beforeExit();
          await Process.start(
            file.path,
            ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CLOSEAPPLICATIONS', '/RELAUNCH=1', allUsers ? '/ALLUSERS' : '/CURRENTUSER'],
            mode: ProcessStartMode.detached,
          );
          exit(0);
        case InstallKind.windowsPortable:
          // Script lancé après la fermeture : décompresse, recopie les fichiers par-dessus, relance.
          final script = File('${tmp.path}${sep}update.cmd');
          final unpack = '${tmp.path}${sep}unpacked';
          await script.writeAsString([
            '@echo off',
            'chcp 65001 >nul',
            ':wait',
            'tasklist /FI "PID eq $pid" 2>nul | find "$pid" >nul && (timeout /t 1 /nobreak >nul & goto wait)',
            'powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Force -LiteralPath \'${file.path}\' -DestinationPath \'$unpack\'"',
            'for /d %%D in ("$unpack\\*") do xcopy /E /Y /I /Q "%%D\\*" "$appDirectory\\" >nul',
            'start "" "$executable"',
          ].join('\r\n'));
          await beforeExit();
          await Process.start('cmd', ['/c', script.path], mode: ProcessStartMode.detached, runInShell: false);
          exit(0);
        case InstallKind.deb:
          // apt installe le paquet (fenêtre de mot de passe du système), puis Kastideo est relancé.
          final result = await Process.run('pkexec', ['apt-get', 'install', '-y', '--allow-downgrades', file.path]);
          if (result.exitCode != 0) {
            state = UpdateState.available;
            error = (result.stderr as String).trim().isEmpty ? 'apt : code ${result.exitCode}' : (result.stderr as String).trim();
            notifyListeners();
            return 'deb:${file.path}';
          }
          await beforeExit();
          await Process.start('/opt/kastideo/kastideo', const [], mode: ProcessStartMode.detached);
          exit(0);
        case InstallKind.appImage:
        case InstallKind.other:
          return 'no-asset';
      }
    } catch (e) {
      state = UpdateState.available;
      error = '$e';
      progress = null;
      PlaybackLog.shared.note('Mise à jour impossible : $e');
      notifyListeners();
      return '$e';
    }
  }
}
