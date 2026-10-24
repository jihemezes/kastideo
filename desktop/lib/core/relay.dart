import 'dart:async';
import 'dart:io';

import 'log.dart';
import 'xtream.dart';

/// Relais local des flux du direct (même principe que la version Mac 1.1.3 et que Piboard) :
/// Kastideo ouvre lui-même UNE connexion chez le fournisseur (en-tête de lecteur VLC, redirections suivies)
/// et la transmet au moteur mpv par 127.0.0.1. Il n'y a jamais deux connexions à la fois.
class StreamRelay {
  StreamRelay._();
  static final StreamRelay shared = StreamRelay._();

  HttpServer? _server;
  final Map<String, Uri> _routes = {};
  HttpClient? _activeClient;
  int _counter = 0;

  /// Dernière réponse du fournisseur pour la chaîne demandée (null : pas de réponse ou pas de relais).
  int? lastStatus;

  bool get isReady => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      PlaybackLog.shared.note('Relais de flux prêt (127.0.0.1:${server.port})');
      server.listen(_handle, onError: (Object e) => PlaybackLog.shared.note('Relais : erreur $e'));
    } catch (e) {
      PlaybackLog.shared.note('Relais de flux indisponible : $e — lecture directe');
    }
  }

  /// Adresse à donner au moteur : le relais pour un flux réseau continu, sinon l'adresse d'origine.
  String playbackUrl(String url, {required bool live}) {
    lastStatus = null;
    final uri = Uri.tryParse(url);
    final server = _server;
    if (!live || server == null || uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return url;
    if (uri.path.toLowerCase().endsWith('.m3u8')) return url;
    final token = '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
    _routes
      ..clear()
      ..[token] = uri; // seule la dernière chaîne demandée est servie
    final ext = uri.path.contains('.') ? uri.path.split('.').last : 'ts';
    return 'http://127.0.0.1:${server.port}/s/$token.$ext';
  }

  /// Ferme immédiatement la connexion chez le fournisseur.
  void closeAll() {
    _routes.clear();
    _closeActive('fermeture demandée');
  }

  void _closeActive(String reason) {
    final client = _activeClient;
    if (client == null) return;
    _activeClient = null;
    client.close(force: true);
    PlaybackLog.shared.note('Relais : connexion au fournisseur fermée ($reason)');
  }

  Future<void> _handle(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    final token = segments.isEmpty ? '' : segments.last.split('.').first;
    final upstream = _routes[token];
    if (upstream == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    _closeActive('nouvelle demande');
    final client = HttpClient()
      ..userAgent = kUserAgent
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 5);
    _activeClient = client;
    final opened = DateTime.now();
    var bytes = 0;
    PlaybackLog.shared.note('Relais : connexion au fournisseur (${upstream.host})');
    try {
      final outgoing = await client.getUrl(upstream);
      outgoing.headers.set(HttpHeaders.acceptHeader, '*/*');
      outgoing.followRedirects = true;
      outgoing.maxRedirects = 5;
      final response = await outgoing.close();
      for (final r in response.redirects) {
        PlaybackLog.shared.note('Relais : redirection ${r.statusCode} vers ${r.location.host}');
      }
      final elapsed = DateTime.now().difference(opened).inMilliseconds / 1000;
      lastStatus = response.statusCode;
      PlaybackLog.shared.note('Relais : réponse du fournisseur HTTP ${response.statusCode} en ${elapsed.toStringAsFixed(2)} s');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _routes.clear(); // le moteur réessaie de lui-même : on ne relaie pas ce nouvel essai
        await response.drain<void>();
        request.response.statusCode = response.statusCode;
        await request.response.close();
        return;
      }
      // Type forcé à MPEG-TS pour un flux .ts : certains fournisseurs annoncent text/plain ou octet-stream,
      // et le moteur prendrait alors le flux pour une liste de lecture.
      final upstreamType = response.headers.contentType;
      final isVideo = upstreamType != null && (upstreamType.primaryType == 'video' || upstreamType.primaryType == 'audio');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = isVideo ? upstreamType : ContentType('video', 'mp2t')
        ..headers.set(HttpHeaders.cacheControlHeader, 'no-cache')
        ..bufferOutput = false;
      // Quand le moteur ferme la connexion (changement de chaîne, arrêt), on ferme aussitôt celle du fournisseur.
      unawaited(request.response.done.then((_) {}, onError: (_) {}).whenComplete(() {
        if (identical(_activeClient, client)) _closeActive('lecteur fermé');
      }));
      // addStream respecte le débit du lecteur : le flux n'est pas accumulé en mémoire.
      await request.response.addStream(response.map((chunk) {
        bytes += chunk.length;
        return chunk;
      }));
      if (identical(_activeClient, client)) {
        PlaybackLog.shared.note('Relais : le fournisseur a terminé le flux');
      }
      await request.response.close();
    } catch (e) {
      if (identical(_activeClient, client)) {
        PlaybackLog.shared.note('Relais : flux interrompu ($e) après ${(bytes / 1048576).toStringAsFixed(1)} Mo');
        lastStatus ??= 0;
      }
      try {
        if (bytes == 0) request.response.statusCode = HttpStatus.badGateway;
        await request.response.close();
      } catch (_) {}
    } finally {
      if (identical(_activeClient, client)) {
        _activeClient = null;
            client.close(force: true);
      }
    }
  }
}
