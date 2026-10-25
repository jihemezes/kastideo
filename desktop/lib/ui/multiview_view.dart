import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

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
  if (!settings.multiviewAvailable) {
    final open = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('MultiVue')),
        content: SizedBox(
          width: 460,
          child: Text(tr('La MultiVue affiche jusqu\'à 4 chaînes à la fois, chacune avec sa propre connexion à votre fournisseur. '
              'Elle est désactivée tant que vous n\'avez pas indiqué le nombre de connexions simultanées de votre abonnement '
              '(Réglages > Général > Lecture).')),
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
  if (watched != null && !recordingInPlayer && !multiview.contains(watched)) await multiview.add(watched);
  if (add != null && !await multiview.add(add) && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('La MultiVue est complète : retirez une chaîne d\'abord.'))));
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
      // MultiVue vide : on propose tout de suite une première chaîne.
      if (mounted && !_openedPicker && context.multiview.slots.isEmpty) {
        _openedPicker = true;
        _add();
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
    if (multiview.slots.length >= multiview.capacity && !multiview.slots.any((s) => s.item == null)) {
      _snack(tr('La MultiVue est complète : retirez une chaîne d\'abord.'));
      return;
    }
    final item = await pickMultiViewChannel(context);
    if (item != null) await multiview.add(item);
  }

  Future<void> _change(int index) async {
    final item = await pickMultiViewChannel(context);
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
    final name = await showDialog<String>(
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
          Text('${tr('Jusqu\'à')} ${context.multiview.capacity} ${tr('chaînes selon votre abonnement.')}', style: kTextD(13, color: Colors.white60)),
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
          Text('${multiview.channels.length} / ${multiview.capacity}', style: kTextD(13, color: Colors.white60)),
          if (busy) ...[
            const SizedBox(width: 12),
            Tooltip(
              message: tr('Un enregistrement ou un téléchargement utilise aussi une connexion à votre fournisseur.'),
              child: const Icon(Icons.info_outline_rounded, size: 18, color: KPalette.orange),
            ),
          ],
          const Spacer(),
          _LayoutPicker(multiview: multiview),
          const SizedBox(width: 10),
          _barButton(Icons.add_rounded, tr('Ajouter une chaîne (A)'), _add),
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
        seg(MultiLayout.focus, Icons.view_quilt_rounded, tr('Une grande et les autres en petit (G)')),
        seg(MultiLayout.row, Icons.view_column_rounded, tr('Côte à côte')),
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

  static List<Rect> rects(MultiLayout layout, int n, int big, Size size) {
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
      case MultiLayout.grid:
        return [for (var i = 0; i < n; i++) cell(i % 2, i ~/ 2, 2, 2)];
      case MultiLayout.focus:
        final bigW = (w - gap) * 0.74;
        final others = n - 1;
        final smallH = (h - gap * (others - 1)) / others;
        final result = <Rect>[];
        var k = 0;
        for (var i = 0; i < n; i++) {
          if (i == big) {
            result.add(Rect.fromLTWH(0, 0, bigW, h));
          } else {
            result.add(Rect.fromLTWH(bigW + gap, k * (smallH + gap), w - bigW - gap, smallH));
            k++;
          }
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
    // Case libre de la grille : bouton « + ».
    final showsAdd = n < multiview.capacity && n == 3 && (multiview.layout == MultiLayout.auto || multiview.layout == MultiLayout.grid);
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final r = rects(multiview.layout, n, big, size);
      final addRect = showsAdd ? rects(MultiLayout.grid, 4, 0, size)[3] : null;
      return Stack(children: [
        for (var i = 0; i < n; i++)
          AnimatedPositioned(
            key: ObjectKey(multiview.slots[i]),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: r[i].left,
            top: r[i].top,
            width: r[i].width,
            height: r[i].height,
            child: _SlotTile(index: i, slot: multiview.slots[i], onChange: () => onChange(i), focus: focus),
          ),
        if (addRect != null)
          Positioned.fromRect(
            rect: addRect,
            child: Hover(
              onTap: onAdd,
              builder: (context, hovering) => Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: hovering ? 0.08 : 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_rounded, size: 40, color: Colors.white54),
                    Text(tr('Ajouter une chaîne'), style: kTextD(13, color: Colors.white60)),
                  ]),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}

class _SlotTile extends StatefulWidget {
  const _SlotTile({required this.index, required this.slot, required this.onChange, required this.focus});
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
                              Text(item.displayName, style: kTextD(13, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      _tileButton(Icons.close_rounded, tr('Retirer'), () => multiview.remove(widget.index)),
                    ]),
                  ),
              ]),
            ),
          ),
        );
      },
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
Future<MediaItem?> pickMultiViewChannel(BuildContext context) =>
    showDialog<MediaItem>(context: context, builder: (_) => const DarkZone(child: _ChannelPicker()));

class _ChannelPicker extends StatefulWidget {
  const _ChannelPicker();

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
    if (_query.trim().length >= 2) {
      final q = _query.searchKey;
      items = library.items(MediaKind.live).where((i) => i.name.searchKey.contains(q)).take(200).toList();
    } else {
      items = switch (_tab) {
        0 => library.favoritesOf(MediaKind.live),
        1 => library.recentsOf(MediaKind.live),
        _ => library.items(MediaKind.live).take(300).toList(),
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
                      final already = multiview.contains(item);
                      final p = context.guide.current(item);
                      return ListTile(
                        dense: true,
                        enabled: !already,
                        leading: LogoView(url: item.logo, name: item.name, size: 32),
                        title: Text(item.displayName, style: kTextD(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(already ? tr('Déjà dans la MultiVue') : p?.title ?? item.group,
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
