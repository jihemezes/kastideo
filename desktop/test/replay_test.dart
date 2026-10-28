import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/epg.dart';
import 'package:kastideo/core/replay.dart';
import 'package:kastideo/core/xtream.dart';

int utc(String iso) => DateTime.parse(iso).millisecondsSinceEpoch ~/ 1000;

void main() {
  test('adresse de replay avec le décalage du serveur', () {
    // 20:00 UTC, serveur à UTC+1 → 21:00 ; marge avant d'une minute → 20:59 ; 60 + 1 + 5 = 66 minutes.
    final url = ReplayUrl.make(
      'https://fr.example.com:8080/live/jean/s3cret/4242.ts',
      startS: utc('2026-10-27T20:00:00Z'),
      stopS: utc('2026-10-27T21:00:00Z'),
      clock: const ServerClock(offset: 3600),
      deviceOffset: 0,
    );
    expect(url, 'https://fr.example.com:8080/timeshift/jean/s3cret/66/2026-10-27:20-59/4242.ts');
  });

  test('heure d\'été / d\'hiver européenne et décalage manuel', () {
    const clock = ServerClock(timezone: 'Europe/Paris', offset: 3600); // lu en hiver
    final winter = ReplayUrl.make(
      'http://h.example/live/u/p%20w/7.m3u8',
      startS: utc('2026-10-27T20:00:00Z'),
      stopS: utc('2026-10-27T20:30:00Z'),
      clock: clock,
      deviceOffset: 0,
    );
    expect(winter, 'http://h.example/timeshift/u/p%20w/36/2026-10-27:20-59/7.ts');
    final summer = ReplayUrl.make(
      'http://h.example/live/u/p%20w/7.m3u8',
      startS: utc('2026-10-20T20:00:00Z'),
      stopS: utc('2026-10-20T20:30:00Z'),
      clock: clock,
      extraOffsetMinutes: 10,
      deviceOffset: 0,
    );
    expect(summer, 'http://h.example/timeshift/u/p%20w/36/2026-10-20:22-09/7.ts');
  });

  test('adresses qui ne sont pas du direct Xtream', () {
    expect(ReplayUrl.make('http://h.example/movie/u/p/7.mp4', startS: 0, stopS: 60), isNull);
    expect(ReplayUrl.make('pas une adresse', startS: 0, stopS: 60), isNull);
  });

  test('horloge du serveur', () {
    final clock = ServerClock.parse({'timezone': 'Europe/Paris', 'time_now': '2027-01-15 09:00:00', 'timestamp_now': '1800000000'});
    expect(clock?.offset, 3600);
    expect(clock?.timezone, 'Europe/Paris');
    expect(ServerClock.parse({}), isNull);
    expect(ServerClock.fromJson(clock!.toJson())?.offset, 3600);
  });

  test('jours de replay annoncés par le fournisseur', () {
    expect(XtreamClient.archiveDaysOf({'tv_archive': 1, 'tv_archive_duration': '14'}), 14);
    expect(XtreamClient.archiveDaysOf({'tv_archive': '1'}), 1);
    expect(XtreamClient.archiveDaysOf({'tv_archive': 0, 'tv_archive_duration': '7'}), isNull);
  });

  test('le guide garde le passé des chaînes à replay seulement', () {
    final now = nowSeconds();
    String d(int s) => DateTime.fromMillisecondsSinceEpoch(
      s * 1000,
      isUtc: true,
    ).toIso8601String().replaceAll(RegExp(r'[-:T]'), '').replaceFirst(RegExp(r'\.\d+Z'), ' +0000');
    String prog(String ch, int start, int stop) =>
        '<programme start="${d(start)}" stop="${d(stop)}" channel="$ch"><title>T</title></programme>';
    final xml =
        '<tv>${prog('a.fr', now - 86400, now - 82800)}${prog('b.fr', now - 86400, now - 82800)}'
        '${prog('a.fr', now - 40 * 86400, now - 40 * 86400 + 3600)}${prog('a.fr', now, now + 3600)}</tv>';
    final parser = XmltvParser(retainChannels: {'a.fr'}, retainFromS: now - 3 * 86400)..add(xml);
    final result = parser.close(xml.length);
    expect(result.programmes.map((p) => p.channel).toList(), ['a.fr', 'a.fr']);
    final plain = XmltvParser()..add(xml);
    expect(plain.close(xml.length).programmes.length, 1);
  });
}
