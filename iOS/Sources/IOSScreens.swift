import SwiftUI
import KastideoCore

// MARK: - Reprendre, Récents, Favoris

enum IOSCollectionKind {
    case resume, recents, favorites

    var title: LocalizedStringKey {
        switch self {
        case .resume: return "Reprendre"
        case .recents: return "Récents"
        case .favorites: return "Favoris"
        }
    }

    var empty: LocalizedStringKey {
        switch self {
        case .resume: return "Rien à reprendre pour le moment."
        case .recents: return "L'historique est vide."
        case .favorites: return "Aucun favori. Touchez longtemps un contenu pour l'ajouter aux favoris."
        }
    }
}

/// Liste en grille de Reprendre / Récents / Favoris, avec retrait par appui long ou sélection (et annulation).
struct IOSCollectionScreen: View {
    let kind: IOSCollectionKind
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui
    @State private var selecting = false
    @State private var selected: Set<String> = []
    @State private var confirmClear = false

    private var items: [MediaItem] {
        switch kind {
        case .resume:
            return store.recentIDs.compactMap { store.item(id: $0) }.filter { $0.kind != .live && watch.inResume($0.id) }
        case .recents:
            return store.recentIDs.compactMap { store.item(id: $0) }
        case .favorites:
            return store.favoriteIDs.compactMap { store.item(id: $0) }
        }
    }

    var body: some View {
        let list = items
        NavigationStack {
            ScrollView {
                if list.isEmpty {
                    Text(kind.empty).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .padding(40).frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104, maximum: 150), spacing: 12, alignment: .top)],
                              alignment: .leading, spacing: 16) {
                        ForEach(list) { item in cell(item) }
                    }
                    .padding(.horizontal).padding(.top, 8)
                }
            }
            .navigationTitle(kind.title)
            .toolbar {
                if !list.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(selecting ? "OK" : "Sélectionner") {
                            selecting.toggle()
                            selected = []
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button("Tout vider", systemImage: "trash", role: .destructive) { confirmClear = true }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if selecting && !selected.isEmpty {
                        Button(role: .destructive) { remove(selected) ; selected = []; selecting = false } label: {
                            Label("Retirer (\(selected.count))", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(.red)
                    }
                    undoBanner
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
            .confirmationDialog("Vider cette liste ?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Tout retirer", role: .destructive) { remove(Set(items.map(\.id))) }
            } message: {
                Text("Vous pourrez annuler juste après.")
            }
        }
    }

    private func cell(_ item: MediaItem) -> some View {
        Button {
            if selecting {
                if selected.contains(item.id) { selected.remove(item.id) } else { selected.insert(item.id) }
            } else {
                ui.open(item, store: store, playback: playback)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Color.clear
                    .aspectRatio(item.kind == .live ? 16.0 / 9.0 : 2.0 / 3.0, contentMode: .fit)
                    .overlay { ArtworkView(url: item.logoURL, name: item.name, contentMode: item.kind == .live ? .fit : .fill) }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .bottom) {
                        if kind == .resume, let fraction = watch.fraction(for: item.id) {
                            ProgressView(value: fraction).tint(IOSPalette.orange).padding(6)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if selecting {
                            Image(systemName: selected.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selected.contains(item.id) ? IOSPalette.orange : Color.white)
                                .padding(6)
                        }
                    }
                Text(item.name).font(.caption.weight(.medium)).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(kind == .favorites ? String(localized: "Retirer des favoris") : String(localized: "Retirer de cette liste"),
                   systemImage: "eye.slash") {
                remove([item.id])
            }
            if kind != .favorites {
                Button(store.isFavorite(item.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris"),
                       systemImage: store.isFavorite(item.id) ? "star.slash" : "star") {
                    store.toggleFavorite(item.id)
                }
            }
        }
    }

    private func remove(_ ids: Set<String>) {
        switch kind {
        case .resume: watch.hideResume(Array(ids))
        case .recents: store.removeRecents(ids)
        case .favorites: for id in ids where store.isFavorite(id) { store.toggleFavorite(id) }
        }
    }

    @ViewBuilder
    private var undoBanner: some View {
        switch kind {
        case .resume where watch.resumeUndo != nil:
            banner(count: watch.resumeUndo?.ids.count ?? 0) { watch.undoHideResume() }
        case .recents where store.recentsBackup != nil:
            banner(count: store.recentsBackup?.removedCount ?? 0) { store.undoRemoveRecents() }
        default:
            EmptyView()
        }
    }

    private func banner(count: Int, undo: @escaping () -> Void) -> some View {
        HStack {
            Text("\(count) retiré(s)").font(.subheadline)
            Spacer()
            Button("Annuler", action: undo).font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Mes vidéos

/// Vidéos des sources locales : galerie, dossiers, serveurs Jellyfin, Emby, Plex.
struct IOSLibraryScreen: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui
    @AppStorage(IOSKeys.cardSize) private var sizeRaw = IOSCardSize.medium.rawValue
    @State private var search = ""

    private var items: [MediaItem] {
        let key = search.kastideoSearchKey
        let all = store.libraryItems()
        return key.isEmpty ? all : all.filter { $0.searchKey.contains(key) }
    }

    var body: some View {
        let list = items
        NavigationStack {
            ScrollView {
                if list.isEmpty {
                    Group {
                        if store.isBusy { Text("Chargement…") } else { Text("Aucune vidéo pour le moment.") }
                    }
                    .foregroundStyle(.secondary).padding(40).frame(maxWidth: .infinity)
                } else {
                    let side = IOSCardSize.current(sizeRaw).width
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: side, maximum: side + 40), spacing: 12, alignment: .top)],
                              alignment: .leading, spacing: 16) {
                        ForEach(list.prefix(3000)) { item in
                            Button { ui.open(item, store: store, playback: playback) } label: {
                                PosterCard(item: item, progress: watch.fraction(for: item.id))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal).padding(.top, 8)
                }
            }
            .searchable(text: $search, prompt: "Rechercher")
            .navigationTitle("Mes vidéos")
            .refreshable { store.refreshAll() }
        }
    }
}

// MARK: - Barre du bas

/// Barre du bas : Accueil, deux familles de réglages (Contenu, Application) et Aide.
struct IOSBottomBar: View {
    @Environment(IOSUI.self) private var ui

    private struct Entry: Identifiable {
        let tab: IOSTab
        let title: LocalizedStringKey
        let icon: String
        var id: IOSTab { tab }
    }

    private let entries = [
        Entry(tab: .home, title: "Accueil", icon: "house.fill"),
        Entry(tab: .settingsContent, title: "Contenu", icon: "tray.2.fill"),
        Entry(tab: .settingsApp, title: "Application", icon: "gearshape.fill"),
        Entry(tab: .help, title: "Aide", icon: "questionmark.circle.fill")
    ]

    private func isSelected(_ tab: IOSTab) -> Bool {
        switch tab {
        case .home: return ![IOSTab.settingsContent, .settingsApp, .help].contains(ui.tab)
        default: return ui.tab == tab
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(entries) { entry in
                Button { ui.tab = entry.tab } label: {
                    VStack(spacing: 3) {
                        Image(systemName: entry.icon).font(.system(size: entry.tab == .home ? 24 : 20))
                        Text(entry.title).font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(isSelected(entry.tab) ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8).padding(.bottom, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
