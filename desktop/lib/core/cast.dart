/// Cast : envoi d'un contenu vers un téléviseur ou un boîtier Chromecast / Google TV / TV Android.
///
/// - Protocole Chromecast (CASTV2) : connexion TLS au port 8009, messages protobuf encadrés, récepteur multimédia par défaut.
/// - Découverte : mDNS (`_googlecast._tcp`) ; ajout manuel par adresse IP possible.
/// - YouTube : lancement de l'application YouTube du téléviseur par DIAL (SSDP + requête HTTP).
/// Le code ne dépend que de dart:io : il pourra servir tel quel aux futures versions Android et iOS.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:multicast_dns/multicast_dns.dart';

import 'log.dart';

/// Récepteur multimédia par défaut de Google (lit les URL MP4 / HLS).
const kDefaultReceiverApp = 'CC1AD845';

enum CastKind { chromecast, dial }

/// Appareil qui peut recevoir un contenu.
class CastDevice {
  const CastDevice({required this.id, required this.name, required this.host, this.port = 8009, this.kind = CastKind.chromecast, this.dialUrl});
  final String id;
  final String name;
  final String host;
  final int port;
  final CastKind kind;

  /// Adresse « Application-URL » du service DIAL (kind == dial).
  final String? dialUrl;

  CastDevice withDial(String? url) => CastDevice(id: id, name: name, host: host, port: port, kind: kind, dialUrl: url ?? dialUrl);

  /// Peut recevoir une vidéo quelconque (Chromecast, Google TV, TV Android).
  bool get canCastVideo => kind == CastKind.chromecast;

  /// Sait ouvrir l'application YouTube du téléviseur.
  bool get canCastYouTube => dialUrl != null;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'host': host, 'port': port, 'kind': kind.name, 'dialUrl': dialUrl};

  static CastDevice? fromJson(Object? json) {
    if (json is! Map) return null;
    final host = json['host'];
    if (host is! String || host.isEmpty) return null;
    return CastDevice(
      id: (json['id'] as String?) ?? host,
      name: (json['name'] as String?) ?? host,
      host: host,
      port: (json['port'] as int?) ?? 8009,
      kind: json['kind'] == 'dial' ? CastKind.dial : CastKind.chromecast,
      dialUrl: json['dialUrl'] as String?,
    );
  }
}

// MARK: Protobuf CastMessage (champs utiles seulement)

class CastMessage {
  const CastMessage({required this.source, required this.destination, required this.namespace, required this.payload});
  final String source;
  final String destination;
  final String namespace;
  final String payload;

  /// Message encodé et précédé de sa longueur (4 octets, grand-boutiste).
  Uint8List frame() {
    final body = BytesBuilder();
    void varint(int value) {
      var v = value;
      while (v > 0x7f) {
        body.addByte((v & 0x7f) | 0x80);
        v >>= 7;
      }
      body.addByte(v);
    }

    void text(int field, String value) {
      final bytes = utf8.encode(value);
      body.addByte((field << 3) | 2);
      varint(bytes.length);
      body.add(bytes);
    }

    body
      ..addByte(0x08) // protocol_version = CASTV2_1_0
      ..addByte(0);
    text(2, source);
    text(3, destination);
    text(4, namespace);
    body
      ..addByte(0x28) // payload_type = STRING
      ..addByte(0);
    text(6, payload);
    final bytes = body.toBytes();
    final out = BytesBuilder()
      ..add([(bytes.length >> 24) & 0xff, (bytes.length >> 16) & 0xff, (bytes.length >> 8) & 0xff, bytes.length & 0xff])
      ..add(bytes);
    return out.toBytes();
  }

  static CastMessage? decode(Uint8List data) {
    var i = 0;
    int varint() {
      var result = 0;
      var shift = 0;
      while (i < data.length) {
        final b = data[i++];
        result |= (b & 0x7f) << shift;
        if (b & 0x80 == 0) break;
        shift += 7;
      }
      return result;
    }

    var source = '';
    var destination = '';
    var namespace = '';
    var payload = '';
    while (i < data.length) {
      final tag = varint();
      final field = tag >> 3;
      final wire = tag & 7;
      if (wire == 0) {
        varint();
      } else if (wire == 2) {
        final length = varint();
        if (i + length > data.length) return null;
        final slice = data.sublist(i, i + length);
        i += length;
        switch (field) {
          case 2:
            source = utf8.decode(slice, allowMalformed: true);
          case 3:
            destination = utf8.decode(slice, allowMalformed: true);
          case 4:
            namespace = utf8.decode(slice, allowMalformed: true);
          case 6:
            payload = utf8.decode(slice, allowMalformed: true);
        }
      } else {
        return null;
      }
    }
    return CastMessage(source: source, destination: destination, namespace: namespace, payload: payload);
  }
}

/// Extrait les messages complets d'un flux d'octets (préfixe de longueur de 4 octets).
class CastFrameReader {
  final _buffer = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);

  List<CastMessage> add(List<int> chunk) {
    final merged = BytesBuilder(copy: false)
      ..add(_pending)
      ..add(chunk);
    var data = merged.takeBytes();
    final messages = <CastMessage>[];
    while (data.length >= 4) {
      final length = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
      if (length < 0 || length > 4 * 1024 * 1024) {
        data = Uint8List(0);
        break;
      }
      if (data.length < 4 + length) break;
      final message = CastMessage.decode(Uint8List.sublistView(data, 4, 4 + length));
      if (message != null) messages.add(message);
      data = Uint8List.sublistView(data, 4 + length);
    }
    _pending = Uint8List.fromList(data);
    _buffer.clear();
    return messages;
  }
}

// MARK: Session Chromecast

const _nsConnection = 'urn:x-cast:com.google.cast.tp.connection';
const _nsHeartbeat = 'urn:x-cast:com.google.cast.tp.heartbeat';
const _nsReceiver = 'urn:x-cast:com.google.cast.receiver';
const _nsMedia = 'urn:x-cast:com.google.cast.media';

/// Une connexion à un appareil : lance le récepteur, charge un contenu, expose l'état et les commandes.
class CastSession {
  CastSession(this.device);
  final CastDevice device;

  SecureSocket? _socket;
  final _reader = CastFrameReader();
  Timer? _heartbeat;
  int _requestId = 0;
  String? _transportId;
  String? _sessionId;
  Completer<void>? _launched;

  /// Dernier état connu (mis à jour par les messages du récepteur).
  String playerState = 'IDLE';
  String? idleReason;
  double currentTime = 0;
  double? duration;
  double volume = 1;
  bool muted = false;
  int? mediaSessionId;
  bool connected = false;

  /// Appelé à chaque changement d'état et à la fermeture.
  void Function()? onChange;
  void Function(String message)? onError;

  Future<void> connect({Duration timeout = const Duration(seconds: 8)}) async {
    final socket = await SecureSocket.connect(device.host, device.port, onBadCertificate: (_) => true, timeout: timeout);
    _socket = socket;
    connected = true;
    socket.listen(_onData, onError: (Object e) => _closed('$e'), onDone: () => _closed(null), cancelOnError: true);
    _send(_nsConnection, 'receiver-0', {'type': 'CONNECT'});
    _heartbeat = Timer.periodic(const Duration(seconds: 5), (_) => _send(_nsHeartbeat, 'receiver-0', {'type': 'PING'}));
  }

  /// Lance le récepteur multimédia et attend qu'il soit prêt.
  Future<void> launch({Duration timeout = const Duration(seconds: 15)}) async {
    _launched = Completer<void>();
    _send(_nsReceiver, 'receiver-0', {'type': 'LAUNCH', 'appId': kDefaultReceiverApp, 'requestId': ++_requestId});
    await _launched!.future.timeout(timeout, onTimeout: () => throw TimeoutException('Le téléviseur n\'a pas démarré le lecteur.'));
  }

  /// Charge une adresse vidéo (MP4 progressif) sur le récepteur. [startSeconds] : position dans le flux chargé.
  void load(String url, {required String title, required bool live, String contentType = 'video/mp4', double startSeconds = 0}) {
    mediaSessionId = null;
    playerState = 'BUFFERING';
    idleReason = null;
    currentTime = startSeconds;
    _send(_nsMedia, _transportId ?? 'receiver-0', {
      'type': 'LOAD',
      'requestId': ++_requestId,
      'sessionId': _sessionId,
      'autoplay': true,
      'currentTime': 0,
      'media': {
        'contentId': url,
        'contentType': contentType,
        'streamType': live ? 'LIVE' : 'BUFFERED',
        'metadata': {'metadataType': 0, 'title': title},
      },
    });
  }

  void play() => _mediaCommand('PLAY');
  void pause() => _mediaCommand('PAUSE');

  void _mediaCommand(String type) {
    final id = mediaSessionId;
    if (id == null) return;
    _send(_nsMedia, _transportId ?? 'receiver-0', {'type': type, 'requestId': ++_requestId, 'mediaSessionId': id});
  }

  void setVolume(double level) {
    volume = level.clamp(0, 1).toDouble();
    _send(_nsReceiver, 'receiver-0', {'type': 'SET_VOLUME', 'requestId': ++_requestId, 'volume': {'level': volume}});
  }

  void setMuted(bool value) {
    muted = value;
    _send(_nsReceiver, 'receiver-0', {'type': 'SET_VOLUME', 'requestId': ++_requestId, 'volume': {'muted': value}});
  }

  /// Arrête le récepteur sur le téléviseur et ferme la connexion.
  Future<void> stop() async {
    if (_socket != null && _sessionId != null) {
      _send(_nsReceiver, 'receiver-0', {'type': 'STOP', 'requestId': ++_requestId, 'sessionId': _sessionId});
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await close();
  }

  Future<void> close() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    final socket = _socket;
    _socket = null;
    connected = false;
    try {
      await socket?.close();
    } catch (_) {}
  }

  void _send(String namespace, String destination, Map<String, Object?> payload) {
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.add(CastMessage(source: 'sender-0', destination: destination, namespace: namespace, payload: jsonEncode(payload)).frame());
    } catch (e) {
      _closed('$e');
    }
  }

  void _onData(List<int> chunk) {
    for (final message in _reader.add(chunk)) {
      _handle(message);
    }
  }

  void _handle(CastMessage message) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(message.payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = json['type'];
    switch (message.namespace) {
      case _nsHeartbeat:
        if (type == 'PING') _send(_nsHeartbeat, message.source, {'type': 'PONG'});
      case _nsConnection:
        if (type == 'CLOSE') _closed(null);
      case _nsReceiver:
        if (type == 'RECEIVER_STATUS') _onReceiverStatus(json['status'] as Map<String, dynamic>? ?? {});
        if (type == 'LAUNCH_ERROR') _launched?.completeError(StateError('Lancement refusé par le téléviseur.'));
      case _nsMedia:
        if (type == 'MEDIA_STATUS') _onMediaStatus(json['status'] as List? ?? const []);
        if (type == 'LOAD_FAILED' || type == 'LOAD_CANCELLED' || type == 'INVALID_REQUEST') {
          playerState = 'IDLE';
          idleReason = 'ERROR';
          onError?.call('Le téléviseur n\'a pas pu lire ce flux ($type).');
          onChange?.call();
        }
    }
  }

  void _onReceiverStatus(Map<String, dynamic> status) {
    final vol = status['volume'];
    if (vol is Map) {
      volume = (vol['level'] as num?)?.toDouble() ?? volume;
      muted = vol['muted'] as bool? ?? muted;
    }
    final apps = status['applications'];
    if (apps is List) {
      for (final app in apps) {
        if (app is Map && app['appId'] == kDefaultReceiverApp && app['transportId'] != null) {
          final first = _transportId == null;
          _transportId = app['transportId'] as String;
          _sessionId = app['sessionId'] as String?;
          if (first) {
            _send(_nsConnection, _transportId!, {'type': 'CONNECT'});
            if (!(_launched?.isCompleted ?? true)) _launched!.complete();
          }
        }
      }
    }
    onChange?.call();
  }

  void _onMediaStatus(List<dynamic> list) {
    if (list.isEmpty) return;
    final status = list.first;
    if (status is! Map) return;
    mediaSessionId = (status['mediaSessionId'] as num?)?.toInt() ?? mediaSessionId;
    playerState = status['playerState'] as String? ?? playerState;
    idleReason = status['idleReason'] as String?;
    currentTime = (status['currentTime'] as num?)?.toDouble() ?? currentTime;
    final media = status['media'];
    if (media is Map && media['duration'] is num) duration = (media['duration'] as num).toDouble();
    onChange?.call();
  }

  void _closed(String? error) {
    if (!connected) return;
    connected = false;
    _heartbeat?.cancel();
    if (error != null) PlaybackLog.shared.note('Cast : connexion interrompue ($error)');
    onError?.call('La connexion avec le téléviseur est coupée.');
    onChange?.call();
  }
}

// MARK: Découverte

/// Cherche les Chromecast / Google TV du réseau (mDNS).
Future<List<CastDevice>> discoverChromecasts({Duration timeout = const Duration(seconds: 4)}) async {
  final client = MDnsClient();
  final found = <String, CastDevice>{};
  try {
    await client.start();
    await for (final ptr in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer('_googlecast._tcp.local'), timeout: timeout)) {
      var name = ptr.domainName.split('._googlecast').first;
      var id = ptr.domainName;
      await for (final txt in client.lookup<TxtResourceRecord>(ResourceRecordQuery.text(ptr.domainName), timeout: const Duration(seconds: 2))) {
        for (final line in txt.text.split('\n')) {
          if (line.startsWith('fn=')) name = line.substring(3);
          if (line.startsWith('id=')) id = line.substring(3);
        }
        break;
      }
      await for (final srv in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName), timeout: const Duration(seconds: 2))) {
        await for (final ip in client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target), timeout: const Duration(seconds: 2))) {
          found[id] = CastDevice(id: id, name: name, host: ip.address.address, port: srv.port);
          break;
        }
        break;
      }
    }
  } catch (e) {
    PlaybackLog.shared.note('Cast : recherche des appareils impossible ($e)');
  } finally {
    client.stop();
  }
  return found.values.toList();
}

// MARK: DIAL (lancer l'application YouTube du téléviseur)

/// Réponse SSDP : valeur d'un en-tête (sans tenir compte de la casse).
String? ssdpHeader(String response, String name) {
  for (final line in const LineSplitter().convert(response)) {
    final i = line.indexOf(':');
    if (i > 0 && line.substring(0, i).trim().toLowerCase() == name.toLowerCase()) return line.substring(i + 1).trim();
  }
  return null;
}

/// Nom lisible d'un appareil, d'après sa description UPnP.
String? upnpFriendlyName(String xml) {
  final m = RegExp(r'<friendlyName>(.*?)</friendlyName>', dotAll: true).firstMatch(xml);
  return m?.group(1)?.trim().replaceAll('&amp;', '&');
}

/// Corps de la requête qui lance YouTube sur la TV avec une vidéo (et un point de départ).
String dialYouTubeBody(String videoID, {int startSeconds = 0}) => 'v=$videoID&t=$startSeconds';

/// Cherche les appareils DIAL (téléviseurs connectés, Chromecast, boîtiers Android TV).
Future<List<CastDevice>> discoverDial({Duration timeout = const Duration(seconds: 3)}) async {
  final found = <String, CastDevice>{};
  RawDatagramSocket? socket;
  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final request = 'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 2\r\nST: urn:dial-multiscreen-org:service:dial:1\r\n\r\n';
    final bytes = utf8.encode(request);
    socket.send(bytes, InternetAddress('239.255.255.250'), 1900);
    final locations = <String>{};
    final done = Completer<void>();
    final timer = Timer(timeout, () {
      if (!done.isCompleted) done.complete();
    });
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final packet = socket?.receive();
      if (packet == null) return;
      final location = ssdpHeader(utf8.decode(packet.data, allowMalformed: true), 'location');
      if (location != null) locations.add(location);
    });
    await done.future;
    timer.cancel();
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    for (final location in locations) {
      try {
        final request = await http.getUrl(Uri.parse(location));
        final response = await request.close().timeout(const Duration(seconds: 4));
        final appUrl = response.headers.value('application-url');
        final xml = await response.transform(utf8.decoder).join();
        if (appUrl == null) continue;
        final uri = Uri.parse(location);
        found[uri.host] = CastDevice(
          id: 'dial-${uri.host}',
          name: upnpFriendlyName(xml) ?? uri.host,
          host: uri.host,
          kind: CastKind.dial,
          dialUrl: appUrl.endsWith('/') ? appUrl : '$appUrl/',
        );
      } catch (_) {}
    }
    http.close();
  } catch (e) {
    PlaybackLog.shared.note('Cast : recherche DIAL impossible ($e)');
  } finally {
    socket?.close();
  }
  return found.values.toList();
}

/// Lance YouTube sur la TV avec la vidéo demandée. Retourne un message d'erreur, ou null si la TV a accepté.
Future<String?> launchYouTubeOnTV(CastDevice device, String videoID, {int startSeconds = 0}) async {
  final base = device.dialUrl;
  if (base == null) return 'Cet appareil ne sait pas ouvrir YouTube.';
  final http = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await http.postUrl(Uri.parse('${base}YouTube'));
    request.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
    request.write(dialYouTubeBody(videoID, startSeconds: startSeconds));
    final response = await request.close().timeout(const Duration(seconds: 8));
    await response.drain<void>();
    if (response.statusCode == 200 || response.statusCode == 201) return null;
    if (response.statusCode == 404) return 'L\'application YouTube n\'est pas installée sur ce téléviseur.';
    return 'Le téléviseur a refusé (code ${response.statusCode}).';
  } catch (e) {
    return 'Le téléviseur ne répond pas ($e).';
  } finally {
    http.close();
  }
}
