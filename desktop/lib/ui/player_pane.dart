import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../core/playback.dart';
import '../l10n.dart';
import '../theme.dart';
import 'log_dialog.dart';
import 'themes_view.dart';

/// Lecteur : image, barre de contrôles compacte qui se cache seule, chargement, erreur (comme sur Mac).
class PlayerPane extends StatefulWidget {
  const PlayerPane({super.key, this.showBack = false});

  /// Bouton « Retour à la fiche » (films et épisodes).
  final bool showBack;

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

  @override
  Widget build(BuildContext context) {
    final playback = context.playback;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): playback.togglePause,
        const SingleActivator(LogicalKeyboardKey.keyM): playback.toggleMute,
        const SingleActivator(LogicalKeyboardKey.f11): _toggleFullScreen,
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
        const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true): () => playback.jump(-10),
        const SingleActivator(LogicalKeyboardKey.bracketRight, control: true): () => playback.jump(30),
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
                    if (playback.startupTime != null && playback.isLive) const _StartupBadge(),
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
          builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [
            if (playback.isSeekable) ...[const ScrubBar(), const SizedBox(height: 4)],
            Row(mainAxisSize: MainAxisSize.min, children: [
            _BarButton(
              icon: playback.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              tooltip: tr('Lecture / pause (Espace)'),
              onTap: playback.togglePause,
            ),
            if (playback.isSeekable) ...[
              const SizedBox(width: 8),
              _BarButton(icon: Icons.replay_10_rounded, tooltip: tr('Reculer de 10 s (←)'), onTap: () => playback.jump(-10)),
              _BarButton(icon: Icons.forward_30_rounded, tooltip: tr('Avancer de 30 s (→)'), onTap: () => playback.jump(30)),
              const SizedBox(width: 8),
              Text('${formatClock(playback.position)} / ${formatClock(playback.duration)}',
                  style: kText(12, color: Colors.white.withValues(alpha: 0.85)).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ],
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
            Flexible(child: _NowTitle(playback.current)),
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
              Text(live ? tr('Retour') : tr('Retour à la fiche'), style: kText(13, weight: FontWeight.w600)),
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
            Text('${tr('Reprise à')} ${formatClock(at)}', style: kText(13, weight: FontWeight.w600)),
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
  Widget build(BuildContext context) {
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
                        style: kText(11, weight: FontWeight.w600)),
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
    final style = kText(13, color: Colors.white.withValues(alpha: 0.75));
    if (current == null) return const SizedBox();
    if (current.kind != MediaKind.live) return Text(current.displayName, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    return ListenableBuilder(
      listenable: context.guide,
      builder: (context, _) {
        final p = context.guide.current(current);
        return Tooltip(
          message: p == null ? current.name : '${p.title} · ${timeRange(p)}${p.desc == null ? '' : '\n\n${p.desc}'}',
          child: Text(p == null ? current.displayName : '${current.displayName} · ${p.title}',
              style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }
}
