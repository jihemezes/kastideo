import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n.dart';
import 'cast.dart';
import 'cast_media.dart';
import 'log.dart';
import 'models.dart';
import 'playback.dart';
import 'settings.dart';
import 'youtube.dart';

enum CastState { idle, connecting, casting, error }

/// Diffusion vers un téléviseur : recherche des appareils, session Chromecast, conversion ffmpeg et télécommande
/// branchée sur le lecteur (la barre de lecture agit sur le téléviseur pendant la diffusion).
class CastController extends ChangeNotifier implements CastRemote {
  CastController(this.playback, this.settings) {
    playback.castHook = _onPlay;
    final saved = settings.castDevice;
    if (saved.isNotEmpty) {
      try {
        target = CastDevice.fromJson(jsonDecode(saved));
      } catch (_) {}
    }
  }

  final PlaybackController playback;
  final AppSettings settings;

  List<CastDevice> devices = const [];
  CastDevice? target;
  bool searching = false;
  CastState state = CastState.idle;
  String? message;

  /// Appareil qui reçoit la diffusion en cours.
  CastDevice? active;

  CastSession? _session;
  final CastMediaServer _media = CastMediaServer();
  String? _baseUrl;
  double _offset = 0;
  Timer? _tick;
  int _generation = 0;

  bool get isCasting => state == CastState.casting || state == CastState.connecting;
  bool get ffmpegMissing => !_media.hasFfmpeg;

  // MARK: Recherche

  Future<void> refresh() async {
    if (searching) return;
    searching = true;
    notifyListeners();
    try {
      final results = await Future.wait([discoverChromecasts(), discoverDial()]);
      final chromecasts = results[0];
      final dial = results[1];
      final byHost = {for (final d in dial) d.host: d};
      final merged = <CastDevice>[
        for (final c in chromecasts) c.withDial(byHost[c.host]?.dialUrl),
        for (final host in settings.castManualHosts)
          if (!chromecasts.any((c) => c.host == host)) CastDevice(id: 'manual-$host', name: host, host: host).withDial(byHost[host]?.dialUrl),
        for (final d in dial)
          if (!chromecasts.any((c) => c.host == d.host) && !settings.castManualHosts.contains(d.host)) d,
      ];
      devices = merged;
      final t = target;
      if (t != null) {
        final fresh = merged.where((d) => d.id == t.id || d.host == t.host).firstOrNull;
        if (fresh != null) target = fresh;
      }
      PlaybackLog.shared.note('Cast : ${merged.length} appareil(s) trouvé(s)');
    } finally {
      searching = false;
      notifyListeners();
    }
  }

  void choose(CastDevice device) {
    target = device;
    settings.setString('cast.device', jsonEncode(device.toJson()));
    notifyListeners();
  }

  // MARK: Diffusion d'un contenu

  /// Diffuse le contenu en cours sur [device] (reprise à la position atteinte).
  Future<void> start(CastDevice device) async {
    final item = playback.current;
    if (item == null || isCasting) return;
    if (!device.canCastVideo) {
      _fail(tr('Cet appareil ne sait lire que YouTube. Choisissez un Chromecast, un Google TV ou une TV Android.'));
      return;
    }
    choose(device);
    final generation = ++_generation;
    state = CastState.connecting;
    message = null;
    active = device;
    notifyListeners();
    if (!await _media.prepare(customPath: settings.castFfmpegPath)) {
      _fail(tr('ffmpeg est introuvable. Il convertit la vidéo pour le téléviseur : installez-le ou indiquez son chemin dans Réglages › Cast.'));
      return;
    }
    final lan = await localNetworkAddress(towards: device.host);
    if (lan == null) {
      _fail(tr('Aucune connexion au réseau local : le téléviseur ne peut pas joindre cet ordinateur.'));
      return;
    }
    final at = await playback.suspendForCast(this);
    try {
      await _begin(item, device, lan, at.inMilliseconds / 1000, generation);
    } catch (e) {
      if (generation != _generation) return;
      PlaybackLog.shared.note('Cast : échec ($e)');
      await _cleanup();
      state = CastState.error;
      message = _friendly(e);
      playback.resumeFromCast(at);
      notifyListeners();
    }
  }

  Future<void> _begin(MediaItem item, CastDevice device, String lan, double startAt, int generation) async {
    final source = _sourceOf(item);
    final live = item.kind == MediaKind.live && !item.isReplay;
    final base = await _media.serve(
      source: source,
      live: live,
      lanAddress: lan,
      mode: CastVideoMode.fromName(settings.castVideoMode),
      maxHeight: settings.castMaxHeight,
    );
    if (base == null) throw StateError(_media.lastError ?? 'serveur indisponible');
    _baseUrl = base;
    if (!live && playback.duration <= Duration.zero) {
      final d = await _media.probeDuration(source);
      if (d != null) playback.castUpdate(duration: Duration(milliseconds: (d * 1000).round()));
    }
    final session = CastSession(device)
      ..onChange = _onSession
      ..onError = _onSessionError;
    _session = session;
    await session.connect();
    await session.launch();
    if (generation != _generation) return;
    _offset = live ? 0 : startAt;
    session.setVolume(playback.muted ? 0 : playback.volume / 100);
    session.load(_media.urlAt(base, _offset), title: item.name, live: live);
    state = CastState.casting;
    message = null;
    PlaybackLog.shared.note('Cast : diffusion de « ${item.name} » sur ${device.name}');
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _push());
    playback.castUpdate(position: Duration(milliseconds: (_offset * 1000).round()), loading: true);
    notifyListeners();
  }

  static String _sourceOf(MediaItem item) {
    final url = item.stream ?? '';
    if (url.startsWith('file://')) {
      try {
        return Uri.parse(url).toFilePath();
      } catch (_) {}
    }
    return url;
  }

  /// Un autre contenu est lancé pendant la diffusion : il part sur le téléviseur.
  bool _onPlay(MediaItem item) {
    final device = active;
    final session = _session;
    final base = _baseUrl;
    if (!isCasting || device == null || session == null || base == null || item.stream == null) return false;
    unawaited(_switchTo(item, device, session));
    return true;
  }

  Future<void> _switchTo(MediaItem item, CastDevice device, CastSession session) async {
    final generation = ++_generation;
    var start = 0.0;
    if (item.kind != MediaKind.live && !item.isReplay && settings.resumePlayback) {
      start = playback.watchProgress?.resumePoint(item.id) ?? 0;
    }
    playback
      ..current = item
      ..position = Duration.zero
      ..duration = Duration.zero;
    playback.castUpdate(loading: true);
    final live = item.kind == MediaKind.live && !item.isReplay;
    try {
      final lan = await localNetworkAddress(towards: device.host);
      final source = _sourceOf(item);
      final base = await _media.serve(
        source: source,
        live: live,
        lanAddress: lan ?? '',
        mode: CastVideoMode.fromName(settings.castVideoMode),
        maxHeight: settings.castMaxHeight,
      );
      if (base == null) throw StateError(_media.lastError ?? 'serveur indisponible');
      if (generation != _generation) return;
      _baseUrl = base;
      if (!live) {
        final d = await _media.probeDuration(source);
        if (d != null) playback.castUpdate(duration: Duration(milliseconds: (d * 1000).round()));
      }
      _offset = live ? 0 : start;
      session.load(_media.urlAt(base, _offset), title: item.name, live: live);
      playback.castUpdate(position: Duration(milliseconds: (_offset * 1000).round()), loading: true);
    } catch (e) {
      if (generation != _generation) return;
      message = _friendly(e);
      playback.castUpdate(loading: false, error: message);
      notifyListeners();
    }
  }

  // MARK: État du téléviseur

  void _onSession() {
    final session = _session;
    if (session == null) return;
    if (session.playerState == 'IDLE' && session.idleReason == 'FINISHED' && state == CastState.casting) {
      final live = playback.isLive;
      playback.castUpdate(playing: false, loading: false, error: live ? tr('Le flux s\'est interrompu. Le serveur a peut-être coupé la connexion.') : null);
    }
    if (session.playerState == 'IDLE' && session.idleReason == 'ERROR') {
      playback.castUpdate(playing: false, loading: false, error: _media.lastError ?? tr('Le téléviseur n\'a pas pu lire ce flux.'));
    }
    _push();
  }

  void _onSessionError(String text) {
    if (state != CastState.casting) return;
    if (text.startsWith('La connexion')) {
      PlaybackLog.shared.note('Cast : connexion perdue, reprise sur l\'ordinateur');
      unawaited(stopCasting(note: tr('La connexion avec le téléviseur est coupée : la lecture reprend sur l\'ordinateur.')));
    } else {
      playback.castUpdate(playing: false, loading: false, error: text);
    }
  }

  void _push() {
    final session = _session;
    if (session == null || state != CastState.casting) return;
    final playing = session.playerState == 'PLAYING';
    final buffering = session.playerState == 'BUFFERING';
    final pos = _offset + session.currentTime;
    playback.castUpdate(
      position: Duration(milliseconds: (pos * 1000).round()),
      playing: playing || buffering,
      loading: buffering && session.currentTime < 0.5,
      error: playback.errorMessage != null && session.playerState == 'IDLE' ? playback.errorMessage : null,
    );
  }

  // MARK: Télécommande (CastRemote)

  @override
  void togglePause() {
    final session = _session;
    if (session == null) return;
    if (session.playerState == 'PAUSED') {
      session.play();
    } else {
      session.pause();
    }
  }

  @override
  void seekTo(Duration position) {
    final session = _session;
    final base = _baseUrl;
    final item = playback.current;
    if (session == null || base == null || item == null || playback.isLive) return;
    _offset = position.inMilliseconds / 1000;
    session.load(_media.urlAt(base, _offset), title: item.name, live: false);
    playback.castUpdate(position: position, loading: true);
  }

  @override
  void setVolume(double level) {
    _session?.setVolume(level);
    _session?.setMuted(false);
  }

  @override
  void setMuted(bool muted) => _session?.setMuted(muted);

  /// Appelé par le lecteur quand la diffusion se termine de son côté (autre lecture, arrêt) : pas de reprise locale.
  @override
  Future<void> end() async {
    _generation++;
    await _cleanup();
    state = CastState.idle;
    active = null;
    notifyListeners();
  }

  /// « Arrêter la diffusion » : le téléviseur est libéré et la lecture reprend ici, là où elle en était.
  Future<void> stopCasting({String? note}) async {
    if (!isCasting) return;
    final at = playback.position;
    _generation++;
    await _cleanup();
    state = CastState.idle;
    active = null;
    message = note;
    playback.resumeFromCast(at);
    notifyListeners();
  }

  Future<void> _cleanup() async {
    _tick?.cancel();
    _tick = null;
    final session = _session;
    _session = null;
    _baseUrl = null;
    try {
      await session?.stop();
    } catch (_) {}
    await _media.stop();
  }

  void _fail(String text) {
    state = CastState.error;
    message = text;
    active = null;
    notifyListeners();
  }

  void clearMessage() {
    if (state == CastState.error) state = CastState.idle;
    message = null;
    notifyListeners();
  }

  String _friendly(Object e) {
    if (e is TimeoutException) return tr('Le téléviseur ne répond pas. Vérifiez qu\'il est allumé et sur le même réseau.');
    if (e is SocketException) return '${tr('Connexion au téléviseur impossible')} (${e.message}).';
    if (e is HandshakeException) return tr('Le téléviseur a refusé la connexion sécurisée.');
    return '${tr('La diffusion a échoué')} : $e';
  }

  // MARK: YouTube

  /// Envoie une vidéo YouTube : application YouTube du téléviseur (DIAL) ou navigateur, selon les réglages.
  /// Retourne un message d'erreur, ou null.
  Future<String?> castYouTube(YouTubeVideo video, CastDevice device, {int startSeconds = 0}) async {
    if (settings.castYouTubeMode == 'browser') {
      final ok = await launchUrl(video.watchUrl);
      return ok ? null : tr('Le navigateur n\'a pas pu s\'ouvrir.');
    }
    if (!device.canCastYouTube) {
      return tr('Ce téléviseur n\'a pas répondu à la recherche d\'applications (DIAL). Utilisez le mode « navigateur » dans Réglages › Cast.');
    }
    final error = await launchYouTubeOnTV(device, video.id, startSeconds: startSeconds);
    PlaybackLog.shared.note(error == null ? 'Cast : YouTube lancé sur ${device.name}' : 'Cast : YouTube refusé ($error)');
    return error;
  }

  @override
  void dispose() {
    playback.castHook = null;
    _tick?.cancel();
    unawaited(_cleanup());
    super.dispose();
  }
}
