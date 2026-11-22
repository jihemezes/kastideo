import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../core/multiview.dart';
import '../l10n.dart';
import '../theme.dart';
import 'multiview_view.dart' show closeMultiView, openMultiView;
import 'tv_shell.dart';

/// Ouvre la MultiVue à la télécommande (jusqu'à 4 chaînes, de sources ou de connexions différentes).
Future<void> openTvMultiView(BuildContext context, {MediaItem? add}) async {
  final library = context.library;
  if (!context.settings.multiviewAvailableFor(library.selectableSources)) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text(tr('La MultiVue demande au moins deux connexions : ajoutez une seconde source de direct, ou indiquez les connexions de votre abonnement (Réglages > Sources > Connexions simultanées).'), style: kTextD(20)),
    ));
    return;
  }
  await openMultiView(context, add: add);
}

/// Écran MultiVue de la télévision : ◀ ▲ ▼ ▶ changent de vignette, OK ouvre ses actions (son, chaîne, grand écran, retirer), Retour ferme.
class TvMultiViewScreen extends StatefulWidget {
  const TvMultiViewScreen({super.key});

  @override
  State<TvMultiViewScreen> createState() => _TvMultiViewScreenState();
}

class _TvMultiViewScreenState extends State<TvMultiViewScreen> with TvKeys<TvMultiViewScreen> {
  int _sel = 0;

  @override
  void initState() {
    super.initState();
    startTvKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.multiview.ensureScreens();
    });
  }

  @override
  void dispose() {
    stopTvKeys();
    super.dispose();
  }

  @override
  bool onTvKey(TvKey key) {
    final mv = context.multiview;
    final n = mv.slots.length;
    if (n == 0) return true;
    setState(() {
      _sel = _sel.clamp(0, n - 1);
      final cols = n <= 2 ? n : 2;
      switch (key) {
        case TvKey.left:
          if (_sel % cols > 0) _sel--;
        case TvKey.right:
          if (_sel % cols < cols - 1 && _sel + 1 < n) _sel++;
        case TvKey.up:
          if (_sel - cols >= 0) _sel -= cols;
        case TvKey.down:
          if (_sel + cols < n) _sel += cols;
        case TvKey.ok:
        case TvKey.menu:
          _actions(_sel);
      }
    });
    return true;
  }

  // MARK: Actions d'une vignette

  void _actions(int index) {
    final mv = context.multiview;
    if (index >= mv.slots.length) return;
    final slot = mv.slots[index];
    if (slot.item == null) {
      _pickChannel(index);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: slot.item!.displayName,
        entries: (c) => [
          TvEntry(tr('Écouter cette chaîne'), (c) {
            mv.setActive(index);
            Navigator.of(c).pop();
          }, icon: Icons.volume_up_rounded, detail: mv.active == index ? tr('Oui') : null),
          TvEntry(tr('Changer de chaîne'), (c) {
            Navigator.of(c).pop();
            _pickChannel(index);
          }, icon: Icons.swap_horiz_rounded),
          if (mv.slots.length > 1)
            TvEntry(mv.layout == MultiLayout.focus && mv.big == index ? tr('Revenir à la grille') : tr('Mettre en grand'), (c) {
              mv.makeBig(index);
              Navigator.of(c).pop();
            }, icon: Icons.zoom_out_map_rounded),
          TvEntry(tr('Mettre en plein écran'), (c) async {
            Navigator.of(c).pop();
            final item = slot.item;
            if (item == null) return;
            final playback = context.playback;
            final library = context.library;
            await closeMultiView(context);
            playback.play(item);
            library.noteRecent(item);
          }, icon: Icons.fullscreen_rounded),
          if (mv.slots.length > 1)
            TvEntry(tr('Retirer cet écran'), (c) async {
              await mv.remove(index);
              if (c.mounted) Navigator.of(c).pop();
            }, icon: Icons.close_rounded),
        ],
      ),
    ));
  }

  /// Vignette vide : choix de la source (si plusieurs ont encore une connexion), puis de la catégorie, puis de la chaîne.
  void _pickChannel(int index) {
    final mv = context.multiview;
    final slot = mv.slots[index];
    final library = context.library;
    final sources = [for (final s in mv.liveSources) if (slot.sourceId == s.id || mv.assignedCount(s.id, excluding: index) < context.settings.multiviewLimit(s)) s];
    if (sources.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('Toutes les connexions sont déjà utilisées.'), style: kTextD(20))));
      return;
    }
    void categories(String sourceId) {
      final items = [for (final i in library.items(MediaKind.live)) if (i.sourceId == sourceId) i];
      final groups = <String, List<MediaItem>>{};
      for (final i in items) {
        groups.putIfAbsent(i.group.isEmpty ? tr('Autres') : i.group, () => []).add(i);
      }
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => TvMenuPage(
          title: tr('Catégories'),
          entries: (_) => [
            for (final g in groups.entries)
              TvEntry(g.key, (c) {
                Navigator.of(c).push(MaterialPageRoute<void>(
                  builder: (_) => TvMenuPage(
                    title: g.key,
                    entries: (_) => [
                      for (final item in g.value.take(400))
                        TvEntry(item.displayName, (c) async {
                          if (await mv.assign(index, sourceId)) {
                            await mv.replace(index, item);
                          }
                          if (c.mounted) {
                            Navigator.of(c)
                              ..pop()
                              ..pop();
                          }
                        }, icon: Icons.live_tv_rounded),
                    ],
                  ),
                ));
              }, detail: '${g.value.length}'),
          ],
        ),
      ));
    }
    if (sources.length == 1) {
      categories(sources.first.id);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: tr('Source'),
        entries: (_) => [
          for (final s in sources)
            TvEntry(MultiViewController.accountLabel(s), (c) {
              Navigator.of(c).pop();
              categories(s.id);
            }, detail: '${mv.assignedCount(s.id)}/${context.settings.multiviewLimit(s)}', icon: Icons.dns_rounded),
        ],
      ),
    ));
  }

  // MARK: Dessin

  @override
  Widget build(BuildContext context) {
    final mv = context.multiview;
    return DarkZone(
      child: Container(
        color: Colors.black,
        child: ListenableBuilder(
          listenable: mv,
          builder: (context, _) {
            final n = mv.slots.length;
            if (n == 0) return Center(child: Text(tr('Chargement…'), style: kTextD(26, color: Colors.white70)));
            _sel = _sel.clamp(0, n - 1);
            return Stack(children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 56),
                  child: LayoutBuilder(builder: (context, box) => _layout(mv, box.biggest)),
                ),
              ),
              const Positioned(left: 0, right: 0, bottom: 8, child: Center(child: TvHints(items: [('OK', 'Actions'), ('◀ ▲ ▼ ▶', 'Vignette'), ('Retour', 'Fermer')]))),
            ]);
          },
        ),
      ),
    );
  }

  Widget _layout(MultiViewController mv, Size size) {
    final n = mv.slots.length;
    const gap = 8.0;
    final rects = <Rect>[];
    if (mv.layout == MultiLayout.focus && n > 1) {
      final bigW = size.width * 0.72;
      rects.addAll(List.filled(n, Rect.zero));
      rects[mv.big.clamp(0, n - 1)] = Rect.fromLTWH(0, 0, bigW - gap, size.height);
      final others = [for (var i = 0; i < n; i++) if (i != mv.big.clamp(0, n - 1)) i];
      final h = (size.height - gap * (others.length - 1)) / others.length;
      for (var k = 0; k < others.length; k++) {
        rects[others[k]] = Rect.fromLTWH(bigW, k * (h + gap), size.width - bigW, h);
      }
    } else if (n == 1) {
      rects.add(Offset.zero & size);
    } else if (n == 2) {
      final w = (size.width - gap) / 2;
      rects.addAll([Rect.fromLTWH(0, 0, w, size.height), Rect.fromLTWH(w + gap, 0, w, size.height)]);
    } else {
      final w = (size.width - gap) / 2;
      final h = (size.height - gap) / 2;
      for (var i = 0; i < n; i++) {
        rects.add(Rect.fromLTWH((i % 2) * (w + gap), (i ~/ 2) * (h + gap), w, h));
      }
    }
    return Stack(children: [
      for (var i = 0; i < n; i++)
        Positioned.fromRect(
          rect: rects[i],
          child: _tile(mv, i),
        ),
    ]);
  }

  Widget _tile(MultiViewController mv, int i) {
    final slot = mv.slots[i];
    final selected = i == _sel;
    final listening = i == mv.active;
    return ListenableBuilder(
      listenable: slot,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111116),
          border: Border.all(color: selected ? KPalette.orange : (listening ? Colors.white38 : Colors.white12), width: selected ? 5 : 2),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          if (slot.item != null) Video(controller: slot.video, controls: NoVideoControls, fill: Colors.black),
          if (slot.item == null)
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_circle_outline_rounded, size: 54, color: Colors.white54),
                const SizedBox(height: 8),
                Text(tr('OK : choisir une chaîne'), style: kTextD(20, color: Colors.white70)),
                if (context.library.sources.where((s) => s.id == slot.sourceId).firstOrNull case final s?)
                  Text(MultiViewController.accountLabel(s), style: kTextD(15, color: Colors.white38)),
              ]),
            ),
          if (slot.loading) const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (slot.failed) Center(child: Text(tr('Chaîne indisponible'), style: kTextD(22, color: Colors.redAccent))),
          if (slot.item != null)
            Positioned(
              left: 10,
              bottom: 8,
              right: 10,
              child: Row(children: [
                if (listening) const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                Expanded(child: Text(slot.item!.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: kTextD(18, weight: FontWeight.w700))),
              ]),
            ),
        ]),
      ),
    );
  }
}
