import SwiftUI
import KastideoCore

/// Accueil : bandeau à la une (reprise ou dernier ajout) puis rangées « Reprendre », chaînes favorites et récentes,
/// derniers films et séries (et tendances TMDB quand une clé est saisie).
struct TVHomeView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(MediaInfoStore.self) private var info
    @Environment(TVUI.self) private var ui
    @State private var trendingMovies: [MediaItem] = []
    @State private var trendingSeries: [MediaItem] = []

    private var resume: [MediaItem] {
        watch.entries
            .filter { watch.inResume($0.key) }
            .sorted { $0.value.updatedAt > $1.value.updatedAt }
            .compactMap { store.item(id: $0.key) }
            .prefix(20).map { $0 }
    }
    private var favoriteChannels: [MediaItem] {
        store.favoriteIDs.compactMap { store.item(id: $0) }.filter { $0.kind == .live }.prefix(30).map { $0 }
    }
    private var recentChannels: [MediaItem] {
        store.recentIDs.compactMap { store.item(id: $0) }.filter { $0.kind == .live }.prefix(30).map { $0 }
    }
    private func latest(_ kind: MediaKind) -> [MediaItem] {
        let all = store.items(for: .all(kind))
        let dated = all.filter { $0.added != nil }.sorted { ($0.added ?? .distantPast) > ($1.added ?? .distantPast) }
        return (dated.isEmpty ? all : dated).prefix(30).map { $0 }
    }
    /// Chaînes dont un programme est en cours (guide), pour une rangée « En ce moment ».
    private var onNow: [MediaItem] {
        guard let first = store.categoriesByKind[.live]?.first else { return [] }
        return store.items(for: .category(.live, first)).filter { store.epg.current(for: $0.epgID) != nil }.prefix(30).map { $0 }
    }
    private var firstChannels: [MediaItem] {
        guard let first = store.categoriesByKind[.live]?.first else { return [] }
        return store.items(for: .category(.live, first)).prefix(30).map { $0 }
    }

    var body: some View {
        if !store.hasSources {
            TVEmptyView(text: String(localized: "Bienvenue dans Kastideo. Ajoutez une source dans Réglages (ou depuis votre téléphone)."))
        } else {
            let resumeItems = resume
            let movies = latest(.movie)
            let series = latest(.series)
            let live = onNow.isEmpty ? firstChannels : onNow
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    if let hero = resumeItems.first ?? movies.first ?? series.first ?? live.first {
                        heroBanner(hero, resuming: resumeItems.first != nil)
                    }
                    shortcuts
                    if !store.loading.isEmpty && movies.isEmpty && series.isEmpty && live.isEmpty {
                        HStack(spacing: 16) { ProgressView(); Text("Chargement des sources…").foregroundStyle(.secondary) }
                    }
                    rail(String(localized: "Reprendre la lecture"), resumeItems, poster: true)
                    rail(String(localized: "Chaînes favorites"), favoriteChannels, poster: false)
                    rail(String(localized: "Chaînes récentes"), recentChannels, poster: false)
                    rail(String(localized: "En ce moment"), live, poster: false)
                    rail(String(localized: "Tendances · Films"), trendingMovies, poster: true)
                    rail(String(localized: "Tendances · Séries"), trendingSeries, poster: true)
                    rail(String(localized: "Derniers films"), movies, poster: true)
                    rail(String(localized: "Dernières séries"), series, poster: true)
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
            }
            .task(id: info.tmdbKey) { await loadTrends() }
        }
    }

    private func loadTrends() async {
        guard info.usesTMDB else { trendingMovies = []; trendingSeries = []; return }
        let movieTrends = await info.trending(isSeries: false)
        let seriesTrends = await info.trending(isSeries: true)
        trendingMovies = await info.match(movieTrends, in: store.items(for: .all(.movie)), kind: .movie).map(\.item)
        trendingSeries = await info.match(seriesTrends, in: store.items(for: .all(.series)), kind: .series).map(\.item)
    }

    private func open(_ item: MediaItem) {
        switch item.kind {
        case .live: ui.play(item, list: store.items(for: .all(.live)), playback: playback)
        case .episode: ui.play(item, playback: playback)
        default: ui.detail = item
        }
    }

    private var shortcuts: some View {
        HStack(spacing: 24) {
            shortcut("Direct", "tv", 1, store.count(for: .live))
            shortcut("Films", "film", 2, store.count(for: .movie))
            shortcut("Séries", "rectangle.stack", 3, store.count(for: .series))
            shortcut("Guide TV", "calendar", 4, nil)
            shortcut("Réglages", "gearshape", 5, nil)
        }
    }

    private func shortcut(_ title: String, _ icon: String, _ tab: Int, _ count: Int?) -> some View {
        Button { ui.tab = tab } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 44))
                Text(LocalizedStringKey(title)).font(.callout.weight(.semibold))
                if let count, count > 0 { Text("\(count)").font(.caption).foregroundStyle(.secondary) }
            }
            .frame(maxWidth: .infinity, minHeight: 130)
        }
        .buttonStyle(.card)
    }

    private func heroBanner(_ item: MediaItem, resuming: Bool) -> some View {
        Button { open(item) } label: {
            ZStack(alignment: .bottomLeading) {
                ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 420)
                    .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 8) {
                    Text(resuming ? "REPRENDRE" : "À DÉCOUVRIR").font(.caption.weight(.bold)).foregroundStyle(TVPalette.orange)
                    Text(TMDB.cleanTitle(item.name).title).font(.largeTitle.bold()).lineLimit(2)
                    if let text = item.info, !text.isEmpty {
                        Text(text).font(.callout).foregroundStyle(.secondary).lineLimit(2).frame(maxWidth: 900, alignment: .leading)
                    }
                }
                .padding(36)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.card)
    }

    @ViewBuilder
    private func rail(_ title: String, _ items: [MediaItem], poster: Bool) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text(title).font(.title3.bold())
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 30) {
                        ForEach(items) { item in
                            Button { open(item) } label: { card(item, poster: poster) }
                                .buttonStyle(.card)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
    }

    private func card(_ item: MediaItem, poster: Bool) -> some View {
        VStack(spacing: 8) {
            if poster {
                ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill)
                    .frame(width: 200, height: 300)
                    .clipped()
            } else {
                ArtworkView(url: item.logoURL, name: item.name)
                    .frame(width: 200, height: 110)
                    .padding(.top, 10)
            }
            Text(TMDB.cleanTitle(item.name).title).font(.caption).lineLimit(1).frame(width: 190)
            if let fraction = watch.fraction(for: item.id) {
                ProgressView(value: fraction).tint(TVPalette.orange).frame(width: 170)
            } else if !poster, let programme = store.epg.current(for: item.epgID) {
                Text(programme.title).font(.caption2).foregroundStyle(.secondary).lineLimit(1).frame(width: 190)
            }
        }
        .padding(.bottom, 10)
    }
}
