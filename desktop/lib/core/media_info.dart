import 'dart:async';

import 'package:flutter/foundation.dart';

import '../l10n.dart';
import 'details.dart';
import 'gallery.dart';
import 'library.dart';
import 'log.dart';
import 'models.dart';
import 'settings.dart';
import 'text.dart';

/// Fiches des films et séries (fournisseur IPTV, complétées par TMDB si une clé est saisie) et saisons des séries.
class MediaInfoStore extends ChangeNotifier {
  MediaInfoStore(this.library, this.settings);
  final LibraryStore library;
  final AppSettings settings;

  final Map<String, MediaDetails> _cache = {};
  final Map<String, List<SeriesSeason>> _seasons = {};
  final Set<String> _loading = {};
  final Map<String, String> errors = {};

  MediaDetails? details(String id) => _cache[id];
  List<SeriesSeason>? seasons(String id) => _seasons[id];
  bool isLoading(String id) => _loading.contains(id);

  String get _language => L10n.english ? 'en-US' : 'fr-FR';

  /// Charge la fiche (une seule fois par session) ; pour une série Xtream, aussi les saisons.
  Future<void> load(MediaItem item, {bool force = false}) async {
    if (!force && (_cache.containsKey(item.id) || _loading.contains(item.id))) return;
    await _loadFixes();
    _loading.add(item.id);
    notifyListeners();
    final series = item.kind == MediaKind.series;
    var d = MediaDetails()
      ..title = item.name
      ..plot = item.info
      ..poster = item.logo;
    final source = library.sourceOf(item);
    final local = source?.kind.isLocalFiles ?? false;
    final server = source?.kind.isMediaServer ?? false;
    // Dossiers locaux et serveurs : épisodes de la série ; fiche du serveur (résumé, distribution, image de fond).
    if (local || server) {
      try {
        if (series) {
          final seasons = await library.seasonsFor(item);
          if (seasons != null) _seasons[item.id] = seasons;
        }
        if (server) {
          final fromServer = await library.serverDetails(item);
          if (fromServer != null) d = fromServer..title ??= item.name;
          d.poster ??= item.logo;
          d.plot ??= item.info;
        } else {
          d.year = cleanTitle(item.name).year;
          d.sources = [tr('Fichier local')];
        }
      } catch (e) {
        PlaybackLog.shared.note('Fiche de « ${item.name} » indisponible : $e');
      }
    }
    try {
      final client = local || server ? null : await library.xtreamClient(item.sourceId);
      if (client != null) {
        if (series && item.seriesId != null) {
          final (info, seasons) = await client.seriesInfo(item);
          _seasons[item.id] = seasons;
          d = info..title ??= item.name;
          d.plot ??= item.info;
          d.poster ??= item.logo;
        } else if (item.kind == MediaKind.movie) {
          final id = item.id.split(':').last;
          final info = await client.movieDetails(id);
          d = info..title ??= item.name;
          d.poster ??= item.logo;
        }
      }
    } catch (e) {
      PlaybackLog.shared.note('Fiche IPTV indisponible pour « ${item.name} » : $e');
    }
    // Vidéos personnelles (dossiers locaux) : recherche TMDB seulement si le titre correspond exactement.
    final personal = local && item.group.startsWith('${tr('Vidéos')} · ');
    if (settings.usesTMDB && item.kind != MediaKind.episode && (!personal || settings.tmdbPersonal || edits[item.id]?.tmdbId != null)) {
      try {
        final client = TMDBClient(settings.tmdbKey, _language);
        var fixed = _nonEmpty(edits[item.id]?.tmdbId) ?? d.tmdbId;
        if (personal && fixed == null) {
          fixed = (await _exactMatch(client, item.name))?.tmdbId;
          if (fixed == null) PlaybackLog.shared.note('TMDB : aucun titre exact pour la vidéo « ${item.name} »');
        }
        final tmdb = personal && fixed == null
            ? null
            : await client.details(item.name, series: series, tmdbId: fixed, year: d.year, originalTitle: d.originalTitle);
        if (tmdb != null) d = d.merged(tmdb)..title ??= item.name;
        // Épisodes : titres et résumés de TMDB dans la langue de l'interface (ceux du fournisseur sont parfois en espagnol…).
        final seasons = _seasons[item.id];
        if (series && tmdb?.tmdbId != null && seasons != null && seasons.isNotEmpty) {
          _seasons[item.id] = await _localizedSeasons(client, tmdb!.tmdbId!, seasons);
        }
        errors.remove(item.id);
      } catch (e) {
        errors[item.id] = tr('TMDB n\'a pas répondu (vérifiez la clé dans Réglages > Général).');
        PlaybackLog.shared.note('TMDB : échec pour « ${item.name} » : $e');
      }
    }
    // Textes et affiche saisis à la main : ils passent avant tout le reste.
    if (edits[item.id] case final edit?) {
      if (_nonEmpty(edit.title?.trim()) case final t?) d.title = t;
      if (edit.year != null) d.year = edit.year;
      if (edit.posterUrl case final p?) d.poster = p;
      if (_nonEmpty(edit.plot?.trim()) case final t?) d.plot = t;
    }
    if (d.sources.isEmpty) d.sources = ['IPTV'];
    _cache[item.id] = d;
    _loading.remove(item.id);
    notifyListeners();
  }

  Future<List<SeriesSeason>> _localizedSeasons(TMDBClient client, String tvId, List<SeriesSeason> seasons) async {
    final result = <SeriesSeason>[];
    for (final season in seasons.take(40)) {
      Map<int, TMDBEpisode> tmdb = const {};
      try {
        tmdb = await client.season(tvId, season.number);
      } catch (_) {}
      result.add(SeriesSeason(season.number, [
        for (final e in season.episodes)
          if (tmdb[e.number] case final t?)
            MediaItem(
              id: e.id,
              sourceId: e.sourceId,
              kind: e.kind,
              name: (t.name != null && !_generic(t.name!)) ? t.name! : e.name,
              group: e.group,
              logo: e.logo ?? t.still,
              stream: e.stream,
              seriesId: e.seriesId,
              number: e.number,
              info: t.overview ?? e.info,
              added: e.added,
            )
          else
            e,
      ]));
    }
    return result;
  }

  // MARK: Fichiers locaux

  static String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

  /// Corrections à la main (identifiant du contenu → correction), gardées dans les préférences.
  Map<String, FicheEdit> edits = {};
  bool _fixesLoaded = false;
  bool _enriching = false;

  Future<void> _loadFixes() async {
    if (_fixesLoaded) return;
    _fixesLoaded = true;
    edits = await FicheEdits.load();
  }

  /// Charge les corrections (réglages) ou les relit après une importation de configuration.
  Future<void> reloadEdits() async {
    _fixesLoaded = true;
    edits = await FicheEdits.load();
    notifyListeners();
  }

  /// Vérifie un code ou une adresse TMDB pour ce contenu : fiche trouvée, ou raison du refus.
  Future<({MediaDetails? details, String? problem})> lookup(String reference, MediaItem item) async {
    if (!settings.usesTMDB) return (details: null, problem: tr('Ajoutez une clé TMDB (Réglages > Général) pour vérifier un code.'));
    final ref = parseTmdbReference(reference);
    if (ref == null) {
      return (details: null, problem: tr('Saisissez le numéro TMDB (par exemple 12345) ou collez l\'adresse de la page themoviedb.org.'));
    }
    final series = item.kind == MediaKind.series;
    if (ref.series != null && ref.series != series) {
      return (
        details: null,
        problem: series ? tr('Cette adresse est celle d\'un film, pas d\'une série.') : tr('Cette adresse est celle d\'une série, pas d\'un film.')
      );
    }
    try {
      final found = await TMDBClient(settings.tmdbKey, _language).details(item.name, series: series, tmdbId: ref.id);
      if (found == null) return (details: null, problem: tr('Aucune fiche TMDB avec ce code.'));
      found.tmdbId = ref.id;
      return (details: found, problem: null);
    } catch (_) {
      return (details: null, problem: tr('Aucune fiche TMDB avec ce code (ou TMDB n\'a pas répondu).'));
    }
  }

  /// Enregistre (ou, avec null, retire) la correction d'un contenu, met à jour l'affiche et le résumé, puis recharge la fiche.
  Future<void> setEdit(MediaItem item, FicheEdit? edit) async {
    await _loadFixes();
    final value = (edit == null || edit.isEmpty) ? null : edit;
    if (value == null) {
      edits.remove(item.id);
    } else {
      edits[item.id] = value;
    }
    await FicheEdits.save(edits);
    final source = library.sourceOf(item);
    final local = source?.kind.isLocalFiles ?? false;
    if (local) {
      if (value != null) {
        var logo = value.posterUrl;
        var info = _nonEmpty(value.plot?.trim());
        var year = value.year;
        var genres = <String>[];
        double? rating;
        int? runtime;
        String? country;
        String? language;
        if (_nonEmpty(value.tmdbId) != null && settings.usesTMDB) {
          try {
            final found = await TMDBClient(settings.tmdbKey, _language)
                .details(item.name, series: item.kind == MediaKind.series, tmdbId: value.tmdbId);
            if (found != null) {
              logo ??= found.poster;
              info ??= found.plot;
              year ??= found.year;
              genres = found.genres;
              rating = found.rating;
              runtime = found.runtime;
              country = found.country;
              language = found.language;
            }
          } catch (_) {}
        }
        await library.applyEnrichment(item.sourceId, {item.id: (logo: logo, info: info, year: year, genres: genres, rating: rating, runtime: runtime, country: country, language: language)});
      } else {
        await library.clearEnrichment(item.sourceId, {item.id});
      }
    }
    _cache.remove(item.id);
    notifyListeners();
    await load(library.item(item.id) ?? item, force: true);
    if (value == null && local && source != null) unawaited(enrichLocal(source));
  }

  /// « Corriger la fiche… » : l'élément est associé au résultat TMDB choisi (affiche, résumé, fiche).
  Future<void> applyFix(MediaItem item, TMDBMatch match) async {
    await _loadFixes();
    final edit = edits[item.id]?.copy() ?? FicheEdit();
    edit.tmdbId = match.tmdbId;
    await setEdit(item, edit);
  }

  Future<List<TMDBMatch>> searchTMDB(String title, {required bool series, int? year}) =>
      TMDBClient(settings.tmdbKey, _language).search(title, series: series, year: year);

  /// Affiches et résumés TMDB des films et séries d'un dossier local qui n'en ont pas encore (par petits lots).
  Future<void> enrichLocal(Source source) async {
    if (!source.kind.isLocalFiles || !settings.usesTMDB || _enriching) return;
    _enriching = true;
    await _loadFixes();
    try {
      final client = TMDBClient(settings.tmdbKey, _language);
      final todo = library
          .contentOf(source.id)
          .where((i) => (i.kind == MediaKind.movie || i.kind == MediaKind.series) && i.epgId != Gallery.genericMarker && (i.logo == null || i.rating == null) && (settings.tmdbPersonal || !i.group.startsWith('${tr('Vidéos')} · ')))
          .take(300)
          .toList();
      if (todo.isEmpty) return;
      PlaybackLog.shared.note('Fiches TMDB des fichiers locaux : ${todo.length} à chercher');
      final found = <String, LocalFiche>{};
      for (var i = 0; i < todo.length; i += 4) {
        await Future.wait([
          for (final item in todo.skip(i).take(4))
            () async {
              try {
                final personal = item.group.startsWith('${tr('Vidéos')} · ');
                final TMDBMatch? m;
                if (personal) {
                  m = await _exactMatch(client, item.name);
                } else {
                  m = (await client.search(item.name, series: item.kind == MediaKind.series)).firstOrNull;
                }
                if (m != null && m.poster != null) {
                  // Note, durée, pays et langue viennent de la fiche complète.
                  MediaDetails? full;
                  try {
                    full = await client.details(item.name, series: item.kind == MediaKind.series, tmdbId: m.tmdbId);
                  } catch (_) {}
                  found[item.id] = (
                    logo: m.poster,
                    info: m.overview,
                    year: m.year,
                    genres: m.genres,
                    rating: full?.rating,
                    runtime: full?.runtime,
                    country: full?.country,
                    language: full?.language,
                  );
                }
              } catch (_) {}
            }(),
        ]);
        // Mise à jour par paquets : les affiches apparaissent au fur et à mesure.
        if (found.length >= 24 || i + 4 >= todo.length) {
          await library.applyEnrichment(source.id, Map.of(found));
          found.clear();
        }
      }
    } finally {
      _enriching = false;
    }
  }

  /// Titre exact (titre affiché ou titre original TMDB) : seule garantie pour une vidéo sans année ni étiquette.
  /// Gère aussi les noms en « CamelCase » (TearsOfSteel → Tears Of Steel).
  Future<TMDBMatch?> _exactMatch(TMDBClient client, String name) async {
    final base = cleanTitle(name).title;
    final spaced = base.replaceAllMapped(RegExp(r'([a-zà-ÿ])([A-ZÀ-Þ])'), (m) => '${m[1]} ${m[2]}');
    for (final query in {base, spaced}) {
      final key = titleKey(query);
      if (key.isEmpty) continue;
      final matches = await client.search(query, series: false);
      for (final m in matches) {
        if (titleKey(m.title) == key || (m.originalTitle != null && titleKey(m.originalTitle!) == key)) return m;
      }
    }
    return null;
  }

  static bool _generic(String name) => RegExp(r'^(Épisode|Episode|Episodio|Capítulo|Capitulo)\s*\d+$', caseSensitive: false).hasMatch(name.trim());

  void clear() {
    _cache.clear();
    _trending.clear();
    notifyListeners();
  }

  final Map<bool, (DateTime, List<TMDBTrend>)> _trending = {};
  final Map<MediaKind, (int, Map<String, MediaItem>)> _titleIndex = {};

  /// Tendances TMDB de la semaine (mises en cache 6 h).
  Future<List<TMDBTrend>> trending({required bool series}) async {
    if (!settings.usesTMDB) return const [];
    final cached = _trending[series];
    if (cached != null && DateTime.now().difference(cached.$1) < const Duration(hours: 6)) return cached.$2;
    try {
      final list = await TMDBClient(settings.tmdbKey, _language).trending(series: series);
      _trending[series] = (DateTime.now(), list);
      return list;
    } catch (e) {
      PlaybackLog.shared.note('TMDB : tendances indisponibles ($e)');
      return const [];
    }
  }

  /// Retrouve les tendances dans le catalogue (titre nettoyé, puis titre original).
  List<(MediaItem, TMDBTrend)> match(List<TMDBTrend> trends, MediaKind kind) {
    final items = library.items(kind);
    var index = _titleIndex[kind];
    if (index == null || index.$1 != items.length) {
      final map = <String, MediaItem>{};
      for (final item in items) {
        final key = titleKey(item.name);
        if (key.isNotEmpty) map.putIfAbsent(key, () => item);
      }
      index = (items.length, map);
      _titleIndex[kind] = index;
    }
    return [
      for (final t in trends)
        if ([titleKey(t.title), if (t.originalTitle != null) titleKey(t.originalTitle!)].map((k) => index!.$2[k]).nonNulls.firstOrNull
            case final item?)
          (item, t),
    ];
  }
}
