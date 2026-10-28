import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../core/paths.dart';
import '../core/settings.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'channel_edit_dialog.dart';
import 'cinema_view.dart';
import 'details_view.dart';
import 'player_pane.dart';
import 'multiview_view.dart';
import 'recents_editor.dart';
import 'fix_dialog.dart';
import 'schedule_dialog.dart';
import '../main.dart' show mediaSync;
import 'settings_dialog.dart';
import 'themes_view.dart';
import 'tv_view.dart';
import 'widgets.dart';

/// Une section (Direct, Films ou Séries) dans l'interface choisie : Classique (trois colonnes) ou Cinéma (affiches).
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, required this.kind});
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final navigation = context.navigation;
    final settings = context.settings;
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([navigation, settings]),
        builder: (context, _) {
          final style = settings.interfaceFor(kind);
          // Interface TV du direct : plein cadre, sans barre latérale.
          if (style == InterfaceStyle.tv && kind == MediaKind.live) return const TVView();
          final selected = navigation.selected(kind);
          final Widget content;
          if (style == InterfaceStyle.cinema && kind == MediaKind.live) {
            // Direct en Cinéma : lecteur plein cadre ; le retour arrête la chaîne et revient au catalogue.
            content = navigation.showPlayer ? const PlayerPane(showBack: true) : const CinemaView(kind: MediaKind.live);
          } else if (style == InterfaceStyle.cinema) {
            content = navigation.showPlayer
                ? const PlayerPane(showBack: true)
                : selected != null
                    ? DetailsView(item: selected, page: true)
                    : CinemaView(kind: kind);
          } else {
            final Widget right = kind == MediaKind.live
                ? const PlayerPane()
                : navigation.showPlayer
                    ? const PlayerPane(showBack: true)
                    : selected != null
                        ? DetailsView(key: ValueKey(selected.id), item: selected, page: false)
                        : _EmptyPane(kind: kind);
            content = Row(children: [
              if (!navigation.theater) ...[
                SizedBox(
                  width: 340,
                  child: kind == MediaKind.live && navigation.filter(kind) is ThemesFilter ? const ThemesList() : ItemList(kind: kind),
                ),
                VerticalDivider(width: 1, color: KPalette.separator),
              ],
              Expanded(child: right),
            ]);
          }
          return Row(children: [
            if (!navigation.theater) ...[
              SizedBox(width: 236, child: Sidebar(kind: kind)),
              VerticalDivider(width: 1, color: KPalette.separator),
            ],
            Expanded(child: content),
          ]);
        },
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.kind});
  final MediaKind kind;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(kind == MediaKind.movie ? Icons.movie_outlined : Icons.video_library_outlined,
              size: 64, color: KPalette.ink.withValues(alpha: 0.35)),
          const SizedBox(height: 12),
          Text(kind == MediaKind.movie ? tr('Choisissez un film') : tr('Choisissez une série'),
              style: kText(15, color: KPalette.secondaryText)),
        ]),
      );
}

String sectionTitle(MediaKind kind) => switch (kind) {
      MediaKind.live => tr('Direct'),
      MediaKind.movie => tr('Films'),
      _ => tr('Séries'),
    };

/// Barre latérale : sections, accueil, favoris, récents et catégories.
class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.kind, this.guide = false, this.recordings = false});
  final MediaKind kind;

  /// Le guide TV est affiché (entrée sélectionnée).
  final bool guide;

  /// L'écran Enregistrements est affiché.
  final bool recordings;

  bool get _other => guide || recordings;

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final navigation = context.navigation;
    return Container(
      color: KPalette.sidebar,
      child: ListenableBuilder(
        listenable: Listenable.merge([library, navigation, context.recordings, context.downloads]),
        builder: (context, _) {
          final categories = library.categories(kind);
          final filter = navigation.filter(kind);
          final allLabel = switch (kind) {
            MediaKind.live => tr('Toutes les chaînes'),
            MediaKind.movie => tr('Tous les films'),
            _ => tr('Toutes les séries'),
          };
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
              child: SectionPicker(current: kind),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                children: [
                  SidebarRow(icon: Icons.home_rounded, label: tr('Accueil'), selected: false, onTap: () => navigation.go(Screen.home)),
                  const SizedBox(height: 10),
                  SidebarHeader(sectionTitle(kind)),
                  SidebarRow(
                    icon: kind == MediaKind.live ? Icons.sensors_rounded : Icons.grid_view_rounded,
                    label: allLabel,
                    count: library.count(kind),
                    selected: filter is AllItems && !_other,
                    onTap: () => navigation.show(kind, const AllItems()),
                  ),
                  SidebarRow(
                    icon: Icons.star_rounded,
                    label: tr('Favoris'),
                    count: library.favoritesOf(kind).length,
                    selected: filter is FavoriteItems && !_other,
                    onTap: () => navigation.show(kind, const FavoriteItems()),
                  ),
                  SidebarRow(
                    icon: Icons.history_rounded,
                    label: tr('Récents'),
                    count: library.recentsOf(kind).length,
                    selected: filter is RecentItems && !_other,
                    onTap: () => navigation.show(kind, const RecentItems()),
                  ),
                  if (kind == MediaKind.live)
                    SidebarRow(
                      icon: Icons.category_outlined,
                      label: tr('Thèmes'),
                      selected: filter is ThemesFilter && !_other,
                      onTap: () => navigation.showThemes(theme: navigation.themeSelection, mode: navigation.themeMode),
                    ),
                  if (kind == MediaKind.live)
                    SidebarRow(
                      icon: Icons.calendar_month_rounded,
                      label: tr('Guide TV'),
                      selected: guide,
                      onTap: () => navigation.go(Screen.guide),
                    ),
                  if (kind == MediaKind.live)
                    SidebarRow(
                      icon: Icons.grid_view_rounded,
                      label: tr('MultiVue'),
                      count: context.multiview.channels.length,
                      selected: false,
                      onTap: () => openMultiView(context),
                    ),
                  SidebarRow(
                    icon: Icons.radio_button_checked_rounded,
                    label: tr('Enregistrements'),
                    count: context.downloads.pendingCount + (context.recordings.active != null ? 1 : 0),
                    selected: recordings,
                    onTap: () => navigation.go(Screen.recordings),
                  ),
                  if (library.hasLibrary && kind != MediaKind.live) ...[
                    const SizedBox(height: 10),
                    // Films et séries de l'IPTV, de « Mes vidéos » (dossiers, serveurs), ou des deux.
                    Tooltip(
                      message: tr('Films et séries de l\'abonnement IPTV, de vos dossiers et serveurs (Mes vidéos), ou des deux'),
                      child: SegmentedButton<CatalogOrigin>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
                        ),
                        segments: [
                          ButtonSegment(value: CatalogOrigin.all, label: Text(tr('Tout'), style: kText(11))),
                          ButtonSegment(value: CatalogOrigin.iptv, label: Text('IPTV', style: kText(11))),
                          ButtonSegment(value: CatalogOrigin.library, label: Text(tr('Mes vidéos'), style: kText(11), maxLines: 1, softWrap: false)),
                        ],
                        selected: {library.catalogOrigin},
                        onSelectionChanged: (v) => library.setCatalogOrigin(v.first),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: SidebarHeader(tr('Catégories'))),
                    Tooltip(
                      message: tr('Gérer les catégories'),
                      child: InkResponse(
                        onTap: () => showSettingsDialog(context, tab: SettingsTab.categories, categoryKind: kind),
                        radius: 14,
                        child: Icon(Icons.tune_rounded, size: 15, color: KPalette.ink.withValues(alpha: 0.5)),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ]),
                  for (final name in categories)
                    SidebarRow(
                      icon: Icons.folder_outlined,
                      label: library.categoryName(kind, name),
                      count: library.itemsInCategory(kind, name).length,
                      selected: filter is CategoryFilter && filter.name == name && !_other,
                      onTap: () => navigation.show(kind, CategoryFilter(name)),
                      onSecondaryTap: (pos) => _categoryMenu(context, name, pos),
                    ),
                ],
              ),
            ),
            const ActivityIndicator(),
            Divider(height: 1, color: KPalette.separator),
            SidebarRow(
              icon: Icons.settings_rounded,
              label: tr('Réglages'),
              selected: false,
              onTap: () => showSettingsDialog(context),
              margin: const EdgeInsets.all(8),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _categoryMenu(BuildContext context, String name, Offset position) async {
    final library = context.library;
    final visible = library.categories(kind);
    final index = visible.indexOf(name);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: KPalette.menu,
      items: [
        PopupMenuItem(height: 34, value: 'rename', child: Text(tr('Renommer…'), style: kText(13))),
        PopupMenuItem(height: 34, value: 'top', enabled: index > 0, child: Text(tr('Placer en haut'), style: kText(13))),
        PopupMenuItem(height: 34, value: 'up', enabled: index > 0, child: Text(tr('Monter'), style: kText(13))),
        PopupMenuItem(height: 34, value: 'down', enabled: index >= 0 && index < visible.length - 1, child: Text(tr('Descendre'), style: kText(13))),
        PopupMenuItem(height: 34, value: 'bottom', enabled: index >= 0 && index < visible.length - 1, child: Text(tr('Placer en bas'), style: kText(13))),
        const PopupMenuDivider(),
        PopupMenuItem(height: 34, value: 'hide', child: Text(tr('Masquer cette catégorie'), style: kText(13))),
        PopupMenuItem(height: 34, value: 'manage', child: Text(tr('Gérer les catégories…'), style: kText(13))),
      ],
    );
    if (!context.mounted || choice == null) return;
    void move(int Function(List<String> order, int from) target) {
      library.updateCategories(kind, (p) {
        final order = [...library.allCategories(kind)];
        final from = order.indexOf(name);
        if (from < 0) return;
        // Position visée parmi les catégories visibles, convertie en position dans l'ordre complet.
        final to = target(order, from).clamp(0, order.length - 1);
        order.removeAt(from);
        order.insert(to, name);
        p.order = order;
      });
    }

    switch (choice) {
      case 'hide':
        library.updateCategories(kind, (p) => p.hidden.add(name));
      case 'manage':
        showSettingsDialog(context, tab: SettingsTab.categories, categoryKind: kind);
      case 'rename':
        final controller = TextEditingController(text: library.prefs(kind).renames[name] ?? '');
        final value = await showKDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(tr('Renommer la catégorie')),
            content: SizedBox(
              width: 400,
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(hintText: name, helperText: tr('Laisser vide pour revenir au nom du fournisseur')),
                onSubmitted: (v) => Navigator.pop(c, v),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('Annuler'))),
              FilledButton(onPressed: () => Navigator.pop(c, controller.text), child: Text(tr('Enregistrer'))),
            ],
          ),
        );
        if (value == null) return;
        library.updateCategories(kind, (p) {
          if (value.trim().isEmpty || value.trim() == name) {
            p.renames.remove(name);
          } else {
            p.renames[name] = value.trim();
          }
        });
      case 'top':
        move((order, from) => order.indexOf(visible.first));
      case 'bottom':
        move((order, from) => order.indexOf(visible.last));
      case 'up':
        move((order, from) => order.indexOf(visible[index - 1]));
      case 'down':
        move((order, from) => order.indexOf(visible[index + 1]));
    }
  }
}

/// Choix de la section (Direct / Films / Séries), comme le sélecteur de la barre d'outils sur Mac.
class SectionPicker extends StatelessWidget {
  const SectionPicker({super.key, required this.current});
  final MediaKind current;

  @override
  Widget build(BuildContext context) {
    Widget segment(MediaKind kind, IconData icon) {
      final selected = kind == current;
      return Expanded(
        child: Tooltip(
          message: sectionTitle(kind),
          child: Hover(
            onTap: () => context.navigation.go(screenFor(kind)),
            builder: (context, hovering) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: selected ? KPalette.ink.withValues(alpha: 0.16) : (hovering ? KPalette.ink.withValues(alpha: 0.06) : null),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(children: [
                Icon(icon, size: 16, color: selected ? KPalette.ink : KPalette.ink.withValues(alpha: 0.6)),
                const SizedBox(height: 2),
                Text(sectionTitle(kind),
                    style: kText(11, weight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? KPalette.ink : KPalette.ink.withValues(alpha: 0.6))),
              ]),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: KPalette.light ? Colors.black.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        segment(MediaKind.live, Icons.sensors_rounded),
        segment(MediaKind.movie, Icons.movie_outlined),
        segment(MediaKind.series, Icons.video_library_outlined),
      ]),
    );
  }
}

class SidebarHeader extends StatelessWidget {
  const SidebarHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        child: Text(text, style: kText(11, weight: FontWeight.w700, color: KPalette.ink.withValues(alpha: 0.45))),
      );
}

class SidebarRow extends StatelessWidget {
  const SidebarRow({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.onSecondaryTap,
    this.margin = const EdgeInsets.symmetric(vertical: 1),
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final void Function(Offset position)? onSecondaryTap;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap == null ? null : (d) => onSecondaryTap!(d.globalPosition),
      child: Hover(
        onTap: onTap,
        builder: (context, hovering) => Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? KPalette.accent.withValues(alpha: 0.85)
                : hovering
                    ? KPalette.ink.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: selected ? KPalette.ink : KPalette.accent),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: kText(13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (count != null && count! > 0)
              Text('$count', style: kText(11, color: KPalette.ink.withValues(alpha: selected ? 0.85 : 0.45))),
          ]),
        ),
      ),
    );
  }
}

/// Contenus du filtre choisi (toutes, favoris, récents, catégorie), avec la recherche.
List<MediaItem> filteredItems(BuildContext context, MediaKind kind) {
  final library = context.library;
  final navigation = context.navigation;
  final base = switch (navigation.filter(kind)) {
    AllItems() || ThemesFilter() => library.items(kind),
    FavoriteItems() => library.favoritesOf(kind),
    RecentItems() => library.recentsOf(kind),
    CategoryFilter(:final name) => library.itemsInCategory(kind, name),
  };
  final key = navigation.search.searchKey;
  if (key.isEmpty) return base;
  return base.where((i) => i.searchKey.contains(key)).toList();
}

String filterTitle(BuildContext context, MediaKind kind) => switch (context.navigation.filter(kind)) {
      AllItems() => switch (kind) {
          MediaKind.live => tr('Toutes les chaînes'),
          MediaKind.movie => tr('Tous les films'),
          _ => tr('Toutes les séries'),
        },
      FavoriteItems() => tr('Favoris'),
      RecentItems() => tr('Récents'),
      ThemesFilter() => tr('Thèmes'),
      CategoryFilter(:final name) => context.library.categoryName(kind, name),
    };

/// Liste de l'interface Classique (logos, noms, recherche).
class ItemList extends StatefulWidget {
  const ItemList({super.key, required this.kind});
  final MediaKind kind;

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final playback = context.playback;
    final navigation = context.navigation;
    if (_search.text != navigation.search) _search.text = navigation.search;
    return Container(
      color: KPalette.list,
      child: ListenableBuilder(
        listenable: Listenable.merge([library, navigation, playback, context.watch, if (widget.kind == MediaKind.live) context.guide]),
        builder: (context, _) {
          final items = filteredItems(context, widget.kind);
          final selectedId = widget.kind == MediaKind.live ? playback.current?.id : navigation.selected(widget.kind)?.id;
          final recents = navigation.filter(widget.kind) is RecentItems && navigation.search.trim().isEmpty;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(children: [
                Expanded(
                  child: Text(filterTitle(context, widget.kind),
                      style: kRounded(20, FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text('${items.length}', style: kText(12, color: KPalette.secondaryText)),
                if (recents) RecentsEditButton(kind: widget.kind),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SearchBox(controller: _search, onChanged: navigation.setSearch),
            ),
            Divider(height: 1, color: KPalette.separator),
            Expanded(
              child: recents && navigation.editingRecents
                  ? RecentsEditor(kind: widget.kind)
                  : items.isEmpty
                  ? Center(child: Text(tr('Aucun résultat'), style: kText(13, color: KPalette.secondaryText)))
                  : ListView.builder(
                      itemCount: items.length,
                      itemExtent: (widget.kind == MediaKind.live ? 56 : 64) * KPalette.density,
                      itemBuilder: (context, index) => ItemRow(item: items[index], selected: selectedId == items[index].id),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

/// Champ de recherche compact.
class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.controller, required this.onChanged, this.height = 32});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: kText(13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: KPalette.ink.withValues(alpha: 0.08),
            prefixIcon: Icon(Icons.search_rounded, size: 16, color: KPalette.ink.withValues(alpha: 0.5)),
            prefixIconConstraints: const BoxConstraints(minWidth: 32),
            hintText: tr('Rechercher'),
            hintStyle: kText(13, color: KPalette.ink.withValues(alpha: 0.4)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      );
}

/// Ligne de liste : logo ou affiche, nom, catégorie, progression de lecture.
class ItemRow extends StatelessWidget {
  const ItemRow({super.key, required this.item, required this.selected});
  final MediaItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final favorite = library.isFavorite(item.id);
    final isLive = item.kind == MediaKind.live;
    final fraction = isLive ? null : context.watch.fraction(item.id);
    final programme = isLive ? context.guide.current(item) : null;
    return GestureDetector(
      onSecondaryTapUp: (details) => showItemMenu(context, item, details.globalPosition),
      child: Hover(
        onTap: () => openItem(context, item),
        builder: (context, hovering) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? KPalette.accent.withValues(alpha: 0.85)
                : hovering
                    ? KPalette.ink.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            if (isLive)
              LogoView(url: item.logo, name: item.name, size: (34 * KPalette.density).clamp(26, 42))
            else
              ClipRRect(borderRadius: BorderRadius.circular(4), child: PosterImage(url: item.logo, name: item.name, width: (54 * KPalette.density).clamp(40, 66) / 1.5, height: (54 * KPalette.density).clamp(40, 66))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isLive ? item.name : item.displayName,
                      style: kText(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    programme != null
                        ? '${hm(programme.start)} · ${programme.title}'
                        : isLive
                            ? tr('Programme non disponible')
                            : item.group,
                    style: kText(11, color: KPalette.ink.withValues(alpha: selected ? 0.8 : 0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (programme != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3, right: 30),
                      child: LinearProgressIndicator(
                        value: programme.progress(),
                        minHeight: 2,
                        color: selected ? KPalette.ink : KPalette.orange,
                        backgroundColor: KPalette.ink.withValues(alpha: 0.15),
                      ),
                    ),
                  if (fraction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 30),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 2,
                        color: selected ? KPalette.ink : KPalette.orange,
                        backgroundColor: KPalette.ink.withValues(alpha: 0.15),
                      ),
                    ),
                ],
              ),
            ),
            if (favorite) Icon(Icons.star_rounded, size: 15, color: selected ? KPalette.ink : KPalette.orange),
          ]),
        ),
      ),
    );
  }
}

/// Menu contextuel d'un contenu (clic droit).
Future<void> showItemMenu(BuildContext context, MediaItem item, Offset position) async {
  final library = context.library;
  final favorite = library.isFavorite(item.id);
  final isLive = item.kind == MediaKind.live;
  final choice = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
    color: KPalette.menu,
    items: [
      PopupMenuItem(
        value: 'open',
        child: Text(isLive ? tr('Regarder') : (item.kind == MediaKind.series ? tr('Voir les épisodes') : tr('Fiche du film')),
            style: kText(13)),
      ),
      if (item.kind == MediaKind.movie) PopupMenuItem(value: 'play', child: Text(tr('Lire'), style: kText(13))),
      PopupMenuItem(value: 'fav', child: Text(favorite ? tr('Retirer des favoris') : tr('Ajouter aux favoris'), style: kText(13))),
      if (isLive)
        PopupMenuItem(
          value: 'record',
          child: Text(context.recordings.isRecording(item) ? tr('Arrêter l\'enregistrement') : tr('Enregistrer maintenant'), style: kText(13)),
        ),
      if (isLive && context.settings.multiviewAvailable)
        PopupMenuItem(value: 'multi', child: Text(tr('Ajouter à la MultiVue'), style: kText(13))),
      if (isLive) PopupMenuItem(value: 'schedule', child: Text(tr('Programmer un enregistrement…'), style: kText(13))),
      if (isLive) PopupMenuItem(value: 'edit', child: Text(tr('Modifier la chaîne…'), style: kText(13))),
      if (isLive && context.guide.groupOf(item) != null)
        PopupMenuItem(value: 'theme', child: Text(tr('Thème de la chaîne…'), style: kText(13))),
      if ((item.kind == MediaKind.movie || item.kind == MediaKind.episode) && !library.isLocalFile(item))
        PopupMenuItem(
          value: 'download',
          enabled: !context.downloads.contains(item.id),
          child: Text(context.downloads.contains(item.id) ? tr('Dans les téléchargements') : tr('Télécharger'), style: kText(13)),
        ),
      if ((item.kind == MediaKind.movie || item.kind == MediaKind.episode) && !library.isLocalFile(item))
        PopupMenuItem(value: 'night', enabled: !context.downloads.contains(item.id), child: Text(tr('Télécharger cette nuit'), style: kText(13))),
      if ((item.kind == MediaKind.movie || item.kind == MediaKind.episode) && !(library.sourceOf(item)?.kind.isIptv ?? true))
        PopupMenuItem(
          value: context.watch.isWatched(item.id) ? 'unwatched' : 'watched',
          child: Text(context.watch.isWatched(item.id) ? tr('Marquer comme non vu') : tr('Marquer comme vu'), style: kText(13)),
        ),
      if ((item.kind == MediaKind.movie || item.kind == MediaKind.series) && library.sourceOf(item)?.kind == SourceKind.folder)
        PopupMenuItem(value: 'fix', child: Text(tr('Corriger la fiche…'), style: kText(13))),
      if (library.recentIds.contains(item.id))
        PopupMenuItem(value: 'unrecent', child: Text(tr('Retirer des récents'), style: kText(13))),
      PopupMenuItem(value: 'copy', child: Text(tr('Copier le nom'), style: kText(13))),
    ],
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'open':
      openItem(context, item);
    case 'play':
      context.navigation.select(item.kind, item);
      playItem(context, item);
    case 'fav':
      library.toggleFavorite(item.id);
    case 'record':
      final recordings = context.recordings;
      if (recordings.isRecording(item)) {
        await recordings.stop();
      } else {
        final p = context.guide.current(item);
        await recordings.recordNow(item, title: p?.title ?? '', stopS: p == null ? null : p.stopS + context.settings.marginAfter * 60);
      }
    case 'schedule':
      await showScheduleDialog(context, channel: item);
    case 'multi':
      await openMultiView(context, add: item);
    case 'edit':
      await showChannelEditor(context, item);
    case 'download':
      context.downloads.enqueue(item);
    case 'night':
      context.downloads.enqueue(item, nightOnly: true);
    case 'theme':
      final group = context.guide.groupOf(item);
      if (group != null) await chooseChannelTheme(context, group);
    case 'watched':
      await mediaSync.setPlayed(item, true);
    case 'unwatched':
      await mediaSync.setPlayed(item, false);
    case 'fix':
      await showFixDialog(context, item);
    case 'unrecent':
      library.removeRecents([item.id]);
    case 'copy':
      await Clipboard.setData(ClipboardData(text: isLive ? item.name : item.displayName));
  }
}

/// Bas de la barre latérale : enregistrement et téléchargement en cours (progression, temps restant).
class ActivityIndicator extends StatelessWidget {
  const ActivityIndicator({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([context.recordings, context.downloads]),
        builder: (context, _) {
          final rec = context.recordings.active;
          final dl = context.downloads.running;
          if (rec == null && dl == null) return const SizedBox();
          return Hover(
            onTap: () => context.navigation.go(Screen.recordings),
            builder: (context, hovering) => Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: KPalette.ink.withValues(alpha: hovering ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (rec != null)
                  Row(children: [
                    const Icon(Icons.fiber_manual_record, size: 12, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${tr('Enregistrement')} · ${rec.channel.displayName}',
                          style: kText(12, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                if (rec != null && dl != null) const SizedBox(height: 8),
                if (dl != null) ...[
                  Row(children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(value: dl.fraction, strokeWidth: 2.4, color: KPalette.accent, backgroundColor: KPalette.ink12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(dl.name, style: kText(12, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (dl.fraction != null) '${(dl.fraction! * 100).round()} %',
                      if (dl.remaining != null) '${tr('reste')} ${durationText(dl.remaining!)}',
                      if (context.downloads.pendingCount > 1) '${context.downloads.pendingCount - 1} ${tr('en attente')}',
                    ].join(' · '),
                    style: kText(11, color: KPalette.ink54),
                  ),
                ],
              ]),
            ),
          );
        },
      );
}
