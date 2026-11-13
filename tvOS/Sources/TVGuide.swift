import SwiftUI
import KastideoCore

/// Guide TV : une ligne par chaîne avec le programme en cours (barre de progression) et le suivant.
/// La grille horaire complète viendra dans une version suivante.
struct TVGuideView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(TVUI.self) private var ui
    @State private var category: String?

    private var categories: [String] { store.categoriesByKind[.live] ?? [] }

    private var channels: [MediaItem] {
        let name = category ?? categories.first
        guard let name else { return [] }
        return store.items(for: .category(.live, name))
    }

    var body: some View {
        if !store.hasSources || store.count(for: .live) == 0 {
            TVEmptyView(text: String(localized: "Le guide apparaît quand une source de direct est chargée."))
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(categories, id: \.self) { name in
                                Button { category = name } label: {
                                    Text(name).font(.callout.weight((category ?? categories.first) == name ? .bold : .regular))
                                }
                                .tint((category ?? categories.first) == name ? TVPalette.orange : nil)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    let list = channels
                    ForEach(list.prefix(120)) { channel in
                        Button { ui.play(channel, list: list, playback: playback) } label: { row(channel) }
                            .buttonStyle(.card)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 30)
            }
        }
    }

    private func row(_ channel: MediaItem) -> some View {
        let now = store.epg.current(for: channel.epgID)
        let next = store.epg.upcoming(for: channel.epgID, limit: 1).first
        return HStack(spacing: 28) {
            ArtworkView(url: channel.logoURL, name: channel.name)
                .frame(width: 140, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                Text(channel.name).font(.headline).lineLimit(1)
                if let now {
                    Text("\(now.title) · \(now.timeRange())").font(.callout).lineLimit(1)
                    ProgressView(value: now.progress()).tint(TVPalette.orange).frame(maxWidth: 520)
                } else {
                    Text("Programme non disponible").font(.callout).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let next {
                Text("Ensuite · \(next.title)").font(.callout).foregroundStyle(.secondary).lineLimit(1).frame(maxWidth: 420, alignment: .trailing)
            }
        }
        .padding(18)
    }
}
