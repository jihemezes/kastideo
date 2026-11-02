import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/details.dart';
import '../core/models.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'widgets.dart';

/// « Corriger la fiche… » : code ou adresse TMDB, recherche par titre, ou titre / année / affiche / résumé saisis à la main.
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
  final _code = TextEditingController();
  final _cTitle = TextEditingController();
  final _cYear = TextEditingController();
  final _cPoster = TextEditingController();
  final _cPlot = TextEditingController();
  List<TMDBMatch>? _results;
  String? _error;
  bool _busy = false;
  MediaDetails? _preview;
  String? _codeProblem;
  bool _checking = false;
  bool _custom = false;

  FicheEdit? get _current => context.info.edits[widget.item.id];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.info.reloadEdits();
      if (!mounted) return;
      final e = _current;
      if (e != null) {
        setState(() {
          _code.text = e.tmdbId ?? '';
          _cTitle.text = e.title ?? '';
          _cYear.text = e.year?.toString() ?? '';
          _cPoster.text = e.poster ?? '';
          _cPlot.text = e.plot ?? '';
          _custom = _cTitle.text.isNotEmpty || _cYear.text.isNotEmpty || _cPoster.text.isNotEmpty || _cPlot.text.isNotEmpty;
        });
      } else {
        _search();
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _year, _code, _cTitle, _cYear, _cPoster, _cPlot]) {
      c.dispose();
    }
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

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _preview = null;
      _codeProblem = null;
    });
    final r = await context.info.lookup(_code.text, widget.item);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _preview = r.details;
      _codeProblem = r.problem;
    });
  }

  Future<void> _done(FicheEdit? edit) async {
    await context.info.setEdit(widget.item, edit);
    if (mounted) Navigator.pop(context);
  }

  String _summary(FicheEdit e) {
    final parts = [
      if (e.tmdbId != null && e.tmdbId!.isNotEmpty) 'TMDB ${e.tmdbId}',
      if (e.title != null && e.title!.isNotEmpty) tr('titre'),
      if (e.year != null) tr('année'),
      if (e.posterUrl != null) tr('affiche'),
      if (e.plot != null && e.plot!.isNotEmpty) tr('résumé'),
    ];
    return '${tr('Correction en place')} : ${parts.join(', ')}';
  }

  Widget _field(TextEditingController c, String label, {int lines = 1, double? width, void Function(String)? onSubmitted}) {
    final field = TextField(
      controller: c,
      minLines: lines,
      maxLines: lines,
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      onSubmitted: onSubmitted,
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final current = _current;
    final preview = _preview;
    return AlertDialog(
      title: Text(tr('Corriger la fiche'), style: kRounded(20, FontWeight.w800)),
      content: SizedBox(
        width: 640,
        height: 560,
        child: ListView(children: [
          Text(widget.item.stream?.split(RegExp(r'[\\/]')).last ?? widget.item.name,
              style: kText(12, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (current != null && !current.isEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(_summary(current), style: kText(13))),
              TextButton(onPressed: () => _done(null), child: Text(tr('Retirer la correction'))),
            ]),
          ],
          const SizedBox(height: 12),
          Text(tr('Code TMDB'), style: kText(14, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(tr('Sur themoviedb.org, ouvrez la bonne fiche : le numéro est dans l\'adresse (…/movie/12345-hero). Saisissez ce numéro ou collez l\'adresse.'),
              style: kText(12, color: KPalette.secondaryText)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _field(_code, tr('Numéro ou adresse TMDB'), onSubmitted: (_) => _check())),
            const SizedBox(width: 8),
            FilledButton(onPressed: _checking || _code.text.trim().isEmpty ? null : _check, child: Text(tr('Vérifier'))),
          ]),
          if (_checking) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          if (_codeProblem != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_codeProblem!, style: kText(13, color: KPalette.orange))),
          if (preview != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(4), child: PosterImage(url: preview.poster, name: preview.title ?? '', width: 54, height: 81)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(preview.year == null ? (preview.title ?? '') : '${preview.title} (${preview.year})', style: kText(14, weight: FontWeight.w700)),
                    Text(preview.plot ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: kText(12, color: KPalette.secondaryText)),
                    const SizedBox(height: 6),
                    FilledButton(
                      onPressed: () {
                        final edit = current?.copy() ?? FicheEdit();
                        edit.tmdbId = preview.tmdbId;
                        _done(edit);
                      },
                      child: Text(tr('Utiliser cette fiche')),
                    ),
                  ]),
                ),
              ]),
            ),
          const Divider(height: 28),
          Text(tr('Chercher par titre'), style: kText(14, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _field(_title, tr('Titre'), onSubmitted: (_) => _search())),
            const SizedBox(width: 8),
            _field(_year, tr('Année'), width: 90, onSubmitted: (_) => _search()),
            const SizedBox(width: 8),
            FilledButton(onPressed: _busy ? null : _search, child: Text(tr('Chercher'))),
          ]),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: kText(13, color: KPalette.orange))),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          if (results != null && results.isEmpty)
            Padding(padding: const EdgeInsets.all(12), child: Text(tr('Aucun résultat'), style: kText(13, color: KPalette.secondaryText))),
          if (results != null)
            for (final r in results)
              ListTile(
                leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: PosterImage(url: r.poster, name: r.title, width: 40, height: 60)),
                title: Text('${r.year == null ? r.title : '${r.title} (${r.year})'} · TMDB ${r.tmdbId}', style: kText(14, weight: FontWeight.w600)),
                subtitle: Text(r.overview ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: kText(12, color: KPalette.secondaryText)),
                onTap: () async {
                  await context.info.applyFix(widget.item, r);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          const Divider(height: 28),
          InkWell(
            onTap: () => setState(() => _custom = !_custom),
            child: Row(children: [
              Icon(_custom ? Icons.expand_more : Icons.chevron_right),
              Text(tr('Personnaliser la fiche à la main'), style: kText(14, weight: FontWeight.w700)),
            ]),
          ),
          if (_custom) ...[
            const SizedBox(height: 6),
            Text(tr('Les champs remplis remplacent ceux du fournisseur et de TMDB. Laissez vide pour ne rien changer.'),
                style: kText(12, color: KPalette.secondaryText)),
            const SizedBox(height: 8),
            _field(_cTitle, tr('Titre affiché')),
            const SizedBox(height: 8),
            _field(_cYear, tr('Année'), width: 120),
            const SizedBox(height: 8),
            _field(_cPoster, tr('Adresse de l\'affiche (https://…)')),
            const SizedBox(height: 8),
            _field(_cPlot, tr('Résumé'), lines: 4),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  final edit = current?.copy() ?? FicheEdit();
                  edit.title = _cTitle.text.trim();
                  edit.year = int.tryParse(_cYear.text.trim());
                  edit.poster = _cPoster.text.trim();
                  edit.plot = _cPlot.text.trim();
                  _done(edit);
                },
                child: Text(tr('Enregistrer')),
              ),
            ),
          ],
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Fermer')))],
    );
  }
}
