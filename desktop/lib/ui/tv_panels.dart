import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../version.dart';
import 'tv_shell.dart';

/// Un menu de la pile : titre, boutons et note de bas de panneau.
class TvPanelSpec {
  const TvPanelSpec({required this.title, required this.entries, this.footer});
  final String title;
  final List<TvEntry> Function(BuildContext context) entries;
  final String? footer;
}

class _Level {
  _Level(this.spec);
  final TvPanelSpec spec;
  int index = 0;
  bool shown = false;
  final scroll = ScrollController();
}

/// Réglages à la télécommande en panneaux : le menu occupe les 2/5 de gauche, son contenu se déploie dans les 3/5 de droite ;
/// un niveau de plus fait glisser les panneaux vers la gauche et vient couvrir en partie le menu parent.
class TvPanelHost extends StatefulWidget {
  const TvPanelHost({super.key, required this.root});
  final TvPanelSpec root;

  /// Ouvre un sous-menu dans le panneau de droite.
  static void open(BuildContext context, TvPanelSpec spec) => context.findAncestorStateOfType<_TvPanelHostState>()?.open(spec);

  /// Referme le panneau actif (retour au menu parent).
  static void close(BuildContext context) => context.findAncestorStateOfType<_TvPanelHostState>()?.close();

  @override
  State<TvPanelHost> createState() => _TvPanelHostState();
}

class _TvPanelHostState extends State<TvPanelHost> with TvKeys<TvPanelHost> {
  late final List<_Level> _levels = [_Level(widget.root)..shown = true];
  BuildContext? _inner; // contexte d'un descendant : c'est lui qui retrouve l'hôte (findAncestorState exclut l'état lui-même)
  static const _rowHeight = 78.0; // 64 de hauteur + 14 d'espace

  @override
  void initState() {
    super.initState();
    startTvKeys();
  }

  @override
  void dispose() {
    stopTvKeys();
    for (final l in _levels) {
      l.scroll.dispose();
    }
    super.dispose();
  }

  void open(TvPanelSpec spec) {
    final level = _Level(spec);
    setState(() => _levels.add(level));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => level.shown = true);
    });
  }

  void close() {
    if (_levels.length <= 1) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _levels.removeLast().scroll.dispose());
  }

  List<TvEntry> _entries(_Level level) => level.spec.entries(_inner ?? context);

  @override
  bool onTvKey(TvKey key) {
    final level = _levels.last;
    final entries = _entries(level);
    switch (key) {
      case TvKey.up:
        if (entries.isNotEmpty) setState(() => level.index = (level.index - 1 + entries.length) % entries.length);
      case TvKey.down:
        if (entries.isNotEmpty) setState(() => level.index = (level.index + 1) % entries.length);
      case TvKey.ok:
      case TvKey.right:
        if (entries.isNotEmpty && (key == TvKey.ok || _levels.length < 4)) {
          final e = entries[level.index.clamp(0, entries.length - 1)];
          if (key == TvKey.ok || e.icon == Icons.chevron_right_rounded) e.onTap?.call(_inner ?? context);
        }
      case TvKey.left:
        if (_levels.length > 1) close();
      case TvKey.menu:
        openTvLog(context);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(level));
    return true;
  }

  /// L'élément choisi reste au milieu de la liste.
  void _follow(_Level level) {
    if (!level.scroll.hasClients) return;
    final view = level.scroll.position.viewportDimension;
    final target = (level.index * _rowHeight - (view - _rowHeight) / 2).clamp(0.0, level.scroll.position.maxScrollExtent);
    level.scroll.animateTo(target, duration: const Duration(milliseconds: 110), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _levels.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: TvBackground(
        child: ListenableBuilder(
          listenable: Listenable.merge([context.library, context.settings]),
          builder: (context, _) => LayoutBuilder(builder: (context, box) {
            _inner = context;
            final w = box.maxWidth;
            final depth = _levels.length;
            return Column(children: [
              Expanded(
                child: Stack(children: [
                  // Marque à droite tant qu'aucun sous-menu n'est ouvert.
                  if (depth == 1)
                    Positioned(
                      left: 0.4 * w,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Opacity(
                          opacity: 0.35,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            ClipRRect(borderRadius: BorderRadius.circular(40), child: Image.asset('assets/images/icon.png', width: 180, height: 180)),
                            const SizedBox(height: 16),
                            Text('Kastideo $kVersion', style: kTextD(22, color: Colors.white70)),
                          ]),
                        ),
                      ),
                    ),
                  for (var i = 0; i < depth; i++) _panel(i, depth, w, i == depth - 1),
                ]),
              ),
              const Padding(padding: EdgeInsets.fromLTRB(0, 4, 0, 14), child: TvHints(items: [('OK', 'Choisir'), ('▲ ▼', 'Se déplacer'), ('◀', 'Revenir'), ('Retour', 'Revenir')])),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _panel(int i, int depth, double w, bool active) {
    final level = _levels[i];
    final root = i == 0;
    final width = root ? 0.4 * w : 0.6 * w;
    // Le niveau actif occupe les 3/5 de droite ; son parent direct reste visible en partie à gauche (derrière lui) ;
    // les niveaux plus anciens sont rangés hors de l'écran (sinon leur texte apparaît coupé sur le bord gauche).
    final distance = depth - 1 - i;
    final double position;
    if (distance == 0) {
      position = root ? 0.0 : 0.4 * w;
    } else if (distance == 1) {
      position = root ? 0.0 : 0.1 * w;
    } else {
      position = -w;
    }
    final left = level.shown ? position : w;
    final entries = _entries(level);
    level.index = level.index.clamp(0, entries.isEmpty ? 0 : entries.length - 1);
    return AnimatedPositioned(
      key: ObjectKey(level),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: left,
      top: 0,
      bottom: 0,
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: root ? Colors.transparent : const Color(0xF2160C20),
          borderRadius: root ? null : const BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28)),
          boxShadow: root ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 40)],
        ),
        child: Opacity(
          opacity: active ? 1 : 0.55,
          child: Padding(
            padding: EdgeInsets.fromLTRB(root ? 50 : 36, 36, root ? 20 : 40, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(level.spec.title, style: kTextD(root ? 36 : 30, weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: level.scroll,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
                  itemCount: entries.length,
                  itemBuilder: (context, n) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _button(entries[n], selected: n == level.index, active: active),
                  ),
                ),
              ),
              if (level.spec.footer != null && active)
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(level.spec.footer!, style: kTextD(15, color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _button(TvEntry e, {required bool selected, required bool active}) {
    final body = Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white.withValues(alpha: 0.13),
      child: Row(children: [
        Expanded(child: Text(e.label, style: kTextD(20, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (e.detail != null) ...[
          const SizedBox(width: 8),
          Flexible(child: Text(e.detail!, style: kTextD(16, color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
        const SizedBox(width: 8),
        Icon(e.icon, color: Colors.white70, size: 26),
      ]),
    );
    if (active) return TvFocusBox(selected: selected, radius: 16, scale: 1.03, child: body);
    // Panneau parent : l'élément ouvert reste repéré par un contour orange discret.
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? KPalette.orange.withValues(alpha: 0.8) : Colors.transparent, width: 3)),
      child: ClipRRect(borderRadius: BorderRadius.circular(13), child: body),
    );
  }
}
