import SwiftUI
import AppKit
import KastideoCore

/// YouTube dans Kastideo : chaînes suivies, favoris, historique, recherche (clé API de l'utilisateur) et file de lecture.
/// La lecture passe par le lecteur officiel de YouTube en « mode confidentialité avancée » (youtube-nocookie.com).
@MainActor
@Observable
final class YouTubeStore {
    static let shared = YouTubeStore()

    private static let keychainAccount = "youtube.apiKey"
    private static let channelsKey = "youtube.channels.v1"
    private static let favoritesKey = "youtube.favorites.v1"
    private static let historyKey = "youtube.history.v1"
    private static let laterKey = "youtube.later.v1"
    private static let progressKey = "youtube.progress.v1"
    private static let progressLimit = 300
    private static let historyLimit = 80

    private(set) var channels: [YouTubeChannel] = []
    private(set) var favorites: [YouTubeVideo] = []
    private(set) var history: [YouTubeVideo] = []
    /// « À regarder plus tard » : vidéos mises de côté, retirées automatiquement une fois vues jusqu'au bout.
    private(set) var watchLater: [YouTubeVideo] = []
    /// Position de reprise (secondes) et durée, par vidéo.
    private(set) var progress: [String: ProgressPoint] = [:]

    struct ProgressPoint: Codable {
        var t: Double
        var d: Double
        var at: Date
        var fraction: Double { d > 0 ? min(t / d, 1) : 0 }
    }
    /// Dernières vidéos de chaque chaîne suivie (flux RSS), rechargées à l'ouverture.
    private(set) var feeds: [String: [YouTubeVideo]] = [:]
    private(set) var feedErrors: [String: String] = [:]
    private(set) var loadingFeeds = false
    private var lastFeedLoad: Date?

    /// Clé API Google de l'utilisateur (trousseau). Vide : la recherche est indisponible.
    var apiKey: String {
        didSet {
            let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if key.isEmpty { Keychain.delete(account: Self.keychainAccount) } else { Keychain.set(key, account: Self.keychainAccount) }
        }
    }

    // File de lecture en cours.
    private(set) var queue: [YouTubeVideo] = []
    private(set) var startIndex = 0
    private(set) var currentIndex = 0
    private(set) var playerSession = 0
    var isPlaying: Bool { !queue.isEmpty }
    var current: YouTubeVideo? { queue.indices.contains(currentIndex) ? queue[currentIndex] : nil }

    var chain: Bool {
        get { UserDefaults.standard.object(forKey: "youtube.chain") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "youtube.chain") }
    }
    var loop: Bool {
        get { UserDefaults.standard.bool(forKey: "youtube.loop") }
        set { UserDefaults.standard.set(newValue, forKey: "youtube.loop") }
    }
    var muted: Bool {
        get { UserDefaults.standard.bool(forKey: "youtube.muted") }
        set { UserDefaults.standard.set(newValue, forKey: "youtube.muted") }
    }

    private init() {
        apiKey = Keychain.get(account: Self.keychainAccount) ?? ""
        channels = Self.load(Self.channelsKey)
        favorites = Self.load(Self.favoritesKey)
        history = Self.load(Self.historyKey)
        watchLater = Self.load(Self.laterKey)
        if let data = UserDefaults.standard.data(forKey: Self.progressKey),
           let saved = try? JSONDecoder().decode([String: ProgressPoint].self, from: data) { progress = saved }
    }

    private static func load<T: Decodable>(_ key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(try? JSONEncoder().encode(channels), forKey: Self.channelsKey)
        defaults.set(try? JSONEncoder().encode(favorites), forKey: Self.favoritesKey)
        defaults.set(try? JSONEncoder().encode(history), forKey: Self.historyKey)
        defaults.set(try? JSONEncoder().encode(watchLater), forKey: Self.laterKey)
        defaults.set(try? JSONEncoder().encode(progress), forKey: Self.progressKey)
    }

    // MARK: Plus tard et reprise

    func isLater(_ video: YouTubeVideo) -> Bool { watchLater.contains { $0.id == video.id } }

    func toggleLater(_ video: YouTubeVideo) {
        if let i = watchLater.firstIndex(where: { $0.id == video.id }) { watchLater.remove(at: i) } else { watchLater.append(video) }
        save()
    }

    func fraction(of video: YouTubeVideo) -> Double { progress[video.id]?.fraction ?? 0 }

    /// Positions de reprise des vidéos de la file (au moins 10 s déjà vues).
    func resumePoints(for videos: [YouTubeVideo]) -> [String: Double] {
        var out: [String: Double] = [:]
        for video in videos { if let p = progress[video.id], p.t >= 10 { out[video.id] = p.t } }
        return out
    }

    /// Progression remontée par la page de lecture (toutes les 5 s). À 95 %, la vidéo est considérée comme vue :
    /// la reprise est oubliée et la vidéo quitte « À regarder plus tard ».
    func didProgress(index: Int, t: Double, d: Double) {
        guard queue.indices.contains(index), d > 0 else { return }
        let id = queue[index].id
        if t / d >= 0.95 {
            progress[id] = nil
            watchLater.removeAll { $0.id == id }
        } else if t >= 10 {
            progress[id] = ProgressPoint(t: t, d: d, at: Date())
            if progress.count > Self.progressLimit {
                for key in progress.sorted(by: { $0.value.at < $1.value.at }).prefix(progress.count - Self.progressLimit).map(\.key) { progress[key] = nil }
            }
        }
        save()
    }

    // MARK: Import des abonnements

    /// Ajoute les chaînes d'un export Google Takeout (ou d'une liste de liens) ; renvoie le nombre de chaînes ajoutées.
    @discardableResult
    func importSubscriptions(_ text: String) -> Int {
        var added = 0
        for channel in YouTube.parseSubscriptions(text) where !channels.contains(where: { $0.id == channel.id }) {
            channels.append(channel)
            added += 1
        }
        if added > 0 { save(); lastFeedLoad = nil }
        return added
    }

    var client: YouTubeClient { YouTubeClient(apiKey: apiKey) }
    var hasKey: Bool { !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    // MARK: Lecture

    func play(_ videos: [YouTubeVideo], at index: Int = 0) {
        guard !videos.isEmpty else { return }
        queue = videos
        startIndex = max(0, min(index, videos.count - 1))
        currentIndex = startIndex
        playerSession += 1
    }

    func closePlayer() {
        queue = []
        currentIndex = 0
    }

    /// Événement de la page de lecture : une vidéo démarre (historique).
    func didStart(index: Int) {
        guard queue.indices.contains(index) else { return }
        currentIndex = index
        record(queue[index])
    }

    private func record(_ video: YouTubeVideo) {
        history.removeAll { $0.id == video.id }
        history.insert(video, at: 0)
        if history.count > Self.historyLimit { history.removeLast(history.count - Self.historyLimit) }
        save()
    }

    func clearHistory() {
        history = []
        save()
    }

    // MARK: Favoris

    func isFavorite(_ video: YouTubeVideo) -> Bool { favorites.contains { $0.id == video.id } }

    func toggleFavorite(_ video: YouTubeVideo) {
        if let i = favorites.firstIndex(where: { $0.id == video.id }) {
            favorites.remove(at: i)
        } else {
            favorites.insert(video, at: 0)
        }
        save()
    }

    // MARK: Chaînes suivies

    func isFollowing(_ id: String) -> Bool { channels.contains { $0.id == id } }

    func unfollow(_ channel: YouTubeChannel) {
        channels.removeAll { $0.id == channel.id }
        feeds[channel.id] = nil
        save()
    }

    /// Suit une chaîne désignée par son identifiant ou son @pseudo ; renvoie la chaîne ajoutée.
    @discardableResult
    func follow(source: YouTubeSource) async throws -> YouTubeChannel {
        let id: String
        switch source {
        case .channel(let value): id = value
        case .handle(let value): id = try await client.resolveHandle(value)
        default: throw YouTubeError.badAddress
        }
        if let existing = channels.first(where: { $0.id == id }) { return existing }
        let feed = try await client.channelFeed(id)
        let channel = YouTubeChannel(id: id, title: feed.title.isEmpty ? id : feed.title)
        channels.append(channel)
        feeds[id] = feed.videos
        save()
        return channel
    }

    /// Recharge les flux RSS des chaînes suivies (au plus une fois toutes les 5 minutes sauf `force`).
    func refreshFeeds(force: Bool = false) async {
        if !force, let last = lastFeedLoad, Date().timeIntervalSince(last) < 300 { return }
        guard !channels.isEmpty, !loadingFeeds else { return }
        loadingFeeds = true
        defer { loadingFeeds = false; lastFeedLoad = Date() }
        let client = self.client
        // Par lots de 8 : un import peut apporter des centaines de chaînes.
        let all = channels
        for start in stride(from: 0, to: all.count, by: 8) {
            let batch = all[start..<min(start + 8, all.count)]
            await withTaskGroup(of: (String, Result<[YouTubeVideo], Error>).self) { group in
                for channel in batch {
                    group.addTask {
                        do { return (channel.id, .success(try await client.channelFeed(channel.id).videos)) }
                        catch { return (channel.id, .failure(error)) }
                    }
                }
                for await (id, result) in group {
                    switch result {
                    case .success(let videos):
                        feeds[id] = videos
                        feedErrors[id] = nil
                    case .failure(let error):
                        feedErrors[id] = error.localizedDescription
                    }
                }
            }
        }
    }

    /// Libellés de la page de lecture dans la langue de l'application.
    static var playerLabels: YouTube.PlayerLabels {
        YouTube.PlayerLabels(previous: String(localized: "Précédente"), next: String(localized: "Suivante"),
                             chain: String(localized: "Enchaîner"), loop: String(localized: "Boucle"), mute: String(localized: "Muet"),
                             openOnYouTube: String(localized: "Ouvrir sur YouTube"),
                             unavailable: String(localized: "Vidéo indisponible, passage à la suivante…"))
    }
}
