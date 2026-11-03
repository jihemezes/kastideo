import 'dart:io';

import 'log.dart';

/// Intégration au système : lancement à l'ouverture de session et fichiers .m3u / .m3u8.
/// Windows : registre de l'utilisateur (HKCU) ; Linux : ~/.config/autostart et xdg-mime.
class SystemIntegration {
  SystemIntegration._();

  static const _runKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _mimeTypes = ['audio/x-mpegurl', 'audio/mpegurl', 'application/x-mpegurl', 'application/vnd.apple.mpegurl'];

  /// Programme à lancer (l'AppImage elle-même, pas son point de montage temporaire).
  static String get launchPath {
    final appImage = Platform.environment['APPIMAGE'];
    if (appImage != null && appImage.isNotEmpty) return appImage;
    return Platform.resolvedExecutable;
  }

  /// Dossier personnel (remplaçable pour les tests).
  static String? homeOverride;
  static String get _home => homeOverride ?? Platform.environment['HOME'] ?? '';
  static File get _autostartFile => File('$_home/.config/autostart/fr.jmezes.kastideo.desktop');

  /// Environnement propre pour lancer les outils du système (xdg-mime, gio…) : dans une AppImage, LD_LIBRARY_PATH et
  /// consorts pointent vers les bibliothèques embarquées, ce qui fait échouer ces programmes.
  static Map<String, String> get _cleanEnv {
    const drop = {
      'LD_LIBRARY_PATH', 'LD_PRELOAD', 'GIO_MODULE_DIR', 'GIO_EXTRA_MODULES', 'GTK_PATH', 'GTK_EXE_PREFIX', 'GTK_DATA_PREFIX',
      'GDK_PIXBUF_MODULE_FILE', 'GDK_PIXBUF_MODULEDIR', 'GSETTINGS_SCHEMA_DIR', 'PYTHONHOME', 'PYTHONPATH', 'PERLLIB', 'PERL5LIB',
      'QT_PLUGIN_PATH', 'APPDIR', 'APPIMAGE', 'ARGV0', 'OWD',
    };
    final env = {for (final e in Platform.environment.entries) if (!drop.contains(e.key)) e.key: e.value};
    final appDir = Platform.environment['APPDIR'];
    if (appDir != null && appDir.isNotEmpty && env['PATH'] != null) {
      env['PATH'] = env['PATH']!.split(':').where((p) => !p.startsWith(appDir)).join(':');
    }
    return env;
  }

  static Future<ProcessResult> _system(String exe, List<String> args) =>
      Process.run(exe, args, environment: _cleanEnv, includeParentEnvironment: false).timeout(const Duration(seconds: 15));

  static File get _mimeApps => File('$_home/.config/mimeapps.list');
  static const _desktopId = 'fr.jmezes.kastideo-m3u.desktop';

  /// Ajoute (ou retire) notre application comme programme par défaut des types M3U dans mimeapps.list,
  /// sans dépendre de xdg-mime (le fichier est lu par GNOME, KDE, Cinnamon, XFCE…).
  static Future<void> _writeMimeApps(bool enabled) async {
    final file = _mimeApps;
    await file.parent.create(recursive: true);
    final lines = file.existsSync() ? file.readAsLinesSync() : <String>[];
    final out = <String>[];
    var section = '';
    var hasDefaults = false;
    final entries = [for (final t in _mimeTypes) '$t=$_desktopId'];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[')) {
        if (section == '[Default Applications]' && enabled) out.addAll(entries);
        section = trimmed;
        if (section == '[Default Applications]') hasDefaults = true;
        out.add(line);
        continue;
      }
      if (section == '[Default Applications]' && _mimeTypes.any((t) => trimmed.startsWith('$t='))) continue;
      if (!enabled && line.contains(_desktopId)) continue;
      out.add(line);
    }
    if (section == '[Default Applications]' && enabled) out.addAll(entries);
    if (enabled && !hasDefaults) {
      if (out.isNotEmpty && out.last.trim().isNotEmpty) out.add('');
      out..add('[Default Applications]')..addAll(entries);
    }
    await file.writeAsString('${out.join('\n')}\n');
  }

  static Future<ProcessResult?> _reg(List<String> args) async {
    try {
      return await Process.run('reg', args);
    } catch (e) {
      PlaybackLog.shared.note('Registre inaccessible : $e');
      return null;
    }
  }

  // MARK: Lancement à l'ouverture de session

  static Future<bool> autostartEnabled() async {
    if (Platform.isWindows) {
      final r = await _reg(['query', _runKey, '/v', 'Kastideo']);
      return r != null && r.exitCode == 0;
    }
    if (Platform.isLinux) return _autostartFile.existsSync();
    return false;
  }

  static Future<bool> autostartMinimized() async {
    if (Platform.isWindows) {
      final r = await _reg(['query', _runKey, '/v', 'Kastideo']);
      return r != null && r.exitCode == 0 && '${r.stdout}'.contains('--minimized');
    }
    if (Platform.isLinux && _autostartFile.existsSync()) return _autostartFile.readAsStringSync().contains('--minimized');
    return false;
  }

  static Future<void> setAutostart(bool enabled, {bool minimized = true}) async {
    final args = minimized ? ' --minimized' : '';
    if (Platform.isWindows) {
      if (enabled) {
        await _reg(['add', _runKey, '/v', 'Kastideo', '/t', 'REG_SZ', '/d', '"$launchPath"$args', '/f']);
      } else {
        await _reg(['delete', _runKey, '/v', 'Kastideo', '/f']);
      }
    } else if (Platform.isLinux) {
      if (enabled) {
        await _autostartFile.parent.create(recursive: true);
        await _autostartFile.writeAsString([
          '[Desktop Entry]',
          'Type=Application',
          'Name=Kastideo',
          'Exec="$launchPath"$args',
          'Icon=fr.jmezes.kastideo',
          'Terminal=false',
          'X-GNOME-Autostart-enabled=true',
          '',
        ].join('\n'));
      } else if (_autostartFile.existsSync()) {
        await _autostartFile.delete();
      }
    }
  }

  /// Au lancement : si le lancement automatique est actif, son chemin suit l'application (nouvelle AppImage, autre dossier).
  static Future<void> refreshAutostartPath() async {
    try {
      if (!await autostartEnabled()) return;
      final text = Platform.isLinux ? _autostartFile.readAsStringSync() : '';
      if (Platform.isLinux && text.contains('"$launchPath"')) return;
      await setAutostart(true, minimized: await autostartMinimized());
    } catch (_) {}
  }

  // MARK: Fichiers .m3u / .m3u8

  static Future<bool> m3uAssociated() async {
    if (Platform.isWindows) {
      final r = await _reg(['query', r'HKCU\Software\Classes\.m3u', '/ve']);
      if (r != null && r.exitCode == 0 && '${r.stdout}'.contains('Kastideo.m3u')) return true;
      final m = await _reg(['query', r'HKLM\Software\Classes\.m3u', '/ve']);
      return m != null && m.exitCode == 0 && '${m.stdout}'.contains('Kastideo.m3u');
    }
    if (Platform.isLinux) {
      try {
        if (_mimeApps.existsSync()) {
          final inDefaults = _mimeApps.readAsLinesSync().any((l) => l.contains('=$_desktopId') && _mimeTypes.any((t) => l.startsWith('$t=')));
          if (inDefaults) return true;
        }
        final r = await _system('xdg-mime', ['query', 'default', 'audio/x-mpegurl']);
        return '${r.stdout}'.contains('kastideo');
      } catch (_) {}
    }
    return false;
  }

  static Future<String?> setM3uAssociation(bool enabled) async {
    if (Platform.isWindows) {
      const cls = r'HKCU\Software\Classes';
      if (enabled) {
        await _reg(['add', '$cls\\Kastideo.m3u', '/ve', '/d', 'Playlist M3U', '/f']);
        await _reg(['add', '$cls\\Kastideo.m3u\\DefaultIcon', '/ve', '/d', '"${Platform.resolvedExecutable}",0', '/f']);
        await _reg(['add', '$cls\\Kastideo.m3u\\shell\\open\\command', '/ve', '/d', '"${Platform.resolvedExecutable}" "%1"', '/f']);
        for (final ext in ['.m3u', '.m3u8']) {
          await _reg(['add', '$cls\\$ext', '/ve', '/d', 'Kastideo.m3u', '/f']);
          await _reg(['add', '$cls\\$ext\\OpenWithProgids', '/v', 'Kastideo.m3u', '/t', 'REG_NONE', '/f']);
        }
      } else {
        for (final ext in ['.m3u', '.m3u8']) {
          final r = await _reg(['query', '$cls\\$ext', '/ve']);
          if (r != null && '${r.stdout}'.contains('Kastideo.m3u')) await _reg(['delete', '$cls\\$ext', '/ve', '/f']);
          await _reg(['delete', '$cls\\$ext\\OpenWithProgids', '/v', 'Kastideo.m3u', '/f']);
        }
        await _reg(['delete', '$cls\\Kastideo.m3u', '/f']);
      }
      return null;
    }
    if (Platform.isLinux) {
      // Fichier .desktop de l'utilisateur qui accepte un fichier (%f), puis association avec xdg-mime.
      final apps = Directory('$_home/.local/share/applications');
      final desktop = File('${apps.path}/fr.jmezes.kastideo-m3u.desktop');
      try {
        if (enabled) {
          await apps.create(recursive: true);
          await desktop.writeAsString([
            '[Desktop Entry]',
            'Type=Application',
            'Name=Kastideo',
            'Exec="$launchPath" %f',
            'Icon=fr.jmezes.kastideo',
            'Terminal=false',
            'NoDisplay=true',
            'MimeType=${_mimeTypes.join(';')};',
            '',
          ].join('\n'));
          // Écriture directe de mimeapps.list (fiable partout), puis xdg-mime pour prévenir le bureau (sans conséquence si absent).
          await _writeMimeApps(true);
          try {
            await _system('update-desktop-database', [apps.path]);
            await _system('xdg-mime', ['default', _desktopId, ..._mimeTypes]);
          } catch (e) {
            PlaybackLog.shared.note('xdg-mime : $e');
          }
          if (!await m3uAssociated()) return 'L\'association n\'a pas pu être enregistrée (${_mimeApps.path}).';
        } else {
          if (desktop.existsSync()) await desktop.delete();
          // L'application par défaut redevient celle choisie par le système.
          if (_mimeApps.existsSync()) await _writeMimeApps(false);
        }
        await _system('update-desktop-database', [apps.path]).catchError((_) => ProcessResult(0, 0, '', ''));
      } catch (e) {
        return '$e';
      }
      return null;
    }
    return 'unsupported';
  }
}
