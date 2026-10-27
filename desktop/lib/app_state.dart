import 'package:flutter/material.dart';

import 'l10n.dart';
import 'theme.dart';
import 'core/alerts.dart';
import 'core/downloads.dart';
import 'core/guide.dart';
import 'core/library.dart';
import 'core/media_info.dart';
import 'core/models.dart';
import 'core/multiview.dart';
import 'core/updater.dart';
import 'core/playback.dart';
import 'core/recording.dart';
import 'core/settings.dart';
import 'core/themes.dart';

/// Écran affiché.
enum Screen { home, live, movies, series, guide, recordings, multiview, library }

extension ScreenKind on Screen {
  MediaKind? get kind => switch (this) {
        Screen.live => MediaKind.live,
        Screen.movies => MediaKind.movie,
        Screen.series => MediaKind.series,
        Screen.home || Screen.guide || Screen.recordings || Screen.multiview || Screen.library => null,
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

/// Vues de la vidéothèque.
enum LibraryView { home, movies, series, videos, folders }

/// Tri de la vidéothèque.
enum LibrarySort { title, added, year }

/// Navigation (équivalent du NavigationModel de la version Mac).
class NavigationModel extends ChangeNotifier {
  Screen screen = Screen.home;
  final Map<MediaKind, CatalogFilter> _filters = {};
  bool theater = false;

  /// Film ou série affiché (fiche) — interface Classique : panneau de droite ; Cinéma : page entière.
  /// La vidéothèque a sa propre fiche ouverte.
  final Map<Object, MediaItem?> _selected = {};
  Object _key(MediaKind kind) => screen == Screen.library ? 'library' : kind;

  // MARK: Vidéothèque

  /// Source affichée (null : toutes), vue, dossier ouvert (navigation par dossiers), filtres et tri.
  String? librarySource;
  LibraryView libraryView = LibraryView.home;
  List<String> libraryFolder = const [];
  String? libraryGenre;
  int? libraryYear;
  bool libraryUnwatched = false;
  LibrarySort librarySort = LibrarySort.title;

  void setLibrary({
    Object? source = _keep,
    LibraryView? view,
    List<String>? folder,
    Object? genre = _keep,
    Object? year = _keep,
    bool? unwatched,
    LibrarySort? sort,
  }) {
    if (source != _keep) {
      librarySource = source as String?;
      libraryFolder = const [];
    }
    if (view != null) {
      libraryView = view;
      if (view != LibraryView.folders) libraryFolder = const [];
    }
    if (folder != null) libraryFolder = folder;
    if (genre != _keep) libraryGenre = genre as String?;
    if (year != _keep) libraryYear = year as int?;
    if (unwatched != null) libraryUnwatched = unwatched;
    if (sort != null) librarySort = sort;
    _selected['library'] = null;
    showPlayer = false;
    notifyListeners();
  }

  static const _keep = Object();

  /// Le lecteur est affiché (au lieu de la fiche) pour un film ou un épisode.
  bool showPlayer = false;

  /// Recherche dans la section affichée.
  String search = '';

  /// Mode « Modifier » des récents (cases à cocher, retirer, tout effacer).
  bool editingRecents = false;

  void setEditingRecents(bool value) {
    editingRecents = value;
    notifyListeners();
  }

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
  MediaItem? selected(MediaKind kind) => _selected[_key(kind)];

  void go(Screen value) {
    screen = value;
    editingRecents = false;
    if (value != Screen.live) theater = false;
    showPlayer = false;
    search = '';
    notifyListeners();
  }

  void show(MediaKind kind, CatalogFilter filter) {
    _filters[kind] = filter;
    editingRecents = false;
    screen = screenFor(kind);
    _selected[_key(kind)] = null;
    showPlayer = false;
    search = '';
    notifyListeners();
  }

  void select(MediaKind kind, MediaItem? item) {
    _selected[_key(kind)] = item;
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
    required this.recordings,
    required this.downloads,
    required this.alerts,
    required this.multiview,
    required this.updates,
    required super.child,
  });

  final LibraryStore library;
  final PlaybackController playback;
  final NavigationModel navigation;
  final AppSettings settings;
  final WatchProgressStore watch;
  final MediaInfoStore info;
  final GuideStore guide;
  final RecordingCenter recordings;
  final DownloadManager downloads;
  final AlertCenter alerts;
  final MultiViewController multiview;
  final UpdateService updates;

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
  RecordingCenter get recordings => AppScope.of(this).recordings;
  DownloadManager get downloads => AppScope.of(this).downloads;
  AlertCenter get alerts => AppScope.of(this).alerts;
  MultiViewController get multiview => AppScope.of(this).multiview;
  UpdateService get updates => AppScope.of(this).updates;
}

/// Une seule connexion : lancer [item] arrêterait l'enregistrement en cours ? On demande d'abord.
Future<bool> confirmConnection(BuildContext context, MediaItem item) async {
  final recordings = context.recordings;
  if (!recordings.conflictsWith(item)) return true;
  final active = recordings.active!;
  final channel = active.channel.displayName;
  if (item.kind == MediaKind.live && item.id == active.channel.id) {
    // Même chaîne, enregistrée en arrière-plan : elle passe dans le lecteur, l'enregistrement continue (nouveau fichier).
    await recordings.moveToPlayer();
    if (context.mounted) {
      context.library.noteRecent(item);
      if (context.navigation.screen != Screen.live) context.navigation.go(Screen.live);
      context.navigation.openPlayer();
    }
    return false;
  }
  final ok = await showKDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(tr('Enregistrement en cours')),
      content: Text('${tr('Kastideo enregistre')} $channel. ${tr('Votre abonnement n\'autorise qu\'une connexion : lancer ce contenu arrêtera l\'enregistrement.')}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Continuer l\'enregistrement'))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Arrêter et lancer'))),
      ],
    ),
  );
  if (ok != true) return false;
  await recordings.stop();
  return true;
}

/// Ouvre un contenu : chaîne → lecture ; film ou série → fiche (comme sur Mac).
Future<void> openItem(BuildContext context, MediaItem item) async {
  final navigation = context.navigation;
  if (item.kind == MediaKind.live && !await confirmConnection(context, item)) return;
  if (!context.mounted) return;
  switch (item.kind) {
    case MediaKind.live:
      context.playback.play(item);
      context.library.noteRecent(item);
      if (navigation.screen != Screen.live) navigation.go(Screen.live);
      // Interface Cinéma : lecteur en plein cadre avec un bouton de retour.
      navigation.openPlayer();
    case MediaKind.movie:
    case MediaKind.series:
      final target = context.library.isLibraryItem(item) ? Screen.library : screenFor(item.kind);
      if (navigation.screen != target) navigation.go(target);
      navigation.select(item.kind, item);
    case MediaKind.episode:
      playItem(context, item);
  }
}

/// Lance la lecture d'un film ou d'un épisode et affiche le lecteur (dans sa section, avec sa fiche derrière).
Future<void> playItem(BuildContext context, MediaItem item) async {
  if (!await confirmConnection(context, item)) return;
  if (!context.mounted) return;
  final navigation = context.navigation;
  final library = context.library;
  final kind = item.kind == MediaKind.episode ? MediaKind.series : item.kind;
  final target = library.isLibraryItem(item) ? Screen.library : screenFor(kind);
  if (navigation.screen != target) navigation.go(target);
  final selected = navigation.selected(kind);
  if (item.kind == MediaKind.episode) {
    if (selected == null || selected.name != item.group) {
      final series = library.seriesOf(item);
      if (series != null) navigation.select(kind, series);
    }
  } else if (selected?.id != item.id) {
    navigation.select(kind, item);
  }
  context.playback.play(item);
  library.noteRecent(item);
  navigation.openPlayer();
}
