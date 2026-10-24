import 'package:flutter/widgets.dart';

import 'core/library.dart';
import 'core/models.dart';
import 'core/playback.dart';

/// Écran affiché.
enum Screen { home, live, movies, series }

/// Ce qui est sélectionné dans la barre latérale du direct.
sealed class LiveFilter {
  const LiveFilter();
}

class AllChannels extends LiveFilter {
  const AllChannels();
}

class FavoriteChannels extends LiveFilter {
  const FavoriteChannels();
}

class RecentChannels extends LiveFilter {
  const RecentChannels();
}

class CategoryFilter extends LiveFilter {
  const CategoryFilter(this.name);
  final String name;
}

/// Navigation (équivalent du NavigationModel de la version Mac).
class NavigationModel extends ChangeNotifier {
  Screen screen = Screen.home;
  LiveFilter liveFilter = const AllChannels();
  bool theater = false;

  void go(Screen value) {
    screen = value;
    if (value != Screen.live) theater = false;
    notifyListeners();
  }

  void showLive(LiveFilter filter) {
    liveFilter = filter;
    screen = Screen.live;
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
    required super.child,
  });

  final LibraryStore library;
  final PlaybackController playback;
  final NavigationModel navigation;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

extension AppScopeContext on BuildContext {
  LibraryStore get library => AppScope.of(this).library;
  PlaybackController get playback => AppScope.of(this).playback;
  NavigationModel get navigation => AppScope.of(this).navigation;
}

/// Ouvre une chaîne : lecture + récents + affichage du direct.
void openItem(BuildContext context, MediaItem item) {
  context.playback.play(item);
  context.library.noteRecent(item);
  if (item.kind == MediaKind.live && context.navigation.screen != Screen.live) {
    context.navigation.go(Screen.live);
  }
}
