import SwiftUI
import KastideoCore

/// Façons d'afficher le direct.
enum IOSLiveMode: String, CaseIterable, Identifiable {
    case cinema, list, themes, guide
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .cinema: return "Cinéma"
        case .list: return "Liste"
        case .themes: return "Thèmes"
        case .guide: return "Guide TV"
        }
    }
    var icon: String {
        switch self {
        case .cinema: return "rectangle.grid.1x2"
        case .list: return "list.bullet"
        case .themes: return "square.grid.2x2"
        case .guide: return "calendar"
        }
    }
}

/// Façons d'afficher les films et les séries.
enum IOSCatalogMode: String, CaseIterable, Identifiable {
    case cinema, grid
    var id: String { rawValue }
    var label: LocalizedStringKey { self == .cinema ? "Cinéma" : "Grille" }
    var icon: String { self == .cinema ? "rectangle.grid.1x2" : "square.grid.3x3" }
}

/// Onglet Direct : liste, Cinéma (à la une + rangées), Thèmes ou Guide TV.
struct IOSLiveHub: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage("ios.live.mode") private var modeRaw = IOSLiveMode.list.rawValue

    private var mode: IOSLiveMode { IOSLiveMode(rawValue: modeRaw) ?? .list }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .list:
                    IOSLiveList()
                case .cinema:
                    IOSCinemaHome(kind: .live).navigationTitle("Direct")
                case .themes:
                    IOSThemesView().navigationTitle("Thèmes")
                case .guide:
                    IOSGuideView().navigationTitle("Guide TV")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Affichage", selection: $modeRaw) {
                            ForEach(IOSLiveMode.allCases) { item in
                                Label(item.label, systemImage: item.icon).tag(item.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: mode.icon)
                    }
                }
                if MultiViewKeys.isAvailable(sources: store.sources) {
                    ToolbarItem(placement: .topBarTrailing) { IOSMultiViewButton() }
                }
                ToolbarItem(placement: .topBarTrailing) { IOSRecordingsLink() }
            }
        }
    }
}

/// Onglets Films et Séries : Cinéma (à la une + rangées) ou grille complète.
struct IOSCatalogHub: View {
    let kind: MediaKind
    @AppStorage("ios.movies.mode") private var moviesMode = IOSCatalogMode.cinema.rawValue
    @AppStorage("ios.series.mode") private var seriesMode = IOSCatalogMode.cinema.rawValue
    @Environment(LibraryStore.self) private var store

    private var modeRaw: Binding<String> { kind == .series ? $seriesMode : $moviesMode }
    private var mode: IOSCatalogMode { IOSCatalogMode(rawValue: modeRaw.wrappedValue) ?? .cinema }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .cinema:
                    IOSCinemaHome(kind: kind).navigationTitle(kind.title)
                case .grid:
                    IOSCatalogGrid(kind: kind)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Affichage", selection: modeRaw) {
                            ForEach(IOSCatalogMode.allCases) { item in
                                Label(item.label, systemImage: item.icon).tag(item.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: mode.icon)
                    }
                }
                if store.hasLibrary {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Afficher", selection: Binding(get: { store.catalogOrigin }, set: { store.catalogOrigin = $0 })) {
                                ForEach(CatalogOrigin.allCases) { origin in Text(origin.label).tag(origin) }
                            }
                        } label: {
                            Image(systemName: "externaldrive.connected.to.line.below")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) { IOSRecordingsLink() }
            }
        }
    }
}
