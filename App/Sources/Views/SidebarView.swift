import SwiftUI
import KastideoCore

struct SidebarView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(RecordingCenter.self) private var recordings
    @Environment(NavigationModel.self) private var navigation
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var navigation = navigation
        let _ = navigation.mark("Barre latérale")
        List(selection: $navigation.browse) {
            Section("Bibliothèque") {
                row(.home, icon: "house", count: nil)
                row(.all(.live), icon: "dot.radiowaves.left.and.right", count: store.count(for: .live))
                row(.themes, icon: "square.grid.2x2", count: nil)
                row(.all(.movie), icon: "film", count: store.count(for: .movie))
                row(.all(.series), icon: "rectangle.stack", count: store.count(for: .series))
                row(.favorites, icon: "star", count: store.favoriteIDs.count)
                row(.recents, icon: "clock.arrow.circlepath", count: nil)
                row(.guide, icon: "calendar", count: nil)
                if store.hasLibrary {
                    row(.library, icon: "photo.stack", count: store.libraryItems().count)
                }
                row(.recordings, icon: recordings.activeLive != nil ? "record.circle.fill" : "record.circle",
                    count: recordings.activityCount)
            }

            let kind = navigation.lastKind
            if store.hasLibrary, kind == .movie || kind == .series {
                // Films et séries de l'IPTV, de « Mes vidéos » (dossiers, serveurs), ou des deux.
                Section {
                    Picker("Afficher", selection: Binding(get: { store.catalogOrigin }, set: { store.catalogOrigin = $0 })) {
                        ForEach(CatalogOrigin.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .help("Films et séries de l'abonnement IPTV, de vos dossiers et serveurs (Mes vidéos), ou des deux")
                }
            }
            let categories = store.categoriesByKind[kind] ?? []
            if !categories.isEmpty {
                Section {
                    ForEach(categories, id: \.self) { name in
                        Label(name, systemImage: "folder")
                            .lineLimit(1)
                            .tag(Browse.category(kind, name))
                            .contextMenu {
                                Button("Masquer cette catégorie") { hide(name, kind: kind) }
                                Divider()
                                Button("Gérer les catégories…") { openWindow(id: "categories") }
                            }
                    }
                } header: {
                    HStack {
                        Text("Catégories — \(kind.title)")
                        Spacer()
                        Button {
                            openWindow(id: "categories")
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        .buttonStyle(.borderless)
                        .help("Réordonner, masquer ou renommer les catégories (⌥⌘C)")
                    }
                }
            }

            Section("Sources") {
                ForEach(store.sources) { source in
                    SourceStatusRow(source: source)
                }
            }
        }
        .listStyle(.sidebar)
    }

    /// Masque une catégorie (nom affiché → nom d'origine du fournisseur).
    private func hide(_ displayed: String, kind: MediaKind) {
        let prefs = store.prefs(for: kind)
        let originals = (store.allCategoriesByKind[kind] ?? []).filter { prefs.displayName($0) == displayed }
        if case .category(_, displayed)? = navigation.browse { navigation.go(.all(kind)) }
        store.updateCategories(kind) { prefs in originals.forEach { prefs.hidden.insert($0) } }
    }

    private func row(_ browse: Browse, icon: String, count: Int?) -> some View {
        HStack {
            Label(browse.title, systemImage: icon)
            Spacer()
            if let count, count > 0 {
                Text(count, format: .number)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .tag(browse)
    }
}

/// Ligne d'état d'une source dans la barre latérale (non sélectionnable).
struct SourceStatusRow: View {
    @Environment(LibraryStore.self) private var store
    let source: Source

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(source.name)
                .lineLimit(1)
                .foregroundStyle(source.isEnabled ? .primary : .secondary)
            Spacer()
            if store.loading.contains(source.id) {
                ProgressView().controlSize(.mini)
            }
        }
        .help(helpText)
        .selectionDisabled()
    }

    private var icon: String {
        if store.errors[source.id] != nil { return "exclamationmark.triangle.fill" }
        if !source.isEnabled { return "pause.circle" }
        switch source.kind {
        case .xtream: return "server.rack"
        case .m3uURL: return "link"
        case .m3uFile: return "doc.text"
        case .folders: return "folder"
        case .mediaServer(let type, _, _): return type == .plex ? "play.rectangle.on.rectangle" : "server.rack"
        }
    }

    private var color: Color {
        if store.errors[source.id] != nil { return .orange }
        return .secondary
    }

    private var helpText: String {
        if let error = store.errors[source.id] { return error }
        let count = store.contents[source.id]?.items.count ?? 0
        return String(localized: "\(source.kind.title) — \(count) éléments")
    }
}
