import 'dart:io';

/// Dossier Vidéos de l'utilisateur (Windows : %USERPROFILE%\Videos ; Linux : XDG_VIDEOS_DIR, sinon ~/Vidéos ou ~/Videos).
String videosDirectory() {
  final env = Platform.environment;
  final sep = Platform.pathSeparator;
  if (Platform.isWindows) {
    final home = env['USERPROFILE'] ?? env['HOMEDRIVE'] ?? 'C:';
    return '$home${sep}Videos';
  }
  final home = env['HOME'] ?? '.';
  try {
    final dirs = File('$home/.config/user-dirs.dirs');
    if (dirs.existsSync()) {
      for (final line in dirs.readAsLinesSync()) {
        final m = RegExp(r'^XDG_VIDEOS_DIR="(.*)"').firstMatch(line.trim());
        if (m != null) return m.group(1)!.replaceAll(r'$HOME', home);
      }
    }
  } catch (_) {}
  for (final name in ['Vidéos', 'Videos']) {
    if (Directory('$home/$name').existsSync()) return '$home/$name';
  }
  return '$home/Videos';
}

/// Dossier Kastideo des enregistrements et téléchargements (réglage, sinon Vidéos/Kastideo).
String kastideoFolder(String setting) {
  if (setting.trim().isNotEmpty) return setting.trim();
  return '${videosDirectory()}${Platform.pathSeparator}Kastideo';
}

/// Nom de fichier sans caractères interdits (Windows et Linux).
String safeFileName(String raw) {
  var s = raw.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  while (s.endsWith('.')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.length > 120) s = s.substring(0, 120).trim();
  return s.isEmpty ? 'Kastideo' : s;
}

String two(int n) => n.toString().padLeft(2, '0');

/// Extension de fichier d'une adresse de flux (mp4, mkv…), « mp4 » par défaut.
String extensionOf(String url) {
  final path = Uri.tryParse(url)?.path ?? url;
  final m = RegExp(r'\.([A-Za-z0-9]{2,4})$').firstMatch(path);
  return m == null ? 'mp4' : m.group(1)!.toLowerCase();
}

/// Taille lisible (« 1,2 Go »).
String sizeText(int bytes) {
  String f(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
  if (bytes >= 1024 * 1024 * 1024) return '${f(bytes / 1024 / 1024 / 1024)} Go';
  if (bytes >= 1024 * 1024) return '${f(bytes / 1024 / 1024)} Mo';
  if (bytes >= 1024) return '${(bytes / 1024).round()} Ko';
  return '$bytes o';
}

/// Durée lisible (« 1 h 05 », « 12 min », « 40 s »).
String durationText(Duration d) {
  if (d.inHours > 0) return '${d.inHours} h ${two(d.inMinutes % 60)}';
  if (d.inMinutes > 0) return '${d.inMinutes} min';
  return '${d.inSeconds} s';
}
