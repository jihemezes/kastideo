import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import 'countries.dart';
import 'epg.dart';
import 'library.dart';
import 'log.dart';
import 'models.dart';
import 'themes.dart';

/// Guide de secours proposé (xmltvfr.fr).
class GuidePreset {
  const GuidePreset(this.label, this.url);
  final String label;
  final String url;
}

/// État du guide d'une source.
class SourceGuideStatus {
  int programmes = 0;
  String? error;
  bool loading = false;
  DateTime? lastAttempt;
}

/// État du guide de secours.
class FallbackStatus {
  DateTime? updated;
  int channelCount = 0;
  int matchedChannels = 0;
  String? error;
  bool loading = false;
}

/// Guide TV : guides des fournisseurs (XMLTV), guide de secours pour les chaînes sans programme,
/// chaînes regroupées par versions et classées par thème (équivalent de la partie guide de LibraryStore sur Mac).
class GuideStore extends ChangeNotifier {
  GuideStore(this.library);
  final LibraryStore library;

  static const defaultFallbackUrl = 'https://xmltvfr.fr/xmltv/xmltv.xml.gz';
  static const presets = [
    GuidePreset('xmltvfr.fr — Complet (~785 chaînes)', 'https://xmltvfr.fr/xmltv/xmltv.xml.gz'),
    GuidePreset('xmltvfr.fr — France (~400 chaînes)', 'https://xmltvfr.fr/xmltv/xmltv_fr.xml.gz'),
    GuidePreset('xmltvfr.fr — TNT France', 'https://xmltvfr.fr/xmltv/xmltv_tnt.xml.gz'),
  ];

  late SharedPreferences _prefs;
  late Directory _dir;
  bool _started = false;

  final Map<String, List<Programme>> _bySource = {};
  final Map<String, List<XmltvChannel>> _channelsBySource = {};

  /// Chaînes des guides (fournisseurs puis secours), pour relier une chaîne à la main.
  List<XmltvChannel> get guideChannels {
    final seen = <String>{};
    return [
      for (final list in [..._channelsBySource.values, _fallbackChannels])
        for (final c in list)
          if (seen.add(c.id.toLowerCase())) c,
    ];
  }
  final Map<String, SourceGuideStatus> status = {};
  List<Programme> _fallback = [];
  List<XmltvChannel> _fallbackChannels = [];
  final fallbackStatus = FallbackStatus();

  EPGIndex epg = EPGIndex();
  List<LiveChannelGroup> groups = [];
  Map<String, LiveChannelGroup> _groupByItem = {};
  Map<String, ContentTheme> themeOverrides = {};
  int _liveGeneration = -1;
  int _generation = 0;
  Timer? _ticker;

  bool get fallbackEnabled => _prefs.getBool('epg.fallback.enabled') ?? true;
  String get fallbackUrlText {
    final text = _prefs.getString('epg.fallback.url') ?? '';
    return text.isEmpty ? defaultFallbackUrl : text;
  }

  bool get isLoading => fallbackStatus.loading || status.values.any((s) => s.loading);

  Future<void> start() async {
    _prefs = await SharedPreferences.getInstance();
    final support = await getApplicationSupportDirectory();
    _dir = Directory('${support.path}${Platform.pathSeparator}guide');
    await _dir.create(recursive: true);
    final raw = _prefs.getString('themes.overrides.v1');
    if (raw != null) {
      try {
        (jsonDecode(raw) as Map).forEach((k, v) {
          final t = ContentTheme.values.where((x) => x.name == v).firstOrNull;
          if (t != null) themeOverrides[k as String] = t;
        });
      } catch (_) {}
    }
    final updated = _prefs.getInt('epg.fallback.date');
    if (updated != null) fallbackStatus.updated = DateTime.fromMillisecondsSinceEpoch(updated * 1000);
    // Guides déjà téléchargés : affichage immédiat.
    for (final source in library.sources) {
      final list = await _readCache('epg-${source.id}');
      if (list != null) {
        _bySource[source.id] = list.$1;
        _channelsBySource[source.id] = list.$2;
        (status[source.id] ??= SourceGuideStatus()).programmes = list.$1.length;
      }
    }
    final fb = await _readCache('fallback');
    if (fb != null) {
      _fallback = fb.$1;
      _fallbackChannels = fb.$2;
      fallbackStatus.channelCount = _fallbackChannels.length;
    }
    _started = true;
    library.onSourceRefreshed = (source) => refreshSource(source, force: true);
    library.addListener(_libraryChanged);
    await _rebuild();
    unawaited(_refreshStale());
    _ticker = Timer.periodic(const Duration(hours: 1), (_) => _refreshStale());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    library.removeListener(_libraryChanged);
    super.dispose();
  }

  void _libraryChanged() {
    if (!_started || library.liveGeneration == _liveGeneration) return;
    _rebuild();
  }

  Future<void> _refreshStale() async {
    for (final source in List.of(library.sources.where((s) => s.enabled && s.kind.isIptv))) {
      final s = status[source.id];
      if (s?.lastAttempt != null && DateTime.now().difference(s!.lastAttempt!) < const Duration(hours: 3)) continue;
      if (_needsRefresh(source.id)) {
        PlaybackLog.shared.note('Guide « ${source.name} » : à recharger (absent ou presque terminé)', topic: LogTopic.guide);
        await refreshSource(source);
      } else {
        PlaybackLog.shared.note('Guide « ${source.name} » : conservé tel quel (${_bySource[source.id]?.length ?? 0} programmes)',
            topic: LogTopic.guide, detail: LogDetail.detailed);
      }
    }
    await refreshFallback();
  }

  bool _needsRefresh(String id) {
    final list = _bySource[id];
    if (list == null || list.isEmpty) return true;
    final latest = list.fold<int>(0, (m, p) => p.stopS > m ? p.stopS : m);
    return latest < nowSeconds() + 12 * 3600;
  }

  // MARK: Téléchargements

  Future<void> refreshSource(Source source, {bool force = false, bool manual = false}) async {
    if (!_started || !source.enabled) return;
    final log = PlaybackLog.shared;
    final url = await library.guideUrlFor(source);
    if (url == null || url.isEmpty) {
      if (manual) {
        log.warn('Guide « ${source.name} » : aucune adresse de guide connue pour cette source (rien à télécharger)', topic: LogTopic.guide);
        (status[source.id] ??= SourceGuideStatus()).error = tr('Aucune adresse de guide connue pour cette source.');
        notifyListeners();
      }
      return;
    }
    final s = status[source.id] ??= SourceGuideStatus();
    if (s.loading) return;
    if (!force && !_needsRefresh(source.id)) return;
    s
      ..loading = true
      ..lastAttempt = DateTime.now();
    notifyListeners();
    // Seules les chaînes de la source sont gardées (les guides des fournisseurs couvrent souvent des milliers de chaînes étrangères).
    final wanted = <String>{
      for (final item in library.allLiveItems(source.id))
        if (item.epgId != null && item.epgId!.isNotEmpty) item.epgId!.toLowerCase().trim(),
    };
    log.note('Guide « ${source.name} » : demande${manual ? ' manuelle' : ''} à ${Uri.tryParse(url)?.host ?? '?'} — $url', topic: LogTopic.guide);
    log.note('Guide « ${source.name} » : ${wanted.length} identifiant(s) de chaîne demandé(s), exemples : ${wanted.take(6).join(', ')}',
        topic: LogTopic.guide, detail: LogDetail.detailed);
    try {
      final filter = wanted.isEmpty ? null : wanted;
      final retention = library.replayRetention(source.id);
      final guide = await Isolate.run(() => downloadGuide(url, channels: filter,
          retainChannels: retention?.$1, retainFromS: retention?.$2));
      final m = guide.meta;
      final size = _size(guide.byteCount);
      var answer = 'Guide « ${source.name} » : réponse ${m.status == null ? 'sans code HTTP' : 'HTTP ${m.status}'}'
          '${m.finalHost != null && m.finalHost != Uri.tryParse(url)?.host ? ' via ${m.finalHost}' : ''}'
          ' en ${m.seconds.toStringAsFixed(1)} s, $size';
      if (m.gzip) answer += ' (compressé)';
      if (m.contentType != null) answer += ', type « ${m.contentType} »';
      log.note(answer, topic: LogTopic.guide, detail: LogDetail.detailed);
      if (m.status != null && (m.status! < 200 || m.status! >= 300)) {
        s.error = '${tr('Le fournisseur a refusé la demande du guide')} (HTTP ${m.status}).';
        log.error('Guide « ${source.name} » : refusé par le fournisseur (HTTP ${m.status})'
            '${m.excerpt == null ? '' : ' — réponse : « ${m.excerpt} »'}', topic: LogTopic.guide);
      } else if (!guide.isValid || guide.programmes.isEmpty) {
        s.error = guide.isValid
            ? '${tr('Le fournisseur a envoyé un guide sans programme pour les prochains jours')} ($size).'
            : '${tr('Le fournisseur a envoyé un guide vide ou illisible')} ($size).';
        final b = StringBuffer('Guide « ${source.name} » : inutilisable ($size, document XMLTV valide : ${guide.isValid ? 'oui' : 'non'}, '
            'chaînes déclarées : ${guide.channels.length}, programmes dans le document : ${m.seen}, '
            'dans les prochaines 48 h : ${m.inWindow}, gardés pour vos chaînes : ${m.kept})');
        if (m.excerpt != null) b.write(' — début de la réponse : « ${m.excerpt} »');
        log.error(b.toString(), topic: LogTopic.guide);
        if (m.inWindow > 0 && m.kept == 0) {
          // Cas typique : le guide existe, mais ses identifiants ne ressemblent pas à ceux des chaînes.
          log.error('Guide « ${source.name} » : le guide contient des programmes, mais aucun pour vos chaînes. '
              'Identifiants du guide (exemples) : ${m.droppedSamples.take(6).join(', ')} — vos identifiants (exemples) : ${wanted.take(6).join(', ')}',
              topic: LogTopic.guide);
        }
      } else {
        _bySource[source.id] = guide.programmes;
        _channelsBySource[source.id] = guide.channels;
        s
          ..programmes = guide.programmes.length
          ..error = null;
        String stamp(int? v) {
          if (v == null) return '?';
          final t = DateTime.fromMillisecondsSinceEpoch(v * 1000);
          String two(int n) => n.toString().padLeft(2, '0');
          return '${two(t.day)}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
        }
        log.note('Guide « ${source.name} » : ${guide.programmes.length} programmes pour ${m.distinctChannels} chaîne(s) du guide '
            '(${guide.channels.length} déclarée(s)), gardés : ${m.kept} sur ${m.inWindow} dans les prochaines 48 h, '
            'du ${stamp(m.firstStart)} au ${stamp(m.lastStop)}', topic: LogTopic.guide);
        log.note('Guide « ${source.name} » : exemples d\'identifiants gardés : ${m.keptSamples.join(', ')}'
            '${m.droppedSamples.isEmpty ? '' : ' — écartés : ${m.droppedSamples.take(6).join(', ')}'}',
            topic: LogTopic.guide, detail: LogDetail.detailed);
        await _writeCache('epg-${source.id}', guide.programmes, guide.channels);
      }
    } catch (e) {
      s.error = '$e';
      log.error('Guide « ${source.name} » : échec du téléchargement ($e)', topic: LogTopic.guide);
    } finally {
      s.loading = false;
      await _rebuild();
    }
  }

  Future<void> refreshAll() async {
    for (final source in List.of(library.sources.where((s) => s.enabled))) {
      await refreshSource(source, force: true, manual: true);
    }
    await refreshFallback(force: true);
  }

  /// Télécharge le guide de secours s'il est activé et date de plus de 12 h (ou sur demande).
  Future<void> refreshFallback({bool force = false}) async {
    if (!_started || !fallbackEnabled || fallbackStatus.loading) return;
    final url = fallbackUrlText;
    if (!url.startsWith('http')) return;
    final updated = fallbackStatus.updated;
    if (!force && updated != null && DateTime.now().difference(updated) < const Duration(hours: 12) && _fallback.isNotEmpty) return;
    fallbackStatus
      ..loading = true
      ..error = null;
    notifyListeners();
    final log = PlaybackLog.shared;
    log.note('Guide de secours : demande${force ? ' manuelle' : ''} à ${Uri.tryParse(url)?.host ?? '?'} — $url', topic: LogTopic.guide);
    try {
      final guide = await Isolate.run(() => downloadGuide(url, timeout: const Duration(seconds: 300)));
      final m = guide.meta;
      log.note('Guide de secours : réponse ${m.status == null ? 'sans code HTTP' : 'HTTP ${m.status}'} en ${m.seconds.toStringAsFixed(1)} s, ${_size(guide.byteCount)}',
          topic: LogTopic.guide, detail: LogDetail.detailed);
      if (!guide.isValid || guide.programmes.isEmpty) {
        fallbackStatus.error = tr('Guide de secours vide ou illisible.');
        log.error('Guide de secours : inutilisable (${_size(guide.byteCount)}, HTTP ${m.status ?? '?'})'
            '${m.excerpt == null ? '' : ' — début de la réponse : « ${m.excerpt} »'}', topic: LogTopic.guide);
      } else {
        _fallback = guide.programmes;
        _fallbackChannels = guide.channels;
        final now = DateTime.now();
        fallbackStatus
          ..updated = now
          ..channelCount = guide.channels.length;
        _prefs.setInt('epg.fallback.date', now.millisecondsSinceEpoch ~/ 1000);
        log.note('Guide de secours : ${guide.channels.length} chaînes, ${guide.programmes.length} programmes (${_size(guide.byteCount)})', topic: LogTopic.guide);
        await _writeCache('fallback', guide.programmes, guide.channels);
      }
    } catch (e) {
      fallbackStatus.error = '$e';
      log.error('Guide de secours : échec du téléchargement ($e)', topic: LogTopic.guide);
    } finally {
      fallbackStatus.loading = false;
      await _rebuild();
    }
  }

  void setFallbackEnabled(bool value) {
    _prefs.setBool('epg.fallback.enabled', value);
    if (value) {
      refreshFallback();
    } else {
      _rebuild();
    }
    notifyListeners();
  }

  void setFallbackUrl(String value) {
    final text = value.trim();
    final changed = text != fallbackUrlText;
    _prefs.setString('epg.fallback.url', text);
    if (changed) {
      _fallback = [];
      _fallbackChannels = [];
      fallbackStatus
        ..updated = null
        ..channelCount = 0
        ..matchedChannels = 0;
    }
    refreshFallback(force: true);
  }

  // MARK: Index et thèmes

  Future<void> _rebuild() async {
    if (!_started) return;
    _liveGeneration = library.liveGeneration;
    final generation = ++_generation;
    final provider = <Programme>[
      for (final source in library.sources.where((s) => s.enabled)) ...?_bySource[source.id],
    ];
    final allLive = library.items(MediaKind.live);
    final live = [for (final i in allLive) if (!ChannelMatcher.isSeparator(i.name)) i];
    final separators = allLive.length - live.length;
    final fallback = fallbackEnabled ? _fallback : const <Programme>[];
    final channels = _fallbackChannels;
    final overrides = Map.of(themeOverrides);
    final result = await Isolate.run(() {
      final index = EPGIndex(provider);
      var matched = 0;
      var fromProvider = 0;
      var none = 0;
      var auto = 0;
      final samples = <String>[];
      final matcher = fallback.isNotEmpty && channels.isNotEmpty ? ChannelMatcher(channels) : null;
      final byChannel = <String, List<Programme>>{};
      if (matcher != null) {
        for (final p in fallback) {
          (byChannel[p.channel] ??= []).add(p);
        }
      }
      final extra = <Programme>[];
      final outcome = <String, int>{}; // 0 : fournisseur, 1 : secours, 2 : rien
      for (final item in live) {
        final key = guideKey(item);
        final lower = key.toLowerCase();
        if (key.startsWith('auto:')) auto++;
        var code = outcome[lower];
        if (code == null) {
          if (index.hasProgrammes(key)) {
            code = 0;
          } else {
            final id = matcher?.match(item.name, key.startsWith('auto:') ? null : key);
            final list = id == null ? null : byChannel[id];
            if (list != null && list.isNotEmpty) {
              matched++;
              extra.addAll(list.map((p) => p.withChannel(key)));
              code = 1;
            } else {
              code = 2;
              if (samples.length < 6) samples.add('${item.name} [$key]');
            }
          }
          outcome[lower] = code;
        }
        if (code == 0) fromProvider++;
        if (code == 2) none++;
      }
      if (extra.isNotEmpty) index.merge(extra);
      final built = LiveChannelGroup.build(live, index, overrides);
      // Couverture finale : une version (4K, FHD…) sans programme propre reprend celui d'une autre version de la chaîne.
      final guideOf = <String, String?>{for (final g in built) for (final v in g.variants) v.id: g.epgId};
      var french = 0;
      var frenchNone = 0;
      var inherited = 0;
      var withGuide = 0;
      final frenchSamples = <String>[];
      for (final item in live) {
        final own = index.hasProgrammes(guideKey(item));
        final viaGroup = !own && index.hasProgrammes(guideOf[item.id]);
        if (own || viaGroup) withGuide++;
        if (viaGroup) inherited++;
        final isFrench = Countries.of(item.group) == 'FR' || Countries.of(item.name) == 'FR';
        if (isFrench) french++;
        if (isFrench && !own && !viaGroup) {
          frenchNone++;
          if (frenchSamples.length < 8) frenchSamples.add('${item.name} [${guideKey(item)}]');
        }
      }
      return (index, matched, built, (live.length, fromProvider, none, auto, samples), (french, frenchNone, inherited, withGuide, frenchSamples));
    });
    if (generation != _generation) return;
    epg = result.$1;
    fallbackStatus.matchedChannels = result.$2;
    groups = result.$3;
    final (total, fromProvider, _, auto, _) = result.$4;
    final (french, frenchNone, inherited, withGuide, frenchSamples) = result.$5;
    final cover = StringBuffer('Guide : $total chaîne(s) en direct — $fromProvider avec le guide du fournisseur, ${result.$2} complétée(s) par le secours, '
        '$inherited reprenant le programme d\'une autre version (4K, FHD…), ${total - withGuide} sans programme');
    if (auto > 0) cover.write(' (dont $auto sans identifiant de guide, rapprochées par leur nom)');
    if (separators > 0) cover.write(' ; $separators séparateur(s) de catégorie ignoré(s)');
    if (isLoading) cover.write(' — guide en cours de chargement');
    final summary = cover.toString();
    if (summary != _lastCoverage) {
      _lastCoverage = summary;
      PlaybackLog.shared.note(summary, topic: LogTopic.guide);
      PlaybackLog.shared.note('Guide : chaînes françaises — ${french - frenchNone} avec programme sur $french ($frenchNone sans programme)',
          topic: LogTopic.guide);
      if (frenchSamples.isNotEmpty) {
        PlaybackLog.shared.note('Guide : exemples de chaînes françaises sans programme : ${frenchSamples.join(' · ')}',
            topic: LogTopic.guide, detail: LogDetail.detailed);
      }
    }
    _groupByItem = {for (final g in groups) for (final v in g.variants) v.id: g};
    _airingCache = null;
    _tonightCache = null;
    notifyListeners();
  }

  String _lastCoverage = '';

  LiveChannelGroup? groupOf(MediaItem item) => _groupByItem[item.id];

  Programme? current(MediaItem item) => epg.current(guideKey(item)) ?? _groupCurrent(item);

  Programme? _groupCurrent(MediaItem item) {
    final g = _groupByItem[item.id];
    return g == null ? null : epg.current(g.epgId);
  }

  /// Programmes d'une chaîne (ceux de sa clé de guide, sinon ceux d'une autre version de la chaîne).
  List<Programme> programmesOf(MediaItem item) {
    final own = epg.programmes(guideKey(item));
    if (own.isNotEmpty) return own;
    final g = _groupByItem[item.id];
    return g == null ? const [] : epg.programmes(g.epgId);
  }

  /// Programmes que l'on peut revoir (le plus récent d'abord), y compris celui en cours.
  List<Programme> replayProgrammes(MediaItem channel, {int limit = 14}) {
    if (library.replayDays(channel) == 0) return const [];
    final now = nowSeconds();
    return [
      for (final p in programmesOf(channel).reversed)
        if (library.canReplay(channel, p.startS, nowS: now)) p,
    ].take(limit).toList();
  }

  Programme? next(MediaItem item) {
    final key = epg.hasProgrammes(guideKey(item)) ? guideKey(item) : _groupByItem[item.id]?.epgId;
    final list = epg.upcoming(key, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  void setTheme(ContentTheme? theme, String channelKey) {
    if (theme == null) {
      themeOverrides.remove(channelKey);
    } else {
      themeOverrides[channelKey] = theme;
    }
    _prefs.setString('themes.overrides.v1', jsonEncode({for (final e in themeOverrides.entries) e.key: e.value.name}));
    _rebuild();
  }

  ({int minute, List<(LiveChannelGroup, Programme?)> list})? _airingCache;

  /// Chaînes à l'antenne maintenant, avec leur programme (ou sans, si le nom de la chaîne suffit à la classer).
  List<(LiveChannelGroup, Programme?)> airingNow() {
    final now = nowSeconds();
    final minute = now ~/ 60;
    final cached = _airingCache;
    if (cached != null && cached.minute == minute) return cached.list;
    final list = <(LiveChannelGroup, Programme?)>[
      for (final g in groups)
        if (epg.current(g.epgId, now) case final p?) (g, p) else if (g.themeFromName && g.theme != ContentTheme.other) (g, null),
    ];
    _airingCache = (minute: minute, list: list);
    return list;
  }

  /// Thème effectif d'une chaîne à l'antenne.
  static ContentTheme themeOf(LiveChannelGroup g, Programme? p) => p?.theme ?? g.theme;

  bool _matchesSport(SportKind? sport, LiveChannelGroup g, Programme? p) {
    if (sport == null) return true;
    if (p != null) {
      final k = SportKind.ofProgramme(p);
      if (k != null) return k == sport;
    }
    return SportKind.detect([g.preferred.name]) == sport;
  }

  /// « En ce moment », filtré par thème (et discipline pour le sport).
  List<(LiveChannelGroup, Programme?)> now({ContentTheme? theme, SportKind? sport, bool withProgrammeOnly = false}) => [
        for (final e in airingNow())
          if ((!withProgrammeOnly || e.$2 != null) &&
              (theme == null || themeOf(e.$1, e.$2) == theme) &&
              (theme != ContentTheme.sport || _matchesSport(sport, e.$1, e.$2)))
            e,
      ];

  ({int minute, List<(LiveChannelGroup, Programme)> list})? _tonightCache;

  /// « Ce soir » : programmes de 20 h à 23 h, par heure de début.
  List<(LiveChannelGroup, Programme)> tonight({ContentTheme? theme, SportKind? sport}) {
    final now = nowSeconds();
    var cached = _tonightCache;
    if (cached == null || cached.minute != now ~/ 60) {
      final window = tonightWindow();
      final all = <(LiveChannelGroup, Programme)>[];
      for (final g in groups) {
        for (final p in epg.programmes(g.epgId)) {
          if (p.startS >= window.end) break;
          if (p.startS < window.start || p.stopS <= now) continue;
          all.add((g, p));
        }
      }
      all.sort((a, b) => a.$2.startS.compareTo(b.$2.startS));
      cached = (minute: now ~/ 60, list: all);
      _tonightCache = cached;
    }
    if (theme == null) return cached.list;
    return [
      for (final e in cached.list)
        if (themeOf(e.$1, e.$2) == theme && (theme != ContentTheme.sport || _matchesSport(sport, e.$1, e.$2))) e,
    ];
  }

  /// Chaînes d'un thème (toutes, à l'antenne ou non).
  List<LiveChannelGroup> channels({ContentTheme? theme, SportKind? sport}) => [
        for (final g in groups)
          if ((theme == null || g.theme == theme) && (theme != ContentTheme.sport || _matchesSport(sport, g, null))) g,
      ];

  // MARK: Cache sur disque

  File _file(String name) => File('${_dir.path}${Platform.pathSeparator}$name.json');

  Future<(List<Programme>, List<XmltvChannel>)?> _readCache(String name) async {
    final file = _file(name);
    if (!await file.exists()) return null;
    final path = file.path;
    try {
      return await Isolate.run(() {
        final root = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        final limit = nowSeconds() - 6 * 3600;
        return (
          [
            for (final e in root['p'] as List)
              if ((e as List)[2] as int > limit) Programme.fromJson(e),
          ],
          [for (final e in root['c'] as List? ?? const []) XmltvChannel.fromJson(e as List)],
        );
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String name, List<Programme> programmes, List<XmltvChannel> channels) async {
    final path = _file(name).path;
    try {
      await Isolate.run(() => File(path).writeAsStringSync(jsonEncode({
            'p': [for (final p in programmes) p.toJson()],
            'c': [for (final c in channels) c.toJson()],
          })));
    } catch (e) {
      PlaybackLog.shared.note('Guide TV : enregistrement impossible ($e)');
    }
  }

  Future<void> forgetSource(String id) async {
    _bySource.remove(id);
    status.remove(id);
    final file = _file('epg-$id');
    if (await file.exists()) await file.delete();
    await _rebuild();
  }

  static String _size(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} Mo';
    if (bytes >= 1024) return '${(bytes / 1024).round()} Ko';
    return '$bytes o';
  }
}
