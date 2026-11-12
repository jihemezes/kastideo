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

enum IOSLibrarySort: String, CaseIterable, Identifiable {
    case nameAsc, nameDesc, newest, oldest, largest, smallest, longest, shortest
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .nameAsc: return "Nom A → Z"
        case .nameDesc: return "Nom Z → A"
        case .newest: return "Date : plus récentes d'abord"
        case .oldest: return "Date : plus anciennes d'abord"
        case .largest: return "Taille : plus lourdes d'abord"
        case .smallest: return "Taille : plus légères d'abord"
        case .longest: return "Durée : plus longues d'abord"
        case .shortest: return "Durée : plus courtes d'abord"
        }
    }
    var needsSize: Bool { self == .largest || self == .smallest }
}

enum IOSLibraryType: String, CaseIterable, Identifiable {
    case all, personal, movies, series
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .all: return "Tous les types"
        case .personal: return "Mes vidéos"
        case .movies: return "Films"
        case .series: return "Séries"
        }
    }
}

enum IOSLibraryStatus: String, CaseIterable, Identifiable {
    case all, unwatched, inProgress, watched, favorites
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .all: return "Tous"
        case .unwatched: return "Non vues"
        case .inProgress: return "En cours"
        case .watched: return "Vues"
        case .favorites: return "Favoris"
        }
    }
}

/// Critères de regroupement de « Mes vidéos » (combinables : « Source · Catégorie »).
enum IOSLibraryGroup: String, CaseIterable, Identifiable {
    case source, category, type, year, month
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .source: return "Source"
        case .category: return "Catégorie / dossier / album"
        case .type: return "Type"
        case .year: return "Année d'ajout"
        case .month: return "Mois d'ajout"
        }
    }
}

/// Vidéos des sources locales : galerie, dossiers, serveurs Jellyfin, Emby, Plex. Tri, regroupements et filtres mémorisés.
struct IOSLibraryScreen: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui
    @AppStorage(IOSKeys.cardSize) private var sizeRaw = IOSCardSize.medium.rawValue
    @AppStorage("ios.lib.sort") private var sortRaw = IOSLibrarySort.nameAsc.rawValue
    @AppStorage("ios.lib.type") private var typeRaw = IOSLibraryType.all.rawValue
    @AppStorage("ios.lib.status") private var statusRaw = IOSLibraryStatus.all.rawValue
    @AppStorage("ios.lib.source") private var sourceRaw = ""
    @AppStorage("ios.lib.group") private var groupRaw = ""
    @State private var collapsed: Set<String> = []
    @State private var search = ""
    @State private var sizes: [String: Int64] = [:]
    @State private var measuring = false

    private var sort: IOSLibrarySort { IOSLibrarySort(rawValue: sortRaw) ?? .nameAsc }
    private var type: IOSLibraryType { IOSLibraryType(rawValue: typeRaw) ?? .all }
    private var status: IOSLibraryStatus { IOSLibraryStatus(rawValue: statusRaw) ?? .all }
    private var sourceID: UUID? { UUID(uuidString: sourceRaw) }
    private var groups: [IOSLibraryGroup] {
        let chosen = Set(groupRaw.split(separator: ",").compactMap { IOSLibraryGroup(rawValue: String($0)) })
        return IOSLibraryGroup.allCases.filter { chosen.contains($0) }
    }

    private func setGroup(_ group: IOSLibraryGroup, _ on: Bool) {
        var chosen = Set(groups)
        if on { chosen.insert(group) } else { chosen.remove(group) }
        if on, group == .year { chosen.remove(.month) }
        if on, group == .month { chosen.remove(.year) }
        groupRaw = IOSLibraryGroup.allCases.filter { chosen.contains($0) }.map(\.rawValue).joined(separator: ",")
        collapsed = []
    }

    private struct LibSection: Identifiable {
        let id: String
        let title: String
        let sortKey: String
        var items: [MediaItem]
    }

    /// Titre et clé de tri d'une vidéo pour un critère de regroupement.
    private func component(_ group: IOSLibraryGroup, _ item: MediaItem) -> (title: String, sort: String) {
        switch group {
        case .source:
            let name = store.source(id: item.sourceID)?.name ?? String(localized: "Source")
            return (name, name.lowercased())
        case .category:
            var name = item.group
            let videos = String(localized: "Vidéos")
            if name.hasPrefix(videos + " · ") { name = String(name.dropFirst(videos.count + 3)) }
            if name == videos || name.isEmpty { name = String(localized: "Sans catégorie") }
            return (name, name.lowercased())
        case .type:
            if isPersonal(item) { return (String(localized: "Mes vidéos"), "2") }
            return item.kind == .series ? (String(localized: "Séries"), "1") : (String(localized: "Films"), "0")
        case .year:
            guard let date = item.added else { return (String(localized: "Sans date"), "9999") }
            let year = Calendar.current.component(.year, from: date)
            return (String(year), String(format: "%04d", 5000 - year))
        case .month:
            guard let date = item.added else { return (String(localized: "Sans date"), "9999") }
            let parts = Calendar.current.dateComponents([.year, .month], from: date)
            let key = String(format: "%04d%02d", 5000 - (parts.year ?? 0), 13 - (parts.month ?? 1))
            return (date.formatted(.dateTime.month(.wide).year()).capitalized, key)
        }
    }

    private func sections(_ items: [MediaItem]) -> [LibSection] {
        let active = groups
        var byID: [String: LibSection] = [:]
        for item in items {
            let parts = active.map { component($0, item) }
            let id = parts.map(\.title).joined(separator: " · ")
            if byID[id] == nil {
                byID[id] = LibSection(id: id, title: id, sortKey: parts.map(\.sort).joined(separator: "|"), items: [])
            }
            byID[id]?.items.append(item)
        }
        return byID.values.sorted { $0.sortKey.localizedStandardCompare($1.sortKey) == .orderedAscending }
    }

    private var isFiltered: Bool { type != .all || status != .all || sourceID != nil || !groups.isEmpty }

    private func isPersonal(_ item: MediaItem) -> Bool {
        let videos = String(localized: "Vidéos")
        return item.kind == .movie && (item.group == videos || item.group.hasPrefix(videos + " · "))
    }

    private var base: [MediaItem] {
        let all = store.libraryItems(source: sourceID)
        let favorites = store.favoriteSet
        let key = search.kastideoSearchKey
        return all.filter { item in
            if !key.isEmpty, !item.searchKey.contains(key) { return false }
            switch type {
            case .all: break
            case .personal: if !isPersonal(item) { return false }
            case .movies: if item.kind != .movie || isPersonal(item) { return false }
            case .series: if item.kind != .series { return false }
            }
            switch status {
            case .all: break
            case .unwatched: if watch.isWatched(item.id) || watch.fraction(for: item.id) != nil { return false }
            case .inProgress: if watch.isWatched(item.id) || watch.fraction(for: item.id) == nil { return false }
            case .watched: if !watch.isWatched(item.id) { return false }
            case .favorites: if !favorites.contains(item.id) { return false }
            }
            return true
        }
    }

    private func sorted(_ items: [MediaItem]) -> [MediaItem] {
        func byName(_ a: MediaItem, _ b: MediaItem) -> Bool { a.name.localizedStandardCompare(b.name) == .orderedAscending }
        switch sort {
        case .nameAsc: return items.sorted(by: byName)
        case .nameDesc: return items.sorted { byName($1, $0) }
        case .newest: return items.sorted { ($0.added ?? .distantPast) > ($1.added ?? .distantPast) }
        case .oldest: return items.sorted { ($0.added ?? .distantFuture) < ($1.added ?? .distantFuture) }
        case .largest: return items.sorted { (sizes[$0.id] ?? -1) > (sizes[$1.id] ?? -1) }
        case .smallest: return items.sorted { (sizes[$0.id] ?? Int64.max) < (sizes[$1.id] ?? Int64.max) }
        case .longest: return items.sorted { ($0.runtime ?? 0) > ($1.runtime ?? 0) }
        case .shortest: return items.sorted { ($0.runtime ?? Int.max) < ($1.runtime ?? Int.max) }
        }
    }

    /// Détail affiché sous le titre quand le tri porte sur la date, la taille ou la durée.
    private func caption(_ item: MediaItem) -> String? {
        switch sort {
        case .newest, .oldest:
            return item.added?.formatted(date: .abbreviated, time: .omitted)
        case .largest, .smallest:
            return sizes[item.id].map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
        case .longest, .shortest:
            return item.runtime.map { String(localized: "\($0) min") }
        default:
            return nil
        }
    }

    var body: some View {
        let list = sorted(base)
        NavigationStack {
            ScrollView {
                if list.isEmpty {
                    Group {
                        if store.isBusy { Text("Chargement…") }
                        else if isFiltered || !search.isEmpty { Text("Aucune vidéo ne correspond aux filtres.") }
                        else { Text("Aucune vidéo pour le moment.") }
                    }
                    .foregroundStyle(.secondary).padding(40).frame(maxWidth: .infinity)
                } else {
                    if groups.isEmpty {
                        grid(Array(list.prefix(3000)))
                            .padding(.horizontal).padding(.top, 8)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [.sectionHeaders]) {
                            ForEach(sections(Array(list.prefix(3000)))) { section in
                                Section {
                                    if !collapsed.contains(section.id) {
                                        grid(section.items).padding(.horizontal)
                                    }
                                } header: {
                                    sectionHeader(section)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .searchable(text: $search, prompt: "Rechercher")
            .navigationTitle("Mes vidéos")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { store.refreshAll() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { filterMenu(count: list.count) }
            }
            .task(id: "\(sortRaw)-\(store.libraryItems().count)") { await measureSizes() }
        }
    }

    private func grid(_ items: [MediaItem]) -> some View {
        let side = IOSCardSize.current(sizeRaw).width
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: side, maximum: side + 40), spacing: 12, alignment: .top)],
                         alignment: .leading, spacing: 16) {
            ForEach(items) { item in
                Button { ui.open(item, store: store, playback: playback) } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        PosterCard(item: item, progress: watch.fraction(for: item.id))
                        if let text = caption(item) {
                            Text(text).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionHeader(_ section: LibSection) -> some View {
        Button {
            if collapsed.contains(section.id) { collapsed.remove(section.id) } else { collapsed.insert(section.id) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: collapsed.contains(section.id) ? "chevron.right" : "chevron.down")
                    .font(.caption.weight(.bold)).frame(width: 14)
                Text(section.title).font(.headline).lineLimit(1)
                Text("\(section.items.count)").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.bar)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func filterMenu(count: Int) -> some View {
        Menu {
            Picker("Trier par", selection: $sortRaw) {
                ForEach(IOSLibrarySort.allCases) { Text($0.label).tag($0.rawValue) }
            }
            Menu("Regrouper par", systemImage: "rectangle.3.group") {
                ForEach(IOSLibraryGroup.allCases) { group in
                    Toggle(isOn: Binding(get: { groups.contains(group) }, set: { setGroup(group, $0) })) {
                        Text(group.label)
                    }
                }
                if !groups.isEmpty {
                    Divider()
                    Button("Ne plus regrouper", systemImage: "xmark.circle") { groupRaw = ""; collapsed = [] }
                }
            }
            Picker("Type", selection: $typeRaw) {
                ForEach(IOSLibraryType.allCases) { Text($0.label).tag($0.rawValue) }
            }
            Picker("Visionnage", selection: $statusRaw) {
                ForEach(IOSLibraryStatus.allCases) { Text($0.label).tag($0.rawValue) }
            }
            if store.librarySources.count > 1 {
                Picker("Source", selection: $sourceRaw) {
                    Text("Toutes les sources").tag("")
                    ForEach(store.librarySources) { Text($0.name).tag($0.id.uuidString) }
                }
            }
            if isFiltered {
                Divider()
                Button("Effacer les filtres", systemImage: "xmark.circle") {
                    typeRaw = IOSLibraryType.all.rawValue
                    statusRaw = IOSLibraryStatus.all.rawValue
                    sourceRaw = ""
                    groupRaw = ""
                    collapsed = []
                }
            }
        } label: {
            Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    /// Mesure la taille des fichiers (hors fil principal) quand le tri par taille est choisi.
    private func measureSizes() async {
        guard sort.needsSize, !measuring else { return }
        measuring = true
        defer { measuring = false }
        let pending = store.libraryItems().filter { sizes[$0.id] == nil }
        guard !pending.isEmpty else { return }
        let measured = await Task.detached(priority: .utility) { () -> [String: Int64] in
            var result: [String: Int64] = [:]
            for item in pending {
                if Task.isCancelled { break }
                if let size = IOSGallery.fileSize(of: item) { result[item.id] = size }
            }
            return result
        }.value
        sizes.merge(measured) { $1 }
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
