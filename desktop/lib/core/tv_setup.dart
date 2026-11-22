import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'library.dart';
import 'models.dart' show Source, SourceKind;
import 'settings.dart' show AppSettings;
import 'log.dart';

/// Ajout d'une source depuis un téléphone (Android TV, sans clavier) : la télévision affiche un QR code,
/// le téléphone ouvre la page de saisie servie sur le réseau local et envoie la source, protégée par un code à 4 chiffres.
class TvSetupServer {
  TvSetupServer(this.library, {this.settings, this.onAdded});
  final LibraryStore library;
  final AppSettings? settings;
  final void Function(Source source)? onAdded;

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
      if (request.method == 'POST' && (request.uri.path == '/add' || request.uri.path == '/tmdb')) {
        final body = await utf8DecodeBody(request);
        final f = Uri.splitQueryString(body.replaceAll('+', ' '));
        final message = request.uri.path == '/tmdb' ? await _tmdb(f) : await _add(f);
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

  Future<String?> _checkCode(Map<String, String> f) async {
    if (_failures >= 5) return 'Trop de codes erronés : fermez et rouvrez cet écran sur la télévision.';
    if ((f['code'] ?? '').trim() != code) {
      _failures++;
      return 'Code incorrect.';
    }
    return null;
  }

  /// Clé d'API TMDB (affiches et résumés des films et séries).
  Future<String> _tmdb(Map<String, String> f) async {
    final refused = await _checkCode(f);
    if (refused != null) return refused;
    final key = (f['key'] ?? '').trim();
    final target = settings;
    if (target == null) return 'Réglages indisponibles.';
    await target.setTMDBKey(key);
    PlaybackLog.shared.note('Clé TMDB ${key.isEmpty ? 'retirée' : 'enregistrée'} depuis un téléphone');
    return key.isEmpty ? 'TMDB-OFF' : 'TMDB-OK';
  }

  Future<String> _add(Map<String, String> f) async {
    final refused = await _checkCode(f);
    if (refused != null) return refused;
    final name = (f['name'] ?? '').trim();
    final type = f['type'] ?? 'xtream';
    try {
      // Les listes IPTV sont enregistrées tout de suite ; leur catalogue (long) se charge ensuite, en arrière-plan,
      // avec le suivi affiché sur la télévision. Les serveurs et dossiers sont vérifiés avant l'ajout.
      final Source source;
      switch (type) {
        case 'xtream':
          source = await library.addXtream(
              name: name, server: (f['xs'] ?? '').trim(), username: (f['xu'] ?? '').trim(), password: f['xp'] ?? '', refreshNow: false);
        case 'm3u':
          final url = (f['url'] ?? '').trim();
          if (url.isEmpty) return 'Adresse vide.';
          source = await library.addM3U(name: name.isEmpty ? 'Playlist' : name, address: url, refreshNow: false);
        case 'jellyfin' || 'emby' || 'plex':
          final kind = SourceKind.values.firstWhere((k) => k.name == type);
          final address = (f['ms'] ?? '').trim();
          if (address.isEmpty) return 'Adresse du serveur vide.';
          source = await library.addMediaServer(
              kind: kind, name: name, address: address, username: (f['mu'] ?? '').trim(), password: f['mp'] ?? '', token: (f['mt'] ?? '').trim().isEmpty ? null : f['mt']!.trim());
        case 'folder':
          final paths = (f['fp'] ?? '').split(RegExp(r'[\r\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          source = await library.addFolders(name: name, paths: paths);
        default:
          return 'Type inconnu.';
      }
      onAdded?.call(source);
      return 'OK';
    } catch (e) {
      return 'Source refusée : $e';
    }
  }

  String _page(String? result) {
    final note = switch (result) {
      null => '',
      'OK' => '<p class="ok">Source ajoutée. Le chargement du catalogue continue sur la télévision.</p>',
      'TMDB-OK' => '<p class="ok">Clé TMDB enregistrée sur la télévision.</p>',
      'TMDB-OFF' => '<p class="ok">Clé TMDB retirée.</p>',
      _ => '<p class="ko">${_esc(result)}</p>',
    };
    return '''<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Kastideo</title><style>
body{font-family:-apple-system,Segoe UI,Roboto,sans-serif;background:#16161a;color:#fff;margin:0;padding:20px;max-width:520px}
h1{font-size:22px}h2{font-size:18px;margin-top:34px;border-top:1px solid #444;padding-top:20px}label{display:block;margin:14px 0 4px;color:#bbb;font-size:14px}
input,select,textarea{width:100%;box-sizing:border-box;padding:12px;font-size:16px;border-radius:8px;border:1px solid #444;background:#26262c;color:#fff}
button{margin-top:22px;width:100%;padding:14px;font-size:17px;border:0;border-radius:10px;background:#ff9933;color:#000;font-weight:600}
.ok{color:#7be07b}.ko{color:#ff8080}.x{display:none}small{color:#999;display:block;margin-top:6px}</style></head><body>
<h1>Kastideo — configurer la télévision</h1>$note
<form method="post" action="/add">
<h2>Ajouter une source</h2>
<label>Code affiché sur la télévision</label><input name="code" inputmode="numeric" maxlength="4" required>
<label>Type</label><select name="type" onchange="t(this.value)">
<option value="xtream">Abonnement IPTV : Xtream (serveur, identifiant, mot de passe)</option>
<option value="m3u">Abonnement IPTV : liste M3U (adresse)</option>
<option value="jellyfin">Mes vidéos : serveur Jellyfin</option>
<option value="emby">Mes vidéos : serveur Emby</option>
<option value="plex">Mes vidéos : serveur Plex</option>
<option value="folder">Mes vidéos : dossiers / partage vus par la télévision</option></select>
<label>Nom</label><input name="name">
<div id="xt"><label>Serveur (http://exemple.com:8080)</label><input name="xs" autocapitalize="off">
<label>Identifiant</label><input name="xu" autocapitalize="off"><label>Mot de passe</label><input name="xp" type="password"></div>
<div id="m3" class="x"><label>Adresse de la liste M3U</label><input name="url" autocapitalize="off"></div>
<div id="ms" class="x"><label>Adresse du serveur (http://192.168.1.20:8096)</label><input name="ms" autocapitalize="off">
<div id="mc"><label>Identifiant</label><input name="mu" autocapitalize="off"><label>Mot de passe (ou clé d'API)</label><input name="mp" type="password"></div>
<div id="mt" class="x"><label>Jeton Plex</label><input name="mt" autocapitalize="off"><small>Vide : serveur Plex ouvert au réseau local.</small></div></div>
<div id="fo" class="x"><label>Dossiers (un par ligne)</label><textarea name="fp" rows="4" autocapitalize="off" placeholder="/storage/emulated/0/Movies"></textarea>
<small>Chemins lisibles par la télévision : disque USB (/storage/…) ou partage réseau déjà monté sur l'appareil.</small></div>
<button>Envoyer à la télévision</button></form>
<form method="post" action="/tmdb">
<h2>Clé TMDB (affiches et résumés)</h2>
<label>Code affiché sur la télévision</label><input name="code" inputmode="numeric" maxlength="4" required>
<label>Clé API TMDB</label><input name="key" autocapitalize="off" autocomplete="off">
<small>Laissez vide pour retirer la clé.</small>
<button>Enregistrer la clé</button></form>
<script>function t(v){var g=function(i,on){document.getElementById(i).className=on?'':'x'};g('xt',v=='xtream');g('m3',v=='m3u');g('ms',v=='jellyfin'||v=='emby'||v=='plex');g('mc',v!='plex');g('mt',v=='plex');g('fo',v=='folder')}</script>
</body></html>''';
  }

  static String _esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
