import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app_state.dart';
import 'core/library.dart';
import 'core/playback.dart';
import 'theme.dart';
import 'ui/home_screen.dart';
import 'ui/live_screen.dart';
import 'ui/log_dialog.dart';
import 'ui/placeholder_screen.dart';

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
  final library = LibraryStore();
  final playback = PlaybackController();
  final navigation = NavigationModel();
  runApp(KastideoApp(library: library, playback: playback, navigation: navigation));
  await library.start();
}

class KastideoApp extends StatelessWidget {
  const KastideoApp({super.key, required this.library, required this.playback, required this.navigation});

  final LibraryStore library;
  final PlaybackController playback;
  final NavigationModel navigation;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      library: library,
      playback: playback,
      navigation: navigation,
      child: MaterialApp(
        title: 'Kastideo',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
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
        const SingleActivator(LogicalKeyboardKey.keyL, control: true, alt: true): () => showLogDialog(context),
        const SingleActivator(LogicalKeyboardKey.enter, control: true): navigation.toggleTheater,
        const SingleActivator(LogicalKeyboardKey.escape): navigation.exitTheater,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): playback.togglePause,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: navigation,
          builder: (context, _) => switch (navigation.screen) {
            Screen.home => const HomeScreen(),
            Screen.live => const LiveScreen(),
            Screen.movies => const PlaceholderScreen(title: 'Films', icon: Icons.movie_outlined),
            Screen.series => const PlaceholderScreen(title: 'Séries', icon: Icons.video_library_outlined),
          },
        ),
      ),
    );
  }
}
