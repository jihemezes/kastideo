import SwiftUI
import AppKit
import UniformTypeIdentifiers
import KastideoCore

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
            mediaInfo.reloadEdits()
            if let key = export.settings["tmdbKey"], !key.isEmpty, !mediaInfo.usesTMDB { mediaInfo.tmdbKey = key }
            message = String(localized: "Importation terminée : \(summary.sourcesAdded) source(s) ajoutée(s), \(summary.sourcesSkipped) déjà présente(s), \(summary.favoritesAdded) favori(s), catégories de \(summary.categoriesImported) section(s).")
        } catch {
            message = String(localized: "Fichier illisible : \(error.localizedDescription)")
        }
    }
}
