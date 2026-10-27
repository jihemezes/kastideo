import 'dart:io';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/library.dart';
import '../core/models.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'catalog_screen.dart';
import 'cinema_view.dart';
import 'details_view.dart';
import 'player_pane.dart';
import 'settings_dialog.dart';
import 'source_form.dart';
import 'widgets.dart';

/// Vidéos personnelles d'un dossier ou d'un serveur (rubrique « Vidéos · … »).
bool isPersonalVideo(MediaItem item) {
  final videos = tr('Vidéos');
  return item.kind == MediaKind.movie && (item.group == videos || item.group.startsWith('$videos · '));
}

/// Année d'un contenu : connue (serveur, fiche TMDB) ou lue dans son nom « Titre (2020) ».
int? yearOf(MediaItem item) => item.year ?? cleanTitle(item.name).year;

/// Vidéothèque : dossiers (disque, clé USB, NAS) et serveurs Jellyfin, Emby, Plex, à part de l'IPTV.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.navigation;
    return Scaffold(
      body: ListenableBuilder(
        listenable: navigation,
        builder: (context, _) {
          final selected = navigation.selected(MediaKind.movie);
          final Widget content = navigation.showPlayer
              ? const PlayerPane(showBack: true)
              : selected != null
                  ? DetailsView(key: ValueKey(selected.id), item: selected, page: true)
                  : const _LibraryBrowser();
          return Row(children: [
            if (!navigation.theater) ...[
              const SizedBox(width: 236, child: _LibrarySidebar()),
              VerticalDivider(width: 1, color: KPalette.separator),
            ],
            Expanded(child: content),
          ]);
        },
      ),
    );
  }
}

// MARK: Barre latérale

class _LibrarySidebar extends StatelessWidget {
  const _LibrarySidebar();

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final navigation = context.navigation;
    return Container(
      color: KPalette.sidebar,
      child: ListenableBuilder(
        listenable: Listenable.merge([library, navigation]),
        builder: (context, _) {
          final items = library.libraryItems(sourceId: navigation.librarySource);
          final movies = items.where((i) => i.kind == MediaKind.movie && !isPersonalVideo(i)).length;
          final series = items.where((i) => i.kind == MediaKind.series).length;
          final videos = items.where(isPersonalVideo).length;
          final view = navigation.libraryView;
          return Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                children: [
                  SidebarRow(icon: Icons.home_rounded, label: tr('Accueil'), selected: false, onTap: () => navigation.go(Screen.home)),
                  const SizedBox(height: 10),
                  SidebarHeader(tr('Mes vidéos')),
                  SidebarRow(
                    icon: Icons.auto_awesome_mosaic_outlined,
                    label: tr('À la une'),
                    selected: view == LibraryView.home,
                    onTap: () => navigation.setLibrary(view: LibraryView.home),
                  ),
                  SidebarRow(
                    icon: Icons.movie_outlined,
                    label: tr('Films'),
                    count: movies,
                    selected: view == LibraryView.movies,
                    onTap: () => navigation.setLibrary(view: LibraryView.movies),
                  ),
                  SidebarRow(
                    icon: Icons.video_library_outlined,
                    label: tr('Séries'),
                    count: series,
                    selected: view == LibraryView.series,
                    onTap: () => navigation.setLibrary(view: LibraryView.series),
                  ),
                  SidebarRow(
                    icon: Icons.videocam_outlined,
                    label: tr('Vidéos'),
                    count: videos,
                    selected: view == LibraryView.videos,
                    onTap: () => navigation.setLibrary(view: LibraryView.videos),
                  ),
                  SidebarRow(
                    icon: Icons.folder_open_rounded,
                    label: tr('Dossiers'),
                    selected: view == LibraryView.folders,
                    onTap: () => navigation.setLibrary(view: LibraryView.folders, folder: const []),
                  ),
                  const SizedBox(height: 10),
                  SidebarHeader(tr('Sources')),
                  SidebarRow(
                    icon: Icons.all_inclusive_rounded,
                    label: tr('Toutes les sources'),
                    count: library.libraryItems().length,
                    selected: navigation.librarySource == null,
                    onTap: () => navigation.setLibrary(source: null),
                  ),
                  for (final source in library.librarySources)
                    SidebarRow(
                      icon: library.sourceErrors.containsKey(source.id)
                          ? Icons.error_outline_rounded
                          : library.loadingSources.contains(source.id)
                              ? Icons.sync_rounded
                              : sourceIcon(source.kind),
                      label: source.name,
                      count: library.libraryItems(sourceId: source.id).length,
                      selected: navigation.librarySource == source.id,
                      onTap: () => navigation.setLibrary(source: source.id),
                      onSecondaryTap: (pos) => _sourceMenu(context, source, pos),
                    ),
                ],
              ),
            ),
            const ActivityIndicator(),
            Divider(height: 1, color: KPalette.separator),
            SidebarRow(
              icon: Icons.add_rounded,
              label: tr('Ajouter une source'),
              selected: false,
              onTap: () => showSettingsDialog(context, tab: SettingsTab.sources, startAdding: true),
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            ),
            SidebarRow(
              icon: Icons.settings_rounded,
              label: tr('Réglages'),
              selected: false,
              onTap: () => showSettingsDialog(context, tab: SettingsTab.sources),
              margin: const EdgeInsets.all(8),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _sourceMenu(BuildContext context, Source source, Offset position) async {
    final library = context.library;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: KPalette.menu,
      items: [
        PopupMenuItem(height: 34, value: 'refresh', child: Text(tr('Actualiser'), style: kText(13))),
        PopupMenuItem(height: 34, value: 'edit', child: Text(tr('Modifier la source…'), style: kText(13))),
        if (library.sourceErrors.containsKey(source.id))
          PopupMenuItem(height: 34, value: 'error', child: Text(tr('Détails de l\'erreur…'), style: kText(13))),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'refresh':
        library.refresh(source);
      case 'edit':
        showSettingsDialog(context, tab: SettingsTab.sources);
      case 'error':
        showSourceError(context, source);
    }
  }
}

/// Diagnostic : message, réponse exacte du serveur et pistes.
Future<void> showSourceError(BuildContext context, Source source) {
  final error = context.library.sourceErrors[source.id];
  return showKDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('${tr('Diagnostic')} — ${source.name}'),
      content: SizedBox(
        width: 560,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(error?.$1 ?? tr('Aucune erreur.'), style: kText(14, weight: FontWeight.w600)),
          if (error?.$2 != null) ...[
            const SizedBox(height: 12),
            Text(tr('Réponse du serveur'), style: kText(12, color: KPalette.secondaryText)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
              child: SelectableText(error!.$2!, style: kText(12)),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            source.kind == SourceKind.folder
                ? tr('Vérifiez que le disque est branché ou que le partage réseau est connecté, puis Actualiser.')
                : tr('Vérifiez l\'adresse (sans « /web/… »), l\'identifiant et le mot de passe dans Réglages > Sources. Le journal de lecture garde le détail de chaque échange.'),
            style: kText(12, color: KPalette.secondaryText),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('Fermer'))),
        FilledButton(
          onPressed: () {
            Navigator.pop(c);
            context.library.refresh(source);
          },
          child: Text(tr('Réessayer')),
        ),
      ],
    ),
  );
}

// MARK: Contenu

class _LibraryBrowser extends StatelessWidget {
  const _LibraryBrowser();

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final navigation = context.navigation;
    return ListenableBuilder(
      listenable: Listenable.merge([library, navigation, context.watch]),
      builder: (context, _) => switch (navigation.libraryView) {
        // Sans « const » : chaque changement de vue, de dossier ou de filtre reconstruit le contenu.
        // ignore: prefer_const_constructors
        LibraryView.home => _LibraryHome(),
        // ignore: prefer_const_constructors
        LibraryView.folders => _FolderBrowser(),
        // ignore: prefer_const_constructors
        _ => _LibraryGrid(),
      },
    );
  }
}

/// Bandeaux d'erreur et de chargement des sources affichées.
class _SourceStatus extends StatelessWidget {
  const _SourceStatus();

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final shown = library.librarySources.where((s) => context.navigation.librarySource == null || s.id == context.navigation.librarySource);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final s in shown)
        if (library.sourceErrors[s.id] case final error?)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: KPalette.orange.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: KPalette.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('${s.name} : ${error.$1}', style: kText(13), maxLines: 2, overflow: TextOverflow.ellipsis)),
              TextButton(onPressed: () => showSourceError(context, s), child: Text(tr('Détails'))),
              TextButton(onPressed: () => library.refresh(s), child: Text(tr('Réessayer'))),
            ]),
          )
        else if (library.loadingSources.contains(s.id))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Text(s.kind == SourceKind.folder ? '${tr('Examen des dossiers…')} ${s.name}' : '${tr('Chargement des bibliothèques…')} ${s.name}',
                  style: kText(13, color: KPalette.secondaryText)),
            ]),
          ),
    ]);
  }
}

class _LibraryHome extends StatelessWidget {
  const _LibraryHome();

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final navigation = context.navigation;
    final watch = context.watch;
    final items = library.libraryItems(sourceId: navigation.librarySource);
    bool inScope(MediaItem i) => library.isLibraryItem(i) && (navigation.librarySource == null || i.sourceId == navigation.librarySource);
    final resume = library.recents.where((i) => inScope(i) && watch.fraction(i.id) != null).take(20).toList();
    final recent = [...items.where((i) => i.added != null)]..sort((a, b) => b.added!.compareTo(a.added!));
    final movies = items.where((i) => i.kind == MediaKind.movie && !isPersonalVideo(i)).toList()..sort(_byTitle);
    final series = items.where((i) => i.kind == MediaKind.series).toList()..sort(_byTitle);
    final videos = items.where(isPersonalVideo).toList()..sort(_byTitle);
    final unwatched = movies.where((i) => !watch.isWatched(i.id) && watch.fraction(i.id) == null).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(0, 18, 0, 30), children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_scopeTitle(context), style: kText(26, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _SourceStatus(),
        ]),
      ),
      if (items.isEmpty && library.loadingSources.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
          child: Center(
            child: Column(children: [
              Icon(Icons.video_library_outlined, size: 56, color: KPalette.ink.withValues(alpha: 0.3)),
              const SizedBox(height: 10),
              Text(tr('Aucune vidéo pour l\'instant.'), style: kText(16, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                tr('Kastideo reconnaît les fichiers vidéo (.mkv, .mp4, .avi…) des dossiers choisis et de leurs sous-dossiers. Vérifiez le dossier de la source, ou ouvrez le journal de lecture pour voir ce qui a été examiné.'),
                textAlign: TextAlign.center,
                style: kText(13, color: KPalette.secondaryText),
              ),
            ]),
          ),
        ),
      if (resume.isNotEmpty) CinemaRail.items(title: tr('Reprendre la lecture'), items: resume),
      if (recent.isNotEmpty) CinemaRail.items(title: tr('Ajouts récents'), items: recent.take(30).toList()),
      if (unwatched.length >= 6 && unwatched.length < movies.length)
        CinemaRail.items(title: tr('Films à voir'), items: unwatched.take(30).toList(), onSeeAll: () => navigation.setLibrary(view: LibraryView.movies, unwatched: true)),
      if (movies.isNotEmpty)
        CinemaRail.items(title: tr('Films'), items: movies.take(30).toList(), onSeeAll: () => navigation.setLibrary(view: LibraryView.movies)),
      if (series.isNotEmpty)
        CinemaRail.items(title: tr('Séries'), items: series.take(30).toList(), onSeeAll: () => navigation.setLibrary(view: LibraryView.series)),
      if (videos.isNotEmpty)
        CinemaRail.items(title: tr('Vidéos'), items: videos.take(30).toList(), onSeeAll: () => navigation.setLibrary(view: LibraryView.videos)),
    ]);
  }
}

int _byTitle(MediaItem a, MediaItem b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());

String _scopeTitle(BuildContext context) {
  final id = context.navigation.librarySource;
  final source = id == null ? null : context.library.sources.where((s) => s.id == id).firstOrNull;
  return source == null ? tr('Mes vidéos') : '${tr('Mes vidéos')} · ${source.name}';
}

/// Films, séries ou vidéos : grille avec recherche, filtres (genre, année, non vus) et tri.
class _LibraryGrid extends StatefulWidget {
  const _LibraryGrid();

  @override
  State<_LibraryGrid> createState() => _LibraryGridState();
}

class _LibraryGridState extends State<_LibraryGrid> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final navigation = context.navigation;
    final watch = context.watch;
    final view = navigation.libraryView;
    final all = library.libraryItems(sourceId: navigation.librarySource).where((i) => switch (view) {
          LibraryView.movies => i.kind == MediaKind.movie && !isPersonalVideo(i),
          LibraryView.series => i.kind == MediaKind.series,
          LibraryView.videos => isPersonalVideo(i),
          _ => false,
        });
    final genres = <String>{for (final i in all) ...i.genres}.toList()..sort();
    final years = <int>{for (final i in all) ?yearOf(i)}.toList()..sort((a, b) => b.compareTo(a));
    final key = _search.text.searchKey;
    final items = all.where((i) {
      if (key.isNotEmpty && !i.searchKey.contains(key)) return false;
      if (navigation.libraryGenre != null && !i.genres.contains(navigation.libraryGenre)) return false;
      if (navigation.libraryYear != null && yearOf(i) != navigation.libraryYear) return false;
      if (navigation.libraryUnwatched && (watch.isWatched(i.id))) return false;
      return true;
    }).toList();
    switch (navigation.librarySort) {
      case LibrarySort.title:
        items.sort(_byTitle);
      case LibrarySort.added:
        items.sort((a, b) => (b.added ?? DateTime(1970)).compareTo(a.added ?? DateTime(1970)));
      case LibrarySort.year:
        items.sort((a, b) => (yearOf(b) ?? 0).compareTo(yearOf(a) ?? 0));
    }
    final title = switch (view) {
      LibraryView.movies => tr('Films'),
      LibraryView.series => tr('Séries'),
      _ => tr('Vidéos'),
    };
    Widget dropdown<T>(String label, T? value, List<(T?, String)> entries, void Function(T?) onChanged) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T?>(
              value: value,
              isDense: true,
              hint: Text(label, style: kText(13)),
              style: kText(13),
              dropdownColor: KPalette.menu,
              items: [for (final (v, text) in entries) DropdownMenuItem<T?>(value: v, child: Text(text, style: kText(13)))],
              onChanged: onChanged,
            ),
          ),
        );
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
        sliver: SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Flexible(child: Text('$title · ${_scopeTitle(context)}', style: kText(22, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text('${items.length}', style: kText(13, color: KPalette.secondaryText)),
            ]),
            const SizedBox(height: 10),
            const _SourceStatus(),
            Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: kText(13),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    hintText: tr('Rechercher'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (genres.isNotEmpty)
                dropdown<String>(tr('Genre'), navigation.libraryGenre, [(null, tr('Tous les genres')), for (final g in genres) (g, g)],
                    (v) => navigation.setLibrary(genre: v)),
              if (years.isNotEmpty)
                dropdown<int>(tr('Année'), navigation.libraryYear, [(null, tr('Toutes les années')), for (final y in years) (y, '$y')],
                    (v) => navigation.setLibrary(year: v)),
              FilterChip(
                label: Text(tr('Non vus'), style: kText(13)),
                selected: navigation.libraryUnwatched,
                onSelected: (v) => navigation.setLibrary(unwatched: v),
              ),
              dropdown<LibrarySort>(
                tr('Tri'),
                navigation.librarySort,
                [(LibrarySort.title, tr('Titre')), (LibrarySort.added, tr('Ajout récent')), (LibrarySort.year, tr('Année'))],
                (v) => navigation.setLibrary(sort: v ?? LibrarySort.title),
              ),
            ]),
          ]),
        ),
      ),
      if (items.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(tr('Aucun résultat'), style: kText(14, color: KPalette.secondaryText))),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: kPosterWidth + 20, mainAxisExtent: kPosterWidth * 1.5 + 52, crossAxisSpacing: 16, mainAxisSpacing: 16),
            delegate: SliverChildBuilderDelegate((context, i) => MediaCard(item: items[i]), childCount: items.length),
          ),
        ),
    ]);
  }
}

// MARK: Dossiers

/// Navigation par dossiers : dossiers choisis (disque, NAS) et leurs sous-dossiers, bibliothèques des serveurs.
class _FolderBrowser extends StatelessWidget {
  const _FolderBrowser();

  static final _sep = RegExp(r'[\\/]');

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final navigation = context.navigation;
    final path = navigation.libraryFolder;
    final sources = library.librarySources.where((s) => navigation.librarySource == null || s.id == navigation.librarySource).toList();

    // Racine : un dossier par dossier choisi, une entrée par bibliothèque de serveur.
    final folders = <(String, String, List<String>)>[]; // (nom, détail, chemin)
    final files = <MediaItem>[];
    if (path.isEmpty) {
      for (final s in sources) {
        if (s.kind == SourceKind.folder) {
          for (final root in LibraryStore.folderPaths(s)) {
            folders.add((root.split(_sep).where((p) => p.isNotEmpty).lastOrNull ?? root, '${s.name} · $root', [s.id, root]));
          }
        } else {
          final groups = <String>{for (final i in library.libraryItems(sourceId: s.id)) i.group}.toList()..sort();
          for (final g in groups) {
            folders.add((g, s.name, [s.id, g]));
          }
        }
      }
    } else {
      final source = library.sources.where((s) => s.id == path.first).firstOrNull;
      if (source != null && source.kind == SourceKind.folder) {
        // Fichiers sous le dossier ouvert : sous-dossiers d'abord, puis vidéos de ce dossier.
        var base = [path[1], ...path.skip(2)].join(Platform.pathSeparator);
        while (base.length > 1 && (base.endsWith('/') || base.endsWith('\\'))) {
          base = base.substring(0, base.length - 1);
        }
        final subfolders = <String>{};
        final contents = library.contentOf(source.id).where((i) => i.stream != null && i.kind != MediaKind.series);
        for (final i in contents) {
          final file = i.stream!;
          if (!file.startsWith(base) || file.length <= base.length || !'/\\'.contains(file[base.length])) continue;
          final rest = file.substring(base.length).split(_sep).where((p) => p.isNotEmpty).toList();
          if (rest.isEmpty) continue;
          if (rest.length > 1) {
            subfolders.add(rest.first);
          } else {
            files.add(library.item(i.id) ?? i);
          }
        }
        for (final f in subfolders.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))) {
          folders.add((f, '', [...path, f]));
        }
        files.sort((a, b) => (a.stream ?? '').toLowerCase().compareTo((b.stream ?? '').toLowerCase()));
      } else if (source != null) {
        files.addAll(library.libraryItems(sourceId: source.id).where((i) => i.group == path[1]).toList()..sort(_byTitle));
      }
    }

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
        sliver: SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('Dossiers'), style: kText(22, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            const _SourceStatus(),
            // Fil d'Ariane.
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              TextButton.icon(
                onPressed: () => navigation.setLibrary(folder: const []),
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text(tr('Tous les dossiers')),
              ),
              for (var i = 1; i < path.length; i++) ...[
                Icon(Icons.chevron_right_rounded, size: 16, color: KPalette.secondaryText),
                TextButton(
                  onPressed: () => navigation.setLibrary(folder: path.sublist(0, i + 1)),
                  child: Text(i == 1 ? (path[1].split(_sep).where((p) => p.isNotEmpty).lastOrNull ?? path[1]) : path[i]),
                ),
              ],
            ]),
          ]),
        ),
      ),
      if (folders.isEmpty && files.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(tr('Dossier vide'), style: kText(14, color: KPalette.secondaryText))),
        ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList.list(children: [
          for (final (name, detail, target) in folders)
            Hover(
              onTap: () => navigation.setLibrary(folder: target),
              builder: (context, hovering) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: KPalette.ink.withValues(alpha: hovering ? 0.08 : 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.folder_rounded, color: KPalette.orange, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, style: kText(14, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (detail.isNotEmpty)
                    Flexible(child: Text(detail, style: kText(12, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Icon(Icons.chevron_right_rounded, color: KPalette.secondaryText),
                ]),
              ),
            ),
          const SizedBox(height: 12),
        ]),
      ),
      if (files.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: kPosterWidth + 20, mainAxisExtent: kPosterWidth * 1.5 + 52, crossAxisSpacing: 16, mainAxisSpacing: 16),
            delegate: SliverChildBuilderDelegate((context, i) => MediaCard(item: files[i]), childCount: files.length),
          ),
        ),
    ]);
  }
}
