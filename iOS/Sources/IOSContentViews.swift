import SwiftUI
import KastideoCore

// MARK: - Ouverture d'un contenu

extension IOSUI {
    /// Lance la lecture et affiche le lecteur plein écran.
    func play(_ item: MediaItem, store: LibraryStore, playback: PlaybackController) {
        store.recordPlay(item)
        playback.play(item)
        showPlayer = true
    }

    /// Chaînes et épisodes : lecture directe. Films et séries : fiche d'abord.
    func open(_ item: MediaItem, store: LibraryStore, playback: PlaybackController) {
        switch item.kind {
        case .live, .episode:
            play(item, store: store, playback: playback)
        case .movie, .series:
            detail = item
        }
    }
}

// MARK: - Cartes

/// Affiche d'un film ou d'une série (2:3), avec une barre de progression si la lecture est entamée.
struct PosterCard: View {
    let item: MediaItem
    var progress: Double?
    var width: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill)
                .frame(width: width, height: width * 1.5)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .bottom) {
                    if let progress {
                        ProgressView(value: progress)
                            .tint(IOSPalette.orange)
                            .padding(6)
                    }
                }
            Text(item.name)
                .font(.caption.weight(.medium))
                .lineLimit(2)
                .frame(width: width, alignment: .leading)
        }
    }
}

/// Vignette d'une chaîne (16:9) pour les rails de l'accueil.
struct ChannelTile: View {
    let item: MediaItem
    @Environment(LibraryStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ArtworkView(url: item.logoURL, name: item.name)
                .frame(width: 150, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(item.name).font(.caption.weight(.medium)).lineLimit(1).frame(width: 150, alignment: .leading)
            if let programme = store.epg.current(for: item.epgID) {
                Text(programme.title).font(.caption2).foregroundStyle(.secondary).lineLimit(1).frame(width: 150, alignment: .leading)
            }
        }
    }
}

// MARK: - Accueil

struct IOSHomeView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui

    private var resume: [MediaItem] {
        store.recentIDs.compactMap { store.item(id: $0) }
            .filter { $0.kind != .live && watch.inResume($0.id) }
            .prefix(14).map { $0 }
    }

    private var favorites: [MediaItem] { store.favoriteIDs.compactMap { store.item(id: $0) }.prefix(30).map { $0 } }
    private var recents: [MediaItem] { store.recentIDs.compactMap { store.item(id: $0) }.prefix(20).map { $0 } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    if !store.hasSources {
                        welcome
                    } else if store.isBusy && store.itemsByKind.isEmpty {
                        HStack(spacing: 10) { ProgressView(); Text("Chargement des sources…").foregroundStyle(.secondary) }
                            .padding(.horizontal)
                    }
                    rail("Reprendre la lecture", items: resume, showProgress: true)
                    rail("Favoris", items: favorites)
                    rail("Récents", items: recents)
                    if store.hasSources {
                        HStack(spacing: 12) {
                            shortcut("Direct", "tv.fill", .live)
                            shortcut("Films", "film.fill", .movies)
                            shortcut("Séries", "rectangle.stack.fill", .series)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Kastideo")
            .refreshable { store.refreshAll() }
        }
    }

    private var welcome: some View {
        VStack(spacing: 14) {
            Image(systemName: "play.tv.fill").font(.system(size: 46)).foregroundStyle(IOSPalette.orange)
            Text("Bienvenue dans Kastideo").font(.title2.bold())
            Text("Ajoutez votre abonnement IPTV (Xtream Codes ou liste M3U), ou importez la configuration de votre Mac.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button { ui.showAddSource = true } label: {
                Label("Ajouter une source", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(IOSPalette.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func shortcut(_ title: LocalizedStringKey, _ icon: String, _ tab: IOSTab) -> some View {
        Button { ui.tab = tab } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.footnote.weight(.semibold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(IOSPalette.card, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func rail(_ title: LocalizedStringKey, items: [MediaItem], showProgress: Bool = false) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.title3.weight(.semibold)).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(items) { item in
                            Button { ui.open(item, store: store, playback: playback) } label: {
                                if item.kind == .live {
                                    ChannelTile(item: item)
                                } else {
                                    PosterCard(item: item, progress: showProgress ? watch.fraction(for: item.id) : nil)
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if showProgress {
                                    Button("Retirer de cette liste", systemImage: "eye.slash") { watch.hideResume([item.id]) }
                                }
                                Button(store.isFavorite(item.id) ? "Retirer des favoris" : "Ajouter aux favoris",
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

// MARK: - Direct

struct IOSLiveView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @State private var search = ""
    @State private var category: String?
    @State private var favoritesOnly = false

    private var channels: [MediaItem] {
        var list: [MediaItem]
        if favoritesOnly {
            list = store.items(for: .favorites).filter { $0.kind == .live }
        } else if let category {
            list = store.items(for: .category(.live, category))
        } else {
            list = store.items(for: .all(.live))
        }
        let key = search.kastideoSearchKey
        if !key.isEmpty { list = list.filter { $0.searchKey.contains(key) } }
        return list
    }

    var body: some View {
        NavigationStack {
            let list = channels
            List {
                ForEach(list.prefix(1500)) { item in
                    Button { ui.play(item, store: store, playback: playback) } label: {
                        ChannelRow(item: item, isCurrent: playback.current?.id == item.id)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button { store.toggleFavorite(item.id) } label: {
                            Label("Favori", systemImage: store.isFavorite(item.id) ? "star.slash" : "star")
                        }
                        .tint(IOSPalette.orange)
                    }
                }
                if list.count > 1500 {
                    Text("Affinez la recherche ou choisissez une catégorie pour voir les \(list.count - 1500) autres chaînes.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
            .overlay {
                if list.isEmpty {
                    ContentUnavailableView(favoritesOnly ? "Aucun favori" : "Aucune chaîne",
                                           systemImage: "tv",
                                           description: Text(store.hasSources ? "Aucun contenu pour cette sélection." : "Ajoutez une source dans Réglages."))
                }
            }
            .navigationTitle(category ?? (favoritesOnly ? String(localized: "Favoris") : String(localized: "Direct")))
            .searchable(text: $search, prompt: "Rechercher une chaîne")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle("Favoris seulement", systemImage: "star", isOn: $favoritesOnly)
                        Divider()
                        Button("Toutes les catégories") { category = nil }
                        ForEach(store.categoriesByKind[.live] ?? [], id: \.self) { name in
                            Button(name) { category = name; favoritesOnly = false }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

struct ChannelRow: View {
    let item: MediaItem
    var isCurrent = false
    @Environment(LibraryStore.self) private var store

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: item.logoURL, name: item.name)
                .frame(width: 56, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.body.weight(.medium)).lineLimit(1)
                if let programme = store.epg.current(for: item.epgID) {
                    Text(programme.title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    ProgressView(value: programme.progress()).tint(IOSPalette.orange)
                }
            }
            Spacer()
            if isCurrent { Image(systemName: "speaker.wave.2.fill").foregroundStyle(IOSPalette.orange) }
            if store.isFavorite(item.id) { Image(systemName: "star.fill").font(.caption).foregroundStyle(IOSPalette.orange) }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Films et séries

struct IOSCatalogView: View {
    let kind: MediaKind
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui
    @State private var search = ""
    @State private var category: String?

    private var items: [MediaItem] {
        var list = category.map { store.items(for: .category(kind, $0)) } ?? store.items(for: .all(kind))
        let key = search.kastideoSearchKey
        if !key.isEmpty { list = list.filter { $0.searchKey.contains(key) } }
        return list
    }

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 12, alignment: .top)] }

    var body: some View {
        NavigationStack {
            let list = items
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(list.prefix(3000)) { item in
                        Button { ui.open(item, store: store, playback: playback) } label: {
                            PosterCard(item: item, progress: watch.fraction(for: item.id), width: 110)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                if list.count > 3000 {
                    Text("Affinez la recherche ou choisissez une catégorie pour voir la suite.")
                        .font(.footnote).foregroundStyle(.secondary).padding()
                }
            }
            .overlay {
                if list.isEmpty {
                    ContentUnavailableView("Aucun contenu", systemImage: "film",
                                           description: Text(store.hasSources ? "Aucun contenu pour cette sélection." : "Ajoutez une source dans Réglages."))
                }
            }
            .navigationTitle(category ?? kind.title)
            .searchable(text: $search, prompt: "Rechercher")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Toutes les catégories") { category = nil }
                        ForEach(store.categoriesByKind[kind] ?? [], id: \.self) { name in
                            Button(name) { category = name }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}
