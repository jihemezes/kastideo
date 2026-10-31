import Foundation
import VLCKitSPM

/// Sujet d'une ligne du journal : permet de ne lire que ce qui concerne le problème étudié.
enum LogTopic: String, CaseIterable, Identifiable, Sendable {
    case guide, playback, sources, recording, tmdb, updates, app

    var id: String { rawValue }

    var title: String {
        switch self {
        case .guide: return String(localized: "Guide TV")
        case .playback: return String(localized: "Lecture et relais")
        case .sources: return String(localized: "Sources et catalogues")
        case .recording: return String(localized: "Enregistrements")
        case .tmdb: return String(localized: "Fiches TMDB")
        case .updates: return String(localized: "Mises à jour")
        case .app: return String(localized: "Affichage et divers")
        }
    }

    /// Détail conservé par défaut : le guide est détaillé tant qu'on cherche à comprendre ses échecs.
    var defaultDetail: LogDetail { self == .guide ? .detailed : .normal }

    /// Déduit le sujet d'un ancien message à partir de son début (les messages récents passent leur sujet).
    static func infer(_ text: String) -> LogTopic {
        let t = text.lowercased()
        func starts(_ list: [String]) -> Bool { list.contains { t.hasPrefix($0) } }
        if starts(["guide"]) { return .guide }
        if starts(["enregistrement", "conversion", "téléchargement", "dossier d'enregistrement"]) { return .recording }
        if starts(["tmdb", "fiche"]) { return .tmdb }
        if starts(["mise à jour", "sparkle"]) { return .updates }
        if starts(["source", "serveur", "catalogue"]) { return .sources }
        if starts(["relais", "ouverture", "état", "son ", "son :", "lecture", "différé", "vitesse", "horloge", "flux",
                   "attente", "arrêt du moteur", "chaîne refusée", "qualité", "image seule", "sous-titres",
                   "multivue", "aucune image"]) { return .playback }
        return .app
    }
}

/// Niveau de détail d'un sujet : « Normal » ne garde que l'essentiel, « Débogage » garde tout.
enum LogDetail: Int, CaseIterable, Identifiable, Sendable {
    case normal = 0, detailed = 1, debug = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .normal: return String(localized: "Normal")
        case .detailed: return String(localized: "Détaillé")
        case .debug: return String(localized: "Débogage")
        }
    }
}

/// Journal de Kastideo : messages du moteur VLC et de l'application, classés par sujet, avec identifiants masqués.
/// Les 3 000 dernières lignes restent en mémoire ; le journal est aussi écrit sur disque (session en cours et précédente).
/// Sert au diagnostic : menu Lecture > Journal de lecture.
final class PlaybackLog: NSObject, VLCLogging {
    struct Line: Identifiable, Hashable {
        let id: Int
        let date: Date
        let level: Int
        let topic: LogTopic
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
    private let capacity = 3000

    // MARK: - Niveau de détail par sujet

    static func detail(for topic: LogTopic) -> LogDetail {
        let raw = UserDefaults.standard.object(forKey: "log.detail.\(topic.rawValue)") as? Int
        return raw.flatMap(LogDetail.init(rawValue:)) ?? topic.defaultDetail
    }

    static func setDetail(_ detail: LogDetail, for topic: LogTopic) {
        UserDefaults.standard.set(detail.rawValue, forKey: "log.detail.\(topic.rawValue)")
    }

    // MARK: - Journal sur disque

    private let writer = DispatchQueue(label: "fr.jmezes.kastideo.log", qos: .utility)
    private var handle: FileHandle?
    private var writtenBytes = 0
    private static let maxFileBytes = 5_000_000

    static var logsDirectory: URL {
        let dir = Storage.directory.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static var currentFile: URL { logsDirectory.appendingPathComponent("journal.log") }
    static var previousFile: URL { logsDirectory.appendingPathComponent("journal-precedent.log") }

    private static let fileDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    override init() {
        super.init()
        // La session qui vient de se terminer devient « précédente » (utile pour les problèmes de démarrage).
        let fm = FileManager.default
        if fm.fileExists(atPath: Self.currentFile.path) {
            try? fm.removeItem(at: Self.previousFile)
            try? fm.moveItem(at: Self.currentFile, to: Self.previousFile)
        }
        fm.createFile(atPath: Self.currentFile.path, contents: nil)
        handle = try? FileHandle(forWritingTo: Self.currentFile)
    }

    /// Une ligne par message : date, niveau, sujet, texte (tabulations et retours remplacés).
    private func persist(_ line: Line) {
        let flat = line.text.replacingOccurrences(of: "\t", with: " ").replacingOccurrences(of: "\n", with: " ⏎ ")
        let record = "\(Self.fileDate.string(from: line.date))\t\(line.level)\t\(line.topic.rawValue)\t\(flat)\n"
        writer.async { [self] in
            guard let data = record.data(using: .utf8), writtenBytes < Self.maxFileBytes else { return }
            writtenBytes += data.count
            try? handle?.write(contentsOf: data)
        }
    }

    /// Lit le journal de la session précédente.
    static func previousSession() -> [Line] {
        guard let text = try? String(contentsOf: previousFile, encoding: .utf8) else { return [] }
        var result: [Line] = []
        for (index, row) in text.split(separator: "\n", omittingEmptySubsequences: true).enumerated() {
            let parts = row.split(separator: "\t", maxSplits: 3, omittingEmptySubsequences: false)
            guard parts.count == 4, let date = fileDate.date(from: String(parts[0])),
                  let level = Int(parts[1]), let topic = LogTopic(rawValue: String(parts[2])) else { continue }
            result.append(Line(id: -(index + 1), date: date, level: level, topic: topic, text: String(parts[3])))
        }
        return result
    }

    /// Alertes d'horloge du flux (« buffer too late », « clock gap », « picture is too late »), depuis le lancement.
    private var clockAlerts = 0
    private var clockLogged = Date.distantPast
    private var clockSinceLog = 0

    /// Nombre total d'alertes d'horloge (lu par la surveillance du son et de l'image).
    func clockProblems() -> Int {
        lock.lock(); defer { lock.unlock() }
        return clockAlerts
    }

    static let clockMessages = ["buffer too late", "clock gap", "picture is too late", "feeding synchro"]

    func handleMessage(_ message: String, logLevel level: VLCLogLevel, context: VLCLogContext?) {
        // Ces alertes arrivent des dizaines de fois par seconde quand l'horloge du flux est incohérente :
        // on les compte et on n'en écrit qu'une ligne toutes les 5 s (sinon le journal ne contient plus que ça).
        if Self.clockMessages.contains(where: { message.hasPrefix($0) }) {
            lock.lock()
            if !message.hasPrefix("feeding synchro") { clockAlerts += 1 }
            clockSinceLog += 1
            let now = Date()
            guard now.timeIntervalSince(clockLogged) >= 5 else { lock.unlock(); return }
            let count = clockSinceLog
            clockSinceLog = 0
            clockLogged = now
            counter += 1
            let line = Line(id: counter, date: now, level: 1, topic: .playback,
                            text: "[libvlc] horloge du flux incohérente : \(count) alerte(s) depuis 5 s (dernière : \(message))")
            lines.append(line)
            if lines.count > capacity { lines.removeFirst(lines.count - capacity) }
            lock.unlock()
            persist(line)
            return
        }
        if level.rawValue >= 3 {
            // Niveau « débogage » (pendant une diffusion) : seuls les échanges avec le téléviseur sont gardés.
            let probe = ((context?.module ?? "") + " " + message).lowercased()
            guard probe.contains("chromecast") || probe.contains("sout") || probe.contains("httpd") || probe.contains("cast") else { return }
        }
        var text = Self.redact(message)
        if let module = context?.module, !module.isEmpty { text = "[\(module)] " + text }
        lock.lock()
        counter += 1
        let line = Line(id: counter, date: Date(), level: Int(level.rawValue), topic: .playback, text: text)
        lines.append(line)
        if lines.count > capacity { lines.removeFirst(lines.count - capacity) }
        lock.unlock()
        persist(line)
    }

    /// Ajoute une ligne de Kastideo lui-même (ouverture d'un flux, délai dépassé…).
    /// Sans sujet précisé, il est déduit du début du message. Les lignes plus détaillées que le réglage du sujet
    /// sont ignorées ; erreurs (0) et alertes (1) sont toujours gardées.
    func note(_ message: String, topic: LogTopic? = nil, detail: LogDetail = .normal, level: Int = 2) {
        let topic = topic ?? LogTopic.infer(message)
        if level >= 2, detail.rawValue > Self.detail(for: topic).rawValue { return }
        lock.lock()
        counter += 1
        let line = Line(id: counter, date: Date(), level: level, topic: topic, text: "[kastideo] " + Self.redact(message))
        lines.append(line)
        if lines.count > capacity { lines.removeFirst(lines.count - capacity) }
        lock.unlock()
        persist(line)
    }

    func warn(_ message: String, topic: LogTopic? = nil) { note(message, topic: topic, level: 1) }
    func error(_ message: String, topic: LogTopic? = nil) { note(message, topic: topic, level: 0) }

    func snapshot() -> [Line] {
        lock.lock(); defer { lock.unlock() }
        return lines
    }

    /// Dernière erreur VLC depuis une date donnée (pour l'afficher à l'utilisateur).
    func lastError(since date: Date) -> String? {
        snapshot().last { $0.level == 0 && $0.topic == .playback && $0.date >= date }?.text
    }

    func clear() {
        lock.lock(); lines.removeAll(); lock.unlock()
    }

    /// Texte à copier : en-tête (version, filtre appliqué) puis les lignes données (par défaut, tout le journal).
    func exportText(_ selection: [Line]? = nil, filter: String? = nil) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        var text = "Kastideo \(version) — journal (identifiants masqués)\n"
        if let filter, !filter.isEmpty { text += "Filtre : \(filter)\n" }
        for line in selection ?? snapshot() {
            text += "\(formatter.string(from: line.date)) \(line.levelLabel) [\(line.topic.title)] \(line.text)\n"
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
