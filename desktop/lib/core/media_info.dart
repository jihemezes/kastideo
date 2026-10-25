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
        final client = TMDBClient(settings.tmdbKey, _language);
        final tmdb = await client.details(item.name, series: series, tmdbId: d.tmdbId, year: d.year, originalTitle: d.originalTitle);
        if (tmdb != null) d = d.merged(tmdb)..title ??= item.name;
        // Épisodes : titres et résumés de TMDB dans la langue de l'interface (ceux du fournisseur sont parfois en espagnol…).
        final seasons = _seasons[item.id];
        if (series && tmdb?.tmdbId != null && seasons != null && seasons.isNotEmpty) {
          _seasons[item.id] = await _localizedSeasons(client, tmdb!.tmdbId!, seasons);
        }
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

  Future<List<SeriesSeason>> _localizedSeasons(TMDBClient client, String tvId, List<SeriesSeason> seasons) async {
    final result = <SeriesSeason>[];
    for (final season in seasons.take(40)) {
      Map<int, TMDBEpisode> tmdb = const {};
      try {
        tmdb = await client.season(tvId, season.number);
      } catch (_) {}
      result.add(SeriesSeason(season.number, [
        for (final e in season.episodes)
          if (tmdb[e.number] case final t?)
            MediaItem(
              id: e.id,
              sourceId: e.sourceId,
              kind: e.kind,
              name: (t.name != null && !_generic(t.name!)) ? t.name! : e.name,
              group: e.group,
              logo: e.logo ?? t.still,
              stream: e.stream,
              seriesId: e.seriesId,
              number: e.number,
              info: t.overview ?? e.info,
              added: e.added,
            )
          else
            e,
      ]));
    }
    return result;
  }

  static bool _generic(String name) => RegExp(r'^(Épisode|Episode|Episodio|Capítulo|Capitulo)\s*\d+$', caseSensitive: false).hasMatch(name.trim());

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
