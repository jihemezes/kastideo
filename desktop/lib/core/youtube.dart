import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'log.dart';
import 'secrets.dart';

// YouTube dans Kastideo (comme KastideoCore/YouTube.swift et App/Sources/YouTube.swift sur Mac) : navigation par flux RSS
// publics, recherche avec la clé API de l'utilisateur, et page de lecture qui intègre le lecteur OFFICIEL en « mode
// confidentialité avancée » (youtube-nocookie.com), comme la tuile YouTube de Piboard. Ce n'est PAS un bloqueur de
// publicités : rien n'est intercepté ni contourné. Ce lecteur ne dépose pas de cookie de suivi et n'affiche donc pas de
// publicité personnalisée — le plus souvent aucune, sans garantie : Google reste libre d'y diffuser des annonces.

class YouTubeVideo {
  YouTubeVideo({required this.id, required this.title, this.channel = '', this.published});
  final String id;
  final String title;
  final String channel;

  /// Date de publication ISO 8601, si connue.
  final String? published;

  String get thumbnail => 'https://i.ytimg.com/vi/$id/mqdefault.jpg';
  Uri get watchUrl => Uri.parse('https://www.youtube.com/watch?v=$id');
  DateTime? get date => published == null ? null : DateTime.tryParse(published!);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'channel': channel, 'published': published};
  factory YouTubeVideo.fromJson(Map<String, dynamic> j) =>
      YouTubeVideo(id: j['id'] as String, title: j['title'] as String? ?? '', channel: j['channel'] as String? ?? '', published: j['published'] as String?);
}

class YouTubeChannel {
  YouTubeChannel({required this.id, required this.title});
  final String id;
  final String title;
  Map<String, dynamic> toJson() => {'id': id, 'title': title};
  factory YouTubeChannel.fromJson(Map<String, dynamic> j) => YouTubeChannel(id: j['id'] as String, title: j['title'] as String? ?? '');
}

enum YouTubeSourceKind { video, playlist, channel, handle }

class YouTubeSource {
  const YouTubeSource(this.kind, this.id);
  final YouTubeSourceKind kind;
  final String id;
  @override
  bool operator ==(Object other) => other is YouTubeSource && other.kind == kind && other.id == id;
  @override
  int get hashCode => Object.hash(kind, id);
  @override
  String toString() => '$kind:$id';
}

class YouTubeSearchPage {
  YouTubeSearchPage(this.videos, this.next, this.previous);
  final List<YouTubeVideo> videos;
  final String? next;
  final String? previous;
}

enum YouTubeOrder { relevance, date, viewCount }

class YouTubeApiError implements Exception {
  YouTubeApiError(this.code, this.message);
  final int code;
  final String message;
  @override
  String toString() => 'HTTP $code — $message';
}

class YouTubeNotFound implements Exception {}

class YouTubeNoKey implements Exception {}

final _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');
final _playlistId = RegExp(r'^(PL|UU|LL|OL|RD|FL)[A-Za-z0-9_-]{10,}$');
final _channelId = RegExp(r'^UC[A-Za-z0-9_-]{22}$');

bool isYouTubeVideoId(String s) => _videoId.hasMatch(s);

/// Reconnaît toutes les formes courantes d'adresse YouTube, plus les identifiants nus.
YouTubeSource? parseYouTubeSource(String text) {
  final raw = text.trim();
  if (raw.isEmpty) return null;
  if (_videoId.hasMatch(raw)) return YouTubeSource(YouTubeSourceKind.video, raw);
  if (_playlistId.hasMatch(raw)) return YouTubeSource(YouTubeSourceKind.playlist, raw);
  if (_channelId.hasMatch(raw)) return YouTubeSource(YouTubeSourceKind.channel, raw);
  if (RegExp(r'^@[\w.-]{3,}$').hasMatch(raw)) return YouTubeSource(YouTubeSourceKind.handle, raw);
  Uri? url;
  try {
    url = Uri.parse(RegExp(r'^https?://', caseSensitive: false).hasMatch(raw) ? raw : 'https://$raw');
  } catch (_) {
    return null;
  }
  var host = url.host.toLowerCase();
  for (final prefix in const ['www.', 'm.', 'music.']) {
    if (host.startsWith(prefix)) host = host.substring(prefix.length);
  }
  if (host != 'youtube.com' && host != 'youtube-nocookie.com' && host != 'youtu.be') return null;
  final list = url.queryParameters['list'];
  final v = url.queryParameters['v'];
  final parts = url.pathSegments.where((s) => s.isNotEmpty).toList();
  // Une playlist explicite l'emporte sur la vidéo qui l'accompagne.
  if (list != null && _playlistId.hasMatch(list)) return YouTubeSource(YouTubeSourceKind.playlist, list);
  if (host == 'youtu.be' && parts.isNotEmpty && _videoId.hasMatch(parts[0])) return YouTubeSource(YouTubeSourceKind.video, parts[0]);
  if (v != null && _videoId.hasMatch(v)) return YouTubeSource(YouTubeSourceKind.video, v);
  if (parts.length > 1 && const ['embed', 'shorts', 'live', 'v'].contains(parts[0]) && _videoId.hasMatch(parts[1])) {
    return YouTubeSource(YouTubeSourceKind.video, parts[1]);
  }
  if (parts.length > 1 && parts[0] == 'channel' && _channelId.hasMatch(parts[1])) return YouTubeSource(YouTubeSourceKind.channel, parts[1]);
  if (parts.isNotEmpty && parts[0].startsWith('@')) return YouTubeSource(YouTubeSourceKind.handle, parts[0]);
  if (parts.length > 1 && (parts[0] == 'c' || parts[0] == 'user')) return YouTubeSource(YouTubeSourceKind.handle, '@${parts[1]}');
  return null;
}

String _decodeXml(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

String? _first(String pattern, String text) => RegExp(pattern, dotAll: true).firstMatch(text)?.group(1);

/// Analyse du flux Atom de YouTube (chaîne ou playlist).
({String title, List<YouTubeVideo> videos}) parseYouTubeFeed(String xml) {
  final parts = xml.split('<entry>');
  final title = _first(r'<title>([^<]*)</title>', parts.first) ?? '';
  final out = <YouTubeVideo>[];
  for (final entry in parts.skip(1)) {
    final id = _first(r'<yt:videoId>([^<]+)</yt:videoId>', entry);
    if (id == null || !_videoId.hasMatch(id)) continue;
    out.add(YouTubeVideo(
      id: id,
      title: _decodeXml(_first(r'<title>([^<]*)</title>', entry) ?? ''),
      channel: _decodeXml(_first(r'<name>([^<]*)</name>', entry) ?? ''),
      published: _first(r'<published>([^<]+)</published>', entry),
    ));
  }
  return (title: _decodeXml(title), videos: out);
}

/// Identifiant de chaîne lu dans la page publique d'une chaîne (fragile par nature : YouTube peut en changer la forme).
String? youTubeChannelIdFromPage(String html) =>
    _first(r'"channelId":"(UC[A-Za-z0-9_-]{22})"', html) ?? _first(r'youtube\.com/channel/(UC[A-Za-z0-9_-]{22})', html);

Uri youTubeSearchUrl(String query, String apiKey, {YouTubeOrder order = YouTubeOrder.relevance, String? pageToken, int maxResults = 24}) =>
    Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'type': 'video',
      // Écarte les vidéos non intégrables : une vignette qui échouerait au clic n'a pas de sens.
      'videoEmbeddable': 'true',
      'maxResults': '$maxResults',
      'order': order.name,
      'q': query,
      'key': apiKey,
      'pageToken': ?pageToken,
    });

YouTubeSearchPage parseYouTubeSearch(String body) {
  final root = jsonDecode(body);
  if (root is! Map<String, dynamic>) throw YouTubeNotFound();
  final error = root['error'];
  if (error is Map) throw YouTubeApiError((error['code'] as num?)?.toInt() ?? 0, '${error['message'] ?? ''}');
  final videos = <YouTubeVideo>[];
  for (final item in (root['items'] as List? ?? const [])) {
    if (item is! Map) continue;
    final id = (item['id'] as Map?)?['videoId'] as String?;
    final snippet = item['snippet'] as Map?;
    if (id == null || !_videoId.hasMatch(id) || snippet == null) continue;
    videos.add(YouTubeVideo(
      id: id,
      title: _decodeXml('${snippet['title'] ?? ''}'),
      channel: _decodeXml('${snippet['channelTitle'] ?? ''}'),
      published: snippet['publishedAt'] as String?,
    ));
  }
  return YouTubeSearchPage(videos, root['nextPageToken'] as String?, root['prevPageToken'] as String?);
}

/// Textes de la barre de la page de lecture.
class YouTubePlayerLabels {
  const YouTubePlayerLabels({
    required this.previous,
    required this.next,
    required this.chain,
    required this.loop,
    required this.mute,
    required this.open,
    required this.unavailable,
  });
  final String previous, next, chain, loop, mute, open, unavailable;
  Map<String, String> toMap() => {'previous': previous, 'next': next, 'chain': chain, 'loop': loop, 'mute': mute, 'open': open, 'unavailable': unavailable};
}

/// Page HTML qui joue une file de vidéos avec le lecteur officiel (mode confidentialité avancée). Identique à celle de
/// la version Mac (KastideoCore/YouTube.swift). `eventPath` : adresse relative appelée pour prévenir l'application.
String youTubePlayerHtml({
  required List<YouTubeVideo> queue,
  required int index,
  bool chain = true,
  bool loop = false,
  bool muted = false,
  required YouTubePlayerLabels labels,
  String? eventPath,
}) {
  final entries = [for (final v in queue) {'id': v.id, 'title': v.title, 'channel': v.channel}];
  final safeJson = jsonEncode(entries).replaceAll('<', r'\u003c');
  final labelJson = jsonEncode(labels.toMap()).replaceAll('<', r'\u003c');
  final eventLiteral = eventPath == null ? 'null' : '"${eventPath.replaceAll('"', '')}"';
  final start = queue.isEmpty ? 0 : index.clamp(0, queue.length - 1);
  return '''<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Kastideo — YouTube</title>
<style>
html,body{margin:0;height:100%;background:#000;overflow:hidden;font-family:-apple-system,"Segoe UI",Roboto,sans-serif}
#p{position:absolute;inset:0;width:100%;height:100%;border:0}
#bar{position:absolute;left:0;right:0;top:0;z-index:5;display:flex;align-items:center;gap:8px;padding:10px 14px;
  background:linear-gradient(#000c,#0000);color:#fff;transition:opacity .25s;opacity:1}
#bar.hide{opacity:0;pointer-events:none}
#t{flex:1;min-width:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-size:14px;font-weight:600}
#t small{font-weight:400;opacity:.7;margin-left:8px}
button,a.b{background:#ffffff26;color:#fff;border:0;border-radius:14px;padding:5px 11px;font-size:12px;cursor:pointer;text-decoration:none}
button:hover,a.b:hover{background:#ffffff40}
button.on{background:#ff6a3d}
#msg{position:absolute;left:0;right:0;bottom:12px;text-align:center;color:#fffc;font-size:13px;z-index:5}
</style></head><body>
<div id="p"></div>
<div id="bar"><button id="prev"></button><button id="next"></button><div id="t"></div>
<button id="chain"></button><button id="loop"></button><button id="mute"></button><a class="b" id="open" target="_blank" rel="noopener"></a></div>
<div id="msg"></div>
<script>
var Q=$safeJson, L=$labelJson, EV=$eventLiteral;
var idx=$start, chain=$chain, loop=$loop, muted=$muted, player=null, hideTimer=null;
function \$(i){return document.getElementById(i)}
function notify(type){
  try{window.webkit.messageHandlers.kastideo.postMessage({type:type,index:idx,id:Q[idx]&&Q[idx].id})}catch(e){}
  if(EV){try{fetch(EV+'?type='+type+'&index='+idx+'&id='+(Q[idx]?Q[idx].id:''),{cache:'no-store'})}catch(e){}}
}
function paint(){
  var v=Q[idx]||{};
  \$('t').innerHTML='';\$('t').appendChild(document.createTextNode(v.title||''));
  if(v.channel){var s=document.createElement('small');s.textContent=v.channel;\$('t').appendChild(s)}
  \$('prev').textContent='\\u23EE '+L.previous;\$('next').textContent=L.next+' \\u23ED';
  \$('chain').textContent=L.chain;\$('loop').textContent=L.loop;\$('mute').textContent=L.mute;
  \$('chain').className=chain?'on':'';\$('loop').className=loop?'on':'';\$('mute').className=muted?'on':'';
  \$('open').textContent=L.open;\$('open').href='https://www.youtube.com/watch?v='+v.id;
  \$('prev').style.display=\$('next').style.display=Q.length>1?'':'none';
  document.title=(v.title||'YouTube')+' — Kastideo';
}
function load(){
  paint();\$('msg').textContent='';
  if(player&&player.loadVideoById){player.loadVideoById(Q[idx].id)}
  notify('video');
}
function go(d){
  var n=idx+d;
  if(n<0||n>=Q.length){ if(d>0&&loop){n=0}else{return} }
  idx=n;load();
}
window.kNext=function(){go(1)};window.kPrev=function(){go(-1)};
\$('prev').onclick=function(){go(-1)};\$('next').onclick=function(){go(1)};
\$('chain').onclick=function(){chain=!chain;paint()};
\$('loop').onclick=function(){loop=!loop;paint()};
\$('mute').onclick=function(){muted=!muted;if(player){muted?player.mute():player.unMute()}paint()};
function wake(){var b=\$('bar');b.className='';clearTimeout(hideTimer);hideTimer=setTimeout(function(){b.className='hide'},3200)}
document.addEventListener('mousemove',wake);document.addEventListener('keydown',function(e){
  if(e.key==='ArrowRight'&&e.shiftKey)go(1);if(e.key==='ArrowLeft'&&e.shiftKey)go(-1);wake()});
window.onYouTubeIframeAPIReady=function(){
  player=new YT.Player('p',{host:'https://www.youtube-nocookie.com',width:'100%',height:'100%',videoId:Q[idx].id,
    playerVars:{autoplay:1,rel:0,playsinline:1,modestbranding:1,iv_load_policy:3,mute:muted?1:0},
    events:{
      onReady:function(){paint();notify('video');wake()},
      onStateChange:function(e){
        if(e.data===0){ notify('ended');
          if(chain&&idx<Q.length-1){go(1)}else if(chain&&loop&&Q.length>1){idx=0;load()}
          else if(loop){player.seekTo(0);player.playVideo()} }
      },
      onError:function(){
        \$('msg').textContent=L.unavailable;notify('error');
        if(idx<Q.length-1){setTimeout(function(){go(1)},1800)}
      }
    }});
};
var s=document.createElement('script');s.src='https://www.youtube.com/iframe_api';document.head.appendChild(s);
paint();wake();
</script></body></html>''';
}

/// Accès réseau : flux RSS, résolution de @pseudo, recherche, titre d'une vidéo collée.
class YouTubeClient {
  YouTubeClient([this.apiKey = '']);
  final String apiKey;

  static const _headers = {'Accept-Language': 'fr,en;q=0.8', 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Kastideo'};

  Future<http.Response> _get(Uri url) => http.get(url, headers: _headers).timeout(const Duration(seconds: 15));

  Future<({String title, List<YouTubeVideo> videos})> channelFeed(String id) async {
    final r = await _get(Uri.parse('https://www.youtube.com/feeds/videos.xml?channel_id=$id'));
    if (r.statusCode != 200) throw HttpException('HTTP ${r.statusCode}');
    return parseYouTubeFeed(utf8.decode(r.bodyBytes));
  }

  Future<({String title, List<YouTubeVideo> videos})> playlistFeed(String id) async {
    final r = await _get(Uri.parse('https://www.youtube.com/feeds/videos.xml?playlist_id=$id'));
    if (r.statusCode != 200) throw HttpException('HTTP ${r.statusCode}');
    return parseYouTubeFeed(utf8.decode(r.bodyBytes));
  }

  /// @pseudo → identifiant de chaîne (page publique, puis l'API si une clé est fournie).
  Future<String> resolveHandle(String handle) async {
    final clean = handle.startsWith('@') ? handle : '@$handle';
    try {
      final r = await _get(Uri.parse('https://www.youtube.com/${Uri.encodeComponent(clean)}'));
      final id = youTubeChannelIdFromPage(utf8.decode(r.bodyBytes, allowMalformed: true));
      if (id != null) return id;
    } catch (_) {}
    if (apiKey.isNotEmpty) {
      final r = await _get(Uri.https('www.googleapis.com', '/youtube/v3/channels', {'part': 'id', 'forHandle': clean, 'key': apiKey}));
      final root = jsonDecode(r.body);
      final items = root is Map ? root['items'] as List? : null;
      if (items != null && items.isNotEmpty) return (items.first as Map)['id'] as String;
    }
    throw YouTubeNotFound();
  }

  Future<YouTubeSearchPage> search(String query, {YouTubeOrder order = YouTubeOrder.relevance, String? pageToken}) async {
    if (apiKey.isEmpty) throw YouTubeNoKey();
    final r = await _get(youTubeSearchUrl(query, apiKey, order: order, pageToken: pageToken));
    return parseYouTubeSearch(utf8.decode(r.bodyBytes));
  }

  /// Titre et chaîne d'une vidéo (service oEmbed public, sans clé).
  Future<YouTubeVideo> describe(String videoId) async {
    try {
      final r = await _get(Uri.https('www.youtube.com', '/oembed', {'url': 'https://www.youtube.com/watch?v=$videoId', 'format': 'json'}));
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return YouTubeVideo(id: videoId, title: j['title'] as String? ?? videoId, channel: j['author_name'] as String? ?? '');
    } catch (_) {
      return YouTubeVideo(id: videoId, title: videoId);
    }
  }
}

/// Chaînes suivies, favoris, historique, clé API et file de lecture.
class YouTubeStore extends ChangeNotifier {
  YouTubeStore._();
  static final YouTubeStore shared = YouTubeStore._();

  static const _historyLimit = 80;

  List<YouTubeChannel> channels = [];
  List<YouTubeVideo> favorites = [];
  List<YouTubeVideo> history = [];
  final Map<String, List<YouTubeVideo>> feeds = {};
  final Map<String, String> feedErrors = {};
  bool loadingFeeds = false;
  DateTime? _lastFeedLoad;
  String apiKey = '';
  bool _loaded = false;
  late SharedPreferences _prefs;

  bool get hasKey => apiKey.trim().isNotEmpty;
  YouTubeClient get client => YouTubeClient(apiKey.trim());

  bool chain = true;
  bool loop = false;
  bool muted = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    _prefs = await SharedPreferences.getInstance();
    List<T> read<T>(String key, T Function(Map<String, dynamic>) make) {
      try {
        return [for (final j in jsonDecode(_prefs.getString(key) ?? '[]') as List) make(j as Map<String, dynamic>)];
      } catch (_) {
        return [];
      }
    }

    channels = read('youtube.channels.v1', YouTubeChannel.fromJson);
    favorites = read('youtube.favorites.v1', YouTubeVideo.fromJson);
    history = read('youtube.history.v1', YouTubeVideo.fromJson);
    chain = _prefs.getBool('youtube.chain') ?? true;
    loop = _prefs.getBool('youtube.loop') ?? false;
    muted = _prefs.getBool('youtube.muted') ?? false;
    try {
      apiKey = await Secrets.shared.read('youtube.apiKey') ?? '';
    } catch (_) {
      apiKey = '';
    }
    notifyListeners();
  }

  void _save() {
    _prefs.setString('youtube.channels.v1', jsonEncode([for (final c in channels) c.toJson()]));
    _prefs.setString('youtube.favorites.v1', jsonEncode([for (final v in favorites) v.toJson()]));
    _prefs.setString('youtube.history.v1', jsonEncode([for (final v in history) v.toJson()]));
  }

  Future<void> setApiKey(String key) async {
    apiKey = key.trim();
    await Secrets.shared.write('youtube.apiKey', apiKey);
    notifyListeners();
  }

  void setOptions({bool? chain, bool? loop, bool? muted}) {
    this.chain = chain ?? this.chain;
    this.loop = loop ?? this.loop;
    this.muted = muted ?? this.muted;
    _prefs.setBool('youtube.chain', this.chain);
    _prefs.setBool('youtube.loop', this.loop);
    _prefs.setBool('youtube.muted', this.muted);
    notifyListeners();
  }

  // Favoris, historique, chaînes

  bool isFavorite(YouTubeVideo v) => favorites.any((f) => f.id == v.id);

  void toggleFavorite(YouTubeVideo v) {
    if (!favorites.any((f) => f.id == v.id)) {
      favorites.insert(0, v);
    } else {
      favorites.removeWhere((f) => f.id == v.id);
    }
    _save();
    notifyListeners();
  }

  void record(YouTubeVideo v) {
    history.removeWhere((h) => h.id == v.id);
    history.insert(0, v);
    if (history.length > _historyLimit) history = history.sublist(0, _historyLimit);
    _save();
    notifyListeners();
  }

  void clearHistory() {
    history = [];
    _save();
    notifyListeners();
  }

  void unfollow(YouTubeChannel c) {
    channels.removeWhere((x) => x.id == c.id);
    feeds.remove(c.id);
    _save();
    notifyListeners();
  }

  /// Suit une chaîne désignée par son identifiant ou son @pseudo ; renvoie la chaîne ajoutée.
  Future<YouTubeChannel> follow(YouTubeSource source) async {
    final String id;
    switch (source.kind) {
      case YouTubeSourceKind.channel:
        id = source.id;
      case YouTubeSourceKind.handle:
        id = await client.resolveHandle(source.id);
      default:
        throw YouTubeNotFound();
    }
    for (final c in channels) {
      if (c.id == id) return c;
    }
    final feed = await client.channelFeed(id);
    final channel = YouTubeChannel(id: id, title: feed.title.isEmpty ? id : feed.title);
    channels.add(channel);
    feeds[id] = feed.videos;
    _save();
    notifyListeners();
    return channel;
  }

  /// Recharge les flux RSS des chaînes suivies (au plus une fois toutes les 5 minutes sauf `force`).
  Future<void> refreshFeeds({bool force = false}) async {
    await load();
    final last = _lastFeedLoad;
    if (!force && last != null && DateTime.now().difference(last).inSeconds < 300) return;
    if (channels.isEmpty || loadingFeeds) return;
    loadingFeeds = true;
    notifyListeners();
    final client = this.client;
    await Future.wait([
      for (final c in List.of(channels))
        () async {
          try {
            feeds[c.id] = (await client.channelFeed(c.id)).videos;
            feedErrors.remove(c.id);
          } catch (e) {
            feedErrors[c.id] = '$e';
          }
        }(),
    ]);
    loadingFeeds = false;
    _lastFeedLoad = DateTime.now();
    notifyListeners();
  }
}

/// Lecteur YouTube : une page locale (servie sur 127.0.0.1) intègre le lecteur officiel ; elle s'ouvre dans une fenêtre
/// d'application du navigateur du système (Edge / Chrome / Chromium en mode « application »), à défaut dans le
/// navigateur par défaut. Aucune dépendance native : fonctionne de la même façon sous Windows et Linux (dont ARM).
class YouTubePlayerHost {
  YouTubePlayerHost._();
  static final YouTubePlayerHost shared = YouTubePlayerHost._();

  HttpServer? _server;
  String _html = '';
  List<YouTubeVideo> _queue = const [];

  /// Une vidéo démarre dans la fenêtre de lecture (historique).
  void Function(YouTubeVideo video)? onVideo;

  Future<void> _ensureServer() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen((req) async {
      try {
        if (req.uri.path == '/event') {
          final index = int.tryParse(req.uri.queryParameters['index'] ?? '');
          if (req.uri.queryParameters['type'] == 'video' && index != null && index >= 0 && index < _queue.length) {
            onVideo?.call(_queue[index]);
          }
          req.response.statusCode = HttpStatus.noContent;
        } else {
          req.response.headers.contentType = ContentType.html;
          req.response.headers.set('Cache-Control', 'no-store');
          req.response.write(_html);
        }
      } catch (_) {}
      await req.response.close();
    }, onError: (Object _) {});
  }

  static const _flags = ['--autoplay-policy=no-user-gesture-required'];

  /// Ouvre la lecture de `queue` à partir de `index`.
  Future<void> play(List<YouTubeVideo> queue, int index, YouTubeStore options, YouTubePlayerLabels labels) async {
    if (queue.isEmpty) return;
    await _ensureServer();
    _queue = queue;
    _html = youTubePlayerHtml(
        queue: queue, index: index, chain: options.chain, loop: options.loop, muted: options.muted, labels: labels, eventPath: '/event');
    final url = 'http://127.0.0.1:${_server!.port}/player?${DateTime.now().millisecondsSinceEpoch}';
    PlaybackLog.shared.note('YouTube : ouverture de la fenêtre de lecture (${queue[index.clamp(0, queue.length - 1)].id})');
    if (await _openAppWindow(url)) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<bool> _openAppWindow(String url) async {
    try {
      if (Platform.isWindows) {
        for (final browser in const ['msedge', 'chrome']) {
          final r = await Process.run('cmd', ['/c', 'start', '', browser, '--app=$url', ..._flags]);
          if (r.exitCode == 0) return true;
        }
      } else if (Platform.isLinux) {
        for (final browser in const ['google-chrome', 'google-chrome-stable', 'chromium', 'chromium-browser', 'microsoft-edge', 'brave-browser']) {
          final found = await Process.run('which', [browser]);
          if (found.exitCode != 0) continue;
          await Process.start(browser, ['--app=$url', ..._flags], mode: ProcessStartMode.detached);
          return true;
        }
      }
    } catch (e) {
      PlaybackLog.shared.note('YouTube : fenêtre d\'application indisponible ($e), navigateur par défaut');
    }
    return false;
  }
}
