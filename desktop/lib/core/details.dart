import 'dart:convert';
import 'dart:io';

import 'models.dart';
import 'text.dart';
import 'xtream.dart';

/// Personne au générique.
class CastMember {
  const CastMember(this.name, {this.role, this.photo});
  final String name;
  final String? role;
  final String? photo;
}

/// Fiche d'un film ou d'une série (fournisseur IPTV et/ou TMDB) — portage de MediaDetails (Mac).
class MediaDetails {
  String? title;
  String? originalTitle;
  int? year;
  String? plot;
  String? tagline;
  List<String> genres = [];
  List<String> directors = [];
  List<CastMember> cast = [];
  double? rating;
  int? runtime;
  int? seasonCount;
  String? trailer;
  String? poster;
  String? backdrop;
  String? tmdbId;
  List<String> sources = [];

  /// Complète cette fiche avec une autre, plus riche (TMDB).
  MediaDetails merged(MediaDetails better) {
    final r = MediaDetails()
      ..title = better.title ?? title
      ..originalTitle = better.originalTitle ?? originalTitle
      ..year = better.year ?? year
      ..plot = better.plot ?? plot
      ..tagline = better.tagline ?? tagline
      ..genres = better.genres.isNotEmpty ? better.genres : genres
      ..directors = better.directors.isNotEmpty ? better.directors : directors
      ..cast = better.cast.isNotEmpty ? better.cast : cast
      ..rating = better.rating ?? rating
      ..runtime = better.runtime ?? runtime
      ..seasonCount = better.seasonCount ?? seasonCount
      ..trailer = better.trailer ?? trailer
      ..poster = better.poster ?? poster
      ..backdrop = better.backdrop ?? backdrop
      ..tmdbId = better.tmdbId ?? tmdbId
      ..sources = [...sources, ...better.sources.where((s) => !sources.contains(s))];
    return r;
  }
}

/// Saison d'une série.
class SeriesSeason {
  SeriesSeason(this.number, this.episodes);
  final int number;
  final List<MediaItem> episodes;
}

int? yearIn(String? text) {
  if (text == null) return null;
  final m = RegExp(r'(19|20)\d{2}').firstMatch(text);
  return m == null ? null : int.parse(m.group(0)!);
}

List<String> _list(dynamic v) {
  final text = XtreamClient.str(v);
  if (text == null) return [];
  return text.split(RegExp(r'[,/|]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

MediaDetails _detailsFromInfo(Map info) {
  final s = XtreamClient.str;
  final d = MediaDetails()
    ..originalTitle = s(info['o_name'])
    ..plot = s(info['plot']) ?? s(info['description'])
    ..genres = _list(info['genre'])
    ..directors = _list(info['director'])
    ..cast = [for (final n in _list(info['cast'] ?? info['actors'])) CastMember(n)];
  final rating = double.tryParse((s(info['rating']) ?? '').replaceAll(',', '.'));
  if (rating != null && rating > 0) d.rating = rating > 10 ? 10 : rating;
  d.year = yearIn(s(info['releasedate']) ?? s(info['releaseDate']) ?? s(info['release_date']) ?? s(info['year']));
  final trailer = s(info['youtube_trailer']);
  if (trailer != null) {
    d.trailer = trailer.toLowerCase().startsWith('http') ? trailer : 'https://www.youtube.com/watch?v=$trailer';
  }
  final backdrops = info['backdrop_path'];
  d.backdrop = backdrops is List ? backdrops.map(XtreamClient.url).whereType<String>().firstOrNull : XtreamClient.url(backdrops);
  d.tmdbId = s(info['tmdb_id']) ?? s(info['tmdb']);
  if (d.tmdbId == '0') d.tmdbId = null;
  d.sources = ['IPTV'];
  return d;
}

/// Fiches et épisodes depuis l'API Xtream.
extension XtreamDetails on XtreamClient {
  Future<dynamic> _get(Uri url) async => jsonDecode(await httpGetText(url, timeout: const Duration(seconds: 20)));

  Future<MediaDetails> movieDetails(String streamId) async {
    final root = await _get(api('get_vod_info', {'vod_id': streamId}));
    if (root is! Map) throw XtreamException('Réponse du serveur illisible.');
    final info = root['info'] is Map ? root['info'] as Map : {};
    final movie = root['movie_data'] is Map ? root['movie_data'] as Map : {};
    final d = _detailsFromInfo(info)..title = XtreamClient.str(movie['name']) ?? XtreamClient.str(info['name']);
    final secs = int.tryParse(XtreamClient.str(info['duration_secs']) ?? '');
    if (secs != null && secs > 0) d.runtime = secs ~/ 60;
    d.poster = XtreamClient.url(info['movie_image']) ?? XtreamClient.url(info['cover_big']);
    return d;
  }

  /// Fiche et saisons d'une série (get_series_info).
  Future<(MediaDetails, List<SeriesSeason>)> seriesInfo(MediaItem series) async {
    final root = await _get(api('get_series_info', {'series_id': series.seriesId ?? ''}));
    if (root is! Map) throw XtreamException('Réponse du serveur illisible.');
    final info = root['info'] is Map ? root['info'] as Map : {};
    final d = _detailsFromInfo(info)
      ..title = XtreamClient.str(info['name'])
      ..poster = XtreamClient.url(info['cover']);
    final run = int.tryParse(XtreamClient.str(info['episode_run_time']) ?? '');
    if (run != null && run > 0) d.runtime = run;
    final bySeason = <int, List<MediaItem>>{};
    void add(Map e, int? hint) {
      final id = XtreamClient.str(e['id']);
      if (id == null) return;
      final season = int.tryParse(XtreamClient.str(e['season']) ?? '') ?? hint ?? 1;
      final number = int.tryParse(XtreamClient.str(e['episode_num']) ?? '');
      final details = e['info'] is Map ? e['info'] as Map : {};
      var title = XtreamClient.str(e['title']) ?? '';
      if (title.isEmpty) title = 'Épisode ${number ?? 0}';
      (bySeason[season] ??= []).add(MediaItem(
        id: '$sourceId:episode:$id',
        sourceId: sourceId,
        kind: MediaKind.episode,
        name: title,
        group: series.name,
        logo: XtreamClient.url(details['movie_image']),
        stream: streamUrl('series', id, XtreamClient.str(e['container_extension']) ?? 'mp4'),
        number: number,
        info: XtreamClient.str(details['plot']),
      ));
    }

    final episodes = root['episodes'];
    if (episodes is Map) {
      episodes.forEach((key, value) {
        if (value is List) {
          for (final e in value.whereType<Map>()) {
            add(e, int.tryParse('$key'));
          }
        }
      });
    } else if (episodes is List) {
      for (var i = 0; i < episodes.length; i++) {
        final v = episodes[i];
        if (v is List) {
          for (final e in v.whereType<Map>()) {
            add(e, i + 1);
          }
        } else if (v is Map) {
          add(v, null);
        }
      }
    }
    final seasons = [
      for (final n in bySeason.keys.toList()..sort())
        SeriesSeason(n, bySeason[n]!..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0))),
    ];
    if (seasons.isNotEmpty) d.seasonCount = seasons.length;
    return (d, seasons);
  }
}

/// Client TMDB (clé v3 ou jeton de lecture v4) — portage de TMDBClient (Mac).
class TMDBClient {
  TMDBClient(String key, this.language) : apiKey = key.trim();
  final String apiKey;
  final String language;
  static const _images = 'https://image.tmdb.org/t/p/';

  bool get _bearer => apiKey.startsWith('eyJ');

  Future<dynamic> _request(String path, [Map<String, String> query = const {}]) async {
    final url = Uri.https('api.themoviedb.org', '/3/$path', {
      ...query,
      'language': language,
      if (!_bearer) 'api_key': apiKey,
    });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptLanguageHeader, acceptLanguage);
      if (_bearer) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      final response = await request.close().timeout(const Duration(seconds: 20));
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw XtreamException('TMDB : code HTTP ${response.statusCode}');
      }
      return jsonDecode(text);
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> check() async {
    try {
      await _request('configuration');
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _search(dynamic root, int? year, bool series) {
    if (root is! Map || root['results'] is! List) return null;
    final results = (root['results'] as List).whereType<Map>().toList();
    if (results.isEmpty) return null;
    if (year != null) {
      final key = series ? 'first_air_date' : 'release_date';
      for (final r in results) {
        if (yearIn(XtreamClient.str(r[key])) == year) return XtreamClient.str(r['id']);
      }
    }
    return XtreamClient.str(results.first['id']);
  }

  Future<MediaDetails?> details(String title, {required bool series, String? tmdbId, int? year, String? originalTitle}) async {
    final kind = series ? 'tv' : 'movie';
    var id = tmdbId;
    // Titre original du fournisseur : second essai si le titre affiché n'est pas trouvé.
    if (id == null && originalTitle != null && originalTitle != title) {
      id = await _findId(title, series: series, year: year) ?? await _findId(originalTitle, series: series, year: year);
    }
    if (id == null) {
      final cleaned = cleanTitle(title);
      final wanted = year ?? cleaned.year;
      id = _search(
          await _request('search/$kind', {
            'query': cleaned.title,
            if (wanted != null) (series ? 'first_air_date_year' : 'year'): '$wanted',
          }),
          wanted,
          series);
      if (id == null && wanted != null) {
        id = _search(await _request('search/$kind', {'query': cleaned.title}), null, series);
      }
    }
    if (id == null) return null;
    final root = await _request('$kind/$id', {
      'append_to_response': 'credits,videos',
      'include_video_language': '${language.substring(0, 2)},en,null',
    });
    if (root is! Map) return null;
    final s = XtreamClient.str;
    final d = MediaDetails()
      ..tmdbId = s(root['id'])
      ..title = s(root[series ? 'name' : 'title'])
      ..originalTitle = s(root[series ? 'original_name' : 'original_title'])
      ..plot = s(root['overview'])
      ..tagline = s(root['tagline'])
      ..year = yearIn(s(root[series ? 'first_air_date' : 'release_date']))
      ..genres = [for (final g in (root['genres'] as List? ?? const []).whereType<Map>()) ?s(g['name'])];
    final vote = root['vote_average'];
    if (vote is num && vote > 0) d.rating = vote.toDouble();
    if (series) {
      final runs = root['episode_run_time'];
      if (runs is List && runs.isNotEmpty && runs.first is int) d.runtime = runs.first as int;
      if (root['number_of_seasons'] is int) d.seasonCount = root['number_of_seasons'] as int;
      d.directors = [for (final c in (root['created_by'] as List? ?? const []).whereType<Map>()) ?s(c['name'])];
    } else if (root['runtime'] is int && (root['runtime'] as int) > 0) {
      d.runtime = root['runtime'] as int;
    }
    final poster = s(root['poster_path']);
    if (poster != null) d.poster = '${_images}w500$poster';
    final backdrop = s(root['backdrop_path']);
    if (backdrop != null) d.backdrop = '${_images}w1280$backdrop';
    final credits = root['credits'];
    if (credits is Map) {
      d.cast = [
        for (final p in (credits['cast'] as List? ?? const []).whereType<Map>().take(15))
          if (s(p['name']) case final name?)
            CastMember(name, role: s(p['character']), photo: s(p['profile_path']) == null ? null : '${_images}w185${s(p['profile_path'])}'),
      ];
      if (!series) {
        d.directors = [
          for (final c in (credits['crew'] as List? ?? const []).whereType<Map>())
            if (s(c['job']) == 'Director') ?s(c['name']),
        ];
      }
    }
    final videos = root['videos'];
    if (videos is Map && videos['results'] is List) {
      final youtube = (videos['results'] as List).whereType<Map>().where((v) => s(v['site']) == 'YouTube').toList();
      final trailer = youtube.where((v) => s(v['type']) == 'Trailer').firstOrNull ?? youtube.firstOrNull;
      final key = trailer == null ? null : s(trailer['key']);
      if (key != null) d.trailer = 'https://www.youtube.com/watch?v=$key';
    }
    d.sources = ['TMDB'];
    return d;
  }

  Future<String?> _findId(String title, {required bool series, int? year}) async {
    final kind = series ? 'tv' : 'movie';
    final cleaned = cleanTitle(title);
    final wanted = year ?? cleaned.year;
    return _search(
        await _request('search/$kind', {
          'query': cleaned.title,
          if (wanted != null) (series ? 'first_air_date_year' : 'year'): '$wanted',
        }),
        wanted,
        series);
  }

  /// Résultats d'une recherche (fichiers locaux : affiche automatique, ou correction à la main).
  Future<List<TMDBMatch>> search(String title, {required bool series, int? year}) async {
    final kind = series ? 'tv' : 'movie';
    final cleaned = cleanTitle(title);
    final wanted = year ?? cleaned.year;
    var root = await _request('search/$kind', {
      'query': cleaned.title,
      if (wanted != null) (series ? 'first_air_date_year' : 'year'): '$wanted',
    });
    var results = root is Map && root['results'] is List ? (root['results'] as List).whereType<Map>().toList() : <Map>[];
    if (results.isEmpty && wanted != null) {
      root = await _request('search/$kind', {'query': cleaned.title});
      results = root is Map && root['results'] is List ? (root['results'] as List).whereType<Map>().toList() : <Map>[];
    }
    final s = XtreamClient.str;
    return [
      for (final r in results.take(12))
        if (s(r['id']) case final id?)
          TMDBMatch(
            id,
            s(r[series ? 'name' : 'title']) ?? cleaned.title,
            year: yearIn(s(r[series ? 'first_air_date' : 'release_date'])),
            poster: s(r['poster_path']) == null ? null : '${_images}w342${s(r['poster_path'])}',
            overview: s(r['overview']),
            genres: tmdbGenreNames(r['genre_ids'] as List? ?? const [], english: !language.startsWith('fr')),
          ),
    ];
  }

  /// Épisodes d'une saison (titre, résumé, image) dans la langue choisie.
  Future<Map<int, TMDBEpisode>> season(String tvId, int number) async {
    final root = await _request('tv/$tvId/season/$number');
    final result = <int, TMDBEpisode>{};
    if (root is! Map || root['episodes'] is! List) return result;
    final s = XtreamClient.str;
    for (final e in (root['episodes'] as List).whereType<Map>()) {
      final n = int.tryParse(s(e['episode_number']) ?? '');
      if (n == null) continue;
      final still = s(e['still_path']);
      result[n] = TMDBEpisode(s(e['name']), s(e['overview']), still == null ? null : '${_images}w300$still');
    }
    return result;
  }

  /// Tendances de la semaine (`/trending/{movie|tv}/week`, deux pages).
  Future<List<TMDBTrend>> trending({required bool series}) async {
    final all = <TMDBTrend>[];
    final s = XtreamClient.str;
    for (final page in [1, 2]) {
      final root = await _request('trending/${series ? 'tv' : 'movie'}/week', {'page': '$page'});
      if (root is! Map || root['results'] is! List) continue;
      for (final e in (root['results'] as List).whereType<Map>()) {
        final id = s(e['id']);
        final title = s(e[series ? 'name' : 'title']);
        if (id == null || title == null) continue;
        final backdrop = s(e['backdrop_path']);
        all.add(TMDBTrend(id, title,
            originalTitle: s(e[series ? 'original_name' : 'original_title']),
            year: yearIn(s(e[series ? 'first_air_date' : 'release_date'])),
            backdrop: backdrop == null ? null : '${_images}w1280$backdrop'));
      }
    }
    return all;
  }
}

/// Film ou série en tendance sur TMDB.
class TMDBTrend {
  TMDBTrend(this.tmdbId, this.title, {this.originalTitle, this.year, this.backdrop});
  final String tmdbId;
  final String title;
  final String? originalTitle;
  final int? year;
  final String? backdrop;
}

/// Résultat d'une recherche TMDB.
class TMDBMatch {
  TMDBMatch(this.tmdbId, this.title, {this.year, this.poster, this.overview, this.genres = const []});
  final String tmdbId;
  final String title;
  final int? year;
  final String? poster;
  final String? overview;
  final List<String> genres;
}

/// Noms des genres TMDB (identifiants fixes de l'API), pour les filtres de la vidéothèque.
List<String> tmdbGenreNames(Iterable<dynamic> ids, {required bool english}) {
  const fr = {
    28: 'Action', 12: 'Aventure', 16: 'Animation', 35: 'Comédie', 80: 'Crime', 99: 'Documentaire', 18: 'Drame',
    10751: 'Familial', 14: 'Fantastique', 36: 'Histoire', 27: 'Horreur', 10402: 'Musique', 9648: 'Mystère',
    10749: 'Romance', 878: 'Science-Fiction', 10770: 'Téléfilm', 53: 'Thriller', 10752: 'Guerre', 37: 'Western',
    10759: 'Action & Aventure', 10762: 'Enfants', 10763: 'Information', 10764: 'Téléréalité',
    10765: 'Science-Fiction & Fantastique', 10766: 'Feuilleton', 10767: 'Talk-show', 10768: 'Guerre & Politique',
  };
  const en = {
    28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy', 80: 'Crime', 99: 'Documentary', 18: 'Drama',
    10751: 'Family', 14: 'Fantasy', 36: 'History', 27: 'Horror', 10402: 'Music', 9648: 'Mystery',
    10749: 'Romance', 878: 'Science Fiction', 10770: 'TV Movie', 53: 'Thriller', 10752: 'War', 37: 'Western',
    10759: 'Action & Adventure', 10762: 'Kids', 10763: 'News', 10764: 'Reality',
    10765: 'Sci-Fi & Fantasy', 10766: 'Soap', 10767: 'Talk', 10768: 'War & Politics',
  };
  final names = english ? en : fr;
  return [for (final id in ids) ?names[id is int ? id : int.tryParse('$id')]];
}

/// Épisode d'une série sur TMDB.
class TMDBEpisode {
  TMDBEpisode(this.name, this.overview, this.still);
  final String? name;
  final String? overview;
  final String? still;
}
