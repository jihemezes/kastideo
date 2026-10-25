import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'secrets.dart';

/// Interface d'affichage d'une section (mêmes valeurs que sur Mac : classic, cinema, tv).
enum InterfaceStyle { classic, cinema, tv }

/// Hauteur du bandeau « à la une ».
enum HeroHeight {
  compact(280),
  normal(360),
  large(460);

  const HeroHeight(this.points);
  final double points;
}

/// Réglages de l'application (équivalent des @AppStorage de la version Mac).
class AppSettings extends ChangeNotifier {
  late SharedPreferences _prefs;
  final _secrets = Secrets.shared;

  /// Clé TMDB (coffre du système). Vide : TMDB n'est pas utilisé.
  String tmdbKey = '';
  bool resumePlayback = true;
  bool relayEnabled = true;
  bool autoRefresh = true;

  /// « system », « fr » ou « en » (appliqué au prochain lancement).
  String language = 'system';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    resumePlayback = _prefs.getBool('resumePlayback') ?? true;
    relayEnabled = _prefs.getBool('relay.enabled') ?? true;
    autoRefresh = _prefs.getBool('autoRefresh') ?? true;
    language = _prefs.getString('language') ?? 'system';
    try {
      tmdbKey = await _secrets.read('tmdb.apiKey') ?? '';
    } catch (_) {
      tmdbKey = '';
    }
  }

  bool get usesTMDB => tmdbKey.trim().isNotEmpty;

  // MARK: Différé, enregistrements, téléchargements, alertes

  /// Durée maximale du différé du direct (minutes) et vitesse de rattrapage (mêmes clés que sur Mac).
  int get timeshiftMinutes => _prefs.getInt('timeshift.maxMinutes') ?? 60;
  double get catchUpSpeed => _prefs.getDouble('timeshift.catchUpSpeed') ?? 1.5;

  /// Dossier des enregistrements et téléchargements (vide : Vidéos/Kastideo).
  String get recordingsFolder => _prefs.getString('recordings.folder') ?? '';

  /// Format des enregistrements du direct : « mkv » ou « ts ».
  String get recordingFormat => _prefs.getString('recordings.format') ?? 'mkv';
  int get marginBefore => _prefs.getInt('recordings.marginBefore') ?? 2;
  int get marginAfter => _prefs.getInt('recordings.marginAfter') ?? 5;
  bool get pauseDownloadsDuringPlayback => _prefs.getBool('downloads.pauseDuringPlayback') ?? true;
  int get nightHour => _prefs.getInt('downloads.nightHour') ?? 1;

  /// Alertes : mots-clés, portée (« favorites » ou « all ») et avance en minutes.
  List<String> get alertKeywords => _prefs.getStringList('alerts.keywords') ?? const [];
  String get alertScope => _prefs.getString('alerts.scope') ?? 'favorites';
  int get alertLead => _prefs.getInt('alerts.lead') ?? 1;

  void setInt(String key, int value) {
    _prefs.setInt(key, value);
    notifyListeners();
  }

  void setDouble(String key, double value) {
    _prefs.setDouble(key, value);
    notifyListeners();
  }

  void setBool(String key, bool value) {
    _prefs.setBool(key, value);
    notifyListeners();
  }

  void setString(String key, String value) {
    _prefs.setString(key, value);
    notifyListeners();
  }

  void setStringList(String key, List<String> value) {
    _prefs.setStringList(key, value);
    notifyListeners();
  }

  // MARK: Bandeau « à la une » (mêmes clés que sur Mac)

  bool get heroEnabled => _prefs.getBool('hero.enabled') ?? true;
  HeroHeight get heroHeight => HeroHeight.values.where((h) => h.name == _prefs.getString('hero.height')).firstOrNull ?? HeroHeight.normal;
  double get heroInterval => _prefs.getDouble('hero.interval') ?? 8;
  bool get heroUseTrending => _prefs.getBool('hero.useTrending') ?? true;
  bool get heroUseRecent => _prefs.getBool('hero.useRecent') ?? true;
  bool get heroUseCategory => _prefs.getBool('hero.useCategory') ?? true;
  String heroCategory(MediaKind kind) => _prefs.getString(kind == MediaKind.series ? 'hero.category.series' : 'hero.category.movie') ?? '';

  void setHero({bool? enabled, HeroHeight? height, double? interval, bool? trending, bool? recent, bool? category}) {
    if (enabled != null) _prefs.setBool('hero.enabled', enabled);
    if (height != null) _prefs.setString('hero.height', height.name);
    if (interval != null) _prefs.setDouble('hero.interval', interval);
    if (trending != null) _prefs.setBool('hero.useTrending', trending);
    if (recent != null) _prefs.setBool('hero.useRecent', recent);
    if (category != null) _prefs.setBool('hero.useCategory', category);
    heroGeneration++;
    notifyListeners();
  }

  void setHeroCategory(MediaKind kind, String name) {
    _prefs.setString(kind == MediaKind.series ? 'hero.category.series' : 'hero.category.movie', name);
    heroGeneration++;
    notifyListeners();
  }

  /// Change quand les réglages du bandeau changent (le bandeau se recompose).
  int heroGeneration = 0;

  static const _heroBools = ['hero.enabled', 'hero.useTrending', 'hero.useRecent', 'hero.useCategory'];
  static const _heroStrings = ['hero.height', 'hero.category.movie', 'hero.category.series'];

  Map<String, String> exportedHero() => {
        for (final k in _heroBools)
          if (_prefs.getBool(k) case final v?) k: v ? '1' : '0',
        for (final k in _heroStrings) k: ?_prefs.getString(k),
        if (_prefs.getDouble('hero.interval') case final v?) 'hero.interval': '$v',
      };

  void importHero(Map<String, dynamic> s) {
    for (final k in _heroBools) {
      if (s[k] case final String v) _prefs.setBool(k, v == '1' || v == 'true');
    }
    for (final k in _heroStrings) {
      if (s[k] case final String v) _prefs.setString(k, v);
    }
    if (s['hero.interval'] case final String v) {
      final d = double.tryParse(v);
      if (d != null) _prefs.setDouble('hero.interval', d);
    }
    heroGeneration++;
    notifyListeners();
  }

  InterfaceStyle interfaceFor(MediaKind kind) {
    final raw = _prefs.getString('interface.${kind.name}');
    final style = InterfaceStyle.values.where((s) => s.name == raw).firstOrNull ?? InterfaceStyle.classic;
    // L'interface TV n'existe que pour le direct (comme sur Mac).
    return style == InterfaceStyle.tv && kind != MediaKind.live ? InterfaceStyle.classic : style;
  }

  void setInterface(MediaKind kind, InterfaceStyle style) {
    _prefs.setString('interface.${kind.name}', style.name);
    notifyListeners();
  }

  String? rawSetting(String key) {
    final value = _prefs.get(key);
    return value?.toString();
  }

  void setResume(bool value) {
    resumePlayback = value;
    _prefs.setBool('resumePlayback', value);
    notifyListeners();
  }

  void setRelay(bool value) {
    relayEnabled = value;
    _prefs.setBool('relay.enabled', value);
    notifyListeners();
  }

  void setAutoRefresh(bool value) {
    autoRefresh = value;
    _prefs.setBool('autoRefresh', value);
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    _prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> setTMDBKey(String value) async {
    tmdbKey = value.trim();
    if (tmdbKey.isEmpty) {
      await _secrets.delete('tmdb.apiKey');
    } else {
      await _secrets.write('tmdb.apiKey', tmdbKey);
    }
    notifyListeners();
  }
}

/// Positions de lecture des films et épisodes (reprise), enregistrées sur disque.
class WatchProgressStore extends ChangeNotifier {
  final Map<String, (double position, double duration)> _entries = {};
  File? _file;

  Future<void> load() async {
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}${Platform.pathSeparator}watch-progress.json');
    try {
      final map = jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
      map.forEach((k, v) {
        final list = (v as List).cast<num>();
        _entries[k] = (list[0].toDouble(), list[1].toDouble());
      });
    } catch (_) {}
  }

  /// Fraction lue (entre 2 % et 95 %), sinon null.
  double? fraction(String id) {
    final e = _entries[id];
    if (e == null || e.$2 <= 0) return null;
    final f = e.$1 / e.$2;
    return (f > 0.02 && f < 0.95) ? f : null;
  }

  /// Position de reprise (quelques secondes avant), si le contenu est entamé.
  double? resumePoint(String id) {
    if (fraction(id) == null) return null;
    final p = _entries[id]!.$1 - 5;
    return p > 0 ? p : 0;
  }

  void update(String id, double position, double duration) {
    if (duration <= 0) return;
    _entries[id] = (position, duration);
    notifyListeners();
  }

  void clear(String id) {
    _entries.remove(id);
    notifyListeners();
    flush();
  }

  Future<void> flush() async {
    final file = _file;
    if (file == null) return;
    await file.writeAsString(jsonEncode({for (final e in _entries.entries) e.key: [e.value.$1, e.value.$2]}));
  }
}

/// Ordre, masquage, noms personnalisés et mots-clés des catégories (comme CategoryPrefs sur Mac).
class CategoryPrefs {
  List<String> order = [];
  Set<String> hidden = {};
  Map<String, String> renames = {};
  List<String> keywords = [];

  bool isHidden(String name) {
    if (hidden.contains(name)) return true;
    final lower = name.toLowerCase();
    return keywords.any((k) => k.trim().isNotEmpty && lower.contains(k.trim().toLowerCase()));
  }

  bool isHiddenByKeyword(String name) => !hidden.contains(name) && isHidden(name);

  String displayName(String name) {
    final r = renames[name];
    return (r != null && r.trim().isNotEmpty) ? r : name;
  }

  List<String> apply(List<String> provider) {
    if (order.isEmpty) return provider;
    final available = provider.toSet();
    final result = order.where(available.contains).toList();
    final placed = result.toSet();
    result.addAll(provider.where((n) => !placed.contains(n)));
    return result;
  }

  Map<String, dynamic> toJson() => {'order': order, 'hidden': hidden.toList(), 'renames': renames, 'keywords': keywords};

  static CategoryPrefs fromJson(Map<String, dynamic> j) => CategoryPrefs()
    ..order = List<String>.from(j['order'] as List? ?? const [])
    ..hidden = Set<String>.from(j['hidden'] as List? ?? const [])
    ..renames = Map<String, String>.from(j['renames'] as Map? ?? const {})
    ..keywords = List<String>.from(j['keywords'] as List? ?? const []);
}
