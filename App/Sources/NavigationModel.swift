import Foundation
import Observation
import KastideoCore

/// Ce que l'utilisateur parcourt dans la barre latérale.
enum Browse: Hashable {
    case home
    case all(MediaKind)
    case category(MediaKind, String)
    case favorites
    case recents
    case recordings
    case guide

    var kind: MediaKind? {
        switch self {
        case .all(let kind), .category(let kind, _): return kind
        case .home, .favorites, .recents, .recordings, .guide: return nil
        }
    }

    var title: String {
        switch self {
        case .home: return String(localized: "Accueil")
        case .all(let kind): return kind.title
        case .category(_, let name): return name
        case .favorites: return String(localized: "Favoris")
        case .recents: return String(localized: "Récents")
        case .recordings: return String(localized: "Enregistrements")
        case .guide: return String(localized: "Guide TV")
        }
    }

    var emptyMessage: String {
        switch self {
        case .favorites: return String(localized: "Ajoutez des favoris avec l'étoile ou ⌘D.")
        case .recents: return String(localized: "Les contenus que vous regardez apparaîtront ici.")
        default: return String(localized: "Aucun contenu dans cette section pour vos sources actives.")
        }
    }
}

/// État de navigation partagé entre la fenêtre et les menus.
@MainActor
@Observable
final class NavigationModel {
    var browse: Browse? = .home {
        didSet {
            if let kind = browse?.kind { lastKind = kind }
            search = ""
        }
    }
    var selectedItemID: String?
    var search = ""
    /// Type de contenu dont les catégories sont affichées dans la barre latérale.
    private(set) var lastKind: MediaKind = .live
    /// Liste visible (pour ⌘↑ / ⌘↓).
    var visibleIDs: [String] = []
    /// Affiche la fenêtre « Nouveautés ».
    var showWhatsNew = false
    /// Mode cinéma : la vidéo occupe toute la fenêtre (colonnes masquées, plein écran).
    var isTheater = false

    func go(_ destination: Browse) {
        browse = destination
    }

    /// Ouvre un contenu dans sa section (depuis l'accueil, par exemple).
    func open(_ item: MediaItem) {
        let kind: MediaKind = item.kind == .episode ? .series : item.kind
        browse = .all(kind)
        selectedItemID = item.id
    }

    /// Ouvre une chaîne en direct dans la section Direct (depuis le guide TV, par exemple).
    func watchLive(_ item: MediaItem) {
        browse = .all(.live)
        selectedItemID = item.id
    }

    func step(_ delta: Int) {
        guard !visibleIDs.isEmpty else { return }
        let current = selectedItemID.flatMap { visibleIDs.firstIndex(of: $0) }
        let next: Int
        if let current {
            next = (current + delta + visibleIDs.count) % visibleIDs.count
        } else {
            next = delta >= 0 ? 0 : visibleIDs.count - 1
        }
        selectedItemID = visibleIDs[next]
    }
}
