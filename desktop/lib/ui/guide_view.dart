import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../core/epg.dart';
import '../core/models.dart';
import '../core/text.dart';
import '../core/themes.dart';
import '../l10n.dart';
import '../theme.dart';
import 'catalog_screen.dart';
import 'themes_view.dart';
import 'widgets.dart';

/// Filtre des chaînes (guide TV, panneau de l'interface TV).
sealed class ChannelFilter {
  const ChannelFilter();
}

class AllChannels extends ChannelFilter {
  const AllChannels();
}

class FavoriteChannels extends ChannelFilter {
  const FavoriteChannels();
}

class RecentChannels extends ChannelFilter {
  const RecentChannels();
}

class CategoryChannels extends ChannelFilter {
  const CategoryChannels(this.name);
  final String name;
}

class ThemeChannels extends ChannelFilter {
  const ThemeChannels(this.theme);
  final ContentTheme theme;
}

String channelFilterTitle(BuildContext context, ChannelFilter f) => switch (f) {
      AllChannels() => tr('Toutes les chaînes'),
      FavoriteChannels() => tr('Favoris'),
      RecentChannels() => tr('Récents'),
      CategoryChannels(:final name) => context.library.categoryName(MediaKind.live, name),
      ThemeChannels(:final theme) => theme.label,
    };

/// Chaînes d'un filtre ; pour un thème, une version par chaîne (chaînes du thème ou qui le diffusent en ce moment).
List<MediaItem> channelsFor(BuildContext context, ChannelFilter f, String query) {
  final library = context.library;
  final guide = context.guide;
  final base = switch (f) {
    AllChannels() => library.items(MediaKind.live),
    FavoriteChannels() => library.favoritesOf(MediaKind.live),
    RecentChannels() => library.recentsOf(MediaKind.live),
    CategoryChannels(:final name) => library.itemsInCategory(MediaKind.live, name),
    ThemeChannels(:final theme) => [
        for (final g in guide.groups)
          if (g.theme == theme || guide.epg.current(g.epgId)?.theme == theme) g.preferred,
      ],
  };
  final key = query.searchKey;
  return key.isEmpty ? base : base.where((i) => i.searchKey.contains(key)).toList();
}

/// Menu de choix du filtre de chaînes.
Future<ChannelFilter?> pickChannelFilter(BuildContext context, Offset position) async {
  final library = context.library;
  final choice = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
    color: KPalette.menu,
    items: [
      PopupMenuItem(value: 'all', child: Text(tr('Toutes les chaînes'), style: kText(13))),
      PopupMenuItem(value: 'fav', child: Text(tr('Favoris'), style: kText(13))),
      PopupMenuItem(value: 'rec', child: Text(tr('Récents'), style: kText(13))),
      const PopupMenuDivider(),
      for (final t in ContentTheme.browsable(showAdult: library.showAdult))
        PopupMenuItem(
          value: 't:${t.name}',
          child: Row(children: [Icon(t.icon, size: 16, color: KPalette.ink60), const SizedBox(width: 8), Text(t.label, style: kText(13))]),
        ),
      if (library.categories(MediaKind.live).isNotEmpty) const PopupMenuDivider(),
      for (final name in library.categories(MediaKind.live))
        PopupMenuItem(value: 'c:$name', child: Text(library.categoryName(MediaKind.live, name), style: kText(13))),
    ],
  );
  if (choice == null) return null;
  if (choice == 'all') return const AllChannels();
  if (choice == 'fav') return const FavoriteChannels();
  if (choice == 'rec') return const RecentChannels();
  if (choice.startsWith('t:')) return ThemeChannels(ContentTheme.values.byName(choice.substring(2)));
  return CategoryChannels(choice.substring(2));
}

/// Écran du guide TV : barre latérale du direct et grille.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Row(children: [
          const SizedBox(width: 236, child: Sidebar(kind: MediaKind.live, guide: true)),
          VerticalDivider(width: 1, color: KPalette.separator),
          const Expanded(child: GuideView()),
        ]),
      );
}

/// Guide TV en grille (comme GuideView sur Mac) : chaînes en lignes, heures en colonnes.
class GuideView extends StatefulWidget {
  const GuideView({super.key});

  @override
  State<GuideView> createState() => _GuideViewState();
}

class _GuideViewState extends State<GuideView> {
  static const _labelWidth = 210.0;
  static const _rowHeight = 58.0;
  late DateTime _start = _defaultStart();
  int _span = 3;
  ChannelFilter _filter = const AllChannels();
  final _search = TextEditingController();
  Timer? _minute;

  /// Début de la demi-heure en cours, moins 30 minutes.
  static DateTime _defaultStart() {
    final s = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return DateTime.fromMillisecondsSinceEpoch(((s ~/ 1800) * 1800 - 1800) * 1000);
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final v = p.getInt('guide.span');
      if (v != null && mounted) setState(() => _span = v);
    });
    _minute = Timer.periodic(const Duration(minutes: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _minute?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setSpan(int value) {
    setState(() => _span = value);
    SharedPreferences.getInstance().then((p) => p.setInt('guide.span', value));
  }

  void _shift(int direction) => setState(() => _start = _start.add(Duration(hours: direction * (_span ~/ 2).clamp(1, 6))));

  /// Aujourd'hui : maintenant ; les autres jours : 19 h.
  void _jumpToDay(int offset) {
    setState(() {
      if (offset == 0) {
        _start = _defaultStart();
      } else {
        final d = DateTime.now().add(Duration(days: offset));
        _start = DateTime(d.year, d.month, d.day, 19);
      }
    });
  }

  String _dayLabel(DateTime d) {
    const fr = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    const en = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const frM = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    const enM = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return L10n.english
        ? '${en[d.weekday - 1]} ${enM[d.month - 1]} ${d.day}'
        : '${fr[d.weekday - 1]} ${d.day} ${frM[d.month - 1]}';
  }

  Future<void> _pickDay(Offset position) async {
    final now = DateTime.now();
    final choice = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: KPalette.menu,
      items: [
        for (var i = 0; i < 7; i++)
          PopupMenuItem(
            value: i,
            child: Text(
              i == 0
                  ? '${tr('Aujourd\'hui')} — ${_dayLabel(now)}'
                  : i == 1
                      ? '${tr('Demain')} — ${_dayLabel(now.add(const Duration(days: 1)))}'
                      : _dayLabel(now.add(Duration(days: i))),
              style: kText(13),
            ),
          ),
      ],
    );
    if (choice != null) _jumpToDay(choice);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KPalette.window,
      child: ListenableBuilder(
        listenable: Listenable.merge([context.guide, context.library, context.recordings, context.alerts]),
        builder: (context, _) {
          final guide = context.guide;
          final rows = [
            for (final item in channelsFor(context, _filter, _search.text))
              if (guide.programmesOf(item).isNotEmpty) item,
          ];
          return Column(children: [
            _controls(context),
            Divider(height: 1, color: KPalette.separator),
            Expanded(
              child: rows.isEmpty
                  ? _empty(context)
                  : LayoutBuilder(builder: (context, c) {
                      final gridWidth = (c.maxWidth - _labelWidth).clamp(240.0, double.infinity);
                      final startS = _start.millisecondsSinceEpoch ~/ 1000;
                      final spanS = _span * 3600;
                      return Column(children: [
                        _GuideHeader(startS: startS, spanS: spanS, labelWidth: _labelWidth, gridWidth: gridWidth),
                        Expanded(
                          child: ListView.builder(
                            itemCount: rows.length,
                            itemExtent: _rowHeight,
                            itemBuilder: (context, i) => _GuideRow(
                              item: rows[i],
                              startS: startS,
                              spanS: spanS,
                              labelWidth: _labelWidth,
                              gridWidth: gridWidth,
                              height: _rowHeight,
                            ),
                          ),
                        ),
                      ]);
                    }),
            ),
          ]);
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final searching = _search.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (context.guide.isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(tr('Chargement du guide TV…'), style: kText(14, color: KPalette.secondaryText)),
          ] else ...[
            Icon(Icons.calendar_month_rounded, size: 56, color: KPalette.ink.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(searching ? tr('Aucun résultat') : tr('Aucun programme'), style: kText(17, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              searching
                  ? tr('Aucune chaîne ne correspond à cette recherche.')
                  : tr('Le guide TV n\'est pas chargé, ou aucune chaîne de ce filtre n\'a de programmes. Vérifiez l\'état du guide dans Réglages > Sources et le guide de secours dans Réglages > Général.'),
              textAlign: TextAlign.center,
              style: kText(13, color: KPalette.secondaryText),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    Widget iconButton(IconData icon, String tip, VoidCallback onTap) =>
        IconButton(tooltip: tip, onPressed: onTap, icon: Icon(icon), visualDensity: VisualDensity.compact);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        Text(tr('Guide TV'), style: kRounded(22, FontWeight.w800)),
        const SizedBox(width: 10),
        iconButton(Icons.chevron_left_rounded, tr('Plus tôt'), () => _shift(-1)),
        OutlinedButton(onPressed: () => _jumpToDay(0), child: Text(tr('Maintenant'))),
        iconButton(Icons.chevron_right_rounded, tr('Plus tard'), () => _shift(1)),
        const SizedBox(width: 6),
        Builder(
          builder: (context) => TextButton.icon(
            onPressed: () {
              final box = context.findRenderObject() as RenderBox;
              _pickDay(box.localToGlobal(Offset(0, box.size.height)));
            },
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(_dayLabel(_start), style: kText(14, weight: FontWeight.w600)),
          ),
        ),
        const Spacer(),
        SegmentedButton<int>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment(value: 2, label: Text('2 h')),
            ButtonSegment(value: 3, label: Text('3 h')),
            ButtonSegment(value: 6, label: Text('6 h')),
          ],
          selected: {_span},
          onSelectionChanged: (v) => _setSpan(v.first),
        ),
        const SizedBox(width: 10),
        Builder(
          builder: (context) => TextButton.icon(
            onPressed: () async {
              final box = context.findRenderObject() as RenderBox;
              final f = await pickChannelFilter(context, box.localToGlobal(Offset(0, box.size.height)));
              if (f != null) setState(() => _filter = f);
            },
            icon: const Icon(Icons.filter_list_rounded, size: 18),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(channelFilterTitle(context, _filter), overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200, minWidth: 120),
            child: SearchBox(controller: _search, onChanged: (_) => setState(() {}), height: 34),
          ),
        ),
      ]),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.startS, required this.spanS, required this.labelWidth, required this.gridWidth});
  final int startS;
  final int spanS;
  final double labelWidth;
  final double gridWidth;

  @override
  Widget build(BuildContext context) {
    final now = nowSeconds();
    final count = spanS ~/ 1800;
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: KPalette.panel,
        border: Border(bottom: BorderSide(color: KPalette.separator)),
      ),
      child: Row(children: [
        SizedBox(width: labelWidth),
        SizedBox(
          width: gridWidth,
          child: ClipRect(
            child: Stack(children: [
              for (var i = 0; i < count; i++)
                Positioned(
                  left: gridWidth * i * 1800 / spanS + 6,
                  top: 7,
                  child: Text(hm(DateTime.fromMillisecondsSinceEpoch((startS + i * 1800) * 1000)),
                      style: kText(12, weight: i.isEven ? FontWeight.w600 : FontWeight.w400, color: i.isEven ? KPalette.ink : KPalette.ink54)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              if (now >= startS && now <= startS + spanS)
                Positioned(left: gridWidth * (now - startS) / spanS, top: 0, bottom: 0, child: Container(width: 2, color: Colors.red)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.item,
    required this.startS,
    required this.spanS,
    required this.labelWidth,
    required this.gridWidth,
    required this.height,
  });
  final MediaItem item;
  final int startS;
  final int spanS;
  final double labelWidth;
  final double gridWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final now = nowSeconds();
    final end = startS + spanS;
    final programmes = context.guide.programmesOf(item).where((p) => p.stopS > startS && p.startS < end);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: KPalette.separator))),
      child: Row(children: [
        GestureDetector(
          onSecondaryTapUp: (d) => showItemMenu(context, item, d.globalPosition),
          child: Hover(
            onTap: () => openItem(context, item),
            builder: (context, hovering) => Container(
              width: labelWidth,
              height: height,
              color: hovering ? KPalette.ink.withValues(alpha: 0.06) : KPalette.list,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                if (item.number != null)
                  SizedBox(
                    width: 30,
                    child: Text('${item.number}', textAlign: TextAlign.right, style: kText(12, color: KPalette.secondaryText)),
                  ),
                const SizedBox(width: 6),
                LogoView(url: item.logo, name: item.name, size: 32),
                const SizedBox(width: 8),
                Expanded(child: Text(item.displayName, style: kText(13), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
        ),
        SizedBox(
          width: gridWidth,
          height: height,
          child: ClipRect(
            child: Stack(children: [
              for (final p in programmes)
                if (_x(p.stopS, gridWidth) - _x(p.startS, gridWidth) > 4)
                  Positioned(
                    left: _x(p.startS, gridWidth),
                    width: _x(p.stopS, gridWidth) - _x(p.startS, gridWidth),
                    top: 0,
                    bottom: 0,
                    child: _GuideCell(item: item, programme: p),
                  ),
              if (now >= startS && now <= end)
                Positioned(
                  left: gridWidth * (now - startS) / spanS,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(child: Container(width: 2, color: Colors.red.withValues(alpha: 0.85))),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  double _x(int t, double w) => ((t - startS) / spanS).clamp(0.0, 1.0) * w;
}

class _GuideCell extends StatelessWidget {
  const _GuideCell({required this.item, required this.programme});
  final MediaItem item;
  final Programme programme;

  @override
  Widget build(BuildContext context) {
    final p = programme;
    final now = nowSeconds();
    final current = p.isAiring(now);
    final past = p.stopS <= now;
    return LayoutBuilder(
      builder: (context, c) => Tooltip(
        message: '${p.title}\n${timeRange(p)}',
        waitDuration: const Duration(milliseconds: 700),
        child: Hover(
          onTap: () => showGuideProgramme(context, item, p),
          builder: (context, hovering) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: current
                  ? KPalette.accent.withValues(alpha: hovering ? 0.45 : 0.32)
                  : KPalette.ink.withValues(alpha: (past ? 0.04 : 0.09) + (hovering ? 0.06 : 0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (context.recordings.isScheduled(item, p)) ...[
                  const Icon(Icons.fiber_manual_record, size: 10, color: Colors.red),
                  const SizedBox(width: 3),
                ],
                if (context.alerts.isWatching(item, p)) ...[
                  const Icon(Icons.notifications_active_rounded, size: 11, color: KPalette.orange),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(p.title,
                      style: kText(12, weight: FontWeight.w600, color: past ? KPalette.ink54 : KPalette.ink),
                      maxLines: c.maxWidth > 80 ? 1 : 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              if (c.maxWidth > 80)
                Text(timeRange(p), style: kText(11, color: KPalette.ink54), maxLines: 1, overflow: TextOverflow.clip),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Fiche d'un programme du guide : horaires, avancement, résumé, regarder.
Future<void> showGuideProgramme(BuildContext context, MediaItem channel, Programme p) {
  final now = nowSeconds();
  final current = p.isAiring(now);
  final minutes = (p.stopS - p.startS) ~/ 60;
  final duration = minutes >= 60 ? '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}' : '$minutes min';
  return showDialog(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: KPalette.panel,
      title: Row(children: [
        LogoView(url: channel.logo, name: channel.name, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.title, style: kText(17, weight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('${channel.displayName} · ${timeRange(p)} ($duration)', style: kText(12, color: KPalette.secondaryText)),
          ]),
        ),
      ]),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (current)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(value: p.progress(), color: KPalette.orange, backgroundColor: KPalette.ink12),
            ),
          if (p.category != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(p.category!, style: kText(12, weight: FontWeight.w600, color: KPalette.orange)),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(p.desc ?? tr('Pas de résumé dans le guide TV.'), style: kText(13, color: KPalette.ink70)),
            ),
          ),
        ]),
      ),
      actions: programmeActions(context, c, channel, p),
    ),
  );
}
