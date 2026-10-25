import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'epg.dart';
import 'guide.dart';
import 'library.dart';
import 'models.dart';
import 'settings.dart';
import 'text.dart';

/// Alerte déclenchée : le programme commence.
class FiredAlert {
  FiredAlert(this.channel, this.programme);
  final MediaItem channel;
  final Programme programme;
}

/// Alertes de programme (comme ProgramAlertCenter sur Mac) : un programme précis (« M'alerter au début »)
/// ou des mots-clés cherchés dans les titres du guide (chaînes favorites ou toutes).
class AlertCenter extends ChangeNotifier {
  AlertCenter(this.settings, this.library, this.guide);
  final AppSettings settings;
  final LibraryStore library;
  final GuideStore guide;

  late SharedPreferences _prefs;

  /// Programmes surveillés : « idChaîne|début » → titre.
  final Map<String, String> _oneShots = {};
  final Set<String> _fired = {};
  final List<FiredAlert> pending = [];
  Timer? _ticker;

  Future<void> start() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString('alerts.oneshot.v1');
    if (raw != null) {
      try {
        _oneShots.addAll(Map<String, String>.from(jsonDecode(raw) as Map));
      } catch (_) {}
    }
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _key(MediaItem channel, Programme p) => '${channel.id}|${p.startS}';

  bool isWatching(MediaItem channel, Programme p) => _oneShots.containsKey(_key(channel, p));

  void toggle(MediaItem channel, Programme p) {
    final k = _key(channel, p);
    if (_oneShots.remove(k) == null) _oneShots[k] = p.title;
    _save();
    notifyListeners();
  }

  int get watchedCount => _oneShots.length;

  void _save() => _prefs.setString('alerts.oneshot.v1', jsonEncode(_oneShots));

  void dismiss(FiredAlert a) {
    pending.remove(a);
    notifyListeners();
  }

  void _check() {
    final now = nowSeconds();
    final lead = settings.alertLead * 60;
    var changed = false;
    // Alertes ponctuelles.
    for (final entry in Map.of(_oneShots).entries) {
      final parts = entry.key.split('|');
      final start = int.tryParse(parts.last) ?? 0;
      if (start + 600 < now) {
        _oneShots.remove(entry.key);
        changed = true;
        continue;
      }
      if (start - lead <= now && !_fired.contains(entry.key)) {
        final channel = library.item(parts.sublist(0, parts.length - 1).join('|'));
        final p = channel == null ? null : guide.programmesOf(channel).where((p) => p.startS == start).firstOrNull;
        _fired.add(entry.key);
        _oneShots.remove(entry.key);
        changed = true;
        if (channel != null && p != null) pending.add(FiredAlert(channel, p));
      }
    }
    // Mots-clés.
    final keywords = [for (final k in settings.alertKeywords) if (k.trim().isNotEmpty) k.searchKey];
    if (keywords.isNotEmpty) {
      final channels = settings.alertScope == 'all'
          ? [for (final g in guide.groups) g.preferred]
          : library.favoritesOf(MediaKind.live);
      for (final channel in channels) {
        for (final p in guide.programmesOf(channel)) {
          if (p.startS > now + lead) break;
          if (p.startS < now - 60 || p.startS - lead > now) continue;
          final key = _key(channel, p);
          if (_fired.contains(key)) continue;
          final title = p.title.searchKey;
          if (keywords.any(title.contains)) {
            _fired.add(key);
            pending.add(FiredAlert(channel, p));
            changed = true;
          }
        }
      }
    }
    if (changed) {
      _save();
      notifyListeners();
    }
  }
}
