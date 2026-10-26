import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// Serveur trouvé sur le réseau de la maison.
class DiscoveredServer {
  DiscoveredServer(this.kind, this.name, this.address);
  final SourceKind kind;
  final String name;
  final String address;

  @override
  bool operator ==(Object other) => other is DiscoveredServer && other.kind == kind && other.address == address;
  @override
  int get hashCode => Object.hash(kind, address);
}

/// Recherche des serveurs Jellyfin et Emby (diffusion UDP sur le port 7359) et Plex (GDM, port 32414).
class ServerDiscovery {
  ServerDiscovery._();

  static Future<List<DiscoveredServer>> scan({Duration wait = const Duration(seconds: 3)}) async {
    final found = <DiscoveredServer>{};
    final sockets = <RawDatagramSocket>[];
    // Une socket par question : la réponse dit alors de quel serveur il s'agit.
    Future<void> ask(List<int> message, List<(InternetAddress, int)> targets, SourceKind hint) async {
      try {
        final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        sockets.add(socket);
        socket.broadcastEnabled = true;
        socket.listen((event) {
          if (event != RawSocketEvent.read) return;
          final d = socket.receive();
          if (d == null) return;
          final server = parseReply(utf8.decode(d.data, allowMalformed: true), d.address.address, hint: hint);
          if (server != null) found.add(server);
        });
        for (var i = 0; i < 2; i++) {
          for (final (address, port) in targets) {
            socket.send(message, address, port);
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
      } catch (_) {
        // Réseau sans diffusion (VPN, pare-feu) : la saisie de l'adresse reste possible.
      }
    }

    final broadcast = InternetAddress('255.255.255.255');
    await Future.wait([
      ask(utf8.encode('who is JellyfinServer?'), [(broadcast, 7359)], SourceKind.jellyfin),
      ask(utf8.encode('who is EmbyServer?'), [(broadcast, 7359)], SourceKind.emby),
      ask(utf8.encode('M-SEARCH * HTTP/1.1\r\n\r\n'), [(InternetAddress('239.0.0.250'), 32414), (broadcast, 32414)], SourceKind.plex),
    ]);
    await Future<void>.delayed(wait);
    for (final s in sockets) {
      s.close();
    }
    return found.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Réponse d'un serveur : JSON (Jellyfin, Emby) ou en-têtes HTTP (Plex GDM).
  static DiscoveredServer? parseReply(String text, String fromAddress, {SourceKind hint = SourceKind.jellyfin}) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{')) {
      try {
        final j = jsonDecode(trimmed) as Map;
        final address = j['Address'] as String?;
        if (address == null) return null;
        final name = j['Name'] as String? ?? address;
        return DiscoveredServer(hint == SourceKind.emby ? SourceKind.emby : SourceKind.jellyfin, name, address);
      } catch (_) {
        return null;
      }
    }
    if (trimmed.startsWith('HTTP/')) {
      final headers = <String, String>{};
      for (final line in trimmed.split(RegExp(r'\r?\n')).skip(1)) {
        final i = line.indexOf(':');
        if (i > 0) headers[line.substring(0, i).trim().toLowerCase()] = line.substring(i + 1).trim();
      }
      if (!(headers['content-type'] ?? '').contains('plex/media-server')) return null;
      final port = headers['port'] ?? '32400';
      return DiscoveredServer(SourceKind.plex, headers['name'] ?? 'Plex', 'http://$fromAddress:$port');
    }
    return null;
  }
}
