import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'details.dart';
import 'log.dart';
import 'models.dart';

/// Événement de lecture transmis au serveur (reprise et « vu » partagés avec ses autres appareils).
enum PlaybackEvent { start, progress, pause, stop }

/// Identité de Kastideo auprès des serveurs (même appareil d'un lancement à l'autre).
class KastideoDevice {
  KastideoDevice._();
  static String version = '1.5.0';

  /// Nom de l'ordinateur, réduit aux caractères ASCII : un accent ou une apostrophe typographique dans un en-tête HTTP
  /// fait répondre « 400 Bad Request » à certains serveurs.
  static String get name {
    String raw;
    try {
      raw = Platform.localHostname;
    } catch (_) {
      raw = 'Kastideo';
    }
    return asciiOnly(raw);
  }

  static String asciiOnly(String text) {
    const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿÀÂÄÁÃÅÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜÝ’‘';
    const to = 'aaaaaaceeeeiiiinooooouuuuyyAAAAAACEEEEIIIINOOOOOUUUUY\'\'';
    final b = StringBuffer();
    for (final ch in text.split('')) {
      final i = from.indexOf(ch);
      final c = i >= 0 ? to[i] : ch;
      final code = c.codeUnitAt(0);
      if (code >= 32 && code < 127 && c != '"') b.write(c);
    }
    final out = b.toString().trim();
    return out.isEmpty ? 'Kastideo' : out;
  }

  /// Identifiant stable de l'appareil (empreinte FNV-1a du nom de l'ordinateur et du système).
  static String get id {
    var h = 0x811c9dc5;
    for (final c in utf8.encode(name + Platform.operatingSystem)) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return 'kastideo-${h.toRadixString(16)}';
  }

  static String get platform => Platform.isWindows ? 'Windows' : (Platform.isMacOS ? 'macOS' : 'Linux');
}

class MediaServerException implements Exception {
  MediaServerException(this.message, {this.detail, this.status});
  final String message;

  /// Réponse exacte du serveur (diagnostic de connexion).
  final String? detail;
  final int? status;
  @override
  String toString() => message;
}

/// Session ouverte sur un serveur (jeton, et pour Jellyfin / Emby l'identifiant de l'utilisateur).
class ServerSession {
  ServerSession(this.token, {this.userId});
  final String token;
  final String? userId;

  String encode() => jsonEncode({'token': token, 'user': ?userId});

  static ServerSession? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map;
      final token = j['token'] as String?;
      return token == null ? null : ServerSession(token, userId: j['user'] as String?);
    } catch (_) {
      // Jeton Plex saisi tel quel.
      return ServerSession(raw);
    }
  }
}

/// Serveur multimédia (Jellyfin, Emby, Plex) : bibliothèques, épisodes, fiches, lecture directe et état « vu ».
abstract class MediaServerClient {
  MediaServerClient(this.server, this.sourceId);

  /// Adresse du serveur, sans « / » final (ex. http://192.168.1.10:8096).
  final String server;
  final String sourceId;

  /// Nom de la source, ajouté aux rubriques (« Films · Salon ») pour les distinguer de celles des autres sources.
  String label = '';

  /// Nom de la rubrique des vidéos personnelles (« Vidéos »), dans la langue de l'interface.
  String videosLabel = 'Vidéos';
  String groupName(String library) => label.isEmpty ? library : '$library · $label';

  Future<SourceContent> fetchLibrary();
  Future<List<SeriesSeason>> seasons(MediaItem series);
  Future<MediaDetails?> details(MediaItem item);
  Future<void> report(MediaItem item, double position, double duration, PlaybackEvent event);
  Future<void> setPlayed(MediaItem item, bool played);

  /// Identifiant du contenu chez le serveur (dernière partie de l'identifiant Kastideo).
  static String serverId(MediaItem item) => item.id.split(':').last;

  /// Adresse complète. Sans « http:// » ni port, le port habituel est ajouté (Plex 32400, Jellyfin / Emby 8096).
  static String normalize(String address, {int? defaultPort}) {
    var a = address.trim();
    if (a.isEmpty) throw MediaServerException('Adresse du serveur manquante.');
    // Adresse copiée depuis le navigateur (« …:8096/web/index.html#!/home ») : seule la racine du serveur compte.
    final cut = RegExp(r'[#?]').firstMatch(a);
    if (cut != null) a = a.substring(0, cut.start);
    final web = RegExp(r'/(web|emby/web)(/.*)?$', caseSensitive: false).firstMatch(a);
    if (web != null) a = a.substring(0, web.start);
    if (!a.contains('://')) {
      a = 'http://$a';
      final bare = Uri.tryParse(a);
      if (defaultPort != null && bare != null && bare.host.isNotEmpty && !bare.hasPort) {
        a = bare.replace(port: defaultPort).toString();
      }
    }
    while (a.endsWith('/')) {
      a = a.substring(0, a.length - 1);
    }
    final uri = Uri.tryParse(a);
    if (uri == null || uri.host.isEmpty) throw MediaServerException('Adresse du serveur invalide.');
    return a;
  }

  static String normalizeFor(SourceKind kind, String address) => normalize(address, defaultPort: kind == SourceKind.plex ? 32400 : 8096);

  Future<dynamic> requestJson(
    String method,
    Uri url, {
    Map<String, String> headers = const {},
    Object? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.openUrl(method, url);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      headers.forEach(request.headers.set);
      if (body != null) {
        // Longueur annoncée (pas d'envoi par morceaux, que certains serveurs refusent).
        final bytes = utf8.encode(jsonEncode(body));
        request.headers.contentType = ContentType.json;
        request.contentLength = bytes.length;
        request.add(bytes);
      }
      final response = await request.close().timeout(timeout);
      final text = await response.transform(utf8.decoder).join().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Diagnostic : requête (sans jeton) et réponse exacte du serveur dans le journal.
        final shown = url.replace(queryParameters: url.queryParameters.isEmpty
            ? null
            : {for (final e in url.queryParameters.entries) e.key: RegExp('token|api_key', caseSensitive: false).hasMatch(e.key) ? '…' : e.value});
        final reply = text.trim().replaceAll(RegExp(r'\s+'), ' ');
        final detail = '$method $shown → HTTP ${response.statusCode}${reply.isEmpty ? '' : ' : ${reply.length > 400 ? '${reply.substring(0, 400)}…' : reply}'}';
        PlaybackLog.shared.note('Serveur : $detail');
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw MediaServerException('Accès refusé par le serveur (HTTP ${response.statusCode}) : vérifiez l\'identifiant, le mot de passe ou le jeton.',
              detail: detail, status: response.statusCode);
        }
        throw MediaServerException(
            'Le serveur a répondu HTTP ${response.statusCode}${reply.isEmpty ? '.' : ' : ${reply.length > 160 ? '${reply.substring(0, 160)}…' : reply}'}',
            detail: detail,
            status: response.statusCode);
      }
      if (text.trim().isEmpty) return null;
      try {
        return jsonDecode(text);
      } catch (_) {
        return text;
      }
    } on SocketException catch (e) {
      throw MediaServerException('Serveur injoignable (${e.osError?.message ?? e.message}). Vérifiez l\'adresse et que le serveur est allumé.');
    } on TimeoutException {
      throw MediaServerException('Le serveur ne répond pas.');
    } finally {
      client.close(force: true);
    }
  }

  static String? str(dynamic v) => v == null ? null : (v is String ? (v.isEmpty ? null : v) : '$v');
  static int? integer(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));
}

// MARK: Jellyfin et Emby (même interface de programmation)

class JellyfinClient extends MediaServerClient {
  JellyfinClient(super.server, super.sourceId, {required this.session, this.emby = false});

  final ServerSession session;
  final bool emby;

  String get _token => session.token;
  String get _user => session.userId ?? '';

  static String authHeader({String? token, String scheme = 'MediaBrowser'}) =>
      '$scheme Client="Kastideo", Device="${KastideoDevice.name}", DeviceId="${KastideoDevice.id}", '
      'Version="${KastideoDevice.version}"${token == null ? '' : ', Token="$token"'}';

  static Map<String, String> headers({String? token, bool emby = false}) => {
    'Authorization': authHeader(token: token),
    'X-Emby-Authorization': authHeader(token: token, scheme: emby ? 'Emby' : 'MediaBrowser'),
    'X-Emby-Token': ?token,
    'X-MediaBrowser-Token': ?token,
  };

  /// Identification de l'appareil en paramètres d'adresse (forme attendue par Emby).
  static Map<String, String> embyQuery() => {
    'X-Emby-Client': 'Kastideo',
    'X-Emby-Device-Name': KastideoDevice.name,
    'X-Emby-Device-Id': KastideoDevice.id,
    'X-Emby-Client-Version': KastideoDevice.version,
  };

  /// Connexion avec un identifiant et un mot de passe (vide si l'utilisateur n'en a pas ; une clé d'API peut le remplacer :
  /// voir [withApiKey]).
  static Future<ServerSession> signIn(String server, String username, String password, {bool emby = false}) async {
    final probe = JellyfinClient(server, '', session: ServerSession(''));
    dynamic root;
    if (emby) {
      // Emby : identification en paramètres et en-tête « Emby », corps réduit à Username / Pw ; certains serveurs
      // ne répondent qu'avec le préfixe /emby.
      MediaServerException? last;
      for (final prefix in ['', '/emby']) {
        try {
          root = await probe.requestJson('POST', Uri.parse('$server$prefix/Users/AuthenticateByName').replace(queryParameters: embyQuery()),
              headers: headers(emby: true), body: {'Username': username, 'Pw': password});
          last = null;
          break;
        } on MediaServerException catch (e) {
          last = e;
          if (e.status != 400 && e.status != 404) rethrow;
        }
      }
      if (last != null) throw last;
    } else {
      root = await probe.requestJson(
        'POST',
        Uri.parse('$server/Users/AuthenticateByName'),
        headers: headers(),
        body: {'Username': username, 'Pw': password},
      );
    }
    if (root is! Map || root['AccessToken'] == null) throw MediaServerException('Réponse du serveur illisible.');
    final user = root['User'] is Map ? (root['User'] as Map)['Id'] as String? : null;
    return ServerSession(root['AccessToken'] as String, userId: user);
  }

  /// Clé d'API (Tableau de bord > Clés API) : l'utilisateur est retrouvé par son nom.
  static Future<ServerSession> withApiKey(String server, String apiKey, String username) async {
    final probe = JellyfinClient(server, '', session: ServerSession(apiKey));
    final users = await probe.requestJson('GET', Uri.parse('$server/Users'), headers: headers(token: apiKey));
    if (users is! List || users.isEmpty) throw MediaServerException('Aucun utilisateur sur ce serveur.');
    final match =
        users.whereType<Map>().where((u) => (u['Name'] as String? ?? '').toLowerCase() == username.trim().toLowerCase()).firstOrNull ??
        users.whereType<Map>().first;
    return ServerSession(apiKey, userId: match['Id'] as String?);
  }

  /// Nom et version du serveur (sans connexion), pour vérifier l'adresse.
  static Future<String?> publicInfo(String server) async {
    final probe = JellyfinClient(server, '', session: ServerSession(''));
    final root = await probe.requestJson('GET', Uri.parse('$server/System/Info/Public'), timeout: const Duration(seconds: 8));
    if (root is! Map) return null;
    return '${root['ServerName'] ?? ''} (${root['ProductName'] ?? (root['Id'] != null ? 'Jellyfin/Emby' : '')} ${root['Version'] ?? ''})'.trim();
  }

  Future<dynamic> _get(String path, [Map<String, String> query = const {}]) => requestJson(
    'GET',
    Uri.parse('$server$path').replace(queryParameters: query.isEmpty ? null : query),
    headers: headers(token: _token, emby: emby),
  );

  String image(String id, {String type = 'Primary', int height = 450, String? tag}) =>
      '$server/Items/$id/Images/$type?maxHeight=$height&quality=85${tag != null ? '&tag=$tag' : ''}';

  String stream(String id) => '$server/Videos/$id/stream?static=true&MediaSourceId=$id&api_key=$_token';

  static const _fields = 'Overview,Genres,ProductionYear,DateCreated,RunTimeTicks,CommunityRating,UserData,PremiereDate';

  @override
  Future<SourceContent> fetchLibrary() async {
    final views = await _get('/Users/$_user/Views');
    final list = views is Map ? (views['Items'] as List? ?? const []) : const [];
    final items = <MediaItem>[];
    final progress = <String, (double, double)>{};
    for (final v in list.whereType<Map>()) {
      final type = (v['CollectionType'] as String? ?? 'mixed').toLowerCase();
      // Musique, livres, photos, direct, listes de lecture… ne sont pas des films ou des séries.
      if (!const {'movies', 'tvshows', 'homevideos', 'mixed', 'folders', ''}.contains(type)) continue;
      final viewId = v['Id'] as String?;
      final viewName = v['Name'] as String? ?? 'Bibliothèque';
      if (viewId == null) continue;
      final root = await _get('/Users/$_user/Items', {
        'ParentId': viewId,
        'Recursive': 'true',
        'IncludeItemTypes': 'Movie,Series,Video',
        'Fields': _fields,
        'ImageTypeLimit': '1',
        'EnableImageTypes': 'Primary,Backdrop',
        'SortBy': 'SortName',
      });
      final entries = root is Map ? (root['Items'] as List? ?? const []) : const [];
      for (final e in entries.whereType<Map>()) {
        final id = e['Id'] as String?;
        if (id == null) continue;
        final series = e['Type'] == 'Series';
        final year = MediaServerClient.integer(e['ProductionYear']);
        final name = e['Name'] as String? ?? '?';
        final tags = e['ImageTags'] is Map ? e['ImageTags'] as Map : const {};
        final item = MediaItem(
          id: '$sourceId:${series ? 'series' : 'movie'}:$id',
          sourceId: sourceId,
          kind: series ? MediaKind.series : MediaKind.movie,
          name: year != null && !series ? '$name ($year)' : name,
          // Vidéos personnelles (bibliothèque « Vidéos personnelles », éléments de type Video) : rubrique « Vidéos ».
          group: e['Type'] == 'Video' || type == 'homevideos' ? groupName(videosLabel) : groupName(viewName),
          logo: tags['Primary'] != null ? image(id, tag: tags['Primary'] as String) : null,
          stream: series ? null : stream(id),
          seriesId: series ? id : null,
          info: e['Overview'] as String?,
          added: DateTime.tryParse(e['DateCreated'] as String? ?? ''),
          year: year,
          genres: [for (final g in (e['Genres'] as List? ?? const [])) '$g'],
        );
        items.add(item);
        _userData(item.id, e, progress);
      }
    }
    return SourceContent(items, progress: progress);
  }

  static void _userData(String id, Map e, Map<String, (double, double)> progress) {
    final data = e['UserData'] is Map ? e['UserData'] as Map : const {};
    final ticks = MediaServerClient.integer(e['RunTimeTicks']) ?? 0;
    final duration = ticks / 1e7;
    if (duration <= 0) return;
    if (data['Played'] == true) {
      progress[id] = (duration, duration);
    } else {
      final pos = (MediaServerClient.integer(data['PlaybackPositionTicks']) ?? 0) / 1e7;
      if (pos > 0) progress[id] = (pos, duration);
    }
  }

  /// Épisodes d'une série, avec leur position de lecture.
  Future<(List<SeriesSeason>, Map<String, (double, double)>)> episodes(MediaItem series) async {
    final root = await _get('/Shows/${series.seriesId ?? MediaServerClient.serverId(series)}/Episodes', {'UserId': _user, 'Fields': _fields});
    final list = root is Map ? (root['Items'] as List? ?? const []) : const [];
    final bySeason = <int, List<MediaItem>>{};
    final progress = <String, (double, double)>{};
    for (final e in list.whereType<Map>()) {
      final id = e['Id'] as String?;
      if (id == null) continue;
      final season = MediaServerClient.integer(e['ParentIndexNumber']) ?? 1;
      final number = MediaServerClient.integer(e['IndexNumber']);
      final tags = e['ImageTags'] is Map ? e['ImageTags'] as Map : const {};
      final item = MediaItem(
        id: '$sourceId:episode:$id',
        sourceId: sourceId,
        kind: MediaKind.episode,
        name: e['Name'] as String? ?? 'Épisode ${number ?? ''}',
        group: series.name,
        logo: tags['Primary'] != null ? image(id, height: 240, tag: tags['Primary'] as String) : null,
        stream: stream(id),
        seriesId: series.seriesId,
        number: number,
        season: season,
        info: e['Overview'] as String?,
      );
      (bySeason[season] ??= []).add(item);
      _userData(item.id, e, progress);
    }
    final seasons = [for (final s in (bySeason.keys.toList()..sort())) SeriesSeason(s, bySeason[s]!..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0)))];
    return (seasons, progress);
  }

  @override
  Future<List<SeriesSeason>> seasons(MediaItem series) async => (await episodes(series)).$1;

  @override
  Future<MediaDetails?> details(MediaItem item) async {
    final root = await _get('/Users/$_user/Items/${MediaServerClient.serverId(item)}');
    if (root is! Map) return null;
    final d = MediaDetails()
      ..title = root['Name'] as String?
      ..originalTitle = root['OriginalTitle'] as String?
      ..year = MediaServerClient.integer(root['ProductionYear'])
      ..plot = root['Overview'] as String?
      ..genres = [for (final g in (root['Genres'] as List? ?? const [])) '$g']
      ..rating = (root['CommunityRating'] as num?)?.toDouble()
      ..runtime = ((MediaServerClient.integer(root['RunTimeTicks']) ?? 0) / 6e8).round()
      ..sources = [emby ? 'Emby' : 'Jellyfin'];
    if (d.runtime == 0) d.runtime = null;
    final id = MediaServerClient.serverId(item);
    if (root['ImageTags'] is Map && (root['ImageTags'] as Map)['Primary'] != null) d.poster = image(id);
    if ((root['BackdropImageTags'] as List?)?.isNotEmpty ?? false) d.backdrop = image(id, type: 'Backdrop', height: 1080);
    for (final p in (root['People'] as List? ?? const []).whereType<Map>()) {
      final name = p['Name'] as String?;
      if (name == null) continue;
      if (p['Type'] == 'Director') {
        d.directors.add(name);
      } else if (p['Type'] == 'Actor' && d.cast.length < 20) {
        final pid = p['Id'] as String?;
        d.cast.add(CastMember(name, role: p['Role'] as String?, photo: pid != null && p['PrimaryImageTag'] != null ? image(pid, height: 300) : null));
      }
    }
    final providers = root['ProviderIds'] is Map ? root['ProviderIds'] as Map : const {};
    d.tmdbId = MediaServerClient.str(providers['Tmdb']);
    return d;
  }

  @override
  Future<void> report(MediaItem item, double position, double duration, PlaybackEvent event) async {
    final path = switch (event) {
      PlaybackEvent.start => '/Sessions/Playing',
      PlaybackEvent.progress || PlaybackEvent.pause => '/Sessions/Playing/Progress',
      PlaybackEvent.stop => '/Sessions/Playing/Stopped',
    };
    await requestJson(
      'POST',
      Uri.parse('$server$path'),
      headers: headers(token: _token, emby: emby),
      body: {
        'ItemId': MediaServerClient.serverId(item),
        'PositionTicks': (position * 1e7).round(),
        'IsPaused': event == PlaybackEvent.pause,
        'CanSeek': true,
        'PlayMethod': 'DirectStream',
      },
    );
  }

  @override
  Future<void> setPlayed(MediaItem item, bool played) => requestJson(
    played ? 'POST' : 'DELETE',
    Uri.parse('$server/Users/$_user/PlayedItems/${MediaServerClient.serverId(item)}'),
    headers: headers(token: _token, emby: emby),
  );
}

// MARK: Plex

class PlexClient extends MediaServerClient {
  PlexClient(super.server, super.sourceId, {required this.token});
  final String token;
  String get _tokenParam => token.isEmpty ? '' : '&X-Plex-Token=$token';

  static Map<String, String> headers({String? token}) => {
    'X-Plex-Product': 'Kastideo',
    'X-Plex-Version': KastideoDevice.version,
    'X-Plex-Client-Identifier': KastideoDevice.id,
    'X-Plex-Device-Name': KastideoDevice.name,
    'X-Plex-Platform': KastideoDevice.platform,
    if (token != null && token.isNotEmpty) 'X-Plex-Token': token,
  };

  /// Connexion par code (plex.tv/link) : [PlexPin.url] s'ouvre dans le navigateur, puis [PlexPin.poll] rend le jeton.
  static Future<PlexPin> createPin() async {
    final probe = PlexClient('https://plex.tv', '', token: '');
    final root = await probe.requestJson('POST', Uri.parse('https://plex.tv/api/v2/pins?strong=true'), headers: headers());
    if (root is! Map || root['id'] == null) throw MediaServerException('plex.tv n\'a pas répondu.');
    return PlexPin(MediaServerClient.integer(root['id'])!, root['code'] as String);
  }

  /// Serveurs du compte Plex (adresse locale d'abord) : (nom, adresses, jeton du serveur).
  static Future<List<(String, List<String>, String)>> accountServers(String token) async {
    final probe = PlexClient('https://plex.tv', '', token: token);
    final root = await probe.requestJson('GET', Uri.parse('https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=0'), headers: headers(token: token));
    final result = <(String, List<String>, String)>[];
    for (final r in (root is List ? root : const []).whereType<Map>()) {
      if (!('${r['provides'] ?? ''}').contains('server')) continue;
      final connections = (r['connections'] as List? ?? const []).whereType<Map>().toList()
        ..sort((a, b) => (b['local'] == true ? 1 : 0).compareTo(a['local'] == true ? 1 : 0));
      result.add((r['name'] as String? ?? 'Plex', [for (final c in connections) c['uri'] as String], r['accessToken'] as String? ?? token));
    }
    return result;
  }

  /// Nom du serveur (vérifie l'adresse et le jeton).
  Future<String?> identity() async {
    final root = await _get('/');
    final c = root is Map ? root['MediaContainer'] as Map? : null;
    return c?['friendlyName'] as String?;
  }

  Future<dynamic> _get(String path, [Map<String, String> query = const {}]) => requestJson(
    'GET',
    Uri.parse('$server$path').replace(queryParameters: {...query, if (token.isNotEmpty) 'X-Plex-Token': token}),
    headers: headers(token: token),
  );

  String _image(String? thumb, {int width = 300, int height = 450}) => thumb == null
      ? ''
      : '$server/photo/:/transcode?width=$width&height=$height&minSize=1&upscale=1&url=${Uri.encodeQueryComponent(thumb)}$_tokenParam';

  String? _stream(Map m) {
    final media = (m['Media'] as List? ?? const []).whereType<Map>().firstOrNull;
    final part = (media?['Part'] as List? ?? const []).whereType<Map>().firstOrNull;
    final key = part?['key'] as String?;
    return key == null ? null : '$server$key${token.isEmpty ? '' : '?X-Plex-Token=$token'}';
  }

  static List<Map> _metadata(dynamic root) {
    final c = root is Map ? root['MediaContainer'] : null;
    return c is Map ? (c['Metadata'] as List? ?? const []).whereType<Map>().toList() : const [];
  }

  static void _userData(String id, Map m, Map<String, (double, double)> progress) {
    final duration = (MediaServerClient.integer(m['duration']) ?? 0) / 1000;
    if (duration <= 0) return;
    if ((MediaServerClient.integer(m['viewCount']) ?? 0) > 0 && m['viewOffset'] == null) {
      progress[id] = (duration, duration);
    } else {
      final pos = (MediaServerClient.integer(m['viewOffset']) ?? 0) / 1000;
      if (pos > 0) progress[id] = (pos, duration);
    }
  }

  @override
  Future<SourceContent> fetchLibrary() async {
    final sections = await _get('/library/sections');
    final c = sections is Map ? sections['MediaContainer'] as Map? : null;
    final items = <MediaItem>[];
    final progress = <String, (double, double)>{};
    for (final d in (c?['Directory'] as List? ?? const []).whereType<Map>()) {
      final type = d['type'] as String?;
      if (type != 'movie' && type != 'show') continue;
      final key = d['key'];
      final title = d['title'] as String? ?? 'Plex';
      for (final m in _metadata(await _get('/library/sections/$key/all'))) {
        final id = MediaServerClient.str(m['ratingKey']);
        if (id == null) continue;
        final show = type == 'show';
        final year = MediaServerClient.integer(m['year']);
        final name = m['title'] as String? ?? '?';
        final added = MediaServerClient.integer(m['addedAt']);
        final item = MediaItem(
          id: '$sourceId:${show ? 'series' : 'movie'}:$id',
          sourceId: sourceId,
          kind: show ? MediaKind.series : MediaKind.movie,
          name: year != null && !show ? '$name ($year)' : name,
          group: groupName(title),
          logo: m['thumb'] != null ? _image(m['thumb'] as String) : null,
          stream: show ? null : _stream(m),
          seriesId: show ? id : null,
          info: m['summary'] as String?,
          added: added == null ? null : DateTime.fromMillisecondsSinceEpoch(added * 1000),
          year: year,
          genres: [for (final g in (m['Genre'] as List? ?? const []).whereType<Map>()) '${g['tag']}'],
        );
        items.add(item);
        _userData(item.id, m, progress);
      }
    }
    return SourceContent(items, progress: progress);
  }

  Future<(List<SeriesSeason>, Map<String, (double, double)>)> episodes(MediaItem series) async {
    final bySeason = <int, List<MediaItem>>{};
    final progress = <String, (double, double)>{};
    for (final m in _metadata(await _get('/library/metadata/${series.seriesId ?? MediaServerClient.serverId(series)}/allLeaves'))) {
      final id = MediaServerClient.str(m['ratingKey']);
      if (id == null) continue;
      final season = MediaServerClient.integer(m['parentIndex']) ?? 1;
      final number = MediaServerClient.integer(m['index']);
      final item = MediaItem(
        id: '$sourceId:episode:$id',
        sourceId: sourceId,
        kind: MediaKind.episode,
        name: m['title'] as String? ?? 'Épisode ${number ?? ''}',
        group: series.name,
        logo: m['thumb'] != null ? _image(m['thumb'] as String, width: 400, height: 225) : null,
        stream: _stream(m),
        seriesId: series.seriesId,
        number: number,
        season: season,
        info: m['summary'] as String?,
      );
      (bySeason[season] ??= []).add(item);
      _userData(item.id, m, progress);
    }
    final seasons = [for (final s in (bySeason.keys.toList()..sort())) SeriesSeason(s, bySeason[s]!..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0)))];
    return (seasons, progress);
  }

  @override
  Future<List<SeriesSeason>> seasons(MediaItem series) async => (await episodes(series)).$1;

  @override
  Future<MediaDetails?> details(MediaItem item) async {
    final m = _metadata(await _get('/library/metadata/${MediaServerClient.serverId(item)}')).firstOrNull;
    if (m == null) return null;
    List<String> tags(String key) => [for (final t in (m[key] as List? ?? const []).whereType<Map>()) '${t['tag']}'];
    final d = MediaDetails()
      ..title = m['title'] as String?
      ..originalTitle = m['originalTitle'] as String?
      ..year = MediaServerClient.integer(m['year'])
      ..plot = m['summary'] as String?
      ..tagline = m['tagline'] as String?
      ..genres = tags('Genre')
      ..directors = tags('Director')
      ..rating = (m['audienceRating'] as num? ?? m['rating'] as num?)?.toDouble()
      ..sources = ['Plex'];
    final duration = MediaServerClient.integer(m['duration']);
    if (duration != null && duration > 0) d.runtime = (duration / 60000).round();
    if (m['thumb'] != null) d.poster = _image(m['thumb'] as String);
    if (m['art'] != null) d.backdrop = _image(m['art'] as String, width: 1920, height: 1080);
    for (final r in (m['Role'] as List? ?? const []).whereType<Map>().take(20)) {
      d.cast.add(CastMember('${r['tag']}', role: r['role'] as String?, photo: r['thumb'] as String?));
    }
    for (final g in (m['Guid'] as List? ?? const []).whereType<Map>()) {
      final id = '${g['id'] ?? ''}';
      if (id.startsWith('tmdb://')) d.tmdbId = id.substring(7);
    }
    return d;
  }

  @override
  Future<void> report(MediaItem item, double position, double duration, PlaybackEvent event) async {
    final id = MediaServerClient.serverId(item);
    final state = switch (event) {
      PlaybackEvent.start || PlaybackEvent.progress => 'playing',
      PlaybackEvent.pause => 'paused',
      PlaybackEvent.stop => 'stopped',
    };
    await _get('/:/timeline', {
      'ratingKey': id,
      'key': '/library/metadata/$id',
      'state': state,
      'time': '${(position * 1000).round()}',
      'duration': '${(duration * 1000).round()}',
    });
  }

  @override
  Future<void> setPlayed(MediaItem item, bool played) =>
      _get(played ? '/:/scrobble' : '/:/unscrobble', {'identifier': 'com.plexapp.plugins.library', 'key': MediaServerClient.serverId(item)});
}

/// Code de connexion Plex (plex.tv/link).
class PlexPin {
  PlexPin(this.id, this.code);
  final int id;
  final String code;

  /// Page à ouvrir dans le navigateur pour autoriser Kastideo.
  String get url => 'https://app.plex.tv/auth#?clientID=${Uri.encodeComponent(KastideoDevice.id)}&code=$code&context%5Bdevice%5D%5Bproduct%5D=Kastideo';

  /// Jeton une fois la connexion acceptée (null tant qu'elle ne l'est pas).
  Future<String?> poll() async {
    final probe = PlexClient('https://plex.tv', '', token: '');
    final root = await probe.requestJson('GET', Uri.parse('https://plex.tv/api/v2/pins/$id'), headers: PlexClient.headers());
    return root is Map ? MediaServerClient.str(root['authToken']) : null;
  }
}
