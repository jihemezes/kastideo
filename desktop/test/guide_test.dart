import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/epg.dart';
import 'package:kastideo/core/models.dart';
import 'package:kastideo/core/themes.dart';

void main() {
  test('XMLTV : dates avec décalage horaire', () {
    expect(parseXmltvDate('20261018203000 +0200'), DateTime.utc(2026, 10, 18, 18, 30).millisecondsSinceEpoch ~/ 1000);
    expect(parseXmltvDate('202610182030'), DateTime.utc(2026, 10, 18, 20, 30).millisecondsSinceEpoch ~/ 1000);
    expect(parseXmltvDate('bad'), isNull);
  });

  test('XMLTV : chaînes, programmes, entités, morceaux coupés', () {
    const doc = '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE tv SYSTEM "xmltv.dtd">\n'
        '<tv generator-info-name="test">'
        '<channel id="TF1.fr"><display-name>TF1</display-name><display-name lang="fr">TF1 HD</display-name></channel>'
        '<programme start="20261018203000 +0200" stop="20261018223000 +0200" channel="TF1.fr">'
        '<title lang="fr">Le 20h &amp; la m&#233;t&#xE9;o</title><desc>Infos <![CDATA[du soir]]></desc><category lang="fr">Journal</category>'
        '</programme>'
        '<programme start="20261018223000 +0200" stop="20261018233000 +0200" channel="TF1.fr"><title>Film</title></programme>'
        '</tv>';
    final window = (start: DateTime.utc(2026, 10, 18).millisecondsSinceEpoch ~/ 1000, end: DateTime.utc(2026, 10, 20).millisecondsSinceEpoch ~/ 1000);
    // Analyse en petits morceaux, comme pendant un téléchargement.
    final parser = XmltvParser(windowStart: window.start, windowEnd: window.end);
    for (var i = 0; i < doc.length; i += 17) {
      parser.add(doc.substring(i, i + 17 > doc.length ? doc.length : i + 17));
    }
    final guide = parser.close(doc.length);
    expect(guide.isValid, isTrue);
    expect(guide.channels.single.names, ['TF1', 'TF1 HD']);
    expect(guide.programmes.length, 2);
    final p = guide.programmes.first;
    expect(p.title, 'Le 20h & la météo');
    expect(p.desc, 'Infos du soir');
    expect(p.theme, ContentTheme.news);
    final index = EPGIndex(guide.programmes);
    expect(index.current('tf1.FR', p.startS + 60)?.title, p.title);
    expect(index.upcoming('TF1.fr', afterS: p.startS).single.title, 'Film');
    expect(XmltvParser.parseString('<html>erreur</html>').isValid, isFalse);
  });

  test('Rapprochement des chaînes et versions', () {
    expect(ChannelMatcher.normalize('|FR| TF1 FHD'), 'tf1');
    expect(ChannelMatcher.normalize('FR: Canal+ Sport HD'), 'canalplussport');
    expect(ChannelMatcher.normalize('M6 4K', keepResolution: true), 'm64k');
    final matcher = ChannelMatcher([
      XmltvChannel('TF1.fr', ['TF1']),
      XmltvChannel('CanalPlus.ch', ['Canal+']),
      XmltvChannel('CanalPlus.fr', ['Canal+']),
    ]);
    expect(matcher.match('|FR| TF1 HD', null), 'TF1.fr');
    expect(matcher.match('Canal+ FHD', null), 'CanalPlus.fr');
    expect(matcher.match('Inconnue', 'tf1.fr'), 'TF1.fr');
  });

  test('Thèmes par nom et qualité', () {
    expect(ThemeClassifier.themeForChannelName('|FR| beIN Sports 1'), ContentTheme.sport);
    expect(ThemeClassifier.themeForChannelName('|FR| BFM TV'), ContentTheme.news);
    expect(ThemeClassifier.themeForChannelName('France 3 Occitanie'), ContentTheme.regional);
    expect(ThemeClassifier.themeForChannelName('|IT| Rai 1'), ContentTheme.international);
    expect(ThemeClassifier.isAdult('|XX| Test'), isTrue);
    expect(ChannelQuality.of('TF1 FHD'), ChannelQuality.fhd);
    MediaItem live(String id, String name) =>
        MediaItem(id: id, sourceId: 's', kind: MediaKind.live, name: name, group: 'FR');
    final groups = LiveChannelGroup.build([live('1', '|FR| TF1 HD'), live('2', '|FR| TF1 FHD'), live('3', 'TF1 SD')], EPGIndex(), {});
    expect(groups.length, 1);
    expect(groups.single.preferred.id, '2');
    expect(groups.single.theme, ContentTheme.general);
    expect(SportKind.detect(['Ligue 1 : PSG - OM']), SportKind.football);
  });
}
