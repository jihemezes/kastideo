import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import 'models.dart';

/// État de l'autorisation d'accès aux vidéos de la galerie.
enum GalleryAccess { granted, limited, denied }

/// Album (dossier) de la galerie qui contient des vidéos.
class GalleryAlbum {
  const GalleryAlbum(this.id, this.name, this.count);
  final String id;
  final String name;
  final int count;
}

/// Vidéos de la galerie du téléphone (Android) : lues avec MediaStore par le code Android.
class Gallery {
  Gallery._();

  static const _channel = MethodChannel('fr.jmezes.kastideo/device');

  /// Repère les vidéos dont le nom est celui d'une caméra (VID_2026…) : pas de recherche TMDB.
  static const genericMarker = 'galerie:generique';

  static bool get isAvailable => Platform.isAndroid;

  static GalleryAccess _parse(String? value) => switch (value) {
        'granted' => GalleryAccess.granted,
        'limited' => GalleryAccess.limited,
        _ => GalleryAccess.denied,
      };

  static Future<GalleryAccess> status() async {
    if (!isAvailable) return GalleryAccess.denied;
    try {
      return _parse(await _channel.invokeMethod<String>('galleryStatus'));
    } catch (_) {
      return GalleryAccess.denied;
    }
  }

  /// Demande l'accès (ou, en accès partiel, rouvre le choix des vidéos autorisées).
  static Future<GalleryAccess> request() async {
    if (!isAvailable) return GalleryAccess.denied;
    try {
      return _parse(await _channel.invokeMethod<String>('galleryRequest'));
    } catch (_) {
      return GalleryAccess.denied;
    }
  }

  static Future<List<GalleryAlbum>> albums() async {
    if (!isAvailable) return const [];
    try {
      final list = await _channel.invokeListMethod<Map>('galleryAlbums') ?? const [];
      return [for (final a in list) GalleryAlbum('${a['id']}', '${a['name']}', (a['count'] as num?)?.toInt() ?? 0)];
    } catch (e) {
      debugPrint('Gallery.albums : $e');
      return const [];
    }
  }

  static final _genericName = RegExp(
    r'^(?:VID|IMG|MVI|PXL|MOV|DSC|DJI|GOPR|GH\d*|VIDEO|TRIM|WA\d|Screen[ _-]?Recording|Screenrecorder)[A-Za-z]*[_\- ]?\d[\w\- ]*$|^[\d_\-. ]+$',
    caseSensitive: false,
  );

  static bool isGenericName(String name) => name.isEmpty || _genericName.hasMatch(name);

  /// Une entrée par vidéo (albums choisis ; liste vide : toutes), triées de la plus récente à la plus ancienne.
  static Future<List<MediaItem>> scan(String sourceId, List<String> albumIds, {required String videosLabel}) async {
    final list = await _channel.invokeListMethod<Map>('galleryVideos', {'albums': albumIds}) ?? const [];
    final items = <MediaItem>[];
    for (final v in list) {
      final id = '${v['id']}';
      final file = (v['name'] as String?) ?? '';
      final dot = file.lastIndexOf('.');
      final base = dot > 0 ? file.substring(0, dot) : file;
      final millis = (v['date'] as num?)?.toInt() ?? 0;
      final date = millis > 0 ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
      final generic = isGenericName(base);
      final dateText = date == null ? '' : _formatDate(date);
      final path = (v['path'] as String?) ?? '';
      final thumb = (v['thumb'] as String?) ?? '';
      final durationMs = (v['duration'] as num?)?.toInt() ?? 0;
      final bucket = (v['bucket'] as String?) ?? '';
      items.add(
        MediaItem(
          id: '$sourceId:movie:g$id',
          sourceId: sourceId,
          kind: MediaKind.movie,
          name: generic ? (dateText.isEmpty ? tr('Vidéo') : '${tr('Vidéo du')} $dateText') : base,
          group: '$videosLabel · ${bucket.isEmpty ? tr('Galerie') : bucket}',
          stream: path.isNotEmpty ? path : (v['uri'] as String?),
          logo: thumb.isEmpty ? null : 'file://$thumb',
          info: generic && dateText.isNotEmpty ? '${tr('Prise le')} $dateText' : null,
          epgId: generic ? genericMarker : null,
          added: date,
          runtime: durationMs > 0 ? (durationMs / 60000).round().clamp(1, 100000) : null,
        ),
      );
    }
    return items;
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
