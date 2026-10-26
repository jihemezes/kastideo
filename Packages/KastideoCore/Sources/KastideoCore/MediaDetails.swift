import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Personne au générique d'un film ou d'une série.
public struct CastMember: Sendable, Hashable, Identifiable {
    public var id: String { name + "|" + (role ?? "") }
    public var name: String
    public var role: String?
    public var photoURL: URL?

    public init(name: String, role: String? = nil, photoURL: URL? = nil) {
        self.name = name
        self.role = role
        self.photoURL = photoURL
    }
}

/// Fiche d'un film ou d'une série (fournisseur IPTV et/ou TMDB).
public struct MediaDetails: Sendable, Equatable {
    public var title: String?
    public var originalTitle: String?
    public var year: Int?
    public var plot: String?
    public var tagline: String?
    public var genres: [String] = []
    public var directors: [String] = []
    public var cast: [CastMember] = []
    /// Note sur 10.
    public var rating: Double?
    /// Durée en minutes (film) ou durée d'un épisode (série).
    public var runtime: Int?
    public var seasonCount: Int?
    public var trailerURL: URL?
    public var posterURL: URL?
    public var backdropURL: URL?
    public var tmdbID: String?
    /// Sources utilisées (« IPTV », « TMDB »).
    public var sources: [String] = []

    public init() {}

    public var isEmpty: Bool {
        plot == nil && cast.isEmpty && directors.isEmpty && genres.isEmpty && year == nil && rating == nil
    }

    /// Complète cette fiche avec une autre, plus riche (TMDB) : ses valeurs priment, sauf si elles sont vides.
    public func merged(with better: MediaDetails) -> MediaDetails {
        var r = self
        r.title = better.title ?? title
        r.originalTitle = better.originalTitle ?? originalTitle
        r.year = better.year ?? year
        r.plot = better.plot ?? plot
        r.tagline = better.tagline ?? tagline
        if !better.genres.isEmpty { r.genres = better.genres }
        if !better.directors.isEmpty { r.directors = better.directors }
        if !better.cast.isEmpty { r.cast = better.cast }
        r.rating = better.rating ?? rating
        r.runtime = better.runtime ?? runtime
        r.seasonCount = better.seasonCount ?? seasonCount
        r.trailerURL = better.trailerURL ?? trailerURL
        r.posterURL = better.posterURL ?? posterURL
        r.backdropURL = better.backdropURL ?? backdropURL
        r.tmdbID = better.tmdbID ?? tmdbID
        r.sources = sources + better.sources.filter { !sources.contains($0) }
        return r
    }
}

// MARK: - Xtream

extension XtreamAPI {
    /// Fiche d'un film (`get_vod_info`).
    public static func parseVODDetails(_ data: Data) throws -> MediaDetails {
        guard let root = try json(data) as? [String: Any] else { throw XtreamError.invalidData }
        let info = root["info"] as? [String: Any] ?? [:]
        let movie = root["movie_data"] as? [String: Any] ?? [:]
        var d = details(from: info)
        d.title = string(movie["name"]) ?? string(info["name"])
        if d.runtime == nil, let secs = string(info["duration_secs"]).flatMap(Int.init), secs > 0 { d.runtime = secs / 60 }
        if d.runtime == nil, let text = string(info["duration"]) { d.runtime = minutes(fromClock: text) }
        d.posterURL = url(info["movie_image"]) ?? url(info["cover_big"])
        return d
    }

    /// Fiche d'une série (`get_series_info`).
    public static func parseSeriesDetails(_ data: Data) throws -> MediaDetails {
        guard let root = try json(data) as? [String: Any] else { throw XtreamError.invalidData }
        let info = root["info"] as? [String: Any] ?? [:]
        var d = details(from: info)
        d.title = string(info["name"])
        d.posterURL = url(info["cover"])
        if d.runtime == nil, let run = string(info["episode_run_time"]).flatMap(Int.init), run > 0 { d.runtime = run }
        if let seasons = root["episodes"] as? [String: Any], !seasons.isEmpty { d.seasonCount = seasons.count }
        return d
    }

    static func details(from info: [String: Any]) -> MediaDetails {
        var d = MediaDetails()
        d.originalTitle = string(info["o_name"])
        d.plot = string(info["plot"]) ?? string(info["description"])
        d.genres = list(info["genre"])
        d.directors = list(info["director"])
        d.cast = list(info["cast"] ?? info["actors"]).map { CastMember(name: $0) }
        if let rating = string(info["rating"]).flatMap({ Double($0.replacingOccurrences(of: ",", with: ".")) }), rating > 0 {
            d.rating = min(rating, 10)
        }
        let release = string(info["releasedate"]) ?? string(info["releaseDate"]) ?? string(info["release_date"]) ?? string(info["year"])
        d.year = release.flatMap(year(in:))
        if let trailer = string(info["youtube_trailer"]) {
            d.trailerURL = trailer.lowercased().hasPrefix("http") ? URL(string: trailer) : URL(string: "https://www.youtube.com/watch?v=\(trailer)")
        }
        if let backdrops = info["backdrop_path"] as? [Any] {
            d.backdropURL = backdrops.lazy.compactMap { url($0) }.first
        } else {
            d.backdropURL = url(info["backdrop_path"])
        }
        d.tmdbID = string(info["tmdb_id"]) ?? string(info["tmdb"])
        if d.tmdbID == "0" { d.tmdbID = nil }
        d.sources = ["IPTV"]
        return d
    }

    static func list(_ any: Any?) -> [String] {
        guard let text = string(any) else { return [] }
        return text.split(whereSeparator: { $0 == "," || $0 == "/" || $0 == "|" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func year(in text: String) -> Int? {
        guard let range = text.range(of: #"(19|20)\d{2}"#, options: .regularExpression) else { return nil }
        return Int(text[range])
    }

    static func minutes(fromClock text: String) -> Int? {
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        let total = parts.count == 3 ? parts[0] * 60 + parts[1] : parts[0]
        return total > 0 ? total : nil
    }
}

extension XtreamClient {
    public func movieDetails(streamID: String) async throws -> MediaDetails {
        let data = try await HTTP.get(XtreamAPI.apiURL(credentials, action: "get_vod_info",
                                                       extra: [URLQueryItem(name: "vod_id", value: streamID)]), timeout: 20)
        return try XtreamAPI.parseVODDetails(data)
    }

    public func seriesDetails(seriesID: String) async throws -> MediaDetails {
        let data = try await HTTP.get(XtreamAPI.apiURL(credentials, action: "get_series_info",
                                                       extra: [URLQueryItem(name: "series_id", value: seriesID)]), timeout: 20)
        return try XtreamAPI.parseSeriesDetails(data)
    }
}

// MARK: - TMDB (The Movie Database)

public enum TMDB {
    static let base = URL(string: "https://api.themoviedb.org/3")!
    static let images = "https://image.tmdb.org/t/p/"

    /// Nettoie un titre IPTV (« FR - Dune (2021) 4K », « |VF| Dune [MULTI] ») pour la recherche.
    public static func cleanTitle(_ raw: String) -> (title: String, year: Int?) {
        var text = raw
        // Préfixes de langue / pays : « FR - », « FR: », « |FR| », « [FR] ».
        text = text.replacingOccurrences(of: #"^\s*(\|[^|]{1,12}\||\[[^\]]{1,12}\])\s*"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"^\s*(FR|FRA|FRENCH|EN|ENG|US|UK|VF|VFF|VFQ|VO|VOST|VOSTFR|MULTI|4K|UHD|FHD|HD|NF|AMZ|DSNP|DE|ES|IT|PT|AR|TR|BE|CA|QC|CH)\s*[-:|]\s*"#,
                                         with: "", options: [.regularExpression, .caseInsensitive])
        var year: Int?
        if let range = text.range(of: #"[\(\[]\s*(19|20)\d{2}\s*[\)\]]"#, options: .regularExpression) {
            year = XtreamAPI.year(in: String(text[range]))
            text.removeSubrange(range)
        } else if let range = text.range(of: #"\s(19|20)\d{2}\s*$"#, options: .regularExpression) {
            year = XtreamAPI.year(in: String(text[range]))
            text.removeSubrange(range)
        }
        text = text.replacingOccurrences(of: #"[\[\(][^\]\)]*[\]\)]"#, with: " ", options: .regularExpression)
        let tags = #"\b(4K|UHD|FHD|HD|SD|HDR|HEVC|H265|x265|1080p|720p|2160p|MULTI|VOSTFR|VOST|VF|VFF|VFQ|VO|TRUEFRENCH|FRENCH)\b"#
        text = text.replacingOccurrences(of: tags, with: " ", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-:|")))
        return (text.isEmpty ? raw : text, year)
    }

    /// Analyse la réponse de `/movie/{id}` ou `/tv/{id}` avec `append_to_response=credits,videos`.
    public static func parseDetails(_ data: Data, isSeries: Bool) throws -> MediaDetails {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw XtreamError.invalidData }
        var d = MediaDetails()
        let s = XtreamAPI.string
        d.tmdbID = s(root["id"])
        d.title = s(root[isSeries ? "name" : "title"])
        d.originalTitle = s(root[isSeries ? "original_name" : "original_title"])
        d.plot = s(root["overview"])
        d.tagline = s(root["tagline"])
        d.year = s(root[isSeries ? "first_air_date" : "release_date"]).flatMap(XtreamAPI.year(in:))
        d.genres = (root["genres"] as? [[String: Any]] ?? []).compactMap { s($0["name"]) }
        if let vote = root["vote_average"] as? Double, vote > 0 { d.rating = vote }
        if isSeries {
            d.runtime = (root["episode_run_time"] as? [Int])?.first
            d.seasonCount = root["number_of_seasons"] as? Int
            d.directors = (root["created_by"] as? [[String: Any]] ?? []).compactMap { s($0["name"]) }
        } else if let runtime = root["runtime"] as? Int, runtime > 0 {
            d.runtime = runtime
        }
        d.posterURL = s(root["poster_path"]).flatMap { URL(string: images + "w500" + $0) }
        d.backdropURL = s(root["backdrop_path"]).flatMap { URL(string: images + "w1280" + $0) }
        if let credits = root["credits"] as? [String: Any] {
            d.cast = (credits["cast"] as? [[String: Any]] ?? []).prefix(15).compactMap { person in
                guard let name = s(person["name"]) else { return nil }
                return CastMember(name: name, role: s(person["character"]),
                                  photoURL: s(person["profile_path"]).flatMap { URL(string: images + "w185" + $0) })
            }
            if !isSeries {
                d.directors = (credits["crew"] as? [[String: Any]] ?? [])
                    .filter { s($0["job"]) == "Director" }.compactMap { s($0["name"]) }
            }
        }
        if let videos = (root["videos"] as? [String: Any])?["results"] as? [[String: Any]] {
            let youtube = videos.filter { s($0["site"]) == "YouTube" }
            let trailer = youtube.first { s($0["type"]) == "Trailer" } ?? youtube.first
            if let key = trailer.flatMap({ s($0["key"]) }) { d.trailerURL = URL(string: "https://www.youtube.com/watch?v=\(key)") }
        }
        d.sources = ["TMDB"]
        return d
    }

    /// Premier identifiant d'une réponse de recherche, en privilégiant l'année indiquée.
    public static func parseSearch(_ data: Data, year: Int?, isSeries: Bool) -> String? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = root["results"] as? [[String: Any]], !results.isEmpty else { return nil }
        if let year {
            let key = isSeries ? "first_air_date" : "release_date"
            if let match = results.first(where: { XtreamAPI.string($0[key]).flatMap(XtreamAPI.year(in:)) == year }) {
                return XtreamAPI.string(match["id"])
            }
        }
        return XtreamAPI.string(results[0]["id"])
    }
}

/// Résultat d'une recherche TMDB (correction d'une fiche).
public struct TMDBMatch: Sendable, Hashable, Identifiable {
    public var tmdbID: String
    public var title: String
    public var year: Int?
    public var posterURL: URL?
    public var overview: String?
    public var id: String { tmdbID }

    public init(tmdbID: String, title: String, year: Int? = nil, posterURL: URL? = nil, overview: String? = nil) {
        self.tmdbID = tmdbID
        self.title = title
        self.year = year
        self.posterURL = posterURL
        self.overview = overview
    }
}

extension TMDB {
    /// Résultats d'une réponse de `/search/{movie|tv}` (12 au plus).
    public static func parseMatches(_ data: Data, isSeries: Bool) -> [TMDBMatch] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = root["results"] as? [[String: Any]] else { return [] }
        let s = XtreamAPI.string
        return results.prefix(12).compactMap { r in
            guard let id = s(r["id"]) else { return nil }
            return TMDBMatch(tmdbID: id, title: s(r[isSeries ? "name" : "title"]) ?? "?",
                             year: s(r[isSeries ? "first_air_date" : "release_date"]).flatMap(XtreamAPI.year(in:)),
                             posterURL: s(r["poster_path"]).flatMap { URL(string: images + "w342" + $0) },
                             overview: s(r["overview"]))
        }
    }
}

/// Film ou série en tendance sur TMDB.
public struct TMDBTrend: Sendable, Hashable {
    public var tmdbID: String
    public var title: String
    public var originalTitle: String?
    public var year: Int?
    public var backdropURL: URL?

    public init(tmdbID: String, title: String, originalTitle: String? = nil, year: Int? = nil, backdropURL: URL? = nil) {
        self.tmdbID = tmdbID
        self.title = title
        self.originalTitle = originalTitle
        self.year = year
        self.backdropURL = backdropURL
    }
}

extension TMDB {
    /// Réponse de `/trending/{movie|tv}/week`.
    public static func parseTrending(_ data: Data, isSeries: Bool) -> [TMDBTrend] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = root["results"] as? [[String: Any]] else { return [] }
        let s = XtreamAPI.string
        return results.compactMap { entry in
            guard let id = s(entry["id"]), let title = s(entry[isSeries ? "name" : "title"]) else { return nil }
            return TMDBTrend(tmdbID: id, title: title,
                             originalTitle: s(entry[isSeries ? "original_name" : "original_title"]),
                             year: s(entry[isSeries ? "first_air_date" : "release_date"]).flatMap(XtreamAPI.year(in:)),
                             backdropURL: s(entry["backdrop_path"]).flatMap { URL(string: images + "w1280" + $0) })
        }
    }

    /// Clé de comparaison d'un titre (catalogue IPTV ou TMDB) : sans étiquettes, accents ni ponctuation.
    public static func titleKey(_ raw: String) -> String {
        let cleaned = cleanTitle(raw).title
        let folded = cleaned.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased()
        return folded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined()
    }
}

/// Client de l'API TMDB (clé v3 ou jeton de lecture v4).
public struct TMDBClient: Sendable {
    public let apiKey: String
    public let language: String

    public init(apiKey: String, language: String) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.language = language
    }

    private var usesBearer: Bool { apiKey.hasPrefix("eyJ") }

    func request(_ path: String, _ query: [URLQueryItem]) async throws -> Data {
        var components = URLComponents(url: TMDB.base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        var items = query + [URLQueryItem(name: "language", value: language)]
        if !usesBearer { items.append(URLQueryItem(name: "api_key", value: apiKey)) }
        components.queryItems = items
        var request = URLRequest(url: components.url!, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if usesBearer { request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw XtreamError.badResponse(http.statusCode)
        }
        return data
    }

    /// Fiche complète (identifiant TMDB connu, sinon recherche par titre nettoyé et année).
    public func details(title: String, isSeries: Bool, tmdbID: String?, year: Int? = nil) async throws -> MediaDetails? {
        let kind = isSeries ? "tv" : "movie"
        var id = tmdbID
        if id == nil {
            let cleaned = TMDB.cleanTitle(title)
            let wanted = year ?? cleaned.year
            var query = [URLQueryItem(name: "query", value: cleaned.title)]
            if let wanted { query.append(URLQueryItem(name: isSeries ? "first_air_date_year" : "year", value: String(wanted))) }
            id = TMDB.parseSearch(try await request("search/\(kind)", query), year: wanted, isSeries: isSeries)
            if id == nil, wanted != nil {
                id = TMDB.parseSearch(try await request("search/\(kind)", [URLQueryItem(name: "query", value: cleaned.title)]),
                                      year: nil, isSeries: isSeries)
            }
        }
        guard let id else { return nil }
        let data = try await request("\(kind)/\(id)", [URLQueryItem(name: "append_to_response", value: "credits,videos"),
                                                            URLQueryItem(name: "include_video_language",
                                                                         value: "\(language.prefix(2)),en,null")])
        return try TMDB.parseDetails(data, isSeries: isSeries)
    }

    /// Recherche par titre (et année), pour choisir la bonne fiche à la main.
    public func search(title: String, isSeries: Bool, year: Int? = nil) async throws -> [TMDBMatch] {
        let kind = isSeries ? "tv" : "movie"
        let cleaned = TMDB.cleanTitle(title)
        let wanted = year ?? cleaned.year
        var query = [URLQueryItem(name: "query", value: cleaned.title)]
        if let wanted { query.append(URLQueryItem(name: isSeries ? "first_air_date_year" : "year", value: String(wanted))) }
        var matches = TMDB.parseMatches(try await request("search/\(kind)", query), isSeries: isSeries)
        if matches.isEmpty, wanted != nil {
            matches = TMDB.parseMatches(try await request("search/\(kind)", [URLQueryItem(name: "query", value: cleaned.title)]),
                                        isSeries: isSeries)
        }
        return matches
    }

    /// Films ou séries en tendance cette semaine (2 pages, ~40 titres).
    public func trending(isSeries: Bool) async throws -> [TMDBTrend] {
        var all: [TMDBTrend] = []
        for page in 1...2 {
            let data = try await request("trending/\(isSeries ? "tv" : "movie")/week", [URLQueryItem(name: "page", value: String(page))])
            all += TMDB.parseTrending(data, isSeries: isSeries)
        }
        return all
    }

    /// Vérifie la clé (réglages).
    public func check() async -> Bool {
        (try? await request("configuration", [])) != nil
    }
}
