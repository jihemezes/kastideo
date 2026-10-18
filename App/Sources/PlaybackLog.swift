import Foundation
import VLCKitSPM

/// Journal des messages du moteur VLC (300 dernières lignes), avec identifiants masqués.
/// Sert au diagnostic : menu Lecture > Journal de lecture.
final class PlaybackLog: NSObject, VLCLogging {
    struct Line: Identifiable, Hashable {
        let id: Int
        let date: Date
        let level: Int
        let text: String

        var levelLabel: String {
            switch level {
            case 0: return "ERREUR"
            case 1: return "ALERTE"
            case 2: return "info"
            default: return "debug"
            }
        }
    }

    static let shared = PlaybackLog()

    /// Niveau « info » : erreurs, alertes et informations.
    var level: VLCLogLevel = VLCLogLevel(rawValue: 2)!

    private let lock = NSLock()
    private var lines: [Line] = []
    private var counter = 0
    private let capacity = 300

    func handleMessage(_ message: String, logLevel level: VLCLogLevel, context: VLCLogContext?) {
        var text = Self.redact(message)
        if let module = context?.module, !module.isEmpty { text = "[\(module)] " + text }
        lock.lock()
        counter += 1
        lines.append(Line(id: counter, date: Date(), level: Int(level.rawValue), text: text))
        if lines.count > capacity { lines.removeFirst(lines.count - capacity) }
        lock.unlock()
    }

    /// Ajoute une ligne de Kastideo lui-même (ouverture d'un flux, délai dépassé…).
    func note(_ message: String) {
        lock.lock()
        counter += 1
        lines.append(Line(id: counter, date: Date(), level: 2, text: "[kastideo] " + Self.redact(message)))
        if lines.count > capacity { lines.removeFirst(lines.count - capacity) }
        lock.unlock()
    }

    func snapshot() -> [Line] {
        lock.lock(); defer { lock.unlock() }
        return lines
    }

    /// Dernière erreur VLC depuis une date donnée (pour l'afficher à l'utilisateur).
    func lastError(since date: Date) -> String? {
        snapshot().last { $0.level == 0 && $0.date >= date }?.text
    }

    func clear() {
        lock.lock(); lines.removeAll(); lock.unlock()
    }

    func exportText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        var text = "Kastideo \(version) — journal de lecture (identifiants masqués)\n"
        for line in snapshot() {
            text += "\(formatter.string(from: line.date)) \(line.levelLabel) \(line.text)\n"
        }
        return text
    }

    /// Masque identifiant et mot de passe dans les adresses Xtream et les paramètres d'URL.
    static func redact(_ text: String) -> String {
        var result = text
        let patterns: [(String, String)] = [
            (#"/(live|movie|series)/[^/\s]+/[^/\s]+/"#, "/$1/***/***/"),
            (#"(username|password)=[^&\s"]+"#, "$1=***"),
            (#"://[^/\s:@]+:[^/\s@]+@"#, "://***:***@")
        ]
        for (pattern, template) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: template)
            }
        }
        return result
    }
}
