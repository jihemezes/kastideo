import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'library.dart';
import 'log.dart';

/// Ajout d'une source depuis un téléphone (Android TV, sans clavier) : la télévision affiche un QR code,
/// le téléphone ouvre la page de saisie servie sur le réseau local et envoie la source, protégée par un code à 4 chiffres.
class TvSetupServer {
  TvSetupServer(this.library, {this.onAdded});
  final LibraryStore library;
  final void Function(String name)? onAdded;

  HttpServer? _server;
  String code = '';
  String? address;
  String? error;
  int _failures = 0;

  bool get running => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    code = (1000 + math.Random.secure().nextInt(9000)).toString();
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      final ip = await _localAddress();
      address = ip == null ? null : 'http://$ip:${_server!.port}/';
      _server!.listen(_handle, onError: (_) {});
      PlaybackLog.shared.note('Ajout de source depuis un téléphone : serveur ouvert sur ${address ?? '?'}');
    } catch (e) {
      error = '$e';
      PlaybackLog.shared.error('Ajout de source depuis un téléphone : $e');
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  static Future<String?> _localAddress() async {
    try {
      final all = await NetworkInterface.list(type: InternetAddressType.IPv4);
      String? fallback;
      for (final i in all) {
        for (final a in i.addresses) {
          if (a.isLoopback) continue;
          final ip = a.address;
          if (ip.startsWith('192.168.') || ip.startsWith('10.') || RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip)) return ip;
          fallback ??= ip;
        }
      }
      return fallback;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method == 'POST' && request.uri.path == '/add') {
        final body = await utf8DecodeBody(request);
        final f = Uri.splitQueryString(body);
        final message = await _add(f);
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(_page(message));
      } else {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(_page(null));
      }
    } catch (e) {
      request.response
        ..statusCode = 500
        ..write('Erreur');
    }
    await request.response.close();
  }

  static Future<String> utf8DecodeBody(HttpRequest request) async {
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > 20000) break;
    }
    return String.fromCharCodes(bytes);
  }

  Future<String> _add(Map<String, String> f) async {
    if (_failures >= 5) return 'Trop de codes erronés : fermez et rouvrez cet écran sur la télévision.';
    if ((f['code'] ?? '').trim() != code) {
      _failures++;
      return 'Code incorrect.';
    }
    final name = (f['name'] ?? '').trim();
    try {
      if (f['type'] == 'xtream') {
        await library.addXtream(
            name: name, server: (f['server'] ?? '').trim(), username: (f['user'] ?? '').trim(), password: f['pass'] ?? '');
      } else {
        final url = (f['url'] ?? '').trim();
        if (url.isEmpty) return 'Adresse vide.';
        await library.addM3U(name: name.isEmpty ? 'Playlist' : name, address: url);
      }
      onAdded?.call(name);
      return 'OK';
    } catch (e) {
      return 'Source refusée : $e';
    }
  }

  String _page(String? result) {
    final ok = result == 'OK';
    final note = result == null
        ? ''
        : ok
            ? '<p class="ok">Source ajoutée. Elle se charge sur la télévision.</p>'
            : '<p class="ko">${_esc(result)}</p>';
    return '''<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Kastideo</title><style>
body{font-family:-apple-system,Segoe UI,Roboto,sans-serif;background:#16161a;color:#fff;margin:0;padding:20px;max-width:520px}
h1{font-size:22px}label{display:block;margin:14px 0 4px;color:#bbb;font-size:14px}
input,select{width:100%;box-sizing:border-box;padding:12px;font-size:16px;border-radius:8px;border:1px solid #444;background:#26262c;color:#fff}
button{margin-top:22px;width:100%;padding:14px;font-size:17px;border:0;border-radius:10px;background:#ff9933;color:#000;font-weight:600}
.ok{color:#7be07b}.ko{color:#ff8080}.x{display:none}</style></head><body>
<h1>Kastideo — ajouter une source</h1>$note
<form method="post" action="/add">
<label>Code affiché sur la télévision</label><input name="code" inputmode="numeric" maxlength="4" required>
<label>Type</label><select name="type" onchange="t(this.value)"><option value="xtream">Xtream (serveur, identifiant, mot de passe)</option><option value="m3u">Liste M3U (adresse)</option></select>
<label>Nom</label><input name="name">
<div id="xt"><label>Serveur (http://exemple.com:8080)</label><input name="server" autocapitalize="off">
<label>Identifiant</label><input name="user" autocapitalize="off"><label>Mot de passe</label><input name="pass" type="password"></div>
<div id="m3" class="x"><label>Adresse de la liste M3U</label><input name="url" autocapitalize="off"></div>
<button>Envoyer à la télévision</button></form>
<script>function t(v){document.getElementById('xt').className=v=='xtream'?'':'x';document.getElementById('m3').className=v=='m3u'?'':'x'}</script>
</body></html>''';
  }

  static String _esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
