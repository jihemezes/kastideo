import SwiftUI
import KastideoCore

/// Fiches des films et séries : informations du fournisseur IPTV, complétées par TMDB si une clé est saisie.
@MainActor
@Observable
final class MediaInfoStore {
    private static let keychainAccount = "tmdb.apiKey"

    private(set) var cache: [String: MediaDetails] = [:]
    private(set) var loading: Set<String> = []
    private(set) var errors: [String: String] = [:]
    /// Clé TMDB (trousseau). Vide : TMDB n'est pas utilisé.
    var tmdbKey: String {
        didSet {
            let key = tmdbKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if key.isEmpty { Keychain.delete(account: Self.keychainAccount) } else { Keychain.set(key, account: Self.keychainAccount) }
            cache.removeAll()
        }
    }

    init() {
        tmdbKey = Keychain.get(account: Self.keychainAccount) ?? ""
        edits = FicheEdits.load()
    }

    var usesTMDB: Bool { !tmdbKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var language: String { (Bundle.main.preferredLocalizations.first ?? "fr") == "en" ? "en-US" : "fr-FR" }

    func details(for item: MediaItem) -> MediaDetails? { cache[item.id] }

    func isLoading(_ item: MediaItem) -> Bool { loading.contains(item.id) }

    /// Charge la fiche (une seule fois par session).
    func load(_ item: MediaItem, store: LibraryStore) async {
        guard cache[item.id] == nil, !loading.contains(item.id) else { return }
        loading.insert(item.id)
        defer { loading.remove(item.id) }
        let isSeries = item.kind == .series

        var details = MediaDetails()
        details.title = item.name
        if let plot = item.info { details.plot = plot }
        details.posterURL = item.logoURL
        let source = store.source(id: item.sourceID)
        let isLocal = store.isLocalFile(item)
        // Vidéos personnelles (dossiers) : recherche TMDB seulement si le réglage est activé (titre exact exigé).
        let isPersonal = isLocal && item.group.hasPrefix(String(localized: "Vidéos") + " · ")
        let personalAllowed = UserDefaults.standard.object(forKey: "tmdb.personal") as? Bool ?? true
        if isLocal {
            let cleaned = TMDB.cleanTitle(item.name)
            details.title = cleaned.title
            details.year = cleaned.year
            details.sources = [String(localized: "Fichier local")]
        }
        let edit = edits[item.id]

        if source?.kind.serverType != nil {
            do {
                if var server = try await store.serverDetails(item) {
                    if server.title == nil { server.title = item.name }
                    if server.plot == nil { server.plot = details.plot }
                    if server.posterURL == nil { server.posterURL = item.logoURL }
                    details = server
                }
            } catch {
                PlaybackLog.shared.note("Fiche du serveur indisponible pour « \(item.name) » : \(error.localizedDescription)")
            }
        } else if let client = store.xtreamClient(for: item.sourceID) {
            do {
                let iptv: MediaDetails?
                if isSeries, let id = item.seriesID {
                    iptv = try await client.seriesDetails(seriesID: id)
                } else if item.kind == .movie, let id = item.id.split(separator: ":").last.map(String.init) {
                    iptv = try await client.movieDetails(streamID: id)
                } else {
                    iptv = nil
                }
                if let iptv {
                    var base = iptv
                    if base.title == nil { base.title = item.name }
                    if base.plot == nil { base.plot = details.plot }
                    if base.posterURL == nil { base.posterURL = item.logoURL }
                    details = base
                }
            } catch {
                PlaybackLog.shared.note("Fiche IPTV indisponible pour « \(item.name) » : \(error.localizedDescription)")
            }
        }

        // Fiche TMDB choisie à la main : elle l'emporte sur l'identifiant du fournisseur.
        if let id = edit?.tmdbID, !id.isEmpty { details.tmdbID = id }
        if usesTMDB, !isPersonal || personalAllowed || details.tmdbID != nil {
            let client = TMDBClient(apiKey: tmdbKey, language: language)
            do {
                if isPersonal, details.tmdbID == nil {
                    details.tmdbID = try await client.exactMatch(name: item.name, isSeries: isSeries)?.tmdbID
                }
                // Vidéo personnelle sans titre exact trouvé : on garde la fiche telle quelle.
                let skip = isPersonal && details.tmdbID == nil
                if !skip, let tmdb = try await client.details(title: isLocal ? (details.title ?? item.name) : item.name, isSeries: isSeries,
                                                       tmdbID: details.tmdbID, year: details.year) {
                    var merged = details.merged(with: tmdb)
                    // Le titre affiché reste celui de votre catalogue s'il n'y a pas de traduction.
                    if merged.title == nil { merged.title = item.name }
                    details = merged
                }
                errors[item.id] = nil
            } catch {
                errors[item.id] = String(localized: "TMDB n'a pas répondu (vérifiez la clé dans Réglages > Général).")
                PlaybackLog.shared.note("TMDB : échec pour « \(item.name) » : \(error.localizedDescription)")
            }
        }
        // Textes et affiche saisis à la main : ils passent avant tout le reste.
        if let edit {
            if let title = edit.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty { details.title = title }
            if let year = edit.year { details.year = year }
            if let poster = edit.posterURL { details.posterURL = poster }
            if let plot = edit.plot?.trimmingCharacters(in: .whitespacesAndNewlines), !plot.isEmpty { details.plot = plot }
        }
        if details.sources.isEmpty { details.sources = ["IPTV"] }
        cache[item.id] = details
    }

    // MARK: Tendances (bandeau Cinéma)

    @ObservationIgnored private var trendingCache: [Bool: (date: Date, list: [TMDBTrend])] = [:]
    @ObservationIgnored private var titleIndex: [MediaKind: (count: Int, index: [String: MediaItem])] = [:]

    /// Films ou séries en tendance cette semaine (TMDB), mis en cache 6 h.
    func trending(isSeries: Bool) async -> [TMDBTrend] {
        guard usesTMDB else { return [] }
        if let cached = trendingCache[isSeries], Date().timeIntervalSince(cached.date) < 6 * 3600 { return cached.list }
        do {
            let list = try await TMDBClient(apiKey: tmdbKey, language: language).trending(isSeries: isSeries)
            trendingCache[isSeries] = (Date(), list)
            return list
        } catch {
            PlaybackLog.shared.note("TMDB : tendances indisponibles (\(error.localizedDescription))")
            return []
        }
    }

    /// Retrouve les tendances dans votre catalogue (par titre nettoyé, puis titre original).
    func match(_ trends: [TMDBTrend], in items: [MediaItem], kind: MediaKind) async -> [(item: MediaItem, trend: TMDBTrend)] {
        let index: [String: MediaItem]
        if let cached = titleIndex[kind], cached.count == items.count {
            index = cached.index
        } else {
            index = await Task.detached(priority: .utility) { () -> [String: MediaItem] in
                var result: [String: MediaItem] = [:]
                for item in items {
                    let key = TMDB.titleKey(item.name)
                    if !key.isEmpty, result[key] == nil { result[key] = item }
                }
                return result
            }.value
            titleIndex[kind] = (items.count, index)
        }
        var found: [(item: MediaItem, trend: TMDBTrend)] = []
        for trend in trends {
            let keys = [TMDB.titleKey(trend.title)] + (trend.originalTitle.map { [TMDB.titleKey($0)] } ?? [])
            if let item = keys.lazy.compactMap({ index[$0] }).first {
                found.append((item, trend))
            }
        }
        return found
    }

    func reload(_ item: MediaItem, store: LibraryStore) async {
        cache[item.id] = nil
        await load(item, store: store)
    }

    // MARK: Fichiers locaux : fiches TMDB

    /// Corrections faites à la main (« Corriger la fiche… ») : identifiant du contenu → correction.
    private(set) var edits: [String: FicheEdit] = [:]
    @ObservationIgnored private var enriching: Set<UUID> = []
    @ObservationIgnored private var enrichTried: Set<String> = []

    /// Résultats TMDB pour corriger la fiche d'un fichier local.
    func searchTMDB(title: String, isSeries: Bool, year: Int?) async throws -> [TMDBMatch] {
        try await TMDBClient(apiKey: tmdbKey, language: language).search(title: title, isSeries: isSeries, year: year)
    }

    /// Retire une correction sans recharger de fiche (contenu qui n'est plus dans le catalogue).
    func discardEdit(id: String) {
        edits[id] = nil
        FicheEdits.save(edits)
        cache[id] = nil
    }

    /// Relit les corrections (après une importation de configuration).
    func reloadEdits() { edits = FicheEdits.load() }

    /// Vérifie un code ou une adresse TMDB pour ce contenu : fiche trouvée, ou raison du refus.
    func lookup(_ reference: String, for item: MediaItem) async -> (details: MediaDetails?, problem: String?) {
        guard usesTMDB else { return (nil, String(localized: "Ajoutez une clé TMDB (Réglages > Général) pour vérifier un code.")) }
        guard let ref = TMDB.parseReference(reference) else {
            return (nil, String(localized: "Saisissez le numéro TMDB (par exemple 12345) ou collez l'adresse de la page themoviedb.org."))
        }
        let isSeries = item.kind == .series
        if let kind = ref.isSeries, kind != isSeries {
            return (nil, isSeries ? String(localized: "Cette adresse est celle d'un film, pas d'une série.")
                                  : String(localized: "Cette adresse est celle d'une série, pas d'un film."))
        }
        do {
            let client = TMDBClient(apiKey: tmdbKey, language: language)
            guard var found = try await client.details(title: item.name, isSeries: isSeries, tmdbID: ref.id) else {
                return (nil, String(localized: "Aucune fiche TMDB avec ce code."))
            }
            found.tmdbID = ref.id
            return (found, nil)
        } catch {
            return (nil, String(localized: "Aucune fiche TMDB avec ce code (ou TMDB n'a pas répondu)."))
        }
    }

    /// Enregistre (ou, avec nil, retire) la correction d'un contenu, met à jour l'affiche et le résumé, puis recharge la fiche.
    func setEdit(_ item: MediaItem, _ edit: FicheEdit?, store: LibraryStore) async {
        let value = (edit?.isEmpty ?? true) ? nil : edit
        edits[item.id] = value
        FicheEdits.save(edits)
        if store.isLocalFile(item) {
            if let value {
                var fiche = LocalFiche(logo: value.posterURL, info: value.plot, year: value.year, genres: [])
                if let id = value.tmdbID, !id.isEmpty, usesTMDB,
                   let found = try? await TMDBClient(apiKey: tmdbKey, language: language)
                    .details(title: item.name, isSeries: item.kind == .series, tmdbID: id) {
                    fiche.logo = value.posterURL ?? found.posterURL
                    fiche.info = value.plot ?? found.plot
                    fiche.year = value.year ?? found.year
                    fiche.genres = found.genres
                    fiche.rating = found.rating
                    fiche.runtime = found.runtime
                    fiche.country = found.country
                    fiche.language = found.language
                }
                store.applyEnrichment(item.sourceID, [item.id: fiche])
            } else {
                store.clearEnrichment(item.sourceID, ids: [item.id])
                enrichTried.remove(item.id)
            }
        }
        await reload(item, store: store)
        if value == nil, let source = store.source(id: item.sourceID) { enrichLocal(source, store: store) }
    }

    /// Retient la fiche choisie dans la liste de résultats.
    func applyFix(_ item: MediaItem, match: TMDBMatch, store: LibraryStore) async {
        var edit = edits[item.id] ?? FicheEdit()
        edit.tmdbID = match.tmdbID
        await setEdit(item, edit, store: store)
    }

    /// Affiches et résumés TMDB des films et séries d'une source « Dossiers » qui n'en ont pas encore
    /// (300 au plus par passage, 4 recherches à la fois).
    func enrichLocal(_ source: Source, store: LibraryStore) {
        guard usesTMDB, case .folders = source.kind, !enriching.contains(source.id),
              let content = store.content(of: source.id) else { return }
        let personal = String(localized: "Vidéos") + " · "
        let personalAllowed = UserDefaults.standard.object(forKey: "tmdb.personal") as? Bool ?? true
        let todo = content.items.filter {
            ($0.kind == .movie || $0.kind == .series) && ($0.logoURL == nil || $0.rating == nil) && (personalAllowed || !$0.group.hasPrefix(personal))
                && !enrichTried.contains($0.id)
        }.prefix(300)
        guard !todo.isEmpty else { return }
        enriching.insert(source.id)
        let client = TMDBClient(apiKey: tmdbKey, language: language)
        let fixes = edits.compactMapValues(\.tmdbID)
        let items = Array(todo)
        let isPersonalItem: @Sendable (MediaItem) -> Bool = { $0.group.hasPrefix(personal) }
        for item in items { enrichTried.insert(item.id) }
        Task {
            var found: [String: LocalFiche] = [:]
            var index = 0
            while index < items.count {
                let batch = items[index..<min(index + 4, items.count)]
                index += 4
                await withTaskGroup(of: (String, MediaDetails?).self) { group in
                    for item in batch {
                        group.addTask {
                            let cleaned = TMDB.cleanTitle(item.name)
                            var fixed = fixes[item.id]
                            if fixed == nil, isPersonalItem(item) {
                                fixed = (try? await client.exactMatch(name: item.name, isSeries: item.kind == .series))?.tmdbID
                                if fixed == nil { return (item.id, nil) }
                            }
                            let tmdb = try? await client.details(title: cleaned.title, isSeries: item.kind == .series,
                                                                 tmdbID: fixed, year: cleaned.year)
                            return (item.id, tmdb)
                        }
                    }
                    for await (id, tmdb) in group {
                        guard let tmdb, tmdb.posterURL != nil || tmdb.plot != nil else { continue }
                        found[id] = LocalFiche(logo: tmdb.posterURL, info: tmdb.plot, year: tmdb.year, genres: tmdb.genres,
                                               rating: tmdb.rating, runtime: tmdb.runtime, country: tmdb.country, language: tmdb.language)
                    }
                }
                if found.count >= 24 {
                    store.applyEnrichment(source.id, found)
                    found = [:]
                }
            }
            store.applyEnrichment(source.id, found)
            enriching.remove(source.id)
            PlaybackLog.shared.note("Fiches TMDB de « \(source.name) » : \(items.count) titre(s) examiné(s)")
        }
    }
}
