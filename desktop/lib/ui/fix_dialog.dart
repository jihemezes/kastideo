import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/details.dart';
import '../core/models.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'widgets.dart';

/// « Corriger la fiche… » d'un fichier local : recherche TMDB par titre (et année), puis choix du bon résultat.
Future<void> showFixDialog(BuildContext context, MediaItem item) => showKDialog(context: context, builder: (_) => _FixDialog(item: item));

class _FixDialog extends StatefulWidget {
  const _FixDialog({required this.item});
  final MediaItem item;

  @override
  State<_FixDialog> createState() => _FixDialogState();
}

class _FixDialogState extends State<_FixDialog> {
  late final _title = TextEditingController(text: cleanTitle(widget.item.name).title);
  late final _year = TextEditingController(text: cleanTitle(widget.item.name).year?.toString() ?? '');
  List<TMDBMatch>? _results;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _title.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final info = context.info;
    if (!context.settings.usesTMDB) {
      setState(() => _error = tr('Ajoutez une clé TMDB (Réglages > Général) pour chercher les fiches.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await info.searchTMDB(_title.text, series: widget.item.kind == MediaKind.series, year: int.tryParse(_year.text.trim()));
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return AlertDialog(
      title: Text(tr('Corriger la fiche'), style: kRounded(20, FontWeight.w800)),
      content: SizedBox(
        width: 620,
        height: 480,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${tr('Fichier')} : ${widget.item.stream?.split(RegExp(r'[\\/]')).last ?? widget.item.name}',
              style: kText(12, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _title,
                decoration: InputDecoration(labelText: tr('Titre'), isDense: true, border: const OutlineInputBorder()),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _year,
                decoration: InputDecoration(labelText: tr('Année'), isDense: true, border: const OutlineInputBorder()),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _busy ? null : _search, child: Text(tr('Chercher'))),
          ]),
          const SizedBox(height: 10),
          if (_error != null) Text(_error!, style: kText(13, color: KPalette.orange)),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: results == null
                ? const SizedBox.shrink()
                : results.isEmpty
                    ? Center(child: Text(tr('Aucun résultat'), style: kText(13, color: KPalette.secondaryText)))
                    : ListView(children: [
                        for (final r in results)
                          ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: PosterImage(url: r.poster, name: r.title, width: 40, height: 60),
                            ),
                            title: Text(r.year == null ? r.title : '${r.title} (${r.year})', style: kText(14, weight: FontWeight.w600)),
                            subtitle: Text(r.overview ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: kText(12, color: KPalette.secondaryText)),
                            onTap: () async {
                              await context.info.applyFix(widget.item, r);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                      ]),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Annuler')))],
    );
  }
}
