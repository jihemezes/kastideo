import 'package:flutter/widgets.dart';

import 'core/guide.dart';
import 'core/library.dart';
import 'core/media_info.dart';
import 'core/models.dart';
import 'core/playback.dart';
import 'core/settings.dart';
import 'core/themes.dart';

/// Écran affiché.
enum Screen { home, live, movies, series, guide }

extension ScreenKind on Screen {
  MediaKind? get kind => switch (this) {
        Screen.live => MediaKind.live,
        Screen.movies => MediaKind.movie,
        Screen.series => MediaKind.series,
        Screen.home || Screen.guide => null,
      };
}

Screen screenFor(MediaKind kind) => switch (kind) {
      MediaKind.live => Screen.live,
      MediaKind.movie => Screen.movies,
      MediaKind.series || MediaKind.episode => Screen.series,
    };

/// Ce qui est sélectionné dans la barre latérale d'une section.
sealed class CatalogFilter {
  const CatalogFilter();
}

class AllItems extends CatalogFilter {
  const AllItems();
}

class FavoriteItems extends CatalogFilter {
  const FavoriteItems();
}

class RecentItems extends CatalogFilter {
  const RecentItems();
}

/// Vue « Thèmes » du direct (En ce moment, Ce soir, Chaînes).
class ThemesFilter extends CatalogFilter {
  const ThemesFilter();
}

/// Mode de la vue Thèmes.
enum ThemeView { now, tonight, channels }

class CategoryFilter extends CatalogFilter {
  const CategoryFilter(this.name);
  final String name;
}

/// Navigation (équivalent du NavigationModel de la version Mac).
class NavigationModel extends ChangeNotifier {
  Screen screen = Screen.home;
  final Map<MediaKind, CatalogFilter> _filters = {};
  bool theater = false;

  /// Film ou série affiché (fiche) — interface Classique : panneau de droite ; Cinéma : page entière.
  final Map<MediaKind, MediaItem?> _selected = {};

  /// Le lecteur est affiché (au lieu de la fiche) pour un film ou un épisode.
  bool showPlayer = false;

  /// Recherche dans la section affichée.
  String search = '';

  /// Vue Thèmes : mode, thème et discipline choisis.
  ThemeView themeMode = ThemeView.now;
  ContentTheme? themeSelection;
  SportKind? sportKind;

  void showThemes({ContentTheme? theme, ThemeView mode = ThemeView.now}) {
    themeSelection = theme;
    themeMode = mode;
    sportKind = null;
    show(MediaKind.live, const ThemesFilter());
  }

  void setThemeMode(ThemeView mode) {
    themeMode = mode;
    notifyListeners();
  }

  void setThemeSelection(ContentTheme? theme) {
    themeSelection = theme;
    if (theme != ContentTheme.sport) sportKind = null;
    notifyListeners();
  }

  void setSportKind(SportKind? kind) {
    sportKind = kind;
    notifyListeners();
  }

  CatalogFilter filter(MediaKind kind) => _filters[kind] ?? const AllItems();
  MediaItem? selected(MediaKind kind) => _selected[kind];

  void go(Screen value) {
    screen = value;
    if (value != Screen.live) theater = false;
    showPlayer = false;
    search = '';
    notifyListeners();
  }

  void show(MediaKind kind, CatalogFilter filter) {
    _filters[kind] = filter;
    screen = screenFor(kind);
    _selected[kind] = null;
    showPlayer = false;
    search = '';
    notifyListeners();
  }

  void select(MediaKind kind, MediaItem? item) {
    _selected[kind] = item;
    showPlayer = false;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void openPlayer() {
    showPlayer = true;
    notifyListeners();
  }

  void closePlayer() {
    showPlayer = false;
    theater = false;
    notifyListeners();
  }

  void toggleTheater() {
    theater = !theater;
    notifyListeners();
  }

  void exitTheater() {
    if (!theater) return;
    theater = false;
    notifyListeners();
  }
}

/// Accès aux objets partagés depuis n'importe quel widget.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.library,
    required this.playback,
    required this.navigation,
    required this.settings,
    required this.watch,
    required this.info,
    required this.guide,
    required super.child,
  });

  final LibraryStore library;
  final PlaybackController playback;
  final NavigationModel navigation;
  final AppSettings settings;
  final WatchProgressStore watch;
  final MediaInfoStore info;
  final GuideStore guide;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

extension AppScopeContext on BuildContext {
  LibraryStore get library => AppScope.of(this).library;
  PlaybackController get playback => AppScope.of(this).playback;
  NavigationModel get navigation => AppScope.of(this).navigation;
  AppSettings get settings => AppScope.of(this).settings;
  WatchProgressStore get watch => AppScope.of(this).watch;
  MediaInfoStore get info => AppScope.of(this).info;
  GuideStore get guide => AppScope.of(this).guide;
}

/// Ouvre un contenu : chaîne → lecture ; film ou série → fiche (comme sur Mac).
void openItem(BuildContext context, MediaItem item) {
  final navigation = context.navigation;
  switch (item.kind) {
    case MediaKind.live:
      context.playback.play(item);
      context.library.noteRecent(item);
      if (navigation.screen != Screen.live) navigation.go(Screen.live);
      // Interface Cinéma : lecteur en plein cadre avec un bouton de retour.
      navigation.openPlayer();
    case MediaKind.movie:
    case MediaKind.series:
      if (navigation.screen != screenFor(item.kind)) navigation.go(screenFor(item.kind));
      navigation.select(item.kind, item);
    case MediaKind.episode:
      playItem(context, item);
  }
}

/// Lance la lecture d'un film ou d'un épisode et affiche le lecteur (dans sa section, avec sa fiche derrière).
void playItem(BuildContext context, MediaItem item) {
  final navigation = context.navigation;
  final library = context.library;
  final kind = item.kind == MediaKind.episode ? MediaKind.series : item.kind;
  if (navigation.screen != screenFor(kind)) navigation.go(screenFor(kind));
  final selected = navigation.selected(kind);
  if (item.kind == MediaKind.episode) {
    if (selected == null || selected.name != item.group) {
      final series = library.items(MediaKind.series).where((s) => s.name == item.group).firstOrNull;
      if (series != null) navigation.select(kind, series);
    }
  } else if (selected?.id != item.id) {
    navigation.select(kind, item);
  }
  context.playback.play(item);
  library.noteRecent(item);
  navigation.openPlayer();
}
