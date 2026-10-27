import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Erreur d'un serveur Jellyfin, Emby ou Plex.
public enum MediaServerError: LocalizedError, Equatable {
    case missingAddress
    case invalidAddress
    /// Code HTTP et diagnostic (requête sans jeton et réponse exacte du serveur).
    case accessDenied(Int, detail: String = "")
    case badResponse(Int, detail: String = "")
    case unreadable
    case noUser
    case plexUnavailable
    case missingToken

    public var errorDescription: String? {
        switch self {
        case .missingAddress: return "Adresse du serveur manquante."
        case .invalidAddress: return "Adresse du serveur invalide."
        case .accessDenied(let code, _): return "Accès refusé par le serveur (HTTP \(code)) : vérifiez l'identifiant, le mot de passe ou le jeton."
        case .badResponse(let code, let detail):
            let reply = detail.components(separatedBy: " : ").dropFirst().joined(separator: " : ")
            return reply.isEmpty ? "Le serveur a répondu HTTP \(code)." : "Le serveur a répondu HTTP \(code) : \(reply.prefix(160))"

        case .unreadable: return "Réponse du serveur illisible."
        case .noUser: return "Aucun utilisateur sur ce serveur."
        case .plexUnavailable: return "plex.tv n'a pas répondu."
        case .missingToken: return "Connectez-vous à Plex ou saisissez le jeton du serveur."
        }
    }

    public var isAccessDenied: Bool {
        if case .accessDenied = self { return true }
        return false
    }

    /// Code HTTP renvoyé par le serveur, s'il y en a un.
    public var status: Int? {
        switch self {
        case .accessDenied(let code, _), .badResponse(let code, _): return code
        default: return nil
        }
    }

    /// Diagnostic : requête (sans jeton) et réponse exacte du serveur.
    public var detail: String? {
        switch self {
        case .accessDenied(_, let detail), .badResponse(_, let detail): return detail.isEmpty ? nil : detail
        default: return nil
        }
    }
}

/// Identité de Kastideo auprès des serveurs (un appareil par ordinateur).
public enum KastideoDevice {
    public static var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3.0" }
    /// Nom de l'ordinateur (lu une fois : la résolution du nom peut être lente), réduit aux caractères ASCII :
    /// un accent ou une apostrophe typographique dans un en-tête HTTP fait répondre « 400 » à certains serveurs.
    public static let name: String = {
        #if os(macOS)
        if let name = Host.current().localizedName, !name.isEmpty { return asciiOnly(name) }
        #endif
        return asciiOnly(ProcessInfo.processInfo.hostName.replacingOccurrences(of: ".local", with: ""))
    }()

    public static func asciiOnly(_ text: String) -> String {
        let folded = text.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "‘", with: "'")
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        let kept = folded.unicodeScalars.filter { $0.value >= 32 && $0.value < 127 && $0 != "\"" }
        let result = String(String.UnicodeScalarView(kept)).trimmingCharacters(in: .whitespaces)
        return result.isEmpty ? "Kastideo" : result
    }
    #if os(macOS)
    public static let platform = "macOS"
    #else
    public static let platform = "Linux"
    #endif
    /// Identifiant stable de l'appareil (empreinte du nom de l'ordinateur et du système).
    public static let id: String = "kastideo-" + stableHash(name + platform.lowercased())
}

/// Session ouverte sur un serveur (jeton d'accès et utilisateur).
public struct ServerSession: Codable, Sendable, Equatable {
    public var token: String
    public var userID: String?
    public init(token: String, userID: String? = nil) {
        self.token = token
        self.userID = userID
    }

    public func encoded() -> String {
        String(data: (try? JSONEncoder().encode(self)) ?? Data(), encoding: .utf8) ?? ""
    }

    public static func decode(_ text: String?) -> ServerSession? {
        guard let text, let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ServerSession.self, from: data)
    }
}

/// Moment de la lecture signalé au serveur.
public enum PlaybackEvent: Sendable {
    case start, progress, pause, stop
}

/// Fonctions communes aux clients Jellyfin / Emby et Plex.
public enum MediaServerHTTP {
    /// Adresse complète. Sans « http:// » ni port, le port habituel est ajouté.
    public static func normalize(_ address: String, type: MediaServerType) throws -> URL {
        var text = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw MediaServerError.missingAddress }
        // Adresse copiée depuis le navigateur (« …:8096/web/index.html#!/home ») : seule la racine du serveur compte.
        if let cut = text.firstIndex(where: { $0 == "#" || $0 == "?" }) { text = String(text[..<cut]) }
        if let web = text.range(of: #"/(web|emby/web)(/.*)?$"#, options: [.regularExpression, .caseInsensitive]) {
            text = String(text[..<web.lowerBound])
        }
        let bare = !text.contains("://")
        if bare { text = "http://" + text }
        while text.hasSuffix("/") { text.removeLast() }
        guard var components = URLComponents(string: text), let host = components.host, !host.isEmpty else {
            throw MediaServerError.invalidAddress
        }
        if bare, components.port == nil { components.port = type.defaultPort }
        guard let url = components.url else { throw MediaServerError.invalidAddress }
        return url
    }

    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        return URLSession(configuration: configuration)
    }()

    /// Requête JSON (corps facultatif). Rend l'objet décodé, ou nil pour une réponse vide.
    static func json(_ method: String, _ url: URL, headers: [String: String] = [:], body: Any? = nil,
                     timeout: TimeInterval = 30) async throws -> Any? {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, error in
                if let error { continuation.resume(throwing: error); return }
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    let detail = diagnostic(method: method, url: url, status: http.statusCode, body: data)
                    if http.statusCode == 401 || http.statusCode == 403 {
                        continuation.resume(throwing: MediaServerError.accessDenied(http.statusCode, detail: detail)); return
                    }
                    continuation.resume(throwing: MediaServerError.badResponse(http.statusCode, detail: detail)); return
                }
                continuation.resume(returning: data ?? Data())
            }.resume()
        }
        guard !data.isEmpty else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    /// « POST http://…/Users/AuthenticateByName → HTTP 400 : réponse » (jetons masqués).
    static func diagnostic(method: String, url: URL, status: Int, body: Data?) -> String {
        var shown = url.absoluteString
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = components.queryItems?.map {
                $0.name.lowercased().contains("token") || $0.name.lowercased() == "api_key" ? URLQueryItem(name: $0.name, value: "…") : $0
            }
            shown = components.url?.absoluteString ?? shown
        }
        let reply = String(decoding: body ?? Data(), as: UTF8.self)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        let short = reply.count > 400 ? String(reply.prefix(400)) + "…" : reply
        return "\(method) \(shown) → HTTP \(status)" + (short.isEmpty ? "" : " : \(short)")
    }

    static func int(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let d = any as? Double { return Int(d) }
        if let s = any as? String { return Int(s) }
        if let n = any as? NSNumber { return n.intValue }
        return nil
    }

    static func string(_ any: Any?) -> String? {
        if let s = any as? String, !s.isEmpty { return s }
        if let i = int(any) { return String(i) }
        return nil
    }

    static func date(_ any: Any?) -> Date? {
        guard let text = any as? String else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: text) { return d }
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: String(text.prefix(19)) + "Z") { return d }
        return f.date(from: text)
    }

    /// Identifiant du contenu chez le serveur (dernière partie de l'identifiant Kastideo).
    public static func serverID(_ item: MediaItem) -> String {
        String(item.id.split(separator: ":").last ?? "")
    }

    static func sortedSeasons(_ bySeason: [Int: [MediaItem]]) -> [SeriesSeason] {
        bySeason.keys.sorted().map { number in
            SeriesSeason(number: number, episodes: (bySeason[number] ?? []).sorted { ($0.number ?? 0) < ($1.number ?? 0) })
        }
    }
}

/// Client d'un serveur multimédia.
public protocol MediaServerClient: Sendable {
    var server: URL { get }
    var sourceID: UUID { get }
    func fetchLibrary() async throws -> SourceContent
    func episodes(of series: MediaItem) async throws -> (seasons: [SeriesSeason], progress: [String: ServerProgress])
    func details(of item: MediaItem) async throws -> MediaDetails?
    func report(_ item: MediaItem, position: Double, duration: Double, event: PlaybackEvent) async throws
    func setPlayed(_ item: MediaItem, played: Bool) async throws
}

// MARK: - Jellyfin / Emby

public struct JellyfinClient: MediaServerClient {
    public let server: URL
    public let sourceID: UUID
    public let session: ServerSession
    public let emby: Bool
    /// Nom de la source, ajouté aux rubriques (« Films · Salon »).
    public var label: String
    /// Rubrique des vidéos personnelles (« Vidéos »), dans la langue de l'interface.
    public var videosLabel: String

    public init(server: URL, sourceID: UUID, session: ServerSession, emby: Bool = false, label: String = "",
                videosLabel: String = "Vidéos") {
        self.server = server
        self.sourceID = sourceID
        self.session = session
        self.emby = emby
        self.label = label
        self.videosLabel = videosLabel
    }

    static func authorization(token: String?, scheme: String = "MediaBrowser") -> String {
        var text = "\(scheme) Client=\"Kastideo\", Device=\"\(KastideoDevice.name)\", DeviceId=\"\(KastideoDevice.id)\", Version=\"\(KastideoDevice.version)\""
        if let token { text += ", Token=\"\(token)\"" }
        return text
    }

    static func headers(token: String?, emby: Bool = false) -> [String: String] {
        var h = ["Authorization": authorization(token: token),
                 "X-Emby-Authorization": authorization(token: token, scheme: emby ? "Emby" : "MediaBrowser")]
        if let token {
            h["X-Emby-Token"] = token
            h["X-MediaBrowser-Token"] = token
        }
        return h
    }

    /// Identification de l'appareil en paramètres d'adresse (forme attendue par Emby).
    static var embyQuery: [URLQueryItem] {
        [URLQueryItem(name: "X-Emby-Client", value: "Kastideo"), URLQueryItem(name: "X-Emby-Device-Name", value: KastideoDevice.name),
         URLQueryItem(name: "X-Emby-Device-Id", value: KastideoDevice.id),
         URLQueryItem(name: "X-Emby-Client-Version", value: KastideoDevice.version)]
    }

    /// Ouverture de session : Jellyfin, ou Emby (identification en paramètres et en-tête « Emby », corps réduit
    /// à Username / Pw ; certains serveurs Emby ne répondent qu'avec le préfixe /emby).
    static func authenticate(server: URL, username: String, password: String, emby: Bool) async throws -> Any? {
        guard emby else {
            return try await MediaServerHTTP.json("POST", server.appendingPathComponent("Users/AuthenticateByName"),
                                                  headers: headers(token: nil), body: ["Username": username, "Pw": password])
        }
        var last: Error = MediaServerError.unreadable
        for prefix in ["", "emby/"] {
            var components = URLComponents(url: server.appendingPathComponent(prefix + "Users/AuthenticateByName"),
                                           resolvingAgainstBaseURL: false)!
            components.queryItems = embyQuery
            do {
                return try await MediaServerHTTP.json("POST", components.url!, headers: headers(token: nil, emby: true),
                                                      body: ["Username": username, "Pw": password])
            } catch let error as MediaServerError where error.status == 400 || error.status == 404 {
                last = error
            }
        }
        throw last
    }

    /// Connexion avec un identifiant et un mot de passe (vide si l'utilisateur n'en a pas ; une clé d'API peut le remplacer).
    public static func signIn(server: URL, username: String, password: String, emby: Bool = false) async throws -> ServerSession {
        do {
            let root = try await authenticate(server: server, username: username, password: password, emby: emby)
            guard let map = root as? [String: Any], let token = map["AccessToken"] as? String else { throw MediaServerError.unreadable }
            return ServerSession(token: token, userID: (map["User"] as? [String: Any])?["Id"] as? String)
        } catch let error as MediaServerError where error.isAccessDenied && password.count >= 24 && !password.contains(" ") {
            // Clé d'API (Tableau de bord > Clés API) : l'utilisateur est retrouvé par son nom.
            let users = try await MediaServerHTTP.json("GET", server.appendingPathComponent("Users"), headers: headers(token: password))
            guard let list = (users as? [[String: Any]]), !list.isEmpty else { throw MediaServerError.noUser }
            let match = list.first { ($0["Name"] as? String ?? "").lowercased() == username.trimmingCharacters(in: .whitespaces).lowercased() }
                ?? list[0]
            return ServerSession(token: password, userID: match["Id"] as? String)
        }
    }

    /// Nom et version du serveur (sans connexion), pour vérifier l'adresse.
    public static func publicInfo(server: URL) async throws -> String? {
        let root = try await MediaServerHTTP.json("GET", server.appendingPathComponent("System/Info/Public"), timeout: 8)
        guard let map = root as? [String: Any] else { return nil }
        let product = map["ProductName"] as? String ?? "Jellyfin/Emby"
        return "\(map["ServerName"] as? String ?? "") (\(product) \(map["Version"] as? String ?? ""))"
            .trimmingCharacters(in: .whitespaces)
    }

    private var user: String { session.userID ?? "" }

    private func get(_ path: String, _ query: [String: String] = [:]) async throws -> Any? {
        var components = URLComponents(url: server.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) } }
        return try await MediaServerHTTP.json("GET", components.url!, headers: Self.headers(token: session.token, emby: emby))
    }

    public func image(_ id: String, type: String = "Primary", height: Int = 450, tag: String? = nil) -> URL? {
        URL(string: "\(server.absoluteString)/Items/\(id)/Images/\(type)?maxHeight=\(height)&quality=85\(tag.map { "&tag=\($0)" } ?? "")")
    }

    public func stream(_ id: String) -> URL? {
        URL(string: "\(server.absoluteString)/Videos/\(id)/stream?static=true&MediaSourceId=\(id)&api_key=\(session.token)")
    }

    private static let fields = "Overview,Genres,ProductionYear,DateCreated,RunTimeTicks,CommunityRating,UserData,PremiereDate"

    private func group(_ library: String) -> String { label.isEmpty ? library : "\(library) · \(label)" }

    static func userData(_ id: String, _ e: [String: Any], into progress: inout [String: ServerProgress]) {
        let data = e["UserData"] as? [String: Any] ?? [:]
        let duration = Double(MediaServerHTTP.int(e["RunTimeTicks"]) ?? 0) / 1e7
        guard duration > 0 else { return }
        if data["Played"] as? Bool == true {
            progress[id] = ServerProgress(position: duration, duration: duration)
        } else {
            let position = Double(MediaServerHTTP.int(data["PlaybackPositionTicks"]) ?? 0) / 1e7
            if position > 0 { progress[id] = ServerProgress(position: position, duration: duration) }
        }
    }

    public func fetchLibrary() async throws -> SourceContent {
        let views = try await get("Users/\(user)/Views")
        let list = (views as? [String: Any])?["Items"] as? [[String: Any]] ?? []
        var items: [MediaItem] = []
        var progress: [String: ServerProgress] = [:]
        let prefix = sourceID.uuidString
        for view in list {
            let type = (view["CollectionType"] as? String ?? "mixed").lowercased()
            // Musique, livres, photos, direct, listes de lecture… ne sont pas des films ou des séries.
            guard ["movies", "tvshows", "homevideos", "mixed", "folders", ""].contains(type), let viewID = view["Id"] as? String else { continue }
            let viewName = view["Name"] as? String ?? "Bibliothèque"
            let root = try await get("Users/\(user)/Items", ["ParentId": viewID, "Recursive": "true", "IncludeItemTypes": "Movie,Series,Video",
                                                             "Fields": Self.fields, "ImageTypeLimit": "1",
                                                             "EnableImageTypes": "Primary,Backdrop", "SortBy": "SortName"])
            for e in (root as? [String: Any])?["Items"] as? [[String: Any]] ?? [] {
                guard let id = e["Id"] as? String else { continue }
                let isSeries = e["Type"] as? String == "Series"
                let year = MediaServerHTTP.int(e["ProductionYear"])
                let name = e["Name"] as? String ?? "?"
                let tag = (e["ImageTags"] as? [String: Any])?["Primary"] as? String
                // Vidéos personnelles (bibliothèque « Vidéos personnelles », éléments de type Video) : rubrique « Vidéos ».
                let personal = e["Type"] as? String == "Video" || type == "homevideos"
                var item = MediaItem(id: "\(prefix):\(isSeries ? "series" : "movie"):\(id)", sourceID: sourceID,
                                     kind: isSeries ? .series : .movie,
                                     name: year != nil && !isSeries ? "\(name) (\(year!))" : name,
                                     group: group(personal ? videosLabel : viewName), logoURL: tag != nil ? image(id, tag: tag) : nil,
                                     streamURL: isSeries ? nil : stream(id), seriesID: isSeries ? id : nil,
                                     info: e["Overview"] as? String, added: MediaServerHTTP.date(e["DateCreated"]))
                item.year = year
                item.genres = (e["Genres"] as? [Any])?.map { "\($0)" }
                items.append(item)
                Self.userData(item.id, e, into: &progress)
            }
        }
        return SourceContent(items: items, epgURL: nil, progress: progress)
    }

    public func episodes(of series: MediaItem) async throws -> (seasons: [SeriesSeason], progress: [String: ServerProgress]) {
        let id = series.seriesID ?? MediaServerHTTP.serverID(series)
        let root = try await get("Shows/\(id)/Episodes", ["UserId": user, "Fields": Self.fields])
        var bySeason: [Int: [MediaItem]] = [:]
        var progress: [String: ServerProgress] = [:]
        for e in (root as? [String: Any])?["Items"] as? [[String: Any]] ?? [] {
            guard let eid = e["Id"] as? String else { continue }
            let season = MediaServerHTTP.int(e["ParentIndexNumber"]) ?? 1
            let number = MediaServerHTTP.int(e["IndexNumber"])
            let tag = (e["ImageTags"] as? [String: Any])?["Primary"] as? String
            var item = MediaItem(id: "\(sourceID.uuidString):episode:\(eid)", sourceID: sourceID, kind: .episode,
                                 name: e["Name"] as? String ?? "Épisode \(number ?? 0)", group: series.name,
                                 logoURL: tag != nil ? image(eid, height: 240, tag: tag) : nil, streamURL: stream(eid),
                                 seriesID: series.seriesID, number: number, info: e["Overview"] as? String)
            item.season = season
            bySeason[season, default: []].append(item)
            Self.userData(item.id, e, into: &progress)
        }
        return (MediaServerHTTP.sortedSeasons(bySeason), progress)
    }

    public func details(of item: MediaItem) async throws -> MediaDetails? {
        let id = MediaServerHTTP.serverID(item)
        guard let root = try await get("Users/\(user)/Items/\(id)") as? [String: Any] else { return nil }
        var d = MediaDetails()
        d.title = root["Name"] as? String
        d.originalTitle = root["OriginalTitle"] as? String
        d.year = MediaServerHTTP.int(root["ProductionYear"])
        d.plot = root["Overview"] as? String
        d.genres = (root["Genres"] as? [Any] ?? []).map { "\($0)" }
        if let rating = root["CommunityRating"] as? Double, rating > 0 { d.rating = rating }
        let minutes = Int((Double(MediaServerHTTP.int(root["RunTimeTicks"]) ?? 0) / 6e8).rounded())
        if minutes > 0 { d.runtime = minutes }
        d.sources = [emby ? "Emby" : "Jellyfin"]
        if (root["ImageTags"] as? [String: Any])?["Primary"] != nil { d.posterURL = image(id) }
        if let backdrops = root["BackdropImageTags"] as? [Any], !backdrops.isEmpty { d.backdropURL = image(id, type: "Backdrop", height: 1080) }
        for person in root["People"] as? [[String: Any]] ?? [] {
            guard let name = person["Name"] as? String else { continue }
            if person["Type"] as? String == "Director" {
                d.directors.append(name)
            } else if person["Type"] as? String == "Actor", d.cast.count < 20 {
                let pid = person["Id"] as? String
                d.cast.append(CastMember(name: name, role: person["Role"] as? String,
                                         photoURL: pid != nil && person["PrimaryImageTag"] != nil ? image(pid!, height: 300) : nil))
            }
        }
        d.tmdbID = MediaServerHTTP.string((root["ProviderIds"] as? [String: Any])?["Tmdb"])
        return d
    }

    public func report(_ item: MediaItem, position: Double, duration: Double, event: PlaybackEvent) async throws {
        let path: String
        switch event {
        case .start: path = "Sessions/Playing"
        case .progress, .pause: path = "Sessions/Playing/Progress"
        case .stop: path = "Sessions/Playing/Stopped"
        }
        _ = try await MediaServerHTTP.json("POST", server.appendingPathComponent(path), headers: Self.headers(token: session.token, emby: emby),
                                           body: ["ItemId": MediaServerHTTP.serverID(item), "PositionTicks": Int(position * 1e7),
                                                  "IsPaused": event == .pause, "CanSeek": true, "PlayMethod": "DirectStream"])
    }

    public func setPlayed(_ item: MediaItem, played: Bool) async throws {
        _ = try await MediaServerHTTP.json(played ? "POST" : "DELETE",
                                           server.appendingPathComponent("Users/\(user)/PlayedItems/\(MediaServerHTTP.serverID(item))"),
                                           headers: Self.headers(token: session.token, emby: emby))
    }
}

// MARK: - Plex

/// Serveur Plex trouvé dans un compte plex.tv.
public struct PlexServer: Sendable, Hashable, Identifiable {
    public var name: String
    public var addresses: [String]
    public var token: String
    public var id: String { name + (addresses.first ?? "") }
}

public struct PlexClient: MediaServerClient {
    public let server: URL
    public let sourceID: UUID
    public let token: String
    public var label: String

    public init(server: URL, sourceID: UUID, token: String, label: String = "") {
        self.server = server
        self.sourceID = sourceID
        self.token = token
        self.label = label
    }

    public static func headers(token: String? = nil) -> [String: String] {
        var h = ["X-Plex-Product": "Kastideo", "X-Plex-Version": KastideoDevice.version, "X-Plex-Client-Identifier": KastideoDevice.id,
                 "X-Plex-Device-Name": KastideoDevice.name, "X-Plex-Platform": KastideoDevice.platform]
        if let token, !token.isEmpty { h["X-Plex-Token"] = token }
        return h
    }

    /// Connexion par code (plex.tv/link) : la page `PlexPin.url` s'ouvre dans le navigateur, puis `poll` rend le jeton.
    public static func createPin() async throws -> PlexPin {
        let root = try await MediaServerHTTP.json("POST", URL(string: "https://plex.tv/api/v2/pins?strong=true")!, headers: headers())
        guard let map = root as? [String: Any], let id = MediaServerHTTP.int(map["id"]), let code = map["code"] as? String else {
            throw MediaServerError.plexUnavailable
        }
        return PlexPin(id: id, code: code)
    }

    /// Serveurs du compte Plex (adresse locale d'abord).
    public static func accountServers(token: String) async throws -> [PlexServer] {
        let root = try await MediaServerHTTP.json("GET", URL(string: "https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=0")!,
                                                  headers: headers(token: token))
        return (root as? [[String: Any]] ?? []).compactMap { r in
            guard (r["provides"] as? String ?? "").contains("server") else { return nil }
            let connections = (r["connections"] as? [[String: Any]] ?? [])
                .sorted { ($0["local"] as? Bool == true ? 1 : 0) > ($1["local"] as? Bool == true ? 1 : 0) }
            return PlexServer(name: r["name"] as? String ?? "Plex", addresses: connections.compactMap { $0["uri"] as? String },
                              token: r["accessToken"] as? String ?? token)
        }
    }

    private func get(_ path: String, _ query: [String: String] = [:]) async throws -> Any? {
        // Chemin écrit tel quel : « /:/timeline » ne doit pas devenir « /%3A/timeline ».
        guard var components = URLComponents(string: server.absoluteString + (path.hasPrefix("/") ? path : "/" + path)) else {
            throw MediaServerError.invalidAddress
        }
        var items = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        // Sans jeton : serveur ouvert au réseau local (Plex > Réseau > « Adresses autorisées sans authentification »).
        if !token.isEmpty { items.append(URLQueryItem(name: "X-Plex-Token", value: token)) }
        components.queryItems = items
        return try await MediaServerHTTP.json("GET", components.url!, headers: Self.headers(token: token))
    }

    /// Nom du serveur (vérifie l'adresse et le jeton).
    public func identity() async throws -> String? {
        ((try await get("/") as? [String: Any])?["MediaContainer"] as? [String: Any])?["friendlyName"] as? String
    }

    private func image(_ thumb: String?, width: Int = 300, height: Int = 450) -> URL? {
        guard let thumb, let encoded = thumb.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else { return nil }
        return URL(string: "\(server.absoluteString)/photo/:/transcode?width=\(width)&height=\(height)&minSize=1&upscale=1&url=\(encoded)\(token.isEmpty ? "" : "&X-Plex-Token=\(token)")")
    }

    private func stream(_ m: [String: Any]) -> URL? {
        guard let media = (m["Media"] as? [[String: Any]])?.first, let part = (media["Part"] as? [[String: Any]])?.first,
              let key = part["key"] as? String else { return nil }
        return URL(string: "\(server.absoluteString)\(key)\(token.isEmpty ? "" : "?X-Plex-Token=\(token)")")
    }

    private static func metadata(_ root: Any?) -> [[String: Any]] {
        ((root as? [String: Any])?["MediaContainer"] as? [String: Any])?["Metadata"] as? [[String: Any]] ?? []
    }

    static func userData(_ id: String, _ m: [String: Any], into progress: inout [String: ServerProgress]) {
        let duration = Double(MediaServerHTTP.int(m["duration"]) ?? 0) / 1000
        guard duration > 0 else { return }
        if (MediaServerHTTP.int(m["viewCount"]) ?? 0) > 0, m["viewOffset"] == nil {
            progress[id] = ServerProgress(position: duration, duration: duration)
        } else {
            let position = Double(MediaServerHTTP.int(m["viewOffset"]) ?? 0) / 1000
            if position > 0 { progress[id] = ServerProgress(position: position, duration: duration) }
        }
    }

    public func fetchLibrary() async throws -> SourceContent {
        let sections = try await get("library/sections")
        let directories = ((sections as? [String: Any])?["MediaContainer"] as? [String: Any])?["Directory"] as? [[String: Any]] ?? []
        var items: [MediaItem] = []
        var progress: [String: ServerProgress] = [:]
        for d in directories {
            let type = d["type"] as? String
            guard type == "movie" || type == "show", let key = MediaServerHTTP.string(d["key"]) else { continue }
            let title = d["title"] as? String ?? "Plex"
            for m in Self.metadata(try await get("library/sections/\(key)/all")) {
                guard let id = MediaServerHTTP.string(m["ratingKey"]) else { continue }
                let show = type == "show"
                let year = MediaServerHTTP.int(m["year"])
                let name = m["title"] as? String ?? "?"
                var item = MediaItem(id: "\(sourceID.uuidString):\(show ? "series" : "movie"):\(id)", sourceID: sourceID,
                                     kind: show ? .series : .movie, name: year != nil && !show ? "\(name) (\(year!))" : name,
                                     group: label.isEmpty ? title : "\(title) · \(label)", logoURL: image(m["thumb"] as? String),
                                     streamURL: show ? nil : stream(m), seriesID: show ? id : nil, info: m["summary"] as? String,
                                     added: MediaServerHTTP.int(m["addedAt"]).map { Date(timeIntervalSince1970: TimeInterval($0)) })
                item.year = year
                let genres = (m["Genre"] as? [[String: Any]] ?? []).compactMap { MediaServerHTTP.string($0["tag"]) }
                item.genres = genres.isEmpty ? nil : genres
                items.append(item)
                Self.userData(item.id, m, into: &progress)
            }
        }
        return SourceContent(items: items, epgURL: nil, progress: progress)
    }

    public func episodes(of series: MediaItem) async throws -> (seasons: [SeriesSeason], progress: [String: ServerProgress]) {
        let id = series.seriesID ?? MediaServerHTTP.serverID(series)
        var bySeason: [Int: [MediaItem]] = [:]
        var progress: [String: ServerProgress] = [:]
        for m in Self.metadata(try await get("library/metadata/\(id)/allLeaves")) {
            guard let eid = MediaServerHTTP.string(m["ratingKey"]) else { continue }
            let season = MediaServerHTTP.int(m["parentIndex"]) ?? 1
            let number = MediaServerHTTP.int(m["index"])
            var item = MediaItem(id: "\(sourceID.uuidString):episode:\(eid)", sourceID: sourceID, kind: .episode,
                                 name: m["title"] as? String ?? "Épisode \(number ?? 0)", group: series.name,
                                 logoURL: image(m["thumb"] as? String, width: 400, height: 225), streamURL: stream(m),
                                 seriesID: series.seriesID, number: number, info: m["summary"] as? String)
            item.season = season
            bySeason[season, default: []].append(item)
            Self.userData(item.id, m, into: &progress)
        }
        return (MediaServerHTTP.sortedSeasons(bySeason), progress)
    }

    public func details(of item: MediaItem) async throws -> MediaDetails? {
        guard let m = Self.metadata(try await get("library/metadata/\(MediaServerHTTP.serverID(item))")).first else { return nil }
        func tags(_ key: String) -> [String] { (m[key] as? [[String: Any]] ?? []).compactMap { MediaServerHTTP.string($0["tag"]) } }
        var d = MediaDetails()
        d.title = m["title"] as? String
        d.originalTitle = m["originalTitle"] as? String
        d.year = MediaServerHTTP.int(m["year"])
        d.plot = m["summary"] as? String
        d.tagline = m["tagline"] as? String
        d.genres = tags("Genre")
        d.directors = tags("Director")
        d.rating = (m["audienceRating"] as? Double) ?? (m["rating"] as? Double)
        if let duration = MediaServerHTTP.int(m["duration"]), duration > 0 { d.runtime = Int((Double(duration) / 60000).rounded()) }
        d.posterURL = image(m["thumb"] as? String)
        d.backdropURL = image(m["art"] as? String, width: 1920, height: 1080)
        for role in (m["Role"] as? [[String: Any]] ?? []).prefix(20) {
            d.cast.append(CastMember(name: MediaServerHTTP.string(role["tag"]) ?? "", role: role["role"] as? String,
                                     photoURL: (role["thumb"] as? String).flatMap(URL.init(string:))))
        }
        for guid in m["Guid"] as? [[String: Any]] ?? [] {
            if let id = guid["id"] as? String, id.hasPrefix("tmdb://") { d.tmdbID = String(id.dropFirst(7)) }
        }
        d.sources = ["Plex"]
        return d
    }

    public func report(_ item: MediaItem, position: Double, duration: Double, event: PlaybackEvent) async throws {
        let id = MediaServerHTTP.serverID(item)
        let state: String
        switch event {
        case .start, .progress: state = "playing"
        case .pause: state = "paused"
        case .stop: state = "stopped"
        }
        _ = try await get(":/timeline", ["ratingKey": id, "key": "/library/metadata/\(id)", "state": state,
                                         "time": String(Int(position * 1000)), "duration": String(Int(duration * 1000))])
    }

    public func setPlayed(_ item: MediaItem, played: Bool) async throws {
        _ = try await get(played ? ":/scrobble" : ":/unscrobble",
                          ["identifier": "com.plexapp.plugins.library", "key": MediaServerHTTP.serverID(item)])
    }
}

/// Code de connexion Plex (plex.tv/link).
public struct PlexPin: Sendable {
    public let id: Int
    public let code: String

    /// Page à ouvrir dans le navigateur pour autoriser Kastideo.
    public var url: URL {
        let client = KastideoDevice.id.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? KastideoDevice.id
        return URL(string: "https://app.plex.tv/auth#?clientID=\(client)&code=\(code)&context%5Bdevice%5D%5Bproduct%5D=Kastideo")!
    }

    /// Jeton une fois la connexion acceptée (nil tant qu'elle ne l'est pas).
    public func poll() async throws -> String? {
        let root = try await MediaServerHTTP.json("GET", URL(string: "https://plex.tv/api/v2/pins/\(id)")!, headers: PlexClient.headers())
        return MediaServerHTTP.string((root as? [String: Any])?["authToken"])
    }
}
