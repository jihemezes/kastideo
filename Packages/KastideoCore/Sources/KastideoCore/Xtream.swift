import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Identifiants d'une connexion Xtream Codes.
public struct XtreamCredentials: Sendable, Hashable {
    public var server: URL
    public var username: String
    public var password: String

    public init(server: URL, username: String, password: String) {
        self.server = server
        self.username = username
        self.password = password
    }

    /// Normalise l'adresse saisie : ajoute http:// si besoin, retire « /player_api.php », « /get.php » et la barre finale.
    public static func normalizeServer(_ input: String) -> URL? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
            text = "http://" + text
        }
        guard var components = URLComponents(string: text) else { return nil }
        components.query = nil
        components.fragment = nil
        var path = components.path
        for suffix in ["/player_api.php", "/get.php", "/xmltv.php"] where path.lowercased().hasSuffix(suffix) {
            path = String(path.dropLast(suffix.count))
        }
        while path.hasSuffix("/") { path.removeLast() }
        components.path = path
        guard let url = components.url, url.host != nil else { return nil }
        return url
    }
}

/// Erreurs Xtream remontées à l'utilisateur.
public enum XtreamError: LocalizedError, Equatable {
    case invalidCredentials
    case accountInactive(String)
    case badResponse(Int)
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Identifiant ou mot de passe refusé par le serveur."
        case .accountInactive(let status): return "Compte non actif (statut : \(status))."
        case .badResponse(let code): return "Le serveur a répondu avec le code HTTP \(code)."
        case .invalidData: return "Réponse du serveur illisible."
        }
    }
}

/// Informations de compte renvoyées par le serveur.
public struct XtreamAccount: Sendable, Equatable {
    public var status: String
    public var expiration: Date?
    public var maxConnections: Int?
}

/// Construction des URL et analyse des réponses de l'API Xtream Codes (player_api.php).
public enum XtreamAPI {

    public static func apiURL(_ c: XtreamCredentials, action: String? = nil, extra: [URLQueryItem] = []) -> URL {
        var components = URLComponents(url: c.server.appendingPathComponent("player_api.php"), resolvingAgainstBaseURL: false)!
        var query = [URLQueryItem(name: "username", value: c.username), URLQueryItem(name: "password", value: c.password)]
        if let action { query.append(URLQueryItem(name: "action", value: action)) }
        query += extra
        components.queryItems = query
        return components.url!
    }

    public static func xmltvURL(_ c: XtreamCredentials) -> URL {
        var components = URLComponents(url: c.server.appendingPathComponent("xmltv.php"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "username", value: c.username), URLQueryItem(name: "password", value: c.password)]
        return components.url!
    }

    /// Flux direct au format HLS (.m3u8), lisible nativement par AVPlayer.
    public static func liveURL(_ c: XtreamCredentials, streamID: String, ext: String = "m3u8") -> URL {
        streamURL(c, type: "live", id: streamID, ext: ext)
    }

    public static func movieURL(_ c: XtreamCredentials, streamID: String, ext: String) -> URL {
        streamURL(c, type: "movie", id: streamID, ext: ext)
    }

    public static func episodeURL(_ c: XtreamCredentials, episodeID: String, ext: String) -> URL {
        streamURL(c, type: "series", id: episodeID, ext: ext)
    }

    static func streamURL(_ c: XtreamCredentials, type: String, id: String, ext: String) -> URL {
        let cleanExt = ext.isEmpty ? "mp4" : ext
        return c.server
            .appendingPathComponent(type)
            .appendingPathComponent(c.username)
            .appendingPathComponent(c.password)
            .appendingPathComponent("\(id).\(cleanExt)")
    }

    // MARK: - Analyse

    static func json(_ data: Data) throws -> Any {
        do { return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) }
        catch { throw XtreamError.invalidData }
    }

    public static func parseAccount(_ data: Data) throws -> XtreamAccount {
        guard let root = try json(data) as? [String: Any],
              let user = root["user_info"] as? [String: Any] else { throw XtreamError.invalidData }
        if let auth = string(user["auth"]), auth == "0" { throw XtreamError.invalidCredentials }
        let status = string(user["status"]) ?? "Active"
        let expiration = string(user["exp_date"]).flatMap { Double($0) }.map { Date(timeIntervalSince1970: $0) }
        let account = XtreamAccount(status: status, expiration: expiration,
                                    maxConnections: string(user["max_connections"]).flatMap { Int($0) })
        if status.lowercased() != "active" { throw XtreamError.accountInactive(status) }
        return account
    }

    /// Catégories : identifiant → nom.
    public static func parseCategories(_ data: Data) throws -> [String: String] {
        guard let list = try json(data) as? [[String: Any]] else { return [:] }
        var result: [String: String] = [:]
        for entry in list {
            if let id = string(entry["category_id"]), let name = string(entry["category_name"]) {
                result[id] = name
            }
        }
        return result
    }

    public static func parseLive(_ data: Data, categories: [String: String], sourceID: UUID, credentials c: XtreamCredentials) throws -> [MediaItem] {
        guard let list = try json(data) as? [[String: Any]] else { return [] }
        return list.compactMap { entry in
            guard let streamID = string(entry["stream_id"]) else { return nil }
            let name = string(entry["name"]) ?? "Chaîne \(streamID)"
            return MediaItem(id: "\(sourceID.uuidString):live:\(streamID)", sourceID: sourceID, kind: .live,
                             name: name, group: groupName(entry, categories),
                             logoURL: url(entry["stream_icon"]),
                             streamURL: liveURL(c, streamID: streamID),
                             epgID: string(entry["epg_channel_id"]),
                             number: string(entry["num"]).flatMap { Int($0) })
        }
    }

    public static func parseVOD(_ data: Data, categories: [String: String], sourceID: UUID, credentials c: XtreamCredentials) throws -> [MediaItem] {
        guard let list = try json(data) as? [[String: Any]] else { return [] }
        return list.compactMap { entry in
            guard let streamID = string(entry["stream_id"]) else { return nil }
            let ext = string(entry["container_extension"]) ?? "mp4"
            var info: String?
            if let rating = string(entry["rating"]), rating != "0" { info = "Note : \(rating)" }
            return MediaItem(id: "\(sourceID.uuidString):movie:\(streamID)", sourceID: sourceID, kind: .movie,
                             name: string(entry["name"]) ?? "Film \(streamID)", group: groupName(entry, categories),
                             logoURL: url(entry["stream_icon"]),
                             streamURL: movieURL(c, streamID: streamID, ext: ext), info: info)
        }
    }

    public static func parseSeries(_ data: Data, categories: [String: String], sourceID: UUID) throws -> [MediaItem] {
        guard let list = try json(data) as? [[String: Any]] else { return [] }
        return list.compactMap { entry in
            guard let seriesID = string(entry["series_id"]) else { return nil }
            return MediaItem(id: "\(sourceID.uuidString):series:\(seriesID)", sourceID: sourceID, kind: .series,
                             name: string(entry["name"]) ?? "Série \(seriesID)", group: groupName(entry, categories),
                             logoURL: url(entry["cover"]), seriesID: seriesID, info: string(entry["plot"]))
        }
    }

    /// Épisodes d'une série (get_series_info), regroupés par saison.
    public static func parseSeriesInfo(_ data: Data, seriesName: String, sourceID: UUID, credentials c: XtreamCredentials) throws -> [SeriesSeason] {
        guard let root = try json(data) as? [String: Any] else { throw XtreamError.invalidData }
        var bySeason: [Int: [MediaItem]] = [:]

        func add(_ episode: [String: Any], seasonHint: Int?) {
            guard let episodeID = string(episode["id"]) else { return }
            let season = string(episode["season"]).flatMap { Int($0) } ?? seasonHint ?? 1
            let number = string(episode["episode_num"]).flatMap { Int($0) }
            let ext = string(episode["container_extension"]) ?? "mp4"
            let details = episode["info"] as? [String: Any]
            var title = string(episode["title"]) ?? "Épisode \(number ?? 0)"
            if title.isEmpty { title = "Épisode \(number ?? 0)" }
            let item = MediaItem(id: "\(sourceID.uuidString):episode:\(episodeID)", sourceID: sourceID, kind: .episode,
                                 name: title, group: seriesName,
                                 logoURL: url(details?["movie_image"]),
                                 streamURL: episodeURL(c, episodeID: episodeID, ext: ext),
                                 number: number, info: string(details?["plot"]))
            bySeason[season, default: []].append(item)
        }

        if let dict = root["episodes"] as? [String: Any] {
            for (key, value) in dict {
                for episode in (value as? [[String: Any]]) ?? [] { add(episode, seasonHint: Int(key)) }
            }
        } else if let array = root["episodes"] as? [Any] {
            for (index, value) in array.enumerated() {
                if let list = value as? [[String: Any]] {
                    for episode in list { add(episode, seasonHint: index + 1) }
                } else if let episode = value as? [String: Any] {
                    add(episode, seasonHint: nil)
                }
            }
        }

        return bySeason.keys.sorted().map { season in
            SeriesSeason(number: season, episodes: bySeason[season]!.sorted { ($0.number ?? 0) < ($1.number ?? 0) })
        }
    }

    // MARK: - Utilitaires (les serveurs Xtream mélangent nombres et chaînes)

    static func string(_ any: Any?) -> String? {
        switch any {
        case let s as String:
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        case let i as Int: return String(i)
        case let d as Double: return d == d.rounded() ? String(Int(d)) : String(d)
        case let b as Bool: return b ? "1" : "0"
        case let n as NSNumber: return n.stringValue
        default: return nil
        }
    }

    static func url(_ any: Any?) -> URL? {
        guard let s = string(any), s.lowercased().hasPrefix("http") else { return nil }
        return URL(string: s) ?? s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed).flatMap(URL.init(string:))
    }

    static func groupName(_ entry: [String: Any], _ categories: [String: String]) -> String {
        if let id = string(entry["category_id"]), let name = categories[id] { return name }
        return M3UParser.defaultGroup
    }
}

/// Client réseau Xtream Codes.
public struct XtreamClient: Sendable {
    public let credentials: XtreamCredentials
    public let sourceID: UUID

    public init(credentials: XtreamCredentials, sourceID: UUID) {
        self.credentials = credentials
        self.sourceID = sourceID
    }

    public func account() async throws -> XtreamAccount {
        try XtreamAPI.parseAccount(try await HTTP.get(XtreamAPI.apiURL(credentials)))
    }

    /// Charge chaînes, films et séries. Les sections en erreur sont ignorées si au moins une réussit.
    public func fetchLibrary() async throws -> SourceContent {
        _ = try await account()
        let c = credentials
        let id = sourceID

        async let live: [MediaItem] = {
            let cats = (try? XtreamAPI.parseCategories(try await HTTP.get(XtreamAPI.apiURL(c, action: "get_live_categories")))) ?? [:]
            return try XtreamAPI.parseLive(try await HTTP.get(XtreamAPI.apiURL(c, action: "get_live_streams")), categories: cats, sourceID: id, credentials: c)
        }()
        async let vod: [MediaItem] = {
            let cats = (try? XtreamAPI.parseCategories(try await HTTP.get(XtreamAPI.apiURL(c, action: "get_vod_categories")))) ?? [:]
            return try XtreamAPI.parseVOD(try await HTTP.get(XtreamAPI.apiURL(c, action: "get_vod_streams")), categories: cats, sourceID: id, credentials: c)
        }()
        async let series: [MediaItem] = {
            let cats = (try? XtreamAPI.parseCategories(try await HTTP.get(XtreamAPI.apiURL(c, action: "get_series_categories")))) ?? [:]
            return try XtreamAPI.parseSeries(try await HTTP.get(XtreamAPI.apiURL(c, action: "get_series")), categories: cats, sourceID: id)
        }()

        let liveItems = (try? await live) ?? []
        let vodItems = (try? await vod) ?? []
        let seriesItems = (try? await series) ?? []
        let all = liveItems + vodItems + seriesItems
        if all.isEmpty {
            // Relance la section « Direct » pour remonter l'erreur réelle.
            _ = try await HTTP.get(XtreamAPI.apiURL(c, action: "get_live_streams"))
        }
        return SourceContent(items: all, epgURL: XtreamAPI.xmltvURL(c))
    }

    public func seasons(for series: MediaItem) async throws -> [SeriesSeason] {
        guard let seriesID = series.seriesID else { return [] }
        let data = try await HTTP.get(XtreamAPI.apiURL(credentials, action: "get_series_info",
                                                       extra: [URLQueryItem(name: "series_id", value: seriesID)]))
        return try XtreamAPI.parseSeriesInfo(data, seriesName: series.name, sourceID: sourceID, credentials: credentials)
    }
}

/// Téléchargement HTTP simple, portable (macOS, iOS, tvOS, Linux pour les tests).
public enum HTTP {
    public static let userAgent = "Kastideo/1.0"

    public static func get(_ url: URL, timeout: TimeInterval = 60) async throws -> Data {
        if url.isFileURL { return try Data(contentsOf: url) }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error { continuation.resume(throwing: error); return }
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    continuation.resume(throwing: XtreamError.badResponse(http.statusCode)); return
                }
                continuation.resume(returning: data ?? Data())
            }.resume()
        }
    }
}
