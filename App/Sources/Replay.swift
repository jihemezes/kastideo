import Foundation
import KastideoCore

/// Réglages du replay (archive du fournisseur, jusqu'à 14 jours selon l'abonnement).
enum ReplaySettings {
    static let enabledKey = "replay.enabled"
    static let guideDaysKey = "replay.guideDays"
    static let offsetKey = "replay.offsetMinutes"
    static let returnToLiveKey = "replay.returnToLive"

    static var enabled: Bool { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
    /// Jours de programmes passés gardés dans le guide pour les chaînes à replay (1 à 14).
    static var guideDays: Int { min(max(UserDefaults.standard.object(forKey: guideDaysKey) as? Int ?? 3, 1), 14) }
    /// Correction manuelle de l'heure écrite dans l'adresse du replay (minutes, négatif ou positif).
    static var offsetMinutes: Int { UserDefaults.standard.integer(forKey: offsetKey) }
    static var returnToLive: Bool { UserDefaults.standard.object(forKey: returnToLiveKey) as? Bool ?? true }
}

/// Un replay ouvert : l'élément lu et la chaîne d'origine (pour revenir au direct).
struct ReplayEntry {
    var item: MediaItem
    var channel: MediaItem
}

extension LibraryStore {
    /// Jours de replay de la chaîne (0 si aucun, ou si la fonction est désactivée).
    func replayDays(of channel: MediaItem) -> Int {
        guard ReplaySettings.enabled, channel.kind == .live else { return 0 }
        return channel.archiveDays ?? 0
    }

    /// Ce programme peut-il être revu ? Déjà commencé, et assez récent pour l'archive de la chaîne.
    func canReplay(_ channel: MediaItem, programme: Programme, now: Date = Date()) -> Bool {
        let days = replayDays(of: channel)
        guard days > 0, programme.start <= now else { return false }
        return programme.start >= now.addingTimeInterval(-Double(days) * 86400 + 600)
    }

    /// Élément lisible pour revoir un programme depuis l'archive du fournisseur.
    func makeReplay(channel: MediaItem, programme: Programme) -> MediaItem? {
        guard let live = channel.streamURL,
              let url = ReplayURL.make(live: live, start: programme.start, end: programme.stop,
                                       clock: contents[channel.sourceID]?.serverClock,
                                       extraOffsetMinutes: ReplaySettings.offsetMinutes) else { return nil }
        let id = "\(ReplayURL.idPrefix)\(channel.id)|\(Int(programme.start.timeIntervalSince1970))"
        let item = MediaItem(id: id, sourceID: channel.sourceID, kind: .movie,
                             name: "\(programme.title) — \(channel.name)", group: channel.name,
                             logoURL: channel.logoURL, streamURL: url, epgID: channel.epgID,
                             info: programme.desc)
        replays[id] = ReplayEntry(item: item, channel: channel)
        PlaybackLog.shared.note("Replay « \(programme.title) » sur \(channel.name) : début \(programme.start.formatted(date: .abbreviated, time: .shortened)), "
                                + "décalage manuel \(ReplaySettings.offsetMinutes) min, horloge serveur : "
                                + (contents[channel.sourceID]?.serverClock.map { "\($0.timezone ?? "?") / \($0.offset.map { "\($0 / 60) min" } ?? "?")" } ?? "inconnue"),
                                topic: .playback, detail: .detailed)
        return item
    }

    /// Programmes que l'on peut revoir (le plus récent d'abord), y compris celui en cours.
    func replayProgrammes(of channel: MediaItem, limit: Int = 14, now: Date = Date()) -> [Programme] {
        guard replayDays(of: channel) > 0 else { return [] }
        return Array(epg.programmes(for: channel.epgID).reversed()
            .filter { canReplay(channel, programme: $0, now: now) }.prefix(limit))
    }

    func replayItem(id: String) -> MediaItem? { replays[id]?.item }
    func replayChannel(of item: MediaItem) -> MediaItem? { replays[item.id]?.channel }
}
