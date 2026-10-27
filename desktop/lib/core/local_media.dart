import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// Ce qu'un nom de fichier vidéo laisse deviner.
enum LocalKind { movie, episode, video }

class LocalEntry {
  LocalEntry({required this.kind, required this.title, this.year, this.series, this.season, this.episode});
  final LocalKind kind;
  final String title;
  final int? year;
  final String? series;
  final int? season;
  final int? episode;
}

/// Reconnaît films, épisodes et vidéos personnelles d'après leur nom et leur dossier
/// (« Titre (2020).mkv », « Titre.2020.1080p.mkv », « Série S01E02 », « Série/Saison 1/1x02 »…).
class LocalNameParser {
  LocalNameParser._();

  static const videoExtensions = {'mkv', 'mp4', 'm4v', 'avi', 'mov', 'wmv', 'ts', 'm2ts', 'mts', 'mpg', 'mpeg', 'webm', 'flv', 'vob', 'ogv', '3gp', 'divx'};
  static const subtitleExtensions = {'srt', 'ass', 'ssa', 'vtt', 'sub'};

  static final _episode = RegExp(r'(?:^|[^a-z0-9])s(\d{1,2})[ ._-]*e(\d{1,3})(?:[^0-9]|$)', caseSensitive: false);
  static final _episodeX = RegExp(r'(?:^|[^0-9])(\d{1,2})x(\d{2,3})(?:[^0-9]|$)', caseSensitive: false);
  static final _seasonFolder = RegExp(r'^(?:saison|season|staffel|temporada|s)[ ._-]*(\d{1,2})$', caseSensitive: false);
  static final _year = RegExp(r'(?:^|[\s.(\[_-])((?:19|20)\d{2})(?:[\s.)\]_-]|$)');
  static final _tags = RegExp(
    r'\b(2160p|1080p|1080i|720p|576p|480p|4k|uhd|hdr10?|hdr|dv|dolby|vision|x264|x265|h\.?264|h\.?265|hevc|avc|xvid|divx|'
    r'bluray|blu-ray|bdrip|brrip|webrip|web-dl|webdl|web|hdtv|dvdrip|dvd|remux|proper|repack|extended|unrated|'
    r'multi|truefrench|french|vff|vfq|vf2|vf|vostfr|vost|subfrench|english|dts|ac3|eac3|aac|ddp?5\.?1|5\.1|7\.1|atmos|10bit)\b.*$',
    caseSensitive: false,
  );

  static String _clean(String raw) {
    var t = raw.replaceAll(RegExp(r'[._]+'), ' ').replaceAll(RegExp(r'\[[^\]]*\]'), ' ');
    t = t.replaceFirst(_tags, '');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    while (t.isNotEmpty && '-–([{'.contains(t[t.length - 1])) {
      t = t.substring(0, t.length - 1).trim();
    }
    while (t.isNotEmpty && '-–)]}'.contains(t[0])) {
      t = t.substring(1).trim();
    }
    return t;
  }

  static String baseName(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static List<String> _folders(String path) {
    final parts = path.split(RegExp(r'[\\/]')).where((p) => p.isNotEmpty).toList();
    return parts.length > 1 ? parts.sublist(0, parts.length - 1) : const [];
  }

  /// [relative] : chemin du fichier par rapport au dossier de la source (ses sous-dossiers aident à le reconnaître).
  /// [aloneInFolder] : seule vidéo de son dossier (« Titre (2020)/film.mkv ») ; sinon l'année du dossier
  /// (« Vacances 2024/plage.mp4 ») ne fait pas un film.
  static LocalEntry parse(String relative, {bool aloneInFolder = true}) {
    final base = baseName(relative);
    final folders = _folders(relative);
    // Épisode : SxxEyy ou 1x02 dans le nom (ou, à défaut, dans le dossier).
    var m = _episode.firstMatch(base) ?? _episodeX.firstMatch(base);
    if (m != null) {
      final season = int.parse(m.group(1)!);
      final episode = int.parse(m.group(2)!);
      var series = _clean(base.substring(0, m.start));
      final rest = _clean(base.substring(m.end));
      if (series.isEmpty) {
        // « Série/Saison 1/S01E02.mkv » : le nom de la série est celui du dossier.
        for (final f in folders.reversed) {
          if (_seasonFolder.hasMatch(f.trim())) continue;
          series = _clean(f);
          break;
        }
      }
      series = series.replaceFirst(_year, '').trim();
      if (series.isEmpty) series = 'Série';
      final title = rest.isEmpty ? 'Épisode $episode' : rest;
      return LocalEntry(kind: LocalKind.episode, title: title, series: series, season: season, episode: episode);
    }
    // Dossier « Saison 2 » sans SxxEyy : numéro d'épisode en tête du nom.
    if (folders.isNotEmpty) {
      final season = _seasonFolder.firstMatch(folders.last.trim());
      final number = RegExp(r'^(?:e|ep|episode|épisode)?[ ._-]*(\d{1,3})(?:[^0-9]|$)', caseSensitive: false).firstMatch(base);
      if (season != null && number != null && folders.length >= 2) {
        final series = _clean(folders[folders.length - 2]).replaceFirst(_year, '').trim();
        final rest = _clean(base.substring(number.end));
        final episode = int.parse(number.group(1)!);
        return LocalEntry(
          kind: LocalKind.episode,
          title: rest.isEmpty ? 'Épisode $episode' : rest,
          series: series.isEmpty ? 'Série' : series,
          season: int.parse(season.group(1)!),
          episode: episode,
        );
      }
    }
    // Film : une année dans le nom, ou dans le dossier « Titre (2020) ».
    final y = _year.allMatches(base).lastOrNull;
    if (y != null) {
      final title = _clean(base.substring(0, y.start));
      if (title.isNotEmpty) return LocalEntry(kind: LocalKind.movie, title: title, year: int.parse(y.group(1)!));
    }
    if (folders.isNotEmpty && aloneInFolder) {
      final fy = _year.allMatches(folders.last).lastOrNull;
      if (fy != null) {
        final title = _clean(folders.last.substring(0, fy.start));
        if (title.isNotEmpty) return LocalEntry(kind: LocalKind.movie, title: title, year: int.parse(fy.group(1)!));
      }
    }
    // Étiquettes de version (1080p, BluRay…) sans année : sans doute un film quand même.
    if (_tags.hasMatch(base.replaceAll(RegExp(r'[._]+'), ' '))) {
      final title = _clean(base);
      if (title.isNotEmpty) return LocalEntry(kind: LocalKind.movie, title: title);
    }
    return LocalEntry(kind: LocalKind.video, title: _clean(base).isEmpty ? base : _clean(base));
  }
}

/// Examine les dossiers d'une source (disque, clé USB, NAS monté) : films, séries (épisodes regroupés) et vidéos.
/// À lancer dans un isolat (catalogues de plusieurs milliers de fichiers).
SourceContent scanFolders(List<String> roots, String sourceId, {String videosLabel = 'Vidéos', String moviesLabel = 'Films', String seriesLabel = 'Séries'}) {
  final items = <MediaItem>[];
  final seriesIds = <String, String>{};
  final seriesNames = <String, String>{};
  final seriesRoots = <String, String>{};
  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    final rootName = root.split(RegExp(r'[\\/]')).where((p) => p.isNotEmpty).lastOrNull ?? root;
    bool isVideo(String path) {
      final name = path.split(RegExp(r'[\\/]')).last;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      return LocalNameParser.videoExtensions.contains(ext);
    }

    final videos = videoFiles(dir).where(isVideo).toList();
    final perFolder = <String, int>{};
    String parentOf(String path) => path.substring(0, path.lastIndexOf(RegExp(r'[\\/]')).clamp(0, path.length));
    for (final path in videos) {
      perFolder.update(parentOf(path), (n) => n + 1, ifAbsent: () => 1);
    }
    for (final path in videos) {
      final relative = path.substring(root.length).replaceFirst(RegExp(r'^[\\/]+'), '');
      if (RegExp(r'(^|[\\/])(sample|trailers?|extras?|featurettes?)([\\/]|$)', caseSensitive: false).hasMatch(relative)) continue;
      DateTime? modified;
      try {
        modified = File(path).statSync().modified;
      } catch (_) {}
      final entry = LocalNameParser.parse(relative, aloneInFolder: perFolder[parentOf(path)] == 1);
      final key = stableHash(path);
      switch (entry.kind) {
        case LocalKind.movie:
          items.add(
            MediaItem(
              id: '$sourceId:movie:$key',
              sourceId: sourceId,
              kind: MediaKind.movie,
              name: entry.year == null ? entry.title : '${entry.title} (${entry.year})',
            year: entry.year,
              group: '$moviesLabel · $rootName',
              stream: path,
              added: modified,
            ),
          );
        case LocalKind.episode:
          final seriesKey = entry.series!.toLowerCase();
          final seriesId = seriesIds.putIfAbsent(seriesKey, () => '$sourceId:series:${stableHash(seriesKey)}');
          seriesNames.putIfAbsent(seriesKey, () => entry.series!);
          seriesRoots.putIfAbsent(seriesKey, () => rootName);
          items.add(
            MediaItem(
              id: '$sourceId:episode:$key',
              sourceId: sourceId,
              kind: MediaKind.episode,
              name: entry.title,
              group: seriesNames[seriesKey]!,
              stream: path,
              seriesId: seriesId,
              number: entry.episode,
              season: entry.season,
              added: modified,
            ),
          );
        case LocalKind.video:
          // Vidéos personnelles : rubrique à part, rangée par dossier.
          final parts = relative.split(RegExp(r'[\\/]'));
          final folder = parts.length > 1 ? parts[parts.length - 2] : rootName;
          items.add(
            MediaItem(
              id: '$sourceId:movie:$key',
              sourceId: sourceId,
              kind: MediaKind.movie,
              name: entry.title,
              group: '$videosLabel · $folder',
              stream: path,
              added: modified,
            ),
          );
      }
    }
  }
  // Une fiche « série » par série trouvée (date : épisode le plus récent).
  final latest = <String, DateTime>{};
  for (final i in items.where((i) => i.kind == MediaKind.episode)) {
    final d = i.added;
    if (d != null && (latest[i.seriesId!] == null || d.isAfter(latest[i.seriesId!]!))) latest[i.seriesId!] = d;
  }
  seriesIds.forEach((key, id) {
    items.add(
      MediaItem(
        id: id,
        sourceId: sourceId,
        kind: MediaKind.series,
        name: seriesNames[key]!,
        group: '$seriesLabel · ${seriesRoots[key]}',
        seriesId: id,
        added: latest[id],
      ),
    );
  });
  return SourceContent(items);
}

/// Sous-titres placés à côté d'une vidéo locale (« film.srt », « film.fr.srt »…).
List<String> sidecarSubtitles(String videoPath) {
  try {
    final file = File(videoPath);
    final dir = file.parent;
    final base = LocalNameParser.baseName(videoPath).toLowerCase();
    return [
      for (final e in dir.listSync())
        if (e is File)
          if (LocalNameParser.subtitleExtensions.contains(e.path.split('.').last.toLowerCase()))
            if (LocalNameParser.baseName(e.path).toLowerCase().startsWith(base)) e.path,
    ];
  } catch (_) {
    return const [];
  }
}

/// Fichiers d'un dossier et de ses sous-dossiers. Un sous-dossier illisible (« System Volume Information » d'une clé USB,
/// droits d'un NAS) est ignoré sans interrompre l'examen ; les liens symboliques sont suivis, sans boucle.
List<String> videoFiles(Directory root, {int maxDepth = 12}) {
  final files = <String>[];
  final visited = <String>{};
  const skipped = {'system volume information', r'$recycle.bin', '@eadir', '#recycle', 'lost+found', '.trash', '.trashes'};
  void walk(Directory dir, int depth) {
    if (depth > maxDepth) return;
    try {
      if (!visited.add(dir.resolveSymbolicLinksSync())) return;
    } catch (_) {
      return;
    }
    final List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } catch (_) {
      return;
    }
    for (final e in entries) {
      final name = e.path.split(RegExp(r'[\\/]')).last;
      if (name.startsWith('.')) continue;
      var type = e is File ? FileSystemEntityType.file : (e is Directory ? FileSystemEntityType.directory : FileSystemEntityType.notFound);
      if (e is Link) {
        try {
          type = FileSystemEntity.typeSync(e.path);
        } catch (_) {
          continue;
        }
      }
      if (type == FileSystemEntityType.file) {
        files.add(e.path);
      } else if (type == FileSystemEntityType.directory && !skipped.contains(name.toLowerCase())) {
        walk(Directory(e.path), depth + 1);
      }
    }
  }

  walk(root, 0);
  return files;
}

/// Empreinte stable d'un texte (FNV-1a 32 bits), identique d'un lancement et d'une version à l'autre.
String stableHash(String text) {
  var h = 0x811c9dc5;
  for (final c in utf8.encode(text)) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16);
}
