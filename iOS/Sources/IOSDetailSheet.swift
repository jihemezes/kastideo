import SwiftUI
import KastideoCore

/// Fiche d'un film ou d'une série : résumé, lecture, favoris, saisons et épisodes.
struct IOSDetailSheet: View {
    let item: MediaItem
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui
    @Environment(IOSDownloads.self) private var downloads
    @Environment(\.dismiss) private var dismiss
    @State private var seasons: [SeriesSeason] = []
    @State private var selectedSeason = 0
    @State private var loadingSeasons = false
    @State private var seasonsError: String?

    private var isSeriesWithEpisodes: Bool { item.kind == .series && item.streamURL == nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 16) {
                        ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill)
                            .frame(width: 120, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.name).font(.title3.bold())
                            Text(meta).font(.subheadline).foregroundStyle(.secondary)
                            if !item.group.isEmpty { Text(item.group).font(.caption).foregroundStyle(.secondary) }
                            if let fraction = watch.fraction(for: item.id), let entry = watch.entries[item.id] {
                                VStack(alignment: .leading, spacing: 3) {
                                    ProgressView(value: fraction).tint(IOSPalette.orange)
                                    Text("Reprise à \(entry.position.clockString)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        if !isSeriesWithEpisodes {
                            Button { play(item) } label: {
                                Label(watch.fraction(for: item.id) != nil ? "Reprendre" : "Lire", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent).controlSize(.large)
                        }
                        if !isSeriesWithEpisodes, IOSDownloads.canDownload(item) {
                            Button { downloads.add(item) } label: {
                                Image(systemName: downloads.isQueued(item) ? "checkmark.circle" : "arrow.down.circle").frame(width: 28)
                            }
                            .buttonStyle(.bordered).controlSize(.large)
                            .disabled(downloads.isQueued(item))
                        }
                        Button { store.toggleFavorite(item.id) } label: {
                            Image(systemName: store.isFavorite(item.id) ? "star.fill" : "star").frame(width: 28)
                        }
                        .buttonStyle(.bordered).controlSize(.large)
                    }

                    if let info = item.info, !info.isEmpty {
                        Text(info).font(.body)
                    }

                    if isSeriesWithEpisodes { episodes }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } }
            }
            .task { await loadSeasons() }
        }
    }

    private var meta: String {
        var parts: [String] = []
        if let year = item.year { parts.append(String(year)) }
        if let runtime = item.runtime { parts.append("\(runtime) min") }
        if let rating = item.rating, rating > 0 { parts.append(String(format: "★ %.1f", rating)) }
        if let genres = item.genres, !genres.isEmpty { parts.append(genres.prefix(2).joined(separator: ", ")) }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var episodes: some View {
        if loadingSeasons {
            HStack { ProgressView(); Text("Chargement des épisodes…").foregroundStyle(.secondary) }
        } else if let seasonsError {
            Text(seasonsError).foregroundStyle(.red).font(.footnote)
        } else if !seasons.isEmpty {
            Picker("Saison", selection: $selectedSeason) {
                ForEach(Array(seasons.enumerated()), id: \.offset) { index, season in
                    Text("Saison \(season.number)").tag(index)
                }
            }
            .pickerStyle(.menu)
            let list = seasons.indices.contains(selectedSeason) ? seasons[selectedSeason].episodes : []
            let downloadable = list.filter { IOSDownloads.canDownload($0) && !downloads.isQueued($0) }
            if !downloadable.isEmpty {
                Button {
                    for episode in downloadable { downloads.add(episode) }
                } label: {
                    Label("Télécharger la saison (\(downloadable.count) épisodes)", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.bordered)
                Text("Maintenez un épisode pour ne télécharger que celui-ci.").font(.caption).foregroundStyle(.secondary)
            }
            VStack(spacing: 0) {
                ForEach(list) { episode in
                    Button { play(episode) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: watch.isWatched(episode.id) ? "checkmark.circle.fill" : "play.circle")
                                .font(.title3)
                                .foregroundStyle(watch.isWatched(episode.id) ? IOSPalette.orange : .secondary)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(episode.name).font(.subheadline).lineLimit(2).multilineTextAlignment(.leading)
                                if let fraction = watch.fraction(for: episode.id) {
                                    ProgressView(value: fraction).tint(IOSPalette.orange)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if IOSDownloads.canDownload(episode) {
                            Button { downloads.add(episode) } label: { Label("Télécharger", systemImage: "arrow.down.circle") }
                        }
                    }
                    Divider()
                }
            }
        } else {
            Text("Aucun épisode trouvé.").foregroundStyle(.secondary)
        }
    }

    private func play(_ target: MediaItem) {
        ui.detail = nil
        ui.play(target, store: store, playback: playback)
    }

    private func loadSeasons() async {
        guard isSeriesWithEpisodes else { return }
        loadingSeasons = true
        defer { loadingSeasons = false }
        do {
            seasons = try await store.seasons(for: item)
            // Ouvre la saison où l'on s'est arrêté.
            if let index = seasons.firstIndex(where: { $0.episodes.contains { watch.fraction(for: $0.id) != nil } }) {
                selectedSeason = index
            }
        } catch {
            seasonsError = error.localizedDescription
        }
    }
}
