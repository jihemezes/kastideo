import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/local_media.dart';

void main() {
  test('Films, épisodes et vidéos reconnus par leur nom', () {
    var e = LocalNameParser.parse('Inception (2010).mkv');
    expect(e.kind, LocalKind.movie);
    expect(e.title, 'Inception');
    expect(e.year, 2010);
    e = LocalNameParser.parse('Films/The.Matrix.1999.1080p.BluRay.x264.mkv');
    expect((e.kind, e.title, e.year), (LocalKind.movie, 'The Matrix', 1999));
    e = LocalNameParser.parse('Le Fabuleux Destin (2001)/film.mkv');
    expect((e.kind, e.title, e.year), (LocalKind.movie, 'Le Fabuleux Destin', 2001));
    e = LocalNameParser.parse('Séries/Breaking Bad/Saison 1/Breaking.Bad.S01E02.Cat.in.the.Bag.720p.mkv');
    expect((e.kind, e.series, e.season, e.episode, e.title), (LocalKind.episode, 'Breaking Bad', 1, 2, 'Cat in the Bag'));
    e = LocalNameParser.parse('Dark/Season 2/S02E05.mkv');
    expect((e.kind, e.series, e.season, e.episode), (LocalKind.episode, 'Dark', 2, 5));
    e = LocalNameParser.parse('Kaamelott/Saison 3/12 - Le Tourment.avi');
    expect((e.kind, e.series, e.season, e.episode, e.title), (LocalKind.episode, 'Kaamelott', 3, 12, 'Le Tourment'));
    e = LocalNameParser.parse('Friends 1x05.mp4');
    expect((e.kind, e.series, e.season, e.episode), (LocalKind.episode, 'Friends', 1, 5));
    e = LocalNameParser.parse('Vacances/plage avec les enfants.mp4');
    expect((e.kind, e.title), (LocalKind.video, 'plage avec les enfants'));
    e = LocalNameParser.parse('Dune.Part.Two.MULTi.2160p.WEB.mkv');
    expect((e.kind, e.title), (LocalKind.movie, 'Dune Part Two'));
    e = LocalNameParser.parse('Vacances 2024/plage.mp4', aloneInFolder: false);
    expect((e.kind, e.title), (LocalKind.video, 'plage'));
    e = LocalNameParser.parse('Heat (1995)/heat.mkv');
    expect((e.kind, e.title, e.year), (LocalKind.movie, 'Heat', 1995));
    expect(stableHash('abc'), '1a47e90b');
  });
}
