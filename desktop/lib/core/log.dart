import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';

/// Sujet d'une ligne du journal : permet de ne lire que ce qui concerne le problème étudié.
enum LogTopic {
  guide,
  playback,
  sources,
  recording,
  tmdb,
  updates,
  app;

  String get title => switch (this) {
        guide => tr('Guide TV'),
        playback => tr('Lecture et relais'),
        sources => tr('Sources et catalogues'),
        recording => tr('Enregistrements'),
        tmdb => tr('Fiches TMDB'),
        updates => tr('Mises à jour'),
        app => tr('Affichage et divers'),
      };

  /// Détail conservé par défaut : le guide est détaillé tant qu'on cherche à comprendre ses échecs.
  LogDetail get defaultDetail => this == LogTopic.guide ? LogDetail.detailed : LogDetail.normal;

  /// Déduit le sujet d'un ancien message à partir de son début (les messages récents passent leur sujet).
  static LogTopic infer(String text) {
    final t = text.toLowerCase();
    bool starts(List<String> list) => list.any(t.startsWith);
    if (starts(['guide'])) return LogTopic.guide;
    if (starts(['enregistrement', 'conversion', 'téléchargement', 'dossier d\'enregistrement'])) return LogTopic.recording;
    if (starts(['tmdb', 'fiche'])) return LogTopic.tmdb;
    if (starts(['mise à jour', 'recherche de mise à jour'])) return LogTopic.updates;
    if (starts(['source', 'serveur', 'synchronisation', 'cache de'])) return LogTopic.sources;
    if (starts(['relais', 'ouverture', 'état', 'son ', 'son :', 'lecture', 'différé', 'vitesse', 'attente', 'chaîne refusée',
      'flux', 'multivue', 'aucune image', 'qualité'])) {
      return LogTopic.playback;
    }
    return LogTopic.app;
  }
}

/// Niveau de détail d'un sujet : « Normal » ne garde que l'essentiel, « Débogage » garde tout.
enum LogDetail {
  normal,
  detailed,
  debug;

  String get title => switch (this) {
        normal => tr('Normal'),
        detailed => tr('Détaillé'),
        debug => tr('Débogage'),
      };
}

/// Ligne du journal.
class LogLine {
  LogLine(this.date, this.level, this.text, [this.topic = LogTopic.app]);
  final DateTime date;

  /// 0 erreur, 1 alerte, 2 info.
  final int level;
  final String text;
  final LogTopic topic;

  String get levelLabel => switch (level) { 0 => 'ERREUR', 1 => 'ALERTE', _ => 'info' };
}

/// Journal de Kastideo (3 000 dernières lignes en mémoire, identifiants masqués), classé par sujet et conservé sur disque
/// (session en cours et session précédente) — même rôle que sur Mac (⌥⌘L / Ctrl+Alt+L).
class PlaybackLog extends ChangeNotifier {
  PlaybackLog._();
  static final PlaybackLog shared = PlaybackLog._();

  final List<LogLine> _lines = [];
  static const _capacity = 3000;
  static const _maxFileBytes = 5000000;
  List<LogLine> get lines => List.unmodifiable(_lines);

  SharedPreferences? _prefs;
  File? _file;
  File? _previousFile;
  int _written = 0;
  final StringBuffer _pending = StringBuffer();
  bool _flushing = false;

  /// Branche le journal sur le disque et sur les réglages (appelé au démarrage).
  /// La session qui vient de se terminer devient « précédente » (utile pour les problèmes de démarrage).
  Future<void> attach(Directory support, SharedPreferences prefs) async {
    _prefs = prefs;
    try {
      final dir = Directory('${support.path}${Platform.pathSeparator}Logs');
      await dir.create(recursive: true);
      final current = File('${dir.path}${Platform.pathSeparator}journal.log');
      final previous = File('${dir.path}${Platform.pathSeparator}journal-precedent.log');
      if (await current.exists()) {
        if (await previous.exists()) await previous.delete();
        await current.rename(previous.path);
      }
      _file = current;
      _previousFile = previous;
      await current.writeAsString('');
      // Les lignes écrites avant le branchement sont reprises.
      for (final line in _lines) {
        _queue(line);
      }
    } catch (e) {
      debugPrint('Journal sur disque indisponible : $e');
    }
  }

  String? get logsPath => _file?.parent.path;

  // MARK: Niveau de détail par sujet

  LogDetail detail(LogTopic topic) {
    final raw = _prefs?.getInt('log.detail.${topic.name}');
    return raw == null || raw < 0 || raw >= LogDetail.values.length ? topic.defaultDetail : LogDetail.values[raw];
  }

  void setDetail(LogTopic topic, LogDetail value) {
    _prefs?.setInt('log.detail.${topic.name}', value.index);
    notifyListeners();
  }

  // MARK: Écriture

  /// Ajoute une ligne de Kastideo. Sans sujet précisé, il est déduit du début du message. Les lignes plus détaillées
  /// que le réglage du sujet sont ignorées ; erreurs (0) et alertes (1) sont toujours gardées.
  void note(String message, {LogTopic? topic, LogDetail detail = LogDetail.normal, int level = 2}) {
    final t = topic ?? LogTopic.infer(message);
    if (level >= 2 && detail.index > this.detail(t).index) return;
    _add(level, '[kastideo] $message', t);
  }

  void warn(String message, {LogTopic? topic}) => note(message, topic: topic, level: 1);
  void error(String message, {LogTopic? topic}) => note(message, topic: topic, level: 0);
  void engine(String message, {int level = 1}) => _add(level, '[mpv] $message', LogTopic.playback);

  /// KASTIDEO_LOG=1 : le journal est aussi écrit sur la sortie standard (diagnostic).
  static final bool _stdout = const bool.fromEnvironment('dart.vm.product') == false || _envLog;
  static bool get _envLog {
    try {
      return Platform.environment['KASTIDEO_LOG'] == '1';
    } catch (_) {
      return false;
    }
  }

  void _add(int level, String text, LogTopic topic) {
    if (_stdout) debugPrint('${DateTime.now().toIso8601String().substring(11, 23)} $text');
    final line = LogLine(DateTime.now(), level, redact(text), topic);
    _lines.add(line);
    if (_lines.length > _capacity) _lines.removeRange(0, _lines.length - _capacity);
    _queue(line);
    notifyListeners();
  }

  /// Une ligne par message : date, niveau, sujet, texte (tabulations et retours remplacés).
  void _queue(LogLine line) {
    if (_file == null || _written >= _maxFileBytes) return;
    final flat = line.text.replaceAll('\t', ' ').replaceAll('\n', ' ⏎ ');
    final record = '${line.date.toIso8601String()}\t${line.level}\t${line.topic.name}\t$flat\n';
    _written += record.length;
    _pending.write(record);
    if (!_flushing) {
      _flushing = true;
      scheduleMicrotask(_flush);
    }
  }

  Future<void> _flush() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final text = _pending.toString();
    _pending.clear();
    _flushing = false;
    try {
      await _file?.writeAsString(text, mode: FileMode.append);
    } catch (_) {}
  }

  /// Lit le journal de la session précédente.
  Future<List<LogLine>> previousSession() async {
    final file = _previousFile;
    if (file == null || !await file.exists()) return [];
    final result = <LogLine>[];
    for (final row in (await file.readAsString()).split('\n')) {
      final parts = row.split('\t');
      if (parts.length < 4) continue;
      final date = DateTime.tryParse(parts[0]);
      final level = int.tryParse(parts[1]);
      final topic = LogTopic.values.where((t) => t.name == parts[2]).firstOrNull;
      if (date == null || level == null || topic == null) continue;
      result.add(LogLine(date, level, parts.sublist(3).join('\t'), topic));
    }
    return result;
  }

  /// Dernière erreur du moteur de lecture depuis une date (affichée à l'utilisateur).
  String? lastError(DateTime since) {
    for (final line in _lines.reversed) {
      if (line.date.isBefore(since)) break;
      if (line.level == 0 && line.topic == LogTopic.playback) return line.text;
    }
    return null;
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  /// Texte à copier : en-tête (version, filtre appliqué) puis les lignes données (par défaut, tout le journal).
  String export(String version, {List<LogLine>? selection, String? filter}) {
    final b = StringBuffer('Kastideo $version — journal (identifiants masqués)\n');
    if (filter != null && filter.isNotEmpty) b.writeln('Filtre : $filter');
    String two(int v) => v.toString().padLeft(2, '0');
    for (final l in selection ?? _lines) {
      final t = l.date;
      b.writeln('${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')} ${l.levelLabel} [${l.topic.title}] ${l.text}');
    }
    return b.toString();
  }

  static final _patterns = <(RegExp, String)>[
    (RegExp(r'/(live|movie|series)/[^/\s]+/[^/\s]+/', caseSensitive: false), r'/$1/***/***/'),
    (RegExp(r'(username|password)=[^&\s"]+', caseSensitive: false), r'$1=***'),
    (RegExp(r'://[^/\s:@]+:[^/\s@]+@'), '://***:***@'),
  ];

  static String redact(String text) {
    var result = text;
    for (final (re, template) in _patterns) {
      result = result.replaceAllMapped(re, (m) {
        var out = template;
        for (var i = 1; i <= m.groupCount; i++) {
          out = out.replaceAll('\$$i', m.group(i) ?? '');
        }
        return out;
      });
    }
    return result;
  }
}
