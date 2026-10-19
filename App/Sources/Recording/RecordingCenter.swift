import Foundation
import AppKit
import Observation
import KastideoCore

/// Question posée à l'utilisateur quand la connexion unique est déjà utilisée.
struct RecordingConflict: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let confirmTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
}

/// Chef d'orchestre des enregistrements (direct, programmés), des téléchargements et des conversions.
/// Garantit qu'une seule connexion au fournisseur est utilisée à la fois.
@MainActor
@Observable
final class RecordingCenter {
    struct ActiveLive: Equatable {
        enum Mode: Equatable { case player, background }
        var item: MediaItem
        var title: String
        var startedAt: Date
        var endsAt: Date?
        var mode: Mode
        var scheduleID: UUID?
    }

    private(set) var activeLive: ActiveLive?
    private(set) var schedules: [ScheduledRecording] = []
    private(set) var downloads: [DownloadItem] = []
    private(set) var files: [RecordingFile] = []
    private(set) var converting: [String] = []
    var conflict: RecordingConflict?
    var scheduleSheetItem: MediaItem?

    private let store: LibraryStore
    private let playback: PlaybackController
    private let downloader = DownloadEngine()
    @ObservationIgnored private var background: BackgroundRecorder?
    @ObservationIgnored private var workDir: URL?
    @ObservationIgnored private var pendingFinalize: ActiveLive?
    @ObservationIgnored private var activeDownloadID: UUID?
    @ObservationIgnored private var remuxer: Remuxer?
    @ObservationIgnored private var remuxQueue: [(input: URL, output: URL, name: String)] = []
    @ObservationIgnored private var pendingScheduleID: UUID?
    @ObservationIgnored private var lastCleanup = Date.distantPast
    @ObservationIgnored private var ticker: Task<Void, Never>?

    init(store: LibraryStore, playback: PlaybackController) {
        self.store = store
        self.playback = playback
        loadState()
        playback.onRecordingStopped = { [weak self] path in self?.playerRecordingStopped(path) }
        downloader.onProgress = { [weak self] id, received, expected in self?.downloadProgress(id, received, expected) }
        downloader.onFinished = { [weak self] id, location, error in self?.downloadFinished(id, location, error) }
        Notifier.setup()
        refreshFiles()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                self?.tick()
            }
        }
    }

    // MARK: - État

    var isPlayerRecording: Bool { activeLive?.mode == .player }

    func isRecording(_ item: MediaItem?) -> Bool {
        guard let item, let live = activeLive else { return false }
        return live.item.id == item.id
    }

    func isScheduled(_ item: MediaItem, _ programme: Programme) -> Bool {
        schedules.contains { $0.item.id == item.id && $0.title == programme.title && abs($0.end.timeIntervalSince(programme.stop)) < 3600 }
    }

    var activeDownload: DownloadItem? { downloads.first { $0.state == .downloading } }

    var activityCount: Int {
        (activeLive == nil ? 0 : 1) + (activeDownload == nil ? 0 : 1) + converting.count
    }

    func fileItem(id: String) -> MediaItem? {
        files.first { $0.id == id }?.mediaItem
    }

    private var playbackUsesNetwork: Bool {
        guard let url = playback.current?.streamURL else { return false }
        return !url.isFileURL
    }

    private var marginBefore: TimeInterval { TimeInterval(RecordingKeys.marginBeforeMinutes * 60) }
    private var marginAfter: TimeInterval { TimeInterval(RecordingKeys.marginAfterMinutes * 60) }

    // MARK: - Lecture (respect de la connexion unique)

    /// Lance la lecture, en demandant d'abord s'il faut arrêter un enregistrement ou suspendre un téléchargement.
    func requestPlay(_ item: MediaItem, onCancel: @escaping () -> Void = {}) {
        let isLocal = item.streamURL?.isFileURL ?? false
        if let live = activeLive {
            let compatible = (live.mode == .player && live.item.id == item.id) || (live.mode == .background && isLocal)
            if !compatible {
                conflict = RecordingConflict(
                    title: "Enregistrement en cours",
                    message: "« \(live.title) » (\(live.item.name)) est en cours d'enregistrement. Votre abonnement n'autorise qu'une connexion : regarder « \(item.name) » arrêtera l'enregistrement.",
                    confirmTitle: "Arrêter l'enregistrement et regarder",
                    onConfirm: { [weak self] in
                        self?.stopLive()
                        self?.playback.play(item)
                    },
                    onCancel: onCancel)
                return
            }
        } else if !isLocal, let download = activeDownload {
            conflict = RecordingConflict(
                title: "Téléchargement en cours",
                message: "« \(download.fileName) » est en cours de téléchargement. Votre abonnement n'autorise qu'une connexion : le téléchargement sera mis en pause et reprendra automatiquement après la lecture.",
                confirmTitle: "Mettre en pause et regarder",
                onConfirm: { [weak self] in
                    self?.pauseActiveDownload(byUser: false)
                    self?.playback.play(item)
                },
                onCancel: onCancel)
            return
        }
        playback.play(item)
    }

    /// Arrêt de la lecture (demande confirmation si l'enregistrement en dépend).
    func requestStop() {
        if let live = activeLive, live.mode == .player {
            conflict = RecordingConflict(
                title: "Enregistrement en cours",
                message: "Arrêter la lecture arrêtera aussi l'enregistrement de « \(live.title) ».",
                confirmTitle: "Tout arrêter",
                onConfirm: { [weak self] in
                    self?.stopLive()
                    self?.playback.stop()
                },
                onCancel: {})
            return
        }
        playback.stop()
    }

    // MARK: - Enregistrement du direct

    /// Bouton ● : enregistre la chaîne regardée, ou arrête l'enregistrement en cours.
    func toggleCurrentRecording() {
        if let live = activeLive, live.mode == .player {
            stopLive()
            return
        }
        guard let item = playback.current, item.kind == .live, playbackUsesNetwork else { return }
        recordNow(item)
    }

    /// Enregistre une chaîne maintenant, jusqu'à la fin du programme en cours (guide TV) ou jusqu'à l'arrêt manuel.
    func recordNow(_ item: MediaItem) {
        if let live = activeLive {
            if live.item.id == item.id { return }
            conflict = RecordingConflict(
                title: "Un enregistrement est déjà en cours",
                message: "« \(live.title) » est en cours d'enregistrement. L'arrêter pour enregistrer « \(item.name) » ?",
                confirmTitle: "Arrêter et enregistrer « \(item.name) »",
                onConfirm: { [weak self] in
                    self?.stopLive()
                    self?.recordNow(item)
                },
                onCancel: {})
            return
        }
        let programme = store.epg.current(for: item.epgID)
        let end = programme.map { $0.stop.addingTimeInterval(marginAfter) }
        let title = programme?.title ?? item.name
        checkDiskSpace()

        if playback.current?.id == item.id, playbackUsesNetwork {
            startPlayerRecording(item, title: title, end: end, scheduleID: nil)
        } else if playbackUsesNetwork, let current = playback.current {
            conflict = RecordingConflict(
                title: "Lecture en cours",
                message: "Votre abonnement n'autorise qu'une connexion : enregistrer « \(item.name) » arrêtera la lecture de « \(current.name) ».",
                confirmTitle: "Arrêter la lecture et enregistrer",
                onConfirm: { [weak self] in
                    self?.playback.stop()
                    self?.startBackground(item, title: title, end: end, scheduleID: nil)
                },
                onCancel: {})
        } else {
            if activeDownload != nil { pauseActiveDownload(byUser: false) }
            startBackground(item, title: title, end: end, scheduleID: nil)
        }
    }

    func stopLive() {
        guard let live = activeLive else { return }
        activeLive = nil
        switch live.mode {
        case .player:
            pendingFinalize = live
            if !playback.stopRecording() {
                pendingFinalize = nil
                Notifier.post("Enregistrement", "L'enregistrement de « \(live.title) » n'a pas pu être finalisé.")
            }
        case .background:
            let segments = background?.stop() ?? []
            background = nil
            finalizeLive(segments: segments, live: live)
        }
        updateSleepGuard()
    }

    private func startPlayerRecording(_ item: MediaItem, title: String, end: Date?, scheduleID: UUID?) {
        let dir = RecordingFolder.workDirectory()
        activeLive = ActiveLive(item: item, title: title, startedAt: Date(), endsAt: end, mode: .player, scheduleID: scheduleID)
        updateSleepGuard()
        Task { [weak self] in
            // La lecture peut être encore en cours d'ouverture : on réessaie pendant 20 s.
            for _ in 0..<20 {
                guard let self, self.activeLive?.mode == .player, self.activeLive?.item.id == item.id else { return }
                if self.playback.startRecording(into: dir) {
                    Notifier.post("Enregistrement démarré", "\(item.name) — \(title)")
                    return
                }
                try? await Task.sleep(for: .seconds(1))
            }
            guard let self, self.activeLive?.mode == .player else { return }
            self.activeLive = nil
            self.updateSleepGuard()
            Notifier.post("Enregistrement impossible", "Le moteur de lecture n'a pas pu démarrer l'enregistrement de « \(item.name) ».")
        }
    }

    private func startBackground(_ item: MediaItem, title: String, end: Date?, scheduleID: UUID?) {
        guard let url = item.streamURL else { return }
        let dir = RecordingFolder.workDirectory()
        let recorder = BackgroundRecorder(workDir: dir)
        background = recorder
        workDir = dir
        activeLive = ActiveLive(item: item, title: title, startedAt: Date(), endsAt: end, mode: .background, scheduleID: scheduleID)
        recorder.start(url: url)
        Notifier.post("Enregistrement démarré", "\(item.name) — \(title)")
        updateSleepGuard()
    }

    private func playerRecordingStopped(_ path: String) {
        // Fin demandée (stopLive) ou arrêt par VLC lui-même (changement de flux, coupure).
        var live = pendingFinalize
        pendingFinalize = nil
        if live == nil, let current = activeLive, current.mode == .player {
            live = current
            activeLive = nil
        }
        updateSleepGuard()
        guard let live else { return }
        finalizeLive(segments: [URL(fileURLWithPath: path)], live: live)
    }

    private func finalizeLive(segments: [URL], live: ActiveLive) {
        if let id = live.scheduleID {
            schedules.removeAll { $0.id == id }
            saveSchedules()
        }
        let valid = segments.filter { ((try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) > 0 }
        guard !valid.isEmpty else {
            Notifier.post("Enregistrement vide", "Aucune donnée reçue pour « \(live.title) ».")
            return
        }
        let base = FileNaming.liveName(channel: live.item.name, title: live.title, date: live.startedAt)
        do {
            let folder = try RecordingFolder.ensure()
            let ts = FileNaming.unique(folder.appendingPathComponent(base).appendingPathExtension("ts"))
            try SegmentJoiner.join(valid, into: ts)
            if let dir = workDir { try? FileManager.default.removeItem(at: dir); workDir = nil }
            if RecordingKeys.convertToMP4 {
                let mp4 = FileNaming.unique(folder.appendingPathComponent(base).appendingPathExtension("mp4"))
                enqueueRemux(input: ts, output: mp4, name: base)
            } else {
                Notifier.post("Enregistrement terminé", base)
            }
        } catch {
            Notifier.post("Enregistrement impossible", "« \(live.title) » : \(error.localizedDescription)")
        }
        refreshFiles()
    }

    private func enqueueRemux(input: URL, output: URL, name: String) {
        remuxQueue.append((input, output, name))
        converting.append(name)
        runRemuxQueue()
    }

    private func runRemuxQueue() {
        guard remuxer == nil, !remuxQueue.isEmpty else { return }
        let job = remuxQueue.removeFirst()
        let remuxer = Remuxer()
        self.remuxer = remuxer
        updateSleepGuard()
        remuxer.run(input: job.input, output: job.output) { [weak self] success in
            guard let self else { return }
            self.remuxer = nil
            self.converting.removeAll { $0 == job.name }
            if success {
                try? FileManager.default.removeItem(at: job.input)
                Notifier.post("Enregistrement terminé", job.name)
            } else {
                try? FileManager.default.removeItem(at: job.output)
                Notifier.post("Enregistrement terminé", "\(job.name) — conservé au format .ts (conversion MP4 impossible)")
            }
            self.refreshFiles()
            self.updateSleepGuard()
            self.runRemuxQueue()
        }
    }

    // MARK: - Programmation

    func schedule(_ item: MediaItem, programme: Programme) {
        schedule(item, title: programme.title,
                 start: programme.start.addingTimeInterval(-marginBefore),
                 end: programme.stop.addingTimeInterval(marginAfter))
    }

    func schedule(_ item: MediaItem, title: String, start: Date, end: Date) {
        guard end > start, end > Date() else { return }
        let recording = ScheduledRecording(item: item, title: title, start: start, end: end)
        if let overlap = schedules.first(where: { $0.start < end && start < $0.end }) {
            Notifier.post("Attention : chevauchement", "« \(title) » chevauche « \(overlap.title) ». Une seule connexion : seul le premier sera enregistré.")
        }
        schedules.append(recording)
        schedules.sort { $0.start < $1.start }
        saveSchedules()
        Notifier.requestAuthorization()
        Notifier.post("Enregistrement programmé", "\(item.name) — \(title), \(start.formatted(date: .abbreviated, time: .shortened))")
        updateSleepGuard()
    }

    func removeSchedule(_ id: UUID) {
        schedules.removeAll { $0.id == id }
        saveSchedules()
        updateSleepGuard()
    }

    private func startScheduled(_ recording: ScheduledRecording) {
        if playback.current?.id == recording.item.id, playbackUsesNetwork {
            startPlayerRecording(recording.item, title: recording.title, end: recording.end, scheduleID: recording.id)
            return
        }
        if playbackUsesNetwork, let current = playback.current {
            let id = recording.id
            pendingScheduleID = id
            conflict = RecordingConflict(
                title: "Enregistrement programmé",
                message: "L'enregistrement de « \(recording.title) » (\(recording.item.name)) doit commencer. Votre abonnement n'autorise qu'une connexion : la lecture de « \(current.name) » va s'arrêter. Sans réponse, l'enregistrement démarrera dans 60 secondes.",
                confirmTitle: "Arrêter la lecture et enregistrer",
                onConfirm: { [weak self] in self?.forceStartScheduled(id) },
                onCancel: { [weak self] in
                    self?.pendingScheduleID = nil
                    self?.removeSchedule(id)
                })
            Notifier.post("Enregistrement programmé", "« \(recording.title) » doit commencer : la lecture en cours va s'arrêter.")
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(60))
                guard let self, self.pendingScheduleID == id, self.activeLive == nil else { return }
                self.conflict = nil
                self.forceStartScheduled(id)
            }
            return
        }
        if activeDownload != nil { pauseActiveDownload(byUser: false) }
        startBackground(recording.item, title: recording.title, end: recording.end, scheduleID: recording.id)
    }

    private func forceStartScheduled(_ id: UUID) {
        pendingScheduleID = nil
        guard activeLive == nil, let recording = schedules.first(where: { $0.id == id }) else { return }
        playback.stop()
        if activeDownload != nil { pauseActiveDownload(byUser: false) }
        startBackground(recording.item, title: recording.title, end: recording.end, scheduleID: recording.id)
    }

    // MARK: - Téléchargements

    func download(_ item: MediaItem, tonight: Bool) {
        guard let url = item.streamURL, !url.isFileURL else { return }
        if downloads.contains(where: { $0.item.id == item.id }) { return }
        let ext = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
        var entry = DownloadItem(item: item, fileName: FileNaming.mediaName(item) + "." + ext)
        if tonight { entry.startAfter = nextNight() }
        downloads.append(entry)
        saveDownloads()
        Notifier.requestAuthorization()
        if tonight {
            Notifier.post("Téléchargement programmé", "\(entry.fileName) — \(entry.startAfter?.formatted(date: .abbreviated, time: .shortened) ?? "")")
        }
        runDownloadQueue()
        updateSleepGuard()
    }

    func download(_ items: [MediaItem], tonight: Bool) {
        for item in items { download(item, tonight: tonight) }
    }

    func pauseDownload(_ id: UUID) {
        if activeDownloadID == id {
            pauseActiveDownload(byUser: true)
        } else if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].state = .paused
            downloads[index].pausedByUser = true
            saveDownloads()
        }
    }

    func resumeDownload(_ id: UUID, now: Bool = false) {
        guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
        downloads[index].state = .queued
        downloads[index].pausedByUser = false
        downloads[index].error = nil
        if now { downloads[index].startAfter = nil }
        saveDownloads()
        runDownloadQueue()
    }

    func cancelDownload(_ id: UUID) {
        if activeDownloadID == id {
            downloader.cancel()
            activeDownloadID = nil
        }
        downloads.removeAll { $0.id == id }
        ResumeStore.delete(id)
        saveDownloads()
        updateSleepGuard()
        runDownloadQueue()
    }

    private func pauseActiveDownload(byUser: Bool) {
        guard let id = activeDownloadID else { return }
        activeDownloadID = nil
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].state = .paused
            downloads[index].pausedByUser = byUser
        }
        saveDownloads()
        downloader.pause { data in ResumeStore.save(data, for: id) }
        updateSleepGuard()
    }

    private func runDownloadQueue() {
        guard activeDownloadID == nil, activeLive == nil, !playbackUsesNetwork else { return }
        let now = Date()
        guard let index = downloads.firstIndex(where: { entry in
            let ready = (entry.startAfter ?? .distantPast) <= now
            return ready && (entry.state == .queued || (entry.state == .paused && !entry.pausedByUser))
        }), let url = downloads[index].item.streamURL else { return }
        checkDiskSpace()
        downloads[index].state = .downloading
        downloads[index].error = nil
        let id = downloads[index].id
        activeDownloadID = id
        saveDownloads()
        PlaybackLog.shared.note("Téléchargement : \(downloads[index].fileName)")
        downloader.start(id: id, url: url, resumeData: ResumeStore.load(id))
        updateSleepGuard()
    }

    private func downloadProgress(_ id: UUID, _ received: Int64, _ expected: Int64) {
        guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
        downloads[index].received = received
        downloads[index].expected = expected
    }

    private func downloadFinished(_ id: UUID, _ location: URL?, _ error: Error?) {
        activeDownloadID = nil
        guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
        let entry = downloads[index]
        if let location {
            do {
                let folder = try RecordingFolder.ensure()
                let destination = FileNaming.unique(folder.appendingPathComponent(entry.fileName))
                try FileManager.default.moveItem(at: location, to: destination)
                downloads.remove(at: index)
                ResumeStore.delete(id)
                Notifier.post("Téléchargement terminé", entry.fileName)
                refreshFiles()
            } catch {
                downloads[index].state = .failed
                downloads[index].error = error.localizedDescription
            }
        } else {
            let resume = (error as NSError?)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
            ResumeStore.save(resume, for: id)
            downloads[index].state = .failed
            downloads[index].error = error.map { LibraryStore.describe($0) } ?? "Échec du téléchargement."
            Notifier.post("Téléchargement interrompu", "\(entry.fileName) — \(downloads[index].error ?? "")")
        }
        saveDownloads()
        updateSleepGuard()
        runDownloadQueue()
    }

    /// Prochaine occurrence de l'heure « cette nuit » (2 h par défaut).
    func nextNight() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = RecordingKeys.nightHourValue
        components.minute = 0
        let today = calendar.date(from: components) ?? Date()
        return today > Date() ? today : (calendar.date(byAdding: .day, value: 1, to: today) ?? today)
    }

    // MARK: - Fichiers

    func refreshFiles() {
        let folder = RecordingFolder.current
        let keys: [URLResourceKey] = [.creationDateKey, .contentModificationDateKey, .fileSizeKey, .isRegularFileKey]
        let urls = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys,
                                                                 options: [.skipsHiddenFiles])) ?? []
        files = urls.compactMap { url in
            guard RecordingFile.extensions.contains(url.pathExtension.lowercased()),
                  let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else { return nil }
            let date = values.creationDate ?? values.contentModificationDate ?? Date()
            return RecordingFile(url: url, date: date, size: Int64(values.fileSize ?? 0))
        }
        .sorted { $0.date > $1.date }
    }

    func deleteFile(_ file: RecordingFile) {
        if (try? FileManager.default.trashItem(at: file.url, resultingItemURL: nil)) == nil {
            try? FileManager.default.removeItem(at: file.url)
        }
        refreshFiles()
    }

    func reveal(_ file: RecordingFile? = nil) {
        if let file {
            NSWorkspace.shared.activateFileViewerSelecting([file.url])
        } else if let folder = try? RecordingFolder.ensure() {
            NSWorkspace.shared.open(folder)
        }
    }

    func chooseFolder(_ url: URL) {
        RecordingFolder.choose(url)
        refreshFiles()
    }

    func resetFolder() {
        RecordingFolder.resetToDefault()
        refreshFiles()
    }

    private func autoClean() {
        guard RecordingKeys.autoCleanEnabled else { return }
        let limit = Date().addingTimeInterval(-TimeInterval(RecordingKeys.autoCleanDayCount) * 86400)
        let old = files.filter { $0.date < limit }
        guard !old.isEmpty else { return }
        for file in old {
            if (try? FileManager.default.trashItem(at: file.url, resultingItemURL: nil)) == nil {
                try? FileManager.default.removeItem(at: file.url)
            }
        }
        Notifier.post("Nettoyage des enregistrements", "\(old.count) enregistrement(s) de plus de \(RecordingKeys.autoCleanDayCount) jours placé(s) dans la corbeille.")
        refreshFiles()
    }

    private func checkDiskSpace() {
        if let space = RecordingFolder.availableSpace(), space < 3_000_000_000 {
            Notifier.post("Espace disque faible", "Il reste \(ByteCountFormatter.string(fromByteCount: space, countStyle: .file)) dans le dossier des enregistrements.")
        }
    }

    // MARK: - Boucle de surveillance (toutes les 10 s)

    private func tick() {
        let now = Date()
        if let live = activeLive, let end = live.endsAt, now >= end {
            stopLive()
        }
        if activeLive == nil, conflict == nil, pendingScheduleID == nil,
           let due = schedules.first(where: { $0.start <= now && $0.end > now }) {
            startScheduled(due)
        }
        let missed = schedules.filter { $0.end <= now && $0.id != activeLive?.scheduleID && $0.id != pendingScheduleID }
        if !missed.isEmpty {
            schedules.removeAll { schedule in missed.contains { $0.id == schedule.id } }
            saveSchedules()
            for recording in missed {
                Notifier.post("Enregistrement manqué", "« \(recording.title) » (\(recording.item.name)) n'a pas pu être enregistré.")
            }
        }
        runDownloadQueue()
        if now.timeIntervalSince(lastCleanup) > 6 * 3600 {
            lastCleanup = now
            autoClean()
        }
        updateSleepGuard()
    }

    private func updateSleepGuard() {
        let now = Date()
        let soon = now.addingTimeInterval(3600)
        let scheduledSoon = schedules.contains { $0.start < soon && $0.end > now }
        let downloadSoon = downloads.contains { entry in
            (entry.state == .queued || (entry.state == .paused && !entry.pausedByUser)) && (entry.startAfter ?? .distantPast) < soon
        }
        SleepGuard.set(activeLive != nil || activeDownloadID != nil || remuxer != nil || scheduledSoon || downloadSoon)
    }

    // MARK: - Persistance

    private func loadState() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: RecordingKeys.schedules),
           let decoded = try? JSONDecoder().decode([ScheduledRecording].self, from: data) {
            schedules = decoded
        }
        if let data = defaults.data(forKey: RecordingKeys.downloads),
           let decoded = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            downloads = decoded.map { entry in
                var copy = entry
                if copy.state == .downloading { copy.state = .queued }
                return copy
            }
        }
    }

    private func saveSchedules() {
        if let data = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(data, forKey: RecordingKeys.schedules)
        }
    }

    private func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: RecordingKeys.downloads)
        }
    }
}
