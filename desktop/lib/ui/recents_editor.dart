import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../l10n.dart';
import '../theme.dart';
import 'widgets.dart';

/// Bouton « Modifier » / « Terminé » au-dessus de la liste des récents.
class RecentsEditButton extends StatelessWidget {
  const RecentsEditButton({super.key, required this.kind});
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final navigation = context.navigation;
    final empty = context.library.recentsOf(kind).isEmpty;
    return TextButton.icon(
      onPressed: empty && !navigation.editingRecents ? null : () => navigation.setEditingRecents(!navigation.editingRecents),
      icon: Icon(navigation.editingRecents ? Icons.check_rounded : Icons.edit_outlined, size: 16),
      label: Text(navigation.editingRecents ? tr('Terminé') : tr('Modifier')),
    );
  }
}

/// Récents en mode « Modifier » (comme sur Mac) : cases à cocher, Tout sélectionner, Retirer la sélection, Tout effacer.
class RecentsEditor extends StatefulWidget {
  const RecentsEditor({super.key, required this.kind});
  final MediaKind kind;

  @override
  State<RecentsEditor> createState() => _RecentsEditorState();
}

class _RecentsEditorState extends State<RecentsEditor> {
  final Set<String> _checked = {};

  Future<void> _clearAll(List<MediaItem> items) async {
    final ok = await showKDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Effacer les récents ?')),
        content: Text('${items.length} ${tr('élément(s) de cette section seront retirés des récents. Vos favoris ne changent pas.')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Annuler'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Tout effacer'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.library.removeRecents(items.map((i) => i.id));
    _checked.clear();
    context.navigation.setEditingRecents(false);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        final items = library.recentsOf(widget.kind);
        _checked.removeWhere((id) => !items.any((i) => i.id == id));
        final all = items.isNotEmpty && _checked.length == items.length;
        return Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
            color: KPalette.ink.withValues(alpha: 0.04),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Checkbox(
                  tristate: true,
                  value: all ? true : (_checked.isEmpty ? false : null),
                  onChanged: items.isEmpty
                      ? null
                      : (_) => setState(() {
                            if (all) {
                              _checked.clear();
                            } else {
                              _checked.addAll(items.map((i) => i.id));
                            }
                          }),
                ),
                Expanded(child: Text(tr('Tout sélectionner'), style: kText(13, weight: FontWeight.w600))),
              ]),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Wrap(spacing: 8, runSpacing: 6, children: [
                  FilledButton.icon(
                    onPressed: _checked.isEmpty
                        ? null
                        : () {
                            library.removeRecents(_checked);
                            setState(_checked.clear);
                          },
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                    label: Text('${tr('Retirer la sélection')} (${_checked.length})'),
                  ),
                  OutlinedButton(onPressed: items.isEmpty ? null : () => _clearAll(items), child: Text(tr('Tout effacer'))),
                ]),
              ),
            ]),
          ),
          Divider(height: 1, color: KPalette.separator),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(tr('Aucun récent'), style: kText(13, color: KPalette.secondaryText)))
                : ListView.builder(
                    itemCount: items.length,
                    itemExtent: 52,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final checked = _checked.contains(item.id);
                      return InkWell(
                        onTap: () => setState(() => checked ? _checked.remove(item.id) : _checked.add(item.id)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(children: [
                            Checkbox(value: checked, onChanged: (v) => setState(() => v == true ? _checked.add(item.id) : _checked.remove(item.id))),
                            const SizedBox(width: 4),
                            LogoView(url: item.logo, name: item.name, size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.kind == MediaKind.live ? item.name : item.displayName,
                                    style: kText(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(item.group, style: kText(11, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                            IconButton(
                              tooltip: tr('Retirer des récents'),
                              icon: Icon(Icons.close_rounded, size: 18, color: KPalette.ink54),
                              onPressed: () => library.removeRecents([item.id]),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}
