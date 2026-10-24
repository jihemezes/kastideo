import 'models.dart';

/// Analyse des playlists M3U / M3U8 étendues (portage du M3UParser de la version Mac).
class M3UParser {
  static const defaultGroup = 'Sans catégorie';

  static SourceContent parse(String text, String sourceId) {
    final items = <MediaItem>[];
    String? epgUrl;
    final seen = <String, int>{};
    var attributes = <String, String>{};
    String? pendingName;
    String? pendingGroup;

    for (var raw in text.split(RegExp(r'\r\n|\r|\n'))) {
      var line = raw.trim();
      if (line.startsWith('﻿')) line = line.substring(1);
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTM3U')) {
        final attrs = parseAttributes(line.substring(7));
        final value = attrs['url-tvg'] ?? attrs['x-tvg-url'] ?? attrs['tvg-url'];
        if (value != null && value.isNotEmpty) epgUrl = value.split(',').first.trim();
        continue;
      }
      if (line.startsWith('#EXTINF')) {
        var body = line.substring(7);
        while (body.startsWith(':')) {
          body = body.substring(1);
        }
        final parts = splitInfo(body);
        attributes = parseAttributes(parts.$1);
        pendingName = parts.$2;
        continue;
      }
      if (line.startsWith('#EXTGRP:')) {
        pendingGroup = line.substring(8).trim();
        continue;
      }
      if (line.startsWith('#')) continue;

      final uri = Uri.tryParse(line);
      if (uri == null || !uri.hasScheme) {
        attributes = {};
        pendingName = null;
        pendingGroup = null;
        continue;
      }

      var name = (pendingName ?? '').trim();
      if (name.isEmpty) name = attributes['tvg-name'] ?? '';
      if (name.isEmpty && uri.pathSegments.isNotEmpty) name = uri.pathSegments.last.split('.').first;
      if (name.isEmpty) name = line;

      var group = (attributes['group-title'] ?? pendingGroup ?? '').trim();
      if (group.isEmpty) group = defaultGroup;

      final logo = attributes['tvg-logo'];
      final epgId = attributes['tvg-id'];
      var id = '$sourceId:$line';
      final count = seen[id];
      if (count != null) {
        seen[id] = count + 1;
        id = '$id#${count + 1}';
      } else {
        seen[id] = 0;
      }
      items.add(MediaItem(
        id: id,
        sourceId: sourceId,
        kind: guessKind(uri),
        name: name,
        group: group,
        logo: (logo == null || logo.isEmpty) ? null : logo,
        stream: line,
        epgId: (epgId == null || epgId.isEmpty) ? null : epgId,
        number: int.tryParse(attributes['tvg-chno'] ?? ''),
      ));
      attributes = {};
      pendingName = null;
      pendingGroup = null;
    }
    return SourceContent(items, epgUrl: epgUrl);
  }

  static MediaKind guessKind(Uri uri) {
    final path = uri.path.toLowerCase();
    if (path.contains('/series/')) return MediaKind.series;
    if (path.contains('/movie/')) return MediaKind.movie;
    if (path.contains('/live/')) return MediaKind.live;
    final ext = path.contains('.') ? path.split('.').last : '';
    if (const ['mp4', 'mkv', 'avi', 'mov', 'm4v', 'wmv', 'flv', 'webm'].contains(ext)) return MediaKind.movie;
    return MediaKind.live;
  }

  /// Sépare les attributs du nom (première virgule hors guillemets).
  static (String, String) splitInfo(String body) {
    var inQuotes = false;
    for (var i = 0; i < body.length; i++) {
      final c = body[i];
      if (c == '"') inQuotes = !inQuotes;
      if (c == ',' && !inQuotes) return (body.substring(0, i), body.substring(i + 1));
    }
    return (body, '');
  }

  /// Paires clé="valeur" ou clé=valeur.
  static Map<String, String> parseAttributes(String text) {
    final result = <String, String>{};
    var i = 0;
    bool isSpace(String c) => c == ' ' || c == '\t';
    while (i < text.length) {
      while (i < text.length && isSpace(text[i])) {
        i++;
      }
      final keyStart = i;
      while (i < text.length && text[i] != '=' && !isSpace(text[i])) {
        i++;
      }
      if (i >= text.length || text[i] != '=') {
        while (i < text.length && !isSpace(text[i])) {
          i++;
        }
        continue;
      }
      final key = text.substring(keyStart, i).toLowerCase();
      i++;
      String value;
      if (i < text.length && text[i] == '"') {
        i++;
        final start = i;
        while (i < text.length && text[i] != '"') {
          i++;
        }
        value = text.substring(start, i.clamp(0, text.length));
        i++;
      } else {
        final start = i;
        while (i < text.length && !isSpace(text[i])) {
          i++;
        }
        value = text.substring(start, i);
      }
      if (key.isNotEmpty) result[key] = value.trim();
    }
    return result;
  }
}
