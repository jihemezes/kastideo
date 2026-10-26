import Foundation
import AppKit
import Observation
import KastideoCore

/// Position de lecture mémorisée pour un film ou un épisode.
struct WatchEntry: Codable, Hashable {
    var position: TimeInterval
    var duration: TimeInterval
    var updatedAt: Date

    var fraction: Double { duration > 0 ? min(position / duration, 1) : 0 }
}

/// Mémorise où vous en êtes dans chaque film ou épisode, pour reprendre la lecture au même endroit.
@MainActor
@Observable
final class WatchProgressStore {
    private(set) var entries: [String: WatchEntry] = [:]
    /// Contenus vus jusqu'au bout (ou marqués « vus »), pour les pastilles et le partage avec les serveurs.
    private(set) var watched: Set<String> = []
    @ObservationIgnored private var lastSave = Date.distantPast
    @ObservationIgnored private var observer: Any?
    private let key = "watchProgress.v1"
    private let watchedKey = "watched.v1"
    /// En dessous de cette durée (clips, bandes-annonces), la position n'est pas mémorisée.
    private let minimumDuration: TimeInterval = 120
    /// Au-delà de cette fraction, le contenu est considéré comme terminé.
    private let finishedFraction = 0.95
    private let maximumEntries = 500

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: PlaybackKeys.resume) as? Bool ?? true
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: WatchEntry].self, from: data) {
            entries = decoded
        }
        watched = Set(UserDefaults.standard.stringArray(forKey: watchedKey) ?? [])
        observer = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification,
                                                          object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.flush() }
        }
    }

    /// Avancement à afficher (0…1) pour un contenu entamé et non terminé.
    func fraction(for id: String) -> Double? {
        guard let entry = entries[id], entry.position >= 10, entry.fraction < finishedFraction else { return nil }
        return entry.fraction
    }

    /// Position à laquelle reprendre la lecture (secondes), si le contenu est entamé et non terminé.
    func resumePoint(for id: String) -> TimeInterval? {
        guard let entry = entries[id], entry.position >= 30, entry.fraction < finishedFraction else { return nil }
        return entry.position
    }

    func update(id: String, position: TimeInterval, duration: TimeInterval) {
        guard duration >= minimumDuration else { return }
        if position / duration >= finishedFraction {
            entries[id] = nil
            watched.insert(id)
        } else {
            entries[id] = WatchEntry(position: position, duration: duration, updatedAt: Date())
        }
        if Date().timeIntervalSince(lastSave) > 10 { flush() }
    }

    func clear(_ id: String) {
        entries[id] = nil
        flush()
    }

    func clearAll() {
        entries = [:]
        watched = []
        flush()
    }

    func isWatched(_ id: String) -> Bool { watched.contains(id) }

    /// « Marquer comme vu / non vu ».
    func setWatched(_ id: String, _ value: Bool) {
        entries[id] = nil
        if value { watched.insert(id) } else { watched.remove(id) }
        flush()
    }

    /// Positions et contenus vus connus d'un serveur Jellyfin, Emby ou Plex (le serveur fait foi).
    func apply(_ progress: [String: ServerProgress]) {
        guard !progress.isEmpty else { return }
        for (id, state) in progress {
            if state.isPlayed {
                entries[id] = nil
                watched.insert(id)
            } else if state.duration >= minimumDuration, state.position >= 10 {
                // Position locale plus récente (lecture en cours d'envoi) : on la garde.
                if let local = entries[id], Date().timeIntervalSince(local.updatedAt) < 60 { continue }
                entries[id] = WatchEntry(position: state.position, duration: state.duration, updatedAt: Date())
                watched.remove(id)
            }
        }
        flush()
    }

    func flush() {
        if entries.count > maximumEntries {
            let keep = entries.sorted { $0.value.updatedAt > $1.value.updatedAt }.prefix(maximumEntries)
            entries = Dictionary(uniqueKeysWithValues: keep.map { ($0.key, $0.value) })
        }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
        if watched.count > 5000 { watched = Set(watched.prefix(5000)) }
        UserDefaults.standard.set(Array(watched), forKey: watchedKey)
        lastSave = Date()
    }
}
