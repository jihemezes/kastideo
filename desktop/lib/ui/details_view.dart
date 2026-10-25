import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/details.dart';
import '../core/models.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'widgets.dart';

/// Fiche d'un film ou d'une série (reproduction de MediaInfoView sur Mac) : fond, affiche, titre, informations,
/// boutons Lire / Reprendre / Bande-annonce / Favori, résumé, générique, distribution et, pour une série, les épisodes.
class DetailsView extends StatefulWidget {
  const DetailsView({super.key, required this.item, required this.page});
  final MediaItem item;

  /// Page entière (interface Cinéma, avec bouton Retour) ou panneau de droite (interface Classique).
  final bool page;

  @override
  State<DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<DetailsView> {
  int? _season;
  final _episodesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.info.load(widget.item);
    });
  }

  @override
  void didUpdateWidget(covariant DetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _season = null;
      context.info.load(widget.item);
    }
  }

  MediaItem get item => widget.item;

  @override
  Widget build(BuildContext context) {
    final info = context.info;
    return ListenableBuilder(
      listenable: Listenable.merge([info, context.library, context.watch, context.settings]),
      builder: (context, _) {
        final d = info.details(item.id);
        return Stack(fit: StackFit.expand, children: [
          _backdrop(d),
          Scrollbar(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(widget.page ? 32 : 24, 16, widget.page ? 32 : 24, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (widget.page) ...[_backButton(context), const SizedBox(height: 22)] else const SizedBox(height: 8),
                _header(context, d),
                const SizedBox(height: 22),
                if (d?.plot != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: SelectableText(d!.plot!, style: kText(14, color: Colors.white).copyWith(height: 1.45)),
                  )
                else if (info.isLoading(item.id))
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                if (d != null && d.directors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.kind == MediaKind.series ? tr('Création') : tr('Réalisation'),
                        style: kText(13, weight: FontWeight.w600, color: Colors.white60)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(d.directors.join(', '), style: kText(13))),
                  ]),
                ],
                if (d != null && d.cast.isNotEmpty) ...[const SizedBox(height: 22), _cast(d)],
                if (item.kind == MediaKind.series) ...[const SizedBox(height: 24), KeyedSubtree(key: _episodesKey, child: _episodes(context))],
                const SizedBox(height: 18),
                _footer(context, d),
              ]),
            ),
          ),
        ]);
      },
    );
  }

  Widget _backdrop(MediaDetails? d) {
    final url = d?.backdrop ?? d?.poster ?? item.logo;
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Colors.black),
      if (url != null)
        Opacity(
          opacity: 0.55,
          child: ImageFiltered(
            imageFilter: d?.backdrop == null ? ImageFilterBlur.strong : ImageFilterBlur.none,
            child: Image.network(url, fit: BoxFit.cover, alignment: const Alignment(0, -0.25), errorBuilder: (_, _, _) => const SizedBox()),
          ),
        ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x59000000), Color(0xCC000000), Colors.black],
          ),
        ),
      ),
    ]);
  }

  Widget _backButton(BuildContext context) {
    final label = item.kind == MediaKind.series ? tr('Retour aux séries') : tr('Retour aux films');
    return Hover(
      onTap: () => context.navigation.select(item.kind == MediaKind.episode ? MediaKind.series : item.kind, null),
      builder: (context, hovering) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: hovering ? 0.22 : 0.14), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chevron_left_rounded, size: 18),
          Text(label, style: kText(13, weight: FontWeight.w600)),
        ]),
      ),
    );
  }

  String _title(MediaDetails? d) {
    if (d?.title != null && d!.sources.contains('TMDB')) return d.title!;
    return cleanTitle(d?.title ?? item.name).title;
  }

  String _meta(MediaDetails? d) {
    final parts = <String>[];
    if (d?.year != null) parts.add('${d!.year}');
    final runtime = d?.runtime;
    if (runtime != null) {
      final text = runtime >= 60 ? '${runtime ~/ 60} h ${(runtime % 60).toString().padLeft(2, '0')}' : '$runtime min';
      parts.add(item.kind == MediaKind.series ? '$text ${tr('par épisode')}' : text);
    }
    final seasons = d?.seasonCount;
    if (seasons != null && seasons > 0) parts.add(seasons == 1 ? tr('1 saison') : '$seasons ${tr('saisons')}');
    if (d != null && d.genres.isNotEmpty) parts.add(d.genres.take(3).join(', '));
    return parts.join(' · ');
  }

  Widget _header(BuildContext context, MediaDetails? d) {
    final posterWidth = widget.page ? 210.0 : 150.0;
    final title = _title(d);
    final meta = _meta(d);
    return Wrap(
      spacing: 26,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 36, offset: const Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: PosterImage(url: d?.poster ?? item.logo, name: item.name, width: posterWidth, height: posterWidth * 1.5),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: kText(widget.page ? 36 : 28, weight: FontWeight.w700), maxLines: 3),
            if (d?.originalTitle != null && d!.originalTitle != title) ...[
              const SizedBox(height: 4),
              Text(d.originalTitle!, style: kText(18, color: Colors.white60)),
            ],
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(meta, style: kText(13, weight: FontWeight.w500, color: Colors.white70)),
            ],
            if (d?.rating != null) ...[
              const SizedBox(height: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${d!.rating!.toStringAsFixed(1).replaceAll('.', L10n.english ? '.' : ',')} / 10',
                    style: kText(13, weight: FontWeight.w600)),
              ]),
            ],
            if (d?.tagline != null) ...[
              const SizedBox(height: 8),
              Text(d!.tagline!, style: kText(13, color: Colors.white70).copyWith(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 14),
            _actions(context, d),
          ]),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context, MediaDetails? d) {
    final library = context.library;
    final fraction = context.watch.fraction(item.id);
    final isSeries = item.kind == MediaKind.series;
    final playLabel = isSeries
        ? tr('Voir les épisodes')
        : fraction != null
            ? '${tr('Reprendre')} (${(fraction * 100).round()} %)'
            : tr('Lire');
    return Wrap(spacing: 10, runSpacing: 10, children: [
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: KPalette.accent, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
        onPressed: isSeries
            ? () {
                final target = _episodesKey.currentContext;
                if (target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 350));
              }
            : () => playItem(context, item),
        icon: Icon(isSeries ? Icons.list_rounded : Icons.play_arrow_rounded),
        label: Text(playLabel),
      ),
      if (d?.trailer != null)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
          onPressed: () => launchUrl(Uri.parse(d!.trailer!)),
          icon: const Icon(Icons.theaters_rounded),
          label: Text(tr('Bande-annonce')),
        ),
      Tooltip(
        message: tr('Ajouter ou retirer des favoris'),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: () => library.toggleFavorite(item.id),
          child: Icon(library.isFavorite(item.id) ? Icons.star_rounded : Icons.star_outline_rounded,
              color: library.isFavorite(item.id) ? Colors.amber : Colors.white),
        ),
      ),
    ]);
  }

  Widget _cast(MediaDetails d) {
    final withPhotos = d.cast.any((c) => c.photo != null);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('Distribution'), style: kText(18, weight: FontWeight.w600)),
      const SizedBox(height: 10),
      if (!withPhotos)
        Text(d.cast.map((c) => c.name).join(', '), style: kText(13, color: Colors.white70))
      else
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: d.cast.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final c = d.cast[i];
              return SizedBox(
                width: 92,
                child: Column(children: [
                  ClipOval(
                    child: Container(
                      width: 84,
                      height: 84,
                      color: Colors.white.withValues(alpha: 0.12),
                      child: c.photo == null
                          ? const Icon(Icons.person_rounded, size: 36, color: Colors.white38)
                          : Image.network(c.photo!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.person_rounded)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(c.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: kText(12, weight: FontWeight.w600)),
                  if (c.role != null)
                    Text(c.role!, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: kText(11, color: Colors.white54)),
                ]),
              );
            },
          ),
        ),
    ]);
  }

  Widget _episodes(BuildContext context) {
    final info = context.info;
    final seasons = info.seasons(item.id);
    if (seasons == null) {
      if (info.isLoading(item.id)) {
        return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
      }
      return Text(tr('Cette source ne fournit pas de liste d\'épisodes.'), style: kText(13, color: Colors.white60));
    }
    if (seasons.isEmpty) return Text(tr('Aucun épisode.'), style: kText(13, color: Colors.white60));
    final current = seasons.where((s) => s.number == _season).firstOrNull ?? seasons.first;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('Épisodes'), style: kText(18, weight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in seasons)
          ChoiceChip(
            label: Text('${tr('Saison')} ${s.number}'),
            selected: s.number == current.number,
            onSelected: (_) => setState(() => _season = s.number),
          ),
      ]),
      const SizedBox(height: 12),
      for (final e in current.episodes) _EpisodeRow(episode: e),
    ]);
  }

  Widget _footer(BuildContext context, MediaDetails? d) {
    final info = context.info;
    final error = info.errors[item.id];
    final sources = d?.sources ?? const [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Expanded(child: Text(error, style: kText(12, color: Colors.orange))),
          ]),
        ),
      if (sources.isNotEmpty)
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
          Text('${tr('Informations')} : ${sources.map((s) => s == 'IPTV' ? tr('fournisseur IPTV') : s).join(' + ')}',
              style: kText(12, color: Colors.white54)),
          if (!context.settings.usesTMDB)
            Text(tr('· Ajoutez une clé TMDB dans Réglages > Général pour des fiches plus complètes.'),
                style: kText(12, color: Colors.white54)),
          TextButton(onPressed: () => info.load(item, force: true), child: Text(tr('Actualiser'))),
        ]),
    ]);
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode});
  final MediaItem episode;

  @override
  Widget build(BuildContext context) {
    final fraction = context.watch.fraction(episode.id);
    final playing = context.playback.current?.id == episode.id;
    return Hover(
      onTap: () => playItem(context, episode),
      builder: (context, hovering) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: hovering ? 0.14 : 0.07),
          borderRadius: BorderRadius.circular(10),
          border: playing ? Border.all(color: KPalette.accent) : null,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              PosterImage(url: episode.logo, name: episode.name, width: 128, height: 72),
              Positioned.fill(
                child: Center(
                  child: Icon(Icons.play_circle_fill_rounded, size: 30, color: Colors.white.withValues(alpha: hovering ? 0.95 : 0.6)),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${episode.number != null ? '${episode.number}. ' : ''}${episode.name}',
                  style: kText(14, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (episode.info != null) ...[
                const SizedBox(height: 4),
                Text(episode.info!, style: kText(12, color: Colors.white60), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (fraction != null) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(value: fraction, minHeight: 3, color: KPalette.orange, backgroundColor: Colors.white12),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Flous prédéfinis (fond de la fiche quand il n'y a pas d'image de fond).
class ImageFilterBlur {
  static final strong = ImageFilter.blur(sigmaX: 30, sigmaY: 30);
  static final none = ImageFilter.blur(sigmaX: 0, sigmaY: 0);
}
