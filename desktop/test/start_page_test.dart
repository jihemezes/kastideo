import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/app_state.dart';
import 'package:kastideo/core/models.dart';
import 'package:kastideo/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<(NavigationModel, AppSettings)> make(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final settings = AppSettings();
    await settings.load();
    final nav = NavigationModel()
      ..settings = settings
      ..categoryNames = (kind) => ['Sport', 'Cinéma'];
    return (nav, settings);
  }

  test('par défaut : tout afficher', () async {
    final (nav, _) = await make({});
    nav.go(Screen.live);
    expect(nav.filter(MediaKind.live), isA<AllItems>());
  });

  test('catégorie de départ à chaque entrée dans la section', () async {
    final (nav, _) = await make({'start.live': 'cat:Sport'});
    nav.go(Screen.live);
    expect((nav.filter(MediaKind.live) as CategoryFilter).name, 'Sport');
    // Navigation libre dans la section, puis retour par l'accueil : la page de départ revient.
    nav.show(MediaKind.live, const CategoryFilter('Cinéma'));
    nav.go(Screen.home);
    nav.go(Screen.live);
    expect((nav.filter(MediaKind.live) as CategoryFilter).name, 'Sport');
  });

  test('catégorie disparue : liste complète', () async {
    final (nav, _) = await make({'start.live': 'cat:Inconnue'});
    nav.go(Screen.live);
    expect(nav.filter(MediaKind.live), isA<AllItems>());
  });

  test('favoris, récents et dernière consultée', () async {
    final (nav, _) = await make({'start.movie': 'favorites', 'start.series': 'recents', 'start.live': 'last'});
    nav.go(Screen.movies);
    expect(nav.filter(MediaKind.movie), isA<FavoriteItems>());
    nav.go(Screen.series);
    expect(nav.filter(MediaKind.series), isA<RecentItems>());
    nav.go(Screen.live);
    nav.show(MediaKind.live, const CategoryFilter('Cinéma'));
    nav.go(Screen.home);
    nav.go(Screen.live);
    expect((nav.filter(MediaKind.live) as CategoryFilter).name, 'Cinéma');
  });
}
