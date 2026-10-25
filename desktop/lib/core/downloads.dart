import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import 'log.dart';
import 'notify.dart';
import 'models.dart';
import 'paths.dart';
import 'playback.dart';
import 'settings.dart';
import 'xtream.dart';

enum DownloadStatus { queued, running, done, failed, paused }

/// Un film ou un épisode à télécharger.
class DownloadTask {
  DownloadTask({
    required this.id,
    required this.name,
    required this.url,
    required this.path,
    this.group = '',
    this.status = DownloadStatus.queued,
    this.received = 0,
    this.total,
    this.nightOnly = false,
    this.error,
  });

  final String id;
  final String name;
  final String group;
  final String url;
  final String path;
  DownloadStatus status;
  int received;
  int? total;
  bool nightOnly;
  String? error;

  /// Vitesse (octets/s) et temps restant estimé, pendant le téléchargement.
  double speed = 0;

  double? get fraction => total == null || total == 0 ? null : (received / total!).clamp(0.0, 1.0);
  Duration? get remaining => total == null || speed < 1 ? null : Duration(seconds: ((total! - received) / speed).round());

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'group': group,
        'url': url,
        'path': path,
        'status': status == DownloadStatus.running ? DownloadStatus.queued.name : status.name,
        'received': received,
        'total': ?total,
        'night': nightOnly,
        'error': ?error,
      };

  static DownloadTask fromJson(Map<String, dynamic> j) => DownloadTask(
        id: j['id'] as String,
        name: j['name'] as String,
        group: j['group'] as String? ?? '',
        url: j['url'] as String,
        path: j['path'] as String,
        status: DownloadStatus.values.where((s) => s.name == j['status']).firstOrNull ?? DownloadStatus.queued,
        received: j['received'] as int? ?? 0,
        total: j['total'] as int?,
        nightOnly: j['night'] as bool? ?? false,
        error: j['error'] as String?,
      );
}

/// File de téléchargements (un à la fois, reprise après coupure, option « cette nuit »), comme sur Mac.
class DownloadManager extends ChangeNotifier {
  DownloadManager(this.settings, this.playback);
  final AppSettings settings;
  final PlaybackController playback;

  final List<DownloadTask> tasks = [];
  late SharedPreferences _prefs;
  HttpClient? _client;
  DownloadTask? _running;
  Timer? _pump;
  bool _cancelRequested = false;

  /// Raison de l'attente de la file : « playback » (lecture en cours) ou « night » (prévu cette nuit).
  String? waitingReason;

  Future<void> start() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString('downloads.v1');
    if (raw != null) {
      try {
        tasks.addAll([for (final e in jsonDecode(raw) as List) DownloadTask.fromJson(Map<String, dynamic>.from(e as Map))]);
      } catch (_) {}
    }
    playback.addListener(_playbackChanged);
    _pump = Timer.periodic(const Duration(seconds: 30), (_) => _next());
    _next();
  }

  @override
  void dispose() {
    _pump?.cancel();
    playback.removeListener(_playbackChanged);
    super.dispose();
  }

  void _save() => _prefs.setString('downloads.v1', jsonEncode([for (final t in tasks) t.toJson()]));

  bool get isActive => _running != null;
  DownloadTask? get running => _running;
  int get pendingCount => tasks.where((t) => t.status == DownloadStatus.queued || t.status == DownloadStatus.running).length;
  bool contains(String id) => tasks.any((t) => t.id == id && t.status != DownloadStatus.failed);
  DownloadTask? task(String id) => tasks.where((t) => t.id == id).firstOrNull;

  bool get _inNight {
    final h = DateTime.now().hour;
    final start = settings.nightHour;
    return ((h - start) % 24 + 24) % 24 < 6;
  }

  bool get _blockedByPlayback => settings.pauseDownloadsDuringPlayback && playback.current != null;

  void _playbackChanged() {
    if (_running != null && _blockedByPlayback) {
      PlaybackLog.shared.note('Téléchargement mis en pause pendant la lecture');
      _cancelRequested = true;
      _client?.close(force: true);
    } else if (_running == null && !_blockedByPlayback) {
      _next();
    }
  }

  /// Ajoute un film ou un épisode à la file.
  void enqueue(MediaItem item, {int? season, bool nightOnly = false}) {
    final url = item.stream;
    if (url == null || contains(item.id)) return;
    final root = kastideoFolder(settings.recordingsFolder);
    final sep = Platform.pathSeparator;
    final ext = extensionOf(url);
    final String path;
    if (item.kind == MediaKind.episode) {
      final s = season == null ? '' : 'S${two(season)}';
      final e = item.number == null ? '' : 'E${two(item.number!)}';
      final prefix = '$s$e'.isEmpty ? '' : '$s$e - ';
      path = '$root${sep}Séries$sep${safeFileName(item.group)}$sep${safeFileName('$prefix${item.name}')}.$ext';
    } else {
      path = '$root${sep}Films$sep${safeFileName(item.displayName)}.$ext';
    }
    tasks.removeWhere((t) => t.id == item.id);
    tasks.add(DownloadTask(id: item.id, name: item.kind == MediaKind.episode ? item.name : item.displayName, group: item.group, url: url, path: path, nightOnly: nightOnly));
    _save();
    notifyListeners();
    _next();
  }

  void pause(DownloadTask t) {
    if (t == _running) {
      _cancelRequested = true;
      _client?.close(force: true);
    }
    t.status = DownloadStatus.paused;
    _save();
    notifyListeners();
  }

  void resume(DownloadTask t) {
    t
      ..status = DownloadStatus.queued
      ..error = null
      ..nightOnly = false;
    _save();
    notifyListeners();
    _next();
  }

  void remove(DownloadTask t, {bool deleteFile = false}) {
    if (t == _running) {
      _cancelRequested = true;
      _client?.close(force: true);
    }
    tasks.remove(t);
    try {
      final part = File('${t.path}.part');
      if (part.existsSync()) part.deleteSync();
      if (deleteFile && File(t.path).existsSync()) File(t.path).deleteSync();
    } catch (_) {}
    _save();
    notifyListeners();
  }

  void clearFinished() {
    tasks.removeWhere((t) => t.status == DownloadStatus.done);
    _save();
    notifyListeners();
  }

  void _next() {
    if (_running != null) return;
    final candidates = tasks.where((t) => t.status == DownloadStatus.queued).toList();
    if (candidates.isEmpty) {
      waitingReason = null;
      notifyListeners();
      return;
    }
    if (_blockedByPlayback) {
      waitingReason = 'playback';
      notifyListeners();
      return;
    }
    final task = candidates.where((t) => !t.nightOnly || _inNight).firstOrNull;
    if (task == null) {
      waitingReason = 'night';
      notifyListeners();
      return;
    }
    waitingReason = null;
    _download(task);
  }

  Future<void> _download(DownloadTask t) async {
    _running = t;
    _cancelRequested = false;
    t
      ..status = DownloadStatus.running
      ..error = null
      ..speed = 0;
    notifyListeners();
    final part = File('${t.path}.part');
    final client = HttpClient()
      ..userAgent = kUserAgent
      ..connectionTimeout = const Duration(seconds: 20);
    _client = client;
    try {
      await part.parent.create(recursive: true);
      final existing = await part.exists() ? await part.length() : 0;
      final request = await client.getUrl(Uri.parse(t.url));
      request.headers.set(HttpHeaders.acceptHeader, '*/*');
      if (existing > 0) request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existing-');
      final response = await request.close();
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw HttpException('code HTTP ${response.statusCode}');
      }
      final resumed = response.statusCode == 206;
      t.received = resumed ? existing : 0;
      final length = response.contentLength;
      t.total = length > 0 ? (resumed ? existing + length : length) : t.total;
      final sink = part.openWrite(mode: resumed ? FileMode.append : FileMode.write);
      var lastTick = DateTime.now();
      var lastBytes = t.received;
      PlaybackLog.shared.note('Téléchargement de « ${t.name} »${resumed ? ' (reprise à ${sizeText(existing)})' : ''}');
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          t.received += chunk.length;
          final now = DateTime.now();
          final dt = now.difference(lastTick).inMilliseconds;
          if (dt >= 1000) {
            final instant = (t.received - lastBytes) * 1000 / dt;
            t.speed = t.speed == 0 ? instant : t.speed * 0.7 + instant * 0.3;
            lastTick = now;
            lastBytes = t.received;
            notifyListeners();
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
      if (t.total != null && t.received < t.total!) throw const HttpException('connexion interrompue');
      final target = File(t.path);
      if (await target.exists()) await target.delete();
      await part.rename(t.path);
      t
        ..status = DownloadStatus.done
        ..speed = 0;
      PlaybackLog.shared.note('Téléchargement terminé : ${t.path}');
      SystemNotifier.show(tr('Téléchargement terminé'), t.group.isEmpty ? t.name : '${t.group} · ${t.name}');
    } catch (e) {
      if (_cancelRequested) {
        if (t.status == DownloadStatus.running) t.status = DownloadStatus.queued;
      } else {
        t
          ..status = DownloadStatus.failed
          ..error = '$e';
        PlaybackLog.shared.note('Téléchargement de « ${t.name} » impossible : $e');
        SystemNotifier.show(tr('Téléchargement impossible'), '${t.name} : $e');
      }
      t.speed = 0;
    } finally {
      client.close(force: true);
      _client = null;
      _running = null;
      _save();
      notifyListeners();
      if (!_cancelRequested || !_blockedByPlayback) Timer(const Duration(seconds: 2), _next);
    }
  }
}
