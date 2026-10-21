import Foundation
import Observation
import KastideoCore

enum LibraryError: LocalizedError {
    case missingPassword
    case emptyPlaylist
    case notXtream

    var errorDescription: String? {
        switch self {
        case .missingPassword: return String(localized: "Mot de passe introuvable dans le trousseau. Modifiez la source pour le saisir à nouveau.")
        case .emptyPlaylist: return String(localized: "La playlist ne contient aucun flux lisible.")
        case .notXtream: return String(localized: "Cette source ne fournit pas de liste d'épisodes.")
        }
    }
}

/// Bibliothèque : sources, contenus chargés, guide TV, favoris et historique.
@MainActor
@Observable
final class LibraryStore {
    private(set) var sources: [Source] = []
    private(set) var contents: [UUID: SourceContent] = [:]
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
    @ObservationIgnored private var epgGeneration = 0
    @ObservationIgnored private var lastEPGAttempt: [UUID: Date] = [:]
    @ObservationIgnored private var epgTicker: Task<Void, Never>?

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
        case .home, .recordings, .guide:
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
            if contents[source.id] == nil || (autoRefresh && (source.lastRefresh ?? .distantPast) < staleLimit) {
                refresh(source)
            } else if epgNeedsRefresh(source.id) {
                Task { await refreshEPG(for: source.id) }
            }
        }
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
        Task {
            do {
                let content = try await Self.fetch(source, password: password)
                guard sources.contains(where: { $0.id == source.id }) else { loading.remove(source.id); return }
                contents[source.id] = content
                if let index = sources.firstIndex(where: { $0.id == source.id }) {
                    sources[index].lastRefresh = Date()
                    saveSources()
                }
                rebuildIndex()
                loading.remove(source.id)
                let id = source.id
                Task.detached(priority: .utility) { Storage.save(content, name: "content-\(id.uuidString)") }
                await refreshEPG(for: source.id)
            } catch {
                errors[source.id] = Self.describe(error)
                loading.remove(source.id)
            }
        }
    }

    func refreshEPG(for id: UUID) async {
        guard let source = self.source(id: id), source.isEnabled,
              let url = source.epgURL ?? contents[id]?.epgURL else { return }
        epgLoadingCount += 1
        defer { epgLoadingCount -= 1 }
        lastEPGAttempt[id] = Date()
        do {
            let guide = try await Self.loadGuide(url, timeout: 180)
            // Réponse vide ou illisible : on garde les programmes déjà connus (le guide de secours prend le relais).
            guard guide.isValid, !guide.programmes.isEmpty else {
                let size = ByteCountFormatter.string(fromByteCount: Int64(guide.byteCount), countStyle: .file)
                epgErrors[id] = guide.isValid
                    ? String(localized: "Le fournisseur a envoyé un guide sans programme pour les prochains jours (\(size)).")
                    : String(localized: "Le fournisseur a envoyé un guide vide ou illisible (\(size)).")
                PlaybackLog.shared.note("Guide TV du fournisseur inutilisable (\(size), valide : \(guide.isValid), programmes : \(guide.programmes.count))")
                return
            }
            let programmes = guide.programmes
            epgBySource[id] = programmes
            epgErrors[id] = nil
            rebuildEPG()
            Task.detached(priority: .utility) { Storage.save(programmes, name: "epg-\(id.uuidString)") }
        } catch {
            epgErrors[id] = Self.describe(error)
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
           !fallbackProgrammes.isEmpty { return }
        fallbackStatus.isLoading = true
        epgLoadingCount += 1
        defer {
            fallbackStatus.isLoading = false
            epgLoadingCount -= 1
        }
        do {
            let guide = try await Self.loadGuide(url, timeout: 300)
            guard guide.isValid, !guide.programmes.isEmpty else {
                fallbackStatus.error = String(localized: "Guide de secours vide ou illisible.")
                return
            }
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

    private func rebuildIndex() {
        var byKind: [MediaKind: [MediaItem]] = [:]
        var categories: [MediaKind: [String]] = [:]
        var seen: [MediaKind: Set<String>] = [:]
        var byID: [String: MediaItem] = [:]
        var byCategory: [MediaKind: [String: [MediaItem]]] = [:]
        for source in sources where source.isEnabled {
            guard let content = contents[source.id] else { continue }
            for original in content.items {
                var item = original
                // Chaîne sans identifiant de guide : clé dérivée du nom, pour le guide de secours.
                if item.kind == .live, item.epgID?.isEmpty ?? true {
                    item.epgID = "auto:" + ChannelMatcher.normalize(item.name, keepResolution: true)
                }
                byKind[item.kind, default: []].append(item)
                if seen[item.kind, default: []].insert(item.group).inserted {
                    categories[item.kind, default: []].append(item.group)
                }
                byID[item.id] = item
                byCategory[item.kind, default: [:]][item.group, default: []].append(item)
            }
        }
        itemsByKind = byKind
        categoriesByKind = categories
        itemsByID = byID
        itemsByCategory = byCategory
        rebuildEPG()
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
        }
    }

    nonisolated static func buildEPG(provider: [Programme], live: [MediaItem], fallback: [Programme],
                                     channels: [XMLTVChannel]) -> (index: EPGIndex, matched: Int) {
        var index = EPGIndex(programmes: provider)
        guard !fallback.isEmpty, !channels.isEmpty else { return (index, 0) }
        let matcher = ChannelMatcher(channels: channels)
        let byChannel = Dictionary(grouping: fallback, by: \.channel)
        var extra: [Programme] = []
        var done = Set<String>()
        var matched = 0
        for item in live {
            guard let key = item.epgID, !key.isEmpty else { continue }
            let lower = key.lowercased()
            if done.contains(lower) || index.hasProgrammes(for: key) { continue }
            done.insert(lower)
            let id = matcher.match(name: item.name, epgID: key.hasPrefix("auto:") ? nil : key)
            guard let id, let list = byChannel[id], !list.isEmpty else { continue }
            matched += 1
            extra += list.map { programme in
                var copy = programme
                copy.channel = key
                return copy
            }
        }
        index.merge(extra)
        return (index, matched)
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
        }
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
