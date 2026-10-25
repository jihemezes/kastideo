import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app_state.dart';
import 'core/guide.dart';
import 'core/library.dart';
import 'core/media_info.dart';
import 'core/settings.dart';
import 'l10n.dart';
import 'core/playback.dart';
import 'theme.dart';
import 'ui/home_screen.dart';
import 'ui/catalog_screen.dart';
import 'ui/log_dialog.dart';
import 'ui/settings_dialog.dart';
import 'ui/widgets.dart';
import 'core/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      title: 'Kastideo',
      size: Size(1280, 820),
      minimumSize: Size(960, 620),
      center: true,
      backgroundColor: Color(0xFF1E1E1E),
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
  final settings = AppSettings();
  await settings.load();
  L10n.apply(settings.language);
  final watch = WatchProgressStore();
  await watch.load();
  final library = LibraryStore();
  final playback = PlaybackController()
    ..settings = settings
    ..watchProgress = watch;
  final navigation = NavigationModel();
  final info = MediaInfoStore(library, settings);
  final guide = GuideStore(library);
  runApp(KastideoApp(
    library: library,
    playback: playback,
    navigation: navigation,
    settings: settings,
    watch: watch,
    info: info,
    guide: guide,
  ));
  await library.start(autoRefresh: settings.autoRefresh);
  library.onSourceRemoved = guide.forgetSource;
  await guide.start();
}

class KastideoApp extends StatelessWidget {
  const KastideoApp({
    super.key,
    required this.library,
    required this.playback,
    required this.navigation,
    required this.settings,
    required this.watch,
    required this.info,
    required this.guide,
  });

  final LibraryStore library;
  final PlaybackController playback;
  final NavigationModel navigation;
  final AppSettings settings;
  final WatchProgressStore watch;
  final MediaInfoStore info;
  final GuideStore guide;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      library: library,
      playback: playback,
      navigation: navigation,
      settings: settings,
      watch: watch,
      info: info,
      guide: guide,
      child: MaterialApp(
        title: 'Kastideo',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        scrollBehavior: const KastideoScrollBehavior(),
        home: const RootView(),
      ),
    );
  }
}

/// Fenêtre principale : écran choisi + raccourcis clavier (Ctrl à la place de ⌘).
class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.navigation;
    final playback = context.playback;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () => navigation.go(Screen.home),
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => navigation.go(Screen.live),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => navigation.go(Screen.movies),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => navigation.go(Screen.series),
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () => showSettingsDialog(context),
        const SingleActivator(LogicalKeyboardKey.keyL, control: true, alt: true): () => showLogDialog(context),
        const SingleActivator(LogicalKeyboardKey.enter, control: true): navigation.toggleTheater,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          // Échap : quitte le mode cinéma, sinon referme le lecteur (le direct s'arrête, comme sur Mac).
          if (navigation.theater) {
            navigation.exitTheater();
            return;
          }
          final kind = navigation.screen.kind;
          if (kind == null || !navigation.showPlayer) return;
          if (kind == MediaKind.live && context.settings.interfaceFor(kind) != InterfaceStyle.cinema) return;
          if (playback.isLive) playback.stop();
          navigation.closePlayer();
        },
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): playback.togglePause,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: navigation,
          builder: (context, _) => switch (navigation.screen) {
            Screen.home => const HomeScreen(),
            Screen.live => const CatalogScreen(kind: MediaKind.live),
            Screen.movies => const CatalogScreen(kind: MediaKind.movie),
            Screen.series => const CatalogScreen(kind: MediaKind.series),
          },
        ),
      ),
    );
  }
}
