import 'package:flutter/material.dart' show IconData, Icons;

import '../l10n.dart';
import 'epg.dart';
import 'models.dart';
import 'text.dart';

/// Thème d'une chaîne ou d'un programme (mêmes valeurs que ContentTheme sur Mac).
enum ContentTheme {
  general, news, sport, movies, series, documentary, kids, entertainment, music, //
  automotive, lifestyle, nature, religion, regional, international, radio, adult, other;

  String get label => tr(switch (this) {
        general => 'Généralistes',
        news => 'Info',
        sport => 'Sport',
        movies => 'Films',
        series => 'Séries',
        documentary => 'Documentaires',
        kids => 'Jeunesse',
        entertainment => 'Divertissement',
        music => 'Musique',
        automotive => 'Auto-Moto',
        lifestyle => 'Cuisine & Maison',
        nature => 'Nature, Chasse & Pêche',
        religion => 'Religion',
        regional => 'Régional',
        international => 'International',
        radio => 'Radio',
        adult => 'Adulte',
        other => 'Autres',
      });

  IconData get icon => switch (this) {
        general => Icons.tv_rounded,
        news => Icons.newspaper_rounded,
        sport => Icons.sports_soccer_rounded,
        movies => Icons.movie_outlined,
        series => Icons.video_library_outlined,
        documentary => Icons.public_rounded,
        kids => Icons.child_care_rounded,
        entertainment => Icons.auto_awesome_rounded,
        music => Icons.music_note_rounded,
        automotive => Icons.directions_car_rounded,
        lifestyle => Icons.restaurant_rounded,
        nature => Icons.eco_rounded,
        religion => Icons.account_balance_rounded,
        regional => Icons.map_outlined,
        international => Icons.language_rounded,
        radio => Icons.radio_rounded,
        adult => Icons.visibility_off_outlined,
        other => Icons.grid_view_rounded,
      };

  /// Titre d'une rangée « en ce moment » (interface Cinéma).
  String get nowTitle => tr(switch (this) {
        sport => 'Sport en ce moment',
        movies => 'Films en cours',
        series => 'Séries en cours',
        news => 'Info en direct',
        documentary => 'Documentaires en cours',
        kids => 'Jeunesse en ce moment',
        entertainment => 'Divertissement en ce moment',
        music => 'Musique en ce moment',
        automotive => 'Sports mécaniques en ce moment',
        lifestyle => 'Cuisine & Maison en ce moment',
        nature => 'Nature en ce moment',
        regional => 'Régional en ce moment',
        international => 'International en ce moment',
        _ => 'En ce moment',
      });

  /// Titre d'une rangée « ce soir ».
  String get tonightTitle => '${tr('Ce soir')} · $label';

  /// Thèmes proposés dans les filtres (les « autres » à la fin).
  static List<ContentTheme> browsable({bool showAdult = false}) => [
        sport, automotive, movies, series, news, documentary, nature, kids, entertainment, //
        lifestyle, music, general, regional, international, religion, radio,
        if (showAdult) adult,
        other,
      ];

  /// Thèmes des rangées de l'accueil Cinéma du direct.
  static const homeRails = [sport, news, movies, series, documentary, kids, entertainment, automotive, music, nature, lifestyle];
}

String _fold(String text) => text.searchKey;
final _wordSplit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
Set<String> _words(String text) => _fold(text).split(_wordSplit).where((w) => w.isNotEmpty).toSet();

/// Classement automatique par thème : nom de la chaîne, genre des programmes du guide (règles de la version Mac).
class ThemeClassifier {
  static ContentTheme? themeForProgramme(Programme p) {
    if (p.category != null) {
      final t = themeForCategory(p.category!);
      if (t != null) return t;
    }
    final title = _fold(p.title);
    if (title.startsWith('journal') || title.contains('le 20h') || title.contains('le 13h') || title.startsWith('jt ')) {
      return ContentTheme.news;
    }
    if (const ['ligue 1', 'ligue des champions', 'football', 'rugby', 'tennis', 'formule 1', 'nba'].any(title.contains)) {
      return ContentTheme.sport;
    }
    return null;
  }

  static const _categoryRules = <(ContentTheme, List<String>)>[
    (ContentTheme.automotive, ['sports mecaniques', 'sport mecanique', 'moteur', 'motorsport', 'formule 1', 'rallye', 'automobile', 'moto']),
    (ContentTheme.sport, ['sport', 'football', 'rugby', 'tennis', 'cyclisme', 'basket', 'golf', 'athletisme', 'moteur', 'motorsport', 'boxe']),
    (ContentTheme.kids, ['jeunesse', 'dessin anime', 'animation', 'children', 'enfant', 'kids', 'animated', 'cartoon']),
    (ContentTheme.news, ['journal', 'information', 'actualite', 'news', 'infos', 'meteo', 'politique', 'debat']),
    (ContentTheme.nature, ['animalier', 'animaux', 'nature', 'chasse', 'peche', 'wildlife']),
    (ContentTheme.lifestyle, ['cuisine', 'gastronomie', 'lifestyle', 'maison', 'bricolage', 'jardinage', 'mode', 'beaute', 'tele-achat', 'teleachat', 'shopping', 'deco']),
    (ContentTheme.religion, ['religion', 'religieux', 'messe', 'spiritualite']),
    (ContentTheme.adult, ['adulte', 'adult', 'erotique', 'charme']),
    (ContentTheme.documentary, ['documentaire', 'documentary', 'decouverte', 'histoire', 'science', 'voyage']),
    (ContentTheme.movies, ['film', 'movie', 'cinema', 'telefilm', 'court metrage']),
    (ContentTheme.series, ['serie', 'series', 'feuilleton', 'sitcom', 'soap', 'drama']),
    (ContentTheme.music, ['musique', 'music', 'clip', 'concert', 'opera', 'variete']),
    (ContentTheme.entertainment, ['divertissement', 'jeu', 'game show', 'talk', 'telerealite', 'reality', 'humour', 'spectacle', 'magazine', 'emission']),
  ];

  static ContentTheme? themeForCategory(String raw) {
    final c = _fold(raw);
    for (final (theme, words) in _categoryRules) {
      if (words.any(c.contains)) return theme;
    }
    return null;
  }

  static const _general = {
    'tf1', 'france2', 'france3', 'france4', 'france5', 'm6', 'c8', 'w9', 'tmc', 'tfx', 'nrj12', //
    'arte', '6ter', 'cherie25', 'rmcstory', 'numero23', 'tv5monde', 'rtsun', 'rtl', 'rtlinfo',
    'latrois', 'lauxun', 'laune', 'tvbreizh', 'paris premiere', 'parispremiere', 'canalplus', 'canal',
  };

  static const _nameRules = <(ContentTheme, List<String>)>[
    (ContentTheme.automotive, ['automoto', 'motorsport', 'motorstv', 'motors', 'f1', 'formula1', 'turbo', 'rallye', 'nascar', 'motogp', 'autoplus']),
    (ContentTheme.religion, ['kto', 'emci', 'dieu', 'god', 'catholic', 'jewish', 'islam', 'coran', 'quran', 'church', 'gospel', 'orthodox']),
    (ContentTheme.radio, ['radio', 'fip', 'rfm', 'nostalgie', 'skyrock', 'funradio', 'rtl2', 'cheriefm', 'virgin radio', 'franceinter', 'franceculture', 'europe1', 'rmcradio', 'ouifm']),
    (ContentTheme.sport, ['bein', 'eurosport', 'rmcsport', 'canalplussport', 'sport', 'equipe', 'foot', 'golf', 'dazn', 'infosport', 'nba', 'skysport', 'tennis', 'rugby', 'equidia', 'multisports']),
    (ContentTheme.news, ['bfm', 'lci', 'cnews', 'franceinfo', 'euronews', 'france24', 'news', 'info', 'cnn', 'bbcworld', 'lcp', 'publicsenat', 'aljazeera']),
    (ContentTheme.kids, ['gulli', 'disney', 'nickelodeon', 'nick', 'cartoon', 'boomerang', 'tiji', 'piwi', 'canalj', 'teletoon', 'junior', 'kids', 'baby', 'boing', 'mangas']),
    (ContentTheme.nature, ['ushuaia', 'animaux', 'seasons', 'chasse', 'peche', 'wild', 'animalplanet', 'natgeowild', 'nature', 'montagne']),
    (ContentTheme.lifestyle, ['cuisine', 'food', 'chef', 'maison', 'deco', 'travel', 'voyage', 'fashion', 'mode', 'teleshopping', 'bestofshopping', 'mieuxetre', 'gourmet']),
    (ContentTheme.documentary, ['discovery', 'nationalgeographic', 'natgeo', 'histoire', 'history', 'planete', 'science', 'docu', 'rmcdecouverte', 'toutelhistoire', 'museum', 'trek']),
    (ContentTheme.movies, ['cine', 'cinema', 'film', 'movie', 'paramount', 'tcm', 'actionfilm', 'ocs', 'cinefx', 'polar', 'warnertv']),
    (ContentTheme.series, ['serie', 'series', '13emerue', 'syfy', 'comedie', 'tf1seriesfilms', 'teva', 'rtl9', 'ab1', 'novelas']),
    (ContentTheme.music, ['mtv', 'mcm', 'music', 'trace', 'mezzo', 'hits', 'melody', 'clip']),
    (ContentTheme.entertainment, ['game', 'comedy', 'realite']),
  ];

  /// Thème d'une chaîne d'après son nom (grandes chaînes françaises et marques thématiques connues).
  static ContentTheme? themeForChannelName(String name, {String group = ''}) {
    if (isAdult(name, group: group)) return ContentTheme.adult;
    final key = ChannelMatcher.normalize(name);
    final words = _words(name);
    if (_general.contains(key)) return ContentTheme.general;
    if (_isRegional(key, words)) return ContentTheme.regional;
    for (final (theme, needles) in _nameRules) {
      if (needles.any((n) => key.contains(n) || words.contains(n))) return theme;
    }
    if (isInternational(name)) return ContentTheme.international;
    return null;
  }

  /// Adulte : « |XX| » dans le nom, ou catégorie du fournisseur explicitement adulte.
  static bool isAdult(String name, {String group = ''}) {
    final upper = name.toUpperCase();
    if (upper.contains('|XX|') || upper.contains('XXX') || upper.contains('[XX]')) return true;
    final g = _fold(group);
    return g.contains('adult') || g.contains('xxx') || g.contains('+18') || g.contains('18+') || g.contains('|xx|');
  }

  static const _locals = [
    'tv7', 'tl7', 'tvr', 'tebeo', 'tebesud', '8montblanc', '7alimoges', 'viaoccitanie', 'biptv', 'grandlilletv', //
    'telegrenoble', 'tvvendee', 'alsace20', 'lyoncapitale', 'canalalpha', 'telenantes', 'weo', 'noa', 'tv8montblanc',
    'maritima', 'provenceazur', 'azurtv', 'tvsud', 'tlm', 'ilti', 'vosgestv', 'dici',
  ];

  static bool _isRegional(String key, Set<String> words) {
    if (key.startsWith('france3') && key != 'france3') return true;
    if (key.startsWith('bfm') && !const ['bfm', 'bfmtv', 'bfmbusiness', 'bfmplus'].contains(key) && !key.contains('sport')) return true;
    return _locals.any(key.contains) || words.contains('locale') || words.contains('regional');
  }

  static final _countryPrefix = RegExp(r'^\s*[\|\[]?\s*([A-Za-z]{2,3})\s*[\|\]:-]');
  static const _francophone = {'FR', 'FRA', 'VF', 'VFF', 'BE', 'CH', 'QC', 'CA', 'MC', 'LU', 'HD', 'SD', 'FHD', 'UHD', 'XX'};

  /// Chaîne étrangère : préfixe de pays autre que francophone (« |IT| », « UK: », « [DE] »).
  static bool isInternational(String name) {
    final m = _countryPrefix.firstMatch(name);
    if (m == null) return false;
    return !_francophone.contains(m.group(1)!.toUpperCase());
  }

  /// Thème dominant d'une liste de programmes (au moins 45 % des programmes classables).
  static ContentTheme? dominantTheme(List<Programme> programmes) {
    final counts = <ContentTheme, int>{};
    var total = 0;
    for (final p in programmes) {
      final t = p.theme;
      if (t == null) continue;
      counts[t] = (counts[t] ?? 0) + 1;
      total++;
    }
    if (total < 4) return null;
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.value / total >= 0.45 ? best.key : ContentTheme.general;
  }
}

/// Qualité annoncée dans le nom d'une chaîne (« TF1 FHD », « M6 4K », « France 2 SD »).
enum ChannelQuality {
  sd, hd, fhd, uhd;

  String get label => switch (this) { sd => 'SD', hd => 'HD', fhd => 'Full HD', uhd => '4K' };

  static ChannelQuality of(String name) {
    final w = _words(name);
    if (w.contains('4k') || w.contains('uhd') || w.contains('2160p') || w.contains('8k')) return uhd;
    if (w.contains('fhd') || w.contains('1080p') || w.contains('1080')) return fhd;
    if (w.contains('sd') || w.contains('lq') || w.contains('low') || w.contains('480p')) return sd;
    return hd;
  }

  /// Meilleure version ne dépassant pas la qualité visée (à défaut, la plus faible).
  static T? pick<T>(List<T> variants, ChannelQuality target, ChannelQuality Function(T) quality) {
    T? best;
    for (final v in variants) {
      if (quality(v).index <= target.index && (best == null || quality(v).index > quality(best).index)) best = v;
    }
    if (best != null) return best;
    for (final v in variants) {
      if (best == null || quality(v).index < quality(best).index) best = v;
    }
    return best;
  }
}

/// Discipline d'un programme ou d'une chaîne de sport.
enum SportKind {
  football, rugby, tennis, basketball, combat, golf, cycling, handball, motorsport, winter, horse, athletics, other;

  String get label => tr(switch (this) {
        football => 'Football',
        rugby => 'Rugby',
        tennis => 'Tennis',
        basketball => 'Basket',
        combat => 'Sports de combat',
        golf => 'Golf',
        cycling => 'Cyclisme',
        handball => 'Handball',
        motorsport => 'Sports mécaniques',
        winter => 'Sports d\'hiver',
        horse => 'Hippisme',
        athletics => 'Athlétisme & natation',
        other => 'Autres sports',
      });

  IconData get icon => switch (this) {
        football => Icons.sports_soccer_rounded,
        rugby => Icons.sports_rugby_rounded,
        tennis => Icons.sports_tennis_rounded,
        basketball => Icons.sports_basketball_rounded,
        combat => Icons.sports_mma_rounded,
        golf => Icons.sports_golf_rounded,
        cycling => Icons.directions_bike_rounded,
        handball => Icons.sports_handball_rounded,
        motorsport => Icons.sports_motorsports_rounded,
        winter => Icons.downhill_skiing_rounded,
        horse => Icons.emoji_events_rounded,
        athletics => Icons.directions_run_rounded,
        other => Icons.sports_rounded,
      };

  static const _keywords = <(SportKind, List<String>)>[
    (football, ['football', 'foot', 'ligue 1', 'ligue 2', 'ligue des champions', 'champions league', 'premier league', 'liga', 'serie a', 'bundesliga', 'coupe de france', 'europa league', 'psg', 'om ', 'ol ']),
    (rugby, ['rugby', 'top 14', 'pro d2', 'six nations', 'tournoi des 6', 'champions cup']),
    (tennis, ['tennis', 'roland-garros', 'roland garros', 'wimbledon', 'atp', 'wta', 'us open', 'open d\'australie', 'masters 1000']),
    (basketball, ['basket', 'nba', 'euroleague', 'betclic elite']),
    (combat, ['boxe', 'boxing', 'mma', 'ufc', 'catch', 'wwe', 'judo', 'karate', 'kickboxing', 'lutte', 'combat']),
    (golf, ['golf', 'pga', 'ryder cup']),
    (cycling, ['cyclisme', 'tour de france', 'giro', 'vuelta', 'velo', 'cycling']),
    (handball, ['handball']),
    (motorsport, ['formule 1', 'formula 1', 'f1', 'motogp', 'moto gp', 'rallye', 'nascar', 'endurance', '24 heures', 'superbike', 'moteur', 'motorsport']),
    (winter, ['ski', 'biathlon', 'patinage', 'hockey', 'snowboard', 'sports d\'hiver']),
    (horse, ['hippisme', 'turf', 'pmu', 'equitation', 'quinte', 'galop', 'trot', 'equidia']),
    (athletics, ['athletisme', 'marathon', 'natation', 'jeux olympiques', 'decathlon']),
  ];

  static SportKind? detect(List<String?> texts) {
    final text = ' ${texts.whereType<String>().map(_fold).join(' ')} ';
    for (final (kind, words) in _keywords) {
      if (words.any(text.contains)) return kind;
    }
    return null;
  }

  static SportKind? ofProgramme(Programme p) => detect([p.title, p.category, p.desc]);
}

/// Clé de guide d'une chaîne : son identifiant XMLTV, ou une clé tirée du nom (guide de secours).
String guideKey(MediaItem item) {
  final id = item.epgId;
  if (id != null && id.isNotEmpty) return id;
  return 'auto:${ChannelMatcher.normalize(item.name, keepResolution: true)}';
}

/// Une chaîne du direct et toutes ses versions (qualités).
class LiveChannelGroup {
  LiveChannelGroup({
    required this.key,
    required this.variants,
    required this.autoTheme,
    required this.theme,
    required this.themeFromName,
    required this.epgId,
  });

  final String key;
  final List<MediaItem> variants;
  final ContentTheme autoTheme;
  final ContentTheme theme;

  /// Le thème vient du nom de la chaîne (ou d'un choix de l'utilisateur) : fiable même sans guide TV.
  final bool themeFromName;

  /// Clé de guide qui a des programmes (parmi les versions).
  final String epgId;

  /// Version proposée (Full HD si elle existe, sinon la plus proche).
  late final MediaItem preferred =
      ChannelQuality.pick(variants, ChannelQuality.fhd, (MediaItem i) => ChannelQuality.of(i.name)) ?? variants.first;

  static List<LiveChannelGroup> build(List<MediaItem> live, EPGIndex epg, Map<String, ContentTheme> overrides) {
    final order = <String>[];
    final byKey = <String, List<MediaItem>>{};
    for (final item in live) {
      final key = ChannelMatcher.variantKey(item.name);
      if (key.isEmpty) continue;
      final list = byKey[key];
      if (list == null) {
        order.add(key);
        byKey[key] = [item];
      } else {
        list.add(item);
      }
    }
    return [
      for (final key in order)
        () {
          final variants = byKey[key]!;
          final withGuide = variants.where((v) => epg.hasProgrammes(guideKey(v))).firstOrNull;
          final programmes = withGuide == null ? const <Programme>[] : epg.programmes(guideKey(withGuide));
          ContentTheme? named;
          for (final v in variants) {
            named = ThemeClassifier.themeForChannelName(v.name, group: v.group);
            if (named != null) break;
          }
          final auto = named ?? ThemeClassifier.dominantTheme(programmes) ?? ContentTheme.other;
          final chosen = overrides[key];
          return LiveChannelGroup(
            key: key,
            variants: variants,
            autoTheme: auto,
            theme: chosen ?? auto,
            themeFromName: chosen != null || named != null,
            epgId: guideKey(withGuide ?? variants.first),
          );
        }(),
    ];
  }
}

/// « Ce soir » : programmes commençant entre 20 h et 23 h (le lendemain si la soirée est passée).
({int start, int end}) tonightWindow([DateTime? at]) {
  final now = at ?? DateTime.now();
  var start = DateTime(now.year, now.month, now.day, 20);
  var end = DateTime(now.year, now.month, now.day, 23);
  if (now.isAfter(end)) {
    start = start.add(const Duration(days: 1));
    end = end.add(const Duration(days: 1));
  }
  return (start: start.millisecondsSinceEpoch ~/ 1000, end: end.millisecondsSinceEpoch ~/ 1000);
}
