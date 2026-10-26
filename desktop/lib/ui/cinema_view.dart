import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/epg.dart';
import '../core/guide.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/themes.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'catalog_screen.dart';
import 'themes_view.dart';
import 'recents_editor.dart';
import 'widgets.dart';

/// Interface Cinéma d'une section : bandeau « à la une », rangées (thèmes, catégories), grilles d'affiches ou de vignettes.
class CinemaView extends StatefulWidget {
  const CinemaView({super.key, required this.kind});
  final MediaKind kind;

  @override
  State<CinemaView> createState() => _CinemaViewState();
}

class _CinemaViewState extends State<CinemaView> {
  final _search = TextEditingController();
  Timer? _minute;

  @override
  void initState() {
    super.initState();
    // Programmes en cours et barres d'avancement : mise à jour chaque minute.
    if (widget.kind == MediaKind.live) _minute = Timer.periodic(Duration(minutes: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _minute?.cancel();
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
        listenable: Listenable.merge([context.library, navigation, context.watch, if (widget.kind == MediaKind.live) context.guide]),
        builder: (context, _) {
          final filter = navigation.filter(widget.kind);
          final searching = navigation.search.trim().isNotEmpty;
          final Widget body;
          if (searching) {
            body = CinemaGrid(title: '${tr('Résultats pour')} « ${navigation.search} »', items: filteredItems(context, widget.kind));
          } else if (filter is AllItems) {
            body = widget.kind == MediaKind.live ? _LiveHome() : _CinemaHome(kind: widget.kind);
          } else if (filter is ThemesFilter) {
            body = _CinemaThemes();
          } else if (filter is RecentItems && navigation.editingRecents) {
            body = Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Row(children: [
                  Text(tr('Récents'), style: kText(22, weight: FontWeight.w700)),
                  Spacer(),
                  RecentsEditButton(kind: widget.kind),
                ]),
              ),
              Expanded(child: RecentsEditor(kind: widget.kind)),
            ]);
          } else {
            body = CinemaGrid(
              title: filterTitle(context, widget.kind),
              items: filteredItems(context, widget.kind),
              trailing: filter is RecentItems ? RecentsEditButton(kind: widget.kind) : null,
            );
          }
          return Column(children: [
            Container(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 10),
              child: Row(children: [
                Text(sectionTitle(widget.kind), style: kRounded(22, FontWeight.w800)),
                if (widget.kind == MediaKind.live && context.guide.isLoading) ...[
                  SizedBox(width: 12),
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text(tr('Guide TV…'), style: kText(12, color: KPalette.secondaryText)),
                ],
                Spacer(),
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

Widget _railList(List<Widget> rails) => ListView.builder(
      padding: EdgeInsets.only(bottom: 30),
      itemCount: rails.length,
      itemBuilder: (context, index) => Padding(padding: EdgeInsets.only(bottom: 26), child: rails[index]),
    );

/// Accueil Films / Séries.
class _CinemaHome extends StatelessWidget {
  const _CinemaHome({required this.kind});
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final watch = context.watch;
    final all = library.items(kind);
    if (all.isEmpty) return _emptySection(context);
    final recents = library.recentsOf(kind);
    final started = recents.where((i) => watch.fraction(i.id) != null).toList();
    final others = recents.where((i) => watch.fraction(i.id) == null).toList();
    final favorites = library.favoritesOf(kind);
    final latest = library.latest(kind);
    return _railList([
      if (context.settings.heroEnabled) HeroCarousel(kind: kind),
      if (started.isNotEmpty) CinemaRail.items(title: tr('Reprendre la lecture'), items: started),
      if (latest.isNotEmpty) CinemaRail.items(title: tr('Derniers ajouts'), items: latest),
      if (others.isNotEmpty)
        CinemaRail.items(title: tr('Regardés récemment'), items: others, onSeeAll: () => context.navigation.show(kind, RecentItems())),
      if (favorites.isNotEmpty)
        CinemaRail.items(title: tr('Favoris'), items: favorites, onSeeAll: () => context.navigation.show(kind, FavoriteItems())),
      for (final name in library.categories(kind))
        if (library.categoryInCountries(name))
        CinemaRail.items(
          title: library.categoryName(kind, name),
          items: library.itemsInCategory(kind, name),
          onSeeAll: () => context.navigation.show(kind, CategoryFilter(name)),
        ),
    ]);
  }
}

Widget _emptySection(BuildContext context) => Center(
      child: Text(context.library.isBusy ? tr('Chargement…') : tr('Aucun contenu dans cette section.'),
          style: kText(15, color: KPalette.secondaryText)),
    );

/// Accueil Cinéma du direct : bandeau, ce qui passe par thème, ce soir, récents, favoris, catégories.
class _LiveHome extends StatelessWidget {
  const _LiveHome();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([context.library, context.guide, context.navigation]),
        builder: (context, _) => _content(context),
      );

  Widget _content(BuildContext context) {
    final library = context.library;
    final guide = context.guide;
    final navigation = context.navigation;
    if (library.items(MediaKind.live).isEmpty) return _emptySection(context);
    // Ce qui passe : programmes du guide d'abord, puis les chaînes classées par leur nom.
    final rails = <Widget>[
      if (context.settings.heroEnabled) HeroCarousel(kind: MediaKind.live),
    ];
    for (final theme in ContentTheme.homeRails) {
      final entries = guide.now(theme: theme)..sort((a, b) => (a.$2 == null ? 1 : 0).compareTo(b.$2 == null ? 1 : 0));
      if (entries.isEmpty) continue;
      rails.add(CinemaRail.live(
        title: theme.nowTitle,
        entries: entries,
        onSeeAll: () => navigation.showThemes(theme: theme),
      ));
    }
    final recents = library.recentsOf(MediaKind.live);
    final favorites = library.favoritesOf(MediaKind.live);
    if (recents.isNotEmpty) {
      rails.add(CinemaRail.items(
          title: tr('Regardées récemment'), items: recents, onSeeAll: () => navigation.show(MediaKind.live, RecentItems())));
    }
    if (favorites.isNotEmpty) {
      rails.add(CinemaRail.items(title: tr('Favoris'), items: favorites, onSeeAll: () => navigation.show(MediaKind.live, FavoriteItems())));
    }
    for (final theme in [ContentTheme.movies, ContentTheme.sport, ContentTheme.series, ContentTheme.documentary, ContentTheme.entertainment, ContentTheme.kids]) {
      final entries = guide.tonight(theme: theme);
      if (entries.isEmpty) continue;
      rails.add(CinemaRail.tonight(
        title: theme.tonightTitle,
        entries: entries,
        onSeeAll: () => navigation.showThemes(theme: theme, mode: ThemeView.tonight),
      ));
    }
    for (final name in library.categories(MediaKind.live)) {
      if (!library.categoryInCountries(name)) continue;
      rails.add(CinemaRail.items(
        title: library.categoryName(MediaKind.live, name),
        items: library.itemsInCategory(MediaKind.live, name),
        onSeeAll: () => navigation.show(MediaKind.live, CategoryFilter(name)),
      ));
    }
    return _railList(rails);
  }
}

/// Vue Thèmes de l'interface Cinéma.
class _CinemaThemes extends StatelessWidget {
  const _CinemaThemes();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([context.library, context.guide, context.navigation]),
        builder: (context, _) => _content(context),
      );

  Widget _content(BuildContext context) {
    final navigation = context.navigation;
    final entries = themeEntries(context);
    final tonight = navigation.themeMode == ThemeView.tonight;
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 6),
          child: Row(children: [
            Text(navigation.themeSelection?.label ?? tr('Thèmes'), style: kText(22, weight: FontWeight.w700)),
            SizedBox(width: 8),
            Text('${entries.length}', style: kText(13, color: KPalette.secondaryText)),
          ]),
        ),
      ),
      SliverToBoxAdapter(child: ThemesHeader(padding: EdgeInsets.fromLTRB(24, 6, 24, 12), compact: false)),
      if (entries.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(themesEmptyText(navigation.themeMode), style: kText(14, color: KPalette.secondaryText))),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 30),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: kTileWidth + 24,
              mainAxisExtent: kTileHeight + 60,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final (group, programme) = entries[i];
              return tonight && programme != null
                  ? ProgrammeCard(group: group, programme: programme)
                  : LiveCard(item: group.preferred, programme: programme, group: group);
            }, childCount: entries.length),
          ),
        ),
    ]);
  }
}

/// Tailles des affiches et vignettes (Réglages > Apparence > Taille des vignettes).
double get kPosterWidth => 150 * KPalette.cardScale;
double get kTileWidth => 208 * KPalette.cardScale;
double get kTileHeight => kTileWidth * 9 / 16;

/// Rangée horizontale d'affiches ou de vignettes.
class CinemaRail extends StatelessWidget {
  const CinemaRail({
    super.key,
    required this.title,
    required this.total,
    required this.builder,
    required this.height,
    this.onSeeAll,
    Size? seeAllSize,
  }) : _seeAllSize = seeAllSize; // ignore: prefer_initializing_formals

  /// Films, séries, épisodes ou chaînes (vignette adaptée au type).
  factory CinemaRail.items({required String title, required List<MediaItem> items, VoidCallback? onSeeAll}) {
    final live = items.isNotEmpty && items.first.kind == MediaKind.live;
    return CinemaRail(
      title: title,
      total: items.length,
      onSeeAll: onSeeAll,
      height: live ? kTileHeight + 64 : kPosterWidth * 1.5 + 48,
      seeAllSize: live ? Size(kTileWidth * 0.6, kTileHeight) : Size(kPosterWidth * 0.8, kPosterWidth * 1.5),
      builder: (context, i) => live ? LiveCard(item: items[i]) : MediaCard(item: items[i]),
    );
  }

  /// Chaînes à l'antenne avec leur programme.
  factory CinemaRail.live({required String title, required List<(LiveChannelGroup, Programme?)> entries, VoidCallback? onSeeAll}) =>
      CinemaRail(
        title: title,
        total: entries.length,
        onSeeAll: onSeeAll,
        height: kTileHeight + 64,
        seeAllSize: Size(kTileWidth * 0.6, kTileHeight),
        builder: (context, i) => LiveCard(item: entries[i].$1.preferred, programme: entries[i].$2, group: entries[i].$1),
      );

  /// Programmes de ce soir.
  factory CinemaRail.tonight({required String title, required List<(LiveChannelGroup, Programme)> entries, VoidCallback? onSeeAll}) =>
      CinemaRail(
        title: title,
        total: entries.length,
        onSeeAll: onSeeAll,
        height: kTileHeight + 64,
        seeAllSize: Size(kTileWidth * 0.6, kTileHeight),
        builder: (context, i) => ProgrammeCard(group: entries[i].$1, programme: entries[i].$2),
      );

  final String title;
  final int total;
  final Widget Function(BuildContext context, int index) builder;
  final double height;
  final VoidCallback? onSeeAll;
  final Size? _seeAllSize;
  Size get seeAllSize => _seeAllSize ?? Size(kPosterWidth * 0.8, kPosterWidth * 1.5);
  static const _limit = 40;

  @override
  Widget build(BuildContext context) {
    final shown = math.min(total, _limit);
    final more = total > _limit && onSeeAll != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(child: Text(title, style: kText(17, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text('$total', style: kText(12, color: KPalette.secondaryText)),
          const Spacer(),
          if (onSeeAll != null && total > 6) TextButton(onPressed: onSeeAll, child: Text(tr('Tout voir'))),
        ]),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: height,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          scrollDirection: Axis.horizontal,
          itemCount: shown + (more ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, i) =>
              i == shown ? _SeeAllCard(remaining: total - _limit, size: seeAllSize, onTap: onSeeAll!) : builder(context, i),
        ),
      ),
    ]);
  }
}

class _SeeAllCard extends StatelessWidget {
  const _SeeAllCard({required this.remaining, required this.size, required this.onTap});
  final int remaining;
  final Size size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: Hover(
          onTap: onTap,
          builder: (context, hovering) => Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: KPalette.ink.withValues(alpha: hovering ? 0.14 : 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.arrow_circle_right_outlined, size: 30),
              const SizedBox(height: 6),
              Text('+ $remaining', style: kText(14, weight: FontWeight.w600)),
              Text(tr('Tout voir'), style: kText(12, color: KPalette.secondaryText)),
            ]),
          ),
        ),
      );
}

/// Grille d'affiches ou de vignettes (catégorie, favoris, récents, recherche).
class CinemaGrid extends StatelessWidget {
  const CinemaGrid({super.key, required this.title, required this.items, this.trailing});
  final String title;
  final List<MediaItem> items;

  /// Bouton à droite du titre (ex. « Modifier » pour les récents).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final live = items.isNotEmpty && items.first.kind == MediaKind.live;
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        sliver: SliverToBoxAdapter(
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: Text(title, style: kText(22, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('${items.length}', style: kText(13, color: KPalette.secondaryText)),
            if (trailing != null) ...[const Spacer(), trailing!],
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
            gridDelegate: live
                ? SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: kTileWidth + 24, mainAxisExtent: kTileHeight + 60, crossAxisSpacing: 16, mainAxisSpacing: 16)
                : SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: kPosterWidth + 20, mainAxisExtent: kPosterWidth * 1.5 + 52, crossAxisSpacing: 16, mainAxisSpacing: 16),
            delegate: SliverChildBuilderDelegate(
              (context, i) => live ? LiveCard(item: items[i]) : MediaCard(item: items[i]),
              childCount: items.length,
            ),
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
    final width = kPosterWidth;
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
                    border: Border.all(color: KPalette.ink.withValues(alpha: hovering ? 0.55 : 0.08), width: hovering ? 2 : 1),
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
                          child: LinearProgressIndicator(value: fraction, minHeight: 3, color: KPalette.ink, backgroundColor: KPalette.ink24),
                        ),
                      if (favorite)
                        const Positioned(top: 6, right: 6, child: Icon(Icons.star_rounded, size: 16, color: Colors.amber)),
                      if (context.watch.isWatched(item.id))
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Tooltip(
                            message: tr('Vu'),
                            child: Container(
                              decoration: const BoxDecoration(color: Color(0xCC000000), shape: BoxShape.circle),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.greenAccent),
                            ),
                          ),
                        ),
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

/// Image 16/9 d'une chaîne : logo centré sur un dégradé de la palette Kastideo.
class ChannelTile extends StatelessWidget {
  const ChannelTile({super.key, required this.item, required this.hovering, this.progress, this.badge, this.favorite = false});
  final MediaItem item;
  final bool hovering;
  final double? progress;
  final String? badge;
  final bool favorite;

  @override
  Widget build(BuildContext context) {
    final hue = (item.name.hashCode % 40).toDouble();
    return Container(
      width: kTileWidth,
      height: kTileHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KPalette.ink.withValues(alpha: hovering ? 0.55 : 0.08), width: hovering ? 2 : 1),
        gradient: LinearGradient(
          colors: [HSLColor.fromColor(KPalette.indigo).withHue((248 + hue) % 360).withLightness(0.2).toColor(), KPalette.night],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Center(child: LogoView(url: item.logo, name: item.name, size: kTileHeight * 0.58)),
        if (badge != null)
          Positioned(
            top: 7,
            left: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: KPalette.orange, borderRadius: BorderRadius.circular(6)),
              child: Text(badge!, style: kText(12, weight: FontWeight.w700, color: Colors.black)),
            ),
          ),
        if (favorite) const Positioned(top: 6, right: 6, child: Icon(Icons.star_rounded, size: 16, color: Colors.amber)),
        if (progress != null)
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: progress, minHeight: 3, color: KPalette.orange, backgroundColor: KPalette.ink24),
            ),
          ),
      ]),
    );
  }
}

/// Vignette d'une chaîne : logo, nom, programme en cours et avancement.
class LiveCard extends StatelessWidget {
  const LiveCard({super.key, required this.item, this.programme, this.group});
  final MediaItem item;
  final Programme? programme;
  final LiveChannelGroup? group;

  @override
  Widget build(BuildContext context) {
    final guide = context.guide;
    final p = programme ?? guide.current(item);
    final g = group ?? guide.groupOf(item);
    final favorite = context.library.isFavorite(item.id);
    return GestureDetector(
      onSecondaryTapUp: (d) => g != null ? showGroupMenu(context, g, p, d.globalPosition) : showItemMenu(context, item, d.globalPosition),
      child: Tooltip(
        message: p == null ? item.name : '${item.name}\n${p.title} · ${timeRange(p)}',
        waitDuration: const Duration(milliseconds: 900),
        child: Hover(
          onTap: () => openItem(context, item),
          builder: (context, hovering) => AnimatedScale(
            scale: hovering ? 1.03 : 1,
            duration: const Duration(milliseconds: 120),
            child: SizedBox(
              width: kTileWidth,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ChannelTile(item: item, hovering: hovering, progress: p?.progress(), favorite: favorite),
                const SizedBox(height: 6),
                Text(item.displayName, style: kText(13, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  p == null ? (item.number != null ? '${item.number} · ${item.group}' : item.group) : '${hm(p.start)} · ${p.title}',
                  style: kText(11.5, color: KPalette.secondaryText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vignette d'un programme de ce soir : heure de début, titre, chaîne.
class ProgrammeCard extends StatelessWidget {
  const ProgrammeCard({super.key, required this.group, required this.programme});
  final LiveChannelGroup group;
  final Programme programme;

  @override
  Widget build(BuildContext context) {
    final item = group.preferred;
    final p = programme;
    final airing = p.isAiring(nowSeconds());
    return GestureDetector(
      onSecondaryTapUp: (d) => showGroupMenu(context, group, p, d.globalPosition),
      child: Tooltip(
        message: '${p.title}\n${item.displayName} · ${timeRange(p)}',
        waitDuration: const Duration(milliseconds: 900),
        child: Hover(
          onTap: () => openProgramme(context, item, p),
          builder: (context, hovering) => AnimatedScale(
            scale: hovering ? 1.03 : 1,
            duration: const Duration(milliseconds: 120),
            child: SizedBox(
              width: kTileWidth,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ChannelTile(item: item, hovering: hovering, badge: airing ? tr('EN DIRECT') : hm(p.start), progress: airing ? p.progress() : null),
                const SizedBox(height: 6),
                Text(p.title, style: kText(13, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${item.displayName} · ${timeRange(p)}',
                    style: kText(11.5, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: Bandeau « à la une »

/// Une diapositive du bandeau.
class HeroSlide {
  HeroSlide(this.item, this.caption, {this.backdrop});
  final MediaItem item;
  final String caption;
  final String? backdrop;
}

/// Bandeau « à la une » en carrousel (comme CinemaHeroCarousel sur Mac) :
/// films et séries (tendances TMDB, derniers ajouts, sélection d'une catégorie) ou programmes en cours du direct.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.kind});
  final MediaKind kind;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  List<HeroSlide> _slides = [];
  int _index = 0;
  Timer? _timer;
  bool _hovering = false;
  int _generation = 0;
  int _heroGeneration = -1;
  int _libraryCount = -1;
  late final AppSettings _settings;
  late final GuideStore _guide;
  late final Listenable _sources;
  int _countriesGeneration = 0;

  bool get _live => widget.kind == MediaKind.live;

  @override
  void initState() {
    super.initState();
    _settings = context.settings;
    _guide = context.guide;
    _sources = Listenable.merge([_settings, context.library, if (_live) _guide]);
    _sources.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sources.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    final count = context.library.count(widget.kind);
    final countries = context.library.countriesGeneration;
    if (_settings.heroGeneration != _heroGeneration || countries != _countriesGeneration || (_slides.isEmpty && count != _libraryCount) || _live) {
      _prepare();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    final seconds = math.max(_settings.heroInterval, 4).round();
    _timer = Timer.periodic(Duration(seconds: seconds), (_) {
      if (!_hovering && _slides.length > 1 && mounted) _go(_index + 1);
    });
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    final generation = ++_generation;
    _heroGeneration = _settings.heroGeneration;
    _countriesGeneration = context.library.countriesGeneration;
    _libraryCount = context.library.count(widget.kind);
    final slides = _live ? _liveSlides() : await _mediaSlides();
    if (!mounted || generation != _generation) return;
    final sameIds = slides.length == _slides.length && [for (var i = 0; i < slides.length; i++) slides[i].item.id == _slides[i].item.id].every((x) => x);
    setState(() {
      _slides = slides;
      if (!sameIds) _index = 0;
      if (_index >= _slides.length) _index = 0;
    });
    if (!sameIds) _restartTimer();
    _loadDetails();
  }

  /// Direct : chaînes favorites puis récentes avec leur programme en cours ;
  /// à défaut, les grandes chaînes d'info, de sport et généralistes à l'antenne.
  List<HeroSlide> _liveSlides() {
    final library = context.library;
    final caption = tr('EN CE MOMENT');
    final seen = <String>{};
    final mine = [...library.favoritesOf(MediaKind.live), ...library.recentsOf(MediaKind.live)].where((i) => seen.add(i.id)).toList();
    final slides = [
      for (final item in mine)
        if (_guide.current(item) != null) HeroSlide(item, caption),
    ].take(10).toList();
    if (slides.isNotEmpty) return slides;
    final keys = <String>{};
    final big = [
      for (final theme in const [ContentTheme.news, ContentTheme.sport, ContentTheme.general])
        ..._guide.now(theme: theme, withProgrammeOnly: true).where((e) => e.$1.preferred.logo != null).take(4),
    ];
    final fallback = [
      for (final e in big)
        if (keys.add(e.$1.key)) HeroSlide(e.$1.preferred, caption),
    ];
    if (fallback.isNotEmpty) return fallback.take(10).toList();
    // Sans guide TV : vos chaînes, sinon les généralistes reconnues par leur nom.
    if (mine.isNotEmpty) return [for (final item in mine.take(8)) HeroSlide(item, tr('VOS CHAÎNES'))];
    return [
      for (final g in _guide.channels(theme: ContentTheme.general).take(6)) HeroSlide(g.preferred, tr('À DÉCOUVRIR')),
    ];
  }

  Future<List<HeroSlide>> _mediaSlides() async {
    final library = context.library;
    final watch = context.watch;
    final info = context.info;
    final kind = widget.kind;
    final all = library.items(kind);
    if (all.isEmpty) return [];
    final groups = <List<HeroSlide>>[];
    final started = library.recentsOf(kind).where((i) => i.kind == kind && watch.fraction(i.id) != null).take(2);
    if (started.isNotEmpty) groups.add([for (final i in started) HeroSlide(i, tr('À REPRENDRE'))]);
    if (_settings.heroUseTrending && _settings.usesTMDB) {
      final trends = await info.trending(series: kind == MediaKind.series);
      if (!mounted) return [];
      final matched = info.match(trends, kind).where((m) => library.inCountries(m.$1)).take(6);
      if (matched.isNotEmpty) {
        groups.add([for (final (item, t) in matched) HeroSlide(item, tr('TENDANCE CETTE SEMAINE'), backdrop: t.backdrop)]);
      }
    }
    if (_settings.heroUseRecent) {
      final dated = library.latest(kind, limit: 6);
      final newest = dated.length >= 3 ? dated : all.reversed.where(library.inCountries).take(6).toList();
      groups.add([for (final i in newest) HeroSlide(i, tr('AJOUTÉ RÉCEMMENT'))]);
    }
    if (_settings.heroUseCategory) {
      final chosen = _settings.heroCategory(kind);
      final inCategory = chosen.isEmpty ? const <MediaItem>[] : library.itemsInCategory(kind, chosen);
      final inCountries = all.where(library.inCountries).toList();
      final pool = inCategory.isNotEmpty ? inCategory : (inCountries.isNotEmpty ? inCountries : all);
      final caption = inCategory.isNotEmpty ? library.categoryName(kind, chosen).toUpperCase() : tr('À DÉCOUVRIR');
      final rnd = math.Random();
      final picked = <MediaItem>[];
      final ids = <String>{};
      for (var i = 0; i < 60 && picked.length < 6; i++) {
        final item = pool[rnd.nextInt(pool.length)];
        if (item.logo != null && ids.add(item.id)) picked.add(item);
      }
      groups.add([for (final i in picked) HeroSlide(i, caption)]);
    }
    // Mélange : une diapositive de chaque source à tour de rôle.
    final result = <HeroSlide>[];
    final seen = <String>{};
    final longest = groups.fold<int>(0, (m, g) => math.max(m, g.length));
    for (var i = 0; i < longest; i++) {
      for (final g in groups) {
        if (i < g.length && seen.add(g[i].item.id)) result.add(g[i]);
      }
    }
    if (result.isEmpty) {
      final item = all.where((i) => i.logo != null).firstOrNull ?? all.first;
      result.add(HeroSlide(item, tr('À LA UNE')));
    }
    return result.take(15).toList();
  }

  void _loadDetails() {
    if (_slides.isEmpty || _live) return;
    context.info.load(_slides[_index].item);
    if (_slides.length > 1) context.info.load(_slides[(_index + 1) % _slides.length].item);
  }

  void _go(int index) {
    setState(() => _index = (index + _slides.length) % _slides.length);
    _loadDetails();
  }

  @override
  Widget build(BuildContext context) => DarkZone(child: Builder(builder: _buildDark));

  Widget _buildDark(BuildContext context) {
    if (_slides.isEmpty) return const SizedBox(height: 8);
    final height = _settings.heroHeight.points;
    final slide = _slides[_index];
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: SizedBox(
        height: height,
        child: ListenableBuilder(
          listenable: _live ? _guide : context.info,
          builder: (context, _) => Stack(fit: StackFit.expand, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _live
                  ? _HeroLiveSlide(key: ValueKey(slide.item.id), slide: slide, height: height)
                  : _HeroSlideView(key: ValueKey(slide.item.id), slide: slide, height: height),
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
      ),
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

Widget get _heroBottomFade => DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Color(0x99000000), KPalette.window],
      stops: [0.5, 0.85, 1],
    ),
  ),
);

Widget _caption(String text) => Text(text, style: kTextD(11, weight: FontWeight.w800, color: KPalette.orange).copyWith(letterSpacing: 1.5));

/// Diapositive film / série.
class _HeroSlideView extends StatelessWidget {
  const _HeroSlideView({super.key, required this.slide, required this.height});
  final HeroSlide slide;
  final double height;

  @override
  Widget build(BuildContext context) {
    final item = slide.item;
    final d = context.info.details(item.id);
    final backdrop = slide.backdrop ?? d?.backdrop;
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
      _heroBottomFade,
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
                _caption(slide.caption),
                const SizedBox(height: 4),
                Text(d?.title != null && d!.sources.contains('TMDB') ? d.title! : item.displayName,
                    style: kTextD(height < 300 ? 26 : 32, weight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meta, style: kTextD(13, weight: FontWeight.w500, color: Colors.white70)),
                ],
                if (d?.plot != null && height >= 300 && !isForeignText(d!.plot, L10n.english ? 'en' : 'fr')) ...[
                  const SizedBox(height: 8),
                  Text(d.plot!, style: kTextD(13, color: Colors.white.withValues(alpha: 0.85)), maxLines: 3, overflow: TextOverflow.ellipsis),
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

/// Diapositive du direct : programme en cours, horaires, avancement, programme suivant.
class _HeroLiveSlide extends StatelessWidget {
  const _HeroLiveSlide({super.key, required this.slide, required this.height});
  final HeroSlide slide;
  final double height;

  @override
  Widget build(BuildContext context) {
    final guide = context.guide;
    final item = slide.item;
    final p = guide.current(item);
    final next = guide.next(item);
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [KPalette.night, KPalette.indigo, KPalette.magenta.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      if (item.logo != null)
        Positioned(
          right: 50,
          top: 0,
          bottom: 0,
          child: Center(
            child: Opacity(
              opacity: 0.14,
              child: LogoView(url: item.logo, name: item.name, size: height * 0.5),
            ),
          ),
        ),
      _heroBottomFade,
      Positioned(
        left: 40,
        right: 40,
        bottom: 40,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            width: 170,
            height: 130,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: LogoView(url: item.logo, name: item.name, size: 110),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                _caption('${slide.caption} · ${item.displayName.toUpperCase()}'),
                const SizedBox(height: 6),
                Text(p?.title ?? item.displayName,
                    style: kTextD(height < 300 ? 26 : 32, weight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (p != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(timeRange(p), style: kTextD(13, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(value: p.progress(), minHeight: 4, color: KPalette.orange, backgroundColor: Colors.white24),
                      ),
                    ),
                  ]),
                  if (p.desc != null && height >= 300) ...[
                    const SizedBox(height: 8),
                    Text(p.desc!, style: kTextD(13, color: Colors.white.withValues(alpha: 0.8)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
                if (next != null) ...[
                  const SizedBox(height: 6),
                  Text('${tr('Ensuite à')} ${hm(next.start)} : ${next.title}',
                      style: kTextD(12, color: Colors.white.withValues(alpha: 0.65)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  onPressed: () => openItem(context, item),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(tr('Regarder')),
                ),
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
