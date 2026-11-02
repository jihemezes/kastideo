import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/details.dart';

void main() {
  group('Corriger la fiche', () {
    test('référence TMDB', () {
      expect(parseTmdbReference(' 12345 ')?.id, '12345');
      expect(parseTmdbReference('12345')?.series, isNull);
      final movie = parseTmdbReference('https://www.themoviedb.org/movie/12345-hero?language=fr-FR');
      expect(movie?.id, '12345');
      expect(movie?.series, false);
      final tv = parseTmdbReference('themoviedb.org/tv/1399-game-of-thrones');
      expect(tv?.id, '1399');
      expect(tv?.series, true);
      expect(parseTmdbReference('hero'), isNull);
      expect(parseTmdbReference(''), isNull);
    });
    test('FicheEdit', () {
      expect(FicheEdit().isEmpty, true);
      expect(FicheEdit(title: '  ').isEmpty, true);
      expect(FicheEdit(tmdbId: '5').isEmpty, false);
      expect(FicheEdit(poster: 'https://x.test/a.jpg').posterUrl, isNotNull);
      expect(FicheEdit(poster: 'file:///a.jpg').posterUrl, isNull);
      final back = FicheEdit.fromJson(FicheEdit(tmdbId: '5', year: 2012, plot: 'x').toJson());
      expect(back.tmdbId, '5');
      expect(back.year, 2012);
      expect(back.plot, 'x');
    });
  });
}
