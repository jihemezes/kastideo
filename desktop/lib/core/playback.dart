import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'log.dart';
import 'models.dart';
import 'relay.dart';
import 'settings.dart';
import 'xtream.dart';

/// Santé du flux (pastille de couleur, comme sur Mac).
enum HealthLevel { unknown, poor, fair, good }

/// Lecteur unique (moteur mpv) : une seule connexion au fournisseur à la fois.
class PlaybackController extends ChangeNotifier {
  PlaybackController() {
    player = Player(
      configuration: const PlayerConfiguration(
        title: 'Kastideo',
        logLevel: MPVLogLevel.warn,
        bufferSize: 64 * 1024 * 1024,
      ),
    );
    video = VideoController(player);
    _subscriptions.addAll([
      player.stream.playing.listen((v) {
        isPlaying = v;
        notifyListeners();
      }),
      player.stream.buffering.listen((v) {
        isBuffering = v;
        if (v && didStart) _stalls.add(DateTime.now());
        _evaluateHealth();
      }),
      player.stream.height.listen((h) {
        videoHeight = h;
        if (h != null && h > 0) _markStarted();
        notifyListeners();
      }),
      player.stream.width.listen((w) => videoWidth = w),
      player.stream.position.listen((p) {
        position = p;
        if (p > Duration.zero) _markStarted();
        _trackProgress();
        if (!isLive) notifyListeners();
      }),
      player.stream.duration.listen((d) {
        duration = d;
        notifyListeners();
      }),
      player.stream.error.listen(_onError),
      player.stream.log.listen((log) {
        final level = log.level == 'error' || log.level == 'fatal' ? 0 : 1;
        PlaybackLog.shared.engine('[${log.prefix}] ${log.text.trim()}', level: level);
      }),
      player.stream.completed.listen((done) {
        if (!done) return;
        if (current?.kind == MediaKind.live) {
          errorMessage = 'Le flux s\'est interrompu. Le serveur a peut-être coupé la connexion.';
          notifyListeners();
        } else if (current != null) {
          watchProgress?.clear(current!.id); // film terminé : plus de reprise
        }
      }),
    ]);
    _prepare();
  }

  late final Player player;
  late final VideoController video;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  MediaItem? current;
  bool isPlaying = false;
  bool isBuffering = false;
  bool isLoading = false;
  bool didStart = false;
  String? errorMessage;
  Duration? startupTime;
  int? videoHeight;
  int? videoWidth;
  double volume = 100;
  bool muted = false;
  HealthLevel health = HealthLevel.unknown;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  /// Position à laquelle la lecture a repris (affichée quelques secondes).
  Duration? resumedAt;
  WatchProgressStore? watchProgress;
  AppSettings? settings;
  Duration? _pendingResume;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);

  final List<DateTime> _stalls = [];
  DateTime? _startedAt;
  DateTime? _closedAt;
  String? _currentUrl;
  int _retries = 0;
  Timer? _watchdog;
  Timer? _openTimer;
  Timer? _healthTimer;
  SharedPreferences? _prefs;

  /// Délai laissé au fournisseur pour libérer la connexion précédente (abonnement à une connexion).
  static const releaseDelay = Duration(milliseconds: 1500);
  static const startTimeout = Duration(seconds: 20);

  Future<void> _prepare() async {
    _prefs = await SharedPreferences.getInstance();
    volume = _prefs?.getDouble('volume') ?? 100;
    muted = _prefs?.getBool('muted') ?? false;
    await _applyVolume();
    final native = player.platform;
    if (native is NativePlayer) {
      await native.setProperty('user-agent', kUserAgent);
      await native.setProperty('network-timeout', '20');
      await native.setProperty('cache', 'yes');
      await native.setProperty('demuxer-readahead-secs', '2');
      await native.setProperty('hwdec', 'auto-safe');
      await native.setProperty('ytdl', 'no');
    }
    await applyCacheSettings();
    await StreamRelay.shared.start();
  }

  // MARK: Différé du direct (cache de mpv)

  /// Retard sur le direct (secondes) et plus grand retard de la séance (pour la barre de rattrapage).
  double liveDelay = 0;
  double peakDelay = 0;
  double rate = 1;
  bool _diskCache = false;
  Timer? _shiftTimer;
  double? _catchUpTarget;

  /// Le direct est en différé (en pause ou en retard de plus de 3 s).
  bool get isTimeshifted => isLive && didStart && (liveDelay > 4.5 || !isPlaying);

  /// Cache de mpv : sur disque si possible (différé jusqu'à la durée choisie), sinon limité en mémoire.
  Future<void> applyCacheSettings() async {
    final native = player.platform;
    if (native is! NativePlayer) return;
    final minutes = settings?.timeshiftMinutes ?? 60;
    await native.setProperty('cache-on-disk', 'yes');
    _diskCache = (await native.getProperty('cache-on-disk')) == 'yes';
    // Environ 1 Mo par seconde pour une chaîne HD ; sans cache disque, 512 Mo au plus en mémoire.
    final bytes = _diskCache ? minutes * 60 * 1024 * 1024 : 512 * 1024 * 1024;
    await native.setProperty('cache-secs', '${minutes * 60}');
    await native.setProperty('demuxer-max-bytes', '$bytes');
    await native.setProperty('demuxer-max-back-bytes', '$bytes');
    await native.setProperty('demuxer-seekable-cache', 'yes');
    // Un direct n'est pas « seekable » pour mpv : on autorise quand même le déplacement dans le cache.
    await native.setProperty('force-seekable', 'yes');
    PlaybackLog.shared.note('Différé : jusqu\'à $minutes min, cache ${_diskCache ? 'sur disque' : 'en mémoire (512 Mo)'}');
  }

  /// Durée maximale réelle du différé (secondes).
  double get maxDelay => _diskCache ? (settings?.timeshiftMinutes ?? 60) * 60.0 : 480;

  void _startShiftTimer() {
    _shiftTimer?.cancel();
    if (!isLive) return;
    _shiftTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _sampleDelay());
  }

  Future<void> _sampleDelay() async {
    final native = player.platform;
    if (native is! NativePlayer || !isLive || !didStart) return;
    final end = double.tryParse(await native.getProperty('demuxer-cache-time', waitForInitialization: false));
    final pos = double.tryParse(await native.getProperty('time-pos', waitForInitialization: false));
    if (end == null || pos == null) return;
    final delay = (end - pos).clamp(0.0, 1e6);
    final changed = (delay - liveDelay).abs() > 0.4;
    liveDelay = delay;
    // Profondeur du différé disponible : début de la plage du cache où l'on peut revenir.
    final state = await native.getProperty('demuxer-cache-state', waitForInitialization: false);
    final start = _rangeStart(state, pos);
    final depth = start == null ? delay : end - start;
    peakDelay = depth < delay ? delay : depth;
    // Rattrapage en accéléré jusqu'au point visé, puis vitesse normale.
    final target = _catchUpTarget;
    if (rate > 1 && delay <= (target ?? 1.5) + 0.5) {
      _catchUpTarget = null;
      await setRate(1);
    }
    // En pause depuis trop longtemps : le cache est plein, la lecture reprend.
    if (!isPlaying && delay >= maxDelay - 5) {
      PlaybackLog.shared.note('Différé : durée maximale atteinte, reprise de la lecture');
      player.play();
    }
    if (changed) notifyListeners();
  }

  /// Début de la plage du cache où se trouve la lecture (« seekable-ranges » de « demuxer-cache-state », en JSON).
  static double? _rangeStart(String state, double pos) {
    double? containing, last, lastEnd;
    for (final m in RegExp(r'"start"\s*:\s*([0-9.eE+-]+)\s*,\s*"end"\s*:\s*([0-9.eE+-]+)').allMatches(state)) {
      final a = double.tryParse(m.group(1)!), b = double.tryParse(m.group(2)!);
      if (a == null || b == null) continue;
      if (a <= pos + 1 && pos <= b + 5) containing = a;
      if (lastEnd == null || b > lastEnd) {
        lastEnd = b;
        last = a;
      }
    }
    return containing ?? last;
  }

  Future<void> setRate(double value) async {
    rate = value;
    await player.setRate(value);
    notifyListeners();
  }

  /// Accélère jusqu'à un retard donné (0 : le direct).
  Future<void> catchUp({double toDelay = 0}) async {
    if (!isLive) return;
    _catchUpTarget = toDelay;
    if (!isPlaying) player.play();
    await setRate(settings?.catchUpSpeed ?? 1.5);
  }

  /// Revient au direct (fin du cache), sans perdre le différé déjà enregistré.
  Future<void> returnToLive() async {
    final native = player.platform;
    if (native is! NativePlayer || !isLive) return;
    _catchUpTarget = null;
    await setRate(1);
    final end = double.tryParse(await native.getProperty('demuxer-cache-time'));
    if (end != null) await native.command(['seek', (end - 0.5).toStringAsFixed(2), 'absolute']);
    if (!isPlaying) player.play();
    liveDelay = 0;
    notifyListeners();
  }

  /// Place la lecture à un retard donné sur le direct (barre de différé).
  Future<void> seekDelay(double delay) async {
    final native = player.platform;
    if (native is! NativePlayer || !isLive) return;
    final end = double.tryParse(await native.getProperty('demuxer-cache-time'));
    if (end == null) return;
    final d = delay.clamp(0.5, peakDelay > 1 ? peakDelay - 0.5 : 0.5);
    await native.command(['seek', (end - d).toStringAsFixed(2), 'absolute']);
    liveDelay = d;
    notifyListeners();
  }

  bool get isLive => current?.kind == MediaKind.live;
  bool get isSeekable => !isLive && duration > Duration.zero;

  void seek(double fraction) {
    if (!isSeekable) return;
    player.seek(duration * fraction.clamp(0.0, 1.0));
  }

  void jump(int seconds) {
    if (isLive && didStart) {
      // Direct : −10 s / +30 s dans le différé (sans dépasser le direct).
      seekDelay(liveDelay - seconds);
      return;
    }
    if (!isSeekable) return;
    var target = position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    player.seek(target);
  }

  void restartFromBeginning() {
    if (!isSeekable) return;
    player.seek(Duration.zero);
    resumedAt = null;
    if (current != null) watchProgress?.clear(current!.id);
    notifyListeners();
  }

  void dismissResume() {
    resumedAt = null;
    notifyListeners();
  }

  /// Reprise à la dernière position, puis mémorisation régulière (toutes les 5 s).
  void _trackProgress() {
    final item = current;
    if (item == null || item.kind == MediaKind.live || !didStart) return;
    final pending = _pendingResume;
    if (pending != null) {
      if (duration <= Duration.zero) return;
      _pendingResume = null;
      player.seek(pending);
      resumedAt = pending;
      notifyListeners();
      return;
    }
    if (DateTime.now().difference(_lastProgressSave) > const Duration(seconds: 5) && position > const Duration(seconds: 2)) {
      _lastProgressSave = DateTime.now();
      watchProgress?.update(item.id, position.inMilliseconds / 1000, duration.inMilliseconds / 1000);
    }
  }

  void _flushProgress() {
    final item = current;
    if (item != null && item.kind != MediaKind.live && duration > Duration.zero && position > const Duration(seconds: 2) && _pendingResume == null) {
      watchProgress?.update(item.id, position.inMilliseconds / 1000, duration.inMilliseconds / 1000);
    }
    watchProgress?.flush();
  }

  int get recentStalls {
    final now = DateTime.now();
    _stalls.removeWhere((d) => now.difference(d) > const Duration(minutes: 1));
    return _stalls.length;
  }

  /// Lance un contenu (la chaîne précédente est fermée d'abord).
  void play(MediaItem item) {
    final url = item.stream;
    if (url == null) return;
    if (current?.id == item.id && errorMessage == null && didStart) {
      if (!isPlaying) player.play();
      return;
    }
    _flushProgress();
    current = item;
    _retries = 0;
    resumedAt = null;
    _pendingResume = null;
    position = Duration.zero;
    duration = Duration.zero;
    if (item.kind != MediaKind.live && (settings?.resumePlayback ?? true)) {
      final point = watchProgress?.resumePoint(item.id);
      if (point != null) _pendingResume = Duration(milliseconds: (point * 1000).round());
    }
    _start(url);
  }

  void retry() {
    final item = current;
    if (item?.stream == null) return;
    _retries = 0;
    _start(item!.stream!);
  }

  Future<void> stop() async {
    _flushProgress();
    _shiftTimer?.cancel();
    liveDelay = 0;
    peakDelay = 0;
    if (rate != 1) {
      rate = 1;
      player.setRate(1);
    }
    _watchdog?.cancel();
    _openTimer?.cancel();
    _healthTimer?.cancel();
    if (current != null) _closedAt = DateTime.now();
    current = null;
    errorMessage = null;
    isLoading = false;
    didStart = false;
    health = HealthLevel.unknown;
    StreamRelay.shared.closeAll();
    notifyListeners();
    await player.stop();
  }

  /// Fermeture de l'application : coupe la lecture et libère mpv (sinon mpv peut ouvrir ses propres fenêtres sous Windows).
  Future<void> shutdown() async {
    _flushProgress();
    _shiftTimer?.cancel();
    _watchdog?.cancel();
    _openTimer?.cancel();
    _healthTimer?.cancel();
    current = null;
    _retries = 999;
    StreamRelay.shared.closeAll();
    try {
      await player.stop().timeout(const Duration(seconds: 1));
    } catch (_) {}
    try {
      await player.dispose().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  void togglePause() => player.playOrPause();

  Future<void> setVolume(double value) async {
    volume = value.clamp(0, 100);
    if (volume > 0) muted = false;
    await _applyVolume();
    _prefs?.setDouble('volume', volume);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    muted = !muted;
    await _applyVolume();
    _prefs?.setBool('muted', muted);
    notifyListeners();
  }

  Future<void> _applyVolume() => player.setVolume(muted ? 0 : volume);

  void _start(String url, {Duration extra = Duration.zero}) {
    _watchdog?.cancel();
    _openTimer?.cancel();
    _healthTimer?.cancel();
    if (_currentUrl != null) {
      player.stop();
      StreamRelay.shared.closeAll();
      _closedAt = DateTime.now();
    }
    _currentUrl = url;
    _shiftTimer?.cancel();
    liveDelay = 0;
    peakDelay = 0;
    _catchUpTarget = null;
    if (rate != 1) {
      rate = 1;
      player.setRate(1);
    }
    errorMessage = null;
    isLoading = true;
    didStart = false;
    startupTime = null;
    videoHeight = null;
    health = HealthLevel.unknown;
    _stalls.clear();
    notifyListeners();
    final since = _closedAt == null ? releaseDelay : DateTime.now().difference(_closedAt!);
    var wait = releaseDelay - since;
    if (extra > wait) wait = extra;
    if (wait > const Duration(milliseconds: 50)) {
      PlaybackLog.shared.note('Attente de ${(wait.inMilliseconds / 1000).toStringAsFixed(1)} s pour que le serveur libère la connexion précédente');
      _openTimer = Timer(wait, () {
        if (_currentUrl == url && current != null) _open(url);
      });
    } else {
      _open(url);
    }
  }

  Future<void> _open(String url) async {
    _startedAt = DateTime.now();
    final source = StreamRelay.shared.playbackUrl(url, live: isLive && (settings?.relayEnabled ?? true));
    PlaybackLog.shared.note('Ouverture de $url${source == url ? '' : ' (via le relais)'}');
    _watchdog = Timer(startTimeout, () {
      if (_currentUrl == url && !didStart && errorMessage == null) {
        PlaybackLog.shared.note('Aucune image après ${startTimeout.inSeconds} s');
        _fail('Aucune image reçue après ${startTimeout.inSeconds} secondes. Le serveur ne répond pas pour cette chaîne, '
            'ou refuse la connexion (abonnement limité à une connexion : vérifiez qu\'aucun autre appareil ne regarde).');
      }
    });
    await player.open(Media(source, httpHeaders: const {'User-Agent': kUserAgent}), play: true);
  }

  void _markStarted() {
    if (didStart || _startedAt == null || current == null) return;
    didStart = true;
    isLoading = false;
    _watchdog?.cancel();
    startupTime = DateTime.now().difference(_startedAt!);
    PlaybackLog.shared.note('Lecture démarrée en ${(startupTime!.inMilliseconds / 1000).toStringAsFixed(2)} s');
    _healthTimer = Timer.periodic(const Duration(seconds: 2), (_) => _evaluateHealth());
    _evaluateHealth();
    _startShiftTimer();
  }

  void _evaluateHealth() {
    if (!didStart) {
      notifyListeners();
      return;
    }
    final stalls = recentStalls;
    health = !isPlaying
        ? HealthLevel.unknown
        : stalls >= 3
            ? HealthLevel.poor
            : stalls >= 1
                ? HealthLevel.fair
                : HealthLevel.good;
    notifyListeners();
  }

  /// Messages du moteur qui signifient vraiment que le flux n'a pas pu être ouvert (les autres erreurs —
  /// sortie audio, décodage matériel… — sont passagères ou sans gravité).
  static bool isOpenFailure(String message) {
    final m = message.toLowerCase();
    return m.contains('failed to open') ||
        m.contains('failed to recognize file format') ||
        m.contains('http error') ||
        m.contains('cannot open') ||
        m.contains('loading failed') ||
        m.contains('no such file');
  }

  void _onError(String message) {
    if (current == null) return;
    PlaybackLog.shared.engine(message, level: 0);
    if (didStart || isLoading == false) return; // erreur pendant la lecture : mpv reprend seul
    final status = StreamRelay.shared.lastStatus;
    final relayRefused = status != null && (status < 200 || status >= 300);
    if (!relayRefused && !isOpenFailure(message)) return;
    if (status == 403 || status == 404 || status == 410) {
      PlaybackLog.shared.note('Chaîne refusée par le fournisseur (HTTP $status) : pas de nouvel essai');
      _fail('Le fournisseur refuse cette chaîne (HTTP $status). Elle est sans doute hors service chez lui ou absente de '
          'votre abonnement : essayez une autre version de la chaîne (HD, SD…) ou réessayez plus tard.');
      return;
    }
    final url = _currentUrl;
    if (url != null && _retries < 1) {
      _retries++;
      PlaybackLog.shared.note('Flux refusé par le serveur : nouvel essai dans 2 s');
      _start(url, extra: const Duration(seconds: 2));
      return;
    }
    _fail('Lecture impossible : le serveur n\'a pas fourni le flux. Votre abonnement n\'autorise peut-être qu\'une '
        'connexion à la fois : vérifiez qu\'aucun autre appareil ne regarde, puis réessayez.');
  }

  void _fail(String message) {
    _watchdog?.cancel();
    isLoading = false;
    final detail = _startedAt == null ? null : PlaybackLog.shared.lastError(_startedAt!);
    errorMessage = detail == null ? message : '$message\n\nDétail : $detail';
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    StreamRelay.shared.closeAll();
    player.dispose();
    super.dispose();
  }
}
