import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../core/help.dart';
import '../core/models.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import '../version.dart';
import 'tv_settings.dart';
import 'tv_shell.dart';
import 'widgets.dart';

/// Ouvre un élément depuis l'accueil, la recherche, les favoris : chaîne → lecture ; film ou série → fiche ;
/// épisode → fiche de sa série.
Future<void> tvOpenItem(BuildContext context, MediaItem item) async {
  final navigation = context.navigation;
  final library = context.library;
  var target = item;
  if (item.kind == MediaKind.episode) {
    final series = library.seriesOf(item);
    if (series == null) return;
    target = series;
  }
  Navigator.of(context).popUntil((r) => r.isFirst);
  if (target.kind == MediaKind.live) {
    if (!context.mounted) return;
    await openItem(context, target);
    return;
  }
  TvCatalog.pendingOpen = target;
  final screen = library.isLibraryItem(target) ? Screen.library : screenFor(target.kind);
  navigation.go(screen);
}

// MARK: Accueil

/// Accueil Android TV (comme l'Apple TV) : pavés Direct, Films, Séries, Mes vidéos ; « Reprendre la lecture » ;
/// Recherche, Favoris, Récents, Guide TV, Aide, Réglages et Journal.
class TvHome extends StatefulWidget {
  const TvHome({super.key});

  @override
  State<TvHome> createState() => _TvHomeState();
}

class _TvHomeState extends State<TvHome> with TvKeys<TvHome> {
  int _row = 0;
  int _col = 0;
  bool _placed = false;
  int _tiles = 3;
  List<MediaItem> _rail = const [];

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

  static const _buttonCount = 7;
  List<String> get _rows => ['tiles', if (_rail.isNotEmpty) 'rail', 'buttons'];
  int _count(String row) => switch (row) {
        'tiles' => _tiles,
        'rail' => _rail.length,
        _ => _buttonCount,
      };

  @override
  bool onTvKey(TvKey key) {
    setState(() {
      final rows = _rows;
      _row = _row.clamp(0, rows.length - 1);
      final n = _count(rows[_row]);
      switch (key) {
        case TvKey.left:
          _col = (_col - 1 + n) % n;
        case TvKey.right:
          _col = (_col + 1) % n;
        case TvKey.up:
          if (_row > 0) {
            _row--;
            _col = _col.clamp(0, _count(rows[_row]) - 1);
          }
        case TvKey.down:
          if (_row < rows.length - 1) {
            _row++;
            _col = _col.clamp(0, _count(rows[_row]) - 1);
          }
        case TvKey.menu:
          openTvLog(context);
        case TvKey.ok:
          _activate(rows[_row]);
      }
    });
    return true;
  }

  void _activate(String row) {
    final nav = context.navigation;
    final library = context.library;
    if (row == 'tiles') {
      final screens = [Screen.live, Screen.movies, Screen.series, if (library.hasLibrary) Screen.library];
      nav.go(screens[_col.clamp(0, screens.length - 1)]);
    } else if (row == 'rail') {
      tvOpenItem(context, _rail[_col.clamp(0, _rail.length - 1)]);
    } else {
      switch (_col) {
        case 0:
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TvItemsPage(title: 'Recherche', search: true)));
        case 1:
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TvItemsPage(title: 'Favoris', items: _favorites)));
        case 2:
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TvItemsPage(title: 'Récents', items: _recents)));
        case 3:
          nav.go(Screen.guide);
        case 4:
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TvHelpPage()));
        case 5:
          openTvSettings(context);
        default:
          openTvLog(context);
      }
    }
  }

  static List<MediaItem> _favorites(BuildContext context) {
    final library = context.library;
    return [
      for (final kind in [MediaKind.live, MediaKind.movie, MediaKind.series]) ...library.favoritesOf(kind),
      for (final i in library.libraryItems()) if (library.isFavorite(i.id)) i,
    ];
  }

  static List<MediaItem> _recents(BuildContext context) => context.library.recents.take(120).toList();

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    return ListenableBuilder(
      listenable: Listenable.merge([library, context.watch]),
      builder: (context, _) {
        final watch = context.watch;
        _rail = [for (final i in library.recents) if (i.kind != MediaKind.live && watch.inResume(i.id)) i].take(12).toList();
        _tiles = library.hasLibrary ? 4 : 3;
        if (!_placed) {
          _placed = true;
          // Sans source : le curseur commence sur Réglages, pour ajouter la première.
          if (library.sources.isEmpty) {
            _row = _rows.length - 1;
            _col = 5;
          }
        }
        _row = _row.clamp(0, _rows.length - 1);
        final tiles = [
          (tr('Direct'), Icons.live_tv_rounded, '${library.items(MediaKind.live).length} ${tr('chaînes')}', const [Color(0xFFD02F8A), Color(0xFFFF9933)]),
          (tr('Films'), Icons.movie_rounded, '${library.items(MediaKind.movie).length} ${tr('films')}', const [Color(0xFF6B3FD6), Color(0xFFD02F8A)]),
          (tr('Séries'), Icons.video_library_rounded, '${library.items(MediaKind.series).length} ${tr('séries')}', const [Color(0xFF3C4BD8), Color(0xFF6B3FD6)]),
          if (library.hasLibrary) (tr('Mes vidéos'), Icons.folder_rounded, '${library.libraryItems().length}', const [Color(0xFF1E8E7E), Color(0xFF3C4BD8)]),
        ];
        final buttons = [
          (Icons.search_rounded, tr('Recherche')),
          (Icons.star_rounded, tr('Favoris')),
          (Icons.history_rounded, tr('Récents')),
          (Icons.calendar_month_rounded, tr('Guide TV')),
          (Icons.help_outline_rounded, tr('Aide')),
          (Icons.settings_rounded, tr('Réglages')),
          (Icons.receipt_long_rounded, tr('Journal')),
        ];
        final rows = _rows;
        return TvBackground(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(70, 28, 70, 16),
            child: Column(
              children: [
                Row(children: [
                  Text('Kastideo', style: kTextD(40, weight: FontWeight.w800)),
                  const Spacer(),
                  Text('v$kVersion · Android TV', style: kTextD(17, color: Colors.white54)),
                ]),
                const SizedBox(height: 14),
                if (library.sources.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(tr('Aucune source. Choisissez Réglages, puis « Ajouter une source avec mon téléphone ».'), textAlign: TextAlign.center, style: kTextD(20, color: Colors.white)),
                  ),
                Row(children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 26),
                    Expanded(
                      child: TvFocusBox(
                        selected: rows[_row] == 'tiles' && _col == i,
                        radius: 24,
                        child: Container(
                          height: 140,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: tiles[i].$4, begin: Alignment.topLeft, end: Alignment.bottomRight)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(tiles[i].$2, size: 38, color: Colors.white),
                            const Spacer(),
                            Text(tiles[i].$1, style: kTextD(30, weight: FontWeight.w800)),
                            Text(tiles[i].$3, style: kTextD(16, color: Colors.white70)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ]),
                if (_rail.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerLeft, child: Text(tr('Reprendre la lecture'), style: kTextD(20, weight: FontWeight.w700))),
                  const SizedBox(height: 6),
                  Expanded(child: _railView(rows)),
                ] else
                  const Spacer(),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: TvFocusBox(
                        selected: rows[_row] == 'buttons' && _col == i,
                        radius: 16,
                        child: Container(
                          height: 66,
                          color: Colors.white.withValues(alpha: 0.14),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(buttons[i].$1, color: Colors.white, size: 24),
                            Text(buttons[i].$2, style: kTextD(15, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 8),
                const TvHints(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _railView(List<String> rows) {
    return LayoutBuilder(builder: (context, c) {
      final height = (c.maxHeight - 34).clamp(90.0, 240.0);
      final width = height * 2 / 3;
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: _rail.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, i) {
          final item = _rail[i];
          final selected = rows[_row] == 'rail' && _col == i;
          final fraction = context.watch.fraction(item.id);
          return SizedBox(
            width: width,
            child: Column(children: [
              TvFocusBox(
                selected: selected,
                radius: 12,
                child: Stack(children: [
                  PosterImage(url: item.logo, name: item.name, width: width, height: height),
                  if (fraction != null && fraction > 0 && fraction < 1)
                    Positioned(left: 0, right: 0, bottom: 0, child: LinearProgressIndicator(value: fraction, minHeight: 5, color: KPalette.orange)),
                ]),
              ),
              const SizedBox(height: 4),
              Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: kTextD(14, weight: selected ? FontWeight.w700 : FontWeight.w500)),
            ]),
          );
        },
      );
    });
  }
}

// MARK: Recherche, favoris, récents

/// Grille d'éléments (favoris, récents) ou recherche : OK ouvre l'élément.
class TvItemsPage extends StatefulWidget {
  const TvItemsPage({super.key, required this.title, this.items, this.search = false});
  final String title;
  final List<MediaItem> Function(BuildContext context)? items;
  final bool search;

  @override
  State<TvItemsPage> createState() => _TvItemsPageState();
}

class _TvItemsPageState extends State<TvItemsPage> with TvKeys<TvItemsPage> {
  static const _columns = 6;
  final _query = TextEditingController();
  final _field = FocusNode();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<MediaItem> _results = const [];
  int _zone = 0; // 0 champ de recherche, 1 grille
  int _cell = 0;
  double _rowHeight = 280;

  @override
  void initState() {
    super.initState();
    startTvKeys();
    _zone = widget.search ? 0 : 1;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _field.dispose();
    _scroll.dispose();
    stopTvKeys();
    super.dispose();
  }

  List<MediaItem> _items(BuildContext context) => widget.search ? _results : widget.items!(context);

  void _search(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final key = text.searchKey;
      final library = context.library;
      final found = <MediaItem>[];
      if (key.isNotEmpty) {
        for (final kind in [MediaKind.live, MediaKind.movie, MediaKind.series]) {
          var n = 0;
          for (final item in library.items(kind)) {
            if (item.searchKey.contains(key)) {
              found.add(item);
              if (++n >= 30) break;
            }
          }
        }
        var n = 0;
        for (final item in library.libraryItems()) {
          if (item.searchKey.contains(key)) {
            found.add(item);
            if (++n >= 30) break;
          }
        }
      }
      setState(() {
        _results = found;
        _cell = 0;
      });
    });
  }

  void _toGrid() {
    _field.unfocus();
    if (_items(context).isNotEmpty) setState(() => _zone = 1);
  }

  @override
  bool onTvKey(TvKey key) {
    if (_field.hasFocus) return false; // saisie du texte
    final items = _items(context);
    setState(() {
      if (_zone == 0) {
        switch (key) {
          case TvKey.ok:
            _field.requestFocus();
          case TvKey.down:
            if (items.isNotEmpty) _zone = 1;
          default:
            break;
        }
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
          } else if (widget.search) {
            _zone = 0;
          }
        case TvKey.ok:
          if (items.isNotEmpty) tvOpenItem(context, items[_cell.clamp(0, items.length - 1)]);
        case TvKey.menu:
          openTvLog(context);
      }
    });
    if (_scroll.hasClients && _zone == 1) {
      final top = (_cell ~/ _columns) * _rowHeight;
      final view = _scroll.position.viewportDimension;
      if (top < _scroll.offset) {
        _scroll.jumpTo(top);
      } else if (top + _rowHeight > _scroll.offset + view) {
        _scroll.jumpTo(top + _rowHeight - view);
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return TvBackground(
      child: ListenableBuilder(
        listenable: Listenable.merge([context.library, context.watch]),
        builder: (context, _) {
          final items = _items(context);
          return Padding(
            padding: const EdgeInsets.fromLTRB(60, 30, 60, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(tr(widget.title), style: kTextD(36, weight: FontWeight.w800)),
                const SizedBox(width: 18),
                Text('${items.length}', style: kTextD(22, color: Colors.white60)),
              ]),
              if (widget.search) ...[
                const SizedBox(height: 14),
                TvFocusBox(
                  selected: _zone == 0,
                  radius: 16,
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.white.withValues(alpha: 0.14),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, color: Colors.white70, size: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                              _toGrid();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _query,
                            focusNode: _field,
                            style: kTextD(24),
                            cursorColor: KPalette.orange,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(border: InputBorder.none, hintText: tr('Appuyez sur OK pour saisir'), hintStyle: kTextD(22, color: Colors.white38)),
                            onChanged: _search,
                            onSubmitted: (t) {
                              _search(t);
                              Future.delayed(const Duration(milliseconds: 350), () => mounted ? _toGrid() : null);
                            },
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text(widget.search && _query.text.isEmpty ? '' : tr('Rien à afficher.'), style: kTextD(22, color: Colors.white70)))
                    : LayoutBuilder(builder: (context, box) {
                        const spacing = 20.0;
                        final width = (box.maxWidth - 24 - spacing * (_columns - 1)) / _columns;
                        final height = width * 1.5;
                        _rowHeight = height + 40 + spacing;
                        return GridView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _columns, mainAxisSpacing: spacing, crossAxisSpacing: spacing, mainAxisExtent: height + 40),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final selected = _zone == 1 && i == _cell;
                            final fraction = context.watch.fraction(item.id);
                            return Column(children: [
                              TvFocusBox(
                                selected: selected,
                                radius: 12,
                                child: Stack(children: [
                                  PosterImage(url: item.logo, name: item.name, width: width, height: height, fit: item.kind == MediaKind.live ? BoxFit.contain : BoxFit.cover),
                                  if (fraction != null && fraction > 0 && fraction < 1)
                                    Positioned(left: 0, right: 0, bottom: 0, child: LinearProgressIndicator(value: fraction, minHeight: 5, color: KPalette.orange)),
                                ]),
                              ),
                              const SizedBox(height: 6),
                              Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: kTextD(15, weight: selected ? FontWeight.w700 : FontWeight.w500)),
                            ]);
                          },
                        );
                      }),
              ),
              TvHints(items: [('OK', widget.search ? 'Saisir / Ouvrir' : 'Ouvrir'), ('◀ ▲ ▼ ▶', 'Se déplacer'), ('Retour', 'Accueil')]),
            ]),
          );
        },
      ),
    );
  }
}

// MARK: Aide

/// Aide à la télécommande : rubriques puis pages (texte défilant avec ▲ ▼).
class TvHelpPage extends StatefulWidget {
  const TvHelpPage({super.key});

  @override
  State<TvHelpPage> createState() => _TvHelpPageState();
}

class _TvHelpPageState extends State<TvHelpPage> {
  List<HelpGroup>? _groups;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/help/aide-${L10n.helpLang}.md').then((text) {
      if (mounted) setState(() => _groups = parseHelp(text, android: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups == null) return const TvBackground(child: Center(child: CircularProgressIndicator(color: Colors.white)));
    return TvMenuPage(
      title: tr('Aide'),
      entries: (_) => [
        for (final g in groups)
          TvEntry(g.title, (c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => _groupPage(g))), detail: '${g.pages.length}'),
      ],
    );
  }

  Widget _groupPage(HelpGroup g) => TvMenuPage(
        title: g.title,
        entries: (_) => [
          for (final p in g.pages) TvEntry(p.title, (c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => TvHelpText(page: p)))),
        ],
      );
}

class TvHelpText extends StatefulWidget {
  const TvHelpText({super.key, required this.page});
  final HelpPage page;

  @override
  State<TvHelpText> createState() => _TvHelpTextState();
}

class _TvHelpTextState extends State<TvHelpText> with TvKeys<TvHelpText> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    startTvKeys();
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
    final max = _scroll.position.maxScrollExtent;
    switch (key) {
      case TvKey.up:
        _scroll.animateTo((_scroll.offset - page).clamp(0, max), duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      case TvKey.down:
        _scroll.animateTo((_scroll.offset + page).clamp(0, max), duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      default:
        break;
    }
    return true;
  }

  static String _plain(String s) => s
      .replaceAllMapped(RegExp(r'!\[[^\]]*\]\([^)]*\)'), (_) => '')
      .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1)!)
      .replaceAll('**', '')
      .replaceAll('`', '');

  @override
  Widget build(BuildContext context) {
    final blocks = parseHelpBlocks(widget.page.body).where((b) => b.type != HelpBlockType.image && b.type != HelpBlockType.rule).toList();
    return TvBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(100, 36, 100, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.page.title, style: kTextD(36, weight: FontWeight.w800)),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final b in blocks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: switch (b.type) {
                      HelpBlockType.heading => Text(_plain(b.text), style: kTextD(26, weight: FontWeight.w700, color: KPalette.orange)),
                      HelpBlockType.bullet => Text('•  ${_plain(b.text)}', style: kTextD(21)),
                      HelpBlockType.numbered => Text('${b.number}.  ${_plain(b.text)}', style: kTextD(21)),
                      HelpBlockType.note => Text(_plain(b.text), style: kTextD(20, color: Colors.white70)),
                      _ => Text(_plain(b.text), style: kTextD(21)),
                    },
                  ),
              ]),
            ),
          ),
          const TvHints(items: [('▲ ▼', 'Défiler'), ('Retour', 'Revenir')]),
        ]),
      ),
    );
  }
}
