import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:smb_connect/smb_connect.dart';

import 'log.dart';

/// Identifiants d'un partage réseau (SMB). « DOMAINE\\utilisateur » est accepté ; sans identifiant : accès invité.
class SmbCredentials {
  const SmbCredentials(this.user, this.password);
  final String user;
  final String password;

  String get domain => user.contains('\\') ? user.split('\\').first : '';
  String get name => user.contains('\\') ? user.split('\\').last : user;
}

/// Adresse « smb://serveur/partage/dossier ».
class SmbLocation {
  const SmbLocation(this.host, this.path);
  final String host;

  /// Chemin sur le serveur, commençant par le nom du partage (« /Videos/Films »).
  final String path;

  static bool isSmb(String text) => text.trim().toLowerCase().startsWith('smb://');

  static SmbLocation? parse(String text) {
    final t = text.trim();
    if (!isSmb(t)) return null;
    final rest = t.substring(6);
    final slash = rest.indexOf('/');
    final host = slash < 0 ? rest : rest.substring(0, slash);
    if (host.isEmpty) return null;
    var path = slash < 0 ? '/' : rest.substring(slash);
    while (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return SmbLocation(host, path);
  }

  String get url => 'smb://$host$path';
}

/// Connexions SMB (une par serveur) et examen des dossiers partagés.
class SmbHub {
  SmbHub._();
  static final shared = SmbHub._();

  final Map<String, SmbCredentials> _credentials = {};
  final Map<String, SmbConnect> _connections = {};

  static const _skipped = {'system volume information', r'$recycle.bin', '@eadir', '#recycle', 'lost+found', '.trash', '.trashes'};

  void register(String host, SmbCredentials credentials) {
    final key = host.toLowerCase();
    final old = _credentials[key];
    if (old != null && (old.user != credentials.user || old.password != credentials.password)) drop(host);
    _credentials[key] = credentials;
  }

  Future<void> drop(String host) async {
    final connection = _connections.remove(host.toLowerCase());
    try {
      await connection?.close();
    } catch (_) {}
  }

  Future<SmbConnect> connection(String host) async {
    final key = host.toLowerCase();
    final cached = _connections[key];
    if (cached != null) return cached;
    final c = _credentials[key] ?? const SmbCredentials('', '');
    try {
      final connect = await SmbConnect.connectAuth(
        host: host,
        domain: c.domain,
        username: c.user.isEmpty ? 'guest' : c.name,
        password: c.password,
        onDisconnect: (_) => _connections.remove(key),
      );
      _connections[key] = connect;
      return connect;
    } catch (e) {
      PlaybackLog.shared.error('SMB $host : $e');
      throw Exception('Connexion SMB impossible ($host) : $e. Vérifiez l\'adresse, l\'identifiant et le mot de passe ; le serveur doit accepter SMB 2.1 ou plus ancien.');
    }
  }

  /// Vidéos d'un dossier partagé et de ses sous-dossiers (chemins « smb://… »).
  Future<List<(String path, DateTime? modified)>> listVideos(String root, bool Function(String name) isVideo, {int maxDepth = 10}) async {
    final location = SmbLocation.parse(root);
    if (location == null) return const [];
    final connect = await connection(location.host);
    final found = <(String, DateTime?)>[];
    Future<void> walk(String path, int depth) async {
      if (depth > maxDepth) return;
      final List<SmbFile> entries;
      try {
        entries = await connect.listFiles(await connect.file(path));
      } catch (e) {
        if (depth == 0) rethrow;
        return; // sous-dossier illisible : ignoré
      }
      for (final e in entries) {
        final name = e.name;
        if (name.isEmpty || name == '.' || name == '..' || name.startsWith('.')) continue;
        final child = path.endsWith('/') ? '$path$name' : '$path/$name';
        if (e.isDirectory()) {
          if (!_skipped.contains(name.toLowerCase())) await walk(child, depth + 1);
        } else if (isVideo(name)) {
          found.add(('smb://${location.host}$child', e.lastModified > 0 ? DateTime.fromMillisecondsSinceEpoch(e.lastModified) : null));
        }
      }
    }

    await walk(location.path, 0);
    return found;
  }
}

/// Relais local : mpv lit un fichier d'un partage SMB comme une adresse http://127.0.0.1 (avec lecture partielle).
class SmbProxy {
  SmbProxy._();
  static final shared = SmbProxy._();

  HttpServer? _server;

  Future<String> urlFor(String smbUrl) async {
    final server = _server ??= await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen(_handle, onError: (_) {});
    final name = smbUrl.split('/').last;
    final token = base64Url.encode(utf8.encode(smbUrl));
    return 'http://127.0.0.1:${server.port}/f/$token/${Uri.encodeComponent(name)}';
  }

  static String _type(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'mp4' || 'm4v' => 'video/mp4',
      'mkv' => 'video/x-matroska',
      'avi' => 'video/x-msvideo',
      'mov' => 'video/quicktime',
      'ts' || 'm2ts' || 'mts' => 'video/mp2t',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      final parts = request.uri.pathSegments;
      if (parts.length < 2 || parts.first != 'f') {
        response.statusCode = 404;
        await response.close();
        return;
      }
      final smbUrl = utf8.decode(base64Url.decode(parts[1]));
      final location = SmbLocation.parse(smbUrl);
      if (location == null) {
        response.statusCode = 400;
        await response.close();
        return;
      }
      var sent = false;
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final connect = await SmbHub.shared.connection(location.host);
          final file = await connect.file(location.path);
          final size = file.size;
          var start = 0;
          var end = size - 1; // inclus
          final range = request.headers.value('range');
          if (range != null) {
            final m = RegExp(r'bytes=(\d*)-(\d*)').firstMatch(range);
            if (m != null) {
              if (m.group(1)!.isNotEmpty) {
                start = int.parse(m.group(1)!);
                if (m.group(2)!.isNotEmpty) end = int.parse(m.group(2)!);
              } else if (m.group(2)!.isNotEmpty) {
                start = size - int.parse(m.group(2)!);
              }
            }
            if (start < 0) start = 0;
            if (end >= size) end = size - 1;
            response.statusCode = 206;
            response.headers.set('Content-Range', 'bytes $start-$end/$size');
          } else {
            response.statusCode = 200;
          }
          response.headers
            ..set('Accept-Ranges', 'bytes')
            ..contentType = ContentType.parse(_type(location.path))
            ..contentLength = end - start + 1;
          if (request.method == 'HEAD' || size == 0 || start > end) {
            await response.close();
            return;
          }
          final Stream<Uint8List> stream = await connect.openRead(file, start, end + 1);
          sent = true;
          await response.addStream(stream);
          await response.close();
          return;
        } catch (e) {
          if (attempt == 0 && !sent) {
            // Connexion SMB perdue : on la rétablit et on réessaie une fois.
            await SmbHub.shared.drop(location.host);
            continue;
          }
          rethrow;
        }
      }
    } catch (e) {
      PlaybackLog.shared.error('Relais SMB : $e');
      try {
        response.statusCode = 502;
        await response.close();
      } catch (_) {}
    }
  }
}
