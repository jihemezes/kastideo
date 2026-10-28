import Foundation
import Observation
import KastideoCore

enum LibraryError: LocalizedError {
    case missingPassword
    case emptyPlaylist
    case notXtream
    case folderMissing(String)
    case noFolder

    var errorDescription: String? {
        switch self {
        case .missingPassword: return String(localized: "Mot de passe introuvable dans le trousseau. Modifiez la source pour le saisir à nouveau.")
        case .emptyPlaylist: return String(localized: "La playlist ne contient aucun flux lisible.")
        case .notXtream: return String(localized: "Cette source ne fournit pas de liste d'épisodes.")
        case .folderMissing(let paths):
            return String(localized: "Dossier introuvable (\(paths)) : disque débranché ou partage réseau non connecté ?")
        case .noFolder: return String(localized: "Choisissez au moins un dossier.")
        }
    }
}

/// Origine des films et séries affichés dans Films et Séries.
enum CatalogOrigin: String, CaseIterable, Identifiable {
    case all, iptv, library
    static let key = "catalog.origin"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return String(localized: "Tout")
        case .iptv: return String(localized: "IPTV")
        case .library: return String(localized: "Mes vidéos")
        }
    }
    /// Par défaut : l'IPTV seul (« Mes vidéos » a sa propre tuile).
    static var stored: CatalogOrigin { CatalogOrigin(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .iptv }
}

/// Fiche trouvée sur TMDB pour un fichier local (affiche, résumé, année, genres).
struct LocalFiche {
    var logo: URL?
    var info: String?
    var year: Int?
    var genres: [String] = []
}

/// Accès aux dossiers choisis (bac à sable) : ouvert une fois et gardé pendant toute la session,
/// pour que la lecture et les sous-titres placés à côté des vidéos restent lisibles.
enum FolderAccess {
    private static let lock = NSLock()
    private static var opened: [String: URL] = [:]

    static func resolve(_ bookmarks: [Data]) -> [URL] {
        bookmarks.compactMap { data in
            var stale = false
            guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil,
                                     bookmarkDataIsStale: &stale) else { return nil }
            lock.lock()
            defer { lock.unlock() }
            if opened[url.path] == nil, url.startAccessingSecurityScopedResource() { opened[url.path] = url }
            return url
        }
    }

    /// Signet d'un dossier choisi dans le panneau d'ouverture.
    static func bookmark(for url: URL) throws -> Data {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        return try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
    }
}

/// Bibliothèque : sources, contenus chargés, guide TV, favoris et historique.
@MainActor
@Observable
final class LibraryStore {
    private(set) var sources: [Source] = []
    private(set) var contents: [UUID: SourceContent] = [:]
    /// Replays ouverts pendant cette session (élément lu + chaîne d'origine).
    @ObservationIgnored var replays: [String: ReplayEntry] = [:]
    private(set) var epg = EPGIndex()
    private(set) var favoriteIDs: [String] = []
    private(set) var recentIDs: [String] = []
    /// Historique avant la dernière suppression (pour pouvoir l'annuler).
    private(set) var recentsBackup: RecentsBackup?
    private(set) var loading: Set<UUID> = []
    private(set) var errors: [UUID: String] = [:]
    private(set) var epgErrors: [UUID: String] = [:]
    private(set) var epgLoadingCount = 0
    private(set) var epgCounts: [UUID: Int] = [:]

    private(set) var itemsByKind: [MediaKind: [MediaItem]] = [:]
    private(set) var categoriesByKind: [MediaKind: [String]] = [:]
    /// Toutes les catégories du fournisseur (noms d'origine, ordre personnalisé, y compris masquées) et leur nombre d'éléments.
    private(set) var allCategoriesByKind: [MediaKind: [String]] = [:]
    private(set) var categoryCounts: [MediaKind: [String: Int]] = [:]
    /// Ordre, masquage et noms personnalisés des catégories.
    private(set) var categoryPrefs: [MediaKind: CategoryPrefs] = [:]
    private var itemsByID: [String: MediaItem] = [:]
    /// Contenus classés par type puis par catégorie (accès direct pour l'interface Cinéma).
    private var itemsByCategory: [MediaKind: [String: [MediaItem]]] = [:]
    /// Épisodes lus (absents de l'index principal), pour l'historique.
    private var extraItems: [String: MediaItem] = [:]
    private var epgBySource: [UUID: [Programme]] = [:]
    private var started = false
    /// Guide de secours (xmltvfr.fr…) : programmes et chaînes.
    private var fallbackProgrammes: [Programme] = []
    private var fallbackChannels: [XMLTVChannel] = []
    private(set) var fallbackStatus = FallbackEPGStatus()
    /// Chaînes du direct regroupées (une entrée par chaîne, toutes versions confondues) avec leur thème.
    private(set) var liveGroups: [LiveChannelGroup] = []
    private(set) var themeOverrides: [String: ContentTheme] = [:]
    /// Corrections apportées par l'utilisateur à des chaînes (nom, numéro, guide TV, logo), par identifiant.
    private(set) var channelEdits: [String: ChannelEdit] = [:]
    @ObservationIgnored private var liveGroupsGeneration = 0
    @ObservationIgnored private var epgGeneration = 0
    @ObservationIgnored private var lastEPGAttempt: [UUID: Date] = [:]
    @ObservationIgnored private var epgTicker: Task<Void, Never>?
    /// Clients des serveurs Jellyfin, Emby et Plex (session ouverte).
    @ObservationIgnored private var serverClients: [UUID: any MediaServerClient] = [:]
    /// Vidéothèque : films, séries et vidéos des dossiers et serveurs, par source.
    private(set) var libraryBySource: [UUID: [MediaItem]] = [:]
    /// Catégories de Films et Séries qui viennent de « Mes vidéos » (jamais filtrées par pays).
    private(set) var libraryCategories: [MediaKind: Set<String>] = [:]
    /// Films et séries affichés dans Films et Séries : tout, l'IPTV seul ou « Mes vidéos » seules.
    var catalogOrigin: CatalogOrigin = CatalogOrigin.stored {
        didSet {
            guard catalogOrigin != oldValue else { return }
            UserDefaults.standard.set(catalogOrigin.rawValue, forKey: CatalogOrigin.key)
            rebuildIndex()
        }
    }
    /// Diagnostic du dernier chargement d'une source (requête et réponse exacte du serveur).
    private(set) var errorDetails: [UUID: String] = [:]
    @ObservationIgnored private var rescanTicker: Task<Void, Never>?
    @ObservationIgnored private var lastReport: [String: Date] = [:]
    /// Positions de lecture et contenus vus reçus d'un serveur (transmis au suivi de lecture).
    @ObservationIgnored var onServerProgress: (([String: ServerProgress]) -> Void)?
    /// Source chargée (dossiers : affiches et résumés TMDB à compléter).
    @ObservationIgnored var onContentLoaded: ((Source) -> Void)?

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let sources = "sources.v1"
        static let favorites = "favorites.v1"
        static let recents = "recents.v1"
        static let extras = "recentItems.v1"
    }

    init() {
        if let data = defaults.data(forKey: Keys.sources),
           let decoded = try? JSONDecoder().decode([Source].self, from: data) {
            sources = decoded
        }
        favoriteIDs = defaults.stringArray(forKey: Keys.favorites) ?? []
        if let data = defaults.data(forKey: ChannelEdit.storageKey),
           let decoded = try? JSONDecoder().decode([String: ChannelEdit].self, from: data) {
            channelEdits = decoded
        }
        if let data = defaults.data(forKey: "themes.overrides.v1"),
           let decoded = try? JSONDecoder().decode([String: ContentTheme].self, from: data) {
            themeOverrides = decoded
        }
        for kind in CategoryPrefs.kinds {
            if let data = defaults.data(forKey: CategoryPrefs.key(kind)),
               let prefs = try? JSONDecoder().decode(CategoryPrefs.self, from: data) {
                categoryPrefs[kind] = prefs
            }
        }
        recentIDs = defaults.stringArray(forKey: Keys.recents) ?? []
        if let data = defaults.data(forKey: Keys.extras),
           let decoded = try? JSONDecoder().decode([String: MediaItem].self, from: data) {
            extraItems = decoded
        }
        migrateXtreamPlaylists()
    }

    /// Convertit les playlists « get.php?username=…&password=… » en sources Xtream :
    /// chargement bien plus rapide et mot de passe déplacé dans le trousseau.
    private func migrateXtreamPlaylists() {
        var changed = false
        for index in sources.indices {
            guard case .m3uURL(let url) = sources[index].kind,
                  let credentials = XtreamCredentials.fromPlaylistURL(url) else { continue }
            Keychain.set(credentials.password, account: sources[index].id.uuidString)
            sources[index].kind = .xtream(server: credentials.server, username: credentials.username)
            sources[index].lastRefresh = nil
            Storage.delete(name: "content-\(sources[index].id.uuidString)")
            changed = true
        }
        if changed { saveSources() }
    }

    /// Message d'erreur compréhensible pour l'utilisateur.
    nonisolated static func describe(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return String(localized: "Le serveur n'a pas répondu à temps. Il est peut-être surchargé ou indisponible : réessayez plus tard.")
            case .cannotFindHost, .dnsLookupFailed:
                return String(localized: "Serveur introuvable : vérifiez l'adresse.")
            case .cannotConnectToHost:
                return String(localized: "Connexion au serveur refusée : vérifiez l'adresse et le port.")
            case .notConnectedToInternet, .networkConnectionLost:
                return String(localized: "Pas de connexion Internet.")
            case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate:
                return String(localized: "Connexion sécurisée impossible avec ce serveur (certificat).")
            default:
                break
            }
        }
        return error.localizedDescription
    }

    // MARK: - État

    var hasSources: Bool { !sources.isEmpty }
    var isBusy: Bool { !loading.isEmpty || epgLoadingCount > 0 }
    var favoriteSet: Set<String> { Set(favoriteIDs) }

    func isFavorite(_ id: String) -> Bool { favoriteIDs.contains(id) }

    func item(id: String) -> MediaItem? { itemsByID[id] ?? extraItems[id] }

    func items(for browse: Browse) -> [MediaItem] {
        switch browse {
        case .all(let kind):
            return itemsByKind[kind] ?? []
        case .category(let kind, let name):
            return itemsByCategory[kind]?[name] ?? []
        case .favorites:
            return favoriteIDs.compactMap { item(id: $0) }
        case .recents:
            return recentIDs.compactMap { item(id: $0) }
        case .home, .recordings, .guide, .themes, .library:
            return []
        }
    }

    func count(for kind: MediaKind) -> Int { itemsByKind[kind]?.count ?? 0 }

    func source(id: UUID) -> Source? { sources.first { $0.id == id } }

    // MARK: - Démarrage

    /// Charge le cache disque puis actualise les sources anciennes.
    func start(autoRefresh: Bool) async {
        guard !started else { return }
        started = true
        let ids = sources.map(\.id)
        let cached = await Task.detached(priority: .userInitiated) { () -> ([UUID: SourceContent], [UUID: [Programme]]) in
            var contents: [UUID: SourceContent] = [:]
            var programmes: [UUID: [Programme]] = [:]
            for id in ids {
                if let c = Storage.load(SourceContent.self, name: "content-\(id.uuidString)") { contents[id] = c }
                if let p = Storage.load([Programme].self, name: "epg-\(id.uuidString)") { programmes[id] = p }
            }
            return (contents, programmes)
        }.value

        contents.merge(cached.0) { current, _ in current }
        epgBySource.merge(cached.1) { current, _ in current }
        let fallback = await Task.detached(priority: .userInitiated) { () -> ([Programme], [XMLTVChannel]) in
            (Storage.load([Programme].self, name: "epg-fallback") ?? [],
             Storage.load([XMLTVChannel].self, name: "epg-fallback-channels") ?? [])
        }.value
        fallbackProgrammes = fallback.0
        fallbackChannels = fallback.1
        fallbackStatus.programmeCount = fallbackProgrammes.count
        fallbackStatus.channelCount = fallbackChannels.count
        fallbackStatus.updated = defaults.object(forKey: EPGKeys.fallbackDate) as? Date
        rebuildIndex()
        startEPGTicker()

        let staleLimit = Date().addingTimeInterval(-6 * 3600)
        for source in sources where source.isEnabled {
            switch source.kind {
            case .folders:
                // Dossiers : examinés à chaque lancement (fichiers ajoutés ou retirés entre-temps).
                refresh(source)
            case .mediaServer:
                if contents[source.id] == nil || (source.lastRefresh ?? .distantPast) < Date().addingTimeInterval(-3600) {
                    refresh(source)
                } else {
                    onContentLoaded?(source)
                }
            default:
                if contents[source.id] == nil || (autoRefresh && (source.lastRefresh ?? .distantPast) < staleLimit) {
                    refresh(source)
                } else if epgNeedsRefresh(source.id) {
                    PlaybackLog.shared.note("Guide « \(source.name) » : à recharger au démarrage (absent ou presque terminé)", topic: .guide)
                    Task { await refreshEPG(for: source.id) }
                } else {
                    let end = (epgBySource[source.id] ?? []).map(\.stop).max()
                    let until = end?.formatted(date: .abbreviated, time: .shortened) ?? "?"
                    PlaybackLog.shared.note("Guide « \(source.name) » : conservé tel quel (valable jusqu'à \(until))", topic: .guide)
                }
            }
        }
        startRescanTicker()
        Task { await refreshFallbackEPG(force: false) }
    }

    // MARK: - Gestion des sources

    func addSource(_ source: Source, password: String?) {
        if let password, !password.isEmpty { Keychain.set(password, account: source.id.uuidString) }
        sources.append(source)
        saveSources()
        refresh(source)
    }

    func updateSource(_ source: Source, password: String?) {
        if let password, !password.isEmpty { Keychain.set(password, account: source.id.uuidString) }
        guard let index = sources.firstIndex(where: { $0.id == source.id }) else { return }
        serverClients[source.id] = nil
        sources[index] = source
        saveSources()
        refresh(source)
    }

    func removeSource(_ id: UUID) {
        sources.removeAll { $0.id == id }
        contents[id] = nil
        epgBySource[id] = nil
        errors[id] = nil
        epgErrors[id] = nil
        Keychain.delete(account: id.uuidString)
        Keychain.delete(account: "session.\(id.uuidString)")
        serverClients[id] = nil
        Storage.delete(name: "content-\(id.uuidString)")
        Storage.delete(name: "epg-\(id.uuidString)")
        saveSources()
        rebuildIndex()
        rebuildEPG()
    }

    func setEnabled(_ id: UUID, _ enabled: Bool) {
        guard let index = sources.firstIndex(where: { $0.id == id }) else { return }
        sources[index].isEnabled = enabled
        saveSources()
        rebuildIndex()
        rebuildEPG()
        if enabled && contents[id] == nil { refresh(sources[index]) }
    }

    func password(for source: Source) -> String? { Keychain.get(account: source.id.uuidString) }

    func refreshAll() {
        for source in sources where source.isEnabled { refresh(source) }
    }

    func refresh(_ source: Source) {
        guard !loading.contains(source.id) else { return }
        loading.insert(source.id)
        errors[source.id] = nil
        let password = Keychain.get(account: source.id.uuidString)
        let started = Date()
        PlaybackLog.shared.note("Source « \(source.name) » (\(source.kind.title)) : chargement…", topic: .sources, detail: .detailed)
        Task {
            do {
                var content = try await Self.fetch(source, password: password)
                guard sources.contains(where: { $0.id == source.id }) else { loading.remove(source.id); return }
                if case .folders = source.kind, let previous = contents[source.id] {
                    // Affiches et résumés déjà trouvés (TMDB) gardés d'un examen à l'autre.
                    let known = Dictionary(previous.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                    for index in content.items.indices {
                        guard let old = known[content.items[index].id] else { continue }
                        if content.items[index].logoURL == nil { content.items[index].logoURL = old.logoURL }
                        if content.items[index].info == nil { content.items[index].info = old.info }
                        if content.items[index].year == nil { content.items[index].year = old.year }
                        if content.items[index].genres == nil { content.items[index].genres = old.genres }
                    }
                }
                contents[source.id] = content
                if let index = sources.firstIndex(where: { $0.id == source.id }) {
                    sources[index].lastRefresh = Date()
                    saveSources()
                }
                errorDetails[source.id] = nil
                rebuildIndex()
                loading.remove(source.id)
                let seconds = String(format: "%.1f", Date().timeIntervalSince(started))
                if source.kind.isIPTV {
                    let live = content.items.filter { $0.kind == .live }.count
                    let withID = content.items.filter { $0.kind == .live && !($0.epgID ?? "").isEmpty }.count
                    let movies = content.items.filter { $0.kind == .movie }.count
                    let series = content.items.filter { $0.kind == .series }.count
                    let guideAddress = source.epgURL != nil ? "choisie dans la source"
                        : (content.epgURL != nil ? "fournie par le fournisseur" : "inconnue")
                    var loaded = "Source « \(source.name) » chargée en \(seconds) s : \(live) chaînes (\(withID) avec un identifiant de guide), "
                    loaded += "\(movies) films, \(series) séries — adresse du guide : \(guideAddress)"
                    PlaybackLog.shared.note(loaded, topic: .sources)
                } else {
                    PlaybackLog.shared.note("Source « \(source.name) » chargée en \(seconds) s : \(content.items.count) éléments", topic: .sources)
                }
                if let progress = content.progress, !progress.isEmpty { onServerProgress?(progress) }
                let id = source.id
                let snapshot = content
                Task.detached(priority: .utility) { Storage.save(snapshot, name: "content-\(id.uuidString)") }
                if !source.kind.isIPTV { onContentLoaded?(source) }
                await refreshEPG(for: source.id)
            } catch {
                errors[source.id] = Self.describe(error)
                errorDetails[source.id] = (error as? MediaServerError)?.detail
                PlaybackLog.shared.error("Source « \(source.name) » : \(Self.describe(error))\((error as? MediaServerError)?.detail.map { " — \($0)" } ?? "")", topic: .sources)
                loading.remove(source.id)
            }
        }
    }

    /// Programmes passés à garder pour le replay : chaînes à archive de la source, sur le nombre de jours choisi.
    func replayRetention(for id: UUID) -> ArchiveRetention? {
        guard ReplaySettings.enabled, let items = contents[id]?.items else { return nil }
        var channels = Set<String>()
        var longest = 0
        for item in items where item.kind == .live && (item.archiveDays ?? 0) > 0 {
            if let epg = item.epgID, !epg.isEmpty { channels.insert(epg) }
            longest = max(longest, item.archiveDays ?? 0)
        }
        guard !channels.isEmpty else { return nil }
        let days = min(ReplaySettings.guideDays, longest)
        return ArchiveRetention(channels: channels, from: Date().addingTimeInterval(-Double(days) * 86400))
    }

    /// Recharge le guide du fournisseur d'une source. `manual` : demande de l'utilisateur (bouton « Recharger le guide »).
    func refreshEPG(for id: UUID, manual: Bool = false) async {
        guard let source = self.source(id: id), source.isEnabled, source.kind.isIPTV else { return }
        guard let url = source.epgURL ?? contents[id]?.epgURL else {
            PlaybackLog.shared.note("Guide « \(source.name) » : aucune adresse de guide connue pour cette source (rien à télécharger)",
                                    topic: .guide, level: 1)
            if manual { epgErrors[id] = String(localized: "Aucune adresse de guide connue pour cette source.") }
            return
        }
        epgLoadingCount += 1
        defer { epgLoadingCount -= 1 }
        lastEPGAttempt[id] = Date()
        let log = PlaybackLog.shared
        let origin = (source.epgURL != nil) ? "adresse choisie dans la source" : "adresse donnée par le fournisseur"
        log.note("Guide « \(source.name) » : demande\(manual ? " manuelle" : "") à \(url.host ?? "?") (\(origin)) — \(url.absoluteString)",
                 topic: .guide)
        do {
            let retention = replayRetention(for: id)
            let report = try await EPGLoader.loadGuideReport(from: url, retention: retention, timeout: 180)
            let guide = report.guide
            let size = ByteCountFormatter.string(fromByteCount: Int64(report.byteCount), countStyle: .file)
            let http = report.status.map { "HTTP \($0)" } ?? "fichier local"
            let host = report.finalHost.map { $0 == url.host ? "" : " via \($0)" } ?? ""
            var answer = "Guide « \(source.name) » : réponse \(http)\(host) en \(String(format: "%.1f", report.seconds)) s, \(size)"
            if report.gzip { answer += " (compressé)" }
            if let type = report.contentType { answer += ", type « \(type) »" }
            log.note(answer, topic: .guide, detail: .detailed)
            if let status = report.status, !(200..<300).contains(status) {
                let message = String(localized: "Le fournisseur a refusé la demande du guide (HTTP \(status)).")
                epgErrors[id] = message
                var refused = "Guide « \(source.name) » : refusé par le fournisseur (HTTP \(status))"
                if let excerpt = report.bodyExcerpt { refused += " — réponse : « \(excerpt) »" }
                log.error(refused, topic: .guide)
                return
            }
            // Réponse vide ou illisible : on garde les programmes déjà connus (le guide de secours prend le relais).
            guard guide.isValid, !guide.programmes.isEmpty else {
                epgErrors[id] = guide.isValid
                    ? String(localized: "Le fournisseur a envoyé un guide sans programme pour les prochains jours (\(size)).")
                    : String(localized: "Le fournisseur a envoyé un guide vide ou illisible (\(size)).")
                var unusable = "Guide « \(source.name) » : inutilisable (\(size), document XMLTV valide : \(guide.isValid ? "oui" : "non"), "
                unusable += "chaînes : \(guide.channels.count), programmes : \(guide.programmes.count))"
                if let excerpt = report.bodyExcerpt { unusable += " — début de la réponse : « \(excerpt) »" }
                log.error(unusable, topic: .guide)
                return
            }
            let programmes = guide.programmes
            epgBySource[id] = programmes
            epgErrors[id] = nil
            let ids = report.channelIDsWithProgrammes
            let days = ((report.lastStop ?? Date()).timeIntervalSince(report.firstStart ?? Date())) / 86400
            let stamp = Date.FormatStyle(date: .abbreviated, time: .shortened)
            let first = (report.firstStart ?? Date()).formatted(stamp)
            let last = (report.lastStop ?? Date()).formatted(stamp)
            var summary = "Guide « \(source.name) » : \(programmes.count) programmes pour \(ids.count) chaîne(s) "
            summary += "(\(guide.channels.count) déclarée(s)), du \(first) au \(last) — \(String(format: "%.1f", days)) jour(s)"
            log.note(summary, topic: .guide)
            log.note("Guide « \(source.name) » : exemples d'identifiants du guide : \(ids.sorted().prefix(8).joined(separator: ", "))",
                     topic: .guide, detail: .detailed)
            rebuildEPG()
            Task.detached(priority: .utility) { Storage.save(programmes, name: "epg-\(id.uuidString)") }
        } catch {
            epgErrors[id] = Self.describe(error)
            log.error("Guide « \(source.name) » : échec du téléchargement (\(Self.describe(error))) — \(error.localizedDescription)",
                      topic: .guide)
        }
    }

    /// Recharge à la main le guide d'une source (réglages) et celui de secours, avec résultat dans le journal.
    func reloadGuide(for id: UUID) {
        Task {
            await refreshEPG(for: id, manual: true)
            await refreshFallbackEPG(force: true)
        }
    }

    /// Vrai si le guide d'une source manque ou se termine bientôt.
    private func epgNeedsRefresh(_ id: UUID) -> Bool {
        guard let list = epgBySource[id], !list.isEmpty else { return true }
        let latest = list.map(\.stop).max() ?? .distantPast
        return latest < Date().addingTimeInterval(12 * 3600)
    }

    /// Vérifie toutes les heures si les guides doivent être rechargés (application laissée ouverte).
    private func startEPGTicker() {
        epgTicker?.cancel()
        epgTicker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3600))
                guard let self else { return }
                for source in self.sources where source.isEnabled && self.epgNeedsRefresh(source.id) {
                    if let last = self.lastEPGAttempt[source.id], Date().timeIntervalSince(last) < 3 * 3600 { continue }
                    await self.refreshEPG(for: source.id)
                }
                await self.refreshFallbackEPG(force: false)
                self.rebuildEPG()
            }
        }
    }

    // MARK: - Guide de secours

    /// Télécharge le guide de secours s'il est activé et date de plus de 12 h (ou sur demande).
    func refreshFallbackEPG(force: Bool) async {
        guard EPGKeys.fallbackEnabled, let url = EPGKeys.fallbackURL, !fallbackStatus.isLoading else { return }
        if !force, let updated = fallbackStatus.updated, Date().timeIntervalSince(updated) < 12 * 3600,
           !fallbackProgrammes.isEmpty {
            let hours = Int(Date().timeIntervalSince(updated) / 3600)
            PlaybackLog.shared.note("Guide de secours : conservé (mis à jour il y a \(hours) h, \(fallbackProgrammes.count) programmes)",
                                    topic: .guide, detail: .debug)
            return
        }
        fallbackStatus.isLoading = true
        epgLoadingCount += 1
        defer {
            fallbackStatus.isLoading = false
            epgLoadingCount -= 1
        }
        let log = PlaybackLog.shared
        log.note("Guide de secours : demande\(force ? " manuelle" : "") à \(url.host ?? "?") — \(url.absoluteString)", topic: .guide)
        do {
            let report = try await EPGLoader.loadGuideReport(from: url, timeout: 300)
            let guide = report.guide
            let size = ByteCountFormatter.string(fromByteCount: Int64(report.byteCount), countStyle: .file)
            let fbStatus = report.status.map { "HTTP \($0)" } ?? "fichier"
            log.note("Guide de secours : réponse \(fbStatus) en \(String(format: "%.1f", report.seconds)) s, \(size)",
                     topic: .guide, detail: .detailed)
            guard guide.isValid, !guide.programmes.isEmpty else {
                fallbackStatus.error = String(localized: "Guide de secours vide ou illisible.")
                var fbBad = "Guide de secours : inutilisable (\(size), HTTP \(report.status.map(String.init) ?? "?"))"
                if let excerpt = report.bodyExcerpt { fbBad += " — début de la réponse : « \(excerpt) »" }
                log.error(fbBad, topic: .guide)
                return
            }
            log.note("Guide de secours : \(guide.programmes.count) programmes, \(guide.channels.count) chaîne(s)", topic: .guide)
            fallbackProgrammes = guide.programmes
            fallbackChannels = guide.channels
            let date = Date()
            defaults.set(date, forKey: EPGKeys.fallbackDate)
            fallbackStatus.updated = date
            fallbackStatus.error = nil
            fallbackStatus.programmeCount = guide.programmes.count
            fallbackStatus.channelCount = guide.channels.count
            let programmes = guide.programmes
            let channels = guide.channels
            Task.detached(priority: .utility) {
                Storage.save(programmes, name: "epg-fallback")
                Storage.save(channels, name: "epg-fallback-channels")
            }
            rebuildEPG()
        } catch {
            fallbackStatus.error = Self.describe(error)
            log.error("Guide de secours : échec du téléchargement (\(Self.describe(error)))", topic: .guide)
        }
    }

    /// Active ou désactive le guide de secours.
    func setFallbackEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: EPGKeys.fallbackEnabledKey)
        rebuildEPG()
        if enabled { Task { await refreshFallbackEPG(force: false) } }
    }

    /// Change l'adresse du guide de secours et le recharge.
    func setFallbackURL(_ text: String) {
        defaults.set(text.trimmingCharacters(in: .whitespacesAndNewlines), forKey: EPGKeys.fallbackURLKey)
        Task { await refreshFallbackEPG(force: true) }
    }

    func clearCache() {
        Storage.clear()
        refreshAll()
    }

    // MARK: - Séries

    /// Client Xtream d'une source (nil pour une playlist M3U).
    func xtreamClient(for sourceID: UUID) -> XtreamClient? {
        guard let source = self.source(id: sourceID), case .xtream(let server, let username) = source.kind,
              let password = Keychain.get(account: source.id.uuidString) else { return nil }
        return XtreamClient(credentials: XtreamCredentials(server: server, username: username, password: password),
                            sourceID: source.id)
    }

    func seasons(for series: MediaItem) async throws -> [SeriesSeason] {
        guard let found = self.source(id: series.sourceID) else { throw LibraryError.notXtream }
        switch found.kind {
        case .folders:
            // Épisodes trouvés dans les dossiers, rangés par saison.
            let episodes = (contents[found.id]?.items ?? []).filter { $0.kind == .episode && $0.seriesID == series.seriesID }
            let bySeason = Dictionary(grouping: episodes) { $0.season ?? 1 }
            return bySeason.keys.sorted().map { number in
                SeriesSeason(number: number, episodes: (bySeason[number] ?? []).sorted { ($0.number ?? 0, $0.name) < ($1.number ?? 0, $1.name) })
            }
        case .mediaServer:
            let result = try await withServer(found) { try await $0.episodes(of: series) }
            onServerProgress?(result.progress)
            return result.seasons
        default:
            break
        }
        guard let source = self.source(id: series.sourceID), case .xtream(let server, let username) = source.kind else {
            throw LibraryError.notXtream
        }
        guard let password = Keychain.get(account: source.id.uuidString) else { throw LibraryError.missingPassword }
        let client = XtreamClient(credentials: XtreamCredentials(server: server, username: username, password: password),
                                  sourceID: source.id)
        return try await client.seasons(for: series)
    }

    // MARK: - Favoris et historique

    func toggleFavorite(_ id: String) {
        if let index = favoriteIDs.firstIndex(of: id) {
            favoriteIDs.remove(at: index)
        } else {
            favoriteIDs.insert(id, at: 0)
        }
        defaults.set(favoriteIDs, forKey: Keys.favorites)
        saveExtras()
    }

    func recordPlay(_ item: MediaItem) {
        recentIDs.removeAll { $0 == item.id }
        recentIDs.insert(item.id, at: 0)
        if recentIDs.count > 60 { recentIDs.removeLast(recentIDs.count - 60) }
        if itemsByID[item.id] == nil { extraItems[item.id] = item }
        defaults.set(recentIDs, forKey: Keys.recents)
        saveExtras()
    }

    func clearRecents() {
        removeRecents(Set(recentIDs))
    }

    /// Retire des éléments de l'historique ; l'opération peut être annulée tant que le bandeau est affiché.
    func removeRecents(_ ids: Set<String>) {
        guard !ids.isEmpty, recentIDs.contains(where: { ids.contains($0) }) else { return }
        recentsBackup = RecentsBackup(ids: recentIDs, extras: extraItems,
                                      removedCount: recentIDs.filter { ids.contains($0) }.count)
        recentIDs.removeAll { ids.contains($0) }
        defaults.set(recentIDs, forKey: Keys.recents)
        saveExtras()
    }

    /// Annule la dernière suppression dans les récents.
    func undoRemoveRecents() {
        guard let backup = recentsBackup else { return }
        recentIDs = backup.ids
        extraItems = backup.extras
        recentsBackup = nil
        defaults.set(recentIDs, forKey: Keys.recents)
        saveExtras()
    }

    func discardRecentsUndo() {
        recentsBackup = nil
    }

    // MARK: - Interne

    private func saveSources() {
        if let data = try? JSONEncoder().encode(sources) { defaults.set(data, forKey: Keys.sources) }
    }

    private func saveExtras() {
        // On ne garde que les épisodes encore référencés par l'historique ou les favoris.
        let keep = Set(recentIDs).union(favoriteIDs)
        extraItems = extraItems.filter { keep.contains($0.key) }
        if let data = try? JSONEncoder().encode(extraItems) { defaults.set(data, forKey: Keys.extras) }
    }

    // MARK: - Corrections de chaînes

    /// Élément tel que fourni par la source (sans les corrections de l'utilisateur).
    func originalItem(id: String) -> MediaItem? {
        for content in contents.values {
            if let item = content.items.first(where: { $0.id == id }) { return item }
        }
        return nil
    }

    /// Enregistre (ou efface, si vide) la correction d'une chaîne.
    func saveChannelEdit(_ edit: ChannelEdit?, for id: String) {
        if let edit, !edit.isEmpty { channelEdits[id] = edit } else { channelEdits[id] = nil }
        if let data = try? JSONEncoder().encode(channelEdits) { defaults.set(data, forKey: ChannelEdit.storageKey) }
        rebuildIndex()
    }

    /// Chaînes du guide TV proposées pour corriger l'association d'une chaîne (guide du fournisseur et de secours).
    func guideChannelChoices() -> [GuideChannelChoice] {
        var choices: [String: GuideChannelChoice] = [:]
        for channel in fallbackChannels {
            choices[channel.id.lowercased()] = GuideChannelChoice(id: channel.id, name: channel.names.first ?? channel.id,
                                                                  source: String(localized: "Guide de secours"))
        }
        for list in epgBySource.values {
            for programme in list where choices[programme.channel.lowercased()] == nil {
                choices[programme.channel.lowercased()] = GuideChannelChoice(id: programme.channel, name: programme.channel,
                                                                              source: String(localized: "Fournisseur"))
            }
        }
        return choices.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Réaffiche ou masque les contenus adultes (réglage).
    func refreshAdultFilter() { rebuildIndex() }

    private func rebuildIndex() {
        let showAdult = UserDefaults.standard.bool(forKey: "adult.show")
        // 1. Catégories du fournisseur, dans l'ordre d'origine, avec leur nombre d'éléments.
        var providerOrder: [MediaKind: [String]] = [:]
        var counts: [MediaKind: [String: Int]] = [:]
        // Origine des films et séries (Tout / IPTV / Mes vidéos) : le direct reste toujours celui de l'IPTV.
        let origin = catalogOrigin
        for source in sources where source.isEnabled && (source.kind.isIPTV || origin != .iptv) {
            guard let content = contents[source.id] else { continue }
            for item in content.items where item.kind != .episode {
                if source.kind.isIPTV, origin == .library, item.kind != .live { continue }
                if counts[item.kind, default: [:]][item.group] == nil { providerOrder[item.kind, default: []].append(item.group) }
                counts[item.kind, default: [:]][item.group, default: 0] += 1
            }
        }
        // 2. Ordre personnalisé et catégories masquées.
        var ordered: [MediaKind: [String]] = [:]
        var hidden: [MediaKind: Set<String>] = [:]
        for (kind, names) in providerOrder {
            let prefs = categoryPrefs[kind] ?? CategoryPrefs()
            let all = prefs.apply(order: names)
            ordered[kind] = all
            hidden[kind] = Set(all.filter { prefs.isHidden($0) })
        }

        // 3. Index des contenus visibles (les éléments masqués restent accessibles par identifiant : favoris, récents).
        var byKind: [MediaKind: [MediaItem]] = [:]
        var byID: [String: MediaItem] = [:]
        var byCategory: [MediaKind: [String: [MediaItem]]] = [:]
        var library: [UUID: [MediaItem]] = [:]
        var libraryGroups: [MediaKind: Set<String>] = [:]
        for source in sources where source.isEnabled {
            guard let content = contents[source.id] else { continue }
            if !source.kind.isIPTV {
                // Dossiers et serveurs de la maison : toujours dans « Mes vidéos » ; dans Films et Séries selon le filtre.
                for original in content.items {
                    byID[original.id] = original
                    guard original.kind != .episode else { continue }
                    library[source.id, default: []].append(original)
                    guard origin != .iptv else { continue }
                    var item = original
                    if let prefs = categoryPrefs[item.kind] {
                        if hidden[item.kind]?.contains(item.group) == true { continue }
                        item.group = prefs.displayName(item.group)
                    }
                    byKind[item.kind, default: []].append(item)
                    byCategory[item.kind, default: [:]][item.group, default: []].append(item)
                    libraryGroups[item.kind, default: []].insert(item.group)
                }
                continue
            }
            for original in content.items {
                if origin == .library, original.kind == .movie || original.kind == .series {
                    byID[original.id] = original
                    continue
                }
                var item = original
                if let edit = channelEdits[item.id] { edit.apply(to: &item) }
                // Chaîne sans identifiant de guide : clé dérivée du nom, pour le guide de secours.
                if item.kind == .live, item.epgID?.isEmpty ?? true {
                    item.epgID = "auto:" + ChannelMatcher.normalize(item.name, keepResolution: true)
                }
                // Contenus adultes (« |XX| », catégorie adulte) : masqués partout tant que l'option n'est pas activée.
                if !showAdult, item.kind != .episode, ThemeClassifier.isAdult(name: item.name, group: item.group) {
                    byID[item.id] = item
                    continue
                }
                if item.kind != .episode, let prefs = categoryPrefs[item.kind] {
                    if hidden[item.kind]?.contains(item.group) == true {
                        byID[item.id] = item
                        continue
                    }
                    item.group = prefs.displayName(item.group)
                }
                byKind[item.kind, default: []].append(item)
                byID[item.id] = item
                byCategory[item.kind, default: [:]][item.group, default: []].append(item)
            }
        }
        var categories: [MediaKind: [String]] = [:]
        for (kind, names) in ordered {
            let prefs = categoryPrefs[kind] ?? CategoryPrefs()
            var seen = Set<String>()
            categories[kind] = names.filter { !(hidden[kind]?.contains($0) ?? false) && (showAdult || !ThemeClassifier.isAdult(name: "", group: $0)) }
                .map { prefs.displayName($0) }
                .filter { seen.insert($0).inserted }
        }
        itemsByKind = byKind
        categoriesByKind = categories
        allCategoriesByKind = ordered
        categoryCounts = counts
        itemsByID = byID
        itemsByCategory = byCategory
        libraryBySource = library
        libraryCategories = libraryGroups
        rebuildEPG()
    }

    // MARK: - Catégories personnalisées

    func prefs(for kind: MediaKind) -> CategoryPrefs { categoryPrefs[kind] ?? CategoryPrefs() }

    /// Modifie l'ordre, le masquage ou les noms des catégories d'un type de contenu.
    func updateCategories(_ kind: MediaKind, _ change: (inout CategoryPrefs) -> Void) {
        var prefs = categoryPrefs[kind] ?? CategoryPrefs()
        change(&prefs)
        categoryPrefs[kind] = prefs
        if let data = try? JSONEncoder().encode(prefs) { defaults.set(data, forKey: CategoryPrefs.key(kind)) }
        rebuildIndex()
    }

    /// Déplace des catégories (liste complète, noms d'origine).
    func moveCategories(_ kind: MediaKind, from offsets: IndexSet, to destination: Int) {
        var list = allCategoriesByKind[kind] ?? []
        list.move(fromOffsets: offsets, toOffset: destination)
        updateCategories(kind) { $0.order = list }
    }

    /// Reconstruit l'index du guide (hors du fil principal) : guide des fournisseurs, puis guide de secours
    /// pour les chaînes qui n'ont aucun programme.
    private func rebuildEPG() {
        var programmes: [Programme] = []
        var counts: [UUID: Int] = [:]
        for source in sources where source.isEnabled {
            let list = epgBySource[source.id] ?? []
            counts[source.id] = list.count
            programmes += list
        }
        epgCounts = counts
        epgGeneration += 1
        let generation = epgGeneration
        let live = itemsByKind[.live] ?? []
        let fallback = EPGKeys.fallbackEnabled ? fallbackProgrammes : []
        let channels = fallbackChannels
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                Self.buildEPG(provider: programmes, live: live, fallback: fallback, channels: channels)
            }.value
            guard generation == self.epgGeneration else { return }
            self.epg = result.index
            self.fallbackStatus.matchedChannels = result.matched
            let c = result.coverage
            var cover = "Guide : \(c.live) chaîne(s) en direct — \(c.provider) avec le guide du fournisseur, "
            cover += "\(result.matched) complétée(s) par le secours, \(c.inherited) reprenant le programme d'une autre version (4K, FHD…), "
            cover += "\(c.none) sans programme"
            if c.auto > 0 { cover += " (dont \(c.auto) sans identifiant de guide, rapprochées par leur nom)" }
            if c.separators > 0 { cover += " ; \(c.separators) séparateur(s) de catégorie ignoré(s)" }
            PlaybackLog.shared.note(cover, topic: .guide)
            PlaybackLog.shared.note("Guide : chaînes françaises — \(c.french - c.frenchNone) avec programme sur \(c.french) (\(c.frenchNone) sans programme)",
                                    topic: .guide)
            if !c.sampleUnmatched.isEmpty {
                PlaybackLog.shared.note("Guide : exemples de chaînes françaises sans programme : \(c.sampleUnmatched.joined(separator: " · "))",
                                        topic: .guide, detail: .detailed)
            }
            self.rebuildLiveGroups()
        }
    }

    // MARK: - Thèmes du direct

    /// Regroupe les versions d'une même chaîne (FHD, HD, SD, 4K) et leur attribue un thème.
    func rebuildLiveGroups() {
        let live = itemsByKind[.live] ?? []
        let index = epg
        let overrides = themeOverrides
        liveGroupsGeneration += 1
        let generation = liveGroupsGeneration
        Task {
            let groups = await Task.detached(priority: .utility) {
                Self.buildLiveGroups(live: live, epg: index, overrides: overrides)
            }.value
            guard generation == self.liveGroupsGeneration else { return }
            self.liveGroups = groups
        }
    }

    nonisolated static func buildLiveGroups(live: [MediaItem], epg: EPGIndex,
                                            overrides: [String: ContentTheme]) -> [LiveChannelGroup] {
        var order: [String] = []
        var byKey: [String: [MediaItem]] = [:]
        for item in live {
            let key = ChannelMatcher.variantKey(item.name)
            guard !key.isEmpty, !ChannelMatcher.isSeparator(item.name) else { continue }
            if byKey[key] == nil { order.append(key) }
            byKey[key, default: []].append(item)
        }
        return order.compactMap { key in
            guard let variants = byKey[key], let first = variants.first else { return nil }
            let programmes = variants.lazy.map { epg.programmes(for: $0.epgID) }.first { !$0.isEmpty } ?? []
            let named = variants.lazy.compactMap { ThemeClassifier.theme(forChannelName: $0.name, group: $0.group) }.first
            let auto = named
                ?? ThemeClassifier.dominantTheme(of: programmes)
                ?? .other
            let chosen = overrides[key]
            return LiveChannelGroup(key: key, variants: variants, autoTheme: auto, theme: chosen ?? auto,
                                    themeFromName: chosen != nil || named != nil,
                                    epgID: variants.first { !epg.programmes(for: $0.epgID).isEmpty }?.epgID ?? first.epgID)
        }
    }

    /// Change le thème d'une chaîne (nil : revenir au thème automatique).
    func setTheme(_ theme: ContentTheme?, forChannelKey key: String) {
        if let theme { themeOverrides[key] = theme } else { themeOverrides[key] = nil }
        if let data = try? JSONEncoder().encode(themeOverrides) { defaults.set(data, forKey: "themes.overrides.v1") }
        rebuildLiveGroups()
    }

    /// Couverture du guide pour les chaînes en direct (journal « Guide TV »).
    struct EPGCoverage: Sendable {
        var live = 0
        var provider = 0
        var none = 0
        var auto = 0
        /// Chaînes qui n'ont pas de programme propre mais reprennent celui d'une autre version (4K, FHD…).
        var inherited = 0
        /// Séparateurs de catégories du fournisseur (ignorés).
        var separators = 0
        /// Chaînes françaises : total et sans programme (les chaînes étrangères sont souvent sans guide).
        var french = 0
        var frenchNone = 0
        var sampleUnmatched: [String] = []
    }

    nonisolated static func buildEPG(provider: [Programme], live allLive: [MediaItem], fallback: [Programme],
                                     channels: [XMLTVChannel]) -> (index: EPGIndex, matched: Int, coverage: EPGCoverage) {
        var index = EPGIndex(programmes: provider)
        var coverage = EPGCoverage()
        // Les séparateurs de catégories (« ♣♦♣---|FR| FRANCE FHD |FR|---♣♦♣ ») ne sont pas de vraies chaînes.
        let live = allLive.filter { !ChannelMatcher.isSeparator($0.name) }
        coverage.separators = allLive.count - live.count
        coverage.live = live.count
        let matcher = channels.isEmpty ? nil : ChannelMatcher(channels: channels)
        let byChannel = Dictionary(grouping: fallback, by: \.channel)
        var extra: [Programme] = []
        var outcome: [String: Int] = [:]   // 0 : fournisseur, 1 : secours, 2 : rien (par identifiant, minuscules)
        var matched = 0
        for item in live {
            guard let key = item.epgID, !key.isEmpty else { continue }
            if key.hasPrefix("auto:") { coverage.auto += 1 }
            let lower = key.lowercased()
            if outcome[lower] != nil { continue }
            if index.hasProgrammes(for: key) { outcome[lower] = 0; continue }
            if let matcher, !fallback.isEmpty,
               let id = matcher.match(name: item.name, epgID: key.hasPrefix("auto:") ? nil : key),
               let list = byChannel[id], !list.isEmpty {
                matched += 1
                outcome[lower] = 1
                extra += list.map { programme in
                    var copy = programme
                    copy.channel = key
                    return copy
                }
            } else {
                outcome[lower] = 2
            }
        }
        index.merge(extra)

        // Les autres versions d'une chaîne (4K, FHD, UHD…) reprennent le programme de la version qui en a un.
        var variants: [String: [MediaItem]] = [:]
        for item in live {
            let key = ChannelMatcher.variantKey(item.name)
            if !key.isEmpty { variants[key, default: []].append(item) }
        }
        var inherited: [Programme] = []
        var inheritedKeys = Set<String>()
        for (_, items) in variants where items.count > 1 {
            guard let donor = items.first(where: { index.hasProgrammes(for: $0.epgID) }),
                  let donorList = Optional(index.programmes(for: donor.epgID)), !donorList.isEmpty else { continue }
            for item in items {
                guard let key = item.epgID, !key.isEmpty, !index.hasProgrammes(for: key),
                      inheritedKeys.insert(key.lowercased()).inserted else { continue }
                inherited += donorList.map { programme in
                    var copy = programme
                    copy.channel = key
                    return copy
                }
            }
        }
        index.merge(inherited)

        // Couverture finale, chaîne par chaîne.
        for item in live {
            let hasGuide = index.hasProgrammes(for: item.epgID)
            let isFrench = CountryDetector.code(for: item) == "FR"
            if isFrench { coverage.french += 1 }
            if hasGuide {
                if let key = item.epgID, outcome[key.lowercased()] == 0 { coverage.provider += 1 }
                else if let key = item.epgID, inheritedKeys.contains(key.lowercased()) { coverage.inherited += 1 }
            } else {
                coverage.none += 1
                if isFrench {
                    coverage.frenchNone += 1
                    if coverage.sampleUnmatched.count < 8 { coverage.sampleUnmatched.append("\(item.name) [\(item.epgID ?? "—")]") }
                }
            }
        }
        return (index, matched, coverage)
    }

    // MARK: - Chargement (hors du fil principal)

    nonisolated static func fetch(_ source: Source, password: String?) async throws -> SourceContent {
        switch source.kind {
        case .m3uURL(let url):
            let data = try await HTTP.get(url, timeout: 120)
            return try parseM3U(data, sourceID: source.id)
        case .m3uFile(let bookmark, _):
            var stale = false
            let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope,
                              relativeTo: nil, bookmarkDataIsStale: &stale)
            let granted = url.startAccessingSecurityScopedResource()
            defer { if granted { url.stopAccessingSecurityScopedResource() } }
            return try parseM3U(try Data(contentsOf: url), sourceID: source.id)
        case .xtream(let server, let username):
            guard let password, !password.isEmpty else { throw LibraryError.missingPassword }
            let client = XtreamClient(credentials: XtreamCredentials(server: server, username: username, password: password),
                                      sourceID: source.id)
            return try await client.fetchLibrary()
        case .folders(let bookmarks, let paths):
            guard !bookmarks.isEmpty else { throw LibraryError.noFolder }
            let roots = FolderAccess.resolve(bookmarks).filter { FileManager.default.fileExists(atPath: $0.path) }
            guard !roots.isEmpty else { throw LibraryError.folderMissing(paths.joined(separator: ", ")) }
            let labels = FolderScanner.Labels(movies: String(localized: "Films"), series: String(localized: "Séries"),
                                              videos: String(localized: "Vidéos"))
            return FolderScanner.scan(roots: roots, sourceID: source.id, labels: labels)
        case .mediaServer(let type, _, _):
            let client = try await makeServerClient(source, forceSignIn: false)
            do {
                return try await client.fetchLibrary()
            } catch let error as MediaServerError where error.isAccessDenied && type != .plex {
                // Session expirée (Jellyfin / Emby) : nouvelle connexion avec le mot de passe.
                return try await makeServerClient(source, forceSignIn: true).fetchLibrary()
            }
        }
    }

    /// Ouvre (ou rouvre) la session d'un serveur multimédia. Jellyfin / Emby : identifiant et mot de passe (ou clé d'API) ;
    /// Plex : jeton enregistré.
    nonisolated static func makeServerClient(_ source: Source, forceSignIn: Bool) async throws -> any MediaServerClient {
        guard case .mediaServer(let type, let server, let username) = source.kind else { throw LibraryError.notXtream }
        let account = "session.\(source.id.uuidString)"
        var session = ServerSession.decode(Keychain.get(account: account))
        if type == .plex {
            // Sans jeton : serveur ouvert au réseau local.
            return PlexClient(server: server, sourceID: source.id, token: session?.token ?? "", label: source.name)
        }
        if session == nil || forceSignIn {
            let password = Keychain.get(account: source.id.uuidString) ?? ""
            let opened = try await JellyfinClient.signIn(server: server, username: username, password: password, emby: type == .emby)
            Keychain.set(opened.encoded(), account: account)
            session = opened
        }
        guard let session else { throw MediaServerError.unreadable }
        return JellyfinClient(server: server, sourceID: source.id, session: session, emby: type == .emby, label: source.name,
                              videosLabel: String(localized: "Vidéos"))
    }

    nonisolated static func parseM3U(_ data: Data, sourceID: UUID) throws -> SourceContent {
        let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        let result = M3UParser.parse(text, sourceID: sourceID)
        if result.items.isEmpty { throw LibraryError.emptyPlaylist }
        return SourceContent(items: result.items, epgURL: result.epgURL)
    }

    nonisolated static func loadGuide(_ url: URL, timeout: TimeInterval) async throws -> XMLTVGuide {
        try await EPGLoader.loadGuide(from: url, timeout: timeout)
    }
}

/// État de l'historique avant une suppression.
struct RecentsBackup {
    let ids: [String]
    let extras: [String: MediaItem]
    let removedCount: Int
}

/// État du guide de secours (réglages).
struct FallbackEPGStatus {
    var isLoading = false
    var updated: Date?
    var error: String?
    var programmeCount = 0
    var channelCount = 0
    var matchedChannels = 0
}

/// Réglages du guide TV de secours.
enum EPGKeys {
    static let fallbackEnabledKey = "epg.fallback.enabled"
    static let fallbackURLKey = "epg.fallback.url"
    static let fallbackDate = "epg.fallback.date"
    static let defaultFallbackURL = "https://xmltvfr.fr/xmltv/xmltv.xml.gz"

    /// Guides proposés par xmltvfr.fr.
    static let presets: [(label: String, url: String)] = [
        (String(localized: "xmltvfr.fr — Complet (~785 chaînes)"), "https://xmltvfr.fr/xmltv/xmltv.xml.gz"),
        (String(localized: "xmltvfr.fr — France (~400 chaînes)"), "https://xmltvfr.fr/xmltv/xmltv_fr.xml.gz"),
        (String(localized: "xmltvfr.fr — TNT France"), "https://xmltvfr.fr/xmltv/xmltv_tnt.xml.gz"),
    ]

    static var fallbackEnabled: Bool { UserDefaults.standard.object(forKey: fallbackEnabledKey) as? Bool ?? true }

    static var fallbackURLText: String {
        let text = UserDefaults.standard.string(forKey: fallbackURLKey) ?? ""
        return text.isEmpty ? defaultFallbackURL : text
    }

    static var fallbackURL: URL? {
        let text = fallbackURLText
        guard let url = URL(string: text), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
        return url
    }
}

/// Préférences d'affichage des catégories d'un type de contenu.
struct CategoryPrefs: Codable, Equatable {
    /// Ordre choisi (noms d'origine). Les catégories absentes gardent l'ordre du fournisseur, à la suite.
    var order: [String] = []
    var hidden: Set<String> = []
    var renames: [String: String] = [:]
    /// Mots-clés : toute catégorie dont le nom en contient un est masquée.
    var keywords: [String] = []

    static let kinds: [MediaKind] = [.live, .movie, .series]
    static func key(_ kind: MediaKind) -> String { "categories.\(kind.rawValue).v1" }

    func isHidden(_ name: String) -> Bool {
        if hidden.contains(name) { return true }
        return keywords.contains { !$0.isEmpty && name.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    func isHiddenByKeyword(_ name: String) -> Bool {
        !hidden.contains(name) && isHidden(name)
    }

    func displayName(_ name: String) -> String {
        if let renamed = renames[name], !renamed.trimmingCharacters(in: .whitespaces).isEmpty { return renamed }
        return name
    }

    /// Applique l'ordre personnalisé à la liste du fournisseur.
    func apply(order provider: [String]) -> [String] {
        guard !order.isEmpty else { return provider }
        let available = Set(provider)
        var result = order.filter { available.contains($0) }
        let placed = Set(result)
        // Nouvelle catégorie du fournisseur : insérée après sa voisine d'origine déjà placée.
        for (index, name) in provider.enumerated() where !placed.contains(name) {
            if index > 0, let anchor = result.firstIndex(of: provider[index - 1]) {
                result.insert(name, at: anchor + 1)
            } else {
                result.append(name)
            }
        }
        return result
    }
}

/// Une chaîne du direct et toutes ses versions (qualités).
struct LiveChannelGroup: Identifiable, Sendable {
    let key: String
    let variants: [MediaItem]
    let autoTheme: ContentTheme
    let theme: ContentTheme
    /// Le thème vient du nom de la chaîne (ou d'un choix de l'utilisateur) : fiable même sans guide TV.
    let themeFromName: Bool
    /// Identifiant de guide qui a des programmes (parmi les versions).
    let epgID: String?
    var id: String { key }

    /// Version à lire selon la qualité choisie (ou mesurée).
    var preferred: MediaItem {
        ChannelQuality.pick(variants, target: QualityPreference.target, quality: { ChannelQuality.of($0.name) }) ?? variants[0]
    }
}

/// Correction d'une chaîne par l'utilisateur.
struct ChannelEdit: Codable, Equatable {
    static let storageKey = "channelEdits.v1"
    var name: String?
    var number: Int?
    var epgID: String?
    var logo: URL?

    var isEmpty: Bool { name == nil && number == nil && epgID == nil && logo == nil }

    func apply(to item: inout MediaItem) {
        if let name, !name.isEmpty { item.name = name }
        if let number { item.number = number }
        if let epgID, !epgID.isEmpty { item.epgID = epgID }
        if let logo { item.logoURL = logo }
    }
}

/// Chaîne du guide TV proposée dans l'éditeur.
struct GuideChannelChoice: Identifiable, Hashable {
    let id: String
    let name: String
    let source: String
}

// MARK: - Dossiers de vidéos et serveurs multimédias

extension LibraryStore {
    /// Vrai pour un fichier d'un dossier local (disque, clé USB, NAS).
    func isLocalFile(_ item: MediaItem) -> Bool {
        if case .folders = source(id: item.sourceID)?.kind { return true }
        return false
    }

    /// Vrai pour un contenu de la vidéothèque (dossiers, serveurs).
    func isLibraryItem(_ item: MediaItem) -> Bool {
        !(source(id: item.sourceID)?.kind.isIPTV ?? true)
    }

    /// Sources de la vidéothèque (actives).
    var librarySources: [Source] { sources.filter { $0.isEnabled && !$0.kind.isIPTV } }
    var hasLibrary: Bool { sources.contains { !$0.kind.isIPTV } }

    /// Films, séries et vidéos de la vidéothèque (d'une source, ou de toutes).
    func libraryItems(source: UUID? = nil) -> [MediaItem] {
        if let source { return libraryBySource[source] ?? [] }
        return sources.flatMap { libraryBySource[$0.id] ?? [] }
    }

    /// Vrai pour un contenu d'un serveur Jellyfin, Emby ou Plex.
    func isServerItem(_ item: MediaItem) -> Bool {
        source(id: item.sourceID)?.kind.serverType != nil
    }

    /// Client du serveur d'une source (session gardée en mémoire).
    func serverClient(for source: Source, forceSignIn: Bool = false) async throws -> any MediaServerClient {
        if !forceSignIn, let client = serverClients[source.id] { return client }
        let client = try await Self.makeServerClient(source, forceSignIn: forceSignIn)
        serverClients[source.id] = client
        return client
    }

    /// Exécute une requête sur le serveur ; une session expirée (Jellyfin / Emby) est rouverte une fois.
    func withServer<T>(_ source: Source, _ operation: (any MediaServerClient) async throws -> T) async throws -> T {
        do {
            return try await operation(try await serverClient(for: source))
        } catch let error as MediaServerError where error.isAccessDenied && source.kind.serverType != .plex {
            return try await operation(try await serverClient(for: source, forceSignIn: true))
        }
    }

    /// Ajoute un serveur Jellyfin / Emby (identifiant et mot de passe vérifiés) ou Plex (jeton vérifié).
    func addMediaServer(_ source: Source, password: String, token: String?) async throws {
        try await openServerSession(source, password: password, token: token)
        addSource(source, password: nil)
    }

    /// Modifie un serveur : nouvelle connexion si l'adresse, l'identifiant, le mot de passe ou le jeton changent.
    func updateMediaServer(_ source: Source, password: String, token: String?, accessChanged: Bool) async throws {
        if accessChanged || !password.isEmpty || !(token ?? "").isEmpty {
            var pass = password
            if pass.isEmpty { pass = Keychain.get(account: source.id.uuidString) ?? "" }
            var plexToken = token
            if (plexToken ?? "").isEmpty { plexToken = ServerSession.decode(Keychain.get(account: "session.\(source.id.uuidString)"))?.token }
            try await openServerSession(source, password: pass, token: plexToken)
        }
        updateSource(source, password: nil)
    }

    private func openServerSession(_ source: Source, password: String, token: String?) async throws {
        guard case .mediaServer(let type, let server, let username) = source.kind else { return }
        let session: ServerSession
        if type == .plex {
            // Jeton facultatif : un serveur peut être ouvert au réseau local sans authentification.
            let value = (token ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await PlexClient(server: server, sourceID: source.id, token: value).identity()
            session = ServerSession(token: value)
        } else {
            session = try await JellyfinClient.signIn(server: server, username: username, password: password, emby: type == .emby)
            Keychain.set(password, account: source.id.uuidString)
        }
        Keychain.set(session.encoded(), account: "session.\(source.id.uuidString)")
        serverClients[source.id] = nil
    }

    /// Fiche d'un film ou d'une série d'un serveur.
    func serverDetails(_ item: MediaItem) async throws -> MediaDetails? {
        guard let source = source(id: item.sourceID), source.kind.serverType != nil else { return nil }
        return try await withServer(source) { try await $0.details(of: item) }
    }

    /// Signale au serveur la lecture en cours (reprise partagée avec ses autres appareils).
    func reportPlayback(_ item: MediaItem, position: Double, duration: Double, event: PlaybackEvent) {
        guard item.kind != .live, let source = source(id: item.sourceID), source.kind.serverType != nil else { return }
        if event == .progress, let last = lastReport[item.id], Date().timeIntervalSince(last) < 15 { return }
        lastReport[item.id] = Date()
        Task {
            do {
                try await withServer(source) { try await $0.report(item, position: position, duration: duration, event: event) }
                if event == .stop, duration > 0, position / duration >= 0.92 {
                    try await withServer(source) { try await $0.setPlayed(item, played: true) }
                }
            } catch {
                PlaybackLog.shared.note("Serveur « \(source.name) » : position non transmise (\(error.localizedDescription))")
            }
        }
    }

    /// « Marquer comme vu / non vu » : transmis au serveur.
    func setPlayedOnServer(_ item: MediaItem, _ played: Bool) {
        guard let source = source(id: item.sourceID), source.kind.serverType != nil else { return }
        Task {
            do {
                try await withServer(source) { try await $0.setPlayed(item, played: played) }
            } catch {
                PlaybackLog.shared.note("Serveur « \(source.name) » : état « vu » non transmis (\(error.localizedDescription))")
            }
        }
    }

    /// Affiches et résumés trouvés sur TMDB pour les fichiers locaux (gardés dans le cache de la source).
    func applyEnrichment(_ sourceID: UUID, _ found: [String: LocalFiche]) {
        guard var content = contents[sourceID], !found.isEmpty else { return }
        for index in content.items.indices {
            guard let update = found[content.items[index].id] else { continue }
            if let logo = update.logo { content.items[index].logoURL = logo }
            if let info = update.info, !info.isEmpty { content.items[index].info = info }
            if let year = update.year { content.items[index].year = year }
            if !update.genres.isEmpty { content.items[index].genres = update.genres }
        }
        contents[sourceID] = content
        rebuildIndex()
        let snapshot = content
        Task.detached(priority: .utility) { Storage.save(snapshot, name: "content-\(sourceID.uuidString)") }
    }

    /// Contenu chargé d'une source.
    func content(of sourceID: UUID) -> SourceContent? { contents[sourceID] }

    /// Examine à nouveau les dossiers toutes les 20 minutes et les serveurs toutes les heures (application laissée ouverte).
    fileprivate func startRescanTicker() {
        rescanTicker?.cancel()
        rescanTicker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(20 * 60))
                guard let self else { return }
                for source in self.sources where source.isEnabled && !self.loading.contains(source.id) {
                    switch source.kind {
                    case .folders:
                        self.refresh(source)
                    case .mediaServer:
                        if (source.lastRefresh ?? .distantPast) < Date().addingTimeInterval(-3600) { self.refresh(source) }
                    default:
                        break
                    }
                }
            }
        }
    }
}

// MARK: - Exportation / importation de la configuration (commune au Mac, à Windows et à Linux)

extension LibraryStore {
    /// Identifiant relatif à la source : « numéro de source|reste de l'identifiant ».
    private func relativeID(_ id: String, sourceIndex: [UUID: Int]) -> String? {
        guard let item = item(id: id) ?? extraItem(id: id),
              let index = sourceIndex[item.sourceID] else { return nil }
        let prefix = item.sourceID.uuidString + ":"
        guard id.hasPrefix(prefix) else { return nil }
        return "\(index)|\(id.dropFirst(prefix.count))"
    }

    private func extraItem(id: String) -> MediaItem? { extraItems[id] }

    func makeExport(includePasswords: Bool) -> KastideoExport {
        var export = KastideoExport()
        var sourceIndex: [UUID: Int] = [:]
        for source in sources {
            switch source.kind {
            case .xtream(let server, let username):
                sourceIndex[source.id] = export.sources.count
                export.sources.append(.init(name: source.name, kind: "xtream", address: server.absoluteString, username: username,
                                            password: includePasswords ? Keychain.get(account: source.id.uuidString) : nil,
                                            epgUrl: source.epgURL?.absoluteString, enabled: source.isEnabled))
            case .m3uURL(let url):
                sourceIndex[source.id] = export.sources.count
                export.sources.append(.init(name: source.name, kind: "m3uUrl", address: url.absoluteString, username: nil,
                                            password: nil, epgUrl: source.epgURL?.absoluteString, enabled: source.isEnabled))
            case .m3uFile:
                continue
            case .folders(_, let paths):
                sourceIndex[source.id] = export.sources.count
                export.sources.append(.init(name: source.name, kind: "folder", address: paths.joined(separator: "\n"), username: nil,
                                            password: nil, epgUrl: nil, enabled: source.isEnabled))
            case .mediaServer(let type, let server, let username):
                sourceIndex[source.id] = export.sources.count
                let session = ServerSession.decode(Keychain.get(account: "session.\(source.id.uuidString)"))
                export.sources.append(.init(name: source.name, kind: type.rawValue, address: server.absoluteString,
                                            username: username.isEmpty ? nil : username,
                                            password: includePasswords && type != .plex ? Keychain.get(account: source.id.uuidString) : nil,
                                            token: includePasswords && type == .plex ? session?.token : nil,
                                            epgUrl: nil, enabled: source.isEnabled))
            }
        }
        export.favorites = favoriteIDs.compactMap { relativeID($0, sourceIndex: sourceIndex) }
        export.recents = recentIDs.compactMap { relativeID($0, sourceIndex: sourceIndex) }
        for kind in CategoryPrefs.kinds {
            guard let prefs = categoryPrefs[kind], let name = KastideoExport.kindNames[kind] else { continue }
            export.categories[name] = .init(order: prefs.order, hidden: Array(prefs.hidden), renames: prefs.renames, keywords: prefs.keywords)
        }
        let defaults = UserDefaults.standard
        for key in ["interface.live", "interface.movie", "interface.series", "adult.show", "buffering", CountryKeys.codes, CountryKeys.neutral] {
            if let value = defaults.object(forKey: key) { export.settings[key] = "\(value)" }
        }
        if includePasswords, let key = MediaInfoStore.storedTMDBKey, !key.isEmpty { export.settings["tmdbKey"] = key }
        return export
    }

    /// Ajoute les sources absentes (même type, même adresse et même identifiant = déjà présente), les favoris,
    /// les récents, les catégories et les réglages du fichier. Rien n'est supprimé.
    func importConfig(_ export: KastideoExport) -> ImportSummary {
        var summary = ImportSummary()
        var newIDs: [Int: UUID] = [:]
        for (index, entry) in export.sources.enumerated() {
            guard let url = URL(string: entry.address) else { continue }
            let kind: SourceKind
            switch entry.kind {
            case "xtream": kind = .xtream(server: url, username: entry.username ?? "")
            case "m3uUrl": kind = .m3uURL(url)
            case "jellyfin", "emby", "plex":
                // Serveur : ajouté tel quel, la connexion se fait au chargement.
                guard let type = MediaServerType(rawValue: entry.kind),
                      let server = try? MediaServerHTTP.normalize(entry.address, type: type) else { continue }
                kind = .mediaServer(type: type, server: server, username: entry.username ?? "")
                if let existing = sources.first(where: { $0.kind == kind }) {
                    newIDs[index] = existing.id
                    summary.sourcesSkipped += 1
                    continue
                }
                let source = Source(name: entry.name, kind: kind, isEnabled: entry.enabled)
                if let password = entry.password, !password.isEmpty { Keychain.set(password, account: source.id.uuidString) }
                if let token = entry.token, !token.isEmpty {
                    Keychain.set(ServerSession(token: token).encoded(), account: "session.\(source.id.uuidString)")
                }
                newIDs[index] = source.id
                addSource(source, password: nil)
                summary.sourcesAdded += 1
                continue
            default:
                // Dossiers d'un autre ordinateur : à choisir à nouveau sur ce Mac (accès du bac à sable).
                continue
            }
            if let existing = sources.first(where: { $0.kind == kind }) {
                newIDs[index] = existing.id
                summary.sourcesSkipped += 1
                if let password = entry.password, !password.isEmpty, Keychain.get(account: existing.id.uuidString) == nil {
                    Keychain.set(password, account: existing.id.uuidString)
                }
                continue
            }
            let source = Source(name: entry.name, kind: kind, epgURL: entry.epgUrl.flatMap(URL.init(string:)), isEnabled: entry.enabled)
            newIDs[index] = source.id
            addSource(source, password: entry.password)
            summary.sourcesAdded += 1
        }
        func absolute(_ relative: String) -> String? {
            let parts = relative.split(separator: "|", maxSplits: 1)
            guard parts.count == 2, let index = Int(parts[0]), let id = newIDs[index] else { return nil }
            return "\(id.uuidString):\(parts[1])"
        }
        for id in export.favorites.compactMap(absolute) where !favoriteIDs.contains(id) {
            favoriteIDs.append(id)
            summary.favoritesAdded += 1
        }
        UserDefaults.standard.set(favoriteIDs, forKey: "favorites.v1")
        for id in export.recents.compactMap(absolute) where !recentIDs.contains(id) {
            recentIDs.append(id)
        }
        if recentIDs.count > 60 { recentIDs.removeLast(recentIDs.count - 60) }
        UserDefaults.standard.set(recentIDs, forKey: "recents.v1")
        for kind in CategoryPrefs.kinds {
            guard let name = KastideoExport.kindNames[kind], let imported = export.categories[name] else { continue }
            updateCategories(kind) { prefs in
                prefs.order = imported.order
                prefs.hidden = Set(imported.hidden)
                prefs.renames = imported.renames
                prefs.keywords = imported.keywords
            }
            summary.categoriesImported += 1
        }
        let defaults = UserDefaults.standard
        for key in ["interface.live", "interface.movie", "interface.series"] {
            if let value = export.settings[key], InterfaceStyle(rawValue: value) != nil { defaults.set(value, forKey: key) }
        }
        if let value = export.settings["adult.show"] { defaults.set(value == "1" || value == "true", forKey: "adult.show") }
        if let value = export.settings[CountryKeys.codes] { defaults.set(value, forKey: CountryKeys.codes) }
        if let value = export.settings[CountryKeys.neutral] { defaults.set(value == "1" || value == "true", forKey: CountryKeys.neutral) }
        rebuildIndex()
        return summary
    }
}
