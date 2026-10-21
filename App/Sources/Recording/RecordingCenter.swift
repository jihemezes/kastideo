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

/// Message affiché en bandeau après un enregistrement ou un téléchargement.
struct RecordingToast: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let file: URL?
    let isError: Bool
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
    private(set) var batches: [UUID: DownloadBatch] = [:]
    /// Vitesse de téléchargement lissée (octets par seconde).
    private(set) var downloadSpeed: Double = 0
    private(set) var files: [RecordingFile] = []
    private(set) var converting: [String] = []
    var conflict: RecordingConflict?
    /// Dernier résultat d'enregistrement ou de téléchargement, affiché en bandeau (les notifications macOS peuvent être refusées).
    var toast: RecordingToast?
    var scheduleSheetItem: MediaItem?

    private let store: LibraryStore
    private let playback: PlaybackController
    private let downloader = DownloadEngine()
    @ObservationIgnored private var background: BackgroundRecorder?
    @ObservationIgnored private var workDir: URL?
    @ObservationIgnored private var playerRecordingDir: URL?
    @ObservationIgnored private var playerRecordingStart: Date?
    @ObservationIgnored private var pendingFinalize: ActiveLive?
    @ObservationIgnored private var activeDownloadID: UUID?
    @ObservationIgnored private var speedSample: (id: UUID, date: Date, bytes: Int64)?
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

    /// Notifie (notification macOS + bandeau dans l'application, avec le fichier créé le cas échéant).
    func report(_ title: String, _ message: String, file: URL? = nil, error: Bool = false) {
        Notifier.post(title, message)
        let toast = RecordingToast(title: title, message: message, file: file, isError: error)
        self.toast = toast
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(error ? 20 : 12))
            if self?.toast?.id == toast.id { self?.toast = nil }
        }
    }

    func isRecording(_ item: MediaItem?) -> Bool {
        guard let item, let live = activeLive else { return false }
        return live.item.id == item.id
    }

    func isScheduled(_ item: MediaItem, _ programme: Programme) -> Bool {
        schedules.contains { $0.item.id == item.id && $0.title == programme.title && abs($0.end.timeIntervalSince(programme.stop)) < 3600 }
    }

    var activeDownload: DownloadItem? { downloads.first { $0.state == .downloading } }

    /// Téléchargement à montrer dans l'indicateur : celui en cours, sinon un téléchargement suspendu pendant la lecture.
    var downloadStatus: DownloadStatus? {
        guard let current = activeDownload ?? downloads.first(where: { $0.state == .paused && !$0.pausedByUser }) else {
            return nil
        }
        let active = current.state == .downloading
        let speed = active ? downloadSpeed : 0
        let remainingCurrent = Double(max(current.expected - current.received, 0))
        let eta: TimeInterval? = (active && speed > 1 && current.expected > 0) ? remainingCurrent / speed : nil

        var info: DownloadBatchInfo?
        if let id = current.batchID, let batch = batches[id] {
            let remaining = downloads.filter { $0.batchID == id }.count
            let total = batch.completed + remaining
            let average = batch.completed > 0 ? Double(batch.bytesDone) / Double(batch.completed) : Double(current.expected)
            let progress = total > 0 ? (Double(batch.completed) + current.progress) / Double(total) : 0
            var batchETA: TimeInterval?
            if active, speed > 1, average > 0 {
                batchETA = (remainingCurrent + Double(max(remaining - 1, 0)) * average) / speed
            }
            info = DownloadBatchInfo(title: batch.title, position: batch.completed + 1, total: total,
                                     progress: progress, eta: batchETA)
        }
        let others = downloads.filter { entry in
            entry.id != current.id && entry.state != .failed
                && (current.batchID == nil || entry.batchID != current.batchID)
        }.count
        return DownloadStatus(current: current, isActive: active, speed: speed, eta: eta,
                              batch: info, othersQueued: others)
    }

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
                    title: String(localized: "Enregistrement en cours"),
                    message: String(localized: "« \(live.title) » (\(live.item.name)) est en cours d'enregistrement. Votre abonnement n'autorise qu'une connexion : regarder « \(item.name) » arrêtera l'enregistrement."),
                    confirmTitle: String(localized: "Arrêter l'enregistrement et regarder"),
                    onConfirm: { [weak self] in
                        self?.stopLive()
                        self?.playback.play(item)
                    },
                    onCancel: onCancel)
                return
            }
        } else if !isLocal, let download = activeDownload {
            conflict = RecordingConflict(
                title: String(localized: "Téléchargement en cours"),
                message: String(localized: "« \(download.fileName) » est en cours de téléchargement. Votre abonnement n'autorise qu'une connexion : le téléchargement sera mis en pause et reprendra automatiquement après la lecture."),
                confirmTitle: String(localized: "Mettre en pause et regarder"),
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
                title: String(localized: "Enregistrement en cours"),
                message: String(localized: "Arrêter la lecture arrêtera aussi l'enregistrement de « \(live.title) »."),
                confirmTitle: String(localized: "Tout arrêter"),
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
                title: String(localized: "Un enregistrement est déjà en cours"),
                message: String(localized: "« \(live.title) » est en cours d'enregistrement. L'arrêter pour enregistrer « \(item.name) » ?"),
                confirmTitle: String(localized: "Arrêter et enregistrer « \(item.name) »"),
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
                title: String(localized: "Lecture en cours"),
                message: String(localized: "Votre abonnement n'autorise qu'une connexion : enregistrer « \(item.name) » arrêtera la lecture de « \(current.name) »."),
                confirmTitle: String(localized: "Arrêter la lecture et enregistrer"),
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
            playback.stopRecording()
            awaitPlayerRecordingFile(live)
        case .background:
            let segments = background?.stop() ?? []
            background = nil
            finalizeLive(segments: segments, live: live)
        }
        updateSleepGuard()
    }

    /// Après l'arrêt demandé à VLC : attend l'annonce du fichier ; sans réponse, le retrouve dans le dossier de travail.
    private func awaitPlayerRecordingFile(_ live: ActiveLive) {
        let started = playerRecordingStart ?? live.startedAt
        let dir = playerRecordingDir
        Task { [weak self] in
            for _ in 0..<12 {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { return }
                if self.pendingFinalize == nil { return }   // déjà finalisé par l'annonce de VLC
            }
            guard let self, let pending = self.pendingFinalize else { return }
            self.pendingFinalize = nil
            if let dir, let found = RecordingLocator.find(workDir: dir, since: started) {
                PlaybackLog.shared.note("Enregistrement : fichier retrouvé sans annonce de VLC : \(found.path)")
                self.finalizeLive(segments: [found], live: pending)
            } else {
                self.report(String(localized: "Enregistrement vide"),
                            String(localized: "Aucune donnée reçue pour « \(live.title) »."), error: true)
                self.cleanPlayerRecordingDir()
            }
        }
    }

    private func cleanPlayerRecordingDir() {
        if let dir = playerRecordingDir { RecordingFolder.removeWorkDirectory(dir) }
        playerRecordingDir = nil
        playerRecordingStart = nil
    }

    private func startPlayerRecording(_ item: MediaItem, title: String, end: Date?, scheduleID: UUID?) {
        let dir = RecordingFolder.liveDirectory(named: FileNaming.liveName(channel: item.name, title: title, date: Date()))
        playerRecordingDir = dir
        playerRecordingStart = Date()
        activeLive = ActiveLive(item: item, title: title, startedAt: Date(), endsAt: end, mode: .player, scheduleID: scheduleID)
        updateSleepGuard()
        Task { [weak self] in
            // La lecture peut être encore en cours d'ouverture : on attend jusqu'à 20 s qu'elle ait démarré.
            for _ in 0..<40 {
                guard let self, self.activeLive?.mode == .player, self.activeLive?.item.id == item.id else { return }
                if self.playback.canRecord { break }
                try? await Task.sleep(for: .milliseconds(500))
            }
            guard let self, self.activeLive?.mode == .player, self.activeLive?.item.id == item.id else { return }
            guard self.playback.canRecord else {
                self.failPlayerRecording(item, reason: "la lecture n'a pas démarré")
                return
            }
            // VLCKit renvoie souvent « faux » alors que l'enregistrement a démarré : c'est la présence du fichier
            // qui fait foi. Premier essai dans le dossier visible « En cours », second dans un dossier temporaire.
            var attempts = [dir]
            let temporary = RecordingFolder.workDirectory()
            if temporary != dir { attempts.append(temporary) }
            for (index, target) in attempts.enumerated() {
                guard self.activeLive?.mode == .player, self.activeLive?.item.id == item.id else { return }
                self.playerRecordingDir = target
                let since = Date()
                self.playback.startRecording(into: target)
                for _ in 0..<10 {
                    try? await Task.sleep(for: .seconds(1))
                    guard self.activeLive?.mode == .player, self.activeLive?.item.id == item.id else { return }
                    if let found = RecordingLocator.find(workDir: target, since: since) {
                        PlaybackLog.shared.note("Enregistrement : fichier en cours d'écriture (essai \(index + 1)) : \(found.path)")
                        if target != dir { RecordingFolder.removeWorkDirectory(dir) }
                        else { RecordingFolder.removeWorkDirectory(temporary) }
                        self.report(String(localized: "Enregistrement démarré"), "\(item.name) — \(title)")
                        return
                    }
                }
                PlaybackLog.shared.note("Enregistrement : aucun fichier après 10 s dans \(target.path) (essai \(index + 1))")
                self.playback.stopRecording()
                try? await Task.sleep(for: .seconds(1))
            }
            RecordingFolder.removeWorkDirectory(temporary)
            self.failPlayerRecording(item, reason: "aucun fichier n'a été créé par le moteur de lecture (2 essais)")
        }
    }

    private func failPlayerRecording(_ item: MediaItem, reason: String) {
        PlaybackLog.shared.note("Enregistrement impossible : \(reason)")
        activeLive = nil
        pendingFinalize = nil
        cleanPlayerRecordingDir()
        updateSleepGuard()
        report(String(localized: "Enregistrement impossible"),
               String(localized: "Le moteur de lecture n'a pas pu démarrer l'enregistrement de « \(item.name) »."), error: true)
    }

    private func startBackground(_ item: MediaItem, title: String, end: Date?, scheduleID: UUID?) {
        guard let url = item.streamURL else { return }
        let dir = RecordingFolder.liveDirectory(named: FileNaming.liveName(channel: item.name, title: title, date: Date()))
        let recorder = BackgroundRecorder(workDir: dir)
        background = recorder
        workDir = dir
        activeLive = ActiveLive(item: item, title: title, startedAt: Date(), endsAt: end, mode: .background, scheduleID: scheduleID)
        recorder.start(url: url)
        Notifier.post(String(localized: "Enregistrement démarré"), "\(item.name) — \(title)")
        updateSleepGuard()
    }

    private func playerRecordingStopped(_ announced: String?) {
        // Fin demandée (stopLive) ou arrêt par VLC lui-même (changement de flux, coupure).
        var live = pendingFinalize
        pendingFinalize = nil
        if live == nil, let current = activeLive, current.mode == .player {
            live = current
            activeLive = nil
        }
        updateSleepGuard()
        guard let live else { return }
        let started = playerRecordingStart ?? live.startedAt
        // Le chemin annoncé est parfois vide ou faux : on le vérifie, sinon on cherche le fichier.
        var file: URL?
        if let announced, !announced.isEmpty, RecordingLocator.size(of: URL(fileURLWithPath: announced)) > 0 {
            file = URL(fileURLWithPath: announced)
        } else if let dir = playerRecordingDir {
            file = RecordingLocator.find(workDir: dir, since: started)
        }
        PlaybackLog.shared.note("Enregistrement : fin (chemin annoncé : \(announced ?? "aucun"), fichier retenu : \(file?.path ?? "aucun"))")
        finalizeLive(segments: file.map { [$0] } ?? [], live: live)
    }

    private func finalizeLive(segments: [URL], live: ActiveLive) {
        if let id = live.scheduleID {
            schedules.removeAll { $0.id == id }
            saveSchedules()
        }
        let valid = segments.filter { RecordingLocator.size(of: $0) > 0 }
        guard !valid.isEmpty else {
            report(String(localized: "Enregistrement vide"),
                   String(localized: "Aucune donnée reçue pour « \(live.title) »."), error: true)
            cleanPlayerRecordingDir()
            if let dir = workDir { RecordingFolder.removeWorkDirectory(dir); workDir = nil }
            return
        }
        let base = FileNaming.liveName(channel: live.item.name, title: live.title, date: live.startedAt)
        do {
            let folder = try destinationFolder()
            let ts = FileNaming.unique(folder.appendingPathComponent(base).appendingPathExtension("ts"))
            try SegmentJoiner.join(valid, into: ts)
            if let dir = workDir { RecordingFolder.removeWorkDirectory(dir); workDir = nil }
            cleanPlayerRecordingDir()
            PlaybackLog.shared.note("Enregistrement : fichier placé dans \(ts.path)")
            if RecordingKeys.convertToMP4 {
                let mp4 = FileNaming.unique(folder.appendingPathComponent(base).appendingPathExtension("mp4"))
                enqueueRemux(input: ts, output: mp4, name: base)
            } else {
                report(String(localized: "Enregistrement terminé"), base, file: ts)
            }
        } catch {
            // Dernier recours : on garde le fichier brut plutôt que de le perdre.
            PlaybackLog.shared.note("Enregistrement : échec du déplacement (\(error.localizedDescription))")
            report(String(localized: "Enregistrement impossible"),
                   "« \(live.title) » : \(error.localizedDescription)", file: valid.first, error: true)
        }
        refreshFiles()
    }

    /// Dossier d'enregistrement choisi ; s'il n'est pas utilisable, le dossier par défaut (avec un avertissement).
    private func destinationFolder() throws -> URL {
        do {
            let folder = try RecordingFolder.ensure()
            let probe = folder.appendingPathComponent(".kastideo-\(UUID().uuidString)")
            guard FileManager.default.createFile(atPath: probe.path, contents: Data()) else {
                throw CocoaError(.fileWriteNoPermission)
            }
            try? FileManager.default.removeItem(at: probe)
            return folder
        } catch {
            guard RecordingFolder.isCustom else { throw error }
            PlaybackLog.shared.note("Dossier d'enregistrement inaccessible (\(error.localizedDescription)) : utilisation de ~/Movies/Kastideo")
            let fallback = RecordingFolder.defaultURL
            try FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
            report(String(localized: "Dossier d'enregistrement inaccessible"),
                   String(localized: "Le dossier choisi n'est plus accessible : l'enregistrement est placé dans ~/Movies/Kastideo. Choisissez à nouveau le dossier dans Réglages > Enregistrements."),
                   error: true)
            return fallback
        }
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
                self.report(String(localized: "Enregistrement terminé"), job.name, file: job.output)
            } else {
                try? FileManager.default.removeItem(at: job.output)
                self.report(String(localized: "Enregistrement terminé"),
                            String(localized: "\(job.name) — conservé au format .ts (conversion MP4 impossible)"), file: job.input)
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
            Notifier.post(String(localized: "Attention : chevauchement"), String(localized: "« \(title) » chevauche « \(overlap.title) ». Une seule connexion : seul le premier sera enregistré."))
        }
        schedules.append(recording)
        schedules.sort { $0.start < $1.start }
        saveSchedules()
        Notifier.requestAuthorization()
        Notifier.post(String(localized: "Enregistrement programmé"), "\(item.name) — \(title), \(start.formatted(date: .abbreviated, time: .shortened))")
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
                title: String(localized: "Enregistrement programmé"),
                message: String(localized: "L'enregistrement de « \(recording.title) » (\(recording.item.name)) doit commencer. Votre abonnement n'autorise qu'une connexion : la lecture de « \(current.name) » va s'arrêter. Sans réponse, l'enregistrement démarrera dans 60 secondes."),
                confirmTitle: String(localized: "Arrêter la lecture et enregistrer"),
                onConfirm: { [weak self] in self?.forceStartScheduled(id) },
                onCancel: { [weak self] in
                    self?.pendingScheduleID = nil
                    self?.removeSchedule(id)
                })
            Notifier.post(String(localized: "Enregistrement programmé"), String(localized: "« \(recording.title) » doit commencer : la lecture en cours va s'arrêter."))
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

    func download(_ item: MediaItem, tonight: Bool, batch: UUID? = nil) {
        guard let url = item.streamURL, !url.isFileURL else { return }
        if downloads.contains(where: { $0.item.id == item.id }) { return }
        let ext = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
        var entry = DownloadItem(item: item, fileName: FileNaming.mediaName(item) + "." + ext)
        entry.batchID = batch
        if tonight { entry.startAfter = nextNight() }
        downloads.append(entry)
        saveDownloads()
        Notifier.requestAuthorization()
        if tonight {
            Notifier.post(String(localized: "Téléchargement programmé"), "\(entry.fileName) — \(entry.startAfter?.formatted(date: .abbreviated, time: .shortened) ?? "")")
        }
        runDownloadQueue()
        updateSleepGuard()
    }

    func download(_ items: [MediaItem], tonight: Bool) {
        let fresh = items.filter { item in
            guard let url = item.streamURL, !url.isFileURL else { return false }
            return !downloads.contains { $0.item.id == item.id }
        }
        var batchID: UUID?
        if fresh.count > 1 {
            let id = UUID()
            batchID = id
            let title = fresh[0].kind == .episode ? fresh[0].group : String(localized: "\(fresh.count) téléchargements")
            batches[id] = DownloadBatch(title: title)
            saveBatches()
        }
        for item in fresh { download(item, tonight: tonight, batch: batchID) }
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
        pruneBatches()
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
        speedSample = nil
        downloadSpeed = 0
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
        speedSample = nil
        downloadSpeed = 0
        saveDownloads()
        PlaybackLog.shared.note("Téléchargement : \(downloads[index].fileName)")
        downloader.start(id: id, url: url, resumeData: ResumeStore.load(id))
        updateSleepGuard()
    }

    private func downloadProgress(_ id: UUID, _ received: Int64, _ expected: Int64) {
        guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
        downloads[index].received = received
        downloads[index].expected = expected
        // Vitesse lissée (moyenne mobile sur des mesures d'au moins une seconde).
        let now = Date()
        if let sample = speedSample, sample.id == id {
            let elapsed = now.timeIntervalSince(sample.date)
            if elapsed >= 1 {
                let instant = Double(received - sample.bytes) / elapsed
                downloadSpeed = downloadSpeed > 0 ? downloadSpeed * 0.7 + instant * 0.3 : instant
                speedSample = (id, now, received)
            }
        } else {
            speedSample = (id, now, received)
        }
    }

    private func downloadFinished(_ id: UUID, _ location: URL?, _ error: Error?) {
        activeDownloadID = nil
        speedSample = nil
        downloadSpeed = 0
        guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
        let entry = downloads[index]
        if let location {
            do {
                let folder = try RecordingFolder.ensure()
                let destination = FileNaming.unique(folder.appendingPathComponent(entry.fileName))
                try FileManager.default.moveItem(at: location, to: destination)
                downloads.remove(at: index)
                ResumeStore.delete(id)
                if let batchID = entry.batchID, batches[batchID] != nil {
                    batches[batchID]?.completed += 1
                    batches[batchID]?.bytesDone += max(entry.expected, entry.received)
                }
                pruneBatches()
                report(String(localized: "Téléchargement terminé"), entry.fileName)
                refreshFiles()
            } catch {
                downloads[index].state = .failed
                downloads[index].error = error.localizedDescription
            }
        } else {
            let resume = (error as NSError?)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
            ResumeStore.save(resume, for: id)
            downloads[index].state = .failed
            downloads[index].error = error.map { LibraryStore.describe($0) } ?? String(localized: "Échec du téléchargement.")
            report(String(localized: "Téléchargement interrompu"), "\(entry.fileName) — \(downloads[index].error ?? "")", error: true)
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
        Notifier.post(String(localized: "Nettoyage des enregistrements"), String(localized: "\(old.count) enregistrement(s) de plus de \(RecordingKeys.autoCleanDayCount) jours placé(s) dans la corbeille."))
        refreshFiles()
    }

    private func checkDiskSpace() {
        if let space = RecordingFolder.availableSpace(), space < 3_000_000_000 {
            Notifier.post(String(localized: "Espace disque faible"), String(localized: "Il reste \(ByteCountFormatter.string(fromByteCount: space, countStyle: .file)) dans le dossier des enregistrements."))
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
                report(String(localized: "Enregistrement manqué"), String(localized: "« \(recording.title) » (\(recording.item.name)) n'a pas pu être enregistré."), error: true)
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
        if let data = defaults.data(forKey: RecordingKeys.batches),
           let decoded = try? JSONDecoder().decode([UUID: DownloadBatch].self, from: data) {
            batches = decoded
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

    private func saveBatches() {
        if let data = try? JSONEncoder().encode(batches) {
            UserDefaults.standard.set(data, forKey: RecordingKeys.batches)
        }
    }

    /// Supprime les lots dont tous les épisodes sont terminés ou annulés.
    private func pruneBatches() {
        let alive = Set(downloads.compactMap(\.batchID))
        let before = batches.count
        batches = batches.filter { alive.contains($0.key) }
        if batches.count != before || !batches.isEmpty { saveBatches() }
    }

    private func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: RecordingKeys.downloads)
        }
    }
}
