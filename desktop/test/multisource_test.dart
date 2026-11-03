import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/app_state.dart';
import 'package:kastideo/core/models.dart';
import 'package:kastideo/core/settings.dart';
import 'package:kastideo/ui/library_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Source src(String id, SourceKind kind, String address) => Source(id: id, name: id, kind: kind, address: address);

  test('abonnement ou liste publique : limite par défaut de chaque source', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    final xtream = src('x', SourceKind.xtream, 'http://srv');
    final subscriptionM3u = src('s', SourceKind.m3uUrl, 'http://srv/get.php?username=a&password=b&type=m3u');
    final publicM3u = src('p', SourceKind.m3uUrl, 'https://example.org/channels.m3u');
    expect(settings.multiviewLimit(xtream), 1);
    expect(settings.multiviewLimit(subscriptionM3u), 1);
    expect(settings.multiviewLimit(publicM3u), 4);
    // Un seul abonnement limité : pas de MultiVue ; avec une liste publique en plus, oui.
    expect(settings.multiviewAvailableFor([xtream]), isFalse);
    expect(settings.multiviewAvailableFor([xtream, publicM3u]), isTrue);
    // Deux abonnements à une connexion chacun : MultiVue possible (un flux par compte).
    expect(settings.multiviewAvailableFor([xtream, subscriptionM3u]), isTrue);
    settings.setMultiviewLimit(xtream, 3);
    expect(settings.multiviewLimit(xtream), 3);
    expect(settings.multiviewAvailableFor([xtream]), isTrue);
  });

  test('qualité d\'image lue dans le nom', () {
    MediaItem named(String n) => MediaItem(id: 'a:1', sourceId: 'a', kind: MediaKind.movie, name: n, group: 'g');
    expect(qualityOf(named('Film.2021.2160p.UHD.mkv')), LibraryQuality.uhd);
    expect(qualityOf(named('Film 4K')), LibraryQuality.uhd);
    expect(qualityOf(named('Film.1080p.BluRay.x264')), LibraryQuality.hd);
    expect(qualityOf(named('Film vieux')), LibraryQuality.other);
  });

  test('note, durée, pays et langue survivent à la sauvegarde', () {
    final i = MediaItem(id: 'a:1', sourceId: 'a', kind: MediaKind.movie, name: 'X', group: 'g', rating: 7.5, runtime: 120, country: 'France', language: 'fr');
    final back = MediaItem.fromJson(i.toJson());
    expect((back.rating, back.runtime, back.country, back.language), (7.5, 120, 'France', 'fr'));
    expect(back.copyWith(info: 'x').rating, 7.5);
  });

  test('filtres de la vidéothèque mémorisés', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    final nav = NavigationModel()..settings = settings;
    nav.loadLibraryPrefs();
    nav.setLibrary(country: 'France', quality: LibraryQuality.hd, status: LibraryStatus.favorites, sort: LibrarySort.rating);
    final again = NavigationModel()..settings = settings;
    again.loadLibraryPrefs();
    expect(again.libraryCountry, 'France');
    expect(again.libraryQuality, LibraryQuality.hd);
    expect(again.libraryStatus, LibraryStatus.favorites);
    expect(again.librarySort, LibrarySort.rating);
    again.resetLibraryFilters();
    expect(again.hasLibraryFilters, isFalse);
    expect(again.librarySort, LibrarySort.rating);
  });
}
