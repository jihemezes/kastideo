import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// YouTube dans Kastideo : navigation (flux RSS publics, recherche avec la clé API de l'utilisateur) et page de lecture
// qui intègre le lecteur OFFICIEL en « mode confidentialité avancée » (youtube-nocookie.com), comme la tuile YouTube de
// Piboard. Ce n'est PAS un bloqueur de publicités : rien n'est intercepté ni contourné. Ce lecteur ne dépose pas de
// cookie de suivi et n'affiche donc pas de publicité personnalisée — le plus souvent aucune, sans garantie : Google
// reste libre d'y diffuser des annonces.

/// Une vidéo YouTube (identifiant à 11 caractères) avec ce qu'il faut pour l'afficher.
public struct YouTubeVideo: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var channel: String
    /// Date de publication ISO 8601, si connue.
    public var published: String?

    public init(id: String, title: String, channel: String = "", published: String? = nil) {
        self.id = id
        self.title = title
        self.channel = channel
        self.published = published
    }

    public var thumbnailURL: URL { URL(string: "https://i.ytimg.com/vi/\(id)/mqdefault.jpg")! }
    public var watchURL: URL { URL(string: "https://www.youtube.com/watch?v=\(id)")! }
}

/// Ce qu'une adresse collée désigne.
public enum YouTubeSource: Equatable, Sendable {
    case video(String)
    case playlist(String)
    case channel(String)
    /// @pseudo, à résoudre en identifiant de chaîne.
    case handle(String)
}

/// Une chaîne suivie.
public struct YouTubeChannel: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

/// Une page de résultats de recherche (jetons de pagination de l'API, rendus tels quels).
public struct YouTubeSearchPage: Sendable, Equatable {
    public var videos: [YouTubeVideo]
    public var next: String?
    public var previous: String?
    public init(videos: [YouTubeVideo], next: String?, previous: String?) {
        self.videos = videos
        self.next = next
        self.previous = previous
    }
}

public enum YouTubeOrder: String, CaseIterable, Sendable {
    case relevance, date, viewCount
}

public enum YouTubeError: Error, Equatable {
    case noKey
    case api(Int, String)
    case notFound
    case badAddress
}

public enum YouTube {
    static let videoID = try! NSRegularExpression(pattern: "^[A-Za-z0-9_-]{11}$")
    static let playlistID = try! NSRegularExpression(pattern: "^(PL|UU|LL|OL|RD|FL)[A-Za-z0-9_-]{10,}$")
    static let channelID = try! NSRegularExpression(pattern: "^UC[A-Za-z0-9_-]{22}$")

    static func matches(_ regex: NSRegularExpression, _ text: String) -> Bool {
        regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    public static func isVideoID(_ s: String) -> Bool { matches(videoID, s) }

    /// Reconnaît toutes les formes courantes d'adresse YouTube, plus les identifiants nus.
    public static func parseSource(_ text: String) -> YouTubeSource? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return nil }
        if matches(videoID, raw) { return .video(raw) }
        if matches(playlistID, raw) { return .playlist(raw) }
        if matches(channelID, raw) { return .channel(raw) }
        if raw.hasPrefix("@"), raw.count >= 4, raw.dropFirst().allSatisfy({ $0.isLetter || $0.isNumber || "._-".contains($0) }) {
            return .handle(raw)
        }
        let withScheme = raw.lowercased().hasPrefix("http") ? raw : "https://" + raw
        guard let url = URL(string: withScheme), var host = url.host?.lowercased() else { return nil }
        for prefix in ["www.", "m.", "music."] where host.hasPrefix(prefix) { host.removeFirst(prefix.count) }
        guard host == "youtube.com" || host == "youtube-nocookie.com" || host == "youtu.be" else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let list = items.first { $0.name == "list" }?.value
        let v = items.first { $0.name == "v" }?.value
        let parts = url.path.split(separator: "/").map(String.init)
        // Une playlist explicite l'emporte sur la vidéo qui l'accompagne.
        if let list, matches(playlistID, list) { return .playlist(list) }
        if host == "youtu.be", let first = parts.first, matches(videoID, first) { return .video(first) }
        if let v, matches(videoID, v) { return .video(v) }
        if let first = parts.first, ["embed", "shorts", "live", "v"].contains(first), parts.count > 1, matches(videoID, parts[1]) {
            return .video(parts[1])
        }
        if parts.first == "channel", parts.count > 1, matches(channelID, parts[1]) { return .channel(parts[1]) }
        if let first = parts.first, first.hasPrefix("@") { return .handle(first) }
        if let first = parts.first, first == "c" || first == "user", parts.count > 1 { return .handle("@" + parts[1]) }
        return nil
    }

    // MARK: Flux RSS

    public static func feedURL(channelID: String) -> URL {
        URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=\(channelID)")!
    }

    public static func feedURL(playlistID: String) -> URL {
        URL(string: "https://www.youtube.com/feeds/videos.xml?playlist_id=\(playlistID)")!
    }

    static func decodeXML(_ s: String) -> String {
        s.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'").replacingOccurrences(of: "&amp;", with: "&")
    }

    static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              m.numberOfRanges > 1, let r = Range(m.range(at: 1), in: text) else { return nil }
        return String(text[r])
    }

    /// Analyse du flux Atom de YouTube (chaîne ou playlist).
    public static func parseFeed(_ xml: String) -> (title: String, videos: [YouTubeVideo]) {
        let parts = xml.components(separatedBy: "<entry>")
        let feedTitle = firstMatch("<title>([^<]*)</title>", in: parts.first ?? "") ?? ""
        var out: [YouTubeVideo] = []
        for entry in parts.dropFirst() {
            guard let id = firstMatch("<yt:videoId>([^<]+)</yt:videoId>", in: entry), isVideoID(id) else { continue }
            out.append(YouTubeVideo(id: id,
                                    title: decodeXML(firstMatch("<title>([^<]*)</title>", in: entry) ?? ""),
                                    channel: decodeXML(firstMatch("<name>([^<]*)</name>", in: entry) ?? ""),
                                    published: firstMatch("<published>([^<]+)</published>", in: entry)))
        }
        return (decodeXML(feedTitle), out)
    }

    /// Identifiant de chaîne lu dans la page publique d'une chaîne (fragile par nature : YouTube peut en changer la forme).
    public static func channelID(fromPage html: String) -> String? {
        firstMatch("\"channelId\":\"(UC[A-Za-z0-9_-]{22})\"", in: html)
            ?? firstMatch("youtube\\.com/channel/(UC[A-Za-z0-9_-]{22})", in: html)
    }

    // MARK: Import des abonnements (Google Takeout)

    /// Découpe une ligne CSV (guillemets doublés acceptés).
    static func csvFields(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var quoted = false
        var chars = Array(line)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if quoted {
                if c == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" { current.append("\""); i += 1 } else { quoted = false }
                } else { current.append(c) }
            } else if c == "\"" { quoted = true }
            else if c == "," { fields.append(current); current = "" }
            else { current.append(c) }
            i += 1
        }
        chars.removeAll()
        fields.append(current)
        return fields.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    /// Abonnements lus dans un export Google Takeout (CSV « abonnements.csv » ou JSON), ou une simple liste de liens / @pseudos.
    /// Les chaînes données par @pseudo (sans identifiant) sont ignorées : elles demandent un accès réseau pour être résolues.
    public static func parseSubscriptions(_ text: String) -> [YouTubeChannel] {
        var out: [YouTubeChannel] = []
        var seen = Set<String>()
        func add(_ id: String, _ title: String) {
            guard matches(channelID, id), seen.insert(id).inserted else { return }
            out.append(YouTubeChannel(id: id, title: title.isEmpty ? id : title))
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("["), let data = trimmed.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for entry in array {
                let snippet = entry["snippet"] as? [String: Any] ?? [:]
                let id = (snippet["resourceId"] as? [String: Any])?["channelId"] as? String ?? ""
                add(id, snippet["title"] as? String ?? "")
            }
            return out
        }
        for line in trimmed.components(separatedBy: .newlines) {
            let fields = csvFields(line)
            if let id = fields.first(where: { matches(channelID, $0) }) {
                add(id, fields.count > 1 ? fields[fields.count - 1] : "")
            } else if case .channel(let id)? = parseSource(line.trimmingCharacters(in: .whitespaces)) {
                add(id, "")
            }
        }
        return out
    }

    // MARK: Recherche (API Data v3, clé de l'utilisateur)

    public static func searchURL(query: String, apiKey: String, order: YouTubeOrder = .relevance, pageToken: String? = nil,
                                 maxResults: Int = 24) -> URL {
        var c = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        var items = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "type", value: "video"),
            // Écarte les vidéos non intégrables : une vignette qui échouerait au clic n'a pas de sens.
            URLQueryItem(name: "videoEmbeddable", value: "true"),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "order", value: order.rawValue),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: apiKey)
        ]
        if let pageToken { items.append(URLQueryItem(name: "pageToken", value: pageToken)) }
        c.queryItems = items
        return c.url!
    }

    public static func parseSearch(_ data: Data) throws -> YouTubeSearchPage {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw YouTubeError.notFound }
        if let error = root["error"] as? [String: Any] {
            throw YouTubeError.api(error["code"] as? Int ?? 0, error["message"] as? String ?? "")
        }
        var videos: [YouTubeVideo] = []
        for item in root["items"] as? [[String: Any]] ?? [] {
            guard let id = (item["id"] as? [String: Any])?["videoId"] as? String, isVideoID(id),
                  let snippet = item["snippet"] as? [String: Any] else { continue }
            videos.append(YouTubeVideo(id: id,
                                       title: decodeXML(snippet["title"] as? String ?? ""),
                                       channel: decodeXML(snippet["channelTitle"] as? String ?? ""),
                                       published: snippet["publishedAt"] as? String))
        }
        return YouTubeSearchPage(videos: videos, next: root["nextPageToken"] as? String, previous: root["prevPageToken"] as? String)
    }

    /// Message lisible pour une erreur de l'API (clé invalide, quota…).
    public static func explain(_ error: YouTubeError) -> String {
        switch error {
        case .noKey: return "no-key"
        case .api(let code, let message): return "HTTP \(code) — \(message)"
        case .notFound: return "not-found"
        case .badAddress: return "bad-address"
        }
    }

    // MARK: Page de lecture

    /// Textes de la barre de la page de lecture (fournis par l'application, dans sa langue).
    public struct PlayerLabels: Sendable {
        public var previous, next, chain, loop, mute, openOnYouTube, unavailable: String
        public init(previous: String, next: String, chain: String, loop: String, mute: String, openOnYouTube: String, unavailable: String) {
            self.previous = previous
            self.next = next
            self.chain = chain
            self.loop = loop
            self.mute = mute
            self.openOnYouTube = openOnYouTube
            self.unavailable = unavailable
        }
    }

    /// Page HTML qui joue une file de vidéos avec le lecteur officiel (mode confidentialité avancée).
    /// `eventPath` : adresse relative appelée (`GET <eventPath>?type=…&index=…`) pour prévenir l'application ;
    /// sur Mac, les mêmes événements passent par le gestionnaire de messages WebKit « kastideo ».
    public static func playerHTML(queue: [YouTubeVideo], index: Int, chain: Bool = true, loop: Bool = false, muted: Bool = false,
                                  resume: [String: Double] = [:], labels: PlayerLabels, eventPath: String? = nil) -> String {
        struct Entry: Encodable { var id: String; var title: String; var channel: String }
        let entries = queue.map { Entry(id: $0.id, title: $0.title, channel: $0.channel) }
        let encoder = JSONEncoder()
        let json = (try? String(data: encoder.encode(entries), encoding: .utf8)) ?? "[]"
        let safeJSON = json.replacingOccurrences(of: "<", with: "\\u003c")
        let labelJSON: String = {
            let dict = ["previous": labels.previous, "next": labels.next, "chain": labels.chain, "loop": labels.loop,
                        "mute": labels.mute, "open": labels.openOnYouTube, "unavailable": labels.unavailable]
            let data = (try? JSONSerialization.data(withJSONObject: dict)) ?? Data("{}".utf8)
            return (String(data: data, encoding: .utf8) ?? "{}").replacingOccurrences(of: "<", with: "\\u003c")
        }()
        let resumeJSON: String = {
            let clean = resume.filter { $0.value >= 1 && isVideoID($0.key) }.mapValues { Int($0) }
            let data = (try? JSONSerialization.data(withJSONObject: clean)) ?? Data("{}".utf8)
            return String(data: data, encoding: .utf8) ?? "{}"
        }()
        let eventLiteral = eventPath.map { "\"\($0.replacingOccurrences(of: "\"", with: ""))\"" } ?? "null"
        return """
        <!doctype html>
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
        var Q=\(safeJSON), L=\(labelJSON), EV=\(eventLiteral), S=\(resumeJSON);
        var idx=\(max(0, min(index, max(queue.count - 1, 0)))), chain=\(chain), loop=\(loop), muted=\(muted), player=null, hideTimer=null;
        function $(i){return document.getElementById(i)}
        function notify(type,t,d){
          var m={type:type,index:idx,id:Q[idx]&&Q[idx].id};if(t!==undefined){m.t=t;m.d=d}
          try{window.webkit.messageHandlers.kastideo.postMessage(m)}catch(e){}
          if(EV){try{fetch(EV+'?type='+type+'&index='+idx+'&id='+(Q[idx]?Q[idx].id:'')+(t!==undefined?'&t='+t+'&d='+d:''),{cache:'no-store'})}catch(e){}}
        }
        function tick(){
          if(player&&player.getCurrentTime&&player.getDuration){var d=player.getDuration();if(d>0)notify('progress',Math.floor(player.getCurrentTime()),Math.floor(d))}
        }
        setInterval(tick,5000);
        function paint(){
          var v=Q[idx]||{};
          $('t').innerHTML='';$('t').appendChild(document.createTextNode(v.title||''));
          if(v.channel){var s=document.createElement('small');s.textContent=v.channel;$('t').appendChild(s)}
          $('prev').textContent='\\u23EE '+L.previous;$('next').textContent=L.next+' \\u23ED';
          $('chain').textContent=L.chain;$('loop').textContent=L.loop;$('mute').textContent=L.mute;
          $('chain').className=chain?'on':'';$('loop').className=loop?'on':'';$('mute').className=muted?'on':'';
          $('open').textContent=L.open;$('open').href='https://www.youtube.com/watch?v='+v.id;
          $('prev').style.display=$('next').style.display=Q.length>1?'':'none';
          document.title=(v.title||'YouTube')+' — Kastideo';
        }
        function load(){
          paint();$('msg').textContent='';
          if(player&&player.loadVideoById){player.loadVideoById({videoId:Q[idx].id,startSeconds:S[Q[idx].id]||0})}
          notify('video');
        }
        function go(d){
          var n=idx+d;
          if(n<0||n>=Q.length){ if(d>0&&loop){n=0}else{return} }
          idx=n;load();
        }
        window.kNext=function(){go(1)};window.kPrev=function(){go(-1)};
        $('prev').onclick=function(){go(-1)};$('next').onclick=function(){go(1)};
        $('chain').onclick=function(){chain=!chain;paint()};
        $('loop').onclick=function(){loop=!loop;paint()};
        $('mute').onclick=function(){muted=!muted;if(player){muted?player.mute():player.unMute()}paint()};
        function wake(){var b=$('bar');b.className='';clearTimeout(hideTimer);hideTimer=setTimeout(function(){b.className='hide'},3200)}
        document.addEventListener('mousemove',wake);document.addEventListener('keydown',function(e){
          if(e.key==='ArrowRight'&&e.shiftKey)go(1);if(e.key==='ArrowLeft'&&e.shiftKey)go(-1);wake()});
        window.onYouTubeIframeAPIReady=function(){
          player=new YT.Player('p',{host:'https://www.youtube-nocookie.com',width:'100%',height:'100%',videoId:Q[idx].id,
            playerVars:{autoplay:1,rel:0,playsinline:1,modestbranding:1,iv_load_policy:3,mute:muted?1:0,start:S[Q[idx].id]||0},
            events:{
              onReady:function(){paint();notify('video');wake()},
              onStateChange:function(e){
                if(e.data===0){ var dd=Math.floor(player.getDuration()||0);if(dd>0)notify('progress',dd,dd);notify('ended');
                  if(chain&&idx<Q.length-1){go(1)}else if(chain&&loop&&Q.length>1){idx=0;load()}
                  else if(loop){player.seekTo(0);player.playVideo()} }
              },
              onError:function(){
                $('msg').textContent=L.unavailable;notify('error');
                if(idx<Q.length-1){setTimeout(function(){go(1)},1800)}
              }
            }});
        };
        var s=document.createElement('script');s.src='https://www.youtube.com/iframe_api';document.head.appendChild(s);
        paint();wake();
        </script></body></html>
        """
    }
}

/// Accès réseau : flux RSS, résolution de @pseudo, recherche, titre d'une vidéo collée.
public struct YouTubeClient: Sendable {
    public let apiKey: String
    public init(apiKey: String = "") {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func fetch(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("fr,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Kastideo", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            // L'API renvoie un corps JSON explicatif : on le laisse analyser.
            if url.host == "www.googleapis.com" { return data }
            throw XtreamError.badResponse(http.statusCode)
        }
        return data
    }

    public func channelFeed(_ id: String) async throws -> (title: String, videos: [YouTubeVideo]) {
        YouTube.parseFeed(String(decoding: try await fetch(YouTube.feedURL(channelID: id)), as: UTF8.self))
    }

    public func playlistFeed(_ id: String) async throws -> (title: String, videos: [YouTubeVideo]) {
        YouTube.parseFeed(String(decoding: try await fetch(YouTube.feedURL(playlistID: id)), as: UTF8.self))
    }

    /// @pseudo → identifiant de chaîne (page publique, puis l'API si une clé est fournie).
    public func resolveHandle(_ handle: String) async throws -> String {
        let clean = handle.hasPrefix("@") ? handle : "@" + handle
        if let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
           let url = URL(string: "https://www.youtube.com/" + encoded),
           let data = try? await fetch(url),
           let id = YouTube.channelID(fromPage: String(decoding: data, as: UTF8.self)) {
            return id
        }
        if !apiKey.isEmpty {
            var c = URLComponents(string: "https://www.googleapis.com/youtube/v3/channels")!
            c.queryItems = [URLQueryItem(name: "part", value: "id"), URLQueryItem(name: "forHandle", value: clean),
                            URLQueryItem(name: "key", value: apiKey)]
            if let root = try JSONSerialization.jsonObject(with: try await fetch(c.url!)) as? [String: Any],
               let id = (root["items"] as? [[String: Any]])?.first?["id"] as? String {
                return id
            }
        }
        throw YouTubeError.notFound
    }

    public func search(_ query: String, order: YouTubeOrder = .relevance, pageToken: String? = nil) async throws -> YouTubeSearchPage {
        guard !apiKey.isEmpty else { throw YouTubeError.noKey }
        return try YouTube.parseSearch(try await fetch(YouTube.searchURL(query: query, apiKey: apiKey, order: order, pageToken: pageToken)))
    }

    /// Titre et chaîne d'une vidéo (service oEmbed public, sans clé).
    public func describe(videoID: String) async -> YouTubeVideo {
        var c = URLComponents(string: "https://www.youtube.com/oembed")!
        c.queryItems = [URLQueryItem(name: "url", value: "https://www.youtube.com/watch?v=\(videoID)"), URLQueryItem(name: "format", value: "json")]
        if let url = c.url, let data = try? await fetch(url),
           let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return YouTubeVideo(id: videoID, title: root["title"] as? String ?? videoID, channel: root["author_name"] as? String ?? "")
        }
        return YouTubeVideo(id: videoID, title: videoID)
    }
}
