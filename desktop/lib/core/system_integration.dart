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

  static String get _home => Platform.environment['HOME'] ?? '';
  static File get _autostartFile => File('$_home/.config/autostart/fr.jmezes.kastideo.desktop');

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
        final r = await Process.run('xdg-mime', ['query', 'default', 'audio/x-mpegurl']);
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
          final r = await Process.run('xdg-mime', ['default', 'fr.jmezes.kastideo-m3u.desktop', ..._mimeTypes]);
          if (r.exitCode != 0) return '${r.stderr}'.trim();
        } else {
          if (desktop.existsSync()) await desktop.delete();
          // L'application par défaut redevient celle choisie par le système.
          final list = File('$_home/.config/mimeapps.list');
          if (list.existsSync()) {
            final lines = list.readAsLinesSync().where((l) => !l.contains('fr.jmezes.kastideo-m3u.desktop')).toList();
            await list.writeAsString('${lines.join('\n')}\n');
          }
        }
        await Process.run('update-desktop-database', [apps.path]).catchError((_) => ProcessResult(0, 0, '', ''));
      } catch (e) {
        return '$e';
      }
      return null;
    }
    return 'unsupported';
  }
}
