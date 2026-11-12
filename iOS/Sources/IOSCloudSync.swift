import SwiftUI
import CryptoKit
import KastideoCore

// MARK: - Coffre iCloud (trousseau synchronisé)

/// Éléments du trousseau iCloud : chiffrés de bout en bout par Apple, sans capacité iCloud supplémentaire.
/// Exige que le « Trousseau iCloud » soit activé sur chaque appareil (Réglages > [votre nom] > iCloud > Mots de passe et trousseau).
enum CloudVault {
    static let service = "fr.jmezes.kastideo.cloud"

    private static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account,
         kSecAttrSynchronizable as String: kSecAttrSynchronizableAny]
    }

    static func get(_ account: String) -> Data? {
        var request = query(account)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    static func set(_ data: Data, account: String) -> OSStatus {
        let update = SecItemUpdate(query(account) as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if update == errSecSuccess { return update }
        var attributes = query(account)
        attributes[kSecAttrSynchronizable as String] = true
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(attributes as CFDictionary, nil)
    }

    static func delete(_ account: String) {
        SecItemDelete(query(account) as CFDictionary)
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
    static let enabled = "ios.cloud.enabled"
    static let library = "ios.cloud.library"
    static let progress = "ios.cloud.progress"
    static let fiches = "ios.cloud.fiches"
    static let passwords = "ios.cloud.passwords"
    static let lastSync = "ios.cloud.lastSync"
    fileprivate static let stamps = "ios.cloud.stamps"
    fileprivate static let hashes = "ios.cloud.hashes"
    fileprivate static let secretHashes = "ios.cloud.secretHashes"

    /// Réglages d'affichage qui suivent l'utilisateur d'un appareil à l'autre.
    static let displayKeys: [String] = [
        IOSKeys.accent, IOSKeys.cardSize, IOSKeys.density, IOSKeys.startTab,
        IOSKeys.liveMode, IOSKeys.moviesMode, IOSKeys.seriesMode, "ios.appearance",
        IOSHeroKeys.enabled, IOSHeroKeys.categoryMovie, IOSHeroKeys.categorySeries, IOSHeroKeys.useCategory,
        IOSHeroKeys.useRecent, IOSHeroKeys.useTrending, IOSHeroKeys.interval,
        PlaybackKeys.resume, PlaybackKeys.buffering, "catalog.dedupe",
        ReplaySettings.enabledKey, ReplaySettings.guideDaysKey, ReplaySettings.offsetKey, ReplaySettings.returnToLiveKey
    ]
}

// MARK: - Moteur

/// Synchronise sources, favoris, catégories, réglages, reprise de lecture, fiches et mots de passe entre vos appareils.
/// Règle : la modification la plus récente l'emporte. Les changements locaux sont détectés par comparaison
/// d'empreintes (toutes les 30 secondes, au retour dans l'app et à sa mise en arrière-plan).
@MainActor
@Observable
final class IOSCloudSync {
    enum State: Equatable { case idle, syncing, done, problem(String) }

    private(set) var state: State = .idle
    private(set) var lastSync: Date? = UserDefaults.standard.object(forKey: CloudKeys.lastSync) as? Date
    /// Récapitulatif de la dernière synchronisation (ce qui a été reçu).
    private(set) var summary: String?

    private let store: LibraryStore
    private let watch: WatchProgressStore
    private let info: MediaInfoStore
    private let defaults = UserDefaults.standard
    @ObservationIgnored private var running = false

    init(store: LibraryStore, watch: WatchProgressStore, info: MediaInfoStore) {
        self.store = store
        self.watch = watch
        self.info = info
    }

    var isEnabled: Bool { defaults.bool(forKey: CloudKeys.enabled) }

    private func isOn(_ key: String) -> Bool { defaults.object(forKey: key) as? Bool ?? true }

    /// Compte iCloud connecté sur l'appareil.
    var accountAvailable: Bool { FileManager.default.ubiquityIdentityToken != nil }

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
        running = true
        state = .syncing
        var received: [String] = []
        var problem: String?

        if isOn(CloudKeys.library) {
            let outcome = syncDomain(librarySpec(.sources)); if outcome.received { received.append(String(localized: "sources")) }
            problem = problem ?? outcome.problem
            if isOn(CloudKeys.passwords) { syncPasswords() }
            let toRefresh = pendingRefresh
            pendingRefresh = []
            for source in toRefresh { store.refresh(source) }
            for spec in [librarySpec(.favorites), librarySpec(.recents), librarySpec(.categories), librarySpec(.settings)] {
                let result = syncDomain(spec)
                if result.received { received.append(spec.label) }
                problem = problem ?? result.problem
            }
        }
        if isOn(CloudKeys.progress) {
            let result = syncDomain(progressSpec())
            if result.received { received.append(String(localized: "reprise de lecture")) }
            problem = problem ?? result.problem
        }
        if isOn(CloudKeys.fiches) {
            let result = syncDomain(fichesSpec())
            if result.received { received.append(String(localized: "fiches")) }
            problem = problem ?? result.problem
            syncSecret(account: "tmdb.apiKey") { [info] value in info.tmdbKey = value }
        }

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

    /// Efface l'état de synchronisation local (les données iCloud restent) : la prochaine synchronisation fusionne.
    func resetLocalState() {
        defaults.removeObject(forKey: CloudKeys.stamps)
        defaults.removeObject(forKey: CloudKeys.hashes)
        defaults.removeObject(forKey: CloudKeys.secretHashes)
        summary = nil
    }

    /// Supprime les données de ce coffre iCloud (sur tous les appareils) et arrête la synchronisation.
    func eraseCloudData() {
        for name in CloudDomain.allCases { CloudVault.delete("d.\(name.rawValue)") }
        for source in store.sources where source.isCloudSyncable {
            CloudVault.delete("pw.\(source.id.uuidString)")
            CloudVault.delete("pw.session.\(source.id.uuidString)")
        }
        CloudVault.delete("pw.tmdb.apiKey")
        resetLocalState()
        defaults.set(false, forKey: CloudKeys.enabled)
        state = .idle
        lastSync = nil
        defaults.removeObject(forKey: CloudKeys.lastSync)
    }

    // MARK: Domaines

    enum CloudDomain: String, CaseIterable {
        case sources, favorites, recents, categories, settings, progress, fiches
    }

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

    @ObservationIgnored private var pendingRefresh: [Source] = []

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
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
        case .settings:
            return Spec(domain: .settings, label: String(localized: "réglages"),
                        read: { [defaults] in
                            var out: [String: CloudScalar] = [:]
                            for key in CloudKeys.displayKeys {
                                if let value = CloudScalar(defaults.object(forKey: key)) { out[key] = value }
                            }
                            return try? Self.encoder().encode(out)
                        },
                        apply: { [defaults] data in
                            guard let decoded = try? JSONDecoder().decode([String: CloudScalar].self, from: data) else { return }
                            for (key, value) in decoded where CloudKeys.displayKeys.contains(key) {
                                defaults.set(value.object, forKey: key)
                            }
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
                 let decoder = JSONDecoder()
                 if let remote = try? decoder.decode(CloudProgress.self, from: data) { watch.mergeCloud(remote) }
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
        guard let raw = CloudVault.get("d.\(domain.rawValue)"),
              let envelope = try? JSONDecoder().decode(CloudEnvelope.self, from: raw) else { return nil }
        return envelope
    }

    private func inflate(_ data: Data) -> Data? {
        (try? (data as NSData).decompressed(using: .zlib)).map { $0 as Data }
    }

    private func deflate(_ data: Data) -> Data? {
        (try? (data as NSData).compressed(using: .zlib)).map { $0 as Data }
    }

    /// Publie `payload` avec la date `stamp`. Retourne un message en cas d'échec.
    private func push(_ domain: CloudDomain, payload: Data, stamp: Double) -> String? {
        guard payload.count < 700_000, let packed = deflate(payload),
              let raw = try? JSONEncoder().encode(CloudEnvelope(t: stamp, d: packed)) else {
            return String(localized: "Données trop volumineuses pour iCloud (\(domain.rawValue)).")
        }
        let status = CloudVault.set(raw, account: "d.\(domain.rawValue)")
        if status != errSecSuccess {
            return String(localized: "Trousseau iCloud indisponible (erreur \(Int(status))). Activez « Mots de passe et trousseau » dans les réglages iCloud.")
        }
        return nil
    }

    private func syncDomain(_ spec: Spec) -> (received: Bool, problem: String?) {
        let domain = spec.domain
        guard let local = spec.read() else { return (false, nil) }
        let localHash = Self.digest(local)
        let known = hashes()[domain.rawValue]
        var stamp = stamps()[domain.rawValue] ?? 0
        let remote = readRemote(domain)
        let remoteData = remote.flatMap { inflate($0.d) }

        // Première synchronisation de ce domaine sur cet appareil.
        if known == nil {
            guard let remote, let remoteData else {
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
                remember(domain, stamp: remote.t, hash: Self.digest(spec.read() ?? remoteData))
            }
            return (true, nil)
        }

        // Modification locale depuis la dernière synchronisation.
        if known != localHash {
            stamp = Date().timeIntervalSince1970
            remember(domain, stamp: stamp, hash: localHash)
        }

        guard let remote, let remoteData else {
            return (false, push(domain, payload: local, stamp: stamp))
        }

        if remote.t > stamp, Self.digest(remoteData) != localHash {
            spec.apply(remoteData)
            let after = spec.read() ?? remoteData
            let afterHash = Self.digest(after)
            if spec.mergesOnApply, afterHash != Self.digest(remoteData) {
                let now = Date().timeIntervalSince1970
                let problem = push(domain, payload: after, stamp: now)
                remember(domain, stamp: now, hash: afterHash)
                return (true, problem)
            }
            remember(domain, stamp: remote.t, hash: afterHash)
            return (true, nil)
        }
        if stamp > remote.t {
            return (false, push(domain, payload: local, stamp: stamp))
        }
        return (false, nil)
    }

    // MARK: Mots de passe

    private func secretHashes() -> [String: String] { defaults.dictionary(forKey: CloudKeys.secretHashes) as? [String: String] ?? [:] }

    private func setSecretHash(_ account: String, _ value: String?) {
        var all = secretHashes()
        all[account] = value
        defaults.set(all, forKey: CloudKeys.secretHashes)
    }

    private func syncPasswords() {
        for source in store.sources where source.isCloudSyncable {
            let id = source.id.uuidString
            syncSecret(account: id) { value in Keychain.set(value, account: id) }
            if case .mediaServer = source.kind {
                syncSecret(account: "session.\(id)") { value in Keychain.set(value, account: "session.\(id)") }
            }
        }
    }

    /// Un secret du trousseau local ↔ le coffre iCloud. Modifié ici : publié ; modifié ailleurs : reçu ; supprimé ici : supprimé là-bas.
    private func syncSecret(account: String, pull: (String) -> Void) {
        let local = Keychain.get(account: account).flatMap { $0.isEmpty ? nil : $0 }
        let remote = CloudVault.get("pw.\(account)").flatMap { String(data: $0, encoding: .utf8) }
        let last = secretHashes()[account]
        func digest(_ s: String) -> String { Self.digest(Data(s.utf8)) }

        switch (local, remote) {
        case (nil, nil):
            setSecretHash(account, nil)
        case (let l?, nil):
            CloudVault.set(Data(l.utf8), account: "pw.\(account)")
            setSecretHash(account, digest(l))
        case (nil, let r?):
            if let last, last == digest(r) {
                // Supprimé sur cet appareil depuis la dernière synchronisation.
                CloudVault.delete("pw.\(account)")
                setSecretHash(account, nil)
            } else {
                pull(r)
                setSecretHash(account, digest(r))
            }
        case (let l?, let r?):
            if l == r {
                setSecretHash(account, digest(l))
            } else if last != digest(l) {
                CloudVault.set(Data(l.utf8), account: "pw.\(account)")
                setSecretHash(account, digest(l))
            } else {
                pull(r)
                setSecretHash(account, digest(r))
            }
        }
    }
}

// MARK: - Réglages > iCloud

struct IOSCloudSettingsSection: View {
    @Environment(IOSCloudSync.self) private var cloud
    @AppStorage(CloudKeys.enabled) private var enabled = false
    @AppStorage(CloudKeys.library) private var library = true
    @AppStorage(CloudKeys.progress) private var progress = true
    @AppStorage(CloudKeys.fiches) private var fiches = true
    @AppStorage(CloudKeys.passwords) private var passwords = true
    @State private var confirmErase = false

    var body: some View {
        Section {
            Toggle("Synchroniser avec iCloud", isOn: $enabled)
                .onChange(of: enabled) { _, on in
                    if on { Task { await cloud.syncNow() } }
                }
            if enabled {
                Toggle("Sources, favoris, catégories et réglages", isOn: $library)
                Toggle("Reprise de lecture", isOn: $progress)
                Toggle("Fiches corrigées et clé TMDB", isOn: $fiches)
                Toggle("Mots de passe des sources", isOn: $passwords)
                    .disabled(!library)
                Button {
                    Task { await cloud.syncNow() }
                } label: {
                    HStack {
                        Label("Synchroniser maintenant", systemImage: "arrow.triangle.2.circlepath.icloud")
                        if cloud.state == .syncing { Spacer(); ProgressView() }
                    }
                }
                .disabled(cloud.state == .syncing)
                LabeledContent("Dernière synchronisation") {
                    if let date = cloud.lastSync {
                        Text(date, format: .relative(presentation: .named))
                    } else {
                        Text("Jamais")
                    }
                }
                if case .problem(let message) = cloud.state {
                    Label(message, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange)
                } else if let summary = cloud.summary {
                    Text(summary).font(.caption).foregroundStyle(.secondary)
                }
                if !cloud.accountAvailable {
                    Label("Aucun compte iCloud n'est connecté sur cet appareil.", systemImage: "icloud.slash")
                        .font(.caption).foregroundStyle(.orange)
                }
                Button("Effacer les données iCloud de Kastideo", role: .destructive) { confirmErase = true }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("Retrouvez vos sources, favoris et la reprise de lecture sur tous vos iPhone et iPad. Les données passent par le Trousseau iCloud (chiffré de bout en bout) : il doit être activé dans Réglages > [votre nom] > iCloud. La modification la plus récente l'emporte. Dossiers, fichiers locaux et galerie restent propres à chaque appareil.")
        }
        .confirmationDialog("Effacer les données iCloud de Kastideo ?", isPresented: $confirmErase, titleVisibility: .visible) {
            Button("Effacer et arrêter la synchronisation", role: .destructive) { cloud.eraseCloudData() }
        } message: {
            Text("Les données de cet appareil sont conservées ; celles stockées dans iCloud sont supprimées pour tous vos appareils.")
        }
    }
}
