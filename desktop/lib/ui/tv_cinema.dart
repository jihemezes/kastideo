import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../l10n.dart';
import '../theme.dart';
import 'tv_shell.dart';
import 'widgets.dart';

/// Style Cinéma à la télécommande : bannière de l'élément sélectionné, puis rangées d'affiches
/// (reprise, favoris, récents, catégories). Les touches sont transmises par l'écran parent (`handle`).
class TvRails extends StatefulWidget {
  const TvRails({super.key, required this.kind, required this.onOpen, required this.onSeeAll, required this.onCategories});
  final MediaKind kind;
  final void Function(MediaItem item) onOpen;

  /// « Voir tout » : ouvre la rangée complète (titre, tous les contenus).
  final void Function(String title, List<MediaItem> items) onSeeAll;

  /// Dernière rangée : liste de toutes les catégories (au-delà de celles affichées en rangées).
  final VoidCallback onCategories;

  @override
  State<TvRails> createState() => TvRailsState();
}

class _Rail {
  const _Rail(this.title, this.items, {List<MediaItem>? full, this.categoryCount}) : full = full ?? items;
  final String title;

  /// Contenus montrés dans la rangée (les premiers).
  final List<MediaItem> items;

  /// Tous les contenus (pour « Voir tout »).
  final List<MediaItem> full;

  /// Rangée finale « Toutes les catégories » : une seule vignette, sans contenus.
  final int? categoryCount;

  bool get isCategories => categoryCount != null;

  /// Nombre de vignettes : « Voir tout » au début, les contenus, « Voir tout » à la fin.
  int get length => isCategories ? 1 : items.length + 2;
}

class TvRailsState extends State<TvRails> {
  int _row = 0;
  int _col = 1; // 0 : « Voir tout » au début de la rangée ; 1 : premier contenu
  final _vertical = ScrollController();
  final _horizontal = <int, ScrollController>{};
  Timer? _load;
  String? _loadedId;

  bool get _live => widget.kind == MediaKind.live;
  double get _cardW => _live ? 190 : 118;
  double get _cardH => _live ? 107 : 177;
  double get _rowExtent => 34 + _cardH + 34 + 14;

  @override
  void dispose() {
    _load?.cancel();
    _vertical.dispose();
    for (final c in _horizontal.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<_Rail> _rails() {
    final library = context.library;
    final watch = context.watch;
    final kind = widget.kind;
    final rails = <_Rail>[];
    if (!_live) {
      final resume = [for (final i in library.recentsOf(kind)) if (watch.inResume(i.id)) i];
      if (resume.isNotEmpty) rails.add(_Rail(tr('Reprendre la lecture'), resume.take(30).toList(), full: resume));
    }
    final favorites = library.favoritesOf(kind);
    if (favorites.isNotEmpty) rails.add(_Rail(tr('Favoris'), favorites.take(40).toList(), full: favorites));
    final recents = library.recentsOf(kind);
    if (recents.isNotEmpty) rails.add(_Rail(tr('Récents'), recents.take(30).toList(), full: recents));
    final categories = library.categories(kind);
    for (final name in categories.take(25)) {
      final all = library.itemsInCategory(kind, name);
      if (all.isNotEmpty) rails.add(_Rail(library.prefs(kind).displayName(name), all.take(40).toList(), full: all));
    }
    final extra = categories.length - 25;
    if (extra > 0) rails.add(_Rail(tr('Toutes les catégories'), const [], categoryCount: categories.length));
    // Page de départ choisie dans les Réglages : sa rangée passe en premier.
    final settings = context.settings;
    var mode = settings.startPage(kind);
    if (mode == 'last') mode = settings.startLast(kind);
    final first = switch (mode) {
      'favorites' => tr('Favoris'),
      'recents' => tr('Récents'),
      _ when mode.startsWith('cat:') => library.prefs(kind).displayName(mode.substring(4)),
      _ => null,
    };
    if (first != null) {
      final i = rails.indexWhere((r) => r.title == first);
      if (i > 0) rails.insert(0, rails.removeAt(i));
    }
    return rails;
  }

  /// Touches de la télécommande. Renvoie vrai si la touche a été utilisée.
  bool handle(TvKey key) {
    final rails = _rails();
    if (rails.isEmpty) return false;
    setState(() {
      _row = _row.clamp(0, rails.length - 1);
      final rail = rails[_row];
      final count = rail.length;
      switch (key) {
        case TvKey.left:
          if (_col > 0) _col--;
        case TvKey.right:
          if (_col < count - 1) _col++;
        case TvKey.up:
          if (_row > 0) {
            _row--;
            _col = _col.clamp(0, rails[_row].length - 1);
          }
        case TvKey.down:
          if (_row < rails.length - 1) {
            _row++;
            _col = _col.clamp(0, rails[_row].length - 1);
          }
        case TvKey.ok:
          final c = _col.clamp(0, count - 1);
          if (rail.isCategories) {
            widget.onCategories();
          } else if (c == 0 || c == count - 1) {
            widget.onSeeAll(rail.title, rail.full);
          } else {
            widget.onOpen(rail.items[c - 1]);
          }
        case TvKey.menu:
          break;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    return true;
  }

  void _follow() {
    if (_vertical.hasClients) {
      final view = _vertical.position.viewportDimension;
      final target = (_row * _rowExtent - (view - _rowExtent) / 2).clamp(0.0, _vertical.position.maxScrollExtent);
      _vertical.animateTo(target, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
    }
    final h = _horizontal[_row];
    if (h != null && h.hasClients) {
      final step = _cardW + 16;
      final target = (_col * step - (h.position.viewportDimension - _cardW) / 2).clamp(0.0, h.position.maxScrollExtent);
      h.animateTo(target, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
    }
  }

  void _scheduleDetails(MediaItem item) {
    if (_live || _loadedId == item.id) return;
    _loadedId = item.id;
    _load?.cancel();
    _load = Timer(const Duration(milliseconds: 450), () {
      if (mounted) context.info.load(item);
    });
  }

  /// Vignette « Voir tout » (début et fin de rangée) ou « Toutes les catégories ».
  Widget _seeAllCard(_Rail rail, bool selected, {required bool atStart}) {
    final count = rail.isCategories ? rail.categoryCount! : rail.full.length;
    return SizedBox(
      width: _cardW,
      child: Column(children: [
        TvFocusBox(
          selected: selected,
          radius: 10,
          child: Container(
            width: _cardW,
            height: _cardH,
            color: Colors.white.withValues(alpha: selected ? 0.22 : 0.12),
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(atStart ? Icons.keyboard_double_arrow_left_rounded : Icons.grid_view_rounded, color: KPalette.orange, size: 34),
              const SizedBox(height: 8),
              Text(rail.isCategories ? tr('Toutes les catégories') : tr('Voir tout'), textAlign: TextAlign.center, style: kTextD(16, weight: FontWeight.w800)),
              Text('($count)', style: kTextD(14, color: Colors.white70)),
            ]),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rails = _rails();
    if (rails.isEmpty) {
      return Center(child: Text(context.library.sources.isEmpty ? tr('Aucune source : ajoutez-en une dans Réglages.') : tr('Rien à afficher.'), style: kTextD(22, color: Colors.white70)));
    }
    _row = _row.clamp(0, rails.length - 1);
    _col = _col.clamp(0, rails[_row].length - 1);
    final current = rails[_row];
    // Sur une vignette « Voir tout », l'en-tête montre la rangée ; sinon le contenu sélectionné.
    final MediaItem? focus = current.isCategories || _col == 0 || _col == current.length - 1 ? null : current.items[_col - 1];
    if (focus != null) _scheduleDetails(focus);
    final d = _live || focus == null ? null : context.info.details(focus.id);
    final parts = <String>[
      if (focus == null) '${current.isCategories ? current.categoryCount : current.full.length} ${current.isCategories ? tr('catégories') : tr('titres')}',
      if (focus != null && (d?.year ?? focus.year) != null) '${d?.year ?? focus.year}',
      if (d?.runtime != null) '${d!.runtime} min',
      if (d?.rating != null) '★ ${d!.rating!.toStringAsFixed(1)}',
      if (d != null && d.genres.isNotEmpty) d.genres.take(3).join(', '),
    ];
    final title = widget.kind == MediaKind.live ? tr('Direct') : (widget.kind == MediaKind.movie ? tr('Films') : tr('Séries'));
    return Stack(children: [
      const Positioned.fill(child: TvWatermark()),
      Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(60, 16, 60, 4),
        child: SizedBox(
          height: 118,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.6,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(title, style: kTextD(16, color: KPalette.orange, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(focus == null ? current.title : (d?.title ?? focus.displayName), style: kTextD(30, weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (parts.isNotEmpty) Text(parts.join('  ·  '), style: kTextD(16, color: Colors.white70)),
                const SizedBox(height: 4),
                if (d?.plot != null) Text(d!.plot!, style: kTextD(16, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          controller: _vertical,
          padding: const EdgeInsets.only(bottom: 20),
          itemExtent: _rowExtent,
          itemCount: rails.length,
          itemBuilder: (context, r) {
            final rail = rails[r];
            final controller = _horizontal.putIfAbsent(r, ScrollController.new);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 6, 60, 4),
                child: Text(rail.title, style: kTextD(19, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                height: _cardH + 40,
                child: ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
                  itemCount: rail.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final selected = r == _row && i == _col;
                    if (rail.isCategories || i == 0 || i == rail.length - 1) {
                      return _seeAllCard(rail, selected, atStart: i == 0 && !rail.isCategories);
                    }
                    final item = rail.items[i - 1];
                    final fraction = _live ? null : context.watch.fraction(item.id);
                    return SizedBox(
                      width: _cardW,
                      child: Column(children: [
                        TvFocusBox(
                          selected: selected,
                          radius: 10,
                          child: Stack(children: [
                            PosterImage(url: item.logo, name: item.name, width: _cardW, height: _cardH, fit: _live ? BoxFit.contain : BoxFit.cover),
                            if (fraction != null && fraction > 0 && fraction < 1)
                              Positioned(left: 0, right: 0, bottom: 0, child: LinearProgressIndicator(value: fraction, minHeight: 5, color: KPalette.orange)),
                          ]),
                        ),
                        const SizedBox(height: 4),
                        Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: kTextD(13, weight: selected ? FontWeight.w700 : FontWeight.w500)),
                      ]),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    ]),
    ]);
  }
}
