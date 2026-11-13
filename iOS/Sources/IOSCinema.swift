import SwiftUI
import KastideoCore

// MARK: - Réglages du bandeau (mêmes clés que sur Mac : elles voyagent dans la sauvegarde)

enum IOSHeroKeys {
    static let enabled = "hero.enabled"
    static let categoryMovie = "hero.category.movie"
    static let categorySeries = "hero.category.series"
    static let useCategory = "hero.useCategory"
    static let useRecent = "hero.useRecent"
    static let useTrending = "hero.useTrending"
    static let interval = "hero.interval"
}

struct IOSHeroSlide: Identifiable, Equatable {
    let item: MediaItem
    let caption: String
    var backdrop: URL?
    var id: String { item.id }
}

// MARK: - Bandeau « à la une »

struct IOSHero: View {
    let kind: MediaKind
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @Environment(MediaInfoStore.self) private var info
    @AppStorage(IOSHeroKeys.useTrending) private var useTrending = true
    @AppStorage(IOSHeroKeys.categoryMovie) private var categoryMovie = ""
    @AppStorage(IOSHeroKeys.categorySeries) private var categorySeries = ""
    @AppStorage(IOSHeroKeys.useCategory) private var useCategory = true
    @AppStorage(IOSHeroKeys.useRecent) private var useRecent = true
    @AppStorage(IOSHeroKeys.interval) private var interval = 8.0
    @AppStorage(CountryKeys.codes) private var countryCodes = ""
    @AppStorage(CountryKeys.neutral) private var countryNeutral = true
    @State private var slides: [IOSHeroSlide] = []
    @State private var index = 0

    private var settingsKey: String {
        "\(kind.rawValue)|\(categoryMovie)|\(categorySeries)|\(useCategory)|\(useRecent)|\(useTrending)|\(info.usesTMDB)|\(store.count(for: kind))|\(store.liveGroups.count)|\(countryCodes)|\(countryNeutral)"
    }

    var body: some View {
        Group {
            if slides.isEmpty {
                EmptyView()
            } else {
                TabView(selection: $index) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { offset, slide in
                        IOSHeroSlideView(slide: slide)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 28)
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 300)
            }
        }
        .task(id: settingsKey) {
            let built = await buildSlides()
            if Task.isCancelled { return }
            slides = built
            index = 0
        }
        .task(id: "timer|\(slides.count)|\(interval)") {
            guard slides.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(max(interval, 4)))
                guard !Task.isCancelled, slides.count > 1 else { return }
                withAnimation(.easeInOut(duration: 0.5)) { index = (index + 1) % slides.count }
            }
        }
    }

    private func buildSlides() async -> [IOSHeroSlide] {
        if kind == .live { return liveSlides() }
        let all = store.items(for: .all(kind))
        guard !all.isEmpty else { return [] }
        let countries = CountryFilter(stored: countryCodes, keepNeutral: countryNeutral)
        var groups: [[IOSHeroSlide]] = []
        // Le bandeau s'affiche dès que les sources locales sont prêtes ; les tendances (réseau) s'y ajoutent ensuite.
        func publish() {
            guard !Task.isCancelled else { return }
            let merged = Self.merge(groups)
            if !merged.isEmpty { slides = merged }
        }

        if useRecent {
            // Calcul hors du fil principal (catalogue de ~100 000 films).
            let newest: [MediaItem] = await Task.detached(priority: .userInitiated) {
                var top: [MediaItem] = []
                var datedCount = 0
                for item in all {
                    guard let date = item.added else { continue }
                    datedCount += 1
                    guard countries.allows(item) else { continue }
                    if top.count < 6 || date > (top.last?.added ?? .distantPast) {
                        top.append(item)
                        top.sort { ($0.added ?? .distantPast) > ($1.added ?? .distantPast) }
                        if top.count > 6 { top.removeLast() }
                    }
                }
                // Sans date d'ajout : les derniers éléments du fournisseur sont en général les plus récents.
                return datedCount > all.count / 4 ? top : Array(all.suffix(400).reversed().filter { countries.allows($0) }.prefix(6))
            }.value
            let caption = String(localized: "AJOUTÉ RÉCEMMENT")
            groups.append(newest.map { IOSHeroSlide(item: $0, caption: caption) })
        }

        if useCategory {
            let chosen = kind == .series ? categorySeries : categoryMovie
            let pool: [MediaItem]
            let caption: String
            if !chosen.isEmpty, !store.items(for: .category(kind, chosen)).isEmpty {
                pool = store.items(for: .category(kind, chosen))
                caption = chosen.uppercased()
            } else {
                pool = all
                caption = String(localized: "À DÉCOUVRIR")
            }
            var picked: [MediaItem] = []
            var ids = Set<String>()
            let filtered = pool.count == all.count && countries.isActive
            for _ in 0..<(filtered ? 300 : 60) where picked.count < 6 {
                guard let item = pool.randomElement() else { break }
                if filtered && !countries.allows(item) { continue }
                if item.logoURL != nil, ids.insert(item.id).inserted { picked.append(item) }
            }
            groups.append(picked.map { IOSHeroSlide(item: $0, caption: caption) })
        }

        publish()

        if useTrending, info.usesTMDB {
            let trends = await info.trending(isSeries: kind == .series)
            if !trends.isEmpty {
                let matched = await info.match(trends, in: all, kind: kind)
                let caption = String(localized: "TENDANCE DE LA SEMAINE")
                groups.append(matched.filter { countries.allows($0.item) }.prefix(6)
                    .map { IOSHeroSlide(item: $0.item, caption: caption, backdrop: $0.trend.backdropURL) })
            }
        }

        let merged = Self.merge(groups)
        if merged.isEmpty, countries.isActive {
            // Filtre de pays trop strict : mieux vaut un bandeau générique que pas de bandeau.
            let caption = String(localized: "À DÉCOUVRIR")
            return Array(all.suffix(400).reversed().filter { $0.logoURL != nil }.prefix(6)).map { IOSHeroSlide(item: $0, caption: caption) }
        }
        return merged
    }

    /// Mélange : une diapositive de chaque source à tour de rôle.
    private static func merge(_ groups: [[IOSHeroSlide]]) -> [IOSHeroSlide] {
        var result: [IOSHeroSlide] = []
        var seen = Set<String>()
        let longest = groups.map(\.count).max() ?? 0
        for i in 0..<longest {
            for group in groups where i < group.count {
                if seen.insert(group[i].id).inserted { result.append(group[i]) }
            }
        }
        return Array(result.prefix(12))
    }

    /// Direct : chaînes favorites puis récentes avec leur programme en cours ; sinon quelques chaînes du guide.
    private func liveSlides() -> [IOSHeroSlide] {
        var ids = store.favoriteIDs + store.recentIDs
        var seen = Set<String>()
        ids = ids.filter { seen.insert($0).inserted }
        let caption = String(localized: "EN CE MOMENT")
        var items = ids.compactMap { store.item(id: $0) }
            .filter { $0.kind == .live && store.epg.current(for: $0.epgID) != nil }
        if items.count < 4 {
            let existing = Set(items.map(\.id))
            let missing = 6 - items.count
            var extra: [MediaItem] = []
            for group in store.liveGroups where extra.count < missing {
                guard group.theme != .adult, store.epg.current(for: group.epgID) != nil else { continue }
                let channel = group.preferred
                if !existing.contains(channel.id) { extra.append(channel) }
            }
            items.append(contentsOf: extra)
        }
        return items.prefix(10).map { IOSHeroSlide(item: $0, caption: caption) }
    }
}

struct IOSHeroSlideView: View {
    let slide: IOSHeroSlide
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui

    private func playTitle(_ item: MediaItem) -> LocalizedStringKey {
        if item.kind == .live { return "Regarder" }
        return watch.inResume(item.id) ? "Reprendre" : "Lire"
    }

    var body: some View {
        let item = slide.item
        let programme = item.kind == .live ? store.epg.current(for: item.epgID) : nil
        ZStack(alignment: .bottomLeading) {
            // L'image remplit le cadre sans l'agrandir : le texte et les boutons restent dans le bandeau.
            Color.clear
                .overlay {
                    if let backdrop = slide.backdrop {
                        ArtworkView(url: backdrop, name: item.name, contentMode: .fill)
                    } else {
                        ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill).blur(radius: 26).scaleEffect(1.3)
                    }
                }
                .clipped()
            LinearGradient(colors: [.black.opacity(0.85), .black.opacity(0.45)], startPoint: .bottom, endPoint: .top)
            HStack(alignment: .bottom, spacing: 14) {
                if item.kind == .live {
                    ArtworkView(url: item.logoURL, name: item.name)
                        .frame(width: 96, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill)
                        .frame(width: 100, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(radius: 8)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(slide.caption).font(.caption2.weight(.bold)).foregroundStyle(IOSPalette.orange)
                    Text(programme?.title ?? TMDB.cleanTitle(item.name).title)
                        .font(.title3.bold()).lineLimit(2).foregroundStyle(.white)
                    if let programme {
                        Text("\(TMDB.cleanTitle(item.name).title) · \(programme.timeRange())")
                            .font(.caption).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
                        ProgressView(value: programme.progress()).tint(IOSPalette.orange)
                    } else if let info = item.info, !info.isEmpty {
                        Text(info).font(.caption).foregroundStyle(.white.opacity(0.8)).lineLimit(3)
                    }
                    HStack(spacing: 8) {
                        Button {
                            ui.open(item, store: store, playback: playback)
                        } label: {
                            Label(playTitle(item), systemImage: "play.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        if item.kind != .live {
                            Button { ui.detail = item } label: {
                                Label("Détails", systemImage: "info.circle").font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Rangées et grilles

struct IOSRail: View {
    let title: String
    let items: [MediaItem]
    var resume = false
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title).font(.title3.weight(.semibold))
                    Spacer()
                    if items.count > 12 {
                        NavigationLink {
                            IOSItemGridPage(title: title, items: items)
                        } label: {
                            Text("Voir tout").font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(items.prefix(30)) { item in
                            Button { ui.open(item, store: store, playback: playback) } label: {
                                if item.kind == .live {
                                    ChannelTile(item: item)
                                } else {
                                    PosterCard(item: item, progress: resume ? watch.fraction(for: item.id) : nil)
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(store.isFavorite(item.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris"),
                                       systemImage: store.isFavorite(item.id) ? "star.slash" : "star") {
                                    store.toggleFavorite(item.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

/// Page « Voir tout » d'une rangée.
struct IOSItemGridPage: View {
    let title: String
    let items: [MediaItem]

    var body: some View {
        ScrollView { IOSItemGrid(items: items) }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// Grille de vignettes (affiches ou chaînes).
struct IOSItemGrid: View {
    let items: [MediaItem]
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui

    @AppStorage(IOSKeys.cardSize) private var sizeRaw = IOSCardSize.medium.rawValue

    private var columns: [GridItem] {
        let side = IOSCardSize.current(sizeRaw).width
        return [GridItem(.adaptive(minimum: side, maximum: side + 40), spacing: 12, alignment: .top)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            ForEach(items.prefix(3000)) { item in
                Button { ui.open(item, store: store, playback: playback) } label: {
                    if item.kind == .live {
                        VStack(alignment: .leading, spacing: 6) {
                            ArtworkView(url: item.logoURL, name: item.name)
                                .frame(height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Text(item.name).font(.caption.weight(.medium)).lineLimit(2)
                        }
                    } else {
                        PosterCard(item: item, progress: watch.fraction(for: item.id))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Accueil Cinéma

/// À la une, reprise, favoris, puis une rangée par catégorie (et par thème pour le direct).
struct IOSCinemaHome: View {
    let kind: MediaKind
    @Environment(LibraryStore.self) private var store
    @Environment(WatchProgressStore.self) private var watch
    @AppStorage(IOSHeroKeys.enabled) private var heroEnabled = true
    @AppStorage(CountryKeys.codes) private var countryCodes = ""
    @AppStorage(CountryKeys.neutral) private var countryNeutral = true
    @State private var search = ""

    var body: some View {
        let key = search.kastideoSearchKey
        ScrollView {
            if !key.isEmpty {
                IOSItemGrid(items: store.items(for: .all(kind)).filter { $0.searchKey.contains(key) })
            } else {
                home
            }
        }
        .searchable(text: $search, prompt: kind == .live ? "Rechercher une chaîne" : "Rechercher")
        .refreshable { store.refreshAll() }
    }

    @ViewBuilder
    private var home: some View {
        let kinds: Set<MediaKind> = kind == .series ? [.series, .episode] : [kind]
        let countries = CountryFilter(stored: countryCodes, keepNeutral: countryNeutral)
        let all = store.items(for: .all(kind))
        let allRecents = store.recentIDs.compactMap { store.item(id: $0) }.filter { kinds.contains($0.kind) }
        let started = kind == .live ? [] : allRecents.filter { watch.inResume($0.id) }
        let recents = kind == .live ? allRecents : allRecents.filter { !watch.inResume($0.id) }
        let favorites = store.favoriteIDs.compactMap { store.item(id: $0) }.filter { kinds.contains($0.kind) }
        var categories = (store.categoriesByKind[kind] ?? []).filter {
            countries.allows(category: $0) || store.libraryCategories[kind]?.contains($0) == true
        }
        // La catégorie choisie comme page de départ (Réglages > Organisation) ouvre la série de rangées.
        let startValue = UserDefaults.standard.string(forKey: StartPage.key(kind)) ?? "all"
        let startName: String? = startValue == "last" ? UserDefaults.standard.string(forKey: StartPage.lastKey(kind))
            : (startValue.hasPrefix("category:") ? String(startValue.dropFirst("category:".count)) : nil)
        if let startName, let at = categories.firstIndex(of: startName), at > 0 {
            categories.move(fromOffsets: IndexSet(integer: at), toOffset: 0)
        }
        if all.isEmpty {
            ContentUnavailableView(kind.title, systemImage: "tray",
                                   description: Text(store.hasSources ? String(localized: "Aucun contenu pour cette sélection.") : String(localized: "Ajoutez une source dans Réglages.")))
                .frame(maxWidth: .infinity, minHeight: 360)
        } else {
            LazyVStack(alignment: .leading, spacing: 24) {
                if heroEnabled { IOSHero(kind: kind) }
                if kind == .live {
                    ForEach(ContentTheme.browsable.filter { $0 != .general && $0 != .other }) { theme in
                        let airing = store.liveGroups.filter { group in
                            guard let programme = store.epg.current(for: group.epgID) else { return false }
                            return (programme.theme ?? group.theme) == theme
                        }.map(\.preferred)
                        IOSRail(title: theme.nowTitle, items: airing)
                    }
                    if ReplaySettings.enabled {
                        var seen = Set<String>()
                        let replayable = (favorites + allRecents).filter { ($0.archiveDays ?? 0) > 0 && seen.insert($0.id).inserted }
                        IOSRail(title: String(localized: "À revoir (replay)"), items: replayable)
                    }
                }
                IOSRail(title: String(localized: "Reprendre la lecture"), items: started, resume: true)
                IOSRail(title: kind == .live ? String(localized: "Regardées récemment") : String(localized: "Regardés récemment"),
                        items: recents)
                IOSRail(title: String(localized: "Favoris"), items: favorites)
                ForEach(categories, id: \.self) { name in
                    IOSRail(title: name, items: store.items(for: .category(kind, name)))
                }
            }
            .padding(.vertical, 12)
        }
    }
}
