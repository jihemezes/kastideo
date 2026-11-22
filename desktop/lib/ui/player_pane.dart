import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' show AudioTrack, SubtitleTrack;
import 'package:media_kit_video/media_kit_video.dart';
import '../core/details.dart' show SeriesSeason;
import '../core/epg.dart' show nowSeconds;
import '../core/desk.dart';
import '../core/device.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../core/playback.dart';
import '../l10n.dart';
import '../theme.dart';
import 'cast_ui.dart';
import 'log_dialog.dart';
import 'pip_view.dart';
import '../core/multiview.dart';
import 'multiview_view.dart' show openMultiView;
import 'themes_view.dart';
import 'tv_multiview.dart';
import 'tv_player_menu.dart';
import 'tv_settings.dart' show openTvSubtitleStyle;

/// Barre d'options du lecteur à la télécommande (OK pendant la lecture) : ouverte ou non.
final ValueNotifier<bool> _tvBarOpen = ValueNotifier(false);

/// Retour : referme la barre d'options si elle est ouverte (vrai) ; sinon ne fait rien.
bool closeTvPlayerBar() {
  if (!_tvBarOpen.value) return false;
  _tvBarOpen.value = false;
  return true;
}

/// Lecteur : image, barre de contrôles compacte qui se cache seule, chargement, erreur (comme sur Mac).
class PlayerPane extends StatefulWidget {
  const PlayerPane({super.key, this.showBack = false, this.tvMode = false, this.placeholder});

  /// Bouton « Retour à la fiche » (films et épisodes).
  final bool showBack;

  /// Interface TV : les flèches et Échap sont laissées à l'interface TV (zapping, panneau).
  final bool tvMode;

  /// Affiché quand rien n'est en lecture.
  final Widget? placeholder;

  @override
  State<PlayerPane> createState() => _PlayerPaneState();
}

class _PlayerPaneState extends State<PlayerPane> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  final _focus = FocusNode();

  // Gestes tactiles : message au centre (volume, luminosité, position) et glissements en cours.
  String? _hud;
  Timer? _hudTimer;
  double _dragVolume = 100;
  double _dragBrightness = 0.5;
  double _dragSeek = 0;
  bool _dragLeftHalf = false;
  Axis? _dragAxis;

  // Barre d'options de la télécommande.
  int _barIndex = 0;
  Timer? _barTimer;

  @override
  void initState() {
    super.initState();
    _tvBarOpen.addListener(_barChanged);
  }

  void _barChanged() {
    _barTimer?.cancel();
    if (_tvBarOpen.value) _barTimer = Timer(const Duration(seconds: 10), () => _tvBarOpen.value = false);
    if (mounted) setState(() {});
  }

  void _barKeepOpen() {
    _barTimer?.cancel();
    _barTimer = Timer(const Duration(seconds: 10), () => _tvBarOpen.value = false);
  }

  /// Boutons de la barre : icône, texte et action (les pages de choix se referment seules après le choix).
  List<(IconData, String, VoidCallback)> _barItems() {
    final playback = context.playback;
    final current = playback.current;
    final live = playback.isLive;
    final isEpisode = current != null && context.library.seriesOf(current) != null;
    final recording = current != null && context.recordings.isRecording(current);
    return [
      (playback.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, playback.isPlaying ? tr('Pause') : tr('Lecture'), playback.togglePause),
      if (!live && playback.isSeekable) (Icons.replay_10_rounded, '−10 s', () => playback.jump(-10)),
      if (!live && playback.isSeekable) (Icons.forward_30_rounded, '+30 s', () => playback.jump(30)),
      if (playback.audioTracks.length > 1) (Icons.audiotrack_rounded, tr('Audio'), () => tvChooseAudio(context, pops: 1)),
      (Icons.subtitles_rounded, tr('Sous-titres'), () => playback.subtitleTracks.isEmpty && !playback.directRender
          ? ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('Aucun sous-titre dans ce flux.'), style: kTextD(20))))
          : tvChooseSubtitles(context, pops: 1)),
      if (!playback.directRender && playback.subtitleTracks.isNotEmpty) (Icons.text_fields_rounded, tr('Réglage'), () => openTvSubtitleStyle(context)),
      if (!live && playback.isSeekable) (Icons.speed_rounded, tr('Vitesse'), () => tvChooseRate(context, pops: 1)),
      (Icons.aspect_ratio_rounded, tr('Format'), () => tvChooseFormat(context, pops: 1)),
      if (live) (recording ? Icons.stop_circle_rounded : Icons.fiber_manual_record_rounded, recording ? tr('Arrêter') : tr('Enregistrer'), () => toggleRecording(context)),
      if (live && context.settings.multiviewAvailableFor(context.library.selectableSources)) (Icons.grid_view_rounded, tr('MultiVue'), () => openTvMultiView(context, add: current)),
      if (isEpisode) (Icons.skip_next_rounded, tr('Suivant'), () => tvNextEpisode(context)),
      if (isEpisode) (Icons.video_library_rounded, tr('Épisodes'), () => tvEpisodeList(context, pops: 1)),
      (Icons.more_horiz_rounded, tr('Options'), () => openTvPlayerOptions(context)),
    ];
  }

  /// Touches pendant que la barre est ouverte : ◀ ▶ choisissent un bouton, OK l'active, ▲ ▼ ou Retour la referment.
  KeyEventResult _barKey(KeyEvent event) {
    final key = event.logicalKey;
    final items = _barItems();
    _barIndex = _barIndex.clamp(0, items.length - 1);
    _barKeepOpen();
    if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() => _barIndex = (_barIndex - 1 + items.length) % items.length);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      setState(() => _barIndex = (_barIndex + 1) % items.length);
    } else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) items[_barIndex].$3();
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      _tvBarOpen.value = false;
    } else if (key == LogicalKeyboardKey.mediaPlayPause || key == LogicalKeyboardKey.mediaPlay || key == LogicalKeyboardKey.mediaPause) {
      context.playback.togglePause();
    } else if (key == LogicalKeyboardKey.contextMenu && event is KeyDownEvent) {
      openTvPlayerOptions(context);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _tvBar() {
    final playback = context.playback;
    final items = _barItems();
    final index = _barIndex.clamp(0, items.length - 1);
    final total = playback.duration.inMilliseconds;
    final fraction = total <= 0 || playback.isLive ? null : (playback.position.inMilliseconds / total).clamp(0.0, 1.0);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(40, 60, 40, 22),
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xDD000000)])),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: Text(playback.current?.displayName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: kTextD(24, weight: FontWeight.w800))),
            if (fraction != null) Text('${formatClock(playback.position)} / ${formatClock(playback.duration)}', style: kTextD(18, color: Colors.white70)),
          ]),
          if (fraction != null) ...[
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: fraction, minHeight: 6, color: KPalette.orange, backgroundColor: Colors.white24)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i == index ? 0.28 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: i == index ? KPalette.orange : Colors.transparent, width: 4),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(items[i].$1, size: 30, color: Colors.white),
                      Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: kTextD(14, weight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  void _showHud(String text) {
    setState(() => _hud = text);
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _hud = null);
    });
  }

  @override
  void dispose() {
    _tvBarOpen.removeListener(_barChanged);
    _tvBarOpen.value = false;
    _barTimer?.cancel();
    PipController.shared.close();
    _hideTimer?.cancel();
    _hudTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _poke() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && context.playback.isPlaying) {
        setState(() => _controlsVisible = false);
        // Télécommande : les boutons cachés ne gardent pas le focus.
        if (Device.isTv) _focus.requestFocus();
      }
    });
  }

  /// Touches de la télécommande (Android TV) quand l'image a le focus ; les boutons de la barre gardent les flèches.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (Device.isAndroid) _poke();
    if (Device.isTv && !widget.tvMode && _tvBarOpen.value) return _barKey(event);
    // Télévision : OK ouvre la barre d'options (audio, sous-titres, vitesse, format, enregistrement…).
    if (Device.isTv && !widget.tvMode && event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      _barIndex = 0;
      _tvBarOpen.value = true;
      return KeyEventResult.handled;
    }
    // Télévision : Menu ouvre les options du lecteur (pistes, vitesse, format, épisodes…).
    if (Device.isTv && !widget.tvMode && event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.contextMenu) {
      openTvPlayerOptions(context);
      return KeyEventResult.handled;
    }
    if (!Device.isAndroid || !node.hasPrimaryFocus || widget.tvMode) return KeyEventResult.ignored;
    final playback = context.playback;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.mediaPlayPause) {
      playback.togglePause();
    } else if (key == LogicalKeyboardKey.mediaPlay || key == LogicalKeyboardKey.mediaPause) {
      playback.togglePause();
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.mediaRewind) {
      playback.jump(-10);
      _showHud('−10 s');
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.mediaFastForward) {
      playback.jump(30);
      _showHud('+30 s');
    } else if (key == LogicalKeyboardKey.arrowUp) {
      playback.setVolume((playback.volume + 5).clamp(0, 100).toDouble());
      _showHud('${tr('Volume')} ${playback.volume.round()} %');
    } else if (key == LogicalKeyboardKey.arrowDown) {
      // Fait apparaître la barre et passe le focus à ses boutons.
      setState(() => _controlsVisible = true);
      FocusScope.of(context).focusInDirection(TraversalDirection.down);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // MARK: Gestes tactiles

  void _onTapTouch() {
    if (_controlsVisible && context.playback.isPlaying) {
      setState(() => _controlsVisible = false);
    } else {
      _poke();
    }
  }

  void _onDoubleTapTouch(Offset position, double width) {
    final playback = context.playback;
    if (position.dx < width / 3) {
      playback.jump(-10);
      _showHud('−10 s');
    } else if (position.dx > width * 2 / 3) {
      playback.jump(30);
      _showHud('+30 s');
    } else {
      playback.togglePause();
    }
  }

  Future<void> _dragStart(Offset position, double width) async {
    _dragLeftHalf = position.dx < width / 2;
    _dragVolume = context.playback.volume;
    _dragBrightness = await Device.brightness();
    _dragSeek = 0;
    _dragAxis = null;
  }

  void _dragUpdate(DragUpdateDetails d, double height) {
    final playback = context.playback;
    _dragAxis ??= d.delta.dx.abs() > d.delta.dy.abs() ? Axis.horizontal : Axis.vertical;
    if (_dragAxis == Axis.vertical) {
      final change = -d.delta.dy / (height * 0.7);
      if (_dragLeftHalf) {
        _dragBrightness = (_dragBrightness + change).clamp(0.02, 1.0);
        Device.setBrightness(_dragBrightness);
        _showHud('${tr('Luminosité')} ${(_dragBrightness * 100).round()} %');
      } else {
        _dragVolume = (_dragVolume + change * 100).clamp(0, 100);
        playback.setVolume(_dragVolume);
        _showHud('${tr('Volume')} ${_dragVolume.round()} %');
      }
    } else if (playback.isSeekable) {
      _dragSeek += d.delta.dx * 0.25;
      final s = _dragSeek.round();
      _showHud('${s >= 0 ? '+' : '−'}${s.abs()} s');
    }
  }

  void _dragEnd() {
    if (_dragAxis == Axis.horizontal && _dragSeek.abs() >= 1) context.playback.jump(_dragSeek.round());
    _dragAxis = null;
  }

  /// Retour : la fiche (films, épisodes, la lecture continue) ou le catalogue du direct (la chaîne s'arrête).
  void _back() {
    final navigation = context.navigation;
    if (navigation.theater) navigation.toggleTheater();
    if (context.playback.isLive) context.playback.stop();
    navigation.closePlayer();
  }

  Future<void> _toggleFullScreen() async {
    final full = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!full);
    if (!mounted) return;
    final navigation = context.navigation;
    if (!full && !navigation.theater) navigation.toggleTheater();
    if (full && navigation.theater) navigation.toggleTheater();
  }

  /// Souris : clic pour le focus, double-clic pour le mode cinéma. Doigt : un appui affiche ou masque la barre,
  /// double appui = ±10/30 s ou pause, glissements = volume (droite), luminosité (gauche), position (horizontal).
  Widget _gestures({required Widget child}) {
    if (!Device.isTouch) {
      return GestureDetector(
        onTap: () => _focus.requestFocus(),
        onDoubleTap: context.navigation.toggleTheater,
        child: child,
      );
    }
    return LayoutBuilder(builder: (context, box) {
      Offset? doubleTapAt;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTapTouch,
        onDoubleTapDown: (d) => doubleTapAt = d.localPosition,
        onDoubleTap: () {
          if (doubleTapAt != null) _onDoubleTapTouch(doubleTapAt!, box.maxWidth);
        },
        onPanStart: (d) => _dragStart(d.localPosition, box.maxWidth),
        onPanUpdate: (d) => _dragUpdate(d, box.maxHeight),
        onPanEnd: (_) => _dragEnd(),
        child: child,
      );
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_tvBarOpen.value,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) closeTvPlayerBar();
        },
        child: DarkZone(child: Builder(builder: _buildDark)),
      );

  Widget _buildDark(BuildContext context) {
    final playback = context.playback;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): playback.togglePause,
        const SingleActivator(LogicalKeyboardKey.keyM): playback.toggleMute,
        SingleActivator(LogicalKeyboardKey.period, control: !Device.isMac, meta: Device.isMac): () => stopPlayback(context),
        const SingleActivator(LogicalKeyboardKey.f11): _toggleFullScreen,
        if (!widget.tvMode && !Device.isAndroid) ...{
          const SingleActivator(LogicalKeyboardKey.escape): () {
            final navigation = context.navigation;
            if (navigation.theater) {
              navigation.exitTheater();
            } else if (widget.showBack) {
              _back();
            }
          },
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => playback.jump(-10),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => playback.jump(30),
        },
        SingleActivator(LogicalKeyboardKey.bracketLeft, control: !Device.isMac, meta: Device.isMac): () => playback.jump(-10),
        SingleActivator(LogicalKeyboardKey.bracketRight, control: !Device.isMac, meta: Device.isMac): () => playback.jump(30),
        const SingleActivator(LogicalKeyboardKey.keyR): () => toggleRecording(context),
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          final item = playback.current;
          if (item != null) context.library.toggleFavorite(item.id);
        },
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: MouseRegion(
          onHover: (_) => _poke(),
          cursor: _controlsVisible || !playback.isPlaying ? MouseCursor.defer : SystemMouseCursors.none,
          child: _gestures(
            child: Container(
              color: Colors.black,
              child: ListenableBuilder(
                listenable: playback,
                builder: (context, _) {
                  if (playback.current == null) {
                    final stopped = playback.stoppedItem;
                    if (stopped != null) return _StoppedView(item: stopped, onBack: widget.showBack ? _back : null);
                    return widget.placeholder ?? const _Placeholder();
                  }
                  return Stack(fit: StackFit.expand, children: [
                    if (playback.casting)
                      const CastPanel()
                    else
                      Video(
                        controller: playback.video,
                        controls: NoVideoControls,
                        fill: Colors.black,
                        fit: playback.videoFormat == VideoFormat.fill ? BoxFit.cover : BoxFit.contain,
                        aspectRatio: switch (playback.videoFormat) {
                          VideoFormat.wide => 16 / 9,
                          VideoFormat.standard => 4 / 3,
                          _ => null,
                        },
                      ),
                    if (playback.isLoading && playback.errorMessage == null)
                      const Center(child: CircularProgressIndicator(color: Colors.white)),
                    if (playback.errorMessage != null) _ErrorView(message: playback.errorMessage!),
                    const CastErrorNotice(),
                    if (playback.startupTime != null && playback.isLive && !widget.tvMode) const _StartupBadge(),
                    if (playback.resumedAt != null) const _ResumeNotice(),
                    if (widget.showBack)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: AnimatedOpacity(
                          opacity: _controlsVisible || !playback.isPlaying ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: _BackChip(live: playback.isLive, onTap: _back),
                        ),
                      ),
                    if (playback.isLive || PipController.shared.isOpen) const PipOverlay(),
                    if (pipAvailable(context, playback.current))
                      Positioned(
                        top: 14,
                        right: 14,
                        child: AnimatedOpacity(
                          opacity: _controlsVisible || !playback.isPlaying ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const PipButton(),
                        ),
                      ),
                    if (_hud != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(12)),
                          child: Text(_hud!, style: kTextD(18, weight: FontWeight.w700)),
                        ),
                      ),
                    // Direct à la télécommande : pas de barre (le bandeau, le panneau et la touche Menu la remplacent).
                    if (Device.isTv && !widget.tvMode && _tvBarOpen.value) _tvBar(),
                    if (!Device.isTv)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 18,
                        child: AnimatedOpacity(
                          opacity: _controlsVisible || !playback.isPlaying ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Center(child: ControlsBar(onFullScreen: _toggleFullScreen)),
                        ),
                      )
                    else if (!playback.isPlaying && !playback.isLoading && playback.errorMessage == null && playback.current != null)
                      const Center(child: Icon(Icons.pause_circle_filled_rounded, size: 96, color: Colors.white70)),
                  ]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Après le bouton Arrêt : message et relance en un clic.
class _StoppedView extends StatelessWidget {
  const _StoppedView({required this.item, this.onBack});
  final MediaItem item;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.stop_circle_outlined, size: 56, color: Colors.white54),
          const SizedBox(height: 12),
          Text(tr('Aucune lecture'), style: kTextD(17, weight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(mainAxisSize: MainAxisSize.min, children: [
            FilledButton.icon(
              onPressed: () async {
                if (!await confirmConnection(context, item)) return;
                if (context.mounted) context.playback.play(item);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('${tr('Relancer')} ${item.displayName}', overflow: TextOverflow.ellipsis),
            ),
            if (onBack != null) ...[
              const SizedBox(width: 10),
              FilledButton.tonal(onPressed: onBack, child: Text(tr('Retour'))),
            ],
          ]),
        ]),
      );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Opacity(
            opacity: 0.5,
            child: ClipRRect(borderRadius: BorderRadius.circular(21.5), child: Image.asset('assets/images/icon.png', width: 96, height: 96)),
          ),
          const SizedBox(height: 14),
          Text(tr('Choisissez une chaîne'), style: kTextD(15, color: KPalette.secondaryDark)),
        ]),
      );
}

/// Badge « Prête en x s » affiché quelques secondes après le démarrage.
class _StartupBadge extends StatefulWidget {
  const _StartupBadge();

  @override
  State<_StartupBadge> createState() => _StartupBadgeState();
}

class _StartupBadgeState extends State<_StartupBadge> {
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = context.playback.startupTime;
    if (time == null) return const SizedBox.shrink();
    return Positioned(
      top: 14,
      right: 14,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
          child: Text('${tr('Prête en')} ${(time.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', L10n.decimal)} s',
              style: kTextD(12, weight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.warning_amber_rounded, size: 46, color: Colors.white),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: kTextD(15, weight: FontWeight.w500)),
            const SizedBox(height: 18),
            Row(mainAxisSize: MainAxisSize.min, children: [
              FilledButton.tonal(onPressed: context.playback.retry, child: Text(tr('Réessayer'))),
              const SizedBox(width: 10),
              FilledButton.tonal(onPressed: () => showLogDialog(context), child: Text(tr('Journal de lecture'))),
            ]),
          ]),
        ),
      );
}

/// Barre de contrôles compacte (reproduction de ControlsBar sur Mac).
class ControlsBar extends StatelessWidget {
  const ControlsBar({super.key, required this.onFullScreen});
  final VoidCallback onFullScreen;

  @override
  Widget build(BuildContext context) {
    final playback = context.playback;
    final navigation = context.navigation;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xCC2A2A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18)],
        ),
        child: ListenableBuilder(
          listenable: Listenable.merge([playback, navigation, context.recordings]),
          builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [
            if (playback.isSeekable) ...[const ScrubBar(), const SizedBox(height: 4)],
            if (playback.isLive && playback.didStart && (playback.isTimeshifted || playback.peakDelay > 10)) ...[
              const TimeshiftBar(),
              const SizedBox(height: 4),
            ],
            Row(mainAxisSize: MainAxisSize.min, children: [
            _BarButton(
              icon: playback.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              tooltip: tr('Lecture / pause (Espace)'),
              onTap: playback.togglePause,
            ),
            _BarButton(
              icon: Icons.stop_rounded,
              tooltip: tr('Arrêter la lecture (Ctrl+.)'),
              onTap: () => stopPlayback(context),
            ),
            if (playback.isLive) ...[
              _BarButton(icon: Icons.skip_previous_rounded, tooltip: tr('Chaîne précédente'), onTap: () => zapChannel(context, -1)),
              _BarButton(icon: Icons.skip_next_rounded, tooltip: tr('Chaîne suivante'), onTap: () => zapChannel(context, 1)),
            ],
            if (playback.current?.kind == MediaKind.episode) ...[
              _BarButton(icon: Icons.skip_next_rounded, tooltip: tr('Épisode suivant'), onTap: () => _playNextEpisode(context)),
              _BarButton(icon: Icons.list_rounded, tooltip: tr('Épisodes…'), onTap: () => _showEpisodes(context)),
            ],
            if (playback.isSeekable) ...[
              const SizedBox(width: 8),
              _BarButton(icon: Icons.replay_10_rounded, tooltip: tr('Reculer de 10 s (←)'), onTap: () => playback.jump(-10)),
              _BarButton(icon: Icons.forward_30_rounded, tooltip: tr('Avancer de 30 s (→)'), onTap: () => playback.jump(30)),
              const SizedBox(width: 8),
              Text('${formatClock(playback.position)} / ${formatClock(playback.duration)}',
                  style: kTextD(12, color: Colors.white.withValues(alpha: 0.85)).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ],
            const SizedBox(width: 10),
            const _HealthPill(),
            const SizedBox(width: 12),
            if (playback.isLive && playback.isTimeshifted)
              Text('${tr('DIFFÉRÉ')} −${formatClock(Duration(seconds: playback.liveDelay.round()))}',
                  style: kTextD(12, weight: FontWeight.w700, color: KPalette.orange).copyWith(fontFeatures: const [FontFeature.tabularFigures()]))
            else if (playback.isLive)
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(tr('EN DIRECT'), style: kTextD(12, weight: FontWeight.w700)),
              ]),
            if (playback.isLive && playback.current != null) ...[
              const SizedBox(width: 8),
              _BarButton(
                icon: context.recordings.isRecording(playback.current!) ? Icons.stop_circle_rounded : Icons.fiber_manual_record_rounded,
                tooltip: context.recordings.isRecording(playback.current!) ? tr('Arrêter l\'enregistrement (R)') : tr('Enregistrer (R)'),
                color: Colors.redAccent,
                onTap: () => toggleRecording(context),
              ),
            ],
            const SizedBox(width: 14),
            Flexible(child: _NowTitle(playback.current)),
            const SizedBox(width: 14),
            const _PlayerOptionsMenu(),
            _BarButton(
              icon: playback.muted || playback.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              tooltip: tr('Couper / rétablir le son'),
              onTap: playback.toggleMute,
            ),
            SizedBox(
              width: 96,
              child: Slider(
                value: playback.muted ? 0 : playback.volume,
                max: 100,
                activeColor: KPalette.orange,
                inactiveColor: Colors.white.withValues(alpha: 0.25),
                onChanged: playback.setVolume,
              ),
            ),
            if (playback.isLive)
              _BarButton(
                icon: Icons.grid_view_rounded,
                tooltip: '${tr('Ouvrir la MultiVue avec cette chaîne')} (Ctrl+Alt+M)',
                onTap: () => openMultiView(context),
              ),
            const CastBarButton(),
            _BarButton(
              icon: navigation.theater ? Icons.close_fullscreen_rounded : Icons.open_in_full_rounded,
              tooltip: '${tr('Mode cinéma')} (Ctrl+Entrée)',
              onTap: navigation.toggleTheater,
            ),
            _BarButton(icon: Icons.fullscreen_rounded, tooltip: '${tr('Plein écran')} (F11)', onTap: onFullScreen),
          ]),
          ]),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.tooltip, required this.onTap, this.color = Colors.white});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 18,
          child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 22, color: color)),
        ),
      );
}

/// Pastille de santé du flux : couleur, mot au survol, définition (SD/HD/FHD/4K).
class _HealthPill extends StatefulWidget {
  const _HealthPill();

  @override
  State<_HealthPill> createState() => _HealthPillState();
}

class _HealthPillState extends State<_HealthPill> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: context.playback, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final playback = context.playback;
    final (color, label) = switch (playback.health) {
      HealthLevel.good => (Colors.green, tr('Excellent')),
      HealthLevel.fair => (Colors.orange, tr('Correct')),
      HealthLevel.poor => (Colors.red, tr('Instable')),
      HealthLevel.unknown => (Colors.grey, '—'),
    };
    final h = playback.videoHeight ?? 0;
    final quality = h >= 2000 ? '4K' : h >= 1000 ? 'FHD' : h >= 700 ? 'HD' : h > 0 ? 'SD' : null;
    final details = [
      '$label${h > 0 ? ' · ${playback.videoWidth}×$h' : ''}',
      '${playback.recentStalls} coupure(s) dans la dernière minute',
    ].join('\n');
    return Tooltip(
      message: details,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          if (_hovering || playback.health == HealthLevel.poor) ...[
            const SizedBox(width: 5),
            Text(label, style: kTextD(12, weight: FontWeight.w600)),
          ],
          if (quality != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(quality, style: kTextD(10, weight: FontWeight.w800)),
            ),
          ],
        ]),
      ),
    );
  }
}


/// Bouton « Retour à la fiche » en haut à gauche du lecteur (films, épisodes).
class _BackChip extends StatelessWidget {
  const _BackChip({required this.onTap, required this.live});
  final VoidCallback onTap;
  final bool live;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: live
            ? tr('Revenir aux chaînes (Échap)')
            : tr('Revenir à la fiche (la lecture continue en arrière-plan jusqu\'au choix d\'un autre contenu)'),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.chevron_left_rounded, size: 18, color: Colors.white),
              Text(live ? tr('Retour') : tr('Retour à la fiche'), style: kTextD(13, weight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

/// « Reprise à 12:34 » avec « Reprendre au début » (comme sur Mac).
class _ResumeNotice extends StatefulWidget {
  const _ResumeNotice();

  @override
  State<_ResumeNotice> createState() => _ResumeNoticeState();
}

class _ResumeNoticeState extends State<_ResumeNotice> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 8), () {
      if (mounted) context.playback.dismissResume();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final at = context.playback.resumedAt;
    if (at == null) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(22)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.history_rounded, size: 16, color: KPalette.orange),
            const SizedBox(width: 8),
            Text('${tr('Reprise à')} ${formatClock(at)}', style: kTextD(13, weight: FontWeight.w600)),
            const SizedBox(width: 10),
            TextButton(onPressed: context.playback.restartFromBeginning, child: Text(tr('Reprendre au début'))),
          ]),
        ),
      ),
    );
  }
}

/// « 1:23:45 » ou « 12:34 ».
String formatClock(Duration d) {
  final total = d.inSeconds;
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// Mini-timeline des films et épisodes : fine, plus épaisse au survol, avec l'heure visée.
class ScrubBar extends StatefulWidget {
  const ScrubBar({super.key});

  @override
  State<ScrubBar> createState() => _ScrubBarState();
}

class _ScrubBarState extends State<ScrubBar> {
  double? _hoverX;
  double? _drag;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: context.playback, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final playback = context.playback;
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth;
      final total = playback.duration.inMilliseconds;
      final progress = _drag ?? (total > 0 ? playback.position.inMilliseconds / total : 0.0);
      final active = _hoverX != null || _drag != null;
      final labelX = _hoverX ?? (_drag != null ? _drag! * width : null);
      return MouseRegion(
        onHover: (e) => setState(() => _hoverX = e.localPosition.dx.clamp(0, width)),
        onExit: (_) => setState(() => _hoverX = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (e) => setState(() => _drag = (e.localPosition.dx / width).clamp(0.0, 1.0)),
          onHorizontalDragEnd: (_) {
            if (_drag != null) playback.seek(_drag!);
            setState(() => _drag = null);
          },
          onTapUp: (e) => playback.seek((e.localPosition.dx / width).clamp(0.0, 1.0)),
          child: SizedBox(
            height: 18,
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: active ? 7 : 3,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: active ? 7 : 3,
                width: width * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(color: KPalette.orange, borderRadius: BorderRadius.circular(4)),
              ),
              if (active)
                Positioned(
                  left: width * progress.clamp(0.0, 1.0) - 6,
                  child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                ),
              if (labelX != null && total > 0)
                Positioned(
                  left: (labelX - 24).clamp(0.0, (width - 56).clamp(0.0, double.infinity)),
                  top: -22,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(10)),
                    child: Text(formatClock(Duration(milliseconds: (total * labelX / width).round())),
                        style: kTextD(11, weight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),
        ),
      );
    });
  }
}

/// Titre de la barre : chaîne et programme en cours (direct), sinon le titre du contenu.
class _NowTitle extends StatelessWidget {
  const _NowTitle(this.item);
  final MediaItem? item;

  @override
  Widget build(BuildContext context) {
    final current = item;
    final style = kTextD(13, color: Colors.white.withValues(alpha: 0.75));
    if (current == null) return const SizedBox();
    if (current.kind != MediaKind.live) return Text(current.displayName, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    return ListenableBuilder(
      listenable: context.guide,
      builder: (context, _) {
        final p = context.guide.current(current);
        final next = context.guide.next(current);
        final title = Text(p == null ? current.displayName : '${current.displayName} · ${p.title}',
            style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
        final tip = p == null
            ? current.name
            : '${p.title} · ${timeRange(p)}${p.desc == null ? '' : '\n\n${p.desc}'}${next == null ? '' : '\n\n${tr('Ensuite')} : ${next.title} · ${timeRange(next)}'}';
        // Programme en cours : barre de progression sous le titre, programme suivant en dessous.
        final total = p == null ? 0 : p.stopS - p.startS;
        final fraction = p != null && total > 0 ? ((nowSeconds() - p.startS) / total).clamp(0.0, 1.0) : null;
        return Tooltip(
          message: tip,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            title,
            if (fraction != null) ...[
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: fraction.toDouble(),
                  minHeight: 3,
                  color: KPalette.orange,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
            if (next != null)
              Text('${tr('Ensuite')} : ${next.title}',
                  style: kTextD(11, color: Colors.white.withValues(alpha: 0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        );
      },
    );
  }
}


/// Enregistre la chaîne regardée, ou arrête son enregistrement.
Future<void> toggleRecording(BuildContext context) async {
  final playback = context.playback;
  final recordings = context.recordings;
  final item = playback.current;
  if (item == null || item.kind != MediaKind.live) return;
  if (recordings.isRecording(item)) {
    await recordings.stop();
    return;
  }
  final p = context.guide.current(item);
  await recordings.recordNow(item, title: p?.title ?? '', stopS: p == null ? null : p.stopS + context.settings.marginAfter * 60);
}

/// Barre du différé : retard sur le direct, glisser pour revenir en arrière ou rattraper, vitesse, retour au direct.
class TimeshiftBar extends StatefulWidget {
  const TimeshiftBar({super.key});

  @override
  State<TimeshiftBar> createState() => _TimeshiftBarState();
}

class _TimeshiftBarState extends State<TimeshiftBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: context.playback, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final playback = context.playback;
    final depth = playback.peakDelay < 1 ? 1.0 : playback.peakDelay;
    final delay = (_drag ?? playback.liveDelay).clamp(0.0, depth);
    final shownDelay = Duration(seconds: delay.round());
    return SizedBox(
      width: 780,
      child: Row(children: [
        Text('−${formatClock(Duration(seconds: depth.round()))}', style: kTextD(11, color: Colors.white54)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: KPalette.orange,
              inactiveTrackColor: Colors.red.withValues(alpha: 0.55),
              thumbColor: Colors.white,
              trackHeight: 3,
            ),
            child: Slider(
              // De gauche (début du différé) à droite (direct).
              value: depth - delay,
              max: depth,
              onChanged: (v) => setState(() => _drag = depth - v),
              onChangeEnd: (v) {
                final target = depth - v;
                setState(() => _drag = null);
                if (target < playback.liveDelay - 2) {
                  // Vers la droite : rattrapage en accéléré jusqu'au point choisi (comme sur Mac).
                  playback.catchUp(toDelay: target);
                } else {
                  playback.seekDelay(target);
                }
              },
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(delay < 4.5 ? tr('Direct') : '−${formatClock(shownDelay)}',
              textAlign: TextAlign.right,
              style: kTextD(12, weight: FontWeight.w600, color: delay < 4.5 ? Colors.white : KPalette.orange)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<double>(
          tooltip: tr('Vitesse de lecture'),
          color: const Color(0xF02C2C2E),
          initialValue: playback.rate,
          onSelected: playback.setRate,
          itemBuilder: (_) => [
            for (final r in const [1.0, 1.25, 1.5, 2.0])
              PopupMenuItem(value: r, child: Text('×${r.toString().replaceAll('.0', '').replaceAll('.', ',')}', style: kTextD(13))),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text('×${playback.rate.toString().replaceAll('.0', '').replaceAll('.', ',')}', style: kTextD(12, weight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 6),
        if (delay >= 4.5) ...[
          TextButton(
            onPressed: () => playback.catchUp(),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(tr('Rattraper')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, visualDensity: VisualDensity.compact),
            onPressed: playback.returnToLive,
            child: Text(tr('Retour au direct')),
          ),
        ],
      ]),
    );
  }
}

Future<void> _playNextEpisode(BuildContext context) async {
  final playback = context.playback;
  final current = playback.current;
  if (current == null) return;
  final next = await nextEpisodeOf(context.library, context.info, current);
  if (!context.mounted) return;
  if (next == null) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('Dernier épisode de la série.'))));
    return;
  }
  playback.play(next);
  context.library.noteRecent(next);
}

Future<void> _showEpisodes(BuildContext context) async {
  final playback = context.playback;
  final current = playback.current;
  if (current == null) return;
  final seasons = await seasonsOfEpisode(context.library, context.info, current);
  if (!context.mounted) return;
  final picked = await showKDialog<MediaItem>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(tr('Épisodes')),
      content: SizedBox(
        width: 460,
        height: 460,
        child: seasons.isEmpty
            ? Text(tr('Aucun épisode.'))
            : ListView(children: [
                for (final SeriesSeason s in seasons) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                    child: Text('${tr('Saison')} ${s.number}', style: kTextD(13, weight: FontWeight.w700, color: KPalette.orange)),
                  ),
                  for (final e in s.episodes)
                    ListTile(
                      dense: true,
                      selected: e.id == current.id,
                      leading: context.watch.isWatched(e.id) ? const Icon(Icons.check_circle_rounded, size: 18, color: Colors.greenAccent) : null,
                      title: Text('${e.number != null ? '${e.number}. ' : ''}${e.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(c, e),
                    ),
                ],
              ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('Fermer')))],
    ),
  );
  if (picked == null || !context.mounted) return;
  playback.play(picked);
  context.library.noteRecent(picked);
}

/// Menu ⋯ du lecteur : vitesse (films, épisodes), pistes audio, sous-titres, format de l'image.
class _PlayerOptionsMenu extends StatelessWidget {
  const _PlayerOptionsMenu();

  @override
  Widget build(BuildContext context) {
    final playback = context.playback;
    String trackName(String? title, String? language, String id, int index) {
      final parts = [if (title != null && title.isNotEmpty) title, if (language != null && language.isNotEmpty) language];
      return parts.isEmpty ? '${tr('Piste')} ${index + 1}' : parts.join(' · ');
    }

    PopupMenuItem<Object> header(String text) => PopupMenuItem<Object>(
          enabled: false,
          height: 28,
          child: Text(text, style: kTextD(11, weight: FontWeight.w700, color: Colors.white54)),
        );
    PopupMenuItem<Object> entry(Object value, String text, bool selected) => PopupMenuItem<Object>(
          value: value,
          height: 34,
          child: Row(children: [
            SizedBox(width: 20, child: selected ? const Icon(Icons.check_rounded, size: 16) : null),
            Flexible(child: Text(text, style: kTextD(13), overflow: TextOverflow.ellipsis)),
          ]),
        );
    return PopupMenuButton<Object>(
      tooltip: tr('Options du lecteur'),
      color: const Color(0xF02C2C2E),
      icon: const Icon(Icons.more_horiz_rounded, size: 22, color: Colors.white),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v is double) {
          playback.setRate(v);
        } else if (v is VideoFormat) {
          playback.setVideoFormat(v);
        } else if (v is AudioTrack) {
          playback.selectAudioTrack(v);
        } else if (v is SubtitleTrack) {
          playback.selectSubtitleTrack(v);
        }
      },
      itemBuilder: (_) {
        final audio = playback.audioTracks;
        final subs = playback.subtitleTracks;
        final selectedAudio = playback.selectedAudio.id;
        final selectedSub = playback.selectedSubtitle.id;
        return [
          if (!playback.isLive && playback.isSeekable) ...[
            header(tr('Vitesse de lecture')),
            for (final r in const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
              entry(r, '×${r.toString().replaceAll('.0', '').replaceAll('.', ',')}', playback.rate == r),
          ],
          if (audio.length > 1) ...[
            header(tr('Audio')),
            for (var i = 0; i < audio.length; i++)
              entry(audio[i], trackName(audio[i].title, audio[i].language, audio[i].id, i), audio[i].id == selectedAudio),
          ],
          if (subs.isNotEmpty) ...[
            header(tr('Sous-titres')),
            entry(SubtitleTrack.no(), tr('Aucun'), selectedSub == 'no'),
            for (var i = 0; i < subs.length; i++)
              entry(subs[i], trackName(subs[i].title, subs[i].language, subs[i].id, i), subs[i].id == selectedSub),
          ],
          header(tr('Format de l\'image')),
          entry(VideoFormat.fit, tr('Ajuster'), playback.videoFormat == VideoFormat.fit),
          entry(VideoFormat.fill, tr('Remplir l\'écran'), playback.videoFormat == VideoFormat.fill),
          entry(VideoFormat.wide, '16:9', playback.videoFormat == VideoFormat.wide),
          entry(VideoFormat.standard, '4:3', playback.videoFormat == VideoFormat.standard),
        ];
      },
    );
  }
}
