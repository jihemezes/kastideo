import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'player_pane.dart';
import 'widgets.dart';

/// Direct en interface Classique : barre latérale (catégories), liste des chaînes, lecteur.
class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.navigation;
    return Scaffold(
      body: ListenableBuilder(
        listenable: navigation,
        builder: (context, _) => Row(children: [
          if (!navigation.theater) ...[
            const SizedBox(width: 236, child: _Sidebar()),
            const VerticalDivider(width: 1, color: KPalette.separator),
            const SizedBox(width: 340, child: _ChannelList()),
            const VerticalDivider(width: 1, color: KPalette.separator),
          ],
          const Expanded(child: PlayerPane()),
        ]),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final navigation = context.navigation;
    return Container(
      color: KPalette.sidebar,
      child: ListenableBuilder(
        listenable: Listenable.merge([library, navigation]),
        builder: (context, _) {
          final categories = library.categories(MediaKind.live);
          final filter = navigation.liveFilter;
          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            children: [
              _SidebarRow(icon: Icons.home_rounded, label: tr('Accueil'), selected: false, onTap: () => navigation.go(Screen.home)),
              const SizedBox(height: 10),
              _SectionHeader(tr('Direct')),
              _SidebarRow(
                icon: Icons.sensors_rounded,
                label: tr('Toutes les chaînes'),
                count: library.count(MediaKind.live),
                selected: filter is AllChannels,
                onTap: () => navigation.showLive(const AllChannels()),
              ),
              _SidebarRow(
                icon: Icons.star_rounded,
                label: tr('Favoris'),
                count: library.favorites.where((i) => i.kind == MediaKind.live).length,
                selected: filter is FavoriteChannels,
                onTap: () => navigation.showLive(const FavoriteChannels()),
              ),
              _SidebarRow(
                icon: Icons.history_rounded,
                label: tr('Récents'),
                count: library.recents.where((i) => i.kind == MediaKind.live).length,
                selected: filter is RecentChannels,
                onTap: () => navigation.showLive(const RecentChannels()),
              ),
              const SizedBox(height: 10),
              _SectionHeader(tr('Catégories')),
              for (final name in categories)
                _SidebarRow(
                  icon: Icons.folder_outlined,
                  label: name,
                  count: library.itemsInCategory(MediaKind.live, name).length,
                  selected: filter is CategoryFilter && filter.name == name,
                  onTap: () => navigation.showLive(CategoryFilter(name)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        child: Text(text, style: kText(11, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.45))),
      );
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({required this.icon, required this.label, required this.selected, required this.onTap, this.count});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Hover(
      onTap: onTap,
      builder: (context, hovering) => Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? KPalette.accent.withValues(alpha: 0.85)
              : hovering
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: selected ? Colors.white : KPalette.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: kText(13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (count != null && count! > 0)
            Text('$count', style: kText(11, color: Colors.white.withValues(alpha: selected ? 0.85 : 0.45))),
        ]),
      ),
    );
  }
}

class _ChannelList extends StatefulWidget {
  const _ChannelList();

  @override
  State<_ChannelList> createState() => _ChannelListState();
}

class _ChannelListState extends State<_ChannelList> {
  final _search = TextEditingController();
  String _key = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MediaItem> _items(BuildContext context) {
    final library = context.library;
    final base = switch (context.navigation.liveFilter) {
      AllChannels() => library.items(MediaKind.live),
      FavoriteChannels() => library.favorites.where((i) => i.kind == MediaKind.live).toList(),
      RecentChannels() => library.recents.where((i) => i.kind == MediaKind.live).toList(),
      CategoryFilter(:final name) => library.itemsInCategory(MediaKind.live, name),
    };
    if (_key.isEmpty) return base;
    return base.where((i) => i.searchKey.contains(_key)).toList();
  }

  String _title(BuildContext context) => switch (context.navigation.liveFilter) {
        AllChannels() => tr('Toutes les chaînes'),
        FavoriteChannels() => tr('Favoris'),
        RecentChannels() => tr('Récents'),
        CategoryFilter(:final name) => name,
      };

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final playback = context.playback;
    return Container(
      color: KPalette.list,
      child: ListenableBuilder(
        listenable: Listenable.merge([library, context.navigation, playback]),
        builder: (context, _) {
          final items = _items(context);
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(children: [
                Expanded(
                  child: Text(_title(context), style: kRounded(20, FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text('${items.length}', style: kText(12, color: KPalette.secondaryText)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _search,
                  onChanged: (t) => setState(() => _key = t.searchKey),
                  style: kText(13),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    prefixIcon: Icon(Icons.search_rounded, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                    prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    hintText: tr('Rechercher'),
                    hintStyle: kText(13, color: Colors.white.withValues(alpha: 0.4)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: KPalette.separator),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(tr('Aucune chaîne'), style: kText(13, color: KPalette.secondaryText)))
                  : ListView.builder(
                      itemCount: items.length,
                      itemExtent: 52,
                      itemBuilder: (context, index) => _ChannelRow(
                        item: items[index],
                        selected: playback.current?.id == items[index].id,
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.item, required this.selected});
  final MediaItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final favorite = library.isFavorite(item.id);
    return GestureDetector(
      onSecondaryTapUp: (details) => _menu(context, details.globalPosition),
      child: Hover(
        onTap: () => openItem(context, item),
        builder: (context, hovering) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? KPalette.accent.withValues(alpha: 0.85)
                : hovering
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            LogoView(url: item.logo, name: item.name, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: kText(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    item.number != null ? '${item.number} · ${item.group}' : item.group,
                    style: kText(11, color: Colors.white.withValues(alpha: selected ? 0.8 : 0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (favorite) Icon(Icons.star_rounded, size: 15, color: selected ? Colors.white : KPalette.orange),
          ]),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, Offset position) async {
    final library = context.library;
    final favorite = library.isFavorite(item.id);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: const Color(0xF02C2C2E),
      items: [
        PopupMenuItem(value: 'play', child: Text(tr('Direct'), style: kText(13))),
        PopupMenuItem(
          value: 'fav',
          child: Text(favorite ? tr('Retirer des favoris') : tr('Ajouter aux favoris'), style: kText(13)),
        ),
        PopupMenuItem(value: 'copy', child: Text(tr('Copier le nom'), style: kText(13))),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'play':
        openItem(context, item);
      case 'fav':
        library.toggleFavorite(item.id);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: item.displayName));
    }
  }
}
