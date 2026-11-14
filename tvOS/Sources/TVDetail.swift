import SwiftUI
import KastideoCore

/// Fiche d'un film ou d'une série : résumé, lecture / reprise, favoris, saisons et épisodes.
struct TVDetailView: View {
    let item: MediaItem
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(TVUI.self) private var ui
    @Environment(MediaInfoStore.self) private var mediaInfo
    @State private var seasons: [SeriesSeason] = []
    @State private var selectedSeason = 0
    @State private var loadError: String?
    @State private var loading = false

    var body: some View {
        ZStack {
            TVBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HStack(alignment: .top, spacing: 50) {
                        ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill)
                            .frame(width: 300, height: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        VStack(alignment: .leading, spacing: 20) {
                            Text(TMDB.cleanTitle(item.name).title).font(.largeTitle.bold())
                            if let d = mediaInfo.details(for: item) {
                                let meta = [d.year.map(String.init), d.runtime.map { "\($0) min" }, d.rating.map { String(format: "★ %.1f", $0) },
                                            d.genres.prefix(3).joined(separator: ", ")].compactMap { $0 }.filter { !$0.isEmpty }
                                if !meta.isEmpty { Text(meta.joined(separator: " · ")).font(.callout).foregroundStyle(TVPalette.orange) }
                                if let plot = d.plot ?? item.info, !plot.isEmpty {
                                    Text(plot).font(.callout).foregroundStyle(.secondary).lineLimit(8)
                                }
                                if !d.directors.isEmpty { Text("De \(d.directors.joined(separator: ", "))").font(.callout) }
                                if !d.cast.isEmpty { Text("Avec \(d.cast.prefix(6).map(\.name).joined(separator: ", "))").font(.callout).foregroundStyle(.secondary).lineLimit(2) }
                            } else if let info = item.info, !info.isEmpty {
                                Text(info).font(.callout).foregroundStyle(.secondary).lineLimit(8)
                            }
                            HStack(spacing: 24) {
                                if item.kind == .movie {
                                    Button { play(item) } label: {
                                        Label(watch.inResume(item.id) ? "Reprendre" : "Lire", systemImage: "play.fill")
                                    }
                                }
                                Button { store.toggleFavorite(item.id) } label: {
                                    Label(store.isFavorite(item.id) ? "Retirer des favoris" : "Ajouter aux favoris",
                                          systemImage: store.isFavorite(item.id) ? "star.slash" : "star")
                                }
                                Button { ui.detail = nil } label: { Label("Fermer", systemImage: "xmark") }
                            }
                        }
                    }
                    if item.kind == .series { episodes }
                }
                .padding(80)
            }
        }
        .task { await mediaInfo.load(item, store: store) }
        .task { if item.kind == .series { await loadSeasons() } }
    }

    @ViewBuilder
    private var episodes: some View {
        if loading {
            ProgressView()
        } else if let loadError {
            Text(loadError).foregroundStyle(.red)
        } else if !seasons.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(Array(seasons.enumerated()), id: \.offset) { index, season in
                        Button { selectedSeason = index } label: {
                            Text("Saison \(season.number)").fontWeight(index == selectedSeason ? .bold : .regular)
                        }
                        .tint(index == selectedSeason ? TVPalette.orange : nil)
                    }
                }
            }
            let list = seasons.indices.contains(selectedSeason) ? seasons[selectedSeason].episodes : []
            ForEach(list) { episode in
                Button { ui.episodeContext = seasons.flatMap(\.episodes); play(episode) } label: {
                    HStack {
                        Text(episode.name).lineLimit(1)
                        Spacer()
                        if let fraction = watch.fraction(for: episode.id) {
                            ProgressView(value: fraction).frame(width: 160).tint(TVPalette.orange)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func play(_ target: MediaItem) {
        ui.detail = nil
        // Le plein écran du détail doit être refermé avant d'ouvrir le lecteur.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            ui.play(target, playback: playback)
        }
    }

    private func loadSeasons() async {
        loading = true
        defer { loading = false }
        do {
            seasons = try await store.seasons(for: item)
            if let index = seasons.firstIndex(where: { $0.episodes.contains { watch.fraction(for: $0.id) != nil } }) {
                selectedSeason = index
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}
