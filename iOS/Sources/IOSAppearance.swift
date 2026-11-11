import SwiftUI
import KastideoCore

/// Clés des réglages d'apparence de l'application iPhone / iPad.
enum IOSKeys {
    static let accent = "ios.accent"
    static let cardSize = "ios.cardSize"
    static let density = "ios.density"
    static let startTab = "ios.startTab"
    static let liveMode = "ios.live.mode"
    static let moviesMode = "ios.movies.mode"
    static let seriesMode = "ios.series.mode"
}

/// Couleur d'accentuation (boutons, barres de progression, pastilles).
enum IOSAccent: String, CaseIterable, Identifiable {
    case orange, red, pink, purple, blue, teal, green, system

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .orange: return "Orange"
        case .red: return "Rouge"
        case .pink: return "Rose"
        case .purple: return "Violet"
        case .blue: return "Bleu"
        case .teal: return "Turquoise"
        case .green: return "Vert"
        case .system: return "Système"
        }
    }

    /// `nil` : couleur du système.
    var color: Color? {
        switch self {
        case .orange: return Color(red: 1.0, green: 0.62, blue: 0.2)
        case .red: return Color(red: 0.95, green: 0.27, blue: 0.3)
        case .pink: return Color(red: 0.98, green: 0.36, blue: 0.62)
        case .purple: return Color(red: 0.62, green: 0.42, blue: 0.95)
        case .blue: return Color(red: 0.25, green: 0.55, blue: 1.0)
        case .teal: return Color(red: 0.2, green: 0.78, blue: 0.75)
        case .green: return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .system: return nil
        }
    }

    static func current(_ raw: String) -> IOSAccent { IOSAccent(rawValue: raw) ?? .orange }
}

/// Taille des affiches.
enum IOSCardSize: String, CaseIterable, Identifiable {
    case small, medium, large

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .small: return "Petites"
        case .medium: return "Moyennes"
        case .large: return "Grandes"
        }
    }

    var width: CGFloat {
        switch self {
        case .small: return 100
        case .medium: return 120
        case .large: return 150
        }
    }

    static func current(_ raw: String) -> IOSCardSize { IOSCardSize(rawValue: raw) ?? .medium }
}

/// Densité des listes (chaînes, programmes).
enum IOSDensity: String, CaseIterable, Identifiable {
    case compact, standard, spacious

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .compact: return "Compacte"
        case .standard: return "Standard"
        case .spacious: return "Aérée"
        }
    }

    var padding: CGFloat {
        switch self {
        case .compact: return -2
        case .standard: return 2
        case .spacious: return 8
        }
    }

    static func current(_ raw: String) -> IOSDensity { IOSDensity(rawValue: raw) ?? .standard }
}

extension IOSTab {
    /// Onglet affiché au lancement (Réglages > Départ).
    static var stored: IOSTab {
        switch UserDefaults.standard.string(forKey: IOSKeys.startTab) {
        case "live": return .live
        case "movies": return .movies
        case "series": return .series
        default: return .home
        }
    }
}

// MARK: - Étendue d'une liste (page de départ)

/// Ce que montrent la liste des chaînes et la grille des films / séries.
enum IOSListScope: Hashable {
    case all, favorites, recents
    case category(String)

    init(_ browse: Browse) {
        switch browse {
        case .favorites: self = .favorites
        case .recents: self = .recents
        case .category(_, let name): self = .category(name)
        default: self = .all
        }
    }

    /// Page de départ choisie dans les réglages pour ce type de contenu.
    @MainActor
    static func start(for kind: MediaKind, store: LibraryStore) -> IOSListScope {
        IOSListScope(StartPage.destination(for: kind, categories: store.categoriesByKind[kind] ?? []))
    }

    @MainActor
    func items(kind: MediaKind, store: LibraryStore) -> [MediaItem] {
        let kinds: Set<MediaKind> = kind == .series ? [.series, .episode] : [kind]
        switch self {
        case .all: return store.items(for: .all(kind))
        case .favorites: return store.items(for: .favorites).filter { kinds.contains($0.kind) }
        case .recents: return store.items(for: .recents).filter { kinds.contains($0.kind) }
        case .category(let name): return store.items(for: .category(kind, name))
        }
    }

    func title(kind: MediaKind) -> String {
        switch self {
        case .all: return kind.title
        case .favorites: return String(localized: "Favoris")
        case .recents: return String(localized: "Récents")
        case .category(let name): return name
        }
    }
}
