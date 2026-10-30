/// Serveur de diffusion pour le Cast : ffmpeg convertit la source (direct, film, vidéo locale…) en MP4 fragmenté
/// que le téléviseur lit par le réseau local. Une seule connexion au fournisseur : le lecteur de Kastideo est coupé
/// pendant la diffusion (voir PlaybackController.suspendForCast).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'log.dart';
import 'xtream.dart';

/// Façon de préparer la vidéo pour le téléviseur.
enum CastVideoMode {
  /// Copie la vidéo si elle est en H.264 (léger), sinon la convertit.
  auto,

  /// Toujours convertir (le plus compatible, plus lourd pour l'ordinateur).
  transcode;

  static CastVideoMode fromName(String? name) => values.firstWhere((m) => m.name == name, orElse: () => auto);
}

/// Cherche ffmpeg : chemin réglé, puis à côté de l'application, puis dans le PATH. Null : introuvable.
Future<String?> findFfmpeg({String? custom, String tool = 'ffmpeg'}) async {
  final exe = Platform.isWindows ? '$tool.exe' : tool;
  final candidates = <String>[];
  if (custom != null && custom.trim().isNotEmpty) {
    final c = custom.trim();
    if (await FileSystemEntity.isDirectory(c)) {
      candidates.add('$c${Platform.pathSeparator}$exe');
    } else if (tool == 'ffmpeg') {
      candidates.add(c);
    } else {
      candidates.add('${File(c).parent.path}${Platform.pathSeparator}$exe');
    }
  }
  final here = File(Platform.resolvedExecutable).parent.path;
  candidates
    ..add('$here${Platform.pathSeparator}$exe')
    ..add('$here${Platform.pathSeparator}bin${Platform.pathSeparator}$exe')
    ..add('$here${Platform.pathSeparator}..${Platform.pathSeparator}bin${Platform.pathSeparator}$exe');
  for (final c in candidates) {
    if (await File(c).exists()) return c;
  }
  try {
    final result = await Process.run(Platform.isWindows ? 'where' : 'which', [exe]);
    if (result.exitCode == 0) {
      final first = const LineSplitter().convert(result.stdout as String).firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
      if (first.isNotEmpty) return first.trim();
    }
  } catch (_) {}
  return null;
}

/// Adresse de l'ordinateur sur le réseau local (celle que le téléviseur peut joindre).
Future<String?> localNetworkAddress({String? towards}) async {
  try {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
    final addresses = [for (final i in interfaces) ...i.addresses.map((a) => a.address)];
    if (addresses.isEmpty) return null;
    // Même réseau que le téléviseur si possible (mêmes trois premiers nombres).
    if (towards != null) {
      final prefix = towards.split('.').take(3).join('.');
      for (final a in addresses) {
        if (a.startsWith('$prefix.')) return a;
      }
    }
    bool isPrivate(String a) {
      if (a.startsWith('192.168.') || a.startsWith('10.')) return true;
      final p = a.split('.');
      final second = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
      return a.startsWith('172.') && second >= 16 && second <= 31;
    }

    return addresses.firstWhere(isPrivate, orElse: () => addresses.first);
  } catch (_) {
    return null;
  }
}

/// Arguments de ffmpeg pour produire un MP4 fragmenté sur la sortie standard.
List<String> buildFfmpegArgs({
  required String source,
  required bool copyVideo,
  double startSeconds = 0,
  bool live = false,
  int maxHeight = 1080,
}) {
  final remote = source.startsWith('http://') || source.startsWith('https://');
  return [
    '-hide_banner',
    '-loglevel', 'warning',
    if (remote) ...['-user_agent', kUserAgent, '-reconnect', '1', '-reconnect_streamed', '1', '-reconnect_delay_max', '5'],
    if (!live && startSeconds > 0.5) ...['-ss', startSeconds.toStringAsFixed(2)],
    '-i', source,
    '-map', '0:v:0',
    '-map', '0:a:0?',
    '-sn',
    if (copyVideo) ...['-c:v', 'copy'] else ...[
      '-c:v', 'libx264',
      '-preset', 'veryfast',
      '-tune', 'zerolatency',
      '-pix_fmt', 'yuv420p',
      '-vf', "scale='if(gt(ih,$maxHeight),-2,iw)':'min(ih,$maxHeight)'",
      '-g', '50',
    ],
    '-c:a', 'aac',
    '-ac', '2',
    '-b:a', '192k',
    '-movflags', 'frag_keyframe+empty_moov+default_base_moof',
    '-f', 'mp4',
    'pipe:1',
  ];
}

/// Serveur HTTP local qui lance ffmpeg pour chaque demande du téléviseur.
class CastMediaServer {
  CastMediaServer();

  HttpServer? _server;
  Process? _ffmpeg;
  String? _ffmpegPath;
  String? _ffprobePath;
  String _source = '';
  bool _live = false;
  CastVideoMode _mode = CastVideoMode.auto;
  int _maxHeight = 1080;
  bool? _sourceIsH264;
  String? lastError;

  /// ffmpeg disponible ?
  bool get hasFfmpeg => _ffmpegPath != null;

  Future<bool> prepare({String? customPath}) async {
    _ffmpegPath = await findFfmpeg(custom: customPath);
    _ffprobePath = await findFfmpeg(custom: customPath, tool: 'ffprobe');
    return _ffmpegPath != null;
  }

  /// Prépare la diffusion d'une source ; retourne l'adresse que le téléviseur doit ouvrir (sans position de départ).
  Future<String?> serve({
    required String source,
    required bool live,
    required String lanAddress,
    required CastVideoMode mode,
    required int maxHeight,
  }) async {
    _source = source;
    _live = live;
    _mode = mode;
    _maxHeight = maxHeight;
    _sourceIsH264 = null;
    await _killFfmpeg();
    if (_server == null) {
      try {
        final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        _server = server;
        server.listen(_handle, onError: (Object e) => PlaybackLog.shared.note('Cast : erreur du serveur ($e)'));
      } catch (e) {
        lastError = 'Impossible d\'ouvrir le port de diffusion ($e). Le pare-feu bloque peut-être Kastideo.';
        return null;
      }
    }
    return 'http://$lanAddress:${_server!.port}/cast.mp4';
  }

  /// Vrai si la vidéo source est du H.264 8 bits (peut être copiée sans conversion).
  Future<bool> _canCopy() async {
    if (_mode == CastVideoMode.transcode) return false;
    final probe = _ffprobePath;
    if (probe == null) return false;
    if (_sourceIsH264 != null) return _sourceIsH264!;
    try {
      final remote = _source.startsWith('http');
      final result = await Process.run(probe, [
        '-v', 'error',
        if (remote) ...['-user_agent', kUserAgent],
        '-select_streams', 'v:0',
        '-show_entries', 'stream=codec_name,pix_fmt',
        '-of', 'csv=p=0',
        _source,
      ]).timeout(const Duration(seconds: 15));
      final text = (result.stdout as String).trim().toLowerCase();
      _sourceIsH264 = text.startsWith('h264') && (text.contains('yuv420p'));
    } catch (_) {
      _sourceIsH264 = false;
    }
    PlaybackLog.shared.note('Cast : vidéo ${_sourceIsH264! ? 'copiée (H.264)' : 'convertie en H.264'}');
    return _sourceIsH264!;
  }

  /// Durée de la source en secondes (null : inconnue, direct).
  Future<double?> probeDuration(String source) async {
    final probe = _ffprobePath;
    if (probe == null) return null;
    try {
      final result = await Process.run(probe, [
        '-v', 'error',
        if (source.startsWith('http')) ...['-user_agent', kUserAgent],
        '-show_entries', 'format=duration',
        '-of', 'csv=p=0',
        source,
      ]).timeout(const Duration(seconds: 15));
      return double.tryParse((result.stdout as String).trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final path = _ffmpegPath;
    if (path == null || request.uri.path != '/cast.mp4') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final start = double.tryParse(request.uri.queryParameters['ss'] ?? '') ?? 0;
    await _killFfmpeg();
    final copy = await _canCopy();
    final args = buildFfmpegArgs(source: _source, copyVideo: copy, startSeconds: start, live: _live, maxHeight: _maxHeight);
    PlaybackLog.shared.note('Cast : demande du téléviseur (${request.method}) à ${start.toStringAsFixed(0)} s');
    if (request.method == 'HEAD') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('video', 'mp4');
      await request.response.close();
      return;
    }
    Process process;
    try {
      process = await Process.start(path, args);
    } catch (e) {
      lastError = 'ffmpeg n\'a pas pu démarrer ($e).';
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      return;
    }
    _ffmpeg = process;
    final errors = StringBuffer();
    process.stderr.transform(utf8.decoder).listen((s) {
      if (errors.length < 4000) errors.write(s);
    });
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('video', 'mp4')
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-cache')
      ..headers.set('transferMode.dlna.org', 'Streaming')
      ..bufferOutput = false;
    try {
      await request.response.addStream(process.stdout);
      await request.response.close();
    } catch (_) {
      // Le téléviseur a fermé la connexion (changement de position, arrêt).
    }
    if (identical(_ffmpeg, process)) {
      final code = await process.exitCode.timeout(const Duration(seconds: 2), onTimeout: () => -1);
      if (code > 0 && errors.isNotEmpty) {
        lastError = errors.toString().trim().split('\n').last;
        PlaybackLog.shared.note('Cast : ffmpeg a signalé ${errors.toString().trim().split('\n').last}');
      }
    }
  }

  Future<void> _killFfmpeg() async {
    final p = _ffmpeg;
    _ffmpeg = null;
    if (p != null) {
      p.kill();
      await p.exitCode.timeout(const Duration(seconds: 2), onTimeout: () {
        p.kill(ProcessSignal.sigkill);
        return -1;
      });
    }
  }

  /// Adresse avec position de départ (pour reprendre ou se déplacer dans un film).
  String urlAt(String base, double seconds) => seconds > 0.5 ? '$base?ss=${seconds.toStringAsFixed(1)}' : base;

  Future<void> stop() async {
    await _killFfmpeg();
    final s = _server;
    _server = null;
    await s?.close(force: true);
  }
}
