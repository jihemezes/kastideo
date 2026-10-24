import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'log.dart';
import 'm3u.dart';
import 'models.dart';
import 'xtream.dart';

/// Bibliothèque : sources, contenus (mis en cache sur disque), favoris et récents.
class LibraryStore extends ChangeNotifier {
  final List<Source> sources = [];
  final Map<String, List<MediaItem>> _contentBySource = {};
  final Map<MediaKind, List<MediaItem>> _byKind = {};
  final Map<MediaKind, List<String>> _categories = {};
  final Map<String, List<MediaItem>> _byCategory = {};
  final Map<String, MediaItem> _byId = {};
  List<String> favoriteIds = [];
  List<String> recentIds = [];
  bool isBusy = false;
  String? lastError;

  late SharedPreferences _prefs;
  final _secrets = const FlutterSecureStorage();
  late Directory _cacheDir;

  Future<void> start() async {
    _prefs = await SharedPreferences.getInstance();
    final support = await getApplicationSupportDirectory();
    _cacheDir = Directory('${support.path}${Platform.pathSeparator}library');
    await _cacheDir.create(recursive: true);
    final raw = _prefs.getString('sources.v1');
    if (raw != null) {
      for (final e in (jsonDecode(raw) as List)) {
        sources.add(Source.fromJson(Map<String, dynamic>.from(e as Map)));
      }
    }
    favoriteIds = _prefs.getStringList('favorites.v1') ?? [];
    recentIds = _prefs.getStringList('recents.v1') ?? [];
    // Démarrage rapide : contenu en cache, puis actualisation si plus de 6 h.
    for (final source in sources) {
      final file = _cacheFile(source.id);
      if (await file.exists()) {
        try {
          final path = file.path;
          final items = await Isolate.run(() => _decodeCache(path));
          _contentBySource[source.id] = items;
        } catch (_) {}
      }
    }
    _rebuild();
    final stale = sources.where((s) =>
        s.enabled && (s.lastRefresh == null || DateTime.now().difference(s.lastRefresh!) > const Duration(hours: 6)));
    if (stale.isNotEmpty) refreshAll();
  }

  File _cacheFile(String id) => File('${_cacheDir.path}${Platform.pathSeparator}$id.json');

  static List<MediaItem> _decodeCache(String path) {
    final list = jsonDecode(File(path).readAsStringSync()) as List;
    return [for (final e in list) MediaItem.fromJson(Map<String, dynamic>.from(e as Map))];
  }

  // MARK: Accès

  int count(MediaKind kind) => _byKind[kind]?.length ?? 0;
  List<MediaItem> items(MediaKind kind) => _byKind[kind] ?? const [];
  List<String> categories(MediaKind kind) => _categories[kind] ?? const [];
  List<MediaItem> itemsInCategory(MediaKind kind, String category) => _byCategory['${kind.index}|$category'] ?? const [];
  MediaItem? item(String id) => _byId[id];
  bool isFavorite(String id) => favoriteIds.contains(id);
  List<MediaItem> get favorites => [for (final id in favoriteIds) ?_byId[id]];
  List<MediaItem> get recents => [for (final id in recentIds) ?_byId[id]];

  void toggleFavorite(String id) {
    if (!favoriteIds.remove(id)) favoriteIds.insert(0, id);
    _prefs.setStringList('favorites.v1', favoriteIds);
    notifyListeners();
  }

  void noteRecent(MediaItem item) {
    recentIds
      ..remove(item.id)
      ..insert(0, item.id);
    if (recentIds.length > 60) recentIds = recentIds.sublist(0, 60);
    _prefs.setStringList('recents.v1', recentIds);
    notifyListeners();
  }

  void _rebuild() {
    _byKind.clear();
    _categories.clear();
    _byCategory.clear();
    _byId.clear();
    for (final source in sources.where((s) => s.enabled)) {
      for (final item in _contentBySource[source.id] ?? const <MediaItem>[]) {
        _byId[item.id] = item;
        (_byKind[item.kind] ??= []).add(item);
        final key = '${item.kind.index}|${item.group}';
        final list = _byCategory[key];
        if (list == null) {
          _byCategory[key] = [item];
          (_categories[item.kind] ??= []).add(item.group);
        } else {
          list.add(item);
        }
      }
    }
    notifyListeners();
  }

  // MARK: Sources

  Future<void> _saveSources() =>
      _prefs.setString('sources.v1', jsonEncode([for (final s in sources) s.toJson()]));

  Future<String?> password(String sourceId) => _secrets.read(key: 'password.$sourceId');

  /// Ajoute une source Xtream (le mot de passe va dans le coffre du système).
  Future<void> addXtream({required String name, required String server, required String username, required String password}) async {
    final normalized = XtreamCredentials.normalizeServer(server);
    if (normalized == null) throw XtreamException('Adresse du serveur invalide.');
    final source = Source(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? normalized.host : name.trim(),
      kind: SourceKind.xtream,
      address: normalized.toString(),
      username: username.trim(),
    );
    await _secrets.write(key: 'password.${source.id}', value: password);
    sources.add(source);
    await _saveSources();
    notifyListeners();
    await refresh(source);
  }

  /// Ajoute une playlist M3U (URL ou fichier). Une URL « get.php » devient une source Xtream, plus rapide.
  Future<void> addM3U({required String name, required String address}) async {
    final xtream = XtreamCredentials.fromPlaylistUrl(address);
    if (xtream != null) {
      return addXtream(name: name, server: xtream.server.toString(), username: xtream.username, password: xtream.password);
    }
    final isFile = !address.trim().toLowerCase().startsWith('http');
    final source = Source(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Playlist' : name.trim(),
      kind: isFile ? SourceKind.m3uFile : SourceKind.m3uUrl,
      address: address.trim(),
    );
    sources.add(source);
    await _saveSources();
    notifyListeners();
    await refresh(source);
  }

  Future<void> removeSource(Source source) async {
    sources.removeWhere((s) => s.id == source.id);
    _contentBySource.remove(source.id);
    await _secrets.delete(key: 'password.${source.id}');
    final file = _cacheFile(source.id);
    if (await file.exists()) await file.delete();
    await _saveSources();
    _rebuild();
  }

  Future<void> refreshAll() async {
    for (final source in List.of(sources.where((s) => s.enabled))) {
      await refresh(source);
    }
  }

  Future<void> refresh(Source source) async {
    isBusy = true;
    lastError = null;
    notifyListeners();
    try {
      final id = source.id;
      List<MediaItem> items;
      switch (source.kind) {
        case SourceKind.xtream:
          final pass = await password(id) ?? '';
          final server = source.address;
          final user = source.username ?? '';
          items = await Isolate.run(() async {
            final client = XtreamClient(XtreamCredentials(Uri.parse(server), user, pass), id);
            return (await client.fetchLibrary()).items;
          });
        case SourceKind.m3uUrl:
          final url = source.address;
          items = await Isolate.run(() async => M3UParser.parse(await httpGetText(Uri.parse(url)), id).items);
        case SourceKind.m3uFile:
          final path = source.address;
          items = await Isolate.run(() => M3UParser.parse(File(path).readAsStringSync(), id).items);
      }
      _contentBySource[id] = items;
      source.lastRefresh = DateTime.now();
      await _saveSources();
      final path = _cacheFile(id).path;
      final encoded = [for (final i in items) i.toJson()];
      await Isolate.run(() => File(path).writeAsStringSync(jsonEncode(encoded)));
      PlaybackLog.shared.note('Source « ${source.name} » chargée : ${items.length} éléments');
    } catch (e) {
      lastError = '${source.name} : $e';
      PlaybackLog.shared.note('Source « ${source.name} » : $e');
    } finally {
      isBusy = false;
      _rebuild();
    }
  }
}
