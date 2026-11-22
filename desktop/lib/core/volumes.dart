import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'device.dart';

/// Support de stockage proposé pour les enregistrements (mémoire interne, clé USB, carte SD).
class StorageVolume {
  StorageVolume({required this.label, required this.path, required this.removable, this.freeBytes});
  final String label;

  /// Dossier de Kastideo sur ce support (écriture possible sans autorisation particulière).
  final String path;
  final bool removable;
  int? freeBytes;
}

/// Supports montés sur la télévision : le dossier propre à l'application sur chacun (Android/data/…/files).
/// C'est le seul emplacement d'une clé USB où Android autorise l'écriture sans « accès à tous les fichiers ».
Future<List<StorageVolume>> storageVolumes() async {
  if (!Device.isAndroid) return const [];
  final result = <StorageVolume>[];
  try {
    final dirs = await getExternalStorageDirectories() ?? const <Directory>[];
    for (var i = 0; i < dirs.length; i++) {
      final path = dirs[i].path;
      final id = RegExp(r'^/storage/([^/]+)/').firstMatch(path)?.group(1) ?? '';
      final removable = i > 0 || (id.isNotEmpty && id != 'emulated');
      result.add(StorageVolume(
        label: removable ? (id.isEmpty ? 'USB' : 'USB · $id') : '',
        path: '$path${Platform.pathSeparator}Kastideo',
        removable: removable,
        freeBytes: await _freeBytes(path),
      ));
    }
  } catch (_) {}
  return result;
}

/// Espace libre (octets) d'un dossier, d'après la commande « df » ; nul si elle n'est pas disponible.
Future<int?> _freeBytes(String path) async {
  try {
    final r = await Process.run('df', ['-k', path]).timeout(const Duration(seconds: 3));
    final lines = r.stdout.toString().trim().split('\n');
    if (lines.length < 2) return null;
    final cols = lines.last.trim().split(RegExp(r'\s+'));
    // Filesystem 1K-blocks Used Available Use% Mounted : « Available » est la 4e colonne.
    if (cols.length < 4) return null;
    final kb = int.tryParse(cols[3]);
    return kb == null ? null : kb * 1024;
  } catch (_) {
    return null;
  }
}
