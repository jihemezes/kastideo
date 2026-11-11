import SwiftUI
import UserNotifications
import KastideoCore

/// Dossiers de l'application visibles dans l'app Fichiers (Sur mon iPhone > Kastideo).
enum IOSFiles {
    static var root: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    static var recordings: URL { root.appendingPathComponent("Enregistrements", isDirectory: true) }
    static var downloads: URL { root.appendingPathComponent("Téléchargements", isDirectory: true) }

    static func ensureFolders() {
        for url in [recordings, downloads] {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    /// Nom de fichier sans caractères interdits.
    static func safeName(_ text: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/\\:*?\"<>|").union(.controlCharacters)
        let cleaned = text.components(separatedBy: forbidden).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Kastideo" : String(cleaned.prefix(120))
    }

    /// Nom libre dans un dossier : « Titre.ext », « Titre 2.ext »…
    static func uniqueURL(in folder: URL, name: String, ext: String) -> URL {
        var candidate = folder.appendingPathComponent(name).appendingPathExtension(ext)
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(name) \(index)").appendingPathExtension(ext)
            index += 1
        }
        return candidate
    }

    /// Identifiant fixe de la « source » des fichiers locaux de l'application.
    static let sourceID = UUID(uuidString: "00000000-0000-0000-0000-00000000F11E")!

    /// Élément lisible pour un fichier enregistré ou téléchargé.
    static func mediaItem(for url: URL, name: String) -> MediaItem {
        MediaItem(id: "ios-file:" + url.lastPathComponent, sourceID: sourceID, kind: .movie, name: name, group: "", streamURL: url)
    }
}

/// Notifications locales (alertes, fin de téléchargement) : affichées aussi quand l'application est ouverte.
@MainActor
enum IOSNotifier {
    private static let delegate = IOSNotificationDelegate()
    /// Chaîne à ouvrir après un toucher sur une alerte.
    static let openChannelName = Notification.Name("kastideo.openChannel")

    static func setup() {
        UNUserNotificationCenter.current().delegate = delegate
    }

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func post(_ title: String, _ body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}

final class IOSNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let channelID = response.notification.request.content.userInfo["channelID"] as? String else { return }
        await MainActor.run {
            NotificationCenter.default.post(name: IOSNotifier.openChannelName, object: channelID)
        }
    }
}

// MARK: - Enregistrement du direct

/// Enregistre la chaîne en cours dans le dossier Enregistrements de l'application.
/// Le flux est copié tel quel (pas de ré-encodage) : le fichier .ts se lit dans Kastideo et dans VLC.
@MainActor
@Observable
final class IOSRecorder {
    private(set) var isRecording = false
    private(set) var startedAt: Date?
    private(set) var channelName = ""
    var message: String?
    @ObservationIgnored private var limitTask: Task<Void, Never>?

    /// Démarre l'enregistrement de la chaîne en cours ; `minutes` > 0 l'arrête tout seul (0 : sans limite).
    func start(playback: PlaybackController, minutes: Int = 0) {
        guard !isRecording else { return }
        guard let item = playback.current, playback.isLive, !item.isReplay else {
            message = String(localized: "Seul un direct peut être enregistré.")
            return
        }
        guard playback.canRecord else {
            message = String(localized: "Attendez que l'image s'affiche pour enregistrer.")
            return
        }
        IOSFiles.ensureFolders()
        startedAt = Date()
        channelName = TMDB.cleanTitle(item.name).title
        _ = playback.startRecording(into: IOSFiles.recordings)
        isRecording = true
        message = nil
        limitTask?.cancel()
        if minutes > 0 {
            limitTask = Task { [weak self, weak playback] in
                try? await Task.sleep(for: .seconds(minutes * 60))
                guard !Task.isCancelled, let self, let playback else { return }
                self.stop(playback: playback)
            }
        }
    }

    func stop(playback: PlaybackController?) {
        guard isRecording else { return }
        limitTask?.cancel()
        _ = playback?.stopRecording()
        finalize()
    }

    /// Le flux a changé ou s'est arrêté : le fichier est clos et renommé.
    func streamEnded() {
        guard isRecording else { return }
        finalize()
    }

    private func finalize() {
        let started = startedAt ?? Date()
        let name = channelName
        isRecording = false
        startedAt = nil
        limitTask?.cancel()
        Task { [weak self] in
            // VLC referme le fichier quelques instants après l'arrêt.
            try? await Task.sleep(for: .seconds(1.5))
            let result = Self.renameNewest(since: started, channel: name)
            await MainActor.run {
                guard let self else { return }
                if let result {
                    self.message = String(localized: "Enregistrement ajouté : \(result)")
                    IOSNotifier.post(String(localized: "Enregistrement terminé"), result)
                } else {
                    self.message = String(localized: "Aucun fichier n'a été écrit (flux trop court ou refusé).")
                }
            }
        }
    }

    /// Renomme le fichier « vlc-record… » le plus récent en « Chaîne – date.ts ».
    nonisolated private static func renameNewest(since: Date, channel: String) -> String? {
        let manager = FileManager.default
        let folder = IOSFiles.recordings
        let keys: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey]
        guard let urls = try? manager.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys,
                                                          options: [.skipsHiddenFiles]) else { return nil }
        var best: (URL, Date)?
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)), (values.fileSize ?? 0) > 0,
                  let date = values.contentModificationDate, date >= since.addingTimeInterval(-3) else { continue }
            if best == nil || date > best!.1 { best = (url, date) }
        }
        guard let url = best?.0 else { return nil }
        let stamp = since.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
            .replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "h")
        let ext = url.pathExtension.isEmpty ? "ts" : url.pathExtension
        let target = IOSFiles.uniqueURL(in: folder, name: IOSFiles.safeName("\(channel) – \(stamp)"), ext: ext)
        do {
            try manager.moveItem(at: url, to: target)
            return target.deletingPathExtension().lastPathComponent
        } catch {
            return url.deletingPathExtension().lastPathComponent
        }
    }
}

// MARK: - Téléchargements

/// Téléchargement d'un film ou d'un épisode (continue application fermée).
struct IOSDownloadJob: Codable, Identifiable, Hashable {
    enum State: String, Codable { case queued, running, paused, failed }
    var id = UUID()
    var name: String
    var url: URL
    var fileName: String
    var state: State = .queued
    var received: Int64 = 0
    var expected: Int64 = 0
    var error: String?
    var resumeData: Data?

    var progress: Double { expected > 0 ? min(Double(received) / Double(expected), 1) : 0 }
}

@MainActor
@Observable
final class IOSDownloads {
    private(set) var jobs: [IOSDownloadJob] = []
    /// Dernier changement de la liste des fichiers (pour rafraîchir l'écran).
    private(set) var filesVersion = 0
    @ObservationIgnored private var session: URLSession!
    @ObservationIgnored private var tasks: [UUID: URLSessionDownloadTask] = [:]
    @ObservationIgnored private let proxy = IOSDownloadProxy()
    private static let key = "ios.downloads.v1"
    private static let sessionID = "fr.jmezes.kastideo.downloads"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([IOSDownloadJob].self, from: data) {
            jobs = decoded
        }
        let configuration = URLSessionConfiguration.background(withIdentifier: Self.sessionID)
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        proxy.owner = self
        session = URLSession(configuration: configuration, delegate: proxy, delegateQueue: nil)
        session.getAllTasks { [weak self] existing in
            let downloads = existing.compactMap { $0 as? URLSessionDownloadTask }
            Task { @MainActor in self?.reattach(downloads) }
        }
    }

    /// Adresse téléchargeable : un fichier (pas une liste HLS ni un direct).
    static func canDownload(_ item: MediaItem) -> Bool {
        guard let url = item.streamURL, let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              item.kind == .movie || item.kind == .episode || item.kind == .series else { return false }
        return !url.path.lowercased().hasSuffix(".m3u8")
    }

    func isQueued(_ item: MediaItem) -> Bool {
        jobs.contains { $0.url == item.streamURL }
    }

    func add(_ item: MediaItem) {
        guard Self.canDownload(item), let url = item.streamURL, !isQueued(item) else { return }
        IOSFiles.ensureFolders()
        IOSNotifier.requestAuthorization()
        let ext = url.pathExtension.isEmpty || url.pathExtension.count > 4 ? "mp4" : url.pathExtension
        let name = TMDB.cleanTitle(item.name).title
        let job = IOSDownloadJob(name: name, url: url, fileName: IOSFiles.safeName(name) + "." + ext)
        jobs.append(job)
        save()
        startNext()
    }

    /// Un seul téléchargement à la fois (la plupart des abonnements n'autorisent qu'une connexion) :
    /// le suivant démarre quand le précédent est terminé, en pause, en erreur ou supprimé.
    private func startNext() {
        guard !jobs.contains(where: { $0.state == .running }) else { return }
        guard let next = jobs.first(where: { $0.state == .queued }) else { return }
        launch(next)
    }

    func pause(_ id: UUID) {
        guard let task = tasks[id] else { return }
        task.cancel(byProducingResumeData: { [weak self] data in
            Task { @MainActor in
                guard let self, let index = self.jobs.firstIndex(where: { $0.id == id }) else { return }
                self.jobs[index].state = .paused
                self.jobs[index].resumeData = data
                self.tasks[id] = nil
                self.save()
                self.startNext()
            }
        })
    }

    func resume(_ id: UUID) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        // Remis en file : il démarre dès qu'aucun autre téléchargement n'est en cours.
        jobs[index].state = .queued
        jobs[index].error = nil
        save()
        startNext()
    }

    func cancel(_ id: UUID) {
        tasks[id]?.cancel()
        tasks[id] = nil
        jobs.removeAll { $0.id == id }
        save()
        startNext()
    }

    private func launch(_ job: IOSDownloadJob) {
        let task: URLSessionDownloadTask
        if let data = job.resumeData {
            task = session.downloadTask(withResumeData: data)
        } else {
            task = session.downloadTask(with: job.url)
        }
        task.taskDescription = job.id.uuidString + "|" + job.fileName
        tasks[job.id] = task
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[index].state = .running
            jobs[index].error = nil
            jobs[index].resumeData = nil
        }
        task.resume()
        save()
    }

    private func reattach(_ existing: [URLSessionDownloadTask]) {
        var keep: UUID?
        for task in existing {
            guard let description = task.taskDescription, let id = UUID(uuidString: String(description.prefix(36))),
                  jobs.contains(where: { $0.id == id }) else { task.cancel(); continue }
            if keep == nil {
                keep = id
                tasks[id] = task
            } else {
                // Une seule connexion : les autres tâches (anciennes versions) repassent en file.
                task.cancel()
                if let index = jobs.firstIndex(where: { $0.id == id }) { jobs[index].state = .queued; jobs[index].resumeData = nil }
            }
        }
        // Un téléchargement « en cours » sans tâche (application relancée) repasse en file.
        for index in jobs.indices where jobs[index].state == .running && tasks[jobs[index].id] == nil { jobs[index].state = .queued }
        save()
        startNext()
    }

    fileprivate func progress(_ id: UUID, received: Int64, expected: Int64) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[index].received = received
        jobs[index].expected = expected
    }

    fileprivate func finished(_ id: UUID, savedAs name: String?) {
        tasks[id] = nil
        guard let job = jobs.first(where: { $0.id == id }) else { return }
        jobs.removeAll { $0.id == id }
        filesVersion += 1
        save()
        if name != nil { IOSNotifier.post(String(localized: "Téléchargement terminé"), job.name) }
        startNext()
    }

    fileprivate func failed(_ id: UUID, message: String, resumeData: Data?) {
        tasks[id] = nil
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[index].state = .failed
        jobs[index].error = message
        jobs[index].resumeData = resumeData
        save()
        startNext()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(jobs) { UserDefaults.standard.set(data, forKey: Self.key) }
    }
}

/// Reçoit les événements de la session d'arrière-plan (hors acteur principal).
final class IOSDownloadProxy: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    weak var owner: IOSDownloads?

    private func parse(_ task: URLSessionTask) -> (UUID, String)? {
        guard let description = task.taskDescription, description.count > 37,
              let id = UUID(uuidString: String(description.prefix(36))) else { return nil }
        return (id, String(description.dropFirst(37)))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let (id, _) = parse(downloadTask) else { return }
        Task { @MainActor [weak self] in self?.owner?.progress(id, received: totalBytesWritten, expected: totalBytesExpectedToWrite) }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let (id, fileName) = parse(downloadTask) else { return }
        // Une réponse d'erreur (404, 403…) n'est pas une vidéo.
        if let http = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let message = String(localized: "Le serveur a refusé le téléchargement (code \(http.statusCode)).")
            Task { @MainActor [weak self] in self?.owner?.failed(id, message: message, resumeData: nil) }
            return
        }
        let folder = IOSFiles.downloads
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        let target = IOSFiles.uniqueURL(in: folder, name: base, ext: ext.isEmpty ? "mp4" : ext)
        do {
            try FileManager.default.moveItem(at: location, to: target)
            Task { @MainActor [weak self] in self?.owner?.finished(id, savedAs: target.lastPathComponent) }
        } catch {
            let message = error.localizedDescription
            Task { @MainActor [weak self] in self?.owner?.failed(id, message: message, resumeData: nil) }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, let (id, _) = parse(task) else { return }
        let nsError = error as NSError
        // Annulé par l'utilisateur (pause ou suppression) : déjà traité.
        if nsError.code == NSURLErrorCancelled { return }
        let data = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        let message = error.localizedDescription
        Task { @MainActor [weak self] in self?.owner?.failed(id, message: message, resumeData: data) }
    }
}
