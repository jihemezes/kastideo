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
  const TvRails({super.key, required this.kind, required this.onOpen});
  final MediaKind kind;
  final void Function(MediaItem item) onOpen;

  @override
  State<TvRails> createState() => TvRailsState();
}

class _Rail {
  const _Rail(this.title, this.items);
  final String title;
  final List<MediaItem> items;
}

class TvRailsState extends State<TvRails> {
  int _row = 0;
  int _col = 0;
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
      final resume = [for (final i in library.recentsOf(kind)) if (watch.inResume(i.id)) i].take(30).toList();
      if (resume.isNotEmpty) rails.add(_Rail(tr('Reprendre la lecture'), resume));
    }
    final favorites = library.favoritesOf(kind).take(40).toList();
    if (favorites.isNotEmpty) rails.add(_Rail(tr('Favoris'), favorites));
    final recents = library.recentsOf(kind).take(30).toList();
    if (recents.isNotEmpty) rails.add(_Rail(tr('Récents'), recents));
    for (final name in library.categories(kind).take(25)) {
      final items = library.itemsInCategory(kind, name).take(40).toList();
      if (items.isNotEmpty) rails.add(_Rail(library.prefs(kind).displayName(name), items));
    }
    return rails;
  }

  /// Touches de la télécommande. Renvoie vrai si la touche a été utilisée.
  bool handle(TvKey key) {
    final rails = _rails();
    if (rails.isEmpty) return false;
    setState(() {
      _row = _row.clamp(0, rails.length - 1);
      final count = rails[_row].items.length;
      switch (key) {
        case TvKey.left:
          if (_col > 0) _col--;
        case TvKey.right:
          if (_col < count - 1) _col++;
        case TvKey.up:
          if (_row > 0) {
            _row--;
            _col = _col.clamp(0, rails[_row].items.length - 1);
          }
        case TvKey.down:
          if (_row < rails.length - 1) {
            _row++;
            _col = _col.clamp(0, rails[_row].items.length - 1);
          }
        case TvKey.ok:
          widget.onOpen(rails[_row].items[_col.clamp(0, count - 1)]);
        case TvKey.menu:
          break;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    return true;
  }

  void _follow() {
    if (_vertical.hasClients) {
      final top = _row * _rowExtent;
      final view = _vertical.position.viewportDimension;
      if (top < _vertical.offset) {
        _vertical.jumpTo(top);
      } else if (top + _rowExtent > _vertical.offset + view) {
        _vertical.jumpTo(top + _rowExtent - view);
      }
    }
    final h = _horizontal[_row];
    if (h != null && h.hasClients) {
      final step = _cardW + 16;
      final target = (_col * step - step * 2).clamp(0.0, h.position.maxScrollExtent);
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

  @override
  Widget build(BuildContext context) {
    final rails = _rails();
    if (rails.isEmpty) {
      return Center(child: Text(context.library.sources.isEmpty ? tr('Aucune source : ajoutez-en une dans Réglages.') : tr('Rien à afficher.'), style: kTextD(22, color: Colors.white70)));
    }
    _row = _row.clamp(0, rails.length - 1);
    _col = _col.clamp(0, rails[_row].items.length - 1);
    final focus = rails[_row].items[_col];
    _scheduleDetails(focus);
    final d = _live ? null : context.info.details(focus.id);
    final parts = <String>[
      if ((d?.year ?? focus.year) != null) '${d?.year ?? focus.year}',
      if (d?.runtime != null) '${d!.runtime} min',
      if (d?.rating != null) '★ ${d!.rating!.toStringAsFixed(1)}',
      if (d != null && d.genres.isNotEmpty) d.genres.take(3).join(', '),
    ];
    final title = widget.kind == MediaKind.live ? tr('Direct') : (widget.kind == MediaKind.movie ? tr('Films') : tr('Séries'));
    return Column(children: [
      SizedBox(
        height: 214,
        child: Stack(children: [
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(colors: [Colors.transparent, Colors.black], begin: Alignment.centerLeft, end: Alignment.centerRight, stops: [0.25, 0.9]).createShader(r),
              blendMode: BlendMode.dstIn,
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.62,
                  child: PosterImage(url: d?.backdrop ?? d?.poster ?? focus.logo, name: focus.name, width: double.infinity, height: 214, fit: _live ? BoxFit.contain : BoxFit.cover),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 16, 60, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(title, style: kTextD(16, color: KPalette.orange, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(d?.title ?? focus.displayName, style: kTextD(32, weight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (parts.isNotEmpty) Text(parts.join('  ·  '), style: kTextD(16, color: Colors.white70)),
                  const SizedBox(height: 6),
                  if (d?.plot != null) Text(d!.plot!, style: kTextD(16, color: Colors.white70), maxLines: 3, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ),
          ),
        ]),
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
                  itemCount: rail.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final item = rail.items[i];
                    final selected = r == _row && i == _col;
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
    ]);
  }
}
