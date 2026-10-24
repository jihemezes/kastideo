import 'package:flutter/foundation.dart';

/// Ligne du journal de lecture.
class LogLine {
  LogLine(this.date, this.level, this.text);
  final DateTime date;

  /// 0 erreur, 1 alerte, 2 info.
  final int level;
  final String text;

  String get levelLabel => switch (level) { 0 => 'ERREUR', 1 => 'ALERTE', _ => 'info' };
}

/// Journal de lecture (300 dernières lignes, identifiants masqués) — même rôle que sur Mac (⌥⌘L / Ctrl+Alt+L).
class PlaybackLog extends ChangeNotifier {
  PlaybackLog._();
  static final PlaybackLog shared = PlaybackLog._();

  final List<LogLine> _lines = [];
  static const _capacity = 300;
  List<LogLine> get lines => List.unmodifiable(_lines);

  void note(String message) => _add(2, '[kastideo] $message');
  void engine(String message, {int level = 1}) => _add(level, '[mpv] $message');

  void _add(int level, String text) {
    _lines.add(LogLine(DateTime.now(), level, redact(text)));
    if (_lines.length > _capacity) _lines.removeRange(0, _lines.length - _capacity);
    notifyListeners();
  }

  /// Dernière erreur depuis une date (affichée à l'utilisateur).
  String? lastError(DateTime since) {
    for (final line in _lines.reversed) {
      if (line.date.isBefore(since)) break;
      if (line.level == 0) return line.text;
    }
    return null;
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  String export(String version) {
    final b = StringBuffer('Kastideo $version — journal de lecture (identifiants masqués)\n');
    for (final l in _lines) {
      final t = l.date;
      String two(int v) => v.toString().padLeft(2, '0');
      b.writeln('${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')} ${l.levelLabel} ${l.text}');
    }
    return b.toString();
  }

  static final _patterns = <(RegExp, String)>[
    (RegExp(r'/(live|movie|series)/[^/\s]+/[^/\s]+/', caseSensitive: false), r'/$1/***/***/'),
    (RegExp(r'(username|password)=[^&\s"]+', caseSensitive: false), r'$1=***'),
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
