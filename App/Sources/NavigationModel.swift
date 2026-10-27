import Foundation
import Observation
import KastideoCore

/// Vues de la vidéothèque.
enum LibraryView: String, CaseIterable, Identifiable {
    case home, movies, series, videos, folders
    var id: String { rawValue }
}

/// Tri de la vidéothèque.
enum LibrarySort: String, CaseIterable, Identifiable {
    case title, added, year
    var id: String { rawValue }
    var label: String {
        switch self {
        case .title: return String(localized: "Titre")
        case .added: return String(localized: "Ajout récent")
        case .year: return String(localized: "Année")
        }
    }
}

/// Ce que l'utilisateur parcourt dans la barre latérale.
enum Browse: Hashable {
    case home
    case all(MediaKind)
    case category(MediaKind, String)
    case favorites
    case recents
    case recordings
    case guide
    /// Direct par thème (Sport, Info…) : en ce moment, ce soir, chaînes.
    case themes
    /// Vidéothèque : dossiers (disque, clé USB, NAS) et serveurs Jellyfin, Emby, Plex.
    case library

    var kind: MediaKind? {
        switch self {
        case .all(let kind), .category(let kind, _): return kind
        case .home, .favorites, .recents, .recordings, .guide, .themes, .library: return nil
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
        case .themes: return String(localized: "Thèmes")
        case .library: return String(localized: "Mes vidéos")
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
            browseChangedAt = Date()
            marked.removeAll()
            if let kind = browse?.kind {
                // Changement de type de contenu (Direct → Films…) : on arrive sur la grille, pas sur le lecteur.
                if kind != lastKind { selectedItemID = nil }
                lastKind = kind
            }
            infoItemID = nil
            search = ""
        }
    }
    var selectedItemID: String?
    /// Instant du dernier changement de section (mesure du temps d'affichage, Journal de lecture).
    @ObservationIgnored var browseChangedAt = Date()

    @ObservationIgnored private var marked = Set<String>()

    /// Étape de construction de l'affichage (diagnostic des lenteurs) : notée une fois par changement de section
    /// si elle survient plus de 0,3 s après le clic.
    func mark(_ what: String) {
        let elapsed = Date().timeIntervalSince(browseChangedAt)
        guard elapsed > 0.3, elapsed < 300, marked.insert(what).inserted else { return }
        let text = "Étape « \(what) » à \(String(format: "%.1f", elapsed)) s"
        Task { @MainActor in PlaybackLog.shared.note(text) }
    }

    /// Note dans le Journal de lecture le temps d'affichage d'une section s'il dépasse une demi-seconde.
    func noteDisplayed(_ what: String) {
        let elapsed = Date().timeIntervalSince(browseChangedAt)
        if elapsed > 0.5 { PlaybackLog.shared.note("Affichage de « \(what) » : \(String(format: "%.1f", elapsed)) s") }
    }
    /// Fiche ouverte (film ou série) dans l'interface Cinéma, avant la lecture.
    var infoItemID: String?
    var search = ""
    /// Type de contenu dont les catégories sont affichées dans la barre latérale.
    private(set) var lastKind: MediaKind = .live
    /// Liste visible (pour ⌘↑ / ⌘↓).
    var visibleIDs: [String] = []
    /// Affiche la fenêtre « Nouveautés ».
    var showWhatsNew = false
    /// Mode cinéma : la vidéo occupe toute la fenêtre (colonnes masquées, plein écran).
    var isTheater = false
    /// Vue « Thèmes » : thème choisi (nil = tous) et mode d'affichage.
    var themeSelection: ContentTheme?
    var themeMode: ThemeMode = .now

    // MARK: Vidéothèque

    /// Source affichée (nil : toutes), vue, dossier ouvert (navigation par dossiers), filtres et tri.
    var librarySource: UUID? {
        didSet { libraryFolder = [] }
    }
    var libraryView: LibraryView = .home {
        didSet { if libraryView != .folders { libraryFolder = [] } }
    }
    var libraryFolder: [String] = []
    var libraryGenre: String?
    var libraryYear: Int?
    var libraryUnwatched = false
    var librarySort: LibrarySort = .title

    /// Ouvre une vue de la vidéothèque (la fiche ou le lecteur ouverts se referment).
    func showLibrary(_ view: LibraryView) {
        if browse != .library { browse = .library }
        libraryView = view
        infoItemID = nil
        selectedItemID = nil
    }

    /// Ouvre la vue Thèmes sur un thème et un mode.
    func showThemes(_ theme: ContentTheme?, mode: ThemeMode) {
        themeSelection = theme
        themeMode = mode
        browse = .themes
    }

    /// Chaîne en cours de modification (feuille « Modifier la chaîne »).
    var editingChannel: MediaItem?

    /// Fichier local dont on corrige la fiche TMDB (feuille « Corriger la fiche »).
    var fixingItem: MediaItem?

    /// Panneau « Contexte » du lecteur (chaîne, programme, pistes, qualité).
    var showContextPanel = false

    func go(_ destination: Browse) {
        browse = destination
    }

    /// Ouvre un contenu dans sa section (depuis l'accueil, par exemple).
    func open(_ item: MediaItem, inLibrary: Bool = false) {
        let kind: MediaKind = item.kind == .episode ? .series : item.kind
        browse = inLibrary ? .library : .all(kind)
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
