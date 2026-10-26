import SwiftUI
import AppKit
import UniformTypeIdentifiers
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

extension MediaInfoStore {
    static var storedTMDBKey: String? { Keychain.get(account: "tmdb.apiKey") }
}

/// Réglages > Général > Sauvegarde : exporter / importer la configuration.
struct ConfigTransferSection: View {
    @Environment(LibraryStore.self) private var store
    @Environment(MediaInfoStore.self) private var mediaInfo
    @State private var includePasswords = true
    @State private var message: String?

    var body: some View {
        Section("Sauvegarde et transfert") {
            Toggle("Inclure les mots de passe dans le fichier", isOn: $includePasswords)
            Text("Le fichier permet de retrouver vos sources, favoris, récents, catégories et réglages sur un autre Mac, ou dans Kastideo pour Windows et Linux. S'il contient les mots de passe, gardez-le en lieu sûr.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button("Exporter la configuration…", action: exportConfig)
                Button("Importer une configuration…", action: importConfig)
            }
            if let message {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func exportConfig() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Kastideo-configuration.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let export = store.makeExport(includePasswords: includePasswords)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(export).write(to: url, options: .atomic)
            message = String(localized: "Configuration exportée : \(export.sources.count) source(s), \(export.favorites.count) favori(s).")
        } catch {
            message = String(localized: "Exportation impossible : \(error.localizedDescription)")
        }
    }

    private func importConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(KastideoExport.self, from: Data(contentsOf: url))
            guard export.format == "kastideo-export" else {
                message = String(localized: "Ce fichier n'est pas une configuration Kastideo.")
                return
            }
            let summary = store.importConfig(export)
            if let key = export.settings["tmdbKey"], !key.isEmpty, !mediaInfo.usesTMDB { mediaInfo.tmdbKey = key }
            message = String(localized: "Importation terminée : \(summary.sourcesAdded) source(s) ajoutée(s), \(summary.sourcesSkipped) déjà présente(s), \(summary.favoritesAdded) favori(s), catégories de \(summary.categoriesImported) section(s).")
        } catch {
            message = String(localized: "Fichier illisible : \(error.localizedDescription)")
        }
    }
}
