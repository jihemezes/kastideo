import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../core/desk.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../core/multiview.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'settings_dialog.dart';
import 'themes_view.dart';
import 'widgets.dart';

/// Écran d'où la MultiVue a été ouverte (retour).
Screen _returnTo = Screen.live;

/// Volume du lecteur principal coupé pendant la MultiVue (il continue seulement pour un enregistrement).
bool _mainDucked = false;

/// Ouvre la MultiVue (en y ajoutant [add], le cas échéant). La lecture principale s'arrête pour libérer sa connexion,
/// sauf si elle enregistre (son coupé), comme sur Mac.
Future<void> openMultiView(BuildContext context, {MediaItem? add}) async {
  final settings = context.settings;
  if (!settings.multiviewAvailableFor(context.library.selectableSources)) {
    final open = await showKDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('MultiVue')),
        content: SizedBox(
          width: 460,
          child: Text(tr('La MultiVue affiche jusqu\'à 4 chaînes à la fois, de sources différentes si vous voulez ; chaque source garde son nombre de connexions. '
              'Elle est désactivée tant qu\'aucune source n\'autorise deux flux : ajoutez une autre source de direct (liste publique, second abonnement) '
              'ou indiquez le nombre de connexions de votre abonnement (Réglages > Général > Lecture).')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Annuler'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Ouvrir les réglages'))),
        ],
      ),
    );
    if (open == true && context.mounted) showSettingsDialog(context);
    return;
  }
  final navigation = context.navigation;
  final playback = context.playback;
  final recordings = context.recordings;
  final multiview = context.multiview;
  if (navigation.screen != Screen.multiview) _returnTo = navigation.screen == Screen.home ? Screen.home : navigation.screen;
  // Une chaîne regardée devient la première vignette de la MultiVue.
  final watched = playback.current?.kind == MediaKind.live ? playback.current : null;
  final recordingInPlayer = recordings.active?.viaPlayer ?? false;
  if (recordingInPlayer) {
    _mainDucked = true;
    await playback.player.setVolume(0);
  } else if (playback.current != null) {
    await playback.stop();
  }
  navigation.go(Screen.multiview);
  multiview.ensureScreens();
  if (watched != null && !recordingInPlayer && !multiview.contains(watched)) await multiview.add(watched);
  if (add != null && !await multiview.add(add) && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('La MultiVue est complète ou les connexions de cette source sont toutes utilisées : retirez une chaîne d\'abord.'))));
  }
}

/// Ferme la MultiVue : tous ses flux s'arrêtent et l'écran précédent revient.
Future<void> closeMultiView(BuildContext context) async {
  final multiview = context.multiview;
  final playback = context.playback;
  final navigation = context.navigation;
  try {
    if (await windowManager.isFullScreen()) await windowManager.setFullScreen(false);
  } catch (_) {}
  await multiview.stopAll();
  if (_mainDucked) {
    _mainDucked = false;
    await playback.player.setVolume(playback.muted ? 0 : playback.volume);
  }
  navigation.go(_returnTo == Screen.multiview ? Screen.live : _returnTo);
}

/// Écran MultiVue : jusqu'à 4 chaînes, le son suit la vignette active (bordure orange).
class MultiViewScreen extends StatefulWidget {
  const MultiViewScreen({super.key});

  @override
  State<MultiViewScreen> createState() => _MultiViewScreenState();
}

class _MultiViewScreenState extends State<MultiViewScreen> {
  final _focus = FocusNode();
  bool _barVisible = true;
  Timer? _hideTimer;
  bool _openedPicker = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Les écrans sont prêts dès l'ouverture : chacun réservé à une source, la chaîne se choisit ensuite.
      if (mounted && !_openedPicker && context.multiview.slots.isEmpty) {
        _openedPicker = true;
        context.multiview.ensureScreens();
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _hideTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  /// Clavier : 1 à 4 (son), G (en grand), A (ajouter), M (muet), F / F11 (plein écran), Suppr (retirer), Échap.
  /// Gestionnaire global : les touches marchent même après un clic sur une vignette ou la fermeture d'un dialogue.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final focused = FocusManager.instance.primaryFocus?.context?.widget;
    if (focused is EditableText) return false;
    final multiview = context.multiview;
    final key = event.logicalKey;
    final digits = [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4];
    final pad = [LogicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad2, LogicalKeyboardKey.numpad3, LogicalKeyboardKey.numpad4];
    if (digits.contains(key) || pad.contains(key)) {
      multiview.setActive(digits.contains(key) ? digits.indexOf(key) : pad.indexOf(key));
    } else if (key == LogicalKeyboardKey.keyG) {
      multiview.makeBig(multiview.active);
    } else if (key == LogicalKeyboardKey.keyA) {
      _add();
    } else if (key == LogicalKeyboardKey.keyM) {
      context.playback.toggleMute().then((_) => multiview.refreshVolume());
    } else if (key == LogicalKeyboardKey.keyF || key == LogicalKeyboardKey.f11) {
      _toggleFullScreen();
    } else if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
      multiview.remove(multiview.active);
    } else if (key == LogicalKeyboardKey.escape) {
      _escape();
    } else {
      return false;
    }
    return true;
  }

  void _poke() {
    if (!_barVisible) setState(() => _barVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && context.multiview.isRunning) setState(() => _barVisible = false);
    });
  }

  Future<void> _add() async {
    final multiview = context.multiview;
    final empty = multiview.slots.indexWhere((s) => s.item == null);
    if (empty >= 0) {
      await _change(empty);
      return;
    }
    if (multiview.slots.length >= multiview.maxScreens) {
      _snack(tr('La MultiVue est complète : retirez une chaîne d\'abord.'));
      return;
    }
    final item = await pickMultiViewChannel(context);
    if (item != null && !await multiview.add(item)) _snack(tr('Les connexions de cette source sont toutes utilisées.'));
  }

  Future<void> _change(int index) async {
    final item = await pickMultiViewChannel(context, replacing: index);
    if (item != null && mounted) await context.multiview.replace(index, item);
  }

  void _snack(String text) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

  Future<void> _toggleFullScreen() async {
    final full = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!full);
  }

  Future<void> _escape() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    } else if (mounted) {
      await closeMultiView(context);
    }
  }

  Future<void> _saveGroup() async {
    final multiview = context.multiview;
    if (multiview.channels.isEmpty) return;
    final controller = TextEditingController(text: multiview.channels.map((c) => c.displayName).take(2).join(' + '));
    final name = await showKDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Mémoriser ce groupe')),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: tr('Nom du groupe'), hintText: tr('ex. Multiplex foot')),
            onSubmitted: (v) => Navigator.pop(c, v),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('Annuler'))),
          FilledButton(onPressed: () => Navigator.pop(c, controller.text), child: Text(tr('Enregistrer'))),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    multiview.saveGroup(name);
    _snack('${tr('Groupe mémorisé')} : ${name.trim()}');
  }

  Future<void> _groupsMenu(Offset position) async {
    final multiview = context.multiview;
    final library = context.library;
    final choice = await showMenu<Object>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: KPalette.menuDark,
      items: [
        PopupMenuItem(value: 'save', enabled: multiview.channels.isNotEmpty, child: Text(tr('Mémoriser ce groupe…'), style: kTextD(13))),
        if (multiview.groups.isNotEmpty) const PopupMenuDivider(),
        for (final g in multiview.groups)
          PopupMenuItem(
            value: g,
            child: Row(children: [
              const Icon(Icons.grid_view_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(child: Text('${g.name} (${g.ids.length})', style: kTextD(13), overflow: TextOverflow.ellipsis)),
              IconButton(
                tooltip: tr('Supprimer'),
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () {
                  multiview.deleteGroup(g);
                  Navigator.pop(context);
                },
              ),
            ]),
          ),
      ],
    );
    if (!mounted) return;
    if (choice == 'save') await _saveGroup();
    if (choice is MultiViewGroup) {
      final missing = await multiview.openGroup(choice, library.item);
      if (missing > 0) _snack('$missing ${tr('chaîne(s) du groupe introuvable(s) dans vos sources.')}');
      if (choice.ids.length > multiview.capacity) {
        _snack(tr('Le groupe contient plus de chaînes que de connexions disponibles : les premières seulement sont ouvertes.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) => DarkZone(child: Builder(builder: _buildDark));

  Widget _buildDark(BuildContext context) {
    final multiview = context.multiview;
    return SizedBox.expand(
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: MouseRegion(
          onHover: (_) => _poke(),
          child: Material(
            color: Colors.black,
            child: ListenableBuilder(
              listenable: multiview,
              builder: (context, _) => Stack(children: [
                Positioned.fill(
                  top: 52,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: multiview.slots.isEmpty ? _empty(context) : _MultiGrid(onChange: _change, onAdd: _add, focus: _focus),
                  ),
                ),
                Positioned(left: 0, right: 0, top: 0, child: _bar(context, multiview)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.grid_view_rounded, size: 54, color: Colors.white30),
          const SizedBox(height: 12),
          Text(tr('Aucune chaîne dans la MultiVue'), style: kTextD(16, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('${tr('Jusqu\'à')} ${context.multiview.capacity} ${tr('chaînes, selon les connexions de chaque source.')}', style: kTextD(13, color: Colors.white60)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add_rounded), label: Text(tr('Ajouter une chaîne'))),
        ]),
      );

  Widget _bar(BuildContext context, MultiViewController multiview) {
    final busy = context.recordings.active != null || context.downloads.isActive;
    return AnimatedOpacity(
      opacity: _barVisible || !multiview.isRunning ? 1 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: const Color(0xE6141416),
        child: Row(children: [
          TextButton.icon(
            onPressed: () => closeMultiView(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
            label: Text(tr('Retour'), style: kTextD(13, weight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(tr('MultiVue'), style: kRoundedD(20, FontWeight.w800)),
          const SizedBox(width: 10),
          IconButton(
            tooltip: tr('Un écran de moins'),
            visualDensity: VisualDensity.compact,
            onPressed: multiview.slots.length > 1 ? () => multiview.setScreenCount(multiview.slots.length - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Colors.white),
          ),
          Text('${tr('Écrans')} : ${multiview.slots.length}', style: kTextD(13, color: Colors.white70)),
          IconButton(
            tooltip: tr('Un écran de plus'),
            visualDensity: VisualDensity.compact,
            onPressed: multiview.slots.length < multiview.maxScreens ? () => multiview.setScreenCount(multiview.slots.length + 1) : null,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.white),
          ),
          if (busy) ...[
            const SizedBox(width: 12),
            Tooltip(
              message: tr('Un enregistrement ou un téléchargement utilise aussi une connexion à votre fournisseur.'),
              child: const Icon(Icons.info_outline_rounded, size: 18, color: KPalette.orange),
            ),
          ],
          const Spacer(),
          _LayoutPicker(multiview: multiview),
          if (multiview.layout == MultiLayout.focus && multiview.slots.length > 1)
            PopupMenuButton<int>(
              tooltip: tr('Taille des vignettes (glissez une vignette pour la déplacer, double-clic pour l\'échanger)'),
              icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 22),
              initialValue: multiview.pipSize,
              onSelected: multiview.setPipSize,
              itemBuilder: (_) => [
                for (final e in [(0, tr('Petites')), (1, tr('Moyennes')), (2, tr('Grandes'))]) PopupMenuItem(value: e.$1, child: Text(e.$2)),
              ],
            ),
          const SizedBox(width: 10),
          Builder(
            builder: (c) => _barButton(Icons.bookmarks_outlined, tr('Groupes mémorisés'), () {
              final box = c.findRenderObject() as RenderBox;
              _groupsMenu(box.localToGlobal(Offset(0, box.size.height)));
            }),
          ),
          _barButton(Icons.fullscreen_rounded, tr('Plein écran (F)'), _toggleFullScreen),
          const SizedBox(width: 6),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)),
            onPressed: () => closeMultiView(context),
            child: Text(tr('Tout arrêter')),
          ),
        ]),
      ),
    );
  }

  Widget _barButton(IconData icon, String tooltip, VoidCallback onTap) =>
      IconButton(tooltip: tooltip, onPressed: onTap, icon: Icon(icon, color: Colors.white, size: 22));
}

class _LayoutPicker extends StatelessWidget {
  const _LayoutPicker({required this.multiview});
  final MultiViewController multiview;

  @override
  Widget build(BuildContext context) {
    Widget seg(MultiLayout l, IconData icon, String tip) {
      final selected = multiview.layout == l;
      return Tooltip(
        message: tip,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => multiview.setLayout(l),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: selected ? Colors.white24 : Colors.transparent, borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 18, color: selected ? Colors.white : Colors.white60),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg(MultiLayout.auto, Icons.auto_awesome_mosaic_rounded, tr('Automatique (selon le nombre de chaînes)')),
        seg(MultiLayout.grid, Icons.grid_view_rounded, tr('Grille 2 × 2')),
        seg(MultiLayout.focus, Icons.picture_in_picture_alt_rounded, tr('Une grande + vignettes PIP déplaçables (G)')),
        seg(MultiLayout.row, Icons.view_column_rounded, tr('Côte à côte')),
        seg(MultiLayout.column, Icons.view_agenda_rounded, tr('Empilé')),
      ]),
    );
  }
}

/// Place les vignettes selon la disposition ; chaque vignette garde son lecteur quand elle change de place.
class _MultiGrid extends StatelessWidget {
  const _MultiGrid({required this.onChange, required this.onAdd, required this.focus});
  final void Function(int index) onChange;
  final VoidCallback onAdd;
  final FocusNode focus;

  static const gap = 6.0;

  static List<Rect> rects(MultiLayout layout, int n, int big, Size size, {List<MultiSlot>? slots, int pipSize = 1}) {
    final w = size.width, h = size.height;
    Rect cell(int col, int row, int cols, int rows) {
      final cw = (w - gap * (cols - 1)) / cols;
      final ch = (h - gap * (rows - 1)) / rows;
      return Rect.fromLTWH(col * (cw + gap), row * (ch + gap), cw, ch);
    }

    if (n <= 1) return [Rect.fromLTWH(0, 0, w, h)];
    switch (layout) {
      case MultiLayout.row:
        return [for (var i = 0; i < n; i++) cell(i, 0, n, 1)];
      case MultiLayout.column:
        return [for (var i = 0; i < n; i++) cell(0, i, 1, n)];
      case MultiLayout.grid:
        return [for (var i = 0; i < n; i++) cell(i % 2, i ~/ 2, 2, 2)];
      case MultiLayout.focus:
        // Une grande vignette plein cadre ; les autres en 16:9 flottantes, accrochées aux coins.
        const margin = 12.0, pgap = 8.0;
        final pw = (w * const [0.16, 0.22, 0.30][pipSize]).clamp(200.0, w / 2);
        final ph = pw * 9 / 16;
        final used = <int, int>{};
        final result = <Rect>[];
        for (var i = 0; i < n; i++) {
          if (i == big) {
            result.add(Rect.fromLTWH(0, 0, w, h));
            continue;
          }
          final corner = slots != null && i < slots.length ? slots[i].pipCorner : 3;
          final drag = slots != null && i < slots.length ? slots[i].pipDrag : Offset.zero;
          final k = used[corner] ?? 0;
          used[corner] = k + 1;
          final right = corner % 2 == 1, bottom = corner >= 2;
          var x = right ? w - margin - pw - k * (pw + pgap) : margin + k * (pw + pgap);
          final y = bottom ? h - margin - ph : margin;
          x = x.clamp(0.0, (w - pw) < 0 ? 0.0 : w - pw);
          result.add(Rect.fromLTWH(x + drag.dx, y + drag.dy, pw, ph));
        }
        return result;
      case MultiLayout.auto:
        if (n == 2) return [cell(0, 0, 2, 1), cell(1, 0, 2, 1)];
        return [for (var i = 0; i < n; i++) cell(i % 2, i ~/ 2, 2, 2)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiview = context.multiview;
    final n = multiview.slots.length;
    final big = multiview.big.clamp(0, n - 1);
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final r = rects(multiview.layout, n, big, size, slots: multiview.slots, pipSize: multiview.pipSize);
      final isFocus = multiview.layout == MultiLayout.focus && n > 1;
      // Les vignettes PIP passent au-dessus de la grande.
      final order = [for (var i = 0; i < n; i++) i]..sort((a, b) => (isFocus && a != big ? 1 : 0).compareTo(isFocus && b != big ? 1 : 0));
      return Stack(children: [
        for (final i in order)
          AnimatedPositioned(
            key: ObjectKey(multiview.slots[i]),
            duration: multiview.pipDragging ? Duration.zero : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: r[i].left,
            top: r[i].top,
            width: r[i].width,
            height: r[i].height,
            child: _SlotTile(
              index: i,
              slot: multiview.slots[i],
              onChange: () => onChange(i),
              focus: focus,
              pip: isFocus && i != big,
              onPipDrag: (d) => multiview.pipMove(i, d),
              onPipDrop: () => multiview.pipDrop(i, r[i].center, size),
            ),
          ),
      ]);
    });
  }
}

class _SlotTile extends StatefulWidget {
  const _SlotTile({
    required this.index,
    required this.slot,
    required this.onChange,
    required this.focus,
    this.pip = false,
    this.onPipDrag,
    this.onPipDrop,
  });
  final bool pip;
  final void Function(Offset delta)? onPipDrag;
  final VoidCallback? onPipDrop;
  final int index;
  final MultiSlot slot;
  final VoidCallback onChange;
  final FocusNode focus;

  @override
  State<_SlotTile> createState() => _SlotTileState();
}

class _SlotTileState extends State<_SlotTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final multiview = context.multiview;
    final slot = widget.slot;
    return ListenableBuilder(
      listenable: slot,
      builder: (context, _) {
        final item = slot.item;
        final active = multiview.active == widget.index;
        final programme = item == null ? null : context.guide.current(item);
        return MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.focus.requestFocus();
              if (item == null) {
                widget.onChange();
              } else {
                multiview.setActive(widget.index);
              }
            },
            onDoubleTap: item == null ? null : () => multiview.makeBig(widget.index),
            onPanUpdate: widget.pip ? (d) => widget.onPipDrag?.call(d.delta) : null,
            onPanEnd: widget.pip ? (_) => widget.onPipDrop?.call() : null,
            onPanCancel: widget.pip ? () => widget.onPipDrop?.call() : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active && item != null ? KPalette.orange : Colors.white12, width: active && item != null ? 3 : 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [
                if (item != null) Video(controller: slot.video, controls: NoVideoControls, fill: Colors.black),
                if (item == null)
                  Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, size: 40, color: Colors.white54),
                      Text(tr('Choisir une chaîne'), style: kTextD(13, color: Colors.white60)),
                    ]),
                  ),
                if (slot.loading) const Center(child: CircularProgressIndicator(color: Colors.white)),
                if (slot.failed && item != null)
                  Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline_rounded, color: KPalette.orange, size: 30),
                      const SizedBox(height: 6),
                      Text(tr('La chaîne ne répond pas.'), style: kTextD(13)),
                      Text(tr('Le fournisseur refuse peut-être une connexion de plus.'), style: kTextD(11, color: Colors.white60)),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: () => multiview.replace(widget.index, item),
                        child: Text(tr('Réessayer')),
                      ),
                    ]),
                  ),
                // Numéro de la vignette (touche du clavier) et son.
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${widget.index + 1}', style: kTextD(12, weight: FontWeight.w700)),
                      if (active && item != null) ...[
                        const SizedBox(width: 5),
                        Icon(context.playback.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 13, color: KPalette.orange),
                      ],
                    ]),
                  ),
                ),
                if (item != null && (_hover || active))
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xCC000000)]),
                        ),
                        child: Row(children: [
                          LogoView(url: item.logo, name: item.name, size: 26),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                              Text(
                                  context.library.selectableSources.length > 1 && context.library.sourceOf(item) != null
                                      ? '${item.displayName} · ${context.library.sourceOf(item)!.name}'
                                      : item.displayName,
                                  style: kTextD(13, weight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (programme != null)
                                Text('${hm(programme.start)} – ${hm(programme.stop)} · ${programme.title}',
                                    style: kTextD(11, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                if (_hover)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Row(children: [
                      if (item != null)
                        _tileButton(Icons.open_in_full_rounded, tr('En grand (double-clic)'), () => multiview.makeBig(widget.index)),
                      _tileButton(Icons.swap_horiz_rounded, tr('Changer de chaîne'), widget.onChange),
                      _sourceMenu(context, multiview),
                      _tileButton(Icons.close_rounded, tr('Arrêter cette chaîne'), () async {
                        await slot.stop();
                        multiview.refresh();
                      }),
                    ]),
                  ),
              ]),
            ),
          ),
        );
      },
    );
  }

  /// Source réservée à cet écran : un clic pour en changer (si plusieurs abonnements ou listes).
  Widget _sourceMenu(BuildContext context, MultiViewController multiview) {
    final sources = multiview.liveSources;
    if (sources.length < 2) return const SizedBox.shrink();
    final current = sources.where((s) => s.id == widget.slot.sourceId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: PopupMenuButton<String>(
        tooltip: tr('Source réservée à cet écran'),
        color: KPalette.menu,
        onSelected: (id) async {
          if (!await multiview.assign(widget.index, id) && context.mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('Les connexions de cette source sont toutes réservées.'))));
          }
        },
        itemBuilder: (_) => [
          for (final s in sources)
            PopupMenuItem(
              value: s.id,
              enabled: s.id == widget.slot.sourceId ||
                  multiview.assignedCount(s.id, excluding: widget.index) < context.settings.multiviewLimit(s),
              child: Text('${s.id == widget.slot.sourceId ? '✓ ' : ''}${MultiViewController.accountLabel(s)}', style: kTextD(13)),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
          child: Text(current == null ? tr('Source') : MultiViewController.accountLabel(current), style: kTextD(11, weight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _tileButton(IconData icon, String tip, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Tooltip(
          message: tip,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 16, color: Colors.white)),
            ),
          ),
        ),
      );
}

/// Choix d'une chaîne pour la MultiVue : favoris, récents, ou recherche dans toutes les chaînes.
Future<MediaItem?> pickMultiViewChannel(BuildContext context, {int? replacing, bool Function(MediaItem)? canPick}) =>
    showKDialog<MediaItem>(context: context, builder: (_) => DarkZone(child: _ChannelPicker(replacing: replacing, canPick: canPick)));

class _ChannelPicker extends StatefulWidget {
  const _ChannelPicker({this.replacing, this.canPick});

  /// Case remplacée (ses flux ne comptent pas dans la limite de la source) et règle de choix personnalisée (image dans l'image).
  final int? replacing;
  final bool Function(MediaItem)? canPick;

  @override
  State<_ChannelPicker> createState() => _ChannelPickerState();
}

class _ChannelPickerState extends State<_ChannelPicker> {
  String _query = '';
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final multiview = context.multiview;
    final List<MediaItem> items;
    // Écran réservé à une source : seules ses chaînes sont proposées (contenu brut, sans filtre de source active).
    final onlySource = widget.replacing != null && widget.replacing! >= 0 && widget.replacing! < multiview.slots.length
        ? multiview.slots[widget.replacing!].sourceId
        : null;
    bool inScope(MediaItem i) => onlySource == null || i.sourceId == onlySource;
    final pool = [
      for (final s in onlySource == null ? multiview.liveSources : multiview.liveSources.where((s) => s.id == onlySource))
        ...library.contentOf(s.id).where((i) => i.kind == MediaKind.live),
    ];
    if (_query.trim().length >= 2) {
      final q = _query.searchKey;
      items = pool.where((i) => i.name.searchKey.contains(q)).take(200).toList();
    } else {
      items = switch (_tab) {
        0 => library.favoritesOf(MediaKind.live).where(inScope).toList(),
        1 => library.recentsOf(MediaKind.live).where(inScope).toList(),
        _ => pool.take(300).toList(),
      };
    }
    return AlertDialog(
      backgroundColor: KPalette.panelDark,
      title: Text(tr('Ajouter une chaîne'), style: kRoundedD(20, FontWeight.w800)),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Column(children: [
          TextField(
            autofocus: true,
            style: kTextD(14),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              hintText: tr('Rechercher une chaîne'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: (_) {
              if (items.isNotEmpty) Navigator.pop(context, items.first);
            },
          ),
          const SizedBox(height: 10),
          if (_query.trim().length < 2)
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(tr('Favoris'))),
                ButtonSegment(value: 1, label: Text(tr('Récents'))),
                ButtonSegment(value: 2, label: Text(tr('Toutes'))),
              ],
              selected: {_tab},
              onSelectionChanged: (v) => setState(() => _tab = v.first),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(_tab == 0 && _query.isEmpty ? tr('Aucun favori : tapez le nom d\'une chaîne.') : tr('Aucune chaîne'),
                        style: kTextD(13, color: Colors.white54)),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemExtent: 50,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final already = widget.canPick == null && multiview.contains(item);
                      final allowed = widget.canPick?.call(item) ?? multiview.canPlay(item, replacing: widget.replacing);
                      final p = context.guide.current(item);
                      return ListTile(
                        dense: true,
                        enabled: !already && allowed,
                        leading: LogoView(url: item.logo, name: item.name, size: 32),
                        title: Text(item.displayName, style: kTextD(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(already ? tr('Déjà dans la MultiVue') : !allowed ? tr('Connexions de cette source toutes utilisées') : p?.title ?? item.group,
                            style: kTextD(11, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Annuler')))],
    );
  }
}
