import 'text.dart';

/// Type de contenu lisible.
enum MediaKind { live, movie, series, episode }

/// Élément de la bibliothèque : chaîne, film, série ou épisode (mêmes champs que la version Mac).
class MediaItem {
  MediaItem({
    required this.id,
    required this.sourceId,
    required this.kind,
    required this.name,
    required this.group,
    this.logo,
    this.stream,
    this.epgId,
    this.seriesId,
    this.number,
    this.info,
    this.added,
  }) : searchKey = name.searchKey;

  final String id;
  final String sourceId;
  final MediaKind kind;
  final String name;
  final String group;
  final String? logo;
  final String? stream;
  final String? epgId;
  final String? seriesId;
  final int? number;
  final String? info;
  final DateTime? added;
  final String searchKey;

  String get displayName => cleanTitle(name).title;

  MediaItem copyWith({String? name, String? logo, String? epgId, int? number, String? info}) => MediaItem(
        id: id,
        sourceId: sourceId,
        kind: kind,
        name: name ?? this.name,
        group: group,
        logo: logo ?? this.logo,
        stream: stream,
        epgId: epgId ?? this.epgId,
        seriesId: seriesId,
        number: number ?? this.number,
        info: info ?? this.info,
        added: added,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        's': sourceId,
        'k': kind.index,
        'n': name,
        'g': group,
        if (logo != null) 'l': logo,
        if (stream != null) 'u': stream,
        if (epgId != null) 'e': epgId,
        if (seriesId != null) 'si': seriesId,
        if (number != null) 'no': number,
        if (info != null) 'i': info,
        if (added != null) 'a': added!.millisecondsSinceEpoch ~/ 1000,
      };

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        id: j['id'] as String,
        sourceId: j['s'] as String,
        kind: MediaKind.values[j['k'] as int],
        name: j['n'] as String,
        group: j['g'] as String,
        logo: j['l'] as String?,
        stream: j['u'] as String?,
        epgId: j['e'] as String?,
        seriesId: j['si'] as String?,
        number: j['no'] as int?,
        info: j['i'] as String?,
        added: j['a'] == null ? null : DateTime.fromMillisecondsSinceEpoch((j['a'] as int) * 1000),
      );
}

/// Type de source.
enum SourceKind { xtream, m3uUrl, m3uFile }

/// Source configurée par l'utilisateur (le mot de passe Xtream est rangé dans le coffre du système).
class Source {
  Source({
    required this.id,
    required this.name,
    required this.kind,
    required this.address,
    this.username,
    this.enabled = true,
    this.lastRefresh,
    this.epgUrl,
    this.guideUrl,
  });

  final String id;
  String name;
  final SourceKind kind;

  /// Serveur Xtream, URL de playlist ou chemin du fichier M3U.
  String address;
  String? username;
  bool enabled;
  DateTime? lastRefresh;

  /// Adresse du guide TV choisie par l'utilisateur (sinon celle du fournisseur).
  String? epgUrl;

  /// Adresse du guide TV indiquée par le fournisseur (xmltv.php, url-tvg de la playlist).
  String? guideUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'address': address,
        if (username != null) 'username': username,
        'enabled': enabled,
        if (lastRefresh != null) 'lastRefresh': lastRefresh!.toIso8601String(),
        'epgUrl': ?epgUrl,
        'guideUrl': ?guideUrl,
      };

  factory Source.fromJson(Map<String, dynamic> j) => Source(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: SourceKind.values.byName(j['kind'] as String),
        address: j['address'] as String,
        username: j['username'] as String?,
        enabled: j['enabled'] as bool? ?? true,
        lastRefresh: j['lastRefresh'] == null ? null : DateTime.tryParse(j['lastRefresh'] as String),
        epgUrl: j['epgUrl'] as String?,
        guideUrl: j['guideUrl'] as String?,
      );
}

/// Contenu chargé d'une source.
class SourceContent {
  SourceContent(this.items, {this.epgUrl});
  final List<MediaItem> items;
  final String? epgUrl;
}

/// Correction d'une chaîne par l'utilisateur (nom, numéro, logo, chaîne du guide TV), comme ChannelEdit sur Mac.
class ChannelEdit {
  ChannelEdit({this.name, this.number, this.logo, this.epgId});
  String? name;
  int? number;
  String? logo;
  String? epgId;

  bool get isEmpty => (name?.isEmpty ?? true) && number == null && (logo?.isEmpty ?? true) && (epgId?.isEmpty ?? true);

  MediaItem apply(MediaItem item) => item.copyWith(
        name: (name?.isNotEmpty ?? false) ? name : null,
        number: number,
        logo: (logo?.isNotEmpty ?? false) ? logo : null,
        epgId: (epgId?.isNotEmpty ?? false) ? epgId : null,
      );

  Map<String, dynamic> toJson() => {'name': ?name, 'number': ?number, 'logo': ?logo, 'epgId': ?epgId};

  static ChannelEdit fromJson(Map<String, dynamic> j) =>
      ChannelEdit(name: j['name'] as String?, number: j['number'] as int?, logo: j['logo'] as String?, epgId: j['epgId'] as String?);
}
