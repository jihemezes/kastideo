import SwiftUI
import AppKit
import KastideoCore

extension MediaItem {
    /// Vidéo personnelle d'un dossier ou d'un serveur (rubrique « Vidéos · … »).
    var isPersonalVideo: Bool {
        let videos = String(localized: "Vidéos")
        return kind == .movie && (group == videos || group.hasPrefix(videos + " · "))
    }

    /// Année connue (serveur, fiche TMDB) ou lue dans le nom « Titre (2020) ».
    var displayYear: Int? { year ?? TMDB.cleanTitle(name).year }
}

/// Vidéothèque : dossiers (disque, clé USB, NAS) et serveurs Jellyfin, Emby, Plex, à part de l'IPTV.
struct LibraryRootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    @State private var columns = NavigationSplitViewVisibility.all

    var body: some View {
        @Bindable var navigation = navigation
        NavigationSplitView(columnVisibility: $columns) {
            LibrarySidebar()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            Group {
                if navigation.selectedItemID != nil {
                    CinemaDetail()
                } else if let id = navigation.infoItemID, let item = store.item(id: id) {
                    MediaInfoView(item: item)
                        .id(item.id)
                } else {
                    LibraryBrowser()
                }
            }
            .onChange(of: navigation.selectedItemID) { _, id in
                // Retour à la vidéothèque : la lecture s'arrête, sauf enregistrement en cours.
                if id == nil, playback.current != nil, !recordings.isPlayerRecording { playback.stop() }
            }
        }
        .navigationTitle(String(localized: "Mes vidéos"))
        .searchable(text: $navigation.search, placement: .toolbar, prompt: "Rechercher")
        .toolbar {
            MainToolbar(store: store, scope: nil, style: .cinema)
        }
        .toolbar(navigation.isTheater ? .hidden : .automatic, for: .windowToolbar)
        .onChange(of: navigation.isTheater) { _, theater in
            columns = theater ? .detailOnly : .all
            setFullScreen(theater)
        }
    }
}

// MARK: - Barre latérale

struct LibrarySidebar: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @State private var diagnosed: Source?

    var body: some View {
        let items = store.libraryItems(source: navigation.librarySource)
        List {
            Section("Mes vidéos") {
                viewRow(.home, title: String(localized: "À la une"), icon: "sparkles.tv", count: nil)
                viewRow(.movies, title: String(localized: "Films"), icon: "film",
                        count: items.filter { $0.kind == .movie && !$0.isPersonalVideo }.count)
                viewRow(.series, title: String(localized: "Séries"), icon: "rectangle.stack",
                        count: items.filter { $0.kind == .series }.count)
                viewRow(.videos, title: String(localized: "Vidéos"), icon: "video", count: items.filter(\.isPersonalVideo).count)
                viewRow(.folders, title: String(localized: "Dossiers"), icon: "folder", count: nil)
            }
            Section("Sources") {
                sourceRow(nil)
                ForEach(store.librarySources) { source in
                    sourceRow(source)
                }
                SettingsLink {
                    Label("Ajouter une source", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .listStyle(.sidebar)
        .sheet(item: $diagnosed) { source in
            LibraryDiagnosticSheet(source: source)
                .environment(store)
        }
    }

    private func viewRow(_ view: LibraryView, title: String, icon: String, count: Int?) -> some View {
        let selected = navigation.libraryView == view
        return Button {
            navigation.showLibrary(view)
        } label: {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                if let count, count > 0 {
                    Text("\(count)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selected ? Color.accentColor.opacity(0.25) : Color.clear)
    }

    private func sourceRow(_ source: Source?) -> some View {
        let selected = navigation.librarySource == source?.id
        let count = store.libraryItems(source: source?.id).count
        return Button {
            navigation.librarySource = source?.id
            navigation.infoItemID = nil
            navigation.selectedItemID = nil
        } label: {
            HStack {
                if let source {
                    if store.loading.contains(source.id) {
                        ProgressView().controlSize(.mini).frame(width: 18)
                    } else if store.errors[source.id] != nil {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).frame(width: 18)
                    } else {
                        Image(systemName: source.kind.libraryIcon).frame(width: 18)
                    }
                    Text(source.name).lineLimit(1)
                } else {
                    Image(systemName: "square.stack.3d.up").frame(width: 18)
                    Text("Toutes les sources")
                }
                Spacer()
                if count > 0 {
                    Text("\(count)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selected ? Color.accentColor.opacity(0.25) : Color.clear)
        .help(source.flatMap { store.errors[$0.id] } ?? "")
        .contextMenu {
            if let source {
                Button("Actualiser") { store.refresh(source) }
                if store.errors[source.id] != nil {
                    Button("Détails de l'erreur…") { diagnosed = source }
                }
                SettingsLink { Text("Modifier la source…") }
            }
        }
    }
}

extension SourceKind {
    /// Icône d'une source de la vidéothèque.
    var libraryIcon: String {
        switch self {
        case .folders: return "folder"
        case .mediaServer(let type, _, _): return type == .plex ? "play.rectangle.on.rectangle" : "server.rack"
        default: return "antenna.radiowaves.left.and.right"
        }
    }
}

/// Diagnostic : message, requête et réponse exacte du serveur, pistes.
struct LibraryDiagnosticSheet: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let source: Source

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diagnostic — \(source.name)").font(.title2.weight(.semibold))
            Text(store.errors[source.id] ?? String(localized: "Aucune erreur."))
                .font(.headline)
                .textSelection(.enabled)
            if let detail = store.errorDetails[source.id] {
                Text("Réponse du serveur").font(.caption).foregroundStyle(.secondary)
                ScrollView {
                    Text(detail)
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 180)
                .padding(8)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                Button("Copier") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(detail, forType: .string)
                }
            }
            Text(source.kind.serverType == nil
                 ? String(localized: "Vérifiez que le disque est branché ou que le partage réseau est monté dans le Finder, puis Actualiser.")
                 : String(localized: "Vérifiez l'adresse (sans « /web/… »), l'identifiant et le mot de passe dans Réglages > Sources. Le journal de lecture garde le détail de chaque échange."))
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Fermer") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Réessayer") {
                    store.refresh(source)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 560)
    }
}

// MARK: - Contenu

struct LibraryBrowser: View {
    @Environment(NavigationModel.self) private var navigation

    var body: some View {
        switch navigation.libraryView {
        case .home: LibraryHomeView()
        case .folders: LibraryFolderView()
        default: LibraryGridView()
        }
    }
}

/// Erreurs et chargements des sources affichées.
struct LibraryStatusBanner: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @State private var diagnosed: Source?

    var body: some View {
        let shown = store.librarySources.filter { navigation.librarySource == nil || $0.id == navigation.librarySource }
        VStack(alignment: .leading, spacing: 8) {
            ForEach(shown) { source in
                if let error = store.errors[source.id] {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("\(source.name) : \(error)").lineLimit(2)
                        Spacer()
                        Button("Détails") { diagnosed = source }
                        Button("Réessayer") { store.refresh(source) }
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                } else if store.loading.contains(source.id) {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text(source.kind.serverType == nil
                             ? String(localized: "Examen des dossiers… \(source.name)")
                             : String(localized: "Chargement des bibliothèques… \(source.name)"))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .sheet(item: $diagnosed) { source in
            LibraryDiagnosticSheet(source: source)
                .environment(store)
        }
    }
}

@MainActor
private func libraryScopeTitle(_ store: LibraryStore, _ navigation: NavigationModel) -> String {
    if let id = navigation.librarySource, let source = store.source(id: id) {
        return String(localized: "Mes vidéos") + " · " + source.name
    }
    return String(localized: "Mes vidéos")
}

private func byTitle(_ a: MediaItem, _ b: MediaItem) -> Bool {
    TMDB.cleanTitle(a.name).title.localizedStandardCompare(TMDB.cleanTitle(b.name).title) == .orderedAscending
}

/// À la une : reprendre, ajouts récents, films à voir, films, séries, vidéos.
struct LibraryHomeView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(WatchProgressStore.self) private var watch

    var body: some View {
        let scope = navigation.librarySource
        let items = store.libraryItems(source: scope)
        let resume = store.recentIDs.compactMap { store.item(id: $0) }
            .filter { store.isLibraryItem($0) && (scope == nil || $0.sourceID == scope) && watch.fraction(for: $0.id) != nil }
        let recent = items.filter { $0.added != nil }.sorted { ($0.added ?? .distantPast) > ($1.added ?? .distantPast) }
        let movies = items.filter { $0.kind == .movie && !$0.isPersonalVideo }.sorted(by: byTitle)
        let series = items.filter { $0.kind == .series }.sorted(by: byTitle)
        let videos = items.filter(\.isPersonalVideo).sorted(by: byTitle)
        let unwatched = movies.filter { !watch.isWatched($0.id) && watch.fraction(for: $0.id) == nil }
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Text(libraryScopeTitle(store, navigation))
                    .font(.largeTitle.weight(.bold))
                    .padding(.horizontal, 24)
                LibraryStatusBanner()
                if items.isEmpty && store.loading.isEmpty {
                    ContentUnavailableView {
                        Label("Aucune vidéo pour l'instant.", systemImage: "film.stack")
                    } description: {
                        Text("Kastideo reconnaît les fichiers vidéo (.mkv, .mp4, .avi…) des dossiers choisis et de leurs sous-dossiers. Vérifiez le dossier de la source, ou ouvrez le journal de lecture pour voir ce qui a été examiné.")
                    }
                    .frame(maxWidth: .infinity, minHeight: 260)
                }
                if !resume.isEmpty {
                    CinemaRail(title: String(localized: "Reprendre la lecture"), items: Array(resume.prefix(20)))
                }
                if !recent.isEmpty {
                    CinemaRail(title: String(localized: "Ajouts récents"), items: Array(recent.prefix(30)))
                }
                if unwatched.count >= 6, unwatched.count < movies.count {
                    CinemaRail(title: String(localized: "Films à voir"), items: unwatched) {
                        navigation.libraryUnwatched = true
                        navigation.showLibrary(.movies)
                    }
                }
                if !movies.isEmpty {
                    CinemaRail(title: String(localized: "Films"), items: movies) { navigation.showLibrary(.movies) }
                }
                if !series.isEmpty {
                    CinemaRail(title: String(localized: "Séries"), items: series) { navigation.showLibrary(.series) }
                }
                if !videos.isEmpty {
                    CinemaRail(title: String(localized: "Vidéos"), items: videos) { navigation.showLibrary(.videos) }
                }
            }
            .padding(.vertical, 20)
        }
    }
}

/// Films, séries ou vidéos : grille avec recherche, filtres (genre, année, non vus) et tri.
struct LibraryGridView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(WatchProgressStore.self) private var watch
    @AppStorage(AppearanceKeys.cardSize) private var cardSizeRaw = CardSize.medium.rawValue

    var body: some View {
        @Bindable var navigation = navigation
        let view = navigation.libraryView
        let all = store.libraryItems(source: navigation.librarySource).filter { item in
            switch view {
            case .movies: return item.kind == .movie && !item.isPersonalVideo
            case .series: return item.kind == .series
            default: return item.isPersonalVideo
            }
        }
        let genres = Array(Set(all.flatMap { $0.genres ?? [] })).sorted()
        let years = Array(Set(all.compactMap(\.displayYear))).sorted(by: >)
        let key = navigation.search.kastideoSearchKey
        var items = all.filter { item in
            if !key.isEmpty, !item.searchKey.contains(key) { return false }
            if let genre = navigation.libraryGenre, !(item.genres ?? []).contains(genre) { return false }
            if let year = navigation.libraryYear, item.displayYear != year { return false }
            if navigation.libraryUnwatched, watch.isWatched(item.id) { return false }
            return true
        }
        switch navigation.librarySort {
        case .title: items.sort(by: byTitle)
        case .added: items.sort { ($0.added ?? .distantPast) > ($1.added ?? .distantPast) }
        case .year: items.sort { ($0.displayYear ?? 0) > ($1.displayYear ?? 0) }
        }
        let title: String = view == .movies ? String(localized: "Films") : view == .series ? String(localized: "Séries") : String(localized: "Vidéos")
        let size = CardSize(rawValue: cardSizeRaw) ?? .medium
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(title) · \(libraryScopeTitle(store, navigation))").font(.title2.weight(.bold)).lineLimit(1)
                    Text("\(items.count)").font(.callout).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                LibraryStatusBanner()
                HStack(spacing: 12) {
                    if !genres.isEmpty {
                        Picker("Genre", selection: $navigation.libraryGenre) {
                            Text("Tous les genres").tag(String?.none)
                            ForEach(genres, id: \.self) { Text($0).tag(String?.some($0)) }
                        }
                        .fixedSize()
                    }
                    if !years.isEmpty {
                        Picker("Année", selection: $navigation.libraryYear) {
                            Text("Toutes les années").tag(Int?.none)
                            ForEach(years, id: \.self) { Text(String($0)).tag(Int?.some($0)) }
                        }
                        .fixedSize()
                    }
                    Toggle("Non vus", isOn: $navigation.libraryUnwatched)
                        .toggleStyle(.checkbox)
                    Picker("Tri", selection: $navigation.librarySort) {
                        ForEach(LibrarySort.allCases) { Text($0.label).tag($0) }
                    }
                    .fixedSize()
                    Spacer()
                }
                .padding(.horizontal, 24)
                if items.isEmpty {
                    ContentUnavailableView(title, systemImage: "tray", description: Text("Aucun résultat."))
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: size.posterWidth), spacing: 16, alignment: .top)],
                              alignment: .leading, spacing: 20) {
                        ForEach(items) { item in
                            MediaCard(item: item)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 20)
        }
    }
}

/// Navigation par dossiers : dossiers choisis (disque, NAS) et leurs sous-dossiers, bibliothèques des serveurs.
struct LibraryFolderView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @AppStorage(AppearanceKeys.cardSize) private var cardSizeRaw = CardSize.medium.rawValue

    /// Dossier affiché : nom, détail et chemin (identifiant de la source, racine ou bibliothèque, sous-dossiers).
    private struct Entry: Identifiable {
        let name: String
        let detail: String
        let path: [String]
        var id: String { path.joined(separator: "/") }
    }

    var body: some View {
        let path = navigation.libraryFolder
        let content = listing(path)
        let folders = content.folders
        let files = content.files
        let size = CardSize(rawValue: cardSizeRaw) ?? .medium
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Dossiers").font(.title2.weight(.bold)).padding(.horizontal, 24)
                LibraryStatusBanner()
                // Fil d'Ariane.
                HStack(spacing: 4) {
                    Button {
                        navigation.libraryFolder = []
                    } label: {
                        Label("Tous les dossiers", systemImage: "folder")
                    }
                    .buttonStyle(.link)
                    ForEach(Array(path.enumerated()).dropFirst(), id: \.offset) { index, segment in
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        Button(index == 1 ? URL(fileURLWithPath: segment).lastPathComponent : segment) {
                            navigation.libraryFolder = Array(path.prefix(index + 1))
                        }
                        .buttonStyle(.link)
                    }
                }
                .padding(.horizontal, 24)
                if folders.isEmpty && files.isEmpty {
                    ContentUnavailableView("Dossier vide", systemImage: "folder")
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
                VStack(spacing: 4) {
                    ForEach(folders) { entry in
                        Button {
                            navigation.libraryFolder = entry.path
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "folder.fill").foregroundStyle(.orange)
                                Text(entry.name).fontWeight(.semibold).lineLimit(1)
                                Spacer()
                                if !entry.detail.isEmpty {
                                    Text(entry.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                                }
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                if !files.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: size.posterWidth), spacing: 16, alignment: .top)],
                              alignment: .leading, spacing: 20) {
                        ForEach(files) { item in
                            MediaCard(item: item)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 20)
        }
    }

    private func listing(_ path: [String]) -> (folders: [Entry], files: [MediaItem]) {
        let sources = store.librarySources.filter { navigation.librarySource == nil || $0.id == navigation.librarySource }
        var folders: [Entry] = []
        var files: [MediaItem] = []
        guard let first = path.first else {
            // Racine : un dossier par dossier choisi, une entrée par bibliothèque de serveur.
            for source in sources {
                switch source.kind {
                case .folders(let bookmarks, _):
                    for root in FolderAccess.resolve(bookmarks) {
                        folders.append(Entry(name: root.lastPathComponent, detail: "\(source.name) · \(root.path)",
                                             path: [source.id.uuidString, root.path]))
                    }
                default:
                    let groups = Set(store.libraryItems(source: source.id).map(\.group)).sorted()
                    for group in groups {
                        folders.append(Entry(name: group, detail: source.name, path: [source.id.uuidString, group]))
                    }
                }
            }
            return (folders, files)
        }
        guard let id = UUID(uuidString: first), let source = store.source(id: id), path.count >= 2 else { return ([], []) }
        guard case .folders = source.kind else {
            files = store.libraryItems(source: id).filter { $0.group == path[1] }.sorted(by: byTitle)
            return ([], files)
        }
        // Fichiers sous le dossier ouvert : sous-dossiers d'abord, puis vidéos de ce dossier.
        var base = ([path[1]] + path.dropFirst(2)).joined(separator: "/")
        while base.count > 1, base.hasSuffix("/") { base.removeLast() }
        var subfolders = Set<String>()
        for item in store.content(of: id)?.items ?? [] where item.kind != .series {
            guard let file = item.streamURL?.path, file.hasPrefix(base + "/") else { continue }
            let rest = file.dropFirst(base.count + 1).split(separator: "/")
            if rest.count > 1 {
                subfolders.insert(String(rest[0]))
            } else if rest.count == 1 {
                files.append(store.item(id: item.id) ?? item)
            }
        }
        folders = subfolders.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { Entry(name: $0, detail: "", path: path + [$0]) }
        files.sort { ($0.streamURL?.lastPathComponent ?? "").localizedStandardCompare($1.streamURL?.lastPathComponent ?? "") == .orderedAscending }
        return (folders, files)
    }
}
