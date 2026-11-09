import Foundation
import KastideoCore

/// Fichier de configuration Kastideo, commun au Mac, à Windows et à Linux (format JSON « kastideo-export » v1) :
/// sources (avec ou sans mots de passe), favoris, récents, catégories personnalisées et quelques réglages.
/// Les favoris et récents sont notés par rapport à leur source (« numéro de source|identifiant »),
/// car chaque appareil attribue ses propres identifiants de source.
struct KastideoExport: Codable {
    var format = "kastideo-export"
    var version = 1
    var exportedAt = Date()
    var app = "mac"
    var sources: [ExportedSource] = []
    var favorites: [String] = []
    var recents: [String] = []
    var categories: [String: ExportedCategories] = [:]
    var settings: [String: String] = [:]
    /// Fiches corrigées à la main (« numéro de source|identifiant » → correction).
    var fiches: [String: FicheEdit]?

    struct ExportedSource: Codable {
        var name: String
        /// « xtream », « m3uUrl », « folder » (chemins, un par ligne), « jellyfin », « emby » ou « plex »
        /// (les fichiers M3U locaux ne sont pas exportables).
        var kind: String
        var address: String
        var username: String?
        var password: String?
        /// Jeton d'un serveur Plex.
        var token: String?
        var epgUrl: String?
        var enabled: Bool
    }

    struct ExportedCategories: Codable {
        var order: [String] = []
        var hidden: [String] = []
        var renames: [String: String] = [:]
        var keywords: [String] = []
    }

    static let kindNames: [MediaKind: String] = [.live: "live", .movie: "movie", .series: "series"]
}

/// Résultat d'une importation (affiché à l'utilisateur).
struct ImportSummary {
    var sourcesAdded = 0
    var sourcesSkipped = 0
    var favoritesAdded = 0
    var categoriesImported = 0
}

/// Corrections de fiches enregistrées (UserDefaults), partagées avec l'export de configuration.
enum FicheEdits {
    static let key = "fiches.edits.v1"
    private static let legacyKey = "local.tmdbFixes.v1"

    static func load() -> [String: FicheEdit] {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: key), let decoded = try? JSONDecoder().decode([String: FicheEdit].self, from: data) {
            return decoded
        }
        // Anciennes versions : seulement l'identifiant TMDB choisi.
        if let old = defaults.dictionary(forKey: legacyKey) as? [String: String] {
            return old.mapValues { FicheEdit(tmdbID: $0) }
        }
        return [:]
    }

    static func save(_ edits: [String: FicheEdit]) {
        if let data = try? JSONEncoder().encode(edits) { UserDefaults.standard.set(data, forKey: key) }
    }
}
