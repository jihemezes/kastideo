import SwiftUI
import AppKit
import KastideoCore

/// Sections proposées dans la barre d'outils de l'interface Cinéma.
enum CinemaSection: String, CaseIterable, Identifiable, Hashable {
    case live, movies, series, guide, favorites, recents, recordings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .live: return String(localized: "Direct")
        case .movies: return String(localized: "Films")
        case .series: return String(localized: "Séries")
        case .guide: return String(localized: "Guide TV")
        case .favorites: return String(localized: "Favoris")
        case .recents: return String(localized: "Récents")
        case .recordings: return String(localized: "Enregistrements")
        }
    }

    var browse: Browse {
        switch self {
        case .live: return .all(.live)
        case .movies: return .all(.movie)
        case .series: return .all(.series)
        case .guide: return .guide
        case .favorites: return .favorites
        case .recents: return .recents
        case .recordings: return .recordings
        }
    }

    static func from(_ browse: Browse?) -> CinemaSection {
        guard let browse else { return .live }
        switch browse {
        case .home: return .live
        case .all(let kind), .category(let kind, _):
            switch kind {
            case .live: return .live
            case .movie: return .movies
            case .series, .episode: return .series
            }
        case .favorites: return .favorites
        case .recents: return .recents
        case .recordings: return .recordings
        case .guide: return .guide
        case .themes, .library: return .live
        }
    }

}

/// Interface « Cinéma » : accueil à rangées horizontales, puis lecteur plein cadre.
struct CinemaRootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    let scope: InterfaceScope?
    let style: InterfaceStyle

    var body: some View {
        @Bindable var navigation = navigation
        let browse = navigation.browse ?? .all(.live)
        NavigationStack {
            Group {
                if navigation.selectedItemID != nil {
                    CinemaDetail()
                } else if let id = navigation.infoItemID, let item = store.item(id: id) {
                    MediaInfoView(item: item)
                        .id(item.id)
                } else {
                    CinemaCatalog(browse: browse)
                }
            }
            .onChange(of: navigation.selectedItemID) { _, id in
                // Retour au catalogue (ou changement de section) : la lecture s'arrête, sauf enregistrement en cours.
                if id == nil, playback.current != nil, !recordings.isPlayerRecording { playback.stop() }
            }
            .navigationTitle(browse.title)
            .searchable(text: $navigation.search, placement: .toolbar, prompt: "Rechercher")
            .toolbar {
                SectionPickerToolbar(navigation: self.navigation, playback: playback, recordings: recordings)
                MainToolbar(store: store, scope: scope, style: style)
            }
            .toolbar(navigation.isTheater ? .hidden : .automatic, for: .windowToolbar)
        }
    }
}

/// Onglets de section (Direct, Films…) au centre de la barre d'outils des interfaces Cinéma et TV.
struct SectionPickerToolbar: ToolbarContent {
    let navigation: NavigationModel
    let playback: PlaybackController
    let recordings: RecordingCenter

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("Section", selection: binding) {
                ForEach(CinemaSection.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(minWidth: 580)
        }
    }

    private var binding: Binding<CinemaSection> {
        Binding(
            get: { CinemaSection.from(navigation.browse) },
            set: { section in
                if navigation.selectedItemID != nil {
                    navigation.selectedItemID = nil
                    if !recordings.isPlayerRecording { playback.stop() }
                }
                navigation.go(section.browse)
            }
        )
    }
}

/// Lecteur en plein cadre avec un bouton de retour vers le catalogue.
struct CinemaDetail: View {
    @Environment(NavigationModel.self) private var navigation
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings

    var body: some View {
        VStack(spacing: 0) {
            if !navigation.isTheater {
                HStack {
                    Button {
                        close()
                    } label: {
                        Label("Retour", systemImage: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    .keyboardShortcut(.cancelAction)
                    .help("Revenir au catalogue (Échap)")
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                Divider()
            }
            DetailView()
        }
    }

    private func close() {
        navigation.selectedItemID = nil
        // Ne pas couper un enregistrement qui dépend de la lecture.
        if !recordings.isPlayerRecording { playback.stop() }
    }
}

/// Clé qui change quand la liste affichée change (pour ⌘↑ / ⌘↓).
private struct VisibleKey: Hashable {
    let browse: Browse
    let count: Int
    let search: String
}

/// Catalogue de l'interface Cinéma : accueil de la section, grille ou résultats de recherche.
struct CinemaCatalog: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    let browse: Browse

    var body: some View {
        let _ = navigation.mark("Catalogue Cinéma — début")
        let search = navigation.search
        let key = search.kastideoSearchKey
        let items = filtered(store.items(for: browse), key: key)
        let _ = navigation.mark("Catalogue Cinéma — \(items.count) éléments")

        ScrollView {
            if !key.isEmpty {
                CinemaGrid(title: String(localized: "Résultats pour « \(search) »"), items: items, emptyText: nil)
            } else {
                switch browse {
                case .all(let kind):
                    CinemaHome(kind: kind)
                case .category(_, let name):
                    CinemaGrid(title: name, items: items, emptyText: browse.emptyMessage)
                case .favorites:
                    CinemaGrid(title: browse.title, items: items, emptyText: browse.emptyMessage)
                case .recents:
                    CinemaRecents(items: items)
                case .home, .recordings, .guide, .themes, .library:
                    EmptyView()
                }
            }
        }
        .task(id: VisibleKey(browse: browse, count: items.count, search: key)) {
            navigation.visibleIDs = items.map(\.id)
        }
        .recentsUndoToast()
        .onAppear { navigation.noteDisplayed(String(localized: "Cinéma — \(browse.title)")) }
    }

    private func filtered(_ items: [MediaItem], key: String) -> [MediaItem] {
        guard !key.isEmpty else { return items }
        return items.filter { $0.searchKey.contains(key) }
    }
}

/// Accueil d'une section : à la une, reprise, favoris, puis une rangée par catégorie.
struct CinemaHome: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(WatchProgressStore.self) private var watch
    @AppStorage(HeroKeys.enabled) private var heroEnabled = true
    @AppStorage(CountryKeys.codes) private var countryCodes = ""
    @AppStorage(CountryKeys.neutral) private var countryNeutral = true
    let kind: MediaKind

    var body: some View {
        let kinds: Set<MediaKind> = kind == .series ? [.series, .episode] : [kind]
        let countries = CountryFilter(stored: countryCodes, keepNeutral: countryNeutral)
        let all = store.items(for: .all(kind))
        let allRecents = store.recentIDs.compactMap { store.item(id: $0) }.filter { kinds.contains($0.kind) }
        // Pour les films et séries : les contenus entamés d'abord (« Reprendre »), puis les autres récents.
        let started = kind == .live ? [] : allRecents.filter { watch.fraction(for: $0.id) != nil }
        let recents = kind == .live ? allRecents : allRecents.filter { watch.fraction(for: $0.id) == nil }
        let favorites = store.favoriteIDs.compactMap { store.item(id: $0) }.filter { kinds.contains($0.kind) }
        // Pays choisis (Réglages > Apparence) : seules leurs catégories ont une rangée.
        let categories = (store.categoriesByKind[kind] ?? []).filter {
            countries.allows(category: $0) || store.libraryCategories[kind]?.contains($0) == true
        }
        let _ = navigation.mark("Accueil Cinéma — \(categories.count) catégories")

        if all.isEmpty {
            ContentUnavailableView(kind.title, systemImage: "tray",
                                   description: Text(Browse.all(kind).emptyMessage))
                .frame(maxWidth: .infinity, minHeight: 360)
        } else {
            let featured = started.first ?? recents.first ?? favorites.first
                ?? all.first(where: { $0.logoURL != nil }) ?? all.first
            let caption = started.first != nil ? String(localized: "À REPRENDRE")
                : (recents.first != nil ? String(localized: "REGARDÉ RÉCEMMENT") : (favorites.first != nil ? String(localized: "VOS FAVORIS") : String(localized: "À LA UNE")))
            LazyVStack(alignment: .leading, spacing: 26) {
                if heroEnabled {
                    CinemaHeroCarousel(kind: kind, fallback: featured, fallbackCaption: caption)
                }
                if kind == .live {
                    // Rangées par thème : ce qui est diffusé en ce moment (une version par chaîne).
                    ForEach(ContentTheme.browsable.filter { $0 != .general && $0 != .other }) { theme in
                        let airing = store.liveGroups.filter { group in
                            guard let programme = store.epg.current(for: group.epgID) else { return false }
                            return (programme.theme ?? group.theme) == theme
                        }.map(\.preferred)
                        if !airing.isEmpty {
                            CinemaRail(title: theme.nowTitle, items: airing,
                                       seeAll: { navigation.showThemes(theme, mode: .now) })
                        }
                    }
                }
                if kind == .live, ReplaySettings.enabled {
                    // Chaînes préférées qui ont un replay : clic droit > « Revoir (replay) » ou fiche du guide TV.
                    var seen = Set<String>()
                    let replayable = (favorites + allRecents).filter { ($0.archiveDays ?? 0) > 0 && seen.insert($0.id).inserted }
                    if !replayable.isEmpty {
                        CinemaRail(title: String(localized: "À revoir (replay)"), items: replayable, seeAll: { navigation.go(.favorites) })
                    }
                }
                if !started.isEmpty {
                    CinemaRail(title: String(localized: "Reprendre la lecture"), items: started, seeAll: { navigation.go(.recents) })
                }
                if !recents.isEmpty {
                    CinemaRail(title: kind == .live ? String(localized: "Regardées récemment") : String(localized: "Regardés récemment"),
                               items: recents, seeAll: { navigation.go(.recents) })
                }
                if !favorites.isEmpty {
                    CinemaRail(title: String(localized: "Favoris"), items: favorites, seeAll: { navigation.go(.favorites) })
                }
                ForEach(categories, id: \.self) { name in
                    CinemaRail(title: name,
                               items: store.items(for: .category(kind, name)),
                               seeAll: { navigation.go(.category(kind, name)) })
                }
            }
            .padding(.vertical, 20)
        }
    }
}

/// Grille de vignettes (catégorie, favoris, récents, recherche).
struct CinemaGrid: View {
    @AppStorage(AppearanceKeys.cardSize) private var cardSizeRaw = CardSize.medium.rawValue
    let title: String
    let items: [MediaItem]
    let emptyText: String?

    var body: some View {
        let size = CardSize(rawValue: cardSizeRaw) ?? .medium
        let hasTiles = items.first?.kind == .live
        let minimum = hasTiles ? size.tileWidth : size.posterWidth
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.title2.weight(.bold)).lineLimit(1)
                Text("\(items.count)").font(.callout).foregroundStyle(.secondary)
            }
            if items.isEmpty {
                ContentUnavailableView(title, systemImage: "tray",
                                       description: Text(emptyText ?? String(localized: "Aucun résultat.")))
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum), spacing: 16, alignment: .top)],
                          alignment: .leading, spacing: 20) {
                    ForEach(items) { item in
                        MediaCard(item: item)
                    }
                }
            }
        }
        .padding(24)
    }
}

/// Rangée horizontale de vignettes.
struct CinemaRail: View {
    let title: String
    let items: [MediaItem]
    var seeAll: (() -> Void)?
    private let limit = 40

    init(title: String, items: [MediaItem], seeAll: (() -> Void)? = nil) {
        self.title = title
        self.items = items
        self.seeAll = seeAll
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title).font(.title3.weight(.semibold)).lineLimit(1)
                Text("\(items.count)").font(.caption).foregroundStyle(.secondary)
                Spacer()
                if let seeAll, items.count > 8 {
                    Button("Tout voir", action: seeAll)
                        .buttonStyle(.link)
                }
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(Array(items.prefix(limit))) { item in
                        MediaCard(item: item)
                    }
                    if items.count > limit, let seeAll {
                        SeeAllCard(remaining: items.count - limit, action: seeAll)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
            }
        }
    }
}

/// Dernière vignette d'une rangée : ouvre la catégorie complète.
struct SeeAllCard: View {
    @AppStorage(AppearanceKeys.cardSize) private var cardSizeRaw = CardSize.medium.rawValue
    let remaining: Int
    let action: () -> Void

    var body: some View {
        let size = CardSize(rawValue: cardSizeRaw) ?? .medium
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.right.circle")
                    .font(.largeTitle)
                Text("+ \(remaining)")
                    .font(.headline.monospacedDigit())
                Text("Tout voir")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: size.posterWidth * 0.8, height: size.posterWidth * 1.5)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Vignette d'un contenu : affiche (film, série) ou tuile 16:9 (chaîne).
struct MediaCard: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(WatchProgressStore.self) private var watch
    @AppStorage(AppearanceKeys.cardSize) private var cardSizeRaw = CardSize.medium.rawValue
    let item: MediaItem
    @State private var hovering = false

    var body: some View {
        let size = CardSize(rawValue: cardSizeRaw) ?? .medium
        let isLive = item.kind == .live
        let width = isLive ? size.tileWidth : size.posterWidth
        let height = isLive ? width * 9 / 16 : width * 3 / 2
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        Button {
            if item.kind == .movie || item.kind == .series {
                navigation.infoItemID = item.id
            } else {
                navigation.selectedItemID = item.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                PosterView(url: item.logoURL, name: item.name, fit: isLive)
                    .frame(width: width, height: height)
                    .clipShape(shape)
                    .overlay(alignment: .bottom) {
                        if item.kind != .live, let fraction = watch.fraction(for: item.id) {
                            ProgressView(value: fraction)
                                .progressViewStyle(.linear)
                                .tint(.white)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                                .shadow(color: .black.opacity(0.6), radius: 2)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if store.isFavorite(item.id) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                                .padding(6)
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if item.kind == .movie, watch.isWatched(item.id) {
                            Label("Vu", systemImage: "checkmark")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.black.opacity(0.65), in: Capsule())
                                .foregroundStyle(.white)
                                .padding(6)
                        }
                    }
                    .overlay(shape.strokeBorder(Color.white.opacity(hovering ? 0.55 : 0.08),
                                                lineWidth: hovering ? 2 : 1))
                Text(isLive ? item.name : TMDB.cleanTitle(item.name).title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                caption
            }
            .frame(width: width, alignment: .leading)
            .scaleEffect(hovering ? 1.03 : 1)
            .animation(.easeOut(duration: 0.12), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .contextMenu { ItemActionsMenu(item: item) }
        .help(item.name)
    }

    @ViewBuilder
    private var caption: some View {
        if item.kind == .live, let programme = store.epg.current(for: item.epgID) {
            VStack(alignment: .leading, spacing: 3) {
                Text(programme.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                ProgressView(value: programme.progress())
                    .progressViewStyle(.linear)
                    .controlSize(.mini)
            }
        } else {
            Text(item.kind == .episode ? item.group : (item.number.map { "\($0) · " } ?? "") + item.group)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

/// Affiche ou logo avec un fond dégradé et des initiales en secours.
struct PosterView: View {
    let url: URL?
    let name: String
    var fit = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.22), Color(white: 0.11)],
                           startPoint: .top, endPoint: .bottom)
            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.15))) { phase in
                    switch phase {
                    case .success(let image):
                        if fit {
                            image.resizable().scaledToFit().padding(14)
                        } else {
                            image.resizable().scaledToFill()
                        }
                    default:
                        initials
                    }
                }
            } else {
                initials
            }
        }
        .clipped()
    }

    private var initials: some View {
        Text(String(name.filter { $0.isLetter || $0.isNumber }.prefix(2)).uppercased())
            .font(.system(size: 34, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.45))
    }
}

/// Bandeau « à la une » en haut de l'accueil d'une section.
struct CinemaHero: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    let item: MediaItem
    let caption: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backdrop
            LinearGradient(colors: [.black.opacity(0.85), .black.opacity(0.4), .clear],
                           startPoint: .leading, endPoint: .trailing)
            HStack(alignment: .bottom, spacing: 22) {
                PosterView(url: item.logoURL, name: item.name, fit: item.kind == .live)
                    .frame(width: item.kind == .live ? 230 : 140, height: item.kind == .live ? 130 : 210)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 14, y: 6)

                VStack(alignment: .leading, spacing: 8) {
                    Text(caption)
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(.tint)
                    Text(item.name)
                        .font(.system(size: 32, weight: .bold))
                        .lineLimit(2)
                    summary
                    HStack(spacing: 10) {
                        Button {
                            navigation.selectedItemID = item.id
                        } label: {
                            Label(item.needsEpisodes ? String(localized: "Voir les épisodes") : String(localized: "Lire"),
                                  systemImage: item.needsEpisodes ? "list.bullet" : "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        if item.kind == .movie || item.kind == .series {
                            Button {
                                navigation.infoItemID = item.id
                            } label: {
                                Label("Plus d'infos", systemImage: "info.circle")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                        Button {
                            store.toggleFavorite(item.id)
                        } label: {
                            Image(systemName: store.isFavorite(item.id) ? "star.fill" : "star")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .help("Ajouter ou retirer des favoris")
                    }
                    .padding(.top, 4)
                }
                .foregroundStyle(.white)
                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var summary: some View {
        if item.kind == .live, let programme = store.epg.current(for: item.epgID) {
            VStack(alignment: .leading, spacing: 4) {
                Text("En ce moment : \(programme.title)")
                    .font(.headline)
                    .lineLimit(1)
                ProgressView(value: programme.progress())
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 320)
            }
        } else if let info = item.info, !info.isEmpty {
            Text(info)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(3)
                .frame(maxWidth: 560, alignment: .leading)
        } else {
            Text(item.group)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
        }
    }

    private var backdrop: some View {
        ZStack {
            Color(white: 0.09)
            if let url = item.logoURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill().blur(radius: 40).opacity(0.6)
                    }
                }
            }
        }
        .clipped()
    }
}
