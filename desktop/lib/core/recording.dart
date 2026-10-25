import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'epg.dart';
import 'library.dart';
import 'log.dart';
import 'notify.dart';
import 'models.dart';
import 'paths.dart';
import 'playback.dart';
import 'relay.dart';
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
/// Les octets du flux sont recopiés tels quels dans un fichier .ts, sans passer par le moteur vidéo :
/// - la chaîne regardée : copie de ce que reçoit le relais (aucune seconde connexion au fournisseur) ;
/// - une autre chaîne : téléchargement direct du flux, avec reconnexion s'il est coupé.
/// À la fin, le .ts est converti sans perte en MKV si ce format est choisi (sinon, ou en cas d'échec, le .ts reste).
/// Les flux HLS (.m3u8) et la lecture sans relais passent encore par mpv (option « stream-record »).
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
  HttpClient? _http;
  IOSink? _sink;
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

  void _say(String text, {bool system = false}) {
    if (system) SystemNotifier.show('Kastideo', text);
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
    final ext = format ?? 'ts';
    final stamp = '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}h${two(now.minute)}';
    final label = title.isEmpty || title == channel.displayName ? channel.displayName : '${channel.displayName} - $title';
    final sep = Platform.pathSeparator;
    return '$folder${sep}Enregistrements$sep${safeFileName('$label - $stamp')}.$ext';
  }

  static bool _isHls(String url) => Uri.tryParse(url)?.path.toLowerCase().endsWith('.m3u8') ?? false;

  /// La chaîne regardée passe par le relais : ses octets peuvent être recopiés.
  bool _relayed(MediaItem channel) {
    final relayed = StreamRelay.shared.relayedUrl;
    final url = channel.stream;
    return relayed != null && url != null && relayed == Uri.tryParse(url)?.toString();
  }

  void _write(ActiveRecording a, List<int> chunk) {
    if (!identical(active, a)) return;
    _sink?.add(chunk);
    a.bytes += chunk.length;
  }

  Future<void> _openSink(String path) async {
    await _closeSink();
    _sink = File(path).openWrite(mode: FileMode.append);
  }

  Future<void> _closeSink() async {
    final sink = _sink;
    _sink = null;
    if (sink == null) return;
    try {
      await sink.flush();
      await sink.close();
    } catch (_) {}
  }

  /// Enregistre une chaîne maintenant (jusqu'à [stopS] si donné, sinon jusqu'à l'arrêt).
  Future<bool> recordNow(MediaItem channel, {String title = '', int? stopS, String? scheduleId}) async {
    if (active != null) {
      if (active!.channel.id == channel.id) return true;
      await stop();
    }
    final url = channel.stream;
    if (url == null) return false;
    final path = _newPath(channel, title);
    try {
      await Directory(File(path).parent.path).create(recursive: true);
    } catch (e) {
      _say('Dossier des enregistrements inaccessible : $e');
      return false;
    }
    final viaPlayer = playback.current?.id == channel.id;
    final a = ActiveRecording(channel: channel, title: title, path: path, viaPlayer: viaPlayer, stopS: stopS, scheduleId: scheduleId);
    String how;
    try {
      if (viaPlayer && _relayed(channel)) {
        await _openSink(path);
        active = a;
        StreamRelay.shared.tap = (chunk) => _write(a, chunk);
        how = 'copie du flux relayé';
      } else if (viaPlayer) {
        final native = playback.player.platform;
        if (native is! NativePlayer) return false;
        await native.setProperty('stream-record', path);
        active = a;
        how = 'par le lecteur (stream-record)';
      } else {
        if (playback.current != null && settings.multiviewConnections < 2) {
          // Une seule connexion : la lecture en cours laisse la place à l'enregistrement.
          await playback.stop();
          _say('Lecture arrêtée : l\'enregistrement de ${channel.displayName} utilise la connexion de l\'abonnement.');
        }
        active = a;
        if (_isHls(url)) {
          await _startRecorder(channel, path);
          how = 'en arrière-plan (mpv, flux HLS)';
        } else {
          await _openSink(path);
          unawaited(_directLoop(a, url));
          how = 'en arrière-plan (téléchargement direct)';
        }
      }
    } catch (e) {
      active = null;
      await _closeSink();
      _say('Enregistrement impossible : $e', system: true);
      PlaybackLog.shared.note('Enregistrement impossible : $e');
      return false;
    }
    PlaybackLog.shared.note('Enregistrement de « ${channel.name} » $how : $path');
    _say('Enregistrement de ${channel.displayName} commencé.', system: true);
    _watchSize();
    notifyListeners();
    return true;
  }

  /// Téléchargement direct du flux (autre chaîne que celle regardée), avec reconnexion s'il est coupé.
  Future<void> _directLoop(ActiveRecording a, String url) async {
    var failures = 0;
    String? lastError;
    while (identical(active, a)) {
      final client = HttpClient()
        ..userAgent = kUserAgent
        ..connectionTimeout = const Duration(seconds: 20);
      _http = client;
      try {
        final request = await client.getUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.acceptHeader, '*/*');
        request.followRedirects = true;
        request.maxRedirects = 5;
        final response = await request.close();
        PlaybackLog.shared.note('Enregistrement : réponse du fournisseur HTTP ${response.statusCode}');
        if (response.statusCode < 200 || response.statusCode >= 300) {
          lastError = 'le fournisseur refuse la chaîne (HTTP ${response.statusCode})';
          failures++;
          await response.drain<void>().catchError((_) {});
        } else {
          await for (final chunk in response) {
            if (!identical(active, a)) break;
            _write(a, chunk);
            failures = 0;
          }
          if (identical(active, a)) {
            PlaybackLog.shared.note('Enregistrement : le fournisseur a coupé le flux, reconnexion');
            lastError = 'le fournisseur a coupé le flux';
            failures++;
          }
        }
      } catch (e) {
        if (!identical(active, a)) break;
        lastError = '$e';
        failures++;
        PlaybackLog.shared.note('Enregistrement : connexion interrompue ($e)');
      } finally {
        client.close(force: true);
        if (identical(_http, client)) _http = null;
      }
      if (!identical(active, a)) break;
      if (failures >= 5 && a.bytes == 0) {
        await stop(failed: true, error: lastError);
        break;
      }
      await Future<void>.delayed(Duration(seconds: failures.clamp(1, 10)));
    }
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

  /// Taille du fichier, affichée pendant l'enregistrement ; journal si rien n'arrive.
  void _watchSize() {
    _sizeTimer?.cancel();
    var checks = 0;
    _sizeTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final a = active;
      if (a == null) return;
      checks++;
      if (_sink == null) {
        // Enregistrement fait par mpv : taille lue sur le disque.
        final f = File(a.path);
        a.bytes = await f.exists() ? await f.length() : 0;
      }
      if (checks == 6 && a.bytes == 0) {
        PlaybackLog.shared.note('Enregistrement : aucune donnée reçue après 30 s (le fournisseur n\'envoie rien sur cette connexion)');
      }
      notifyListeners();
    });
  }

  Future<void> _stopEngines(ActiveRecording a) async {
    StreamRelay.shared.tap = null;
    final http = _http;
    _http = null;
    http?.close(force: true);
    await _closeSink();
    try {
      if (a.viaPlayer) {
        final native = playback.player.platform;
        if (native is NativePlayer) await native.setProperty('stream-record', '');
      }
      final native = _recorder?.platform;
      if (native is NativePlayer) await native.setProperty('stream-record', '');
      await _recorder?.stop();
    } catch (_) {}
  }

  /// Regarder la chaîne enregistrée en arrière-plan : l'enregistrement passe dans le lecteur (une seule connexion).
  Future<void> moveToPlayer() async {
    final a = active;
    if (a == null || a.viaPlayer) return;
    active = null;
    _sizeTimer?.cancel();
    await _stopEngines(a);
    final path = _newPath(a.channel, a.title);
    final next = ActiveRecording(channel: a.channel, title: a.title, path: path, viaPlayer: true, stopS: a.stopS, scheduleId: a.scheduleId);
    final relay = settings.relayEnabled && !_isHls(a.channel.stream ?? '');
    if (relay) {
      // La copie commence dès que le relais reçoit les premiers octets de la nouvelle connexion.
      await _openSink(path);
      active = next;
      StreamRelay.shared.tap = (chunk) => _write(next, chunk);
      playback.play(a.channel);
    } else {
      playback.play(a.channel);
      final native = playback.player.platform;
      if (native is NativePlayer) await native.setProperty('stream-record', path);
      active = next;
    }
    PlaybackLog.shared.note('Enregistrement de « ${a.channel.name} » poursuivi par le lecteur : $path');
    unawaited(_finish(a.path));
    _watchSize();
    notifyListeners();
  }

  /// Arrête l'enregistrement en cours.
  Future<void> stop({bool failed = false, String? error}) async {
    final a = active;
    if (a == null) return;
    active = null;
    _sizeTimer?.cancel();
    await _stopEngines(a);
    final f = File(a.path);
    final size = await f.exists() ? await f.length() : 0;
    final ok = !failed && size > 0;
    if (!ok && size == 0) {
      try {
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
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
    _say(ok ? 'Enregistrement terminé : ${f.uri.pathSegments.last} (${sizeText(size)})' : 'Enregistrement sans données : ${error ?? 'le fournisseur n\'a rien envoyé.'}',
        system: true);
    notifyListeners();
    if (ok) {
      unawaited(_finish(a.path, scheduleId: a.scheduleId));
    } else {
      unawaited(scanFiles());
    }
  }

  // MARK: Conversion en MKV

  /// Conversions en cours (chemin du .ts).
  final Set<String> converting = {};

  /// Convertit le .ts en MKV sans perte si ce format est choisi ; le .ts reste en cas d'échec.
  Future<void> _finish(String path, {String? scheduleId}) async {
    if (settings.recordingFormat != 'mkv' || !path.toLowerCase().endsWith('.ts')) {
      await scanFiles();
      return;
    }
    final source = File(path);
    if (!await source.exists() || await source.length() == 0) {
      await scanFiles();
      return;
    }
    final target = '${path.substring(0, path.length - 3)}.mkv';
    converting.add(path);
    notifyListeners();
    final ok = await remuxToMkv(path, target);
    converting.remove(path);
    if (ok) {
      try {
        await source.delete();
      } catch (_) {}
      for (final s in schedules.where((s) => s.path == path)) {
        s.path = target;
      }
      _save();
      PlaybackLog.shared.note('Enregistrement converti en MKV : $target');
    } else {
      PlaybackLog.shared.note('Conversion en MKV impossible : le fichier .ts est gardé ($path)');
    }
    notifyListeners();
    await scanFiles();
  }

  /// Recopie les pistes d'un .ts dans un .mkv (sans réencodage) avec un lecteur mpv en pause, sans image ni son :
  /// son démultiplexeur lit tout le fichier dans son cache (sur disque) et l'option « stream-record » écrit
  /// chaque paquet lu. La fin est connue quand le cache signale la fin du fichier.
  static Future<bool> remuxToMkv(String input, String output) async {
    final player = Player(configuration: const PlayerConfiguration(title: 'Kastideo', vo: 'null', muted: true, logLevel: MPVLogLevel.warn));
    try {
      final native = player.platform;
      if (native is! NativePlayer) return false;
      final size = await File(input).length();
      await native.setProperty('ao', 'null');
      await native.setProperty('vid', 'auto');
      await native.setProperty('aid', 'auto');
      await native.setProperty('sid', 'auto');
      await native.setProperty('pause', 'yes');
      await native.setProperty('cache', 'yes');
      await native.setProperty('cache-on-disk', 'yes');
      await native.setProperty('cache-secs', '100000000');
      await native.setProperty('demuxer-readahead-secs', '100000000');
      await native.setProperty('demuxer-max-bytes', '${size + 64 * 1024 * 1024}');
      await native.setProperty('stream-record', output);
      await player.open(Media(input), play: false);
      // Au moins 2 min, puis environ 1 min par Go.
      final deadline = DateTime.now().add(Duration(seconds: 120 + size ~/ (1024 * 1024 * 1024) * 60));
      var ok = false;
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final state = await native.getProperty('demuxer-cache-state', waitForInitialization: false);
        if (RegExp(r'"eof"\s*:\s*true').hasMatch(state)) {
          ok = true;
          break;
        }
      }
      await native.setProperty('stream-record', '');
      await player.stop();
      final out = File(output);
      final outSize = await out.exists() ? await out.length() : 0;
      // Garde-fou : un MKV bien plus petit que le .ts est sans doute incomplet.
      if (!ok || outSize < size * 0.6) {
        PlaybackLog.shared.note('Conversion en MKV incomplète (${sizeText(outSize)} pour ${sizeText(size)})');
        try {
          if (await out.exists()) await out.delete();
        } catch (_) {}
        return false;
      }
      return true;
    } catch (e) {
      PlaybackLog.shared.note('Conversion en MKV : $e');
      return false;
    } finally {
      await player.dispose();
    }
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
