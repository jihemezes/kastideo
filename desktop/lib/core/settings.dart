import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'secrets.dart';

/// Interface d'affichage d'une section (mêmes valeurs que sur Mac : classic, cinema, tv).
enum InterfaceStyle { classic, cinema, tv }

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

  InterfaceStyle interfaceFor(MediaKind kind) {
    final raw = _prefs.getString('interface.${kind.name}');
    final style = InterfaceStyle.values.where((s) => s.name == raw).firstOrNull ?? InterfaceStyle.classic;
    return style == InterfaceStyle.tv ? InterfaceStyle.classic : style; // l'interface TV arrive à l'étape 2c
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
