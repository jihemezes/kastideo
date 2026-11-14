import SwiftUI
import KastideoCore

/// Direct, Films ou Séries : barre de catégories + grille. Un appui lance la lecture (direct) ou ouvre la fiche.
struct TVBrowseView: View {
    let kind: MediaKind
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(TVUI.self) private var ui
    @State private var scope: TVScope = .none

    private var categories: [String] { store.categoriesByKind[kind] ?? [] }

    private var items: [MediaItem] {
        switch effectiveScope {
        case .none, .all: return store.items(for: .all(kind))
        case .favorites: return store.favoriteIDs.compactMap { store.item(id: $0) }.filter { $0.kind == kind || (kind == .series && $0.kind == .episode) }
        case .recents: return store.recentIDs.compactMap { store.item(id: $0) }.filter { $0.kind == kind || (kind == .series && $0.kind == .episode) }
        case .category(let name): return store.items(for: .category(kind, name))
        }
    }

    /// Sans choix, la première catégorie (tout le catalogue d'un fournisseur serait trop lourd à afficher).
    private var effectiveScope: TVScope {
        if scope != .none { return scope }
        switch StartPage.destination(for: kind, categories: categories) {
        case .favorites: return .favorites
        case .recents: return .recents
        case .category(_, let name): return .category(name)
        default: break
        }
        if let first = categories.first { return .category(first) }
        return .all
    }

    var body: some View {
        if !store.hasSources {
            TVEmptyView(text: String(localized: "Ajoutez une source dans Réglages."))
        } else if store.count(for: kind) == 0 {
            TVEmptyView(text: store.loading.isEmpty ? String(localized: "Aucun contenu pour cette section.") : String(localized: "Chargement des sources…"))
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    chips
                    let shown = items
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 40) {
                        ForEach(shown.prefix(240)) { item in
                            Button { open(item, list: shown) } label: { tile(item) }
                                .buttonStyle(.card)
                        }
                    }
                    if shown.count > 240 {
                        Text("\(shown.count) contenus : affinez par catégorie.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 30)
            }
        }
    }

    private var columns: [GridItem] {
        kind == .live
            ? [GridItem(.adaptive(minimum: 260, maximum: 300), spacing: 36, alignment: .top)]
            : [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 36, alignment: .top)]
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                chip(String(localized: "Toutes"), .all)
                chip(String(localized: "Favoris"), .favorites)
                chip(String(localized: "Récents"), .recents)
                ForEach(categories, id: \.self) { name in chip(name, .category(name)) }
            }
            .padding(.vertical, 10)
        }
    }

    private func chip(_ title: String, _ value: TVScope) -> some View {
        Button {
            scope = value
            if case .category(let name) = value { UserDefaults.standard.set(name, forKey: StartPage.lastKey(kind)) }
        } label: {
            Text(title).font(.callout.weight(effectiveScope == value ? .bold : .regular)).padding(.horizontal, 10)
        }
        .tint(effectiveScope == value ? TVPalette.orange : nil)
    }

    private func open(_ item: MediaItem, list: [MediaItem]) {
        if item.kind == .live {
            ui.play(item, list: list, playback: playback)
        } else {
            ui.detail = item
        }
    }

    @ViewBuilder
    private func tile(_ item: MediaItem) -> some View {
        if item.kind == .live {
            VStack(spacing: 10) {
                ArtworkView(url: item.logoURL, name: item.name)
                    .frame(height: 130)
                Text(item.name).font(.caption).lineLimit(2).multilineTextAlignment(.center)
                if let programme = store.epg.current(for: item.epgID) {
                    Text(programme.title).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .padding(12)
        } else {
            VStack(spacing: 8) {
                ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill)
                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                Text(TMDB.cleanTitle(item.name).title).font(.caption).lineLimit(2).multilineTextAlignment(.center)
                    .padding(.horizontal, 6).padding(.bottom, 8)
            }
        }
    }
}

enum TVScope: Hashable {
    case none, all, favorites, recents
    case category(String)
}

struct TVEmptyView: View {
    let text: String
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv").font(.system(size: 90)).foregroundStyle(.secondary)
            Text(text).font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
