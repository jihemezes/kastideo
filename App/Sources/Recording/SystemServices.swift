import Foundation
import AppKit
import IOKit.pwr_mgt
import UserNotifications

/// Empêche la mise en veille automatique du Mac pendant un enregistrement ou un téléchargement.
@MainActor
enum SleepGuard {
    private static var assertionID: IOPMAssertionID = 0
    private static var active = false

    static func set(_ enabled: Bool) {
        if enabled && !active {
            var id: IOPMAssertionID = 0
            let reason = "Kastideo : enregistrement ou téléchargement en cours" as CFString
            let result = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                                                     IOPMAssertionLevel(kIOPMAssertionLevelOn), reason, &id)
            if result == kIOReturnSuccess {
                assertionID = id
                active = true
            }
        } else if !enabled && active {
            IOPMAssertionRelease(assertionID)
            active = false
        }
    }
}

/// Notifications macOS (fin d'enregistrement, téléchargement terminé…).
@MainActor
enum Notifier {
    private static let delegate = NotificationDelegate()
    private static var requested = false

    static func setup() {
        UNUserNotificationCenter.current().delegate = delegate
    }

    static func requestAuthorization() {
        guard !requested else { return }
        requested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func post(_ title: String, _ body: String) {
        PlaybackLog.shared.note("\(title) — \(body)")
        guard RecordingKeys.notificationsEnabled else { return }
        requestAuthorization()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}

/// Affiche les notifications même quand Kastideo est au premier plan.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

/// Dossier des enregistrements : ~/Movies/Kastideo par défaut, ou dossier choisi par l'utilisateur.
@MainActor
enum RecordingFolder {
    private static var accessed: URL?

    /// Dossier personnel réel (hors conteneur du bac à sable).
    static var realHome: URL {
        if let entry = getpwuid(getuid()), let dir = entry.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir), isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    static var defaultURL: URL {
        realHome.appendingPathComponent("Movies", isDirectory: true).appendingPathComponent("Kastideo", isDirectory: true)
    }

    static var isCustom: Bool { UserDefaults.standard.data(forKey: RecordingKeys.folderBookmark) != nil }

    static var current: URL {
        if let data = UserDefaults.standard.data(forKey: RecordingKeys.folderBookmark) {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope,
                                  relativeTo: nil, bookmarkDataIsStale: &stale) {
                if accessed != url {
                    accessed?.stopAccessingSecurityScopedResource()
                    _ = url.startAccessingSecurityScopedResource()
                    accessed = url
                }
                return url
            }
        }
        return defaultURL
    }

    /// Crée le dossier si besoin et le renvoie.
    static func ensure() throws -> URL {
        let url = current
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func choose(_ url: URL) {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        if let data = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(data, forKey: RecordingKeys.folderBookmark)
            accessed?.stopAccessingSecurityScopedResource()
            accessed = nil
        }
    }

    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: RecordingKeys.folderBookmark)
        accessed?.stopAccessingSecurityScopedResource()
        accessed = nil
    }

    /// Espace libre sur le volume du dossier, en octets.
    static func availableSpace() -> Int64? {
        let url = (try? ensure()) ?? current
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }

    /// Nom du sous-dossier visible qui contient les enregistrements en cours d'écriture.
    static var inProgressName: String { String(localized: "En cours") }

    /// Dossier de travail d'un enregistrement du direct, visible dans le dossier des enregistrements
    /// (« En cours/<nom> ») pour suivre le fichier qui grossit ; dossier temporaire si ce n'est pas possible.
    static func liveDirectory(named name: String) -> URL {
        if let folder = try? ensure() {
            let url = folder.appendingPathComponent(inProgressName, isDirectory: true)
                .appendingPathComponent(name, isDirectory: true)
            if (try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)) != nil {
                return url
            }
        }
        return workDirectory()
    }

    /// Supprime un dossier de travail, ainsi que « En cours » s'il est devenu vide.
    static func removeWorkDirectory(_ url: URL) {
        let manager = FileManager.default
        try? manager.removeItem(at: url)
        let parent = url.deletingLastPathComponent()
        if parent.lastPathComponent == inProgressName,
           let rest = try? manager.contentsOfDirectory(atPath: parent.path),
           rest.allSatisfy({ $0.hasPrefix(".") }) {
            try? manager.removeItem(at: parent)
        }
    }

    /// Dossier de travail temporaire (enregistrement en cours).
    static func workDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("kastideo-rec-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
