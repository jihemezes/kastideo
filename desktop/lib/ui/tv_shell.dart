import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';

import '../app_state.dart';
import '../core/device.dart';
import '../core/log.dart';
import '../core/models.dart';
import '../core/tv_setup.dart';
import '../l10n.dart';
import '../theme.dart';
import '../version.dart';
import 'player_pane.dart';
import 'widgets.dart';

// Interface Android TV : écrans pensés pour la télécommande (flèches, OK, Retour).
// Les touches sont lues avant le système de focus de Flutter (comme l'interface TV du direct) : la sélection est
// gérée ici, par indices, et toujours dessinée avec un contour orange et un léger agrandissement, comme sur Apple TV.

/// Touches de la télécommande.
enum TvKey { up, down, left, right, ok, menu }

TvKey? tvKeyOf(KeyEvent event) {
  final k = event.logicalKey;
  if (k == LogicalKeyboardKey.arrowUp) return TvKey.up;
  if (k == LogicalKeyboardKey.arrowDown) return TvKey.down;
  if (k == LogicalKeyboardKey.arrowLeft) return TvKey.left;
  if (k == LogicalKeyboardKey.arrowRight) return TvKey.right;
  if (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter || k == LogicalKeyboardKey.gameButtonA) {
    return TvKey.ok;
  }
  if (k == LogicalKeyboardKey.contextMenu || k == LogicalKeyboardKey.info || k == LogicalKeyboardKey.colorF0Red) return TvKey.menu;
  return null;
}

/// Reçoit les touches de la télécommande tant que l'écran est au premier plan.
mixin TvKeys<T extends StatefulWidget> on State<T> {
  /// Renvoie vrai si la touche est traitée.
  bool onTvKey(TvKey key);

  void startTvKeys() => HardwareKeyboard.instance.addHandler(_tvHandler);
  void stopTvKeys() => HardwareKeyboard.instance.removeHandler(_tvHandler);

  bool _tvHandler(KeyEvent event) {
    if (!mounted || event is KeyUpEvent) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final key = tvKeyOf(event);
    if (key == null) return false;
    // OK et Menu ne se répètent pas (appui long).
    if (event is KeyRepeatEvent && (key == TvKey.ok || key == TvKey.menu)) return true;
    return onTvKey(key);
  }
}

/// Fond sombre des écrans TV.
class TvBackground extends StatelessWidget {
  const TvBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DarkZone(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0B0B10), Color(0xFF241236), Color(0xFF3B1233)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      );
}

/// Élément sélectionné : contour orange épais, halo et agrandissement (comme Apple TV).
class TvFocusBox extends StatelessWidget {
  const TvFocusBox({super.key, required this.selected, required this.child, this.radius = 18});
  final bool selected;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: selected ? 1.07 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: selected ? KPalette.orange : Colors.transparent, width: 5),
            boxShadow: selected ? [BoxShadow(color: KPalette.orange.withValues(alpha: 0.55), blurRadius: 28, spreadRadius: 1)] : null,
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(radius - 4), child: child),
        ),
      );
}

/// Rappel des touches, en bas de l'écran.
class TvHints extends StatelessWidget {
  const TvHints({super.key, this.items});
  final List<(String, String)>? items;

  @override
  Widget build(BuildContext context) {
    final list = items ?? [('OK', tr('Choisir')), ('◀ ▲ ▼ ▶', tr('Se déplacer')), (tr('Retour'), tr('Revenir')), ('Menu', tr('Journal'))];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final h in list) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
            child: Text(h.$1, style: kTextD(15, weight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(tr(h.$2), style: kTextD(15, color: Colors.white70)),
          const SizedBox(width: 28),
        ],
      ],
    );
  }
}

// MARK: Accueil

/// Accueil Android TV : grands pavés Direct, Films, Séries, puis Réglages et Journal.
class TvHome extends StatefulWidget {
  const TvHome({super.key});

  @override
  State<TvHome> createState() => _TvHomeState();
}

class _TvHomeState extends State<TvHome> with TvKeys<TvHome> {
  int _row = 0; // 0 pavés, 1 boutons
  int _col = 0;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    startTvKeys();
  }

  @override
  void dispose() {
    stopTvKeys();
    super.dispose();
  }

  int get _count => _row == 0 ? 3 : 2;

  @override
  bool onTvKey(TvKey key) {
    setState(() {
      switch (key) {
        case TvKey.left:
          _col = (_col - 1 + _count) % _count;
        case TvKey.right:
          _col = (_col + 1) % _count;
        case TvKey.up:
          if (_row == 1) {
            _row = 0;
            _col = _col.clamp(0, 2);
          }
        case TvKey.down:
          if (_row == 0) {
            _row = 1;
            _col = _col.clamp(0, 1);
          }
        case TvKey.menu:
          openTvLog(context);
        case TvKey.ok:
          _activate();
      }
    });
    return true;
  }

  void _activate() {
    final nav = context.navigation;
    if (_row == 0) {
      nav.go([Screen.live, Screen.movies, Screen.series][_col]);
    } else if (_col == 0) {
      openTvSettings(context);
    } else {
      openTvLog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        if (!_placed) {
          _placed = true;
          // Sans source : le curseur commence sur Réglages, pour ajouter la première.
          if (library.sources.isEmpty) {
            _row = 1;
            _col = 0;
          }
        }
        final tiles = [
          (tr('Direct'), Icons.live_tv_rounded, '${library.items(MediaKind.live).length} ${tr('chaînes')}', const [Color(0xFFD02F8A), Color(0xFFFF9933)]),
          (tr('Films'), Icons.movie_rounded, '${library.items(MediaKind.movie).length} ${tr('films')}', const [Color(0xFF6B3FD6), Color(0xFFD02F8A)]),
          (tr('Séries'), Icons.video_library_rounded, '${library.items(MediaKind.series).length} ${tr('séries')}', const [Color(0xFF3C4BD8), Color(0xFF6B3FD6)]),
        ];
        return TvBackground(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(80, 50, 80, 30),
            child: Column(
              children: [
                Row(children: [
                  Text('Kastideo', style: kTextD(46, weight: FontWeight.w800)),
                  const Spacer(),
                  Text('v$kVersion · Android TV', style: kTextD(18, color: Colors.white54)),
                ]),
                const Spacer(),
                if (library.sources.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Text(tr('Aucune source. Choisissez Réglages, puis « Ajouter une source avec mon téléphone ».'),
                        textAlign: TextAlign.center, style: kTextD(22, color: Colors.white)),
                  ),
                Row(children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 36),
                    Expanded(
                      child: TvFocusBox(
                        selected: _row == 0 && _col == i,
                        radius: 28,
                        child: Container(
                          height: 230,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: tiles[i].$4, begin: Alignment.topLeft, end: Alignment.bottomRight)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(tiles[i].$2, size: 56, color: Colors.white),
                            const Spacer(),
                            Text(tiles[i].$1, style: kTextD(40, weight: FontWeight.w800)),
                            Text(tiles[i].$3, style: kTextD(18, color: Colors.white70)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 36),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _small(0, Icons.settings_rounded, tr('Réglages')),
                  const SizedBox(width: 28),
                  _small(1, Icons.receipt_long_rounded, tr('Journal')),
                ]),
                const Spacer(),
                const TvHints(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _small(int index, IconData icon, String label) => SizedBox(
        width: 260,
        child: TvFocusBox(
          selected: _row == 1 && _col == index,
          radius: 22,
          child: Container(
            height: 84,
            color: Colors.white.withValues(alpha: 0.14),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Text(label, style: kTextD(22, weight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

// MARK: Films et séries

enum _Mode { grid, detail, episodes, player }

/// Films ou séries : catégories en haut, affiches en dessous, fiche, épisodes puis lecteur plein cadre.
class TvCatalog extends StatefulWidget {
  const TvCatalog({super.key, required this.kind});
  final MediaKind kind;

  /// Touche Retour : revient d'un cran (lecteur, épisodes, fiche). Vrai si quelque chose a été refermé.
  static bool Function()? onBack;

  @override
  State<TvCatalog> createState() => _TvCatalogState();
}

class _TvCatalogState extends State<TvCatalog> with TvKeys<TvCatalog> {
  int _chip = 0;
  int _cell = 0;
  bool _inChips = false;
  _Mode _mode = _Mode.grid;
  MediaItem? _item;
  int _button = 0; // fiche : Lecture, Épisodes, Favori
  int _season = 0;
  int _episode = 0;
  int _columns = 6;
  double _rowHeight = 300;
  final _scroll = ScrollController();
  final _chipScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    startTvKeys();
    TvCatalog.onBack = _back;
  }

  @override
  void dispose() {
    stopTvKeys();
    if (TvCatalog.onBack == _back) TvCatalog.onBack = null;
    _scroll.dispose();
    _chipScroll.dispose();
    super.dispose();
  }

  bool _back() {
    switch (_mode) {
      case _Mode.player:
        final playback = context.playback;
        if (playback.current != null) playback.stop();
        setState(() => _mode = _item?.kind == MediaKind.series ? _Mode.episodes : _Mode.detail);
        return true;
      case _Mode.episodes:
        setState(() => _mode = _Mode.detail);
        return true;
      case _Mode.detail:
        setState(() => _mode = _Mode.grid);
        return true;
      case _Mode.grid:
        return false;
    }
  }

  List<String> get _chipNames {
    final library = context.library;
    return [tr('Tout'), tr('Favoris'), tr('Récents'), ...library.categories(widget.kind)];
  }

  List<MediaItem> get _items {
    final library = context.library;
    final kind = widget.kind;
    return switch (_chip) {
      0 => library.items(kind),
      1 => library.favoritesOf(kind),
      2 => library.recentsOf(kind),
      _ => library.itemsInCategory(kind, library.categories(kind)[_chip - 3]),
    };
  }

  @override
  bool onTvKey(TvKey key) {
    if (_mode == _Mode.player) return false; // le lecteur gère lui-même les touches
    setState(() {
      switch (_mode) {
        case _Mode.grid:
          _gridKey(key);
        case _Mode.detail:
          _detailKey(key);
        case _Mode.episodes:
          _episodesKey(key);
        case _Mode.player:
          break;
      }
    });
    if (key == TvKey.menu) openTvLog(context);
    return true;
  }

  void _gridKey(TvKey key) {
    final items = _items;
    if (_inChips) {
      final count = _chipNames.length;
      switch (key) {
        case TvKey.left:
          _chip = (_chip - 1 + count) % count;
          _cell = 0;
        case TvKey.right:
          _chip = (_chip + 1) % count;
          _cell = 0;
        case TvKey.down:
          if (items.isNotEmpty) _inChips = false;
        case TvKey.up:
        case TvKey.ok:
        case TvKey.menu:
          break;
      }
      _scroll.hasClients ? _scroll.jumpTo(0) : null;
      _ensureChipVisible();
      return;
    }
    switch (key) {
      case TvKey.left:
        if (_cell % _columns > 0) _cell--;
      case TvKey.right:
        if (_cell % _columns < _columns - 1 && _cell + 1 < items.length) _cell++;
      case TvKey.down:
        if (_cell + _columns < items.length) _cell += _columns;
      case TvKey.up:
        if (_cell - _columns >= 0) {
          _cell -= _columns;
        } else {
          _inChips = true;
        }
      case TvKey.ok:
        if (items.isNotEmpty) {
          _item = items[_cell.clamp(0, items.length - 1)];
          _mode = _Mode.detail;
          _button = 0;
          _season = 0;
          _episode = 0;
          context.info.load(_item!);
        }
      case TvKey.menu:
        break;
    }
    _ensureCellVisible();
  }

  void _ensureCellVisible() {
    if (!_scroll.hasClients) return;
    final row = _cell ~/ _columns;
    final top = row * _rowHeight;
    final view = _scroll.position.viewportDimension;
    var target = _scroll.offset;
    if (top < _scroll.offset) target = top;
    if (top + _rowHeight > _scroll.offset + view) target = top + _rowHeight - view;
    if (target != _scroll.offset) _scroll.animateTo(target, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
  }

  void _ensureChipVisible() {
    if (!_chipScroll.hasClients) return;
    final target = (_chip * 170.0 - 300).clamp(0.0, _chipScroll.position.maxScrollExtent);
    _chipScroll.animateTo(target, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
  }

  // Fiche : Lecture / Épisodes / Favori.
  List<String> get _buttons {
    final item = _item!;
    final library = context.library;
    return [
      if (item.kind != MediaKind.series) tr('Lecture') else tr('Épisodes'),
      library.isFavorite(item.id) ? tr('Retirer des favoris') : tr('Ajouter aux favoris'),
      tr('Retour'),
    ];
  }

  void _detailKey(TvKey key) {
    final count = _buttons.length;
    switch (key) {
      case TvKey.left:
        _button = (_button - 1 + count) % count;
      case TvKey.right:
        _button = (_button + 1) % count;
      case TvKey.ok:
        final item = _item!;
        if (_button == 0) {
          if (item.kind == MediaKind.series) {
            _mode = _Mode.episodes;
            _season = 0;
            _episode = 0;
          } else {
            _play(item);
          }
        } else if (_button == 1) {
          context.library.toggleFavorite(item.id);
        } else {
          _mode = _Mode.grid;
        }
      case TvKey.up:
      case TvKey.down:
      case TvKey.menu:
        break;
    }
  }

  void _episodesKey(TvKey key) {
    final seasons = context.info.seasons(_item!.id) ?? const [];
    if (seasons.isEmpty) return;
    _season = _season.clamp(0, seasons.length - 1);
    final episodes = seasons[_season].episodes;
    switch (key) {
      case TvKey.left:
        if (_season > 0) {
          _season--;
          _episode = 0;
        }
      case TvKey.right:
        if (_season < seasons.length - 1) {
          _season++;
          _episode = 0;
        }
      case TvKey.up:
        if (_episode > 0) _episode--;
      case TvKey.down:
        if (_episode < episodes.length - 1) _episode++;
      case TvKey.ok:
        if (episodes.isNotEmpty) _play(episodes[_episode.clamp(0, episodes.length - 1)]);
      case TvKey.menu:
        break;
    }
  }

  Future<void> _play(MediaItem item) async {
    if (!await confirmConnection(context, item)) return;
    if (!mounted) return;
    context.playback.play(item);
    context.library.noteRecent(item);
    setState(() => _mode = _Mode.player);
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == _Mode.player) {
      return const DarkZone(child: PlayerPane());
    }
    return ListenableBuilder(
      listenable: Listenable.merge([context.library, context.info, context.watch]),
      builder: (context, _) => TvBackground(
        child: switch (_mode) {
          _Mode.grid => _gridView(context),
          _Mode.detail => _detailView(context),
          _Mode.episodes => _episodesView(context),
          _Mode.player => const SizedBox(),
        },
      ),
    );
  }

  Widget _gridView(BuildContext context) {
    final names = _chipNames;
    final items = _items;
    final title = widget.kind == MediaKind.movie ? tr('Films') : tr('Séries');
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 36, 60, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title, style: kTextD(38, weight: FontWeight.w800)),
            const SizedBox(width: 20),
            Text('${items.length}', style: kTextD(22, color: Colors.white60)),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            height: 70,
            child: ListView.separated(
              controller: _chipScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              itemCount: names.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final selected = i == _chip;
                final focused = selected && _inChips;
                return TvFocusBox(
                  selected: focused,
                  radius: 24,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    color: selected ? KPalette.orange : Colors.white.withValues(alpha: 0.14),
                    child: Text(names[i], style: kTextD(19, weight: FontWeight.w700, color: selected ? Colors.black : Colors.white)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(context.library.sources.isEmpty ? tr('Aucune source : ajoutez-en une dans Réglages.') : tr('Rien à afficher.'), style: kTextD(22, color: Colors.white70)))
                : LayoutBuilder(builder: (context, box) {
                    const spacing = 22.0;
                    _columns = 6;
                    final width = (box.maxWidth - 24 - spacing * (_columns - 1)) / _columns;
                    final height = width * 1.5;
                    _rowHeight = height + 44 + spacing;
                    return GridView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 40),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        mainAxisExtent: height + 44,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final selected = !_inChips && i == _cell;
                        final fraction = context.watch.fraction(item.id);
                        return Column(children: [
                          TvFocusBox(
                            selected: selected,
                            radius: 14,
                            child: Stack(children: [
                              PosterImage(url: item.logo, name: item.name, width: width, height: height),
                              if (context.watch.isWatched(item.id))
                                const Positioned(top: 8, right: 8, child: Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28)),
                              if (fraction != null && fraction > 0 && fraction < 1)
                                Positioned(left: 0, right: 0, bottom: 0, child: LinearProgressIndicator(value: fraction, minHeight: 6, color: KPalette.orange)),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: kTextD(16, weight: selected ? FontWeight.w700 : FontWeight.w500)),
                        ]);
                      },
                    );
                  }),
          ),
          const TvHints(),
        ],
      ),
    );
  }

  Widget _detailView(BuildContext context) {
    final item = _item!;
    final d = context.info.details(item.id);
    final buttons = _buttons;
    final parts = <String>[
      if ((d?.year ?? item.year) != null) '${d?.year ?? item.year}',
      if (d?.runtime != null) '${d!.runtime} min',
      if (d?.rating != null) '★ ${d!.rating!.toStringAsFixed(1)}',
      if (d != null && d.genres.isNotEmpty) d.genres.take(3).join(', '),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(80, 50, 80, 30),
      child: Column(children: [
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PosterImage(url: d?.poster ?? item.logo, name: item.name, width: 340, height: 510),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d?.title ?? item.displayName, style: kTextD(44, weight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Text(parts.join('  ·  '), style: kTextD(20, color: Colors.white70)),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Text(
                      d?.plot ?? (context.info.isLoading(item.id) ? tr('Chargement…') : ''),
                      maxLines: 9,
                      overflow: TextOverflow.ellipsis,
                      style: kTextD(20, color: Colors.white).copyWith(height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(width: 20),
                    TvFocusBox(
                      selected: _button == i,
                      radius: 22,
                      child: Container(
                        height: 76,
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        alignment: Alignment.center,
                        color: i == 0 ? KPalette.orange : Colors.white.withValues(alpha: 0.16),
                        child: Text(buttons[i], style: kTextD(22, weight: FontWeight.w800, color: i == 0 ? Colors.black : Colors.white)),
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
        const TvHints(),
      ]),
    );
  }

  Widget _episodesView(BuildContext context) {
    final item = _item!;
    final seasons = context.info.seasons(item.id);
    if (seasons == null || seasons.isEmpty) {
      return Center(
        child: Text(context.info.isLoading(item.id) ? tr('Chargement…') : tr('Aucun épisode.'), style: kTextD(26, color: Colors.white70)),
      );
    }
    final s = _season.clamp(0, seasons.length - 1);
    final episodes = seasons[s].episodes;
    final selected = _episode.clamp(0, episodes.isEmpty ? 0 : episodes.length - 1);
    // Fenêtre de 8 épisodes autour de la sélection.
    final start = (selected - 3).clamp(0, (episodes.length - 8).clamp(0, episodes.length));
    final shown = episodes.skip(start).take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(80, 44, 80, 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.displayName, style: kTextD(38, weight: FontWeight.w800)),
        const SizedBox(height: 14),
        SizedBox(
          height: 60,
          child: Row(children: [
            Icon(Icons.chevron_left_rounded, color: s > 0 ? Colors.white : Colors.white24, size: 36),
            Text('${tr('Saison')} ${seasons[s].number}', style: kTextD(26, weight: FontWeight.w800, color: KPalette.orange)),
            Icon(Icons.chevron_right_rounded, color: s < seasons.length - 1 ? Colors.white : Colors.white24, size: 36),
            const SizedBox(width: 18),
            Text('${episodes.length} ${tr('épisodes')}', style: kTextD(18, color: Colors.white60)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(children: [
            for (var i = 0; i < shown.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TvFocusBox(
                  selected: start + i == selected,
                  radius: 16,
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.white.withValues(alpha: 0.12),
                    child: Row(children: [
                      SizedBox(width: 70, child: Text('${shown[i].number ?? start + i + 1}', style: kTextD(22, weight: FontWeight.w800, color: KPalette.orange))),
                      Expanded(child: Text(shown[i].displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: kTextD(21, weight: FontWeight.w600))),
                      if (context.watch.isWatched(shown[i].id)) const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        const TvHints(items: [('OK', 'Lire'), ('▲ ▼', 'Épisode'), ('◀ ▶', 'Saison'), ('Retour', 'Fiche')]),
      ]),
    );
  }
}

// MARK: Pages simples (réglages, QR code, journal)

/// Ligne d'un menu TV.
class TvEntry {
  const TvEntry(this.label, this.onTap, {this.detail, this.icon = Icons.chevron_right_rounded});
  final String label;
  final String? detail;
  final IconData icon;
  final FutureOr<void> Function(BuildContext context)? onTap;
}

/// Liste de choix à la télécommande.
class TvMenuPage extends StatefulWidget {
  const TvMenuPage({super.key, required this.title, required this.entries, this.footer});
  final String title;
  final List<TvEntry> Function(BuildContext context) entries;
  final String? footer;

  @override
  State<TvMenuPage> createState() => _TvMenuPageState();
}

class _TvMenuPageState extends State<TvMenuPage> with TvKeys<TvMenuPage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    startTvKeys();
  }

  @override
  void dispose() {
    stopTvKeys();
    super.dispose();
  }

  @override
  bool onTvKey(TvKey key) {
    final entries = widget.entries(context);
    switch (key) {
      case TvKey.up:
        setState(() => _index = (_index - 1 + entries.length) % entries.length);
      case TvKey.down:
        setState(() => _index = (_index + 1) % entries.length);
      case TvKey.ok:
        if (entries.isNotEmpty) entries[_index.clamp(0, entries.length - 1)].onTap?.call(context);
      case TvKey.menu:
        openTvLog(context);
      case TvKey.left:
      case TvKey.right:
        break;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.library,
      builder: (context, _) {
        final entries = widget.entries(context);
        _index = _index.clamp(0, entries.isEmpty ? 0 : entries.length - 1);
        return TvBackground(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(120, 50, 120, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: kTextD(42, weight: FontWeight.w800)),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(children: [
                  for (var i = 0; i < entries.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TvFocusBox(
                        selected: i == _index,
                        radius: 18,
                        child: Container(
                          height: 82,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          color: Colors.white.withValues(alpha: 0.13),
                          child: Row(children: [
                            Expanded(child: Text(entries[i].label, style: kTextD(24, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (entries[i].detail != null) Text(entries[i].detail!, style: kTextD(19, color: Colors.white60)),
                            const SizedBox(width: 10),
                            Icon(entries[i].icon, color: Colors.white70, size: 32),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
              if (widget.footer != null) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(widget.footer!, style: kTextD(17, color: Colors.white54))),
              const TvHints(items: [('OK', 'Choisir'), ('▲ ▼', 'Se déplacer'), ('Retour', 'Revenir')]),
            ]),
          ),
        );
      },
    );
  }
}

void openTvSettings(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => TvMenuPage(
      title: tr('Réglages'),
      footer: 'Kastideo $kVersion',
      entries: (context) => [
        TvEntry(tr('Ajouter une source avec mon téléphone'), (c) => openTvQr(c), icon: Icons.qr_code_2_rounded),
        TvEntry(tr('Retirer une source'), (c) => openTvRemoveSource(c), detail: '${context.library.sources.length}'),
        TvEntry(tr('Journal de lecture'), (c) => openTvLog(c), icon: Icons.receipt_long_rounded),
      ],
    ),
  ));
}

void openTvRemoveSource(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => TvMenuPage(
      title: tr('Retirer une source'),
      footer: tr('OK retire immédiatement la source choisie.'),
      entries: (context) {
        final sources = context.library.sources;
        if (sources.isEmpty) return [TvEntry(tr('Aucune source'), null)];
        return [
          for (final s in List.of(sources)) TvEntry(s.name, (c) => c.library.removeSource(s), icon: Icons.delete_outline_rounded),
        ];
      },
    ),
  ));
}

void openTvQr(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TvQrPage()));
}

/// QR code : le téléphone ouvre la page de saisie servie par la télévision sur le réseau local.
class TvQrPage extends StatefulWidget {
  const TvQrPage({super.key});

  @override
  State<TvQrPage> createState() => _TvQrPageState();
}

class _TvQrPageState extends State<TvQrPage> with TvKeys<TvQrPage> {
  TvSetupServer? _server;
  String? _added;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    startTvKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final server = TvSetupServer(context.library, onAdded: (name) {
        if (mounted) setState(() => _added = name.isEmpty ? tr('Source') : name);
      });
      _server = server;
      await server.start();
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    stopTvKeys();
    _server?.stop();
    super.dispose();
  }

  @override
  bool onTvKey(TvKey key) {
    if (key == TvKey.menu) openTvLog(context);
    if (key == TvKey.ok && _added != null) Navigator.of(context).pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final server = _server;
    final address = server?.address;
    return TvBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(100, 50, 100, 30),
        child: Column(children: [
          Text(tr('Ajouter une source avec mon téléphone'), style: kTextD(38, weight: FontWeight.w800)),
          const SizedBox(height: 26),
          Expanded(
            child: !_ready
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : address == null
                    ? Center(
                        child: Text(tr('Impossible de se connecter au réseau local. Vérifiez que la télévision est sur le même Wi-Fi que le téléphone.'),
                            textAlign: TextAlign.center, style: kTextD(24)),
                      )
                    : Row(children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                          child: SizedBox(width: 380, height: 380, child: CustomPaint(painter: _QrPainter(address))),
                        ),
                        const SizedBox(width: 60),
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(tr('1. Branchez le téléphone sur le même Wi-Fi.'), style: kTextD(24)),
                            const SizedBox(height: 10),
                            Text(tr('2. Scannez le code, ou ouvrez cette adresse :'), style: kTextD(24)),
                            const SizedBox(height: 8),
                            Text(address, style: kTextD(26, weight: FontWeight.w800, color: KPalette.orange)),
                            const SizedBox(height: 10),
                            Text(tr('3. Saisissez ce code, puis les informations de la source :'), style: kTextD(24)),
                            const SizedBox(height: 8),
                            Text(server!.code, style: kTextD(64, weight: FontWeight.w800)),
                            if (_added != null) ...[
                              const SizedBox(height: 18),
                              Text('✓ ${tr('Source ajoutée')} : $_added', style: kTextD(26, weight: FontWeight.w800, color: Colors.greenAccent)),
                              Text(tr('OK pour terminer, ou ajoutez-en une autre.'), style: kTextD(20, color: Colors.white70)),
                            ],
                          ]),
                        ),
                      ]),
          ),
          const TvHints(items: [('OK', 'Terminer'), ('Retour', 'Revenir')]),
        ]),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.data);
  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final image = QrImage(QrCode(payload: QrPayload.fromString(data), errorCorrectLevel: QrErrorCorrectLevel.medium));
    final n = image.moduleCount;
    final cell = size.width / n;
    final paint = Paint()..color = Colors.black;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (image.isDark(r, c)) canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell + 0.5, cell + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.data != data;
}

// MARK: Journal

bool _logOpen = false;

/// Journal de lecture lisible à la télécommande (touche Menu, Info ou rouge depuis n'importe quel écran).
void openTvLog(BuildContext context) {
  if (_logOpen) return;
  _logOpen = true;
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TvLogPage())).whenComplete(() => _logOpen = false);
}

class TvLogPage extends StatefulWidget {
  const TvLogPage({super.key});

  @override
  State<TvLogPage> createState() => _TvLogPageState();
}

class _TvLogPageState extends State<TvLogPage> with TvKeys<TvLogPage> {
  final _scroll = ScrollController();
  bool _errorsOnly = false;

  @override
  void initState() {
    super.initState();
    startTvKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    stopTvKeys();
    _scroll.dispose();
    super.dispose();
  }

  @override
  bool onTvKey(TvKey key) {
    if (!_scroll.hasClients) return true;
    final page = _scroll.position.viewportDimension * 0.8;
    switch (key) {
      case TvKey.up:
        _scroll.animateTo((_scroll.offset - page).clamp(0, _scroll.position.maxScrollExtent), duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      case TvKey.down:
        _scroll.animateTo((_scroll.offset + page).clamp(0, _scroll.position.maxScrollExtent), duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      case TvKey.ok:
        setState(() => _errorsOnly = !_errorsOnly);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
        });
      case TvKey.left:
      case TvKey.right:
      case TvKey.menu:
        break;
    }
    return true;
  }

  String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final lines = PlaybackLog.shared.lines.where((l) => !_errorsOnly || l.level <= 1).toList();
    final shown = lines.length > 400 ? lines.sublist(lines.length - 400) : lines;
    return TvBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60, 36, 60, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(tr('Journal de lecture'), style: kTextD(36, weight: FontWeight.w800)),
            const SizedBox(width: 24),
            Text(_errorsOnly ? tr('Erreurs et alertes seulement') : tr('Tout'), style: kTextD(20, color: KPalette.orange)),
          ]),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(16)),
              child: shown.isEmpty
                  ? Text(tr('Journal vide.'), style: kTextD(20, color: Colors.white70))
                  : ListView.builder(
                      controller: _scroll,
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final l = shown[i];
                        final color = l.level == 0 ? Colors.redAccent : (l.level == 1 ? Colors.amberAccent : Colors.white);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${_time(l.date)} ${l.levelLabel}  ${l.text}', style: kTextD(16, color: color)),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 14),
          const TvHints(items: [('▲ ▼', 'Défiler'), ('OK', 'Erreurs / tout'), ('Retour', 'Fermer')]),
        ]),
      ),
    );
  }
}

/// Touche Menu / Info / rouge n'importe où dans l'application (télévision) : ouvre le journal, même si l'écran ne répond plus.
class TvLogShortcut {
  static bool _installed = false;
  static GlobalKey<NavigatorState>? navigatorKey;

  static void install(BuildContext Function() context) {
    if (_installed || !Device.isTv) return;
    _installed = true;
    HardwareKeyboard.instance.addHandler((event) {
      if (event is! KeyDownEvent) return false;
      final key = event.logicalKey;
      if (key != LogicalKeyboardKey.info && key != LogicalKeyboardKey.colorF0Red) return false;
      openTvLog(context());
      return true;
    });
  }
}
