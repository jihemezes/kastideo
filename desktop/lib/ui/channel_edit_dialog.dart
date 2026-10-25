import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../l10n.dart';
import '../theme.dart';
import 'widgets.dart';

/// « Modifier la chaîne… » (comme ChannelEditSheet sur Mac) : nom, numéro, logo et chaîne du guide TV,
/// pour cette version de la chaîne seulement.
Future<void> showChannelEditor(BuildContext context, MediaItem item) =>
    showKDialog(context: context, builder: (_) => _ChannelEditDialog(item: item));

class _ChannelEditDialog extends StatefulWidget {
  const _ChannelEditDialog({required this.item});
  final MediaItem item;

  @override
  State<_ChannelEditDialog> createState() => _ChannelEditDialogState();
}

class _ChannelEditDialogState extends State<_ChannelEditDialog> {
  late final MediaItem original = context.library.originalItem(widget.item.id) ?? widget.item;
  late final ChannelEdit edit = context.library.channelEdits[widget.item.id] ?? ChannelEdit();
  late final _name = TextEditingController(text: edit.name ?? '');
  late final _number = TextEditingController(text: edit.number?.toString() ?? '');
  late final _logo = TextEditingController(text: edit.logo ?? '');
  late final _epg = TextEditingController(text: edit.epgId ?? '');

  @override
  void dispose() {
    for (final c in [_name, _number, _logo, _epg]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif']),
    ]);
    if (file == null) return;
    // Copie dans le dossier de Kastideo : le logo reste disponible même si le fichier d'origine est déplacé.
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}${Platform.pathSeparator}logos');
    await dir.create(recursive: true);
    final ext = file.path.split('.').last.toLowerCase();
    final target = File('${dir.path}${Platform.pathSeparator}${widget.item.id.hashCode.toUnsigned(32)}-${DateTime.now().millisecondsSinceEpoch}.$ext');
    await File(file.path).copy(target.path);
    setState(() => _logo.text = target.uri.toString());
  }

  void _save() {
    context.library.setChannelEdit(
      widget.item.id,
      ChannelEdit(
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        number: int.tryParse(_number.text.trim()),
        logo: _logo.text.trim().isEmpty ? null : _logo.text.trim(),
        epgId: _epg.text.trim().isEmpty ? null : _epg.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  InputDecoration _field(String label, String hint) =>
      InputDecoration(labelText: label, hintText: hint, isDense: true, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    final channels = context.guide.guideChannels;
    final preview = _logo.text.trim().isEmpty ? original.logo : _logo.text.trim();
    return AlertDialog(
      backgroundColor: KPalette.panel,
      title: Row(children: [
        LogoView(url: preview, name: _name.text.isEmpty ? original.name : _name.text, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('Modifier la chaîne'), style: kText(17, weight: FontWeight.w700)),
            Text(original.name, style: kText(12, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
      content: SizedBox(
        width: 520,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _name, decoration: _field(tr('Nom'), original.name), onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          TextField(controller: _number, keyboardType: TextInputType.number, decoration: _field(tr('Numéro'), '${original.number ?? ''}')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _logo,
                decoration: _field(tr('Logo (adresse d\'une image)'), original.logo ?? 'https://…'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _pickLogo, child: Text(tr('Choisir un fichier…'))),
          ]),
          const SizedBox(height: 12),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _epg.text),
            optionsBuilder: (value) {
              final q = value.text.toLowerCase().trim();
              if (q.length < 2) return const Iterable<String>.empty();
              return channels
                  .where((c) => c.id.toLowerCase().contains(q) || c.names.any((n) => n.toLowerCase().contains(q)))
                  .take(30)
                  .map((c) => '${c.id} — ${c.names.isEmpty ? c.id : c.names.first}');
            },
            onSelected: (v) => _epg.text = v.split(' — ').first,
            fieldViewBuilder: (context, controller, focus, onSubmit) {
              controller.addListener(() => _epg.text = controller.text.split(' — ').first);
              return TextField(
                controller: controller,
                focusNode: focus,
                decoration: _field(tr('Chaîne du guide TV'), original.epgId ?? tr('Tapez un nom (ex. TF1)')),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            tr('Les champs vides gardent la valeur du fournisseur. La correction s\'applique à cette version de la chaîne (HD, FHD…) et reste après chaque actualisation de la source.'),
            style: kText(12, color: KPalette.ink54),
          ),
        ]),
      ),
      actions: [
        if (context.library.channelEdits.containsKey(widget.item.id))
          TextButton(
            onPressed: () {
              context.library.setChannelEdit(widget.item.id, null);
              Navigator.pop(context);
            },
            child: Text(tr('Rétablir'), style: kText(14, color: KPalette.orange)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Annuler'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: KPalette.accent), onPressed: _save, child: Text(tr('Enregistrer'))),
      ],
    );
  }
}
