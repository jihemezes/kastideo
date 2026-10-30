import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/youtube.dart';

void main() {
  subscriptionsTests();
  test('reconnaît les formes d\'adresse YouTube', () {
    YouTubeSource v(String id) => YouTubeSource(YouTubeSourceKind.video, id);
    expect(parseYouTubeSource('dQw4w9WgXcQ'), v('dQw4w9WgXcQ'));
    expect(parseYouTubeSource('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), v('dQw4w9WgXcQ'));
    expect(parseYouTubeSource('youtu.be/dQw4w9WgXcQ?t=3'), v('dQw4w9WgXcQ'));
    expect(parseYouTubeSource('https://youtube.com/shorts/dQw4w9WgXcQ'), v('dQw4w9WgXcQ'));
    expect(parseYouTubeSource('https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ'), v('dQw4w9WgXcQ'));
    expect(
      parseYouTubeSource('https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLabcdefghijkl'),
      const YouTubeSource(YouTubeSourceKind.playlist, 'PLabcdefghijkl'),
    );
    expect(
      parseYouTubeSource('https://www.youtube.com/channel/UCabcdefghijklmnopqrstuv'),
      const YouTubeSource(YouTubeSourceKind.channel, 'UCabcdefghijklmnopqrstuv'),
    );
    expect(parseYouTubeSource('https://www.youtube.com/@Squeezie/videos'), const YouTubeSource(YouTubeSourceKind.handle, '@Squeezie'));
    expect(parseYouTubeSource('@Squeezie'), const YouTubeSource(YouTubeSourceKind.handle, '@Squeezie'));
    expect(parseYouTubeSource('https://www.youtube.com/c/Foo'), const YouTubeSource(YouTubeSourceKind.handle, '@Foo'));
    expect(parseYouTubeSource('https://example.com/watch?v=dQw4w9WgXcQ'), isNull);
    expect(parseYouTubeSource('bonjour'), isNull);
    expect(parseYouTubeSource(''), isNull);
  });

  test('analyse le flux Atom', () {
    const xml = '''<feed><title>Ma chaîne &amp; moi</title>
<entry><yt:videoId>dQw4w9WgXcQ</yt:videoId><title>Titre &quot;un&quot;</title><author><name>Auteur</name></author>
<published>2026-10-01T10:00:00+00:00</published></entry>
<entry><yt:videoId>court</yt:videoId><title>Ignorée</title></entry>
<entry><yt:videoId>abcdefghijk</yt:videoId><title>Deux</title><author><name>Auteur</name></author></entry></feed>''';
    final feed = parseYouTubeFeed(xml);
    expect(feed.title, 'Ma chaîne & moi');
    expect(feed.videos.map((v) => v.id), ['dQw4w9WgXcQ', 'abcdefghijk']);
    expect(feed.videos[0].title, 'Titre "un"');
    expect(feed.videos[0].channel, 'Auteur');
    expect(feed.videos[0].date, isNotNull);
  });

  test('identifiant de chaîne lu dans la page', () {
    expect(youTubeChannelIdFromPage('..."channelId":"UCabcdefghijklmnopqrstuv",...'), 'UCabcdefghijklmnopqrstuv');
    expect(youTubeChannelIdFromPage('rien'), isNull);
  });

  test('recherche : adresse et résultats', () {
    final page = parseYouTubeSearch(
      '{"nextPageToken":"N","items":[{"id":{"videoId":"dQw4w9WgXcQ"},"snippet":{"title":"L&#39;été","channelTitle":"A &amp; B","publishedAt":"2026-01-01T00:00:00Z"}},{"id":{"channelId":"x"},"snippet":{"title":"autre"}}]}',
    );
    expect(page.videos.length, 1);
    expect(page.videos[0].title, "L'été");
    expect(page.videos[0].channel, 'A & B');
    expect(page.next, 'N');
    expect(page.previous, isNull);
    expect(() => parseYouTubeSearch('{"error":{"code":403,"message":"quota"}}'), throwsA(isA<YouTubeApiError>()));
    final url = youTubeSearchUrl('chat & chien', 'K', order: YouTubeOrder.date, pageToken: 'T').toString();
    expect(url, contains('videoEmbeddable=true'));
    expect(url, contains('order=date'));
    expect(url, contains('pageToken=T'));
  });

  test('page de lecture : lecteur officiel, échappement, index borné', () {
    const labels = YouTubePlayerLabels(
      previous: 'Précédente',
      next: 'Suivante',
      chain: 'Enchaîner',
      loop: 'Boucle',
      mute: 'Muet',
      open: 'Ouvrir',
      unavailable: 'Indisponible',
    );
    final html = youTubePlayerHtml(
      queue: [YouTubeVideo(id: 'dQw4w9WgXcQ', title: '</script><b>x', channel: 'C')],
      index: 5,
      labels: labels,
      eventPath: '/event',
    );
    expect(html, contains('youtube-nocookie.com'));
    expect(html, isNot(contains('</script><b>')));
    expect(html, contains('idx=0'));
    expect(html, contains('EV="/event"'));
    expect(html, contains(r"$('t')"));
  });
}

void subscriptionsTests() {
  test('import des abonnements Takeout (CSV, JSON, liens) et reprise', () {
    const csv =
        'Channel ID,Channel URL,Channel title\n'
        'UCabcdefghijklmnopqrstuv,http://www.youtube.com/channel/UCabcdefghijklmnopqrstuv,"Chaîne, avec ""virgule"""\n'
        'UCzzzzzzzzzzzzzzzzzzzzzz,http://www.youtube.com/channel/UCzzzzzzzzzzzzzzzzzzzzzz,Deux\n'
        'UCabcdefghijklmnopqrstuv,http://www.youtube.com/channel/UCabcdefghijklmnopqrstuv,Doublon';
    final channels = parseYouTubeSubscriptions(csv);
    expect(channels.map((c) => c.id), ['UCabcdefghijklmnopqrstuv', 'UCzzzzzzzzzzzzzzzzzzzzzz']);
    expect(channels[0].title, 'Chaîne, avec "virgule"');
    expect(
      parseYouTubeSubscriptions('[{"snippet":{"title":"Trois","resourceId":{"channelId":"UCyyyyyyyyyyyyyyyyyyyyyy"}}}]')
          .map((c) => c.title),
      ['Trois'],
    );
    expect(parseYouTubeSubscriptions('https://www.youtube.com/channel/UCabcdefghijklmnopqrstuv\n@pseudo').length, 1);
    const labels = YouTubePlayerLabels(previous: 'a', next: 'b', chain: 'c', loop: 'd', mute: 'e', open: 'f', unavailable: 'g');
    final html = youTubePlayerHtml(
      queue: [YouTubeVideo(id: 'dQw4w9WgXcQ', title: 't')],
      index: 0,
      resume: {'dQw4w9WgXcQ': 125.7, 'bad': 3},
      labels: labels,
    );
    expect(html, contains('S={"dQw4w9WgXcQ":125}'));
    expect(html, isNot(contains('"bad"')));
  });
}
