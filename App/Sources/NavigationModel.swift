import Foundation
import Observation
import KastideoCore

/// Ce que l'utilisateur parcourt dans la barre latérale.
enum Browse: Hashable {
    case all(MediaKind)
    case category(MediaKind, String)
    case favorites
    case recents

    var kind: MediaKind? {
        switch self {
        case .all(let kind), .category(let kind, _): return kind
        case .favorites, .recents: return nil
        }
    }

    var title: String {
        switch self {
        case .all(let kind): return kind.label
        case .category(_, let name): return name
        case .favorites: return "Favoris"
        case .recents: return "Récents"
        }
    }

    var emptyMessage: String {
        switch self {
        case .favorites: return "Ajoutez des favoris avec l'étoile ou ⌘D."
        case .recents: return "Les contenus que vous regardez apparaîtront ici."
        default: return "Aucun contenu dans cette section pour vos sources actives."
        }
    }
}

/// État de navigation partagé entre la fenêtre et les menus.
@MainActor
@Observable
final class NavigationModel {
    var browse: Browse? = .all(.live) {
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

    func go(_ destination: Browse) {
        browse = destination
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
