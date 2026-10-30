import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/cast.dart';
import 'package:kastideo/core/cast_media.dart';

void main() {
  group('protocole', () {
    test('un message encodé puis décodé reste identique', () {
      const m = CastMessage(source: 'sender-0', destination: 'receiver-0', namespace: 'urn:x-cast:com.google.cast.tp.connection', payload: '{"type":"CONNECT"}');
      final framed = m.frame();
      final length = ByteData.sublistView(framed).getUint32(0);
      expect(length, framed.length - 4);
      final back = CastMessage.decode(Uint8List.sublistView(framed, 4))!;
      expect(back.source, 'sender-0');
      expect(back.destination, 'receiver-0');
      expect(back.namespace, m.namespace);
      expect(back.payload, m.payload);
    });

    test('le lecteur de trames recolle les morceaux et sépare les messages', () {
      CastMessage msg(int i) => CastMessage(source: 'a', destination: 'b', namespace: 'n', payload: '{"i":$i,"é":"ü"}');
      final data = BytesBuilder()
        ..add(msg(1).frame())
        ..add(msg(2).frame());
      final all = data.toBytes();
      final reader = CastFrameReader();
      final out = <CastMessage>[];
      for (var i = 0; i < all.length; i += 7) {
        out.addAll(reader.add(all.sublist(i, i + 7 > all.length ? all.length : i + 7)));
      }
      expect(out.map((m) => m.payload), [msg(1).payload, msg(2).payload]);
    });

    test('un long message (varint sur 2 octets) passe', () {
      final long = CastMessage(source: 's', destination: 'd', namespace: 'n', payload: '{"x":"${'a' * 5000}"}');
      final back = CastMessage.decode(Uint8List.sublistView(long.frame(), 4))!;
      expect(back.payload.length, long.payload.length);
    });
  });

  group('DIAL', () {
    test('en-têtes SSDP et nom de l\'appareil', () {
      const response = 'HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\nLocation: http://192.168.1.40:8008/ssdp/device-desc.xml\r\nST: urn:dial-multiscreen-org:service:dial:1\r\n\r\n';
      expect(ssdpHeader(response, 'LOCATION'), 'http://192.168.1.40:8008/ssdp/device-desc.xml');
      expect(ssdpHeader(response, 'x-inconnu'), isNull);
      expect(upnpFriendlyName('<root><device><friendlyName>Salon &amp; TV</friendlyName></device></root>'), 'Salon & TV');
    });

    test('corps de la requête YouTube', () {
      expect(dialYouTubeBody('dQw4w9WgXcQ'), 'v=dQw4w9WgXcQ&t=0');
      expect(dialYouTubeBody('abc', startSeconds: 90), 'v=abc&t=90');
    });

    test('appareil enregistré et relu', () {
      const d = CastDevice(id: 'x', name: 'Salon', host: '192.168.1.40', dialUrl: 'http://192.168.1.40:8008/apps/');
      final back = CastDevice.fromJson(jsonDecode(jsonEncode(d.toJson())))!;
      expect(back.name, 'Salon');
      expect(back.canCastVideo, isTrue);
      expect(back.canCastYouTube, isTrue);
      expect(CastDevice.fromJson({'host': ''}), isNull);
    });
  });

  group('ffmpeg', () {
    test('copie de la vidéo ou conversion, position de départ', () {
      final copy = buildFfmpegArgs(source: 'http://x/film.mkv', copyVideo: true, startSeconds: 120);
      expect(copy, containsAllInOrder(['-ss', '120.00', '-i', 'http://x/film.mkv']));
      expect(copy, containsAllInOrder(['-c:v', 'copy']));
      final live = buildFfmpegArgs(source: 'http://x/live.ts', copyVideo: false, live: true, startSeconds: 50, maxHeight: 720);
      expect(live, isNot(contains('-ss')));
      expect(live, contains('libx264'));
      expect(live.join(' '), contains('720'));
      expect(live.last, 'pipe:1');
      final local = buildFfmpegArgs(source: '/tmp/a.mp4', copyVideo: true);
      expect(local, isNot(contains('-user_agent')));
    });
  });

  bool has(String tool) => Platform.isLinux && Process.runSync('which', [tool]).exitCode == 0;
  final canRun = has('ffmpeg') && has('openssl') && has('python3');
  group('de bout en bout (faux Chromecast + ffmpeg)', () {
    late Directory dir;
    late Process mock;
    late StreamQueue events;
    late String clip;
    final ffmpegPath = canRun ? Process.runSync('which', ['ffmpeg']).stdout.toString().trim() : '';

    setUpAll(() async {
      if (!canRun) return;
      dir = Directory.systemTemp.createTempSync('cast_test');
      final cert = '${dir.path}/c.pem';
      final key = '${dir.path}/k.pem';
      final r = Process.runSync('openssl', ['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-keyout', key, '-out', cert, '-days', '1', '-subj', '/CN=test']);
      expect(r.exitCode, 0);
      clip = '${dir.path}/clip.mkv';
      final make = Process.runSync(ffmpegPath, ['-y', '-f', 'lavfi', '-i', 'testsrc=duration=6:size=320x240:rate=25', '-f', 'lavfi', '-i', 'sine=duration=6', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-c:a', 'aac', clip]);
      expect(make.exitCode, 0, reason: make.stderr.toString());
      mock = await Process.start('python3', ['-I', 'test/tools/mock_cast_receiver.py', '18009', cert, key]);
      events = StreamQueue(mock.stdout);
      await events.next('READY');
    });

    tearDownAll(() {
      if (!canRun) return;
      mock.kill();
      dir.deleteSync(recursive: true);
    });

    test('connexion, lancement, chargement, lecture du flux converti, pause', () async {
      final device = const CastDevice(id: 't', name: 'Faux salon', host: '127.0.0.1', port: 18009);
      final session = CastSession(device);
      await session.connect();
      await session.launch();
      final media = CastMediaServer();
      expect(await media.prepare(), isTrue);
      final base = await media.serve(source: clip, live: false, lanAddress: '127.0.0.1', mode: CastVideoMode.auto, maxHeight: 720);
      expect(base, isNotNull);
      expect(await media.probeDuration(clip), closeTo(6, 0.5));
      session.load(media.urlAt(base!, 2), title: 'Clip', live: false);
      final load = await events.next('LOAD');
      expect(load['payload']['media']['contentId'], '$base?ss=2.0');
      expect(load['payload']['media']['streamType'], 'BUFFERED');
      expect(load['payload']['media']['contentType'], 'video/mp4');
      final fetched = await events.next('FETCHED');
      expect(fetched['bytes'] as int, greaterThan(1000));
      expect(fetched['type'], 'video/mp4');
      expect(fetched['head'], 'ftyp');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(session.playerState, 'PLAYING');
      expect(session.currentTime, 3.5);
      session.pause();
      await events.next('PAUSE');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(session.playerState, 'PAUSED');
      await session.close();
      await media.stop();
    }, skip: !canRun ? 'ffmpeg, openssl ou python3 absent' : false);
  });
}

/// Lit les événements JSON du faux récepteur, dans l'ordre, jusqu'à celui demandé.
class StreamQueue {
  StreamQueue(Stream<List<int>> stream) {
    stream.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      try {
        _items.add(jsonDecode(line) as Map<String, dynamic>);
      } catch (_) {}
      if (!(_wake?.isCompleted ?? true)) _wake!.complete();
    });
  }
  final _items = <Map<String, dynamic>>[];
  Completer<void>? _wake;

  Future<Map<String, dynamic>> next(String event) async {
    final end = DateTime.now().add(const Duration(seconds: 25));
    while (DateTime.now().isBefore(end)) {
      final i = _items.indexWhere((e) => e['event'] == event);
      if (i >= 0) return _items.removeAt(i);
      _wake = Completer<void>();
      await _wake!.future.timeout(const Duration(milliseconds: 500), onTimeout: () {});
    }
    throw TimeoutException('événement $event non reçu');
  }
}
