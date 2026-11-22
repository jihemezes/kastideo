import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/epg.dart';
import '../core/log.dart';
import '../core/models.dart';
import '../core/settings.dart' show AppSettings;
import '../core/themes.dart';
import '../l10n.dart';
import '../theme.dart';
import 'guide_view.dart' show AllChannels, CategoryChannels, ChannelFilter, FavoriteChannels, RecentChannels, ThemeChannels, channelFilterTitle, channelsFor;
import 'themes_view.dart' show hm, timeRange;
import 'tv_shell.dart';
import 'widgets.dart' show LogoView;

/// Guide TV à la télécommande (comme sur Apple TV) : grille chaînes × heures, ◀ ▶ de programme en programme,
/// ▲ ▼ de chaîne en chaîne, OK regarde (ou ouvre les options d'un programme passé ou à venir), Menu = options.
class TvGuide extends StatefulWidget {
  const TvGuide({super.key});

  @override
  State<TvGuide> createState() => _TvGuideState();
}

class _TvGuideState extends State<TvGuide> with TvKeys<TvGuide> {
  static const _labelWidth = 300.0;
  static const _rowHeight = 84.0;
  static const _span = 2; // heures affichées

  late DateTime _start = _defaultStart();
  late int _t = nowSeconds();
  ChannelFilter _filter = const AllChannels();
  List<MediaItem> _rows = const [];
  int _row = 0;
  int _zone = 1; // 0 en-tête, 1 grille
  int _head = 0;
  double _viewH = 600;
  final _scroll = ScrollController();
  Listenable? _sources;
  AppSettings? _settings;
  bool _ready = false;
  Timer? _minute;

  static DateTime _defaultStart() {
    final s = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return DateTime.fromMillisecondsSinceEpoch(((s ~/ 1800) * 1800 - 1800) * 1000);
  }

  @override
  void initState() {
    super.initState();
    startTvKeys();
    _minute = Timer.periodic(const Duration(minutes: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final settings = _settings = context.settings;
    if (settings.guideStart == 'last') {
      final start = settings.guideLastStart;
      if (start != null) {
        _start = DateTime.fromMillisecondsSinceEpoch(start * 1000);
        _t = start + 1800;
      }
      final category = settings.guideLastCategory;
      if (category.isNotEmpty) _filter = CategoryChannels(category);
    }
    _sources = Listenable.merge([context.guide, context.library])..addListener(_recompute);
    _recompute(keepRow: false, initial: true);
  }

  @override
  void dispose() {
    _settings?.rememberGuide(_start.millisecondsSinceEpoch ~/ 1000, switch (_filter) { CategoryChannels(:final name) => name, _ => '' });
    _sources?.removeListener(_recompute);
    _minute?.cancel();
    _scroll.dispose();
    stopTvKeys();
    super.dispose();
  }

  /// Chaînes ayant un programme dans le guide (calculé une fois : la grille se redessine à chaque touche).
  void _recompute({bool keepRow = true, bool initial = false}) {
    if (!mounted) return;
    final guide = context.guide;
    final current = keepRow && _row < _rows.length ? _rows[_row] : context.playback.current;
    final rows = [
      for (final item in channelsFor(context, _filter, ''))
        if (guide.programmesOf(item).isNotEmpty) item,
    ];
    final index = current == null ? -1 : rows.indexWhere((i) => i.id == current.id);
    void apply() {
      _rows = rows;
      _row = index >= 0 ? index : (_row < rows.length ? _row : 0);
    }

    if (initial) {
      apply();
    } else {
      setState(apply);
    }
    _scrollToRow();
  }

  int get _startS => _start.millisecondsSinceEpoch ~/ 1000;
  int get _endS => _startS + _span * 3600;

  List<Programme> _progs(MediaItem ch) => context.guide.programmesOf(ch);

  /// Programme de la chaîne à l'instant [t] (sinon le suivant, sinon le dernier).
  Programme? _progAt(MediaItem ch, int t) {
    final list = _progs(ch);
    for (final p in list) {
      if (p.startS <= t && t < p.stopS) return p;
    }
    for (final p in list) {
      if (p.startS >= t) return p;
    }
    return list.isEmpty ? null : list.last;
  }

  Programme? get _selected => _rows.isEmpty ? null : _progAt(_rows[_row.clamp(0, _rows.length - 1)], _t);

  void _scrollToRow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = (_row * _rowHeight - (_viewH - _rowHeight) / 2).clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.jumpTo(target);
    });
  }

  void _showTime(int s) {
    // Fait défiler la fenêtre pour que l'instant [s] soit visible.
    if (s < _startS) {
      _start = DateTime.fromMillisecondsSinceEpoch(((s ~/ 1800) * 1800) * 1000);
    } else if (s >= _endS - 900) {
      _start = DateTime.fromMillisecondsSinceEpoch(((s ~/ 1800) * 1800 - 1800) * 1000);
    }
  }

  void _moveProgramme(int dir) {
    if (_rows.isEmpty) return;
    final list = _progs(_rows[_row]);
    final cur = _selected;
    final i = cur == null ? -1 : list.indexOf(cur);
    final j = i + dir;
    if (j < 0 || j >= list.length) {
      // Au bout du guide de cette chaîne : décale simplement la fenêtre.
      _t += dir * 3600;
      _showTime(_t);
      return;
    }
    _t = list[j].startS;
    _showTime(_t);
  }

  void _jumpToDay(int offset) {
    if (offset == 0) {
      _start = _defaultStart();
      _t = nowSeconds();
    } else {
      final d = DateTime.now().add(Duration(days: offset));
      _start = DateTime(d.year, d.month, d.day, 19);
      _t = _startS + 1800;
    }
    _zone = 1;
  }

  // MARK: Touches

  @override
  bool onTvKey(TvKey key) {
    setState(() {
      if (_zone == 0) {
        switch (key) {
          case TvKey.left:
            _head = (_head - 1 + 4) % 4;
          case TvKey.right:
            _head = (_head + 1) % 4;
          case TvKey.down:
            _zone = 1;
          case TvKey.up:
            break;
          case TvKey.ok:
            _headAction();
          case TvKey.menu:
            openTvLog(context);
        }
        return;
      }
      switch (key) {
        case TvKey.up:
          if (_row == 0) {
            _zone = 0;
          } else {
            _row--;
            _scrollToRow();
          }
        case TvKey.down:
          if (_row < _rows.length - 1) {
            _row++;
            _scrollToRow();
          }
        case TvKey.left:
          _moveProgramme(-1);
        case TvKey.right:
          _moveProgramme(1);
        case TvKey.ok:
          _activate();
        case TvKey.menu:
          _programmeMenu();
      }
    });
    return true;
  }

  /// Bouton « Replay » : saute à hier soir (programmes passés à revoir) ou explique pourquoi le replay n'est pas disponible.
  void _replayShortcut() {
    final library = context.library;
    final settings = library.settings;
    if (!(settings?.replayEnabled ?? true)) {
      _notice(tr('Le replay est désactivé : Réglages > Lecture > Revoir une émission.'));
      return;
    }
    final days = _replayDays;
    if (days <= 0) {
      final withArchive = library.items(MediaKind.live).where((i) => (i.archiveDays ?? 0) > 0).length;
      PlaybackLog.shared.note('Replay : $withArchive chaînes avec archive, jours gardés dans le guide ${settings?.replayGuideDays}');
      _notice(withArchive == 0 ? tr('Aucune chaîne de vos sources n\'annonce de replay (archive).') : tr('Aucun jour de replay à afficher.'));
      return;
    }
    _jumpToDay(-1);
    _notice('${tr('Replay')} : ${tr('choisissez un programme passé (icône ↺), puis OK.')}');
  }

  void _notice(String text) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text, style: kTextD(20)), duration: const Duration(seconds: 4)));
  }

  void _headAction() {
    switch (_head) {
      case 0:
        _jumpToDay(0);
      case 1:
        _pickDay();
      case 2:
        _pickFilter();
      default:
        _replayShortcut();
    }
  }

  void _activate() {
    if (_rows.isEmpty) return;
    final channel = _rows[_row];
    final p = _selected;
    if (p == null || p.isAiring(nowSeconds())) {
      openItem(context, channel);
    } else {
      _programmeMenu();
    }
  }

  // MARK: Menus

  int get _replayDays {
    final library = context.library;
    if (!(library.settings?.replayEnabled ?? true)) return 0;
    var longest = 0;
    for (final i in library.items(MediaKind.live)) {
      final d = i.archiveDays ?? 0;
      if (d > longest) longest = d;
    }
    final kept = library.settings?.replayGuideDays ?? 3;
    return longest < kept ? longest : kept;
  }

  void _pickDay() {
    final now = DateTime.now();
    String label(int i) => i == 0
        ? '${tr('Aujourd\'hui')} — ${L10n.longDate(now)}'
        : i == 1
            ? '${tr('Demain')} — ${L10n.longDate(now.add(const Duration(days: 1)))}'
            : L10n.longDate(now.add(Duration(days: i)));
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: tr('Jour'),
        entries: (_) => [
          for (var i = 0; i < 7; i++)
            TvEntry(label(i), (c) {
              Navigator.of(c).pop();
              setState(() => _jumpToDay(i));
            }),
          for (var i = 1; i <= _replayDays; i++)
            TvEntry(
              '${tr('Revoir (replay)')} · ${i == 1 ? '${tr('Hier')} — ${L10n.longDate(now.subtract(const Duration(days: 1)))}' : L10n.longDate(now.subtract(Duration(days: i)))}',
              (c) {
                Navigator.of(c).pop();
                setState(() => _jumpToDay(-i));
              },
              icon: Icons.replay_rounded,
            ),
        ],
      ),
    ));
  }

  void _pickFilter() {
    final library = context.library;
    void choose(BuildContext c, ChannelFilter f) {
      Navigator.of(c).pop();
      _filter = f;
      _row = 0;
      _recompute(keepRow: false);
    }

    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: tr('Filtre'),
        entries: (c) => [
          TvEntry(tr('Toutes les chaînes'), (c) => choose(c, const AllChannels())),
          TvEntry(tr('Favoris'), (c) => choose(c, const FavoriteChannels())),
          TvEntry(tr('Récents'), (c) => choose(c, const RecentChannels())),
          for (final t in ContentTheme.browsable(showAdult: library.showAdult)) TvEntry(t.label, (c) => choose(c, ThemeChannels(t)), icon: t.icon),
          for (final name in library.categories(MediaKind.live)) TvEntry(library.categoryName(MediaKind.live, name), (c) => choose(c, CategoryChannels(name))),
        ],
      ),
    ));
  }

  /// Options du programme sélectionné : regarder, revoir, enregistrer, alerte.
  void _programmeMenu() {
    if (_rows.isEmpty) return;
    final channel = _rows[_row];
    final p = _selected;
    if (p == null) return;
    final now = nowSeconds();
    final current = p.isAiring(now);
    final future = p.startS > now;
    final library = context.library;
    final recordings = context.recordings;
    final alerts = context.alerts;
    final desc = (p.desc ?? tr('Pas de résumé dans le guide TV.')).trim();
    final host = context;
    void after(BuildContext c, VoidCallback action) {
      Navigator.of(c).pop();
      action();
    }

    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: p.title,
        footer: '${channel.displayName} · ${timeRange(p)}${p.category == null ? '' : ' · ${p.category}'}\n${desc.length > 220 ? '${desc.substring(0, 220)}…' : desc}',
        entries: (_) => [
          if (p.stopS > now)
            TvEntry(current ? tr('Regarder') : tr('Aller sur la chaîne'), (c) => after(c, () => openItem(host, channel)), icon: Icons.play_arrow_rounded),
          if (library.canReplay(channel, p.startS, nowS: now)) ...[
            TvEntry(current ? tr('Revoir depuis le début') : tr('Revoir'), (c) => after(c, () => watchReplay(host, channel, p)), icon: Icons.replay_rounded),
            if (!current)
              TvEntry(tr('Enregistrer ce replay'), (c) {
                after(c, () {
                  final replay = library.makeReplay(channel, p);
                  if (replay != null) host.downloads.enqueue(replay);
                });
              }, icon: Icons.download_rounded),
          ],
          if (current && !recordings.isRecording(channel))
            TvEntry(tr('Enregistrer'), (c) => after(c, () => recordings.recordNow(channel, title: p.title, stopS: p.stopS + host.settings.marginAfter * 60)),
                icon: Icons.fiber_manual_record_rounded),
          if (future) ...[
            TvEntry(alerts.isWatching(channel, p) ? tr('Ne plus m\'alerter') : tr('M\'alerter au début'), (c) => after(c, () => alerts.toggle(channel, p)),
                icon: alerts.isWatching(channel, p) ? Icons.notifications_active_rounded : Icons.notifications_none_rounded),
            if (!recordings.isScheduled(channel, p))
              TvEntry(tr('Programmer l\'enregistrement'), (c) => after(c, () => recordings.schedule(channel, p)), icon: Icons.fiber_manual_record_rounded),
          ],
        ],
      ),
    ));
  }

  // MARK: Dessin

  @override
  Widget build(BuildContext context) {
    final p = _selected;
    return TvBackground(
      child: ListenableBuilder(
        listenable: Listenable.merge([context.recordings, context.alerts]),
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(40, 26, 40, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(tr('Guide TV'), style: kTextD(36, weight: FontWeight.w800)),
              const SizedBox(width: 24),
              _headButton(0, Icons.schedule_rounded, tr('Maintenant')),
              const SizedBox(width: 12),
              _headButton(1, Icons.calendar_today_rounded, L10n.longDate(_start)),
              const SizedBox(width: 12),
              _headButton(2, Icons.filter_list_rounded, channelFilterTitle(context, _filter)),
              const SizedBox(width: 12),
              _headButton(3, Icons.replay_rounded, tr('Replay')),
            ]),
            const SizedBox(height: 14),
            Expanded(child: _rows.isEmpty ? _empty(context) : _grid(context)),
            const SizedBox(height: 10),
            _detail(p),
            const SizedBox(height: 8),
            const TvHints(items: [('OK', 'Regarder'), ('◀ ▲ ▼ ▶', 'Se déplacer'), ('Menu', 'Options'), ('Retour', 'Accueil')]),
          ]),
        ),
      ),
    );
  }

  Widget _headButton(int index, IconData icon, String label) => TvFocusBox(
        selected: _zone == 0 && _head == index,
        radius: 16,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          color: Colors.white.withValues(alpha: 0.14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(width: 10),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: Text(label, style: kTextD(20, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );

  Widget _empty(BuildContext context) => Center(
        child: context.guide.isLoading
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(tr('Chargement du guide TV…'), style: kTextD(22, color: Colors.white70)),
              ])
            : Text(tr('Aucun programme'), style: kTextD(26, weight: FontWeight.w700)),
      );

  Widget _grid(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _viewH = c.maxHeight - 40;
      final gridWidth = (c.maxWidth - _labelWidth).clamp(300.0, double.infinity);
      final startS = _startS;
      final spanS = _span * 3600;
      return Column(children: [
        SizedBox(
          height: 40,
          child: Row(children: [
            const SizedBox(width: _labelWidth),
            SizedBox(
              width: gridWidth,
              child: Stack(children: [
                for (var m = 0; m <= _span * 2; m++)
                  Positioned(
                    left: gridWidth * m / (_span * 2),
                    top: 6,
                    child: Text(hm(DateTime.fromMillisecondsSinceEpoch((startS + m * 1800) * 1000)), style: kTextD(18, color: Colors.white70)),
                  ),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemCount: _rows.length,
            itemExtent: _rowHeight,
            itemBuilder: (context, i) => _row_(context, i, gridWidth, startS, spanS),
          ),
        ),
      ]);
    });
  }

  Widget _row_(BuildContext context, int i, double gridWidth, int startS, int spanS) {
    final item = _rows[i];
    final focusedRow = _zone == 1 && i == _row;
    final selected = focusedRow ? _selected : null;
    final now = nowSeconds();
    final end = startS + spanS;
    double x(int t) => ((t - startS) / spanS).clamp(0.0, 1.0) * gridWidth;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)))),
      child: Row(children: [
        Container(
          width: _labelWidth,
          height: _rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: i == _row ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          child: Row(children: [
            if (item.number != null) SizedBox(width: 46, child: Text('${item.number}', textAlign: TextAlign.right, style: kTextD(18, color: Colors.white60))),
            const SizedBox(width: 8),
            LogoView(url: item.logo, name: item.name, size: 46),
            const SizedBox(width: 10),
            Expanded(child: Text(item.displayName, style: kTextD(18, weight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (context.library.replayDays(item) > 0) const Icon(Icons.replay_rounded, size: 18, color: Colors.white54),
          ]),
        ),
        SizedBox(
          width: gridWidth,
          height: _rowHeight,
          child: ClipRect(
            child: Stack(children: [
              for (final p in _progs(item))
                if (p.stopS > startS && p.startS < end && x(p.stopS) - x(p.startS) > 6)
                  Positioned(
                    left: x(p.startS),
                    width: x(p.stopS) - x(p.startS),
                    top: 0,
                    bottom: 0,
                    child: _cell(context, item, p, identical(p, selected), now),
                  ),
              if (now >= startS && now <= end) Positioned(left: gridWidth * (now - startS) / spanS, top: 0, bottom: 0, child: Container(width: 3, color: Colors.redAccent)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _cell(BuildContext context, MediaItem item, Programme p, bool selected, int now) {
    final airing = p.isAiring(now);
    final past = p.stopS <= now;
    return Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? KPalette.orange.withValues(alpha: 0.38)
            : airing
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: past ? 0.07 : 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? KPalette.orange : Colors.transparent, width: 4),
      ),
      child: LayoutBuilder(
        builder: (context, c) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [
            if (context.recordings.isScheduled(item, p)) ...[const Icon(Icons.fiber_manual_record, size: 14, color: Colors.redAccent), const SizedBox(width: 4)],
            if (context.alerts.isWatching(item, p)) ...[const Icon(Icons.notifications_active_rounded, size: 15, color: KPalette.orange), const SizedBox(width: 4)],
            if (past && context.library.canReplay(item, p.startS, nowS: now)) ...[const Icon(Icons.replay_rounded, size: 15, color: Colors.white70), const SizedBox(width: 4)],
            Expanded(child: Text(p.title, style: kTextD(18, weight: FontWeight.w700, color: past ? Colors.white60 : Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          if (c.maxWidth > 120) Text(timeRange(p), style: kTextD(15, color: Colors.white60), maxLines: 1, overflow: TextOverflow.clip),
        ]),
      ),
    );
  }

  Widget _detail(Programme? p) {
    if (p == null || _rows.isEmpty) return const SizedBox(height: 56);
    final channel = _rows[_row.clamp(0, _rows.length - 1)];
    final desc = (p.desc ?? '').trim();
    return SizedBox(
      height: 76,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${p.title} · ${channel.displayName} · ${timeRange(p)}${p.category == null ? '' : ' · ${p.category}'}',
            style: kTextD(22, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (desc.isNotEmpty) Text(desc, style: kTextD(17, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
