import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/log.dart';
import 'package:kastideo/core/m3u.dart';
import 'package:kastideo/core/models.dart';
import 'package:kastideo/core/text.dart';
import 'package:kastideo/core/xtream.dart';

void main() {
  test('M3U : attributs, groupes, guide', () {
    const text = '#EXTM3U url-tvg="http://guide.example/xmltv.xml"\n'
        '#EXTINF:-1 tvg-id="tf1.fr" tvg-logo="http://logo/tf1.png" group-title="France" tvg-chno="1",TF1 HD\n'
        'http://srv/live/u/p/1.ts\n'
        '#EXTINF:-1,Film, avec virgule\n'
        'http://srv/movie/u/p/2.mkv\n';
    final result = M3UParser.parse(text, 'src');
    expect(result.epgUrl, 'http://guide.example/xmltv.xml');
    expect(result.items.length, 2);
    expect(result.items[0].name, 'TF1 HD');
    expect(result.items[0].group, 'France');
    expect(result.items[0].epgId, 'tf1.fr');
    expect(result.items[0].number, 1);
    expect(result.items[0].kind, MediaKind.live);
    expect(result.items[1].name, 'Film, avec virgule');
    expect(result.items[1].kind, MediaKind.movie);
    expect(result.items[1].group, M3UParser.defaultGroup);
  });

  test('Nettoyage des titres et recherche', () {
    expect(cleanTitle('|FR| TF1 FHD').title, 'TF1');
    expect(cleanTitle('FR - Le Film (2021)').year, 2021);
    expect(cleanTitle('FR - Le Film (2021)').title, 'Le Film');
    expect('Élysée Évènement'.searchKey, 'elysee evenement');
  });

  test('Xtream : serveur et URL get.php', () {
    expect(XtreamCredentials.normalizeServer('exemple.com:8080/player_api.php').toString(), 'http://exemple.com:8080');
    final c = XtreamCredentials.fromPlaylistUrl('http://h.tv:80/get.php?username=a&password=b&type=m3u_plus')!;
    expect(c.username, 'a');
    expect(c.password, 'b');
    expect(c.server.host, 'h.tv');
  });

  test('Journal : identifiants masqués', () {
    expect(PlaybackLog.redact('https://h/live/user/pass/1.ts'), 'https://h/live/***/***/1.ts');
    expect(PlaybackLog.redact('player_api.php?username=a&password=b'), 'player_api.php?username=***&password=***');
  });
}
