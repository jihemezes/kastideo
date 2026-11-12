import SwiftUI
import CryptoKit
import CommonCrypto
import KastideoCore

// MARK: - Dossier iCloud Drive

/// Dossier d'iCloud Drive choisi une fois par l'utilisateur : les fichiers de synchronisation y sont écrits et relus.
/// Fonctionne sans capacité iCloud ni profil de provisionnement (accès par signet de sécurité), sur iPhone, iPad et Mac.
enum CloudFolder {
    static let bookmarkKey = "cloud.folder.bookmark"
    static let nameKey = "cloud.folder.name"

    static var name: String? { UserDefaults.standard.string(forKey: nameKey) }
    static var isChosen: Bool { UserDefaults.standard.data(forKey: bookmarkKey) != nil }

    #if os(macOS)
    private static let creation: URL.BookmarkCreationOptions = [.withSecurityScope]
    private static let resolution: URL.BookmarkResolutionOptions = [.withSecurityScope]
    #else
    private static let creation: URL.BookmarkCreationOptions = []
    private static let resolution: URL.BookmarkResolutionOptions = []
    #endif

    /// Mémorise le dossier choisi (URL fournie par le sélecteur de dossiers).
    @discardableResult
    static func choose(_ url: URL) -> Bool {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? url.bookmarkData(options: creation, includingResourceValuesForKeys: nil, relativeTo: nil) else { return false }
        UserDefaults.standard.set(data, forKey: bookmarkKey)
        UserDefaults.standard.set(url.lastPathComponent, forKey: nameKey)
        return true
    }

    static func forget() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
    }

    static func resolve() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: resolution, relativeTo: nil, bookmarkDataIsStale: &stale) else { return nil }
        if stale { choose(url) }
        return url
    }

    static func file(_ name: String, in folder: URL) -> URL { folder.appendingPathComponent(name) }

    /// Lit les fichiers demandés (hors thread principal : un fichier iCloud peut devoir être téléchargé d'abord).
    static func readAll(_ names: [String], in folder: URL) async -> [String: Data] {
        await Task.detached(priority: .utility) { () -> [String: Data] in
            let scoped = folder.startAccessingSecurityScopedResource()
            defer { if scoped { folder.stopAccessingSecurityScopedResource() } }
            var out: [String: Data] = [:]
            for name in names {
                let url = folder.appendingPathComponent(name)
                try? FileManager.default.startDownloadingUbiquitousItem(at: url)
                var failure: NSError?
                NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: url, options: [], error: &failure) { readable in
                    if let data = try? Data(contentsOf: readable) { out[name] = data }
                }
            }
            return out
        }.value
    }

    /// Écrit (données) ou supprime (`nil`) des fichiers. Retourne un message en cas d'échec.
    static func writeAll(_ files: [String: Data?], in folder: URL) async -> String? {
        await Task.detached(priority: .utility) { () -> String? in
            let scoped = folder.startAccessingSecurityScopedResource()
            defer { if scoped { folder.stopAccessingSecurityScopedResource() } }
            var problem: String?
            for (name, data) in files {
                let url = folder.appendingPathComponent(name)
                var failure: NSError?
                NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forReplacing, error: &failure) { writable in
                    do {
                        if let data { try data.write(to: writable, options: .atomic) }
                        else if FileManager.default.fileExists(atPath: writable.path) { try FileManager.default.removeItem(at: writable) }
                    } catch {
                        problem = error.localizedDescription
                    }
                }
                if let failure { problem = failure.localizedDescription }
            }
            return problem
        }.value
    }
}

// MARK: - Chiffrement des secrets

/// Les mots de passe sont chiffrés (AES-GCM) avec une phrase secrète que vous saisissez sur chaque appareil ;
/// le dossier iCloud Drive ne contient jamais de mot de passe en clair.
enum CloudCrypto {
    private static let magic = Data("KSC1".utf8)

    static func derive(_ passphrase: String, salt: Data) -> SymmetricKey? {
        var derived = [UInt8](repeating: 0, count: 32)
        let saltBytes = [UInt8](salt)
        let status = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passphrase, passphrase.utf8.count,
                                          saltBytes, saltBytes.count,
                                          CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), 120_000,
                                          &derived, derived.count)
        return status == Int32(kCCSuccess) ? SymmetricKey(data: Data(derived)) : nil
    }

    static func seal(_ plain: Data, key: SymmetricKey, salt: Data) -> Data? {
        guard let box = try? AES.GCM.seal(plain, using: key), let combined = box.combined else { return nil }
        return magic + salt + combined
    }

    static func salt(of file: Data) -> Data? {
        guard file.count > 20, file.prefix(4) == magic else { return nil }
        return file.subdata(in: 4..<20)
    }

    static func open(_ file: Data, key: SymmetricKey) -> Data? {
        guard file.count > 20 + 28, file.prefix(4) == magic,
              let box = try? AES.GCM.SealedBox(combined: Data(file.suffix(from: 20))) else { return nil }
        return try? AES.GCM.open(box, using: key)
    }
}

/// Enveloppe d'une donnée échangée : date de dernière modification + contenu compressé.
private struct CloudEnvelope: Codable {
    var t: Double
    var d: Data
}

// MARK: - Données échangées

/// Réglages d'affichage échangés (valeurs simples).
private enum CloudScalar: Codable, Equatable {
    case bool(Bool), int(Int), double(Double), string(String)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(Int.self) { self = .int(v) }
        else if let v = try? c.decode(Double.self) { self = .double(v) }
        else { self = .string(try c.decode(String.self)) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .bool(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        }
    }

    init?(_ object: Any?) {
        guard let object else { return nil }
        if let number = object as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() { self = .bool(number.boolValue) }
            else if CFNumberIsFloatType(number as CFNumber) { self = .double(number.doubleValue) }
            else { self = .int(number.intValue) }
        } else if let string = object as? String {
            self = .string(string)
        } else {
            return nil
        }
    }

    var object: Any {
        switch self {
        case .bool(let v): return v
        case .int(let v): return v
        case .double(let v): return v
        case .string(let v): return v
        }
    }
}

/// Préférences de catégories sous forme stable (tableaux triés) pour détecter les vrais changements.
private struct CloudCategoryPrefs: Codable {
    var order: [String]
    var hidden: [String]
    var renames: [String: String]
    var keywords: [String]
    var itemOrder: [String: [String]]?

    init(_ prefs: CategoryPrefs) {
        order = prefs.order
        hidden = prefs.hidden.sorted()
        renames = prefs.renames
        keywords = prefs.keywords
        itemOrder = prefs.itemOrder
    }

    var prefs: CategoryPrefs {
        var value = CategoryPrefs()
        value.order = order
        value.hidden = Set(hidden)
        value.renames = renames
        value.keywords = keywords
        value.itemOrder = itemOrder
        return value
    }
}

// MARK: - Réglages

enum CloudKeys {
    static let enabled = "cloud.enabled"
    static let library = "cloud.library"
    static let progress = "cloud.progress"
    static let fiches = "cloud.fiches"
    static let passwords = "cloud.passwords"
    static let lastSync = "cloud.lastSync"
    static let passphraseAccount = "cloud.passphrase"
    fileprivate static let stamps = "cloud.stamps"
    fileprivate static let hashes = "cloud.hashes"
    fileprivate static let secretHashes = "cloud.secretHashes"

    /// Réglages communs à toutes les plateformes Apple.
    static let commonKeys: [String] = [
        "hero.enabled", "hero.category.movie", "hero.category.series", "hero.useCategory",
        "hero.useRecent", "hero.useTrending", "hero.interval",
        PlaybackKeys.resume, PlaybackKeys.buffering, "catalog.dedupe",
        CountryKeys.codes, CountryKeys.neutral,
        ReplaySettings.enabledKey, ReplaySettings.guideDaysKey, ReplaySettings.offsetKey, ReplaySettings.returnToLiveKey
    ]

    #if os(iOS)
    /// Réglages d'affichage propres à l'iPhone et à l'iPad.
    static let platformKeys: [String] = [
        IOSKeys.accent, IOSKeys.cardSize, IOSKeys.density, IOSKeys.startTab,
        IOSKeys.liveMode, IOSKeys.moviesMode, IOSKeys.seriesMode, "ios.appearance"
    ]
    static let platformName = "ios"
    #else
    /// Réglages d'affichage propres au Mac.
    static let platformKeys: [String] = [
        AppearanceKeys.accent, AppearanceKeys.density, AppearanceKeys.cardSize, SettingsKeys.appearance, HeroKeys.height
    ] + InterfaceScope.allCases.map(\.storageKey)
    static let platformName = "mac"
    #endif
}

// MARK: - Moteur

/// Synchronise sources, favoris, catégories, réglages, reprise de lecture, fiches et mots de passe entre vos appareils
/// (iPhone, iPad, Mac) par un dossier d'iCloud Drive. La modification la plus récente l'emporte. Les changements locaux
/// sont détectés par comparaison d'empreintes (toutes les 30 secondes, au retour dans l'app et à sa mise en arrière-plan).
@MainActor
@Observable
final class CloudSync {
    enum State: Equatable { case idle, syncing, done, problem(String) }

    enum CloudDomain: String, CaseIterable {
        case sources, favorites, recents, categories, settings, display, progress, fiches

        var file: String {
            let base = self == .display ? "display-\(CloudKeys.platformName)" : rawValue
            return "kastideo-sync-\(base).json"
        }
    }

    static let secretsFile = "kastideo-sync-secrets.bin"

    private(set) var state: State = .idle
    private(set) var lastSync: Date? = UserDefaults.standard.object(forKey: CloudKeys.lastSync) as? Date
    /// Récapitulatif de la dernière synchronisation (ce qui a été reçu).
    private(set) var summary: String?

    private let store: LibraryStore
    private let watch: WatchProgressStore
    private let info: MediaInfoStore
    private let defaults = UserDefaults.standard
    @ObservationIgnored private var running = false
    @ObservationIgnored private var remote: [String: Data] = [:]
    @ObservationIgnored private var outbox: [String: Data?] = [:]
    @ObservationIgnored private var pendingRefresh: [Source] = []
    @ObservationIgnored private var secrets: [String: String] = [:]
    @ObservationIgnored private var secretsDirty = false
    @ObservationIgnored private var secretsReady = false
    @ObservationIgnored private var cachedKey: (pass: String, salt: Data, key: SymmetricKey)?

    init(store: LibraryStore, watch: WatchProgressStore, info: MediaInfoStore) {
        self.store = store
        self.watch = watch
        self.info = info
    }

    var isEnabled: Bool { defaults.bool(forKey: CloudKeys.enabled) }
    var folderName: String? { CloudFolder.name }

    private func isOn(_ key: String) -> Bool { defaults.object(forKey: key) as? Bool ?? true }

    var passphrase: String { Keychain.get(account: CloudKeys.passphraseAccount) ?? "" }

    func setPassphrase(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { Keychain.delete(account: CloudKeys.passphraseAccount) }
        else { Keychain.set(trimmed, account: CloudKeys.passphraseAccount) }
        cachedKey = nil
    }

    func chooseFolder(_ url: URL) {
        if CloudFolder.choose(url) {
            resetLocalState()
            if isEnabled { Task { await syncNow() } }
        } else {
            state = .problem(String(localized: "Ce dossier n'est pas accessible."))
        }
    }

    // MARK: Boucle

    /// Tâche de l'app : une synchronisation peu après le lancement, puis toutes les 30 secondes.
    func run() async {
        try? await Task.sleep(for: .seconds(4))
        while !Task.isCancelled {
            if isEnabled { await syncNow() }
            try? await Task.sleep(for: .seconds(30))
        }
    }

    func syncNow() async {
        guard isEnabled, !running else { return }
        guard let folder = CloudFolder.resolve() else {
            state = .problem(String(localized: "Choisissez le dossier d'iCloud Drive qui servira à la synchronisation."))
            return
        }
        running = true
        state = .syncing
        var received: [String] = []
        var problem: String?

        remote = await CloudFolder.readAll(CloudDomain.allCases.map(\.file) + [Self.secretsFile], in: folder)
        outbox = [:]
        pendingRefresh = []

        let useLibrary = isOn(CloudKeys.library)
        let usePasswords = useLibrary && isOn(CloudKeys.passwords)
        let useFiches = isOn(CloudKeys.fiches)

        if usePasswords || useFiches { problem = loadSecrets(required: usePasswords) }

        func exchange(_ spec: Spec) {
            let result = syncDomain(spec)
            if result.received { received.append(spec.label) }
            problem = problem ?? result.problem
        }

        if useLibrary {
            exchange(librarySpec(.sources))
            if usePasswords, secretsReady { syncSourcePasswords() }
            let toRefresh = pendingRefresh
            pendingRefresh = []
            for source in toRefresh { store.refresh(source) }
            for domain in [CloudDomain.favorites, .recents, .categories] { exchange(librarySpec(domain)) }
            exchange(settingsSpec(.settings, keys: CloudKeys.commonKeys))
            exchange(settingsSpec(.display, keys: CloudKeys.platformKeys))
        }
        if isOn(CloudKeys.progress) { exchange(progressSpec()) }
        if useFiches {
            exchange(fichesSpec())
            if secretsReady { syncSecret(account: "tmdb.apiKey") { [info] value in info.tmdbKey = value } }
        }

        if secretsDirty, secretsReady,
           let json = try? Self.encoder().encode(secrets), let sealed = sealSecrets(json) {
            outbox[Self.secretsFile] = .some(sealed)
        }
        secretsDirty = false

        if !outbox.isEmpty, let failure = await CloudFolder.writeAll(outbox, in: folder) {
            problem = problem ?? failure
        }
        outbox = [:]
        remote = [:]
        secrets = [:]

        running = false
        if let problem {
            state = .problem(problem)
        } else {
            state = .done
            lastSync = Date()
            defaults.set(lastSync, forKey: CloudKeys.lastSync)
        }
        if !received.isEmpty {
            summary = String(localized: "Reçu d'un autre appareil : ") + received.joined(separator: ", ")
        }
    }

    /// Oublie l'état de synchronisation local (les fichiers iCloud restent) : la prochaine synchronisation fusionne.
    func resetLocalState() {
        defaults.removeObject(forKey: CloudKeys.stamps)
        defaults.removeObject(forKey: CloudKeys.hashes)
        defaults.removeObject(forKey: CloudKeys.secretHashes)
        summary = nil
    }

    /// Supprime les fichiers de synchronisation du dossier (pour tous les appareils) et arrête la synchronisation.
    func eraseCloudData() async {
        if let folder = CloudFolder.resolve() {
            let removal: Data? = nil
            var files: [String: Data?] = [:]
            files[Self.secretsFile] = removal
            for domain in CloudDomain.allCases { files[domain.file] = removal }
            files["kastideo-sync-display-ios.json"] = removal
            files["kastideo-sync-display-mac.json"] = removal
            _ = await CloudFolder.writeAll(files, in: folder)
        }
        resetLocalState()
        defaults.set(false, forKey: CloudKeys.enabled)
        state = .idle
        lastSync = nil
        defaults.removeObject(forKey: CloudKeys.lastSync)
    }

    // MARK: Domaines

    private struct Spec {
        let domain: CloudDomain
        let label: String
        let read: () -> Data?
        let apply: (Data) -> Void
        /// Premier échange : fusion plutôt que remplacement (listes).
        let merge: ((Data, Data) -> Data?)?
        /// L'application d'un état distant fusionne : on republie le résultat s'il diffère.
        let mergesOnApply: Bool
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private func settingsSpec(_ domain: CloudDomain, keys: [String]) -> Spec {
        Spec(domain: domain, label: String(localized: "réglages"),
             read: { [defaults] in
                 var out: [String: CloudScalar] = [:]
                 for key in keys {
                     if let value = CloudScalar(defaults.object(forKey: key)) { out[key] = value }
                 }
                 return try? Self.encoder().encode(out)
             },
             apply: { [defaults] data in
                 guard let decoded = try? JSONDecoder().decode([String: CloudScalar].self, from: data) else { return }
                 for (key, value) in decoded where keys.contains(key) {
                     defaults.set(value.object, forKey: key)
                 }
             },
             merge: nil, mergesOnApply: false)
    }

    private func librarySpec(_ domain: CloudDomain) -> Spec {
        switch domain {
        case .sources:
            return Spec(domain: .sources, label: String(localized: "sources"),
                        read: { [store] in
                            let list = store.sources.filter(\.isCloudSyncable).map { source -> Source in
                                var copy = source
                                copy.lastRefresh = nil
                                return copy
                            }
                            return try? Self.encoder().encode(list)
                        },
                        apply: { [store, weak self] data in
                            guard let list = try? JSONDecoder().decode([Source].self, from: data) else { return }
                            self?.pendingRefresh += store.applyCloudSources(list)
                        },
                        merge: { local, remote in
                            guard let mine = try? JSONDecoder().decode([Source].self, from: local),
                                  let theirs = try? JSONDecoder().decode([Source].self, from: remote) else { return nil }
                            let extra = mine.filter { m in !theirs.contains { $0.id == m.id } }
                            return try? Self.encoder().encode(theirs + extra)
                        },
                        mergesOnApply: false)
        case .favorites:
            return listSpec(.favorites, label: String(localized: "favoris"),
                            read: { [store] in store.favoriteIDs }, apply: { [store] in store.applyCloudFavorites($0) })
        case .recents:
            return listSpec(.recents, label: String(localized: "historique"),
                            read: { [store] in store.recentIDs }, apply: { [store] in store.applyCloudRecents($0) })
        case .categories:
            return Spec(domain: .categories, label: String(localized: "catégories"),
                        read: { [store] in
                            var out: [String: CloudCategoryPrefs] = [:]
                            for (kind, prefs) in store.categoryPrefs { out[kind.rawValue] = CloudCategoryPrefs(prefs) }
                            return try? Self.encoder().encode(out)
                        },
                        apply: { [store] data in
                            guard let decoded = try? JSONDecoder().decode([String: CloudCategoryPrefs].self, from: data) else { return }
                            var out: [MediaKind: CategoryPrefs] = [:]
                            for (raw, value) in decoded { if let kind = MediaKind(rawValue: raw) { out[kind] = value.prefs } }
                            store.applyCloudCategories(out)
                        },
                        merge: nil, mergesOnApply: false)
        default:
            fatalError("Domaine non géré")
        }
    }

    /// Liste ordonnée d'identifiants (favoris, historique) : à la première synchronisation, les deux listes sont réunies.
    private func listSpec(_ domain: CloudDomain, label: String, read: @escaping () -> [String],
                          apply: @escaping ([String]) -> Void) -> Spec {
        Spec(domain: domain, label: label,
             read: { try? Self.encoder().encode(read()) },
             apply: { data in if let list = try? JSONDecoder().decode([String].self, from: data) { apply(list) } },
             merge: { local, remote in
                 guard let mine = try? JSONDecoder().decode([String].self, from: local),
                       let theirs = try? JSONDecoder().decode([String].self, from: remote) else { return nil }
                 var seen = Set<String>()
                 let union = (theirs + mine).filter { seen.insert($0).inserted }
                 return try? Self.encoder().encode(union)
             },
             mergesOnApply: false)
    }

    private func progressSpec() -> Spec {
        Spec(domain: .progress, label: String(localized: "reprise de lecture"),
             read: { [watch] in try? Self.encoder().encode(watch.cloudSnapshot()) },
             apply: { [watch] data in
                 if let remote = try? JSONDecoder().decode(CloudProgress.self, from: data) { watch.mergeCloud(remote) }
             },
             merge: nil, mergesOnApply: true)
    }

    private func fichesSpec() -> Spec {
        Spec(domain: .fiches, label: String(localized: "fiches"),
             read: { try? Self.encoder().encode(FicheEdits.load()) },
             apply: { [info] data in
                 guard let edits = try? JSONDecoder().decode([String: FicheEdit].self, from: data) else { return }
                 FicheEdits.save(edits)
                 info.reloadEdits()
             },
             merge: { local, remote in
                 guard let mine = try? JSONDecoder().decode([String: FicheEdit].self, from: local),
                       let theirs = try? JSONDecoder().decode([String: FicheEdit].self, from: remote) else { return nil }
                 return try? Self.encoder().encode(mine.merging(theirs) { _, remote in remote })
             },
             mergesOnApply: false)
    }

    // MARK: Échange d'un domaine

    private func stamps() -> [String: Double] { defaults.dictionary(forKey: CloudKeys.stamps) as? [String: Double] ?? [:] }
    private func hashes() -> [String: String] { defaults.dictionary(forKey: CloudKeys.hashes) as? [String: String] ?? [:] }

    private func remember(_ domain: CloudDomain, stamp: Double, hash: String) {
        var s = stamps(); s[domain.rawValue] = stamp; defaults.set(s, forKey: CloudKeys.stamps)
        var h = hashes(); h[domain.rawValue] = hash; defaults.set(h, forKey: CloudKeys.hashes)
    }

    private static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func readRemote(_ domain: CloudDomain) -> CloudEnvelope? {
        guard let raw = remote[domain.file], let envelope = try? JSONDecoder().decode(CloudEnvelope.self, from: raw) else { return nil }
        return envelope
    }

    private func inflate(_ data: Data) -> Data? {
        (try? (data as NSData).decompressed(using: .zlib)).map { $0 as Data }
    }

    private func deflate(_ data: Data) -> Data? {
        (try? (data as NSData).compressed(using: .zlib)).map { $0 as Data }
    }

    /// Prépare l'écriture de `payload` avec la date `stamp`. Retourne un message en cas d'échec.
    private func push(_ domain: CloudDomain, payload: Data, stamp: Double) -> String? {
        guard payload.count < 5_000_000, let packed = deflate(payload),
              let raw = try? JSONEncoder().encode(CloudEnvelope(t: stamp, d: packed)) else {
            return String(localized: "Données trop volumineuses pour la synchronisation (\(domain.rawValue)).")
        }
        outbox[domain.file] = .some(raw)
        return nil
    }

    private func syncDomain(_ spec: Spec) -> (received: Bool, problem: String?) {
        let domain = spec.domain
        guard let local = spec.read() else { return (false, nil) }
        let localHash = Self.digest(local)
        let known = hashes()[domain.rawValue]
        var stamp = stamps()[domain.rawValue] ?? 0
        let remoteEnvelope = readRemote(domain)
        let remoteData = remoteEnvelope.flatMap { inflate($0.d) }

        // Première synchronisation de ce domaine sur cet appareil.
        if known == nil {
            guard let remoteEnvelope, let remoteData else {
                let now = Date().timeIntervalSince1970
                if let problem = push(domain, payload: local, stamp: now) { return (false, problem) }
                remember(domain, stamp: now, hash: localHash)
                return (false, nil)
            }
            if let merge = spec.merge, let merged = merge(local, remoteData) {
                spec.apply(merged)
                let after = spec.read() ?? merged
                let now = Date().timeIntervalSince1970
                if let problem = push(domain, payload: after, stamp: now) { return (true, problem) }
                remember(domain, stamp: now, hash: Self.digest(after))
            } else {
                spec.apply(remoteData)
                remember(domain, stamp: remoteEnvelope.t, hash: Self.digest(spec.read() ?? remoteData))
            }
            return (true, nil)
        }

        // Modification locale depuis la dernière synchronisation.
        if known != localHash {
            stamp = Date().timeIntervalSince1970
            remember(domain, stamp: stamp, hash: localHash)
        }

        guard let remoteEnvelope, let remoteData else {
            return (false, push(domain, payload: local, stamp: stamp))
        }

        if remoteEnvelope.t > stamp, Self.digest(remoteData) != localHash {
            spec.apply(remoteData)
            let after = spec.read() ?? remoteData
            let afterHash = Self.digest(after)
            if spec.mergesOnApply, afterHash != Self.digest(remoteData) {
                let now = Date().timeIntervalSince1970
                let problem = push(domain, payload: after, stamp: now)
                remember(domain, stamp: now, hash: afterHash)
                return (true, problem)
            }
            remember(domain, stamp: remoteEnvelope.t, hash: afterHash)
            return (true, nil)
        }
        if stamp > remoteEnvelope.t {
            return (false, push(domain, payload: local, stamp: stamp))
        }
        return (false, nil)
    }

    // MARK: Mots de passe (fichier chiffré)

    private func key(for pass: String, salt: Data) -> SymmetricKey? {
        if let cached = cachedKey, cached.pass == pass, cached.salt == salt { return cached.key }
        guard let derived = CloudCrypto.derive(pass, salt: salt) else { return nil }
        cachedKey = (pass, salt, derived)
        return derived
    }

    /// Charge les secrets du dossier. `required` : un message est retourné si la phrase secrète manque.
    private func loadSecrets(required: Bool) -> String? {
        secretsReady = false
        secrets = [:]
        let pass = passphrase
        if pass.isEmpty {
            return required ? String(localized: "Saisissez une phrase secrète pour synchroniser les mots de passe (la même sur chaque appareil).") : nil
        }
        if let file = remote[Self.secretsFile] {
            guard let salt = CloudCrypto.salt(of: file), let key = key(for: pass, salt: salt),
                  let plain = CloudCrypto.open(file, key: key),
                  let dict = try? JSONDecoder().decode([String: String].self, from: plain) else {
                return String(localized: "Phrase secrète incorrecte : elle doit être la même sur tous vos appareils.")
            }
            secrets = dict
        }
        secretsReady = true
        return nil
    }

    private func sealSecrets(_ plain: Data) -> Data? {
        let pass = passphrase
        guard !pass.isEmpty else { return nil }
        let salt = remote[Self.secretsFile].flatMap { CloudCrypto.salt(of: $0) }
            ?? Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        guard let key = key(for: pass, salt: salt) else { return nil }
        return CloudCrypto.seal(plain, key: key, salt: salt)
    }

    private func secretHashes() -> [String: String] { defaults.dictionary(forKey: CloudKeys.secretHashes) as? [String: String] ?? [:] }

    private func setSecretHash(_ account: String, _ value: String?) {
        var all = secretHashes()
        all[account] = value
        defaults.set(all, forKey: CloudKeys.secretHashes)
    }

    private func syncSourcePasswords() {
        for source in store.sources where source.isCloudSyncable {
            let id = source.id.uuidString
            syncSecret(account: id) { value in Keychain.set(value, account: id) }
            if case .mediaServer = source.kind {
                syncSecret(account: "session.\(id)") { value in Keychain.set(value, account: "session.\(id)") }
            }
        }
    }

    /// Un secret du trousseau local ↔ le fichier chiffré. Modifié ici : publié ; modifié ailleurs : reçu ; supprimé ici : supprimé là-bas.
    private func syncSecret(account: String, pull: (String) -> Void) {
        let local = Keychain.get(account: account).flatMap { $0.isEmpty ? nil : $0 }
        let distant = secrets[account]
        let last = secretHashes()[account]
        func digest(_ s: String) -> String { Self.digest(Data(s.utf8)) }
        func publish(_ value: String) {
            secrets[account] = value
            secretsDirty = true
            setSecretHash(account, digest(value))
        }

        switch (local, distant) {
        case (nil, nil):
            setSecretHash(account, nil)
        case (let l?, nil):
            publish(l)
        case (nil, let r?):
            if let last, last == digest(r) {
                secrets[account] = nil
                secretsDirty = true
                setSecretHash(account, nil)
            } else {
                pull(r)
                setSecretHash(account, digest(r))
            }
        case (let l?, let r?):
            if l == r {
                setSecretHash(account, digest(l))
            } else if last != digest(l) {
                publish(l)
            } else {
                pull(r)
                setSecretHash(account, digest(r))
            }
        }
    }
}
