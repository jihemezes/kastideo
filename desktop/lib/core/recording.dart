import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'epg.dart';
import 'library.dart';
import 'log.dart';
import 'models.dart';
import 'paths.dart';
import 'playback.dart';
import 'settings.dart';
import 'xtream.dart';

enum ScheduleStatus { scheduled, recording, done, failed, missed }

/// Enregistrement programmé depuis le guide TV.
class ScheduledRecording {
  ScheduledRecording({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.title,
    required this.startS,
    required this.stopS,
    this.status = ScheduleStatus.scheduled,
    this.path,
    this.error,
  });

  final String id;
  final String channelId;
  final String channelName;
  final String title;
  final int startS;
  final int stopS;
  ScheduleStatus status;
  String? path;
  String? error;

  DateTime get start => DateTime.fromMillisecondsSinceEpoch(startS * 1000);
  DateTime get stop => DateTime.fromMillisecondsSinceEpoch(stopS * 1000);

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel': channelId,
        'channelName': channelName,
        'title': title,
        'start': startS,
        'stop': stopS,
        'status': status.name,
        'path': ?path,
        'error': ?error,
      };

  static ScheduledRecording fromJson(Map<String, dynamic> j) => ScheduledRecording(
        id: j['id'] as String,
        channelId: j['channel'] as String,
        channelName: j['channelName'] as String? ?? '',
        title: j['title'] as String? ?? '',
        startS: j['start'] as int,
        stopS: j['stop'] as int,
        status: ScheduleStatus.values.where((s) => s.name == j['status']).firstOrNull ?? ScheduleStatus.scheduled,
        path: j['path'] as String?,
        error: j['error'] as String?,
      );
}

/// Enregistrement en cours (un seul à la fois : l'abonnement n'a qu'une connexion).
class ActiveRecording {
  ActiveRecording({required this.channel, required this.title, required this.path, required this.viaPlayer, this.stopS, this.scheduleId});
  final MediaItem channel;
  final String title;
  String path;
  final bool viaPlayer;
  final int? stopS;
  final String? scheduleId;
  final DateTime startedAt = DateTime.now();
  int bytes = 0;
}

/// Fichier vidéo du dossier Kastideo (enregistrements et téléchargements terminés).
class RecordedFile {
  RecordedFile(this.path, this.size, this.modified);
  final String path;
  final int size;
  final DateTime modified;
  String get name => path.split(Platform.pathSeparator).last;
}

/// Enregistrement du direct (immédiat ou programmé), comme RecordingCenter sur Mac.
/// La chaîne regardée est enregistrée par le lecteur (option « stream-record » de mpv) ; une autre chaîne,
/// ou une chaîne programmée sans lecture en cours, par un second lecteur sans image ni son.
class RecordingCenter extends ChangeNotifier {
  RecordingCenter(this.settings, this.playback, this.library);
  final AppSettings settings;
  final PlaybackController playback;
  final LibraryStore library;

  final List<ScheduledRecording> schedules = [];
  ActiveRecording? active;
  List<RecordedFile> files = [];

  /// Message bref affiché dans l'application (début / fin d'enregistrement, conflit).
  String? notice;
  late SharedPreferences _prefs;
  Player? _recorder;
  Timer? _ticker;
  Timer? _sizeTimer;
  Timer? _noticeTimer;

  String get folder => kastideoFolder(settings.recordingsFolder);

  Future<void> start() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString('recordings.schedule.v1');
    if (raw != null) {
      try {
        schedules.addAll([for (final e in jsonDecode(raw) as List) ScheduledRecording.fromJson(Map<String, dynamic>.from(e as Map))]);
      } catch (_) {}
    }
    // Ceux qui étaient en cours quand l'application a été fermée.
    for (final s in schedules.where((s) => s.status == ScheduleStatus.recording)) {
      s.status = ScheduleStatus.failed;
      s.error = 'Kastideo a été fermé pendant l\'enregistrement.';
    }
    playback.addListener(_playbackChanged);
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
    _tick();
    unawaited(scanFiles());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sizeTimer?.cancel();
    playback.removeListener(_playbackChanged);
    super.dispose();
  }

  void _save() => _prefs.setString('recordings.schedule.v1', jsonEncode([for (final s in schedules) s.toJson()]));

  void _say(String text) {
    notice = text;
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 6), () {
      notice = null;
      notifyListeners();
    });
    notifyListeners();
  }

  bool isRecording(MediaItem item) => active?.channel.id == item.id;

  bool isScheduled(MediaItem channel, Programme p) =>
      schedules.any((s) => s.channelId == channel.id && s.startS == p.startS && s.status == ScheduleStatus.scheduled);

  /// Lancer [item] couperait l'enregistrement en cours (autre chaîne, film, épisode).
  bool conflictsWith(MediaItem item) {
    final a = active;
    if (a == null) return false;
    if (item.kind == MediaKind.live && item.id == a.channel.id) return !a.viaPlayer;
    return item.stream != null && !(item.stream!.startsWith('/') || item.stream!.contains(':\\'));
  }

  // MARK: Enregistrement

  String _newPath(MediaItem channel, String title, {String? format}) {
    final now = DateTime.now();
    final ext = format ?? settings.recordingFormat;
    final stamp = '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}h${two(now.minute)}';
    final label = title.isEmpty || title == channel.displayName ? channel.displayName : '${channel.displayName} - $title';
    final sep = Platform.pathSeparator;
    return '$folder${sep}Enregistrements$sep${safeFileName('$label - $stamp')}.$ext';
  }

  /// Enregistre une chaîne maintenant (jusqu'à [stopS] si donné, sinon jusqu'à l'arrêt).
  Future<bool> recordNow(MediaItem channel, {String title = '', int? stopS, String? scheduleId}) async {
    if (active != null) {
      if (active!.channel.id == channel.id) return true;
      await stop();
    }
    final path = _newPath(channel, title);
    try {
      await Directory(File(path).parent.path).create(recursive: true);
    } catch (e) {
      _say('Dossier des enregistrements inaccessible : $e');
      return false;
    }
    final viaPlayer = playback.current?.id == channel.id;
    try {
      if (viaPlayer) {
        final native = playback.player.platform;
        if (native is! NativePlayer) return false;
        await native.setProperty('stream-record', path);
      } else {
        if (playback.current != null) {
          // Une seule connexion : la lecture en cours laisse la place à l'enregistrement.
          await playback.stop();
          _say('Lecture arrêtée : l\'enregistrement de ${channel.displayName} utilise la connexion de l\'abonnement.');
        }
        await _startRecorder(channel, path);
      }
    } catch (e) {
      _say('Enregistrement impossible : $e');
      PlaybackLog.shared.note('Enregistrement impossible : $e');
      return false;
    }
    active = ActiveRecording(channel: channel, title: title, path: path, viaPlayer: viaPlayer, stopS: stopS, scheduleId: scheduleId);
    PlaybackLog.shared.note('Enregistrement de « ${channel.name} » ${viaPlayer ? 'par le lecteur' : 'en arrière-plan'} : $path');
    _say('Enregistrement de ${channel.displayName} commencé.');
    _watchSize();
    notifyListeners();
    return true;
  }

  Future<void> _startRecorder(MediaItem channel, String path) async {
    final player = _recorder ??= Player(
      configuration: const PlayerConfiguration(title: 'Kastideo', vo: 'null', muted: true, logLevel: MPVLogLevel.warn),
    );
    final native = player.platform;
    if (native is NativePlayer) {
      await native.setProperty('ao', 'null');
      // Sans lecteur vidéo attaché, media_kit désactive la piste vidéo : on la réactive pour l'enregistrer.
      await native.setProperty('vid', 'auto');
      await native.setProperty('user-agent', kUserAgent);
      await native.setProperty('network-timeout', '30');
      // L'image n'est pas décodée : le flux est seulement recopié dans le fichier.
      await native.setProperty('vd-lavc-skipframe', 'all');
      await native.setProperty('stream-lavf-o', 'reconnect=1,reconnect_streamed=1,reconnect_delay_max=10');
      await native.setProperty('stream-record', path);
    }
    await player.open(Media(channel.stream!, httpHeaders: const {'User-Agent': kUserAgent}), play: true);
  }

  /// Vérifie que le fichier grossit ; sinon (format refusé par le multiplexeur) repasse en .ts.
  void _watchSize() {
    _sizeTimer?.cancel();
    var checks = 0;
    _sizeTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final a = active;
      if (a == null) return;
      checks++;
      final f = File(a.path);
      final size = await f.exists() ? await f.length() : 0;
      a.bytes = size;
      notifyListeners();
      if (checks == 5 && size == 0 && a.path.endsWith('.mkv')) {
        PlaybackLog.shared.note('Enregistrement : fichier MKV vide après 25 s, nouvel essai en .ts');
        final path = _newPath(a.channel, a.title, format: 'ts');
        a.path = path;
        final native = (a.viaPlayer ? playback.player : _recorder)?.platform;
        if (native is NativePlayer) {
          await native.setProperty('stream-record', '');
          await native.setProperty('stream-record', path);
        }
      }
    });
  }

  /// Regarder la chaîne enregistrée en arrière-plan : l'enregistrement passe dans le lecteur (une seule connexion).
  Future<void> moveToPlayer() async {
    final a = active;
    if (a == null || a.viaPlayer) return;
    active = null;
    _sizeTimer?.cancel();
    try {
      final native = _recorder?.platform;
      if (native is NativePlayer) await native.setProperty('stream-record', '');
      await _recorder?.stop();
    } catch (_) {}
    playback.play(a.channel);
    final path = _newPath(a.channel, a.title);
    final native = playback.player.platform;
    if (native is NativePlayer) await native.setProperty('stream-record', path);
    active = ActiveRecording(channel: a.channel, title: a.title, path: path, viaPlayer: true, stopS: a.stopS, scheduleId: a.scheduleId);
    PlaybackLog.shared.note('Enregistrement de « ${a.channel.name} » poursuivi par le lecteur : $path');
    _watchSize();
    notifyListeners();
  }

  /// Arrête l'enregistrement en cours.
  Future<void> stop({bool failed = false, String? error}) async {
    final a = active;
    if (a == null) return;
    active = null;
    _sizeTimer?.cancel();
    try {
      if (a.viaPlayer) {
        final native = playback.player.platform;
        if (native is NativePlayer) await native.setProperty('stream-record', '');
      } else {
        final native = _recorder?.platform;
        if (native is NativePlayer) await native.setProperty('stream-record', '');
        await _recorder?.stop();
      }
    } catch (_) {}
    final f = File(a.path);
    final size = await f.exists() ? await f.length() : 0;
    final ok = !failed && size > 0;
    if (a.scheduleId != null) {
      final s = schedules.where((s) => s.id == a.scheduleId).firstOrNull;
      if (s != null) {
        s
          ..status = ok ? ScheduleStatus.done : ScheduleStatus.failed
          ..path = a.path
          ..error = ok ? null : (error ?? 'Aucune donnée reçue du fournisseur.');
        _save();
      }
    }
    PlaybackLog.shared.note('Enregistrement arrêté (${sizeText(size)}) : ${a.path}');
    _say(ok ? 'Enregistrement terminé : ${f.uri.pathSegments.last} (${sizeText(size)})' : 'Enregistrement sans données : ${error ?? 'le fournisseur n\'a rien envoyé.'}');
    notifyListeners();
    unawaited(scanFiles());
  }

  /// La lecture change de chaîne pendant un enregistrement fait par le lecteur : il s'arrête proprement.
  void _playbackChanged() {
    final a = active;
    if (a != null && a.viaPlayer && playback.current?.id != a.channel.id) {
      stop();
    }
  }

  // MARK: Programmation

  void schedule(MediaItem channel, Programme p) {
    if (isScheduled(channel, p)) return;
    schedules.add(ScheduledRecording(
      id: '${channel.id}|${p.startS}',
      channelId: channel.id,
      channelName: channel.displayName,
      title: p.title,
      startS: p.startS,
      stopS: p.stopS,
    ));
    schedules.sort((a, b) => a.startS.compareTo(b.startS));
    _save();
    _say('Enregistrement programmé : ${p.title}');
    notifyListeners();
  }

  void cancel(ScheduledRecording s) {
    if (s.status == ScheduleStatus.recording && active?.scheduleId == s.id) stop();
    schedules.remove(s);
    _save();
    notifyListeners();
  }

  void clearFinishedSchedules() {
    schedules.removeWhere((s) => s.status != ScheduleStatus.scheduled && s.status != ScheduleStatus.recording);
    _save();
    notifyListeners();
  }

  Future<void> _tick() async {
    final now = nowSeconds();
    final a = active;
    if (a?.stopS != null && now >= a!.stopS!) await stop();
    var changed = false;
    for (final s in schedules) {
      if (s.status != ScheduleStatus.scheduled) continue;
      final from = s.startS - settings.marginBefore * 60;
      final to = s.stopS + settings.marginAfter * 60;
      if (now >= to) {
        s
          ..status = ScheduleStatus.missed
          ..error = 'Kastideo n\'était pas ouvert à l\'heure prévue.';
        changed = true;
      } else if (now >= from && active == null) {
        final channel = library.item(s.channelId);
        if (channel == null) {
          // Sources pas encore chargées (démarrage, actualisation) : nouvel essai au prochain passage.
          if (now >= s.stopS) {
            s
              ..status = ScheduleStatus.failed
              ..error = 'Chaîne introuvable dans vos sources.';
            changed = true;
          }
          continue;
        }
        s.status = ScheduleStatus.recording;
        changed = true;
        final ok = await recordNow(channel, title: s.title, stopS: to, scheduleId: s.id);
        if (!ok) {
          s
            ..status = ScheduleStatus.failed
            ..error = notice;
        }
      }
    }
    if (changed) {
      _save();
      notifyListeners();
    }
  }

  // MARK: Fichiers

  static const _videoExtensions = {'mkv', 'ts', 'mp4', 'm4v', 'avi', 'mov', 'webm', 'mpg', 'mpeg'};

  Future<void> scanFiles() async {
    final dir = Directory(folder);
    final result = <RecordedFile>[];
    try {
      if (await dir.exists()) {
        await for (final e in dir.list(recursive: true, followLinks: false)) {
          if (e is! File) continue;
          final ext = e.path.split('.').last.toLowerCase();
          if (!_videoExtensions.contains(ext)) continue;
          final stat = await e.stat();
          result.add(RecordedFile(e.path, stat.size, stat.modified));
        }
      }
    } catch (_) {}
    result.sort((a, b) => b.modified.compareTo(a.modified));
    files = result;
    notifyListeners();
  }

  Future<void> deleteFile(RecordedFile f) async {
    try {
      await File(f.path).delete();
    } catch (_) {}
    await scanFiles();
  }

  Future<void> shutdown() async {
    if (active != null) await stop();
    try {
      await _recorder?.dispose().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
