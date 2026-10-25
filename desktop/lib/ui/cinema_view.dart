import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../l10n.dart';
import '../theme.dart';
import 'catalog_screen.dart';
import 'widgets.dart';

/// Interface Cinéma d'une section (Films, Séries) : bandeau « à la une », rangées par catégorie, grilles d'affiches.
class CinemaView extends StatefulWidget {
  const CinemaView({super.key, required this.kind});
  final MediaKind kind;

  @override
  State<CinemaView> createState() => _CinemaViewState();
}

class _CinemaViewState extends State<CinemaView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigation = context.navigation;
    if (_search.text != navigation.search) _search.text = navigation.search;
    return Container(
      color: KPalette.window,
      child: ListenableBuilder(
        listenable: Listenable.merge([context.library, navigation, context.watch]),
        builder: (context, _) {
          final filter = navigation.filter(widget.kind);
          final searching = navigation.search.trim().isNotEmpty;
          final Widget body;
          if (searching) {
            body = CinemaGrid(title: '${tr('Résultats pour')} « ${navigation.search} »', items: filteredItems(context, widget.kind));
          } else if (filter is AllItems) {
            body = _CinemaHome(kind: widget.kind);
          } else {
            body = CinemaGrid(title: filterTitle(context, widget.kind), items: filteredItems(context, widget.kind));
          }
          return Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
              child: Row(children: [
                Text(sectionTitle(widget.kind), style: kRounded(22, FontWeight.w800)),
                const Spacer(),
                SizedBox(width: 300, child: SearchBox(controller: _search, onChanged: navigation.setSearch, height: 34)),
              ]),
            ),
            Expanded(child: body),
          ]);
        },
      ),
    );
  }
}

class _CinemaHome extends StatelessWidget {
  const _CinemaHome({required this.kind});
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final watch = context.watch;
    final all = library.items(kind);
    if (all.isEmpty) {
      return Center(
        child: Text(library.isBusy ? tr('Chargement…') : tr('Aucun contenu dans cette section.'),
            style: kText(15, color: KPalette.secondaryText)),
      );
    }
    final recents = library.recentsOf(kind);
    final started = recents.where((i) => watch.fraction(i.id) != null).toList();
    final others = recents.where((i) => watch.fraction(i.id) == null).toList();
    final favorites = library.favoritesOf(kind);
    final latest = library.latest(kind);
    final categories = library.categories(kind);
    final rails = <Widget>[
      HeroCarousel(kind: kind),
      if (started.isNotEmpty) CinemaRail(title: tr('Reprendre la lecture'), items: started),
      if (latest.isNotEmpty) CinemaRail(title: tr('Derniers ajouts'), items: latest),
      if (others.isNotEmpty) CinemaRail(title: tr('Regardés récemment'), items: others,
          onSeeAll: () => context.navigation.show(kind, const RecentItems())),
      if (favorites.isNotEmpty) CinemaRail(title: tr('Favoris'), items: favorites,
          onSeeAll: () => context.navigation.show(kind, const FavoriteItems())),
    ];
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 30),
      itemCount: rails.length + categories.length,
      itemBuilder: (context, index) {
        if (index < rails.length) {
          return Padding(padding: const EdgeInsets.only(bottom: 26), child: rails[index]);
        }
        final name = categories[index - rails.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: CinemaRail(
            title: library.categoryName(kind, name),
            items: library.itemsInCategory(kind, name),
            onSeeAll: () => context.navigation.show(kind, CategoryFilter(name)),
          ),
        );
      },
    );
  }
}

const double kPosterWidth = 150;

/// Rangée horizontale d'affiches.
class CinemaRail extends StatelessWidget {
  const CinemaRail({super.key, required this.title, required this.items, this.onSeeAll});
  final String title;
  final List<MediaItem> items;
  final VoidCallback? onSeeAll;
  static const _limit = 40;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(_limit).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(child: Text(title, style: kText(17, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text('${items.length}', style: kText(12, color: KPalette.secondaryText)),
          const Spacer(),
          if (onSeeAll != null && items.length > 8) TextButton(onPressed: onSeeAll, child: Text(tr('Tout voir'))),
        ]),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: kPosterWidth * 1.5 + 48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          scrollDirection: Axis.horizontal,
          itemCount: shown.length + (items.length > _limit && onSeeAll != null ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, i) {
            if (i == shown.length) return _SeeAllCard(remaining: items.length - _limit, onTap: onSeeAll!);
            return MediaCard(item: shown[i]);
          },
        ),
      ),
    ]);
  }
}

class _SeeAllCard extends StatelessWidget {
  const _SeeAllCard({required this.remaining, required this.onTap});
  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Hover(
        onTap: onTap,
        builder: (context, hovering) => Container(
          width: kPosterWidth * 0.8,
          height: kPosterWidth * 1.5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: hovering ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.arrow_circle_right_outlined, size: 34),
            const SizedBox(height: 8),
            Text('+ $remaining', style: kText(15, weight: FontWeight.w600)),
            Text(tr('Tout voir'), style: kText(12, color: KPalette.secondaryText)),
          ]),
        ),
      );
}

/// Grille d'affiches (catégorie, favoris, récents, recherche).
class CinemaGrid extends StatelessWidget {
  const CinemaGrid({super.key, required this.title, required this.items});
  final String title;
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        sliver: SliverToBoxAdapter(
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: Text(title, style: kText(22, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('${items.length}', style: kText(13, color: KPalette.secondaryText)),
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
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: kPosterWidth + 20,
              mainAxisExtent: kPosterWidth * 1.5 + 52,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate((context, i) => MediaCard(item: items[i]), childCount: items.length),
          ),
        ),
    ]);
  }
}

/// Vignette d'un film ou d'une série : affiche, titre, catégorie, progression, favori.
class MediaCard extends StatelessWidget {
  const MediaCard({super.key, required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final fraction = context.watch.fraction(item.id);
    final favorite = context.library.isFavorite(item.id);
    const width = kPosterWidth;
    return GestureDetector(
      onSecondaryTapUp: (d) => showItemMenu(context, item, d.globalPosition),
      child: Tooltip(
        message: item.name,
        waitDuration: const Duration(milliseconds: 900),
        child: Hover(
          onTap: () => item.kind == MediaKind.episode ? playItem(context, item) : openItem(context, item),
          builder: (context, hovering) => AnimatedScale(
            scale: hovering ? 1.03 : 1,
            duration: const Duration(milliseconds: 120),
            child: SizedBox(
              width: width,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: hovering ? 0.55 : 0.08), width: hovering ? 2 : 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(children: [
                      PosterImage(url: item.logo, name: item.name, width: width, height: width * 1.5),
                      if (fraction != null)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: LinearProgressIndicator(value: fraction, minHeight: 3, color: Colors.white, backgroundColor: Colors.white24),
                        ),
                      if (favorite)
                        const Positioned(top: 6, right: 6, child: Icon(Icons.star_rounded, size: 16, color: Colors.amber)),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),
                Text(item.displayName, style: kText(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(item.group, style: kText(11, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau « à la une » en carrousel : contenus à reprendre, derniers ajouts et sélection au hasard.
/// Avec une clé TMDB, l'image de fond de la fiche est utilisée ; sinon l'affiche, floutée.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.kind});
  final MediaKind kind;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  List<MediaItem> _slides = [];
  int _index = 0;
  Timer? _timer;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_hovering && _slides.length > 1 && mounted) _go(_index + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prepare() {
    if (!mounted) return;
    final library = context.library;
    final watch = context.watch;
    final started = library.recentsOf(widget.kind).where((i) => i.kind == widget.kind && watch.fraction(i.id) != null).take(2);
    final latest = library.latest(widget.kind, limit: 30).where((i) => i.logo != null).toList()..shuffle();
    final random = library.items(widget.kind).where((i) => i.logo != null).toList();
    final picks = <MediaItem>[...started, ...latest.take(5)];
    final rnd = math.Random();
    for (var i = 0; i < 12 && picks.length < 8 && random.isNotEmpty; i++) {
      final item = random[rnd.nextInt(random.length)];
      if (!picks.any((p) => p.id == item.id)) picks.add(item);
    }
    setState(() => _slides = picks);
    _loadDetails();
  }

  void _loadDetails() {
    if (_slides.isEmpty) return;
    context.info.load(_slides[_index]);
    if (_slides.length > 1) context.info.load(_slides[(_index + 1) % _slides.length]);
  }

  void _go(int index) {
    setState(() => _index = (index + _slides.length) % _slides.length);
    _loadDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) return const SizedBox(height: 8);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: LayoutBuilder(builder: (context, constraints) {
        final height = math.min(math.max(constraints.maxWidth * 0.34, 300.0), 460.0);
        return SizedBox(
          height: height,
          child: ListenableBuilder(
            listenable: context.info,
            builder: (context, _) => Stack(fit: StackFit.expand, children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: _HeroSlide(key: ValueKey(_slides[_index].id), item: _slides[_index], height: height),
              ),
              if (_slides.length > 1) ...[
                Positioned(left: 8, top: 0, bottom: 0, child: Center(child: _arrow(Icons.chevron_left_rounded, () => _go(_index - 1)))),
                Positioned(right: 8, top: 0, bottom: 0, child: Center(child: _arrow(Icons.chevron_right_rounded, () => _go(_index + 1)))),
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < _slides.length; i++)
                      GestureDetector(
                        onTap: () => _go(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: i == _index ? 0.95 : 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ]),
                ),
              ],
            ]),
          ),
        );
      }),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => AnimatedOpacity(
        opacity: _hovering ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Hover(
          onTap: onTap,
          builder: (context, hovering) => Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: hovering ? 0.7 : 0.45), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      );
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({super.key, required this.item, required this.height});
  final MediaItem item;
  final double height;

  @override
  Widget build(BuildContext context) {
    final d = context.info.details(item.id);
    final backdrop = d?.backdrop;
    final poster = d?.poster ?? item.logo;
    final meta = [
      if (d?.year != null) '${d!.year}',
      if (d != null && d.genres.isNotEmpty) d.genres.take(2).join(', '),
      if (d?.rating != null) '★ ${d!.rating!.toStringAsFixed(1)}',
    ].join(' · ');
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Colors.black),
      if (backdrop != null)
        Image.network(backdrop, fit: BoxFit.cover, alignment: const Alignment(0, -0.25), errorBuilder: (_, _, _) => const SizedBox())
      else if (poster != null)
        Opacity(
          opacity: 0.6,
          child: ImageFiltered(
            imageFilter: ImageFilterBlurHero.blur,
            child: Image.network(poster, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
          ),
        ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xE6000000), Color(0x66000000), Colors.transparent], stops: [0, 0.55, 1]),
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0x99000000), KPalette.window],
            stops: [0.5, 0.85, 1],
          ),
        ),
      ),
      Positioned(
        left: 40,
        right: 40,
        bottom: 40,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 24, offset: const Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PosterImage(url: poster, name: item.name, width: height * 0.36, height: height * 0.54),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(tr('À LA UNE'), style: kText(11, weight: FontWeight.w800, color: KPalette.orange).copyWith(letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(d?.title != null && d!.sources.contains('TMDB') ? d.title! : item.displayName,
                    style: kText(32, weight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meta, style: kText(13, weight: FontWeight.w500, color: Colors.white70)),
                ],
                if (d?.plot != null) ...[
                  const SizedBox(height: 8),
                  Text(d!.plot!, style: kText(13, color: Colors.white.withValues(alpha: 0.85)), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 14),
                Wrap(spacing: 10, children: [
                  if (item.kind == MediaKind.movie)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                      onPressed: () {
                        context.navigation.select(item.kind, item);
                        playItem(context, item);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(tr('Lire')),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: () => openItem(context, item),
                    icon: const Icon(Icons.info_outline_rounded),
                    label: Text(item.kind == MediaKind.series ? tr('Voir les épisodes') : tr('Plus d\'infos')),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class ImageFilterBlurHero {
  static final blur = ImageFilter.blur(sigmaX: 28, sigmaY: 28);
}
