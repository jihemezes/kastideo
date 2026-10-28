import 'dart:convert';
import 'dart:io';

import '../l10n.dart';

import 'models.dart';
import 'm3u.dart';
import 'replay.dart';

/// En-tête d'un lecteur reconnu : les plateformes IPTV refusent souvent un client inconnu (comme sur Mac et Piboard).
const String kUserAgent = 'VLC/3.0.20 LibVLC/3.0.20';

class XtreamException implements Exception {
  XtreamException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Téléchargement simple avec l'en-tête de lecteur VLC.
/// Langues acceptées envoyées aux serveurs (langue de l'interface d'abord).
String get acceptLanguage => L10n.english ? 'en-US,en;q=0.9,fr;q=0.5' : 'fr-FR,fr;q=0.9,en;q=0.8';

Future<String> httpGetText(Uri url, {Duration timeout = const Duration(seconds: 60)}) async {
  final client = HttpClient()
    ..userAgent = kUserAgent
    ..connectionTimeout = const Duration(seconds: 20);
  try {
    final request = await client.getUrl(url).timeout(timeout);
    request.headers.set(HttpHeaders.acceptHeader, '*/*');
    // Comme la version Mac (URLSession) : certains fournisseurs choisissent la langue des fiches d'après cet en-tête
    // et répondent sinon dans une langue par défaut (espagnol…).
    request.headers.set(HttpHeaders.acceptLanguageHeader, acceptLanguage);
    final response = await request.close().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw XtreamException('Le serveur a répondu avec le code HTTP ${response.statusCode}.');
    }
    return await response.transform(utf8.decoder).join().timeout(const Duration(minutes: 10));
  } on SocketException catch (e) {
    throw XtreamException('Serveur injoignable : ${e.message}');
  } finally {
    client.close(force: true);
  }
}

/// Identifiants Xtream Codes.
class XtreamCredentials {
  XtreamCredentials(this.server, this.username, this.password);
  final Uri server;
  final String username;
  final String password;

  /// Ajoute http:// si besoin, retire /player_api.php, /get.php et la barre finale.
  static Uri? normalizeServer(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;
    if (!text.toLowerCase().startsWith('http://') && !text.toLowerCase().startsWith('https://')) {
      text = 'http://$text';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    var path = uri.path;
    for (final suffix in ['/player_api.php', '/get.php', '/xmltv.php']) {
      if (path.toLowerCase().endsWith(suffix)) path = path.substring(0, path.length - suffix.length);
    }
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return uri.replace(path: path, query: null, fragment: null);
  }

  /// Reconnaît une URL « get.php?username=…&password=… » et en extrait serveur et identifiants.
  static XtreamCredentials? fromPlaylistUrl(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) return null;
    final user = uri.queryParameters['username'];
    final pass = uri.queryParameters['password'];
    if (user == null || pass == null || user.isEmpty || pass.isEmpty) return null;
    return XtreamCredentials(Uri(scheme: uri.scheme, host: uri.host, port: uri.hasPort ? uri.port : null), user, pass);
  }
}

/// API Xtream Codes (player_api.php), portage de la version Mac.
class XtreamClient {
  XtreamClient(this.credentials, this.sourceId);
  final XtreamCredentials credentials;
  final String sourceId;

  Uri api([String? action, Map<String, String> extra = const {}]) {
    final base = credentials.server;
    return base.replace(path: '${base.path}/player_api.php', queryParameters: {
      'username': credentials.username,
      'password': credentials.password,
      'action': ?action,
      ...extra,
    });
  }

  String streamUrl(String type, String id, String ext) {
    final base = credentials.server.toString();
    return '$base/$type/${Uri.encodeComponent(credentials.username)}/${Uri.encodeComponent(credentials.password)}/$id.${ext.isEmpty ? 'mp4' : ext}';
  }

  String get xmltvUrl => credentials.server
      .replace(path: '${credentials.server.path}/xmltv.php', queryParameters: {
        'username': credentials.username,
        'password': credentials.password,
      })
      .toString();

  Future<dynamic> _json(Uri url) async {
    final text = await httpGetText(url);
    try {
      return jsonDecode(text);
    } catch (_) {
      throw XtreamException('Réponse du serveur illisible.');
    }
  }

  /// Vérifie le compte (identifiants, statut) ; renvoie le nombre de connexions simultanées autorisées, s'il est indiqué.
  Future<int?> account() async {
    final root = await _json(api());
    if (root is! Map || root['user_info'] is! Map) throw XtreamException('Réponse du serveur illisible.');
    final user = root['user_info'] as Map;
    if (str(user['auth']) == '0') throw XtreamException('Identifiant ou mot de passe refusé par le serveur.');
    final status = str(user['status']) ?? 'Active';
    if (status.toLowerCase() != 'active') throw XtreamException('Compte non actif (statut : $status).');
    clock = ServerClock.parse(root['server_info']);
    return int.tryParse(str(user['max_connections']) ?? '');
  }

  /// Horloge du serveur lue lors de la dernière vérification du compte.
  ServerClock? clock;

  Future<Map<String, String>> _categories(String action) async {
    try {
      final list = await _json(api(action));
      final result = <String, String>{};
      if (list is List) {
        for (final e in list) {
          if (e is Map) {
            final id = str(e['category_id']);
            final name = str(e['category_name']);
            if (id != null && name != null) result[id] = name;
          }
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Charge chaînes, films et séries ; une section en erreur est ignorée si une autre réussit.
  Future<SourceContent> fetchLibrary() async {
    await account();
    Future<List<MediaItem>> safe(Future<List<MediaItem>> Function() f) async {
      try {
        return await f();
      } catch (_) {
        return <MediaItem>[];
      }
    }

    final results = await Future.wait([
      safe(_live),
      safe(_vod),
      safe(_series),
    ]);
    final all = [...results[0], ...results[1], ...results[2]];
    if (all.isEmpty) await _live(); // remonte l'erreur réelle
    return SourceContent(all, epgUrl: xmltvUrl, clock: clock);
  }

  Future<List<MediaItem>> _live() async {
    final cats = await _categories('get_live_categories');
    final list = await _json(api('get_live_streams'));
    if (list is! List) return [];
    return [
      for (final e in list.whereType<Map>())
        if (str(e['stream_id']) case final id?)
          MediaItem(
            id: '$sourceId:live:$id',
            sourceId: sourceId,
            kind: MediaKind.live,
            name: str(e['name']) ?? 'Chaîne $id',
            group: cats[str(e['category_id'])] ?? M3UParser.defaultGroup,
            logo: url(e['stream_icon']),
            stream: streamUrl('live', id, 'ts'),
            epgId: str(e['epg_channel_id']),
            number: int.tryParse(str(e['num']) ?? ''),
            archiveDays: archiveDaysOf(e),
          ),
    ];
  }

  /// Jours de replay annoncés pour une chaîne (tv_archive = 1, tv_archive_duration = nombre de jours).
  static int? archiveDaysOf(Map e) {
    if (int.tryParse(str(e['tv_archive']) ?? '') != 1) return null;
    final days = int.tryParse(str(e['tv_archive_duration']) ?? '') ?? 0;
    return days > 0 ? days : 1;
  }

  Future<List<MediaItem>> _vod() async {
    final cats = await _categories('get_vod_categories');
    final list = await _json(api('get_vod_streams'));
    if (list is! List) return [];
    return [
      for (final e in list.whereType<Map>())
        if (str(e['stream_id']) case final id?)
          MediaItem(
            id: '$sourceId:movie:$id',
            sourceId: sourceId,
            kind: MediaKind.movie,
            name: str(e['name']) ?? 'Film $id',
            group: cats[str(e['category_id'])] ?? M3UParser.defaultGroup,
            logo: url(e['stream_icon']),
            stream: streamUrl('movie', id, str(e['container_extension']) ?? 'mp4'),
            added: timestamp(e['added']),
          ),
    ];
  }

  Future<List<MediaItem>> _series() async {
    final cats = await _categories('get_series_categories');
    final list = await _json(api('get_series'));
    if (list is! List) return [];
    return [
      for (final e in list.whereType<Map>())
        if (str(e['series_id']) case final id?)
          MediaItem(
            id: '$sourceId:series:$id',
            sourceId: sourceId,
            kind: MediaKind.series,
            name: str(e['name']) ?? 'Série $id',
            group: cats[str(e['category_id'])] ?? M3UParser.defaultGroup,
            logo: url(e['cover']),
            seriesId: id,
            info: str(e['plot']),
            added: timestamp(e['last_modified']),
          ),
    ];
  }

  /// Les serveurs Xtream mélangent nombres et chaînes.
  static String? str(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    if (v is int) return '$v';
    if (v is double) return v == v.roundToDouble() ? '${v.toInt()}' : '$v';
    if (v is bool) return v ? '1' : '0';
    return null;
  }

  static String? url(dynamic v) {
    final s = str(v);
    return (s != null && s.toLowerCase().startsWith('http')) ? s : null;
  }

  static DateTime? timestamp(dynamic v) {
    final value = double.tryParse(str(v) ?? '');
    if (value == null || value <= 946684800) return null;
    return DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
  }
}
