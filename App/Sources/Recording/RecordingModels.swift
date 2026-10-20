import Foundation
import KastideoCore

/// Réglages liés aux enregistrements et téléchargements.
enum RecordingKeys {
    static let folderBookmark = "recordings.folderBookmark"
    static let marginBefore = "recordings.marginBefore"     // minutes
    static let marginAfter = "recordings.marginAfter"       // minutes
    static let nightHour = "recordings.nightHour"           // heure de début « cette nuit »
    static let convertMP4 = "recordings.convertMP4"
    static let autoClean = "recordings.autoClean"
    static let autoCleanDays = "recordings.autoCleanDays"
    static let notifications = "recordings.notifications"
    static let schedules = "recordings.schedules.v1"
    static let downloads = "recordings.downloads.v1"
    static let batches = "recordings.batches.v1"

    static var marginBeforeMinutes: Int { UserDefaults.standard.object(forKey: marginBefore) as? Int ?? 2 }
    static var marginAfterMinutes: Int { UserDefaults.standard.object(forKey: marginAfter) as? Int ?? 5 }
    static var nightHourValue: Int { UserDefaults.standard.object(forKey: nightHour) as? Int ?? 2 }
    static var convertToMP4: Bool { UserDefaults.standard.object(forKey: convertMP4) as? Bool ?? true }
    static var autoCleanEnabled: Bool { UserDefaults.standard.bool(forKey: autoClean) }
    static var autoCleanDayCount: Int { UserDefaults.standard.object(forKey: autoCleanDays) as? Int ?? 30 }
    static var notificationsEnabled: Bool { UserDefaults.standard.object(forKey: notifications) as? Bool ?? true }
}

/// Enregistrement programmé d'une chaîne en direct (marges incluses).
struct ScheduledRecording: Identifiable, Codable, Hashable {
    var id = UUID()
    var item: MediaItem
    var title: String
    var start: Date
    var end: Date
}

/// Téléchargement d'un film ou d'un épisode.
struct DownloadItem: Identifiable, Codable, Hashable {
    enum State: String, Codable {
        case queued, downloading, paused, failed
    }

    var id = UUID()
    var item: MediaItem
    var fileName: String
    /// Ne pas démarrer avant cette date (téléchargement « cette nuit »).
    var startAfter: Date?
    var state: State = .queued
    /// Mis en pause par l'utilisateur (sinon reprise automatique quand la connexion se libère).
    var pausedByUser = false
    var received: Int64 = 0
    var expected: Int64 = 0
    var error: String?
    /// Lot d'épisodes (saison, série) auquel appartient ce téléchargement.
    var batchID: UUID?

    var progress: Double { expected > 0 ? min(Double(received) / Double(expected), 1) : 0 }
}

/// Lot de téléchargements (épisodes d'une saison ou d'une série), pour suivre l'avancement global.
struct DownloadBatch: Codable, Hashable {
    var title: String
    /// Épisodes déjà terminés.
    var completed = 0
    /// Octets cumulés des épisodes terminés (pour estimer la taille des suivants).
    var bytesDone: Int64 = 0
}

/// Avancement d'une série ou d'une saison en cours de téléchargement.
struct DownloadBatchInfo {
    var title: String
    /// Rang de l'épisode en cours (1, 2, 3…).
    var position: Int
    var total: Int
    /// Avancement global entre 0 et 1.
    var progress: Double
    /// Temps restant estimé pour tout le lot.
    var eta: TimeInterval?
}

/// État affiché par l'indicateur de téléchargement.
struct DownloadStatus {
    var current: DownloadItem
    /// `false` : téléchargement suspendu (lecture en cours), il reprendra tout seul.
    var isActive: Bool
    /// Vitesse lissée en octets par seconde.
    var speed: Double
    /// Temps restant estimé pour le fichier en cours.
    var eta: TimeInterval?
    var batch: DownloadBatchInfo?
    /// Autres téléchargements en attente (hors lot en cours).
    var othersQueued: Int
}

/// Fichier enregistré dans le dossier des enregistrements.
struct RecordingFile: Identifiable, Hashable {
    let url: URL
    let date: Date
    let size: Int64

    var id: String { "file:" + url.path }
    var name: String { url.deletingPathExtension().lastPathComponent }

    /// Source fictive des fichiers locaux.
    static let localSource = UUID(uuidString: "00000000-0000-0000-0000-00000000F11E")!

    var mediaItem: MediaItem {
        MediaItem(id: id, sourceID: Self.localSource, kind: .movie, name: name,
                  group: "Enregistrements", streamURL: url)
    }

    static let extensions: Set<String> = ["mp4", "ts", "mkv", "avi", "mov", "m4v", "webm"]
}

/// Noms de fichiers lisibles et sans caractères interdits.
enum FileNaming {
    static func sanitize(_ text: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>").union(.newlines).union(.controlCharacters)
        var result = text.components(separatedBy: forbidden).joined(separator: "-")
        result = result.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ".-")))
        if result.count > 120 { result = String(result.prefix(120)) }
        return result.isEmpty ? "Kastideo" : result
    }

    static func liveName(channel: String, title: String, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "yyyy-MM-dd HH'h'mm"
        let cleanTitle = sanitize(title)
        let cleanChannel = sanitize(channel)
        if cleanTitle == cleanChannel { return "\(cleanChannel) – \(formatter.string(from: date))" }
        return "\(cleanChannel) – \(cleanTitle) – \(formatter.string(from: date))"
    }

    static func mediaName(_ item: MediaItem) -> String {
        if item.kind == .episode {
            let number = item.number.map { String(format: "E%02d ", $0) } ?? ""
            return "\(sanitize(item.group)) – \(number)\(sanitize(item.name))"
        }
        return sanitize(item.name)
    }

    /// Ajoute « (2) », « (3) »… si le fichier existe déjà.
    static func unique(_ url: URL) -> URL {
        let manager = FileManager.default
        guard manager.fileExists(atPath: url.path) else { return url }
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let folder = url.deletingLastPathComponent()
        var index = 2
        while true {
            let candidate = folder.appendingPathComponent("\(base) (\(index))").appendingPathExtension(ext)
            if !manager.fileExists(atPath: candidate.path) { return candidate }
            index += 1
        }
    }
}
