import 'package:flutter/material.dart';
import '../app_state.dart';
import '../core/models.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'widgets.dart';

/// Mode « Arranger » d'une catégorie : poignées pour changer l'ordre, la liste défile librement ailleurs.
class ArrangeList extends StatefulWidget {
  const ArrangeList({super.key, required this.kind, required this.category, required this.items, required this.onDone});
  final MediaKind kind;
  final String category;
  final List<MediaItem> items;
  final VoidCallback onDone;

  @override
  State<ArrangeList> createState() => _ArrangeListState();
}

class _ArrangeListState extends State<ArrangeList> {
  late List<MediaItem> _items = [...widget.items];

  @override
  void didUpdateWidget(ArrangeList old) {
    super.didUpdateWidget(old);
    _items = [...widget.items];
  }

  void _save(List<MediaItem> list) {
    setState(() => _items = list);
    context.library.setItemOrder(widget.kind, widget.category, [for (final i in list) i.id]);
  }

  void _sort(int Function(MediaItem, MediaItem) compare) => _save([..._items]..sort(compare));

  void _moveTo(int from, int to) {
    final list = [..._items];
    final item = list.removeAt(from);
    list.insert(to.clamp(0, list.length), item);
    _save(list);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final live = widget.kind == MediaKind.live;
    final moved = library.prefs(widget.kind).moves;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Wrap(spacing: 6, runSpacing: 0, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilledButton.icon(
            onPressed: widget.onDone,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(tr('Terminé')),
          ),
          TextButton(
            onPressed: () => _sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
            child: Text(tr('A → Z')),
          ),
          if (live)
            TextButton(
              onPressed: () => _sort((a, b) => (a.number ?? 1 << 30).compareTo(b.number ?? 1 << 30)),
              child: Text(tr('Par numéro')),
            ),
          TextButton(
            onPressed: () => library.resetItemOrder(widget.kind, widget.category),
            child: Text(tr('Ordre du fournisseur')),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
        child: Text(
          tr('Maintenez la poignée ⋮⋮ puis glissez pour déplacer. Faites défiler la liste en touchant ailleurs que sur la poignée.'),
          style: kText(11, color: KPalette.secondaryText),
        ),
      ),
      Divider(height: 1, color: KPalette.separator),
      Expanded(
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: _items.length,
          itemExtent: 60,
          onReorderItem: (from, to) => _moveTo(from, to),
          itemBuilder: (context, i) {
            final item = _items[i];
            return Container(
              key: ValueKey(item.id),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                ReorderableDragStartListener(
                  index: i,
                  child: const SizedBox(
                    width: 52,
                    height: 60,
                    child: Icon(Icons.drag_indicator_rounded, size: 26),
                  ),
                ),
                if (live)
                  LogoView(url: item.logo, name: item.name, size: 32)
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: PosterImage(url: item.logo, name: item.name, width: 30, height: 44),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(live ? item.name : item.displayName, style: kText(13, weight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                PopupMenuButton<String>(
                  tooltip: tr('Plus'),
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (v) async {
                    switch (v) {
                      case 'top':
                        _moveTo(i, 0);
                      case 'bottom':
                        _moveTo(i, _items.length);
                      case 'move':
                        final target = await showMoveDialog(context, widget.kind, widget.category);
                        if (target != null && context.mounted) {
                          context.library.moveItem(widget.kind, item, target, from: widget.category);
                        }
                      case 'back':
                        context.library.moveItem(widget.kind, item, null, from: widget.category);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'top', child: Text(tr('Tout en haut'))),
                    PopupMenuItem(value: 'bottom', child: Text(tr('Tout en bas'))),
                    PopupMenuItem(value: 'move', child: Text(tr('Déplacer vers une autre catégorie…'))),
                    if (moved.containsKey(item.id)) PopupMenuItem(value: 'back', child: Text(tr('Remettre dans sa catégorie d\'origine'))),
                  ],
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

/// Choix d'une catégorie existante ou création d'une liste personnelle. Renvoie le nom d'origine de la catégorie.
Future<String?> showMoveDialog(BuildContext context, MediaKind kind, String current) {
  final library = context.library;
  final controller = TextEditingController();
  return showKDialog<String>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) {
        final names = library.allCategories(kind).where((n) => n != current).toList();
        final key = controller.text.searchKey;
        final shown = key.isEmpty ? names : names.where((n) => library.categoryName(kind, n).searchKey.contains(key)).toList();
        final fresh = controller.text.trim();
        return AlertDialog(
          title: Text(tr('Déplacer vers…')),
          content: SizedBox(
            width: 420,
            height: (MediaQuery.sizeOf(dialog).height * 0.6).clamp(240.0, 560.0),
            child: Column(children: [
              TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: tr('Rechercher, ou nom d\'une nouvelle liste'),
                ),
              ),
              if (fresh.isNotEmpty && !names.contains(fresh))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.playlist_add_rounded),
                  title: Text('${tr('Nouvelle liste')} « $fresh »'),
                  onTap: () => Navigator.pop(dialog, fresh),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    title: Text(library.categoryName(kind, shown[i]), maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(dialog, shown[i]),
                  ),
                ),
              ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: Text(tr('Annuler')))],
        );
      },
    ),
  );
}
