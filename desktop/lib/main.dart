import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app_state.dart';
import 'core/alerts.dart';
import 'core/downloads.dart';
import 'core/guide.dart';
import 'core/multiview.dart';
import 'core/notify.dart';
import 'core/recording.dart';
import 'core/library.dart';
import 'core/media_info.dart';
import 'core/settings.dart';
import 'l10n.dart';
import 'core/playback.dart';
import 'theme.dart';
import 'ui/home_screen.dart';
import 'ui/catalog_screen.dart';
import 'ui/guide_view.dart';
import 'ui/multiview_view.dart';
import 'ui/recordings_view.dart';
import 'ui/log_dialog.dart';
import 'ui/settings_dialog.dart';
import 'ui/widgets.dart';
import 'ui/notices.dart';
import 'core/models.dart';

/// Port local qui sert de verrou : une seule instance de Kastideo à la fois.
const _instancePort = 47819;
const _instanceHello = 'kastideo-instance';

/// Vrai si cette instance est la seule ; sinon l'instance déjà ouverte est mise au premier plan.
Future<bool> _claimSingleInstance() async {
  try {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, _instancePort);
    server.listen((socket) async {
      socket.write(_instanceHello);
      await socket.flush();
      socket.destroy();
      await windowManager.show();
      await windowManager.restore();
      await windowManager.focus();
    });
    return true;
  } catch (_) {
    // Port occupé : est-ce une autre instance de Kastideo ?
    try {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, _instancePort, timeout: const Duration(seconds: 2));
      final answer = await socket.cast<List<int>>().transform(const SystemEncoding().decoder).join().timeout(const Duration(seconds: 2));
      socket.destroy();
      return !answer.contains(_instanceHello);
    } catch (_) {
      return true;
    }
  }
}

/// Fermeture de la fenêtre : la lecture est coupée et mpv libéré avant de quitter, puis le processus s'arrête.
class _CloseHandler with WindowListener {
  _CloseHandler(this.playback, this.watch, this.recordings, this.multiview);
  final MultiViewController multiview;
  final PlaybackController playback;
  final WatchProgressStore watch;
  final RecordingCenter recordings;
  bool _closing = false;

  @override
  Future<void> onWindowClose() async {
    if (_closing) return;
    _closing = true;
    try {
      await windowManager.hide();
    } catch (_) {}
    try {
      await watch.flush().timeout(const Duration(seconds: 1));
    } catch (_) {}
    try {
      await multiview.stopAll().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await recordings.shutdown().timeout(const Duration(seconds: 3));
    } catch (_) {}
    await playback.shutdown();
    exit(0);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (!await _claimSingleInstance()) exit(0);
  MediaKit.ensureInitialized();
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
  await SystemNotifier.setup();
  SystemNotifier.enabled = settings.systemNotifications;
  settings.addListener(() => SystemNotifier.enabled = settings.systemNotifications);
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
  final recordings = RecordingCenter(settings, playback, library);
  final downloads = DownloadManager(settings, playback);
  final alerts = AlertCenter(settings, library, guide);
  final multiview = MultiViewController(settings, playback);
  await windowManager.setPreventClose(true);
  windowManager.addListener(_CloseHandler(playback, watch, recordings, multiview));
  runApp(
    KastideoApp(
      library: library,
      playback: playback,
      navigation: navigation,
      settings: settings,
      watch: watch,
      info: info,
      guide: guide,
      recordings: recordings,
      downloads: downloads,
      alerts: alerts,
      multiview: multiview,
    ),
  );
  await library.start(autoRefresh: settings.autoRefresh);
  library.onSourceRemoved = guide.forgetSource;
  await recordings.start();
  await downloads.start();
  await alerts.start();
  await guide.start();
}

class KastideoApp extends StatefulWidget {
  const KastideoApp({
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

  @override
  State<KastideoApp> createState() => _KastideoAppState();
}

/// Applique le thème (sombre, clair ou celui du système) et la couleur d'accent, et redessine toute la fenêtre.
class _KastideoAppState extends State<KastideoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_apply);
    _apply(initial: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_apply);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _apply();

  void _apply({bool initial = false}) {
    final mode = widget.settings.appearance;
    final light = switch (mode) {
      AppearanceMode.light => true,
      AppearanceMode.dark => false,
      AppearanceMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light,
    };
    final accent = widget.settings.accent;
    final density = widget.settings.listDensity.factor;
    final cards = widget.settings.cardSize.factor;
    if (!initial && light == KPalette.light && accent == KPalette.accentChoice && density == KPalette.density && cards == KPalette.cardScale) return;
    KPalette.light = light;
    KPalette.accentChoice = accent;
    KPalette.density = density;
    KPalette.cardScale = cards;
    if (initial) return;
    setState(() {});
    // Les couleurs sont lues au moment de construire chaque élément : on les reconstruit tous (l'état est gardé).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void rebuild(Element e) {
        e.markNeedsBuild();
        e.visitChildren(rebuild);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
      windowManager.setBackgroundColor(KPalette.window).catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      library: widget.library,
      playback: widget.playback,
      navigation: widget.navigation,
      settings: widget.settings,
      watch: widget.watch,
      info: widget.info,
      guide: widget.guide,
      recordings: widget.recordings,
      downloads: widget.downloads,
      alerts: widget.alerts,
      multiview: widget.multiview,
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
        const SingleActivator(LogicalKeyboardKey.digit7, control: true): () => navigation.go(Screen.guide),
        const SingleActivator(LogicalKeyboardKey.keyM, control: true, alt: true): () => openMultiView(context),
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
        child: Stack(
          children: [
            Positioned.fill(
              child: ListenableBuilder(
                listenable: navigation,
                builder: (context, _) => switch (navigation.screen) {
                  Screen.home => const HomeScreen(),
                  Screen.live => const CatalogScreen(kind: MediaKind.live),
                  Screen.movies => const CatalogScreen(kind: MediaKind.movie),
                  Screen.series => const CatalogScreen(kind: MediaKind.series),
                  Screen.guide => const GuideScreen(),
                  Screen.recordings => const RecordingsScreen(),
                  Screen.multiview => const MultiViewScreen(),
                },
              ),
            ),
            const Positioned(top: 14, right: 14, child: NoticeOverlay()),
          ],
        ),
      ),
    );
  }
}
