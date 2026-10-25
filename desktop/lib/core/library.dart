import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'log.dart';
import 'm3u.dart';
import 'models.dart';
import 'secrets.dart';
import 'settings.dart';
import 'themes.dart';
import 'xtream.dart';

/// Bibliothèque : sources, contenus (mis en cache sur disque), favoris, récents et catégories personnalisées.
class LibraryStore extends ChangeNotifier {
  final List<Source> sources = [];
  final Map<String, List<MediaItem>> _contentBySource = {};
  final Map<MediaKind, List<MediaItem>> _byKind = {};
  final Map<MediaKind, List<String>> _categories = {};
  final Map<MediaKind, List<String>> _allCategories = {};
  final Map<String, List<MediaItem>> _byCategory = {};
  final Map<String, MediaItem> _byId = {};

  /// Épisodes lus (absents de l'index principal), pour les récents et les favoris.
  final Map<String, MediaItem> _extras = {};
  final Map<MediaKind, CategoryPrefs> _categoryPrefs = {};
  List<String> favoriteIds = [];
  List<String> recentIds = [];
  bool isBusy = false;
  String? lastError;

  /// Contenus adultes (« |XX| », catégorie adulte) : masqués partout tant que l'option est désactivée.
  bool showAdult = false;

  /// Change à chaque reconstruction de l'index (le guide TV recalcule alors ses chaînes).
  int liveGeneration = 0;

  /// Appelé après l'actualisation réussie d'une source (rechargement de son guide TV).
  void Function(Source source)? onSourceRefreshed;
  void Function(String sourceId)? onSourceRemoved;

  late SharedPreferences _prefs;
  final _secrets = Secrets.shared;
  late Directory _cacheDir;

  static const categoryKinds = [MediaKind.live, MediaKind.movie, MediaKind.series];

  Future<void> start({bool autoRefresh = true}) async {
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
    showAdult = _prefs.getBool('adult.show') ?? false;
    favoriteIds = _prefs.getStringList('favorites.v1') ?? [];
    recentIds = _prefs.getStringList('recents.v1') ?? [];
    for (final kind in categoryKinds) {
      final json = _prefs.getString('categories.${kind.name}.v1');
      if (json != null) _categoryPrefs[kind] = CategoryPrefs.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }
    final extras = _prefs.getString('recentItems.v1');
    if (extras != null) {
      for (final e in (jsonDecode(extras) as List)) {
        final item = MediaItem.fromJson(Map<String, dynamic>.from(e as Map));
        _extras[item.id] = item;
      }
    }
    // Démarrage rapide : contenu en cache, puis actualisation si plus de 6 h.
    for (final source in sources) {
      final file = _cacheFile(source.id);
      if (await file.exists()) {
        try {
          final path = file.path;
          _contentBySource[source.id] = await Isolate.run(() => _decodeCache(path));
        } catch (_) {}
      }
    }
    _rebuild();
    final stale = sources.where((s) =>
        s.enabled &&
        (_contentBySource[s.id] == null ||
            (autoRefresh && (s.lastRefresh == null || DateTime.now().difference(s.lastRefresh!) > const Duration(hours: 6)))));
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

  /// Catégories visibles, dans l'ordre choisi (noms d'origine).
  List<String> categories(MediaKind kind) => _categories[kind] ?? const [];

  /// Toutes les catégories, masquées comprises (gestionnaire de catégories).
  List<String> allCategories(MediaKind kind) => _allCategories[kind] ?? const [];
  List<MediaItem> itemsInCategory(MediaKind kind, String category) => _byCategory['${kind.index}|$category'] ?? const [];
  String categoryName(MediaKind kind, String name) => prefs(kind).displayName(name);
  MediaItem? item(String id) => _byId[id] ?? _extras[id];
  bool isFavorite(String id) => favoriteIds.contains(id);
  List<MediaItem> get favorites => [for (final id in favoriteIds) ?item(id)];
  List<MediaItem> get recents => [for (final id in recentIds) ?item(id)];

  /// Contenus récents d'une section (épisodes compris pour les séries).
  List<MediaItem> recentsOf(MediaKind kind) =>
      recents.where((i) => i.kind == kind || (kind == MediaKind.series && i.kind == MediaKind.episode)).toList();
  List<MediaItem> favoritesOf(MediaKind kind) =>
      favorites.where((i) => i.kind == kind || (kind == MediaKind.series && i.kind == MediaKind.episode)).toList();

  /// Derniers ajouts du fournisseur (Xtream), du plus récent au plus ancien.
  List<MediaItem> latest(MediaKind kind, {int limit = 40}) {
    final withDate = items(kind).where((i) => i.added != null).toList()..sort((a, b) => b.added!.compareTo(a.added!));
    return withDate.take(limit).toList();
  }

  void toggleFavorite(String id) {
    if (!favoriteIds.remove(id)) favoriteIds.insert(0, id);
    _prefs.setStringList('favorites.v1', favoriteIds);
    _saveExtras();
    notifyListeners();
  }

  void noteRecent(MediaItem item) {
    recentIds
      ..remove(item.id)
      ..insert(0, item.id);
    if (recentIds.length > 60) recentIds = recentIds.sublist(0, 60);
    if (_byId[item.id] == null) _extras[item.id] = item;
    _prefs.setStringList('recents.v1', recentIds);
    _saveExtras();
    notifyListeners();
  }

  void clearRecents() {
    recentIds = [];
    _prefs.setStringList('recents.v1', recentIds);
    _saveExtras();
    notifyListeners();
  }

  void _saveExtras() {
    final keep = {...recentIds, ...favoriteIds};
    _extras.removeWhere((k, _) => !keep.contains(k));
    _prefs.setString('recentItems.v1', jsonEncode([for (final i in _extras.values) i.toJson()]));
  }

  // MARK: Catégories

  CategoryPrefs prefs(MediaKind kind) => _categoryPrefs[kind] ?? CategoryPrefs();

  void updateCategories(MediaKind kind, void Function(CategoryPrefs prefs) change) {
    final p = _categoryPrefs[kind] ?? CategoryPrefs();
    change(p);
    _categoryPrefs[kind] = p;
    _prefs.setString('categories.${kind.name}.v1', jsonEncode(p.toJson()));
    _rebuild();
  }

  void _rebuild() {
    _byKind.clear();
    _categories.clear();
    _allCategories.clear();
    _byCategory.clear();
    _byId.clear();
    final providerOrder = <MediaKind, List<String>>{};
    for (final source in sources.where((s) => s.enabled)) {
      for (final item in _contentBySource[source.id] ?? const <MediaItem>[]) {
        final prefs = _categoryPrefs[item.kind];
        final key = '${item.kind.index}|${item.group}';
        final list = _byCategory[key];
        if (list == null) {
          _byCategory[key] = [item];
          (providerOrder[item.kind] ??= []).add(item.group);
        } else {
          list.add(item);
        }
        _byId[item.id] = item;
        if (!showAdult && item.kind != MediaKind.episode && ThemeClassifier.isAdult(item.name, group: item.group)) continue;
        // Une catégorie masquée l'est partout (listes, recherche, accueil), comme sur Mac.
        if (prefs != null && prefs.isHidden(item.group)) continue;
        (_byKind[item.kind] ??= []).add(item);
      }
    }
    providerOrder.forEach((kind, names) {
      final prefs = _categoryPrefs[kind] ?? CategoryPrefs();
      final ordered = prefs.apply(names);
      _allCategories[kind] = ordered;
      _categories[kind] = ordered
          .where((n) => !prefs.isHidden(n) && (showAdult || !ThemeClassifier.isAdult('', group: n)))
          .toList();
    });
    liveGeneration++;
    notifyListeners();
  }

  void setShowAdult(bool value) {
    showAdult = value;
    _prefs.setBool('adult.show', value);
    _rebuild();
  }

  // MARK: Sources

  Future<void> _saveSources() => _prefs.setString('sources.v1', jsonEncode([for (final s in sources) s.toJson()]));

  Future<String?> password(String sourceId) => _secrets.read('password.$sourceId');

  /// Client Xtream d'une source (fiches, épisodes).
  Future<XtreamClient?> xtreamClient(String sourceId) async {
    final source = sources.where((s) => s.id == sourceId).firstOrNull;
    if (source == null || source.kind != SourceKind.xtream) return null;
    final pass = await password(sourceId) ?? '';
    return XtreamClient(XtreamCredentials(Uri.parse(source.address), source.username ?? '', pass), sourceId);
  }

  /// Toutes les chaînes d'une source (masquées comprises), pour filtrer son guide TV.
  List<MediaItem> allLiveItems(String sourceId) =>
      (_contentBySource[sourceId] ?? const <MediaItem>[]).where((i) => i.kind == MediaKind.live).toList();

  /// Adresse du guide TV d'une source : choisie par l'utilisateur, indiquée par le fournisseur, ou xmltv.php (Xtream).
  Future<String?> guideUrlFor(Source source) async {
    if (source.epgUrl?.isNotEmpty ?? false) return source.epgUrl;
    if (source.guideUrl?.isNotEmpty ?? false) return source.guideUrl;
    final client = await xtreamClient(source.id);
    return client?.xmltvUrl;
  }

  /// Ajoute une source Xtream (le mot de passe va dans le coffre du système).
  Future<Source> addXtream(
      {required String name,
      required String server,
      required String username,
      required String password,
      String? epgUrl,
      bool refreshNow = true}) async {
    final normalized = XtreamCredentials.normalizeServer(server);
    if (normalized == null) throw XtreamException('Adresse du serveur invalide.');
    final source = Source(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? normalized.host : name.trim(),
      kind: SourceKind.xtream,
      address: normalized.toString(),
      username: username.trim(),
      epgUrl: (epgUrl?.trim().isEmpty ?? true) ? null : epgUrl!.trim(),
    );
    await _secrets.write('password.${source.id}', password);
    sources.add(source);
    await _saveSources();
    notifyListeners();
    if (refreshNow) await refresh(source);
    return source;
  }

  /// Ajoute une playlist M3U (URL ou fichier). Une URL « get.php » devient une source Xtream, plus rapide.
  Future<Source> addM3U({required String name, required String address, String? epgUrl, bool refreshNow = true}) async {
    final xtream = XtreamCredentials.fromPlaylistUrl(address);
    if (xtream != null) {
      return addXtream(
          name: name,
          server: xtream.server.toString(),
          username: xtream.username,
          password: xtream.password,
          epgUrl: epgUrl,
          refreshNow: refreshNow);
    }
    final isFile = !address.trim().toLowerCase().startsWith('http');
    final source = Source(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Playlist' : name.trim(),
      kind: isFile ? SourceKind.m3uFile : SourceKind.m3uUrl,
      address: address.trim(),
      epgUrl: (epgUrl?.trim().isEmpty ?? true) ? null : epgUrl!.trim(),
    );
    sources.add(source);
    await _saveSources();
    notifyListeners();
    if (refreshNow) await refresh(source);
    return source;
  }

  Future<void> removeSource(Source source) async {
    sources.removeWhere((s) => s.id == source.id);
    _contentBySource.remove(source.id);
    await _secrets.delete('password.${source.id}');
    final file = _cacheFile(source.id);
    if (await file.exists()) await file.delete();
    await _saveSources();
    _rebuild();
    onSourceRemoved?.call(source.id);
  }

  Future<void> refreshAll() async {
    for (final source in List.of(sources.where((s) => s.enabled))) {
      await refresh(source);
    }
  }

  Future<void> refresh(Source source) async {
    var refreshed = false;
    isBusy = true;
    lastError = null;
    notifyListeners();
    try {
      final id = source.id;
      SourceContent content;
      switch (source.kind) {
        case SourceKind.xtream:
          final pass = await password(id) ?? '';
          final server = source.address;
          final user = source.username ?? '';
          content = await Isolate.run(() async {
            final client = XtreamClient(XtreamCredentials(Uri.parse(server), user, pass), id);
            return client.fetchLibrary();
          });
        case SourceKind.m3uUrl:
          final url = source.address;
          content = await Isolate.run(() async => M3UParser.parse(await httpGetText(Uri.parse(url)), id));
        case SourceKind.m3uFile:
          final path = source.address;
          content = await Isolate.run(() => M3UParser.parse(File(path).readAsStringSync(), id));
      }
      final items = content.items;
      _contentBySource[id] = items;
      source.lastRefresh = DateTime.now();
      source.guideUrl = content.epgUrl;
      refreshed = true;
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
    if (refreshed) onSourceRefreshed?.call(source);
  }

  // MARK: Exportation / importation (format commun avec la version Mac)

  /// Identifiant relatif : « numéro de source|reste de l'identifiant ».
  String? _relative(String id, Map<String, int> index) {
    final sep = id.indexOf(':');
    if (sep <= 0) return null;
    final n = index[id.substring(0, sep)];
    return n == null ? null : '$n|${id.substring(sep + 1)}';
  }

  Future<Map<String, dynamic>> makeExport({required bool includePasswords, required AppSettings settings, required String app}) async {
    final index = <String, int>{};
    final exported = <Map<String, dynamic>>[];
    for (final s in sources) {
      if (s.kind == SourceKind.m3uFile) continue;
      index[s.id] = exported.length;
      exported.add({
        'name': s.name,
        'kind': s.kind == SourceKind.xtream ? 'xtream' : 'm3uUrl',
        'address': s.address,
        'username': ?s.username,
        if (includePasswords && s.kind == SourceKind.xtream) 'password': ?await password(s.id),
        'epgUrl': ?s.epgUrl,
        'enabled': s.enabled,
      });
    }
    final settingsMap = <String, String>{
      for (final kind in categoryKinds)
        'interface.${kind.name}': ?settings.rawSetting('interface.${kind.name}'),
      'adult.show': showAdult ? '1' : '0',
      ...settings.exportedHero(),
      if (includePasswords && settings.usesTMDB) 'tmdbKey': settings.tmdbKey,
    };
    return {
      'format': 'kastideo-export',
      'version': 1,
      'exportedAt': '${DateTime.now().toUtc().toIso8601String().split('.').first}Z',
      'app': app,
      'sources': exported,
      'favorites': [for (final id in favoriteIds) ?_relative(id, index)],
      'recents': [for (final id in recentIds) ?_relative(id, index)],
      'categories': {for (final kind in categoryKinds) if (_categoryPrefs[kind] case final p?) kind.name: p.toJson()},
      'settings': settingsMap,
    };
  }

  /// Ajoute les sources absentes, les favoris, les récents, les catégories et les réglages. Rien n'est supprimé.
  Future<String> importConfig(Map<String, dynamic> data, AppSettings settings) async {
    if (data['format'] != 'kastideo-export') throw XtreamException('Ce fichier n\'est pas une configuration Kastideo.');
    var added = 0, skipped = 0, favs = 0, cats = 0;
    final newIds = <int, String>{};
    final list = (data['sources'] as List? ?? const []).whereType<Map>().toList();
    final toRefresh = <Source>[];
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      final kind = e['kind'] == 'xtream' ? SourceKind.xtream : e['kind'] == 'm3uUrl' ? SourceKind.m3uUrl : null;
      final address = e['address'] as String?;
      if (kind == null || address == null) continue;
      final normalized = kind == SourceKind.xtream ? XtreamCredentials.normalizeServer(address)?.toString() ?? address : address;
      final existing = sources
          .where((s) => s.kind == kind && s.address == normalized && (kind != SourceKind.xtream || s.username == e['username']))
          .firstOrNull;
      if (existing != null) {
        newIds[i] = existing.id;
        skipped++;
        continue;
      }
      final source = kind == SourceKind.xtream
          ? await addXtream(
              name: e['name'] as String? ?? '',
              server: address,
              username: e['username'] as String? ?? '',
              password: e['password'] as String? ?? '',
              epgUrl: e['epgUrl'] as String?,
              refreshNow: false)
          : await addM3U(name: e['name'] as String? ?? '', address: address, epgUrl: e['epgUrl'] as String?, refreshNow: false);
      source.enabled = e['enabled'] as bool? ?? true;
      newIds[i] = source.id;
      toRefresh.add(source);
      added++;
    }
    await _saveSources();
    String? absolute(dynamic rel) {
      if (rel is! String) return null;
      final sep = rel.indexOf('|');
      if (sep <= 0) return null;
      final id = newIds[int.tryParse(rel.substring(0, sep)) ?? -1];
      return id == null ? null : '$id:${rel.substring(sep + 1)}';
    }

    for (final id in (data['favorites'] as List? ?? const []).map(absolute).whereType<String>()) {
      if (!favoriteIds.contains(id)) {
        favoriteIds.add(id);
        favs++;
      }
    }
    for (final id in (data['recents'] as List? ?? const []).map(absolute).whereType<String>()) {
      if (!recentIds.contains(id)) recentIds.add(id);
    }
    if (recentIds.length > 60) recentIds = recentIds.sublist(0, 60);
    _prefs.setStringList('favorites.v1', favoriteIds);
    _prefs.setStringList('recents.v1', recentIds);
    final categories = data['categories'];
    if (categories is Map) {
      for (final kind in categoryKinds) {
        final c = categories[kind.name];
        if (c is Map) {
          final imported = CategoryPrefs.fromJson(Map<String, dynamic>.from(c));
          _categoryPrefs[kind] = imported;
          _prefs.setString('categories.${kind.name}.v1', jsonEncode(imported.toJson()));
          cats++;
        }
      }
    }
    final s = data['settings'];
    if (s is Map) {
      for (final kind in categoryKinds) {
        final v = s['interface.${kind.name}'];
        final style = InterfaceStyle.values.where((x) => x.name == v).firstOrNull;
        if (style != null) settings.setInterface(kind, style);
      }
      final adult = s['adult.show'];
      if (adult is String) {
        showAdult = adult == '1' || adult == 'true';
        _prefs.setBool('adult.show', showAdult);
      }
      settings.importHero(Map<String, dynamic>.from(s));
      final key = s['tmdbKey'];
      if (key is String && key.isNotEmpty && !settings.usesTMDB) await settings.setTMDBKey(key);
    }
    _rebuild();
    for (final source in toRefresh) {
      await refresh(source);
    }
    return 'Importation terminée : $added source(s) ajoutée(s), $skipped déjà présente(s), $favs favori(s), '
        'catégories de $cats section(s).';
  }
}
