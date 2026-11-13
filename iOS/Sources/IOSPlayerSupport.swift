import SwiftUI
import KastideoCore

/// Épisodes de la série en cours de lecture (dans l'ordre des saisons).
struct IOSEpisodeContext {
    let series: MediaItem
    let episodes: [MediaItem]
}

/// Indication brève au centre du lecteur (volume, luminosité, saut, vitesse…).
struct IOSPlayerHUD: Equatable {
    var icon: String
    var text: String
    var value: Double?
}

extension IOSUI {
    /// Chaînes parmi lesquelles on zappe : la catégorie de la chaîne (à défaut, toutes les chaînes).
    func zapList(for item: MediaItem, store: LibraryStore) -> [MediaItem] {
        let prefs = store.prefs(for: .live)
        var list = store.items(for: .category(.live, prefs.displayName(item.group)))
        if !list.contains(where: { $0.id == item.id }) { list = store.items(for: .category(.live, item.group)) }
        if !list.contains(where: { $0.id == item.id }) { list = store.items(for: .all(.live)) }
        return list
    }

    func nextEpisode(after item: MediaItem) -> MediaItem? {
        guard let episodes = episodeContext?.episodes,
              let index = episodes.firstIndex(where: { $0.id == item.id }),
              index + 1 < episodes.count else { return nil }
        return episodes[index + 1]
    }

    /// Fin d'un épisode : lance le suivant si l'option est active.
    func playNextEpisode(after item: MediaItem, store: LibraryStore, playback: PlaybackController) {
        guard UserDefaults.standard.object(forKey: "ios.autonext") as? Bool ?? true,
              let next = nextEpisode(after: item) else { return }
        play(next, store: store, playback: playback)
    }
}

/// Liste des épisodes de la série en cours de lecture.
struct IOSEpisodeListSheet: View {
    let context: IOSEpisodeContext
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(context.episodes) { episode in
                Button {
                    ui.play(episode, store: store, playback: playback)
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: playback.current?.id == episode.id ? "play.fill"
                              : (watch.isWatched(episode.id) ? "checkmark.circle.fill" : "circle"))
                            .foregroundStyle(playback.current?.id == episode.id ? IOSPalette.orange : .secondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(episode.name).lineLimit(2).multilineTextAlignment(.leading)
                            if let season = episode.season {
                                Text("Saison \(season)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle(TMDB.cleanTitle(context.series.name).title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
