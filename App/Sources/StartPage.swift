import SwiftUI
import KastideoCore

/// Page de départ de Direct, Films et Séries : ce qui s'affiche en ouvrant la section depuis une autre.
/// Valeurs mémorisées par type de contenu : « all » (tout), « favorites », « recents », « last » (dernière catégorie
/// consultée) ou « category:<nom affiché> ».
enum StartPage {
    static func key(_ kind: MediaKind) -> String { "start.\(kind.rawValue)" }
    static func lastKey(_ kind: MediaKind) -> String { "start.last.\(kind.rawValue)" }

    static func categoryValue(_ name: String) -> String { "category:\(name)" }

    /// Section à afficher en entrant dans [kind]. Une catégorie disparue (masquée, renommée) donne la liste complète.
    static func destination(for kind: MediaKind, categories: [String]) -> Browse {
        let defaults = UserDefaults.standard
        let value = defaults.string(forKey: key(kind)) ?? "all"
        switch value {
        case "favorites": return .favorites
        case "recents": return .recents
        case "last":
            if let name = defaults.string(forKey: lastKey(kind)), categories.contains(name) { return .category(kind, name) }
            return .all(kind)
        default:
            if value.hasPrefix("category:") {
                let name = String(value.dropFirst("category:".count))
                if categories.contains(name) { return .category(kind, name) }
            }
            return .all(kind)
        }
    }
}

/// Réglages > Général > Page de départ.
struct StartPageSettingsSection: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage("start.live") private var live = "all"
    @AppStorage("start.movie") private var movie = "all"
    @AppStorage("start.series") private var series = "all"

    var body: some View {
        Section("Page de départ") {
            picker(.live, $live)
            picker(.movie, $movie)
            picker(.series, $series)
            Text("Page affichée en ouvrant Direct, Films ou Séries depuis une autre section. « Dernière consultée » reprend la catégorie où vous étiez. Clic droit sur une catégorie de la barre latérale : « Définir comme catégorie de départ ».")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func picker(_ kind: MediaKind, _ selection: Binding<String>) -> some View {
        let names = store.categoriesByKind[kind] ?? []
        let current = selection.wrappedValue
        let missing: String? = current.hasPrefix("category:") && !names.contains(String(current.dropFirst("category:".count)))
            ? String(current.dropFirst("category:".count)) : nil
        return Picker(kind.title, selection: selection) {
            Text("Toutes").tag("all")
            Text("Favoris").tag("favorites")
            Text("Récents").tag("recents")
            Text("Dernière consultée").tag("last")
            Divider()
            ForEach(names, id: \.self) { name in
                Text(name).tag(StartPage.categoryValue(name))
            }
            if let missing {
                Text(missing).tag(current)
            }
        }
    }
}
