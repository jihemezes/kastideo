import SwiftUI
import KastideoCore

// MARK: - Ouverture d'un contenu

extension IOSUI {
    /// Lance la lecture et affiche le lecteur plein écran.
    func play(_ item: MediaItem, store: LibraryStore, playback: PlaybackController) {
        if let current = playback.current, current.kind == .live, item.kind == .live, current.id != item.id {
            previousChannel = current
        }
        if item.kind != .episode || !(episodeContext?.episodes.contains { $0.id == item.id } ?? false) {
            episodeContext = nil
        }
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
    /// Largeur imposée ; sinon celle choisie dans Réglages > Apparence.
    var width: CGFloat?
    @AppStorage(IOSKeys.cardSize) private var sizeRaw = IOSCardSize.medium.rawValue

    private var side: CGFloat { width ?? IOSCardSize.current(sizeRaw).width }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill)
                .frame(width: side, height: side * 1.5)
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
                .frame(width: side, alignment: .leading)
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

// MARK: - Direct

/// Liste des chaînes (le conteneur « Direct » fournit la pile de navigation).
struct IOSLiveList: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @State private var search = ""
    @State private var scope: IOSListScope = .all
    @State private var started = false
    @State private var arranging: String?

    private var channels: [MediaItem] {
        var list = scope.items(kind: .live, store: store)
        let key = search.kastideoSearchKey
        if !key.isEmpty { list = list.filter { $0.searchKey.contains(key) } }
        return list
    }

    var body: some View {
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
                .contextMenu { IOSChannelMenu(channel: item) }
            }
            if list.count > 1500 {
                Text("Affinez la recherche ou choisissez une catégorie pour voir les \(list.count - 1500) autres chaînes.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .overlay {
            if list.isEmpty {
                ContentUnavailableView(String(localized: "Aucune chaîne"),
                                       systemImage: "tv",
                                       description: Text(store.hasSources ? String(localized: "Aucun contenu pour cette sélection.") : String(localized: "Ajoutez une source dans Réglages.")))
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { IOSScopeBar(kind: .live, scope: $scope) }
        .navigationTitle(scope.title(kind: .live))
        .searchable(text: $search, prompt: "Rechercher une chaîne")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Toutes les chaînes") { scope = .all }
                    Button("Favoris", systemImage: "star") { scope = .favorites }
                    Button("Récents", systemImage: "clock") { scope = .recents }
                    if case .category(let name) = scope {
                        Divider()
                        Button("Réordonner les chaînes…", systemImage: "arrow.up.arrow.down") { arranging = name }
                    }
                    Divider()
                    ForEach(store.categoriesByKind[.live] ?? [], id: \.self) { name in
                        Button(name) { scope = .category(name) }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(item: Binding(get: { arranging.map(ArrangeTarget.init) }, set: { arranging = $0?.name })) { target in
            IOSChannelArrangeView(category: target.name)
        }
        .onAppear {
            guard !started else { return }
            started = true
            scope = IOSListScope.start(for: .live, store: store)
        }
        .onChange(of: ui.tab) { old, new in
            if new == .live && old != .live { scope = IOSListScope.start(for: .live, store: store) }
        }
        .onChange(of: scope) { _, new in
            if case .category(let name) = new { UserDefaults.standard.set(name, forKey: StartPage.lastKey(.live)) }
        }
    }
}

private struct ArrangeTarget: Identifiable {
    let name: String
    var id: String { name }
}

/// Menu d'une chaîne (appui long) : favori, replay, modification.
struct IOSChannelMenu: View {
    let channel: MediaItem
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui

    var body: some View {
        Button(store.isFavorite(channel.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris"),
               systemImage: store.isFavorite(channel.id) ? "star.slash" : "star") {
            store.toggleFavorite(channel.id)
        }
        let past = store.replayProgrammes(of: channel)
        if !past.isEmpty {
            Menu("Revoir (replay)") {
                ForEach(past) { programme in
                    Button("\(programme.start.formatted(.dateTime.weekday(.abbreviated).hour().minute())) — \(programme.title)") {
                        ui.playReplay(channel: channel, programme: programme, store: store, playback: playback)
                    }
                }
            }
        }
        Button("Modifier la chaîne…", systemImage: "pencil") { ui.editingChannel = channel }
    }
}

struct ChannelRow: View {
    let item: MediaItem
    var isCurrent = false
    @Environment(LibraryStore.self) private var store
    @AppStorage(IOSKeys.density) private var densityRaw = IOSDensity.standard.rawValue

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
        .padding(.vertical, IOSDensity.current(densityRaw).padding)
        .contentShape(Rectangle())
    }
}

// MARK: - Films et séries

/// Grille de tous les films ou séries (le conteneur fournit la pile de navigation).
struct IOSCatalogGrid: View {
    let kind: MediaKind
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui
    @AppStorage(IOSKeys.cardSize) private var sizeRaw = IOSCardSize.medium.rawValue
    @State private var search = ""
    @State private var scope: IOSListScope = .all
    @State private var started = false

    private var items: [MediaItem] {
        var list = scope.items(kind: kind, store: store)
        let key = search.kastideoSearchKey
        if !key.isEmpty { list = list.filter { $0.searchKey.contains(key) } }
        return list
    }

    private var tab: IOSTab { kind == .series ? .series : .movies }

    private var columns: [GridItem] {
        let side = IOSCardSize.current(sizeRaw).width
        return [GridItem(.adaptive(minimum: side, maximum: side + 40), spacing: 12, alignment: .top)]
    }

    var body: some View {
        let list = items
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(list.prefix(3000)) { item in
                    Button { ui.open(item, store: store, playback: playback) } label: {
                        PosterCard(item: item, progress: watch.fraction(for: item.id))
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
                                       description: Text(store.hasSources ? String(localized: "Aucun contenu pour cette sélection.") : String(localized: "Ajoutez une source dans Réglages.")))
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { IOSScopeBar(kind: kind, scope: $scope) }
        .navigationTitle(scope.title(kind: kind))
        .searchable(text: $search, prompt: "Rechercher")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Toutes les catégories") { scope = .all }
                    Button("Favoris", systemImage: "star") { scope = .favorites }
                    Button("Récents", systemImage: "clock") { scope = .recents }
                    Divider()
                    ForEach(store.categoriesByKind[kind] ?? [], id: \.self) { name in
                        Button(name) { scope = .category(name) }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .onAppear {
            guard !started else { return }
            started = true
            scope = IOSListScope.start(for: kind, store: store)
        }
        .onChange(of: ui.tab) { old, new in
            if new == tab && old != tab { scope = IOSListScope.start(for: kind, store: store) }
        }
        .onChange(of: scope) { _, new in
            if case .category(let name) = new { UserDefaults.standard.set(name, forKey: StartPage.lastKey(kind)) }
        }
    }
}
