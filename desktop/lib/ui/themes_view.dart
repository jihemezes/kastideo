import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/epg.dart';
import '../core/guide.dart';
import '../core/models.dart';
import '../core/themes.dart';
import '../l10n.dart';
import '../theme.dart';
import 'channel_edit_dialog.dart';
import 'widgets.dart';

/// Heure « 21:05 ».
String hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String timeRange(Programme p) => '${hm(p.start)} – ${hm(p.stop)}';

/// Ouvre une chaîne si son programme est à l'antenne, sinon affiche sa fiche (programme à venir).
void openProgramme(BuildContext context, MediaItem channel, Programme? programme) {
  if (programme == null || programme.isAiring(nowSeconds())) {
    openItem(context, channel);
  } else {
    showProgrammeInfo(context, channel, programme);
  }
}

/// Fiche d'un programme du guide.
Future<void> showProgrammeInfo(BuildContext context, MediaItem channel, Programme p) => showKDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: KPalette.panel,
        title: Row(children: [
          LogoView(url: channel.logo, name: channel.name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: kText(17, weight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('${channel.displayName} · ${timeRange(p)}', style: kText(12, color: KPalette.secondaryText)),
            ]),
          ),
        ]),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (p.category != null || p.theme != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(p.theme?.icon ?? Icons.label_outline_rounded, size: 15, color: KPalette.orange),
                  const SizedBox(width: 6),
                  Text(p.category ?? p.theme!.label, style: kText(12, weight: FontWeight.w600, color: KPalette.orange)),
                ]),
              ),
            Text(p.desc ?? tr('Pas de résumé dans le guide TV.'), style: kText(13, color: KPalette.ink70)),
          ]),
        ),
        actions: programmeActions(context, c, channel, p),
      ),
    );

/// Boutons de la fiche d'un programme : alerte et enregistrement programmé (à venir), enregistrer (en cours), regarder.
List<Widget> programmeActions(BuildContext context, BuildContext dialog, MediaItem channel, Programme p) {
  final now = nowSeconds();
  final current = p.isAiring(now);
  final future = p.startS > now;
  final recordings = context.recordings;
  final alerts = context.alerts;
  return [
    TextButton(onPressed: () => Navigator.pop(dialog), child: Text(tr('Fermer'))),
    if (future) ...[
      TextButton.icon(
        onPressed: () {
          alerts.toggle(channel, p);
          Navigator.pop(dialog);
        },
        icon: Icon(alerts.isWatching(channel, p) ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, size: 18),
        label: Text(alerts.isWatching(channel, p) ? tr('Ne plus m\'alerter') : tr('M\'alerter au début')),
      ),
      TextButton.icon(
        onPressed: recordings.isScheduled(channel, p)
            ? null
            : () {
                recordings.schedule(channel, p);
                Navigator.pop(dialog);
              },
        icon: const Icon(Icons.fiber_manual_record_rounded, size: 18, color: Colors.redAccent),
        label: Text(recordings.isScheduled(channel, p) ? tr('Programmé') : tr('Programmer l\'enregistrement')),
      ),
    ],
    if (current)
      TextButton.icon(
        onPressed: recordings.isRecording(channel)
            ? null
            : () async {
                Navigator.pop(dialog);
                await recordings.recordNow(channel, title: p.title, stopS: p.stopS + context.settings.marginAfter * 60);
              },
        icon: const Icon(Icons.fiber_manual_record_rounded, size: 18, color: Colors.redAccent),
        label: Text(recordings.isRecording(channel) ? tr('Enregistrement en cours') : tr('Enregistrer')),
      ),
    if (p.stopS > now)
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: KPalette.accent),
        onPressed: () {
          Navigator.pop(dialog);
          openItem(context, channel);
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(current ? tr('Regarder') : tr('Aller sur la chaîne')),
      ),
  ];
}

/// Choix du thème d'une chaîne (correction du classement automatique).
Future<void> chooseChannelTheme(BuildContext context, LiveChannelGroup group) async {
  final guide = context.guide;
  final library = context.library;
  const auto = '__auto__';
  final choice = await showKDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      backgroundColor: KPalette.panel,
      title: Text('${tr('Thème de la chaîne')} · ${group.preferred.displayName}', style: kText(16, weight: FontWeight.w700)),
      children: [
        for (final t in ContentTheme.browsable(showAdult: library.showAdult))
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, t.name),
            child: Row(children: [
              Icon(t.icon, size: 18, color: group.theme == t ? KPalette.accent : KPalette.ink60),
              const SizedBox(width: 10),
              Expanded(child: Text(t.label, style: kText(14, weight: group.theme == t ? FontWeight.w700 : FontWeight.w400))),
              if (group.theme == t) Icon(Icons.check_rounded, size: 18, color: KPalette.accent),
            ]),
          ),
        if (guide.themeOverrides.containsKey(group.key))
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, auto),
            child: Text('${tr('Automatique')} (${group.autoTheme.label})', style: kText(14, color: KPalette.orange)),
          ),
      ],
    ),
  );
  if (choice == null) return;
  guide.setTheme(choice == auto ? null : ContentTheme.values.byName(choice), group.key);
}

/// Menu contextuel d'une chaîne dans les thèmes (versions, thème).
Future<void> showGroupMenu(BuildContext context, LiveChannelGroup group, Programme? programme, Offset position) async {
  final library = context.library;
  final item = group.preferred;
  final airing = programme == null || programme.isAiring(nowSeconds());
  final choice = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
    color: KPalette.menu,
    items: [
      PopupMenuItem(value: 'open', child: Text(tr('Regarder'), style: kText(13))),
      if (!airing) PopupMenuItem(value: 'info', child: Text(tr('Fiche du programme'), style: kText(13))),
      if (group.variants.length > 1)
        for (final v in group.variants)
          PopupMenuItem(value: 'v:${v.id}', child: Text('${tr('Version')} : ${v.name}', style: kText(13))),
      PopupMenuItem(value: 'theme', child: Text(tr('Thème de la chaîne…'), style: kText(13))),
      PopupMenuItem(value: 'edit', child: Text(tr('Modifier la chaîne…'), style: kText(13))),
      PopupMenuItem(
          value: 'fav', child: Text(library.isFavorite(item.id) ? tr('Retirer des favoris') : tr('Ajouter aux favoris'), style: kText(13))),
    ],
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'open') openItem(context, item);
  if (choice == 'info' && programme != null) showProgrammeInfo(context, item, programme);
  if (choice == 'theme') chooseChannelTheme(context, group);
  if (choice == 'edit') showChannelEditor(context, item);
  if (choice == 'fav') library.toggleFavorite(item.id);
  if (choice.startsWith('v:')) {
    final variant = group.variants.where((v) => v.id == choice.substring(2)).firstOrNull;
    if (variant != null) openItem(context, variant);
  }
}

/// En-tête de la vue Thèmes : mode, thèmes (avec le nombre de chaînes), disciplines du sport.
class ThemesHeader extends StatelessWidget {
  const ThemesHeader({super.key, this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 10), this.compact = true});
  final EdgeInsets padding;

  /// Colonne étroite (Classique) : pastilles sur une ligne qui défile ; sinon sur plusieurs lignes.
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([context.navigation, context.guide, context.library]),
        builder: (context, _) => _content(context),
      );

  Widget _content(BuildContext context) {
    final navigation = context.navigation;
    final guide = context.guide;
    final mode = navigation.themeMode;
    final selected = navigation.themeSelection;
    final themes = ContentTheme.browsable(showAdult: context.library.showAdult);
    int count(ContentTheme t) => switch (mode) {
          ThemeView.channels => guide.channels(theme: t).length,
          ThemeView.now => guide.now(theme: t).length,
          ThemeView.tonight => guide.tonight(theme: t).length,
        };
    Widget chip(String label, IconData icon, bool on, VoidCallback onTap, {int? n}) => Padding(
          padding: const EdgeInsets.only(right: 6, bottom: 6),
          child: Hover(
            onTap: onTap,
            builder: (context, hovering) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: on ? KPalette.accent.withValues(alpha: 0.3) : KPalette.ink.withValues(alpha: hovering ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 14, color: on ? KPalette.ink : KPalette.ink70),
                const SizedBox(width: 5),
                Text(label, style: kText(12, weight: on ? FontWeight.w600 : FontWeight.w400)),
                if (n != null) ...[const SizedBox(width: 5), Text('$n', style: kText(11, color: KPalette.ink54))],
              ]),
            ),
          ),
        );
    Widget line(List<Widget> chips) => compact ? WheelRow(children: chips) : Wrap(children: chips);
    return Padding(
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeView>(
            showSelectedIcon: false,
            style: compact
                ? ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(kText(12, weight: FontWeight.w500)),
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
                  )
                : null,
            segments: [
              for (final (v, label) in [(ThemeView.now, 'En ce moment'), (ThemeView.tonight, 'Ce soir'), (ThemeView.channels, 'Chaînes')])
                ButtonSegment(value: v, label: Text(tr(label), maxLines: 1, softWrap: false, overflow: TextOverflow.fade)),
            ],
            selected: {mode},
            onSelectionChanged: (v) => navigation.setThemeMode(v.first),
          ),
        ),
        const SizedBox(height: 10),
        line([
          chip(tr('Tout'), Icons.grid_view_rounded, selected == null, () => navigation.setThemeSelection(null)),
          for (final t in themes)
            if (count(t) case final n when n > 0 || selected == t)
              chip(t.label, t.icon, selected == t, () => navigation.setThemeSelection(t), n: mode == ThemeView.tonight ? null : n),
        ]),
        if (selected == ContentTheme.sport)
          line([
            chip(tr('Tous les sports'), Icons.sports_rounded, navigation.sportKind == null, () => navigation.setSportKind(null)),
            for (final k in SportKind.values.where((k) => k != SportKind.other))
              chip(k.label, k.icon, navigation.sportKind == k, () => navigation.setSportKind(k)),
          ]),
      ]),
    );
  }
}

/// Entrées affichées par la vue Thèmes (chaîne, programme éventuel).
List<(LiveChannelGroup, Programme?)> themeEntries(BuildContext context) {
  final navigation = context.navigation;
  final guide = context.guide;
  final theme = navigation.themeSelection;
  final sport = navigation.sportKind;
  return switch (navigation.themeMode) {
    ThemeView.now => guide.now(theme: theme, sport: sport),
    ThemeView.tonight => [for (final e in guide.tonight(theme: theme, sport: sport)) (e.$1, e.$2)],
    ThemeView.channels => [for (final g in guide.channels(theme: theme, sport: sport)) (g, guide.epg.current(g.epgId))],
  };
}

String themesEmptyText(ThemeView mode) => tr(switch (mode) {
      ThemeView.now => 'Aucune chaîne de ce thème en ce moment (d\'après le guide TV et le nom des chaînes).',
      ThemeView.tonight => 'Aucun programme de ce thème ce soir (d\'après le guide TV).',
      ThemeView.channels => 'Aucune chaîne dans ce thème.',
    });

/// Colonne « Thèmes » de l'interface Classique.
class ThemesList extends StatelessWidget {
  const ThemesList({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.navigation;
    return Container(
      color: KPalette.list,
      child: ListenableBuilder(
        listenable: Listenable.merge([context.guide, navigation, context.playback, context.library]),
        builder: (context, _) {
          final entries = themeEntries(context);
          final currentId = context.playback.current?.id;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(children: [
                Expanded(
                  child: Text(navigation.themeSelection?.label ?? tr('Thèmes'),
                      style: kRounded(20, FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (context.guide.isLoading)
                  const Padding(
                      padding: EdgeInsets.only(right: 8), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                Text('${entries.length}', style: kText(12, color: KPalette.secondaryText)),
              ]),
            ),
            const ThemesHeader(),
            Divider(height: 1, color: KPalette.separator),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(themesEmptyText(navigation.themeMode),
                            textAlign: TextAlign.center, style: kText(13, color: KPalette.secondaryText)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemExtent: 62 * KPalette.density,
                      itemBuilder: (context, i) {
                        final (group, programme) = entries[i];
                        return ProgrammeRow(
                          group: group,
                          programme: programme,
                          selected: group.variants.any((v) => v.id == currentId),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

/// Ligne : logo, programme, chaîne et horaires, avancement.
class ProgrammeRow extends StatelessWidget {
  const ProgrammeRow({super.key, required this.group, required this.programme, required this.selected});
  final LiveChannelGroup group;
  final Programme? programme;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final item = group.preferred;
    final p = programme;
    final airing = p == null || p.isAiring(nowSeconds());
    final theme = GuideStore.themeOf(group, p);
    return GestureDetector(
      onSecondaryTapUp: (d) => showGroupMenu(context, group, p, d.globalPosition),
      child: Hover(
        onTap: () => openProgramme(context, item, p),
        builder: (context, hovering) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? KPalette.accent.withValues(alpha: 0.85) : (hovering ? KPalette.ink.withValues(alpha: 0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            LogoView(url: item.logo, name: item.name, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p?.title ?? item.displayName, style: kText(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [item.displayName, if (p != null) timeRange(p), ChannelQuality.of(item.name).label].join(' · '),
                  style: kText(11, color: KPalette.ink.withValues(alpha: selected ? 0.8 : 0.5)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (p != null && airing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 40),
                    child: LinearProgressIndicator(
                      value: p.progress(),
                      minHeight: 2,
                      color: selected ? KPalette.ink : KPalette.orange,
                      backgroundColor: KPalette.ink.withValues(alpha: 0.15),
                    ),
                  ),
              ]),
            ),
            Tooltip(message: theme.label, child: Icon(theme.icon, size: 16, color: KPalette.ink.withValues(alpha: selected ? 0.9 : 0.4))),
            if (!airing) ...[
              const SizedBox(width: 8),
              Text(hm(p.start), style: kText(12, weight: FontWeight.w600, color: selected ? KPalette.ink : KPalette.orange)),
            ],
          ]),
        ),
      ),
    );
  }
}
