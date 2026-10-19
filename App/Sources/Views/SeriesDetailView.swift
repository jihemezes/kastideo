import SwiftUI
import KastideoCore

/// Fiche d'une série Xtream : saisons, épisodes et lecteur intégré.
struct SeriesDetailView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    let series: MediaItem

    @State private var seasons: [SeriesSeason] = []
    @State private var selectedSeason: Int?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if let current = playback.current, current.kind == .episode, current.group == series.name {
                VideoSurface()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 280, idealHeight: 420, maxHeight: 520)
                Divider()
            }

            header
            Divider()

            if isLoading {
                ProgressView("Chargement des épisodes…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                ContentUnavailableView("Épisodes indisponibles", systemImage: "exclamationmark.triangle",
                                       description: Text(errorMessage))
            } else if seasons.isEmpty {
                ContentUnavailableView("Aucun épisode", systemImage: "rectangle.stack")
            } else {
                episodeList
            }
        }
        .task {
            if let current = playback.current, !(current.kind == .episode && current.group == series.name),
               !recordings.isPlayerRecording {
                playback.stop()
            }
            await load()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            LogoView(url: series.logoURL, name: series.name, size: 84)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(series.name).font(.title2.weight(.semibold))
                    Spacer()
                    if !seasons.isEmpty {
                        Menu {
                            let season = seasons.first { $0.number == selectedSeason } ?? seasons[0]
                            Section("Saison \(season.number) (\(season.episodes.count) épisodes)") {
                                Button("Télécharger maintenant") { recordings.download(season.episodes, tonight: false) }
                                Button("Télécharger cette nuit") { recordings.download(season.episodes, tonight: true) }
                            }
                            if seasons.count > 1 {
                                let all = seasons.flatMap(\.episodes)
                                Section("Toute la série (\(all.count) épisodes)") {
                                    Button("Télécharger maintenant") { recordings.download(all, tonight: false) }
                                    Button("Télécharger cette nuit") { recordings.download(all, tonight: true) }
                                }
                            }
                        } label: {
                            Label("Télécharger", systemImage: "arrow.down.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .help("Télécharger des épisodes sans les regarder (en file d'attente)")
                    }
                    Button {
                        store.toggleFavorite(series.id)
                    } label: {
                        Image(systemName: store.isFavorite(series.id) ? "star.fill" : "star")
                            .foregroundStyle(store.isFavorite(series.id) ? .yellow : .secondary)
                    }
                    .buttonStyle(.borderless)
                }
                Text(series.group).font(.subheadline).foregroundStyle(.secondary)
                if let info = series.info {
                    Text(info).font(.callout).lineLimit(3)
                }
                if seasons.count > 1 {
                    Picker("Saison", selection: $selectedSeason) {
                        ForEach(seasons) { season in
                            Text("Saison \(season.number)").tag(Optional(season.number))
                        }
                    }
                    .frame(maxWidth: 220)
                }
            }
        }
        .padding(16)
    }

    private var episodeList: some View {
        let season = seasons.first { $0.number == selectedSeason } ?? seasons[0]
        return List(season.episodes) { episode in
            Button {
                recordings.requestPlay(episode)
                store.recordPlay(episode)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: playback.current?.id == episode.id ? "speaker.wave.2.fill" : "play.circle")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(episodeTitle(episode)).lineLimit(1)
                        if let info = episode.info {
                            Text(info).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Télécharger l'épisode") { recordings.download(episode, tonight: false) }
                Button("Télécharger l'épisode cette nuit") { recordings.download(episode, tonight: true) }
            }
        }
        .listStyle(.inset)
    }

    private func episodeTitle(_ episode: MediaItem) -> String {
        guard let number = episode.number else { return episode.name }
        return "\(number). \(episode.name)"
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            seasons = try await store.seasons(for: series)
            selectedSeason = seasons.first?.number
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
