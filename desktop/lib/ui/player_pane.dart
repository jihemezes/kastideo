import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import '../app_state.dart';
import '../core/playback.dart';
import '../l10n.dart';
import '../theme.dart';
import 'log_dialog.dart';

/// Lecteur : image, barre de contrôles compacte qui se cache seule, chargement, erreur (comme sur Mac).
class PlayerPane extends StatefulWidget {
  const PlayerPane({super.key});

  @override
  State<PlayerPane> createState() => _PlayerPaneState();
}

class _PlayerPaneState extends State<PlayerPane> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  final _focus = FocusNode();

  @override
  void dispose() {
    _hideTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _poke() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && context.playback.isPlaying) setState(() => _controlsVisible = false);
    });
  }

  Future<void> _toggleFullScreen() async {
    final full = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!full);
    if (!mounted) return;
    final navigation = context.navigation;
    if (!full && !navigation.theater) navigation.toggleTheater();
    if (full && navigation.theater) navigation.toggleTheater();
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.playback;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): playback.togglePause,
        const SingleActivator(LogicalKeyboardKey.keyM): playback.toggleMute,
        const SingleActivator(LogicalKeyboardKey.f11): _toggleFullScreen,
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          final item = playback.current;
          if (item != null) context.library.toggleFavorite(item.id);
        },
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: MouseRegion(
          onHover: (_) => _poke(),
          cursor: _controlsVisible || !playback.isPlaying ? MouseCursor.defer : SystemMouseCursors.none,
          child: GestureDetector(
            onTap: () => _focus.requestFocus(),
            onDoubleTap: context.navigation.toggleTheater,
            child: Container(
              color: Colors.black,
              child: ListenableBuilder(
                listenable: playback,
                builder: (context, _) {
                  if (playback.current == null) return const _Placeholder();
                  return Stack(fit: StackFit.expand, children: [
                    Video(controller: playback.video, controls: NoVideoControls, fill: Colors.black),
                    if (playback.isLoading && playback.errorMessage == null)
                      const Center(child: CircularProgressIndicator(color: Colors.white)),
                    if (playback.errorMessage != null) _ErrorView(message: playback.errorMessage!),
                    if (playback.startupTime != null) const _StartupBadge(),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
                      child: AnimatedOpacity(
                        opacity: _controlsVisible || !playback.isPlaying ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Center(child: ControlsBar(onFullScreen: _toggleFullScreen)),
                      ),
                    ),
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
          Text(tr('Choisissez une chaîne'), style: kText(15, color: KPalette.secondaryText)),
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
          child: Text('${tr('Prête en')} ${(time.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', L10n.english ? '.' : ',')} s',
              style: kText(12, weight: FontWeight.w600)),
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
            Text(message, textAlign: TextAlign.center, style: kText(15, weight: FontWeight.w500)),
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
          listenable: Listenable.merge([playback, navigation]),
          builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
            _BarButton(
              icon: playback.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              tooltip: tr('Lecture / pause (Espace)'),
              onTap: playback.togglePause,
            ),
            const SizedBox(width: 10),
            const _HealthPill(),
            const SizedBox(width: 12),
            if (playback.isLive)
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(tr('EN DIRECT'), style: kText(12, weight: FontWeight.w700)),
              ]),
            const SizedBox(width: 14),
            Flexible(
              child: Text(playback.current?.displayName ?? '',
                  style: kText(13, color: Colors.white.withValues(alpha: 0.75)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 14),
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
            _BarButton(
              icon: navigation.theater ? Icons.close_fullscreen_rounded : Icons.open_in_full_rounded,
              tooltip: '${tr('Mode cinéma')} (Ctrl+Entrée)',
              onTap: navigation.toggleTheater,
            ),
            _BarButton(icon: Icons.fullscreen_rounded, tooltip: '${tr('Plein écran')} (F11)', onTap: onFullScreen),
          ]),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 18,
          child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 22, color: Colors.white)),
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
            Text(label, style: kText(12, weight: FontWeight.w600)),
          ],
          if (quality != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(quality, style: kText(10, weight: FontWeight.w800)),
            ),
          ],
        ]),
      ),
    );
  }
}
