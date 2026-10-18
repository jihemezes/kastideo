import Foundation

/// Type de contenu lisible.
public enum MediaKind: String, Codable, CaseIterable, Sendable {
    case live      // chaîne en direct
    case movie     // film / VOD
    case series    // série (Xtream : nécessite le chargement des épisodes ; M3U : épisode lisible directement)
    case episode   // épisode d'une série Xtream

    public var label: String {
        switch self {
        case .live: return "Direct"
        case .movie: return "Films"
        case .series: return "Séries"
        case .episode: return "Épisodes"
        }
    }
}

/// Élément de la bibliothèque : chaîne, film, série ou épisode.
public struct MediaItem: Identifiable, Hashable, Codable, Sendable {
    /// Identifiant stable entre deux rafraîchissements (sert aux favoris).
    public var id: String
    public var sourceID: UUID
    public var kind: MediaKind
    public var name: String
    public var group: String
    public var logoURL: URL?
    /// URL du flux. `nil` pour une série Xtream (il faut charger les épisodes).
    public var streamURL: URL?
    /// Identifiant de chaîne dans le guide TV (tvg-id / epg_channel_id).
    public var epgID: String?
    /// Identifiant de série Xtream.
    public var seriesID: String?
    /// Numéro de chaîne éventuel.
    public var number: Int?
    /// Résumé / informations complémentaires.
    public var info: String?

    public init(id: String, sourceID: UUID, kind: MediaKind, name: String, group: String,
                logoURL: URL? = nil, streamURL: URL? = nil, epgID: String? = nil,
                seriesID: String? = nil, number: Int? = nil, info: String? = nil) {
        self.id = id
        self.sourceID = sourceID
        self.kind = kind
        self.name = name
        self.group = group
        self.logoURL = logoURL
        self.streamURL = streamURL
        self.epgID = epgID
        self.seriesID = seriesID
        self.number = number
        self.info = info
    }

    /// Nom normalisé pour la recherche (sans casse ni accents).
    public var searchKey: String { name.kastideoSearchKey }

    /// Vrai si l'élément ouvre une liste d'épisodes plutôt qu'un lecteur.
    public var needsEpisodes: Bool { kind == .series && streamURL == nil && seriesID != nil }
}

/// Type de source ajoutée par l'utilisateur.
public enum SourceKind: Codable, Hashable, Sendable {
    /// Playlist M3U/M3U8 distante.
    case m3uURL(URL)
    /// Playlist M3U locale (signet de sécurité pour la relire dans le bac à sable).
    case m3uFile(bookmark: Data, displayName: String)
    /// Connexion Xtream Codes (serveur + identifiant ; le mot de passe est dans le trousseau).
    case xtream(server: URL, username: String)

    public var typeLabel: String {
        switch self {
        case .m3uURL: return "Playlist M3U (URL)"
        case .m3uFile: return "Playlist M3U (fichier)"
        case .xtream: return "Xtream Codes"
        }
    }
}

/// Source de contenus configurée par l'utilisateur.
public struct Source: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: SourceKind
    /// URL de guide TV XMLTV saisie par l'utilisateur (prioritaire sur celle de la playlist).
    public var epgURL: URL?
    public var isEnabled: Bool
    public var lastRefresh: Date?

    public init(id: UUID = UUID(), name: String, kind: SourceKind, epgURL: URL? = nil,
                isEnabled: Bool = true, lastRefresh: Date? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.epgURL = epgURL
        self.isEnabled = isEnabled
        self.lastRefresh = lastRefresh
    }
}

/// Contenu chargé d'une source (mis en cache sur disque pour un démarrage rapide).
public struct SourceContent: Codable, Sendable {
    public var items: [MediaItem]
    /// URL de guide TV annoncée par la playlist ou le serveur.
    public var epgURL: URL?
    public var loadedAt: Date

    public init(items: [MediaItem], epgURL: URL?, loadedAt: Date = Date()) {
        self.items = items
        self.epgURL = epgURL
        self.loadedAt = loadedAt
    }
}

/// Saison d'une série Xtream.
public struct SeriesSeason: Identifiable, Hashable, Sendable {
    public var number: Int
    public var episodes: [MediaItem]
    public var id: Int { number }

    public init(number: Int, episodes: [MediaItem]) {
        self.number = number
        self.episodes = episodes
    }
}

extension String {
    /// Clé de recherche : minuscules, sans accents, espaces réduits.
    public var kastideoSearchKey: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "fr_FR"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
