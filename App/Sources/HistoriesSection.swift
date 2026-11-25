import SwiftUI

/// Section « Historiques » des réglages (Mac, iPhone / iPad, Apple TV) : vider les récents, les positions de reprise
/// et l'historique YouTube, un par un ou tout d'un coup. Les favoris, les sources et les réglages ne sont jamais touchés.
struct HistoriesSection: View {
    @Environment(LibraryStore.self) private var store
    @Environment(WatchProgressStore.self) private var watch
    @State private var pending: Kind?
    @State private var confirmAll = false

    private enum Kind: String, Identifiable {
        case recents, progress, youtube
        var id: String { rawValue }
    }

    private var youtubeCount: Int {
        #if os(tvOS)
        0
        #else
        YouTubeStore.shared.history.count
        #endif
    }

    private func count(_ kind: Kind) -> Int {
        switch kind {
        case .recents: store.recentIDs.count
        case .progress: watch.count
        case .youtube: youtubeCount
        }
    }

    private func title(_ kind: Kind) -> String {
        switch kind {
        case .recents: String(localized: "Récents")
        case .progress: String(localized: "Vus et reprise de lecture")
        case .youtube: String(localized: "Historique YouTube")
        }
    }

    private func detail(_ kind: Kind) -> String {
        switch kind {
        case .recents: String(localized: "Chaînes, films et épisodes ouverts récemment")
        case .progress: String(localized: "Marques « vu » et positions de reprise des films et épisodes")
        case .youtube: String(localized: "Vidéos YouTube regardées")
        }
    }

    private var kinds: [Kind] {
        #if os(tvOS)
        [.recents, .progress]
        #else
        [.recents, .progress, .youtube]
        #endif
    }

    private func clear(_ kind: Kind) {
        switch kind {
        case .recents: store.clearRecents()
        case .progress: watch.clearAll()
        case .youtube:
            #if !os(tvOS)
            YouTubeStore.shared.clearHistory()
            #endif
        }
    }

    var body: some View {
        Section {
            ForEach(kinds) { kind in
                Button {
                    pending = kind
                } label: {
                    HStack {
                        Text(title(kind))
                        Spacer()
                        Text("\(count(kind))").foregroundStyle(.secondary)
                    }
                }
                .disabled(count(kind) == 0)
            }
            Button(role: .destructive) {
                confirmAll = true
            } label: {
                Text("Tout effacer")
            }
            .disabled(kinds.allSatisfy { count($0) == 0 })
        } header: {
            Text("Historiques").settingsHeader()
        } footer: {
            Text("Les favoris, les sources et les réglages ne sont pas touchés.")
        }
        .confirmationDialog(pending.map { title($0) } ?? "", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }), titleVisibility: .visible, presenting: pending) { kind in
            Button("Effacer", role: .destructive) { clear(kind) }
            Button("Annuler", role: .cancel) {}
        } message: { kind in
            Text(detail(kind))
        }
        .confirmationDialog("Tout effacer", isPresented: $confirmAll, titleVisibility: .visible) {
            Button("Tout effacer", role: .destructive) { kinds.forEach(clear) }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Efface tous les historiques ci-dessus.")
        }
    }
}
