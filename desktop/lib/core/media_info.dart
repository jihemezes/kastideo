import 'package:flutter/foundation.dart';

import '../l10n.dart';
import 'details.dart';
import 'library.dart';
import 'log.dart';
import 'models.dart';
import 'settings.dart';
import 'text.dart';

/// Fiches des films et séries (fournisseur IPTV, complétées par TMDB si une clé est saisie) et saisons des séries.
class MediaInfoStore extends ChangeNotifier {
  MediaInfoStore(this.library, this.settings);
  final LibraryStore library;
  final AppSettings settings;

  final Map<String, MediaDetails> _cache = {};
  final Map<String, List<SeriesSeason>> _seasons = {};
  final Set<String> _loading = {};
  final Map<String, String> errors = {};

  MediaDetails? details(String id) => _cache[id];
  List<SeriesSeason>? seasons(String id) => _seasons[id];
  bool isLoading(String id) => _loading.contains(id);

  String get _language => L10n.english ? 'en-US' : 'fr-FR';

  /// Charge la fiche (une seule fois par session) ; pour une série Xtream, aussi les saisons.
  Future<void> load(MediaItem item, {bool force = false}) async {
    if (!force && (_cache.containsKey(item.id) || _loading.contains(item.id))) return;
    _loading.add(item.id);
    notifyListeners();
    final series = item.kind == MediaKind.series;
    var d = MediaDetails()
      ..title = item.name
      ..plot = item.info
      ..poster = item.logo;
    try {
      final client = await library.xtreamClient(item.sourceId);
      if (client != null) {
        if (series && item.seriesId != null) {
          final (info, seasons) = await client.seriesInfo(item);
          _seasons[item.id] = seasons;
          d = info..title ??= item.name;
          d.plot ??= item.info;
          d.poster ??= item.logo;
        } else if (item.kind == MediaKind.movie) {
          final id = item.id.split(':').last;
          final info = await client.movieDetails(id);
          d = info..title ??= item.name;
          d.poster ??= item.logo;
        }
      }
    } catch (e) {
      PlaybackLog.shared.note('Fiche IPTV indisponible pour « ${item.name} » : $e');
    }
    if (settings.usesTMDB && item.kind != MediaKind.episode) {
      try {
        final tmdb = await TMDBClient(settings.tmdbKey, _language).details(item.name, series: series, tmdbId: d.tmdbId, year: d.year);
        if (tmdb != null) d = d.merged(tmdb)..title ??= item.name;
        errors.remove(item.id);
      } catch (e) {
        errors[item.id] = tr('TMDB n\'a pas répondu (vérifiez la clé dans Réglages > Général).');
        PlaybackLog.shared.note('TMDB : échec pour « ${item.name} » : $e');
      }
    }
    if (d.sources.isEmpty) d.sources = ['IPTV'];
    _cache[item.id] = d;
    _loading.remove(item.id);
    notifyListeners();
  }

  void clear() {
    _cache.clear();
    _trending.clear();
    notifyListeners();
  }

  final Map<bool, (DateTime, List<TMDBTrend>)> _trending = {};
  final Map<MediaKind, (int, Map<String, MediaItem>)> _titleIndex = {};

  /// Tendances TMDB de la semaine (mises en cache 6 h).
  Future<List<TMDBTrend>> trending({required bool series}) async {
    if (!settings.usesTMDB) return const [];
    final cached = _trending[series];
    if (cached != null && DateTime.now().difference(cached.$1) < const Duration(hours: 6)) return cached.$2;
    try {
      final list = await TMDBClient(settings.tmdbKey, _language).trending(series: series);
      _trending[series] = (DateTime.now(), list);
      return list;
    } catch (e) {
      PlaybackLog.shared.note('TMDB : tendances indisponibles ($e)');
      return const [];
    }
  }

  /// Retrouve les tendances dans le catalogue (titre nettoyé, puis titre original).
  List<(MediaItem, TMDBTrend)> match(List<TMDBTrend> trends, MediaKind kind) {
    final items = library.items(kind);
    var index = _titleIndex[kind];
    if (index == null || index.$1 != items.length) {
      final map = <String, MediaItem>{};
      for (final item in items) {
        final key = titleKey(item.name);
        if (key.isNotEmpty) map.putIfAbsent(key, () => item);
      }
      index = (items.length, map);
      _titleIndex[kind] = index;
    }
    return [
      for (final t in trends)
        if ([titleKey(t.title), if (t.originalTitle != null) titleKey(t.originalTitle!)].map((k) => index!.$2[k]).nonNulls.firstOrNull
            case final item?)
          (item, t),
    ];
  }
}
