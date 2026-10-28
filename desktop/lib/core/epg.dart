import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'text.dart';
import 'themes.dart';

/// Programme du guide TV (mêmes champs que Programme sur Mac). Heures en secondes depuis 1970 (UTC).
class Programme {
  Programme(this.channel, this.startS, this.stopS, this.title, {this.desc, this.category});

  final String channel;
  final int startS;
  final int stopS;
  final String title;
  final String? desc;

  /// Genre indiqué par le guide (« Sport », « Film », « Documentaire »…).
  final String? category;

  DateTime get start => DateTime.fromMillisecondsSinceEpoch(startS * 1000);
  DateTime get stop => DateTime.fromMillisecondsSinceEpoch(stopS * 1000);
  String get id => '$channel|$startS';

  /// Thème d'après le genre, puis le titre (calculé une seule fois).
  late final ContentTheme? theme = ThemeClassifier.themeForProgramme(this);

  bool isAiring(int nowS) => startS <= nowS && nowS < stopS;

  double progress([DateTime? at]) {
    final now = (at ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final total = stopS - startS;
    if (total <= 0) return 0;
    return ((now - startS) / total).clamp(0.0, 1.0);
  }

  Programme withChannel(String value) => Programme(value, startS, stopS, title, desc: desc, category: category);

  List<Object?> toJson() => [channel, startS, stopS, title, desc, category];

  static Programme fromJson(List<dynamic> j) =>
      Programme(j[0] as String, j[1] as int, j[2] as int, j[3] as String, desc: j[4] as String?, category: j[5] as String?);
}

int nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Index du guide par chaîne (clé en minuscules).
class EPGIndex {
  EPGIndex([Iterable<Programme> programmes = const []]) {
    merge(programmes);
  }

  final Map<String, List<Programme>> _byChannel = {};

  bool get isEmpty => _byChannel.isEmpty;
  int get channelCount => _byChannel.length;

  static String key(String channel) => channel.toLowerCase().trim();

  void merge(Iterable<Programme> programmes) {
    final touched = <String>{};
    for (final p in programmes) {
      final k = key(p.channel);
      (_byChannel[k] ??= []).add(p);
      touched.add(k);
    }
    for (final k in touched) {
      _byChannel[k]!.sort((a, b) => a.startS.compareTo(b.startS));
    }
  }

  List<Programme> programmes(String? channel) => channel == null ? const [] : _byChannel[key(channel)] ?? const [];
  bool hasProgrammes(String? channel) => programmes(channel).isNotEmpty;

  Programme? current(String? channel, [int? atS]) {
    final now = atS ?? nowSeconds();
    for (final p in programmes(channel)) {
      if (p.startS <= now && now < p.stopS) return p;
      if (p.startS > now) break;
    }
    return null;
  }

  List<Programme> upcoming(String? channel, {int? afterS, int limit = 6}) {
    final now = afterS ?? nowSeconds();
    return programmes(channel).where((p) => p.startS > now).take(limit).toList();
  }

  /// Dernière fin de programme connue.
  int? get latestStop {
    int? best;
    for (final list in _byChannel.values) {
      if (list.isEmpty) continue;
      final s = list.last.stopS;
      if (best == null || s > best) best = s;
    }
    return best;
  }
}

/// Chaîne déclarée dans un guide XMLTV.
class XmltvChannel {
  XmltvChannel(this.id, this.names);
  final String id;
  final List<String> names;

  List<Object> toJson() => [id, names];
  static XmltvChannel fromJson(List<dynamic> j) => XmltvChannel(j[0] as String, List<String>.from(j[1] as List));
}

/// Résultat de l'analyse d'un guide XMLTV.
class XmltvGuide {
  XmltvGuide(this.programmes, this.channels, {required this.isValid, required this.byteCount, GuideMeta? meta})
      : meta = meta ?? GuideMeta();
  final List<Programme> programmes;
  final List<XmltvChannel> channels;

  /// Ce que le téléchargement et l'analyse ont constaté (journal « Guide TV »).
  final GuideMeta meta;

  /// Faux si le document n'est pas un guide XMLTV (page d'erreur, réponse vide…).
  final bool isValid;
  final int byteCount;
}

/// Constats d'un téléchargement de guide : de quoi diagnostiquer sans deviner.
class GuideMeta {
  /// Code HTTP (null : fichier local ou pas de réponse).
  int? status;
  String? contentType;
  String? finalHost;
  double seconds = 0;
  bool gzip = false;

  /// Début du texte reçu quand ce n'est pas un guide (page d'erreur, message du serveur…).
  String? excerpt;

  /// Programmes présents dans le document, dans la fenêtre de temps, puis gardés (chaînes demandées).
  int seen = 0;
  int inWindow = 0;
  int kept = 0;

  /// Chaînes distinctes ayant des programmes dans le document.
  int distinctChannels = 0;

  /// Exemples d'identifiants de chaînes du guide écartées (absentes de la liste demandée).
  List<String> droppedSamples = [];

  /// Exemples d'identifiants gardés.
  List<String> keptSamples = [];
  int? firstStart;
  int? lastStop;
}

/// Dates XMLTV : « 20261018203000 +0200 » (décalage facultatif, UTC par défaut). Renvoie des secondes UTC.
int? parseXmltvDate(String text) {
  final parts = text.trim().split(RegExp(r'\s+'));
  final stamp = parts.first;
  if (stamp.length < 12) return null;
  int? n(int from, int length) {
    if (from + length > stamp.length) return null;
    return int.tryParse(stamp.substring(from, from + length));
  }

  final year = n(0, 4), month = n(4, 2), day = n(6, 2), hour = n(8, 2), minute = n(10, 2);
  if (year == null || month == null || day == null || hour == null || minute == null) return null;
  final second = n(12, 2) ?? 0;
  var offset = 0;
  final tz = parts.length > 1 ? parts[1] : (stamp.length > 14 ? stamp.substring(14).trim() : '');
  if (tz.length == 5 && (tz[0] == '+' || tz[0] == '-')) {
    final h = int.tryParse(tz.substring(1, 3)) ?? 0;
    final m = int.tryParse(tz.substring(3, 5)) ?? 0;
    offset = (h * 3600 + m * 60) * (tz[0] == '-' ? -1 : 1);
  }
  final utc = DateTime.utc(year, month, day, hour, minute, second).millisecondsSinceEpoch ~/ 1000;
  return utc - offset;
}

final _attr = RegExp(r'''([A-Za-z_][\w\-:.]*)\s*=\s*("([^"]*)"|'([^']*)')''');
final _entity = RegExp(r'&(#x[0-9A-Fa-f]+|#\d+|amp|lt|gt|quot|apos);');

String _unescape(String raw) {
  var text = raw;
  if (text.contains('<![CDATA[')) {
    text = text.replaceAllMapped(RegExp(r'<!\[CDATA\[([\s\S]*?)\]\]>'), (m) => m.group(1)!);
  }
  if (!text.contains('&')) return text.trim();
  return text.replaceAllMapped(_entity, (m) {
    final e = m.group(1)!;
    switch (e) {
      case 'amp':
        return '&';
      case 'lt':
        return '<';
      case 'gt':
        return '>';
      case 'quot':
        return '"';
      case 'apos':
        return "'";
    }
    final code = e.startsWith('#x') ? int.tryParse(e.substring(2), radix: 16) : int.tryParse(e.substring(1));
    return code == null ? m.group(0)! : String.fromCharCode(code);
  }).trim();
}

Map<String, String> _attributes(String tag) => {
      for (final m in _attr.allMatches(tag)) m.group(1)!: _unescape(m.group(3) ?? m.group(4) ?? ''),
    };

/// Analyseur XMLTV en flux (morceaux de texte), avec une fenêtre de temps pour limiter la mémoire.
class XmltvParser {
  XmltvParser({int? windowStart, int? windowEnd, this.channels})
      : windowStart = windowStart ?? nowSeconds() - 6 * 3600,
        windowEnd = windowEnd ?? nowSeconds() + 48 * 3600;

  final int windowStart;
  final int windowEnd;

  /// Identifiants (en minuscules) des chaînes à garder ; null : toutes (guide de secours).
  final Set<String>? channels;
  final programmes = <Programme>[];
  final _channels = <String, List<String>>{};
  final meta = GuideMeta();
  final _seenIds = <String>{};
  final _dropped = <String>{};
  final _keptIds = <String>{};
  var _buffer = '';
  var sawRoot = false;
  var _malformed = false;

  void add(String chunk) {
    _buffer = _buffer.isEmpty ? chunk : _buffer + chunk;
    _process();
    // Un document qui n'est pas du XMLTV (page HTML géante) : on évite d'accumuler.
    if (_buffer.length > 8 * 1024 * 1024) {
      _malformed = true;
      _buffer = '';
    }
  }

  XmltvGuide close(int byteCount) {
    _process();
    meta
      ..distinctChannels = _seenIds.length
      ..kept = programmes.length
      ..droppedSamples = _dropped.toList()
      ..keptSamples = _keptIds.take(6).toList();
    return XmltvGuide(
      programmes,
      [for (final e in _channels.entries) XmltvChannel(e.key, e.value)],
      isValid: sawRoot && (!_malformed || programmes.isNotEmpty),
      byteCount: byteCount,
      meta: meta,
    );
  }

  void _process() {
    final b = _buffer;
    var pos = 0;
    while (true) {
      final lt = b.indexOf('<', pos);
      if (lt < 0) {
        pos = b.length;
        break;
      }
      if (b.startsWith('<programme', lt) && _boundary(b, lt + 10)) {
        final end = b.indexOf('</programme>', lt);
        if (end < 0) {
          // Programme vide en balise auto-fermante.
          final close = b.indexOf('>', lt);
          if (close > 0 && b[close - 1] == '/') {
            pos = close + 1;
            continue;
          }
          pos = lt;
          break;
        }
        _programme(b.substring(lt, end));
        pos = end + 12;
      } else if (b.startsWith('<channel', lt) && _boundary(b, lt + 8)) {
        final end = b.indexOf('</channel>', lt);
        if (end < 0) {
          final close = b.indexOf('>', lt);
          if (close > 0 && b[close - 1] == '/') {
            pos = close + 1;
            continue;
          }
          pos = lt;
          break;
        }
        _channel(b.substring(lt, end));
        pos = end + 10;
      } else if (b.startsWith('<!--', lt)) {
        final end = b.indexOf('-->', lt);
        if (end < 0) {
          pos = lt;
          break;
        }
        pos = end + 3;
      } else {
        final end = b.indexOf('>', lt);
        if (end < 0) {
          pos = lt;
          break;
        }
        if (b.startsWith('<tv', lt) && _boundary(b, lt + 3)) sawRoot = true;
        pos = end + 1;
      }
    }
    _buffer = pos >= b.length ? '' : b.substring(pos);
  }

  static bool _boundary(String b, int i) {
    if (i >= b.length) return true;
    final c = b.codeUnitAt(i);
    return c == 32 || c == 62 || c == 9 || c == 10 || c == 13 || c == 47;
  }

  static String? _child(String block, String name) {
    var from = 0;
    while (true) {
      final i = block.indexOf('<$name', from);
      if (i < 0) return null;
      if (!_boundary(block, i + name.length + 1)) {
        from = i + 1;
        continue;
      }
      final open = block.indexOf('>', i);
      if (open < 0) return null;
      if (block[open - 1] == '/') {
        from = open;
        continue;
      }
      final close = block.indexOf('</$name>', open);
      if (close < 0) return null;
      return _unescape(block.substring(open + 1, close));
    }
  }

  void _programme(String block) {
    final tagEnd = block.indexOf('>');
    if (tagEnd < 0) return;
    final attrs = _attributes(block.substring(0, tagEnd));
    final channel = attrs['channel'];
    final start = attrs['start'] == null ? null : parseXmltvDate(attrs['start']!);
    if (channel == null || start == null) return;
    meta.seen++;
    if (_seenIds.length < 20000) _seenIds.add(channel);
    final stop = (attrs['stop'] == null ? null : parseXmltvDate(attrs['stop']!)) ?? start + 3600;
    if (stop < windowStart || start > windowEnd) return;
    meta.inWindow++;
    if (channels != null && !channels!.contains(channel.toLowerCase().trim())) {
      if (_dropped.length < 8) _dropped.add(channel);
      return;
    }
    if (_keptIds.length < 6) _keptIds.add(channel);
    if (meta.firstStart == null || start < meta.firstStart!) meta.firstStart = start;
    if (meta.lastStop == null || stop > meta.lastStop!) meta.lastStop = stop;
    final title = _child(block, 'title');
    final desc = _child(block, 'desc');
    final category = _child(block, 'category');
    programmes.add(Programme(channel, start, stop, (title == null || title.isEmpty) ? 'Sans titre' : title,
        desc: (desc == null || desc.isEmpty) ? null : desc, category: (category == null || category.isEmpty) ? null : category));
  }

  void _channel(String block) {
    final tagEnd = block.indexOf('>');
    if (tagEnd < 0) return;
    final id = _attributes(block.substring(0, tagEnd))['id'];
    if (id == null) return;
    final names = _channels[id] ??= [];
    var from = tagEnd;
    while (true) {
      final i = block.indexOf('<display-name', from);
      if (i < 0) break;
      final open = block.indexOf('>', i);
      final close = open < 0 ? -1 : block.indexOf('</display-name>', open);
      if (close < 0) break;
      final name = _unescape(block.substring(open + 1, close));
      if (name.isNotEmpty) names.add(name);
      from = close;
    }
  }

  /// Analyse d'un document complet (tests).
  static XmltvGuide parseString(String text, {int? windowStart, int? windowEnd}) {
    final parser = XmltvParser(windowStart: windowStart, windowEnd: windowEnd)..add(text);
    return parser.close(text.length);
  }
}

/// Télécharge et analyse un guide (gzip reconnu automatiquement). À appeler dans un isolat (Isolate.run).
/// Une réponse HTTP hors 2xx ne lève pas d'exception : elle donne un guide invalide dont `meta` porte le code
/// et le début du texte reçu (pour le journal).
Future<XmltvGuide> downloadGuide(String url, {Duration timeout = const Duration(seconds: 180), Set<String>? channels}) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..userAgent = 'VLC/3.0.20 LibVLC/3.0.20';
  final started = DateTime.now();
  double elapsed() => DateTime.now().difference(started).inMilliseconds / 1000;
  try {
    Future<XmltvGuide> run() async {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, '*/*');
      final response = await request.close();
      final meta = GuideMeta()
        ..status = response.statusCode
        ..contentType = response.headers.contentType?.toString()
        ..finalHost = response.redirects.isNotEmpty ? response.redirects.last.location.host : uri.host;
      String? headText;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length >= 400) break;
        }
        meta
          ..seconds = elapsed()
          ..excerpt = _excerpt(utf8.decode(bytes.take(400).toList(), allowMalformed: true));
        return XmltvGuide([], [], isValid: false, byteCount: bytes.length, meta: meta);
      }
      final iterator = StreamIterator<List<int>>(response);
      final parser = XmltvParser(channels: channels);
      if (!await iterator.moveNext()) {
        final empty = parser.close(0);
        meta.seconds = elapsed();
        return XmltvGuide(empty.programmes, empty.channels, isValid: false, byteCount: 0, meta: meta);
      }
      final head = iterator.current;
      var bytes = 0;
      Stream<List<int>> rest() async* {
        yield head;
        while (await iterator.moveNext()) {
          yield iterator.current;
        }
      }

      Stream<List<int>> stream = rest();
      if (head.length > 1 && head[0] == 0x1f && head[1] == 0x8b) {
        meta.gzip = true;
        stream = gzip.decoder.bind(stream);
      }
      stream = stream.map((chunk) {
        bytes += chunk.length;
        return chunk;
      });
      await for (final text in stream.transform(const Utf8Decoder(allowMalformed: true))) {
        headText ??= text.length > 400 ? text.substring(0, 400) : text;
        parser.add(text);
      }
      final guide = parser.close(bytes);
      guide.meta
        ..status = meta.status
        ..contentType = meta.contentType
        ..finalHost = meta.finalHost
        ..gzip = meta.gzip
        ..seconds = elapsed()
        ..excerpt = (!guide.isValid || guide.programmes.isEmpty) && headText != null ? _excerpt(headText) : null;
      return guide;
    }

    return await run().timeout(timeout);
  } finally {
    client.close(force: true);
  }
}

String? _excerpt(String text) {
  if (text.contains('\u0000')) return '(contenu binaire)';
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.isEmpty) return null;
  return flat.length > 200 ? flat.substring(0, 200) : flat;
}

/// Rapprochement des chaînes d'un fournisseur avec celles d'un guide de secours (xmltvfr.fr…),
/// par identifiant puis par nom normalisé (« |FR| TF1 FHD » → « tf1 »).
class ChannelMatcher {
  ChannelMatcher(List<XmltvChannel> channels) {
    final scores = <String, int>{};
    void offer(String key, String id, int base) {
      if (key.isEmpty) return;
      final score = base + (id.toLowerCase().endsWith('.fr') ? 5 : 0);
      if (score > (scores[key] ?? -1)) {
        scores[key] = score;
        _byName[key] = id;
      }
    }

    for (final channel in channels) {
      _byId[channel.id.toLowerCase()] = channel.id;
      final stem = channel.id.split('.').first;
      offer(normalize(stem, keepResolution: true), channel.id, 10);
      for (final name in channel.names) {
        offer(normalize(name, keepResolution: true), channel.id, 20);
        offer(normalize(name), channel.id, 15);
      }
    }
  }

  final _byId = <String, String>{};
  final _byName = <String, String>{};

  bool get isEmpty => _byId.isEmpty;

  String? match(String name, String? epgId) {
    if (epgId != null) {
      final id = _byId[epgId.toLowerCase()];
      if (id != null) return id;
    }
    for (final key in [normalize(name, keepResolution: true), normalize(name)]) {
      if (key.isEmpty) continue;
      final id = _byName[key];
      if (id != null) return id;
    }
    return null;
  }

  static const _tags = {
    'fhd', 'hd', 'uhd', 'sd', '4k', '8k', 'hevc', 'h265', 'h264', 'raw', 'ott', 'backup', 'multi', 'vip', //
    'fr', 'france', 'be', 'ch', 'ca', 'qc', 'lq', 'hq', '50fps', '60fps', '1080p', '720p', 'low', 'direct', 'live', 'tv',
  };
  static const _resolutionTags = {'4k', '8k', 'uhd'};
  static final _prefix1 = RegExp(r'^\s*(\|[^|]*\||\[[^\]]*\])\s*');
  static final _prefix2 = RegExp(r'^\s*[a-z]{2,3}\s*[:|\-]\s+');
  static final _brackets = RegExp(r'\([^)]*\)|\[[^\]]*\]');
  static final _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  /// Nom réduit à l'essentiel : minuscules sans accents, sans préfixe de pays ni mention de qualité.
  static String normalize(String raw, {bool keepResolution = false}) {
    var text = raw.searchKey;
    text = text.replaceFirst(_prefix1, '').replaceFirst(_prefix2, '').replaceAll(_brackets, ' ');
    text = text.replaceAll('+', ' plus ').replaceAll('&', ' et ');
    final kept = text.split(_separators).where((w) => w.isNotEmpty).toList();
    while (kept.length > 1 && _tags.contains(kept.last) && !(keepResolution && _resolutionTags.contains(kept.last))) {
      kept.removeLast();
    }
    while (kept.length > 1 && const ['fr', 'be', 'ch', 'ca'].contains(kept.first)) {
      kept.removeAt(0);
    }
    if (kept.length > 2 && kept[0] == 'la' && kept[1] == 'chaine') kept.removeRange(0, 2);
    return kept.join();
  }

  /// Clé commune aux versions d'une même chaîne (« |FR| TF1 FHD », « TF1 HD », « TF1 4K » → « tf1 »).
  static String variantKey(String name) => normalize(name);

  static const _decoration = '-=_*~•●★☆♣♦♠♥◆◇■□▬═─━▪▫◦·✦✧⚡';

  /// Vrai pour une « chaîne » qui n'est qu'un séparateur de catégorie des fournisseurs IPTV
  /// (par exemple « ♣♦♣----|FR| FRANCE FHD |FR|---♣♦♣ » ou « •●★---|FR| CINEMA FHD |FR|---★●• »).
  static bool isSeparator(String name) {
    var run = 0;
    for (final r in name.runes) {
      if (_decoration.contains(String.fromCharCode(r))) {
        run++;
        if (run >= 3) return true;
      } else {
        run = 0;
      }
    }
    return false;
  }
}
