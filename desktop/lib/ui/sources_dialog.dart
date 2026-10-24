import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../l10n.dart';
import '../theme.dart';

/// Gestion des sources : liste, ajout (Xtream Codes ou playlist M3U), actualisation, suppression.
Future<void> showSourcesDialog(BuildContext context, {bool startAdding = false}) => showDialog(
      context: context,
      builder: (_) => AppScope(
        library: context.library,
        playback: context.playback,
        navigation: context.navigation,
        child: _SourcesDialog(startAdding: startAdding),
      ),
    );

class _SourcesDialog extends StatefulWidget {
  const _SourcesDialog({required this.startAdding});
  final bool startAdding;

  @override
  State<_SourcesDialog> createState() => _SourcesDialogState();
}

class _SourcesDialogState extends State<_SourcesDialog> {
  late bool _adding = widget.startAdding;
  bool _xtream = true;
  bool _saving = false;
  String? _error;
  final _name = TextEditingController();
  final _server = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _server, _user, _pass, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final library = context.library;
    try {
      if (_xtream) {
        await library.addXtream(name: _name.text, server: _server.text, username: _user.text, password: _pass.text);
      } else {
        await library.addM3U(name: _name.text, address: _address.text);
      }
      if (library.lastError != null) {
        setState(() => _error = library.lastError);
      } else {
        setState(() => _adding = false);
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _field(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    return Dialog(
      backgroundColor: const Color(0xFF242426),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: ListenableBuilder(
            listenable: library,
            builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Sources'), style: kRounded(24, FontWeight.w800)),
              const SizedBox(height: 14),
              if (!_adding) ...[
                if (library.sources.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(tr('Ajoutez votre abonnement IPTV (Xtream Codes ou playlist M3U) pour commencer.'),
                        style: kText(13, color: KPalette.secondaryText)),
                  ),
                for (final source in library.sources) _sourceRow(source),
                const SizedBox(height: 16),
                Row(children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: KPalette.magenta),
                    onPressed: () => setState(() => _adding = true),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(tr('Ajouter une source')),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Fermer'))),
                ]),
              ] else
                Flexible(child: SingleChildScrollView(child: _addForm())),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sourceRow(Source source) {
    final library = context.library;
    final count = library.items(MediaKind.live).where((i) => i.sourceId == source.id).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(source.kind == SourceKind.xtream ? Icons.dns_rounded : Icons.playlist_play_rounded, color: KPalette.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(source.name, style: kText(14, weight: FontWeight.w600)),
            Text(
              '${source.kind == SourceKind.xtream ? 'Xtream Codes' : 'Playlist M3U'} · $count ${tr('chaînes')}',
              style: kText(12, color: KPalette.secondaryText),
            ),
          ]),
        ),
        IconButton(
          tooltip: tr('Actualiser'),
          onPressed: library.isBusy ? null : () => library.refresh(source),
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: tr('Supprimer'),
          onPressed: () => library.removeSource(source),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ]),
    );
  }

  Widget _addForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('Xtream Codes'), icon: Icon(Icons.dns_rounded)),
          ButtonSegment(value: false, label: Text('Playlist M3U'), icon: Icon(Icons.playlist_play_rounded)),
        ],
        selected: {_xtream},
        onSelectionChanged: (v) => setState(() => _xtream = v.first),
      ),
      const SizedBox(height: 16),
      TextField(controller: _name, decoration: _field(tr('Nom'), hint: 'Mon abonnement')),
      const SizedBox(height: 12),
      if (_xtream) ...[
        TextField(controller: _server, decoration: _field(tr('Serveur'), hint: 'http://exemple.com:8080')),
        const SizedBox(height: 12),
        TextField(controller: _user, decoration: _field(tr('Identifiant'))),
        const SizedBox(height: 12),
        TextField(controller: _pass, obscureText: true, decoration: _field(tr('Mot de passe'))),
      ] else
        TextField(
          controller: _address,
          decoration: _field(tr('Adresse de la playlist ou chemin du fichier'), hint: 'http://…/get.php?username=…&password=…'),
        ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: kText(13, color: KPalette.orange)),
      ],
      const SizedBox(height: 18),
      Row(children: [
        if (_saving) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        const Spacer(),
        TextButton(onPressed: _saving ? null : () => setState(() => _adding = false), child: Text(tr('Annuler'))),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: KPalette.magenta),
          onPressed: _saving ? null : _save,
          child: Text(tr('Ajouter')),
        ),
      ]),
    ]);
  }
}
