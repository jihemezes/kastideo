import Foundation
import AppKit
import Observation
import VLCKitSPM
import KastideoCore

/// Réglage de la mémoire tampon réseau (compromis vitesse de zapping / stabilité).
enum BufferingMode: String, CaseIterable, Identifiable {
    case fast, normal, stable
    var id: String { rawValue }

    var label: String {
        switch self {
        case .fast: return String(localized: "Rapide — zapping le plus court (0,4 s)")
        case .normal: return String(localized: "Équilibré (1 s)")
        case .stable: return String(localized: "Stable — connexions irrégulières (3 s)")
        }
    }

    /// Valeur de « network-caching » de VLC, en millisecondes.
    var networkCaching: Int {
        switch self {
        case .fast: return 400
        case .normal: return 1000
        case .stable: return 3000
        }
    }

    static var current: BufferingMode {
        BufferingMode(rawValue: UserDefaults.standard.string(forKey: PlaybackKeys.buffering) ?? "") ?? .fast
    }
}

enum PlaybackKeys {
    static let buffering = "buffering"
    static let showStartupTime = "showStartupTime"
    static let volume = "volume"
    static let muted = "muted"
    static let resume = "resumePlayback"
    /// Durée maximale du différé en minutes (0 = sans limite).
    static let timeshiftMax = "timeshift.maxMinutes"
    static let catchUpSpeed = "timeshift.catchUpSpeed"
}

/// Réglages du direct en différé.
enum TimeshiftSettings {
    static var maxMinutes: Int { UserDefaults.standard.object(forKey: PlaybackKeys.timeshiftMax) as? Int ?? 120 }
    static var catchUpSpeed: Float {
        let value = UserDefaults.standard.object(forKey: PlaybackKeys.catchUpSpeed) as? Double ?? 1.5
        return Float(min(max(value, 1.25), 2))
    }
    /// Dossier des fichiers du différé (dossier temporaire de l'application).
    static var folder: URL { URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true) }
    static let speeds: [Float] = [1, 1.25, 1.5, 2]

    static func label(_ rate: Float) -> String {
        rate == 1 ? "×1" : "×" + String(format: rate == 1.25 ? "%.2f" : "%.1f", rate).replacingOccurrences(of: ".", with: ",")
    }
}

/// Relais des événements VLC (objet Objective-C) vers le contrôleur.
final class VLCEventBridge: NSObject, VLCMediaPlayerDelegate {
    var onState: ((VLCMediaPlayerState) -> Void)?
    var onTime: (() -> Void)?
    var onRecordingStopped: ((String?) -> Void)?
    var onRecordingStarted: (() -> Void)?

    /// VLC peut transmettre un chemin vide ou nul : il est donc optionnel ici.
    func mediaPlayer(_ player: VLCMediaPlayer, recordingStoppedAtPath path: String?) {
        DispatchQueue.main.async { [weak self] in self?.onRecordingStopped?(path) }
    }

    func mediaPlayerStartedRecording(_ player: VLCMediaPlayer) {
        DispatchQueue.main.async { [weak self] in self?.onRecordingStarted?() }
    }

    func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let player = aNotification.object as? VLCMediaPlayer else { return }
        let state = player.state
        DispatchQueue.main.async { [weak self] in self?.onState?(state) }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        DispatchQueue.main.async { [weak self] in self?.onTime?() }
    }
}

/// Pilote le moteur de lecture VLC (VLCKit) : direct MPEG-TS, HLS, MP4, MKV, AVI…
/// Une seule connexion au fournisseur à la fois : le flux précédent est toujours fermé avant d'ouvrir le suivant.
@MainActor
@Observable
final class PlaybackController {
    @ObservationIgnored let player: VLCMediaPlayer
    @ObservationIgnored private let bridge = VLCEventBridge()

    private(set) var current: MediaItem?
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    private(set) var isPlaying = false
    private(set) var elapsed: TimeInterval = 0
    /// Durée totale (0 pour le direct).
    private(set) var duration: TimeInterval = 0
    private(set) var position: Double = 0
    private(set) var isSeekable = false
    /// Temps entre la demande de lecture et la première image (mesuré à chaque démarrage).
    private(set) var startupTime: TimeInterval?
    /// Le flux accepte la pause (direct en différé si le moteur le permet).
    private(set) var canPause = false
    /// Retard accumulé sur le direct (pauses), en secondes.
    private(set) var liveDelay: TimeInterval = 0
    /// Début de la pause en cours sur le direct.
    private(set) var pausedAt: Date?
    /// Position à laquelle la lecture a repris (films et épisodes), le temps d'afficher l'information.
    private(set) var resumedAt: TimeInterval?
    /// Mémoire des positions de lecture (injectée au démarrage).
    @ObservationIgnored var watchProgress: WatchProgressStore?
    /// Appelé quand VLC a fini d'écrire un enregistrement (chemin du fichier).
    @ObservationIgnored var onRecordingStopped: ((String?) -> Void)?
    @ObservationIgnored var onRecordingStarted: (() -> Void)?

    /// Santé du flux (débit, définition, images perdues, coupures), mesurée toutes les 2 s.
    private(set) var health = StreamHealth()
    /// Pistes audio et sous-titres du flux en cours.
    private(set) var audioTracks: [PlayerTrack] = []
    private(set) var subtitleTracks: [PlayerTrack] = []
    private(set) var currentAudioTrack: Int32 = -1
    private(set) var currentSubtitleTrack: Int32 = -1
    @ObservationIgnored private var healthTask: Task<Void, Never>?
    @ObservationIgnored private var lastPictures: (displayed: Int, lost: Int)?
    @ObservationIgnored private var bufferingEvents: [Date] = []
    /// Mesure de la session en cours, pour ajuster la qualité automatique des chaînes.
    @ObservationIgnored private var sessionQuality: ChannelQuality?
    @ObservationIgnored private var sessionSamples = 0
    @ObservationIgnored private var sessionPoor = 0

    var isLive: Bool { current?.kind == .live && !(current?.streamURL?.isFileURL ?? false) }
    var isTimeshifted: Bool { isLive && (liveDelay > 0.5 || pausedAt != nil) }

    func delay(at date: Date) -> TimeInterval {
        liveDelay + (pausedAt.map { date.timeIntervalSince($0) } ?? 0)
    }

    // MARK: - Différé : vitesse, rattrapage, déplacement

    /// Vitesse de lecture (1 = normale ; plus rapide pour rattraper le direct).
    private(set) var rate: Float = 1
    /// Retard visé par le rattrapage en cours (0 = le direct).
    private(set) var catchUpTarget: TimeInterval?
    /// Plus grand retard atteint depuis le début du différé (longueur de la timeline).
    private(set) var peakDelay: TimeInterval = 0
    /// Le moteur sait se déplacer dans le différé (sinon on avance en accélérant).
    private(set) var timeshiftSeekable = false
    /// Message bref affiché dans la barre (vitesse refusée, différé maximal atteint…).
    var timeshiftNotice: String?
    @ObservationIgnored private var timeshiftTask: Task<Void, Never>?
    @ObservationIgnored private var lastTimeshiftTick = Date()

    /// Change la vitesse de lecture du différé (impossible d'aller plus vite que le direct).
    func setRate(_ value: Float) {
        guard isLive, player.media != nil else { return }
        if value > 1 {
            guard isTimeshifted else { return }
            if pausedAt != nil { togglePause() }
        } else {
            catchUpTarget = nil
        }
        applyRate(max(value, 1))
    }

    /// Avance dans le différé jusqu'à un retard donné (0 = le direct) : saut direct si le moteur le permet,
    /// sinon lecture accélérée jusqu'à la position visée.
    func catchUp(toDelay target: TimeInterval) {
        guard isLive, isTimeshifted, player.media != nil else { return }
        if pausedAt != nil { togglePause() }
        let now = delay(at: Date())
        peakDelay = max(peakDelay, now)
        let goal = min(max(0, target), peakDelay)
        if timeshiftSeekable {
            let shift = now - goal
            if shift > 0 { player.jumpForward(Int32(shift.rounded())) } else if shift < 0 { player.jumpBackward(Int32((-shift).rounded())) }
            liveDelay = goal
            PlaybackLog.shared.note(String(format: "Différé : déplacement à −%.0f s", goal))
            if goal < 1 { finishCatchUp(reachedLive: true) }
            return
        }
        guard now - goal > 1 else { return }
        catchUpTarget = goal
        applyRate(max(rate, TimeshiftSettings.catchUpSpeed))
        PlaybackLog.shared.note(String(format: "Différé : rattrapage de −%.0f s à −%.0f s", now, goal))
    }

    private func applyRate(_ value: Float) {
        tickTimeshift()
        rate = value
        player.rate = value
        PlaybackLog.shared.note("Vitesse de lecture : \(TimeshiftSettings.label(value))")
        if value != 1 {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.5))
                guard let self, self.rate == value, self.player.media != nil else { return }
                if abs(self.player.rate - value) > 0.05 {
                    PlaybackLog.shared.note("Vitesse refusée par le moteur (\(self.player.rate))")
                    self.rate = 1
                    self.catchUpTarget = nil
                    self.timeshiftNotice = String(localized: "Ce flux ne permet pas d'accélérer la lecture.")
                }
            }
        }
        startTimeshiftTicker()
    }

    private func finishCatchUp(reachedLive: Bool) {
        catchUpTarget = nil
        if rate != 1 {
            rate = 1
            player.rate = 1
        }
        if reachedLive {
            liveDelay = 0
            peakDelay = 0
            timeshiftNotice = String(localized: "Direct rattrapé")
            PlaybackLog.shared.note("Différé : direct rattrapé")
        }
    }

    private func startTimeshiftTicker() {
        guard timeshiftTask == nil else { return }
        lastTimeshiftTick = Date()
        timeshiftTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { return }
                if !self.tickTimeshift() {
                    self.timeshiftTask = nil
                    return
                }
            }
        }
    }

    /// Met à jour le retard (lecture accélérée), la fin du rattrapage et la limite du différé.
    /// Renvoie vrai tant qu'il faut continuer à surveiller.
    @discardableResult
    private func tickTimeshift() -> Bool {
        let now = Date()
        let elapsedTime = now.timeIntervalSince(lastTimeshiftTick)
        lastTimeshiftTick = now
        guard isLive, player.media != nil else { return false }
        if isPlaying, pausedAt == nil, rate > 1 {
            liveDelay = max(0, liveDelay - elapsedTime * Double(rate - 1))
        }
        let current = delay(at: now)
        peakDelay = max(peakDelay, current)
        if let target = catchUpTarget, current <= target + 0.5 {
            finishCatchUp(reachedLive: target < 1)
        } else if rate > 1, current < 1 {
            finishCatchUp(reachedLive: true)
        }
        let maxMinutes = TimeshiftSettings.maxMinutes
        if maxMinutes > 0, pausedAt != nil, current >= Double(maxMinutes * 60) {
            togglePause()
            timeshiftNotice = String(localized: "Différé maximal atteint (\(maxMinutes) min) : la lecture reprend.")
            PlaybackLog.shared.note("Différé maximal atteint : reprise de la lecture")
        }
        return pausedAt != nil || rate != 1 || catchUpTarget != nil
    }

    private func resetTimeshift() {
        timeshiftTask?.cancel()
        timeshiftTask = nil
        rate = 1
        catchUpTarget = nil
        peakDelay = 0
        timeshiftSeekable = false
        timeshiftNotice = nil
    }

    var volume: Double {
        didSet {
            applyAudio()
            UserDefaults.standard.set(volume, forKey: PlaybackKeys.volume)
        }
    }
    var isMuted: Bool {
        didSet {
            applyAudio()
            UserDefaults.standard.set(isMuted, forKey: PlaybackKeys.muted)
        }
    }

    @ObservationIgnored private var startedAt: Date?
    @ObservationIgnored private var didStart = false
    @ObservationIgnored private var pendingResume: TimeInterval?
    @ObservationIgnored private var ignoreProgressUntil = Date.distantPast
    @ObservationIgnored private var lastProgressSave = Date.distantPast
    @ObservationIgnored private var fallbacks: [URL] = []
    @ObservationIgnored private var currentURL: URL?
    @ObservationIgnored private var watchdog: Task<Void, Never>?
    /// Délai maximal sans image avant d'abandonner (ou d'essayer la variante suivante).
    static let startTimeout: TimeInterval = 20

    init() {
        let defaults = UserDefaults.standard
        volume = defaults.object(forKey: PlaybackKeys.volume) as? Double ?? 100
        isMuted = defaults.bool(forKey: PlaybackKeys.muted)
        player = VLCMediaPlayer(options: ["--no-video-title-show", "--no-snapshot-preview"])
        player.libraryInstance.setHumanReadableName("Kastideo", withHTTPUserAgent: HTTP.userAgent)
        player.libraryInstance.loggers = [PlaybackLog.shared]
        StreamRelay.shared.start()
        player.delegate = bridge
        bridge.onState = { [weak self] state in
            MainActor.assumeIsolated { self?.handle(state) }
        }
        bridge.onTime = { [weak self] in
            MainActor.assumeIsolated { self?.handleTime() }
        }
        bridge.onRecordingStopped = { [weak self] path in
            MainActor.assumeIsolated { self?.onRecordingStopped?(path) }
        }
        bridge.onRecordingStarted = { [weak self] in
            MainActor.assumeIsolated { self?.onRecordingStarted?() }
        }
        // En quittant Kastideo, on ferme proprement le flux pour que le fournisseur libère la connexion.
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                StreamRelay.shared.closeAll()
                guard let self, self.player.media != nil else { return }
                VideoContainerView.ensureHosted(for: self.player)
                self.player.stop()
                PlaybackLog.shared.note("Flux fermé à la fermeture de Kastideo")
            }
        }
    }

    // MARK: - Commandes

    func play(_ item: MediaItem) {
        guard let url = item.streamURL else { return }
        if current?.id == item.id, errorMessage == nil, player.media != nil {
            if !player.isPlaying { player.play() }
            return
        }
        flushProgress()
        current = item
        resumedAt = nil
        pendingResume = nil
        if WatchProgressStore.isEnabled, item.kind != .live, let point = watchProgress?.resumePoint(for: item.id) {
            pendingResume = point
        }
        fallbacks = Self.alternatives(for: url)
        sameURLRetries = 0
        start(url)
    }

    func stop() {
        flushProgress()
        pendingResume = nil
        resumedAt = nil
        watchdog?.cancel()
        openTask?.cancel()
        openTask = nil
        pausedAt = nil
        liveDelay = 0
        resetTimeshift()
        if player.media != nil { streamClosedAt = Date() }
        StreamRelay.shared.closeAll()
        if player.media != nil, !isStopping {
            // L'arrêt d'un flux réseau peut prendre plusieurs secondes dans le moteur VLC : il se fait
            // en arrière-plan pour ne jamais bloquer l'interface (passage du Direct aux Films, etc.).
            VideoContainerView.ensureHosted(for: player)
            isStopping = true
            let engine = player
            let begin = Date()
            Task.detached(priority: .userInitiated) {
                engine.stop()
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isStopping = false
                    if self.current == nil { self.player.media = nil }
                    let elapsed = Date().timeIntervalSince(begin)
                    if elapsed > 1 { PlaybackLog.shared.note("Arrêt du moteur : \(String(format: "%.1f", elapsed)) s") }
                }
            }
        }
        current = nil
        errorMessage = nil
        isLoading = false
        isPlaying = false
        resetTimeline()
    }

    func togglePause() {
        guard player.media != nil else { return }
        if player.isPlaying {
            guard canPause || !isLive else { return }
            player.pause()
            if isLive {
                pausedAt = Date()
                startTimeshiftTicker()
            }
        } else {
            player.play()
            if let pausedAt {
                liveDelay += Date().timeIntervalSince(pausedAt)
                self.pausedAt = nil
            }
        }
    }

    /// Revient au direct (rouvre le flux) après une pause.
    func goLive() {
        guard isLive, let url = current?.streamURL else { return }
        if timeshiftSeekable, isTimeshifted, player.media != nil {
            // Le moteur sait se déplacer dans le différé : on saute au direct en gardant ce qui est en mémoire.
            catchUp(toDelay: 0)
            return
        }
        fallbacks = Self.alternatives(for: url)
        sameURLRetries = 0
        start(url)
    }

    /// Démarre l'enregistrement du flux en cours (même connexion), dans un dossier de travail.
    /// Vrai quand le flux est ouvert et l'image affichée : l'enregistrement peut alors démarrer.
    var canRecord: Bool { player.media != nil && didStart && !isStopping }
    /// Arrêt du moteur en cours (en arrière-plan).
    @ObservationIgnored private var isStopping = false

    /// VLCKit renvoie souvent `false` alors que l'enregistrement a bien démarré : le résultat n'est donc qu'indicatif
    /// et c'est la présence du fichier qui fait foi (voir RecordingCenter).
    @discardableResult
    func startRecording(into directory: URL) -> Bool {
        guard canRecord else { return false }
        let accepted = player.startRecording(atPath: directory.path)
        PlaybackLog.shared.note("Enregistrement : démarrage demandé dans \(directory.path) (retour VLC : \(accepted))")
        return accepted
    }

    @discardableResult
    func stopRecording() -> Bool {
        let accepted = player.stopRecording()
        PlaybackLog.shared.note("Enregistrement : arrêt demandé (retour VLC : \(accepted))")
        return accepted
    }

    func retry() {
        guard let item = current else { return }
        current = nil
        play(item)
    }

    /// Position relative (0…1) dans un film ou un épisode.
    func seek(to fraction: Double) {
        guard isSeekable else { return }
        player.position = Float(min(max(fraction, 0), 1))
    }

    /// Reprend le contenu depuis le début et oublie la position mémorisée.
    func restartFromBeginning() {
        guard let item = current, isSeekable else { return }
        player.position = 0
        resumedAt = nil
        ignoreProgressUntil = Date().addingTimeInterval(3)
        watchProgress?.clear(item.id)
    }

    func dismissResumeNotice() {
        resumedAt = nil
    }

    /// Enregistre la position courante (film ou épisode) avant de changer de contenu.
    private func flushProgress() {
        if let item = current, item.kind != .live, pendingResume == nil, duration > 0, elapsed > 1,
           Date() >= ignoreProgressUntil {
            watchProgress?.update(id: item.id, position: elapsed, duration: duration)
        }
        watchProgress?.flush()
    }

    func jump(seconds: Int) {
        if isLive, player.media != nil {
            // Direct en différé : se déplacer dans ce qui a été mis en mémoire.
            if timeshiftSeekable, isTimeshifted || seconds < 0 {
                let now = delay(at: Date())
                let goal = min(max(now - Double(seconds), 0), max(peakDelay, now))
                if pausedAt != nil { togglePause() }
                if seconds > 0 { player.jumpForward(Int32(seconds)) } else { player.jumpBackward(Int32(-seconds)) }
                liveDelay = goal
                peakDelay = max(peakDelay, goal)
                if goal < 1 { finishCatchUp(reachedLive: true) }
            } else if seconds > 0, isTimeshifted {
                catchUp(toDelay: delay(at: Date()) - Double(seconds))
            }
            return
        }
        guard isSeekable else { return }
        if seconds >= 0 { player.jumpForward(Int32(seconds)) } else { player.jumpBackward(Int32(-seconds)) }
    }

    // MARK: - Interne

    /// Délai laissé au serveur pour libérer la connexion précédente (abonnement à une connexion) :
    /// sans lui, le fournisseur refuse le nouveau flux (HTTP 404/403) parce qu'il compte encore l'ancien.
    static let releaseDelay: TimeInterval = 1.5
    @ObservationIgnored private var streamClosedAt: Date?
    @ObservationIgnored private var openTask: Task<Void, Never>?
    @ObservationIgnored private var sameURLRetries = 0

    private func start(_ url: URL, delay extra: TimeInterval = 0) {
        // Une seule connexion autorisée par l'abonnement : on ferme d'abord le flux en cours
        // (y compris un arrêt encore en cours en arrière-plan).
        openTask?.cancel()
        openTask = nil
        watchdog?.cancel()
        if player.media != nil || isStopping {
            VideoContainerView.ensureHosted(for: player)
            player.stop()
            player.media = nil
            isStopping = false
            streamClosedAt = Date()
            StreamRelay.shared.closeAll()
        }
        errorMessage = nil
        isLoading = true
        isPlaying = false
        didStart = false
        resetTimeline()
        currentURL = url
        let since = streamClosedAt.map { Date().timeIntervalSince($0) } ?? .infinity
        let wait = max(extra, Self.releaseDelay - since)
        guard wait > 0.05 else {
            open(url)
            return
        }
        PlaybackLog.shared.note(String(format: "Attente de %.1f s pour que le serveur libère la connexion précédente", wait))
        openTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled, let self, self.currentURL == url, self.current != nil else { return }
            self.open(url)
        }
    }

    private func open(_ url: URL) {
        openTask = nil
        errorMessage = nil
        isLoading = true
        isPlaying = false
        startupTime = nil
        didStart = false
        canPause = false
        liveDelay = 0
        pausedAt = nil
        resetTimeshift()
        startedAt = Date()
        currentURL = url
        resetTimeline()

        let caching = BufferingMode.current.networkCaching
        let source = StreamRelay.shared.playbackURL(for: url, live: current?.kind == .live)
        PlaybackLog.shared.note("Ouverture de \(url.absoluteString) — tampon \(caching) ms\(source == url ? "" : " (via le relais)")")
        let media = VLCMedia(url: source)
        media.addOption(":network-caching=\(caching)")
        media.addOption(":live-caching=\(caching)")
        media.addOption(":http-user-agent=\(HTTP.userAgent)")
        media.addOption(":http-reconnect")
        if let item = current, item.kind == .live, Self.clockFixIDs.contains(item.id) {
            // Horloge du flux faussée (son jeté) : VLC se cale sur les horodatages du son et de l'image.
            media.addOption(":no-ts-trust-pcr")
            PlaybackLog.shared.note("Ouverture sans l'horloge du fournisseur (son réparé pour cette chaîne)")
        }
        // Direct en différé : VLC met le flux en mémoire sur disque pendant les pauses.
        media.addOption(":input-timeshift-path=\(NSTemporaryDirectory())")
        media.addOption(":input-timeshift-granularity=52428800")
        player.media = media
        player.rate = 1
        applyAudio()
        player.play()

        // Délai de garde : sans image au bout de 20 s, on essaie la variante suivante ou on abandonne.
        watchdog?.cancel()
        watchdog = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.startTimeout))
            guard !Task.isCancelled else { return }
            self?.startTimedOut(url)
        }
    }

    private func startTimedOut(_ url: URL) {
        guard currentURL == url, !didStart, errorMessage == nil else { return }
        PlaybackLog.shared.note("Aucune image après \(Int(Self.startTimeout)) s")
        if !fallbacks.isEmpty {
            start(fallbacks.removeFirst())
            return
        }
        VideoContainerView.ensureHosted(for: player)
        player.stop()
        isLoading = false
        isPlaying = false
        var message = String(localized: "Aucune image reçue après \(Int(Self.startTimeout)) secondes. Le serveur ne répond pas pour cette chaîne, ou refuse la connexion (abonnement limité à une connexion : vérifiez qu'aucun autre appareil — TV, Piboard… — ne regarde).")
        if let startedAt, let detail = PlaybackLog.shared.lastError(since: startedAt) {
            message += String(localized: "\n\nDétail : \(detail)")
        }
        errorMessage = message
    }

    private func resetTimeline() {
        stopHealthSampling()
        elapsed = 0
        duration = 0
        position = 0
        isSeekable = false
    }

    private func applyAudio() {
        if let audio = player.audio as VLCAudio? {
            audio.volume = Int32(min(max(volume, 0), 200))
            audio.isMuted = isMuted
        }
    }

    private func handle(_ state: VLCMediaPlayerState) {
        guard player.media != nil, current != nil, !isStopping else { return }
        if state != .buffering || !didStart { PlaybackLog.shared.note("État : \(Self.stateName(state))") }
        switch state {
        case .opening, .buffering:
            if !didStart { isLoading = true } else if state == .buffering { bufferingEvents.append(Date()) }
        case .playing:
            isPlaying = true
            markStarted()
            applyAudio()
        case .paused:
            isPlaying = false
        case .error:
            let detail = startedAt.flatMap { PlaybackLog.shared.lastError(since: $0) }
            if let url = currentURL, sameURLRetries < 1, Self.isRefusal(detail) {
                // Refus du serveur : souvent l'ancienne connexion n'est pas encore libérée. On patiente puis on réessaie.
                sameURLRetries += 1
                PlaybackLog.shared.note("Flux refusé par le serveur : nouvel essai dans 2 s")
                start(url, delay: 2.0 * Double(sameURLRetries))
                return
            }
            if !fallbacks.isEmpty {
                sameURLRetries = 1 // variante (.m3u8) : un seul essai
                start(fallbacks.removeFirst())
                return
            }
            watchdog?.cancel()
            isLoading = false
            isPlaying = false
            var message = Self.describe(url: currentURL)
            if let startedAt, let detail = PlaybackLog.shared.lastError(since: startedAt) {
                message += String(localized: "\n\nDétail : \(detail)")
            }
            errorMessage = message
        case .ended:
            isLoading = false
            isPlaying = false
            if current?.kind == .live {
                errorMessage = String(localized: "Le flux s'est interrompu. Le serveur a peut-être coupé la connexion.")
            }
        case .stopped:
            isPlaying = false
        default:
            break
        }
    }

    private func markStarted() {
        guard !didStart else { return }
        didStart = true
        watchdog?.cancel()
        isLoading = false
        if let startedAt {
            startupTime = Date().timeIntervalSince(startedAt)
            PlaybackLog.shared.note(String(format: "Lecture démarrée en %.2f s", startupTime ?? 0))
        }
        startHealthSampling()
    }

    // MARK: - Santé du flux et pistes

    private func startHealthSampling() {
        healthTask?.cancel()
        sessionQuality = (current?.kind == .live) ? current.map { ChannelQuality.of($0.name) } : nil
        sessionSamples = 0
        sessionPoor = 0
        lastPictures = nil
        bufferingEvents = []
        audioChecks = 0
        audioRepairs = 0
        lastLateAudio = nil
        triedAudioTracks = []
        lastAudio = nil
        audioIssue = nil
        healthTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.sampleHealth()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private func stopHealthSampling() {
        adjustAutoQuality()
        healthTask?.cancel()
        healthTask = nil
        health = StreamHealth()
        audioTracks = []
        subtitleTracks = []
        userDisabledAudio = false
        currentAudioTrack = -1
        currentSubtitleTrack = -1
    }

    private func sampleHealth() {
        guard let media = player.media, current != nil, didStart, !isStopping else { return }
        let stats = media.statistics
        var next = StreamHealth()
        next.bitrateKbps = Double(stats.inputBitrate) * 8000
        let size = player.videoSize
        if size.width > 0, size.height > 0 { next.resolution = size }
        let displayed = Int(stats.displayedPictures)
        let lost = Int(stats.lostPictures)
        if let previous = lastPictures {
            let shown = max(displayed - previous.displayed, 0)
            let dropped = max(lost - previous.lost, 0)
            next.lostRatio = shown + dropped > 0 ? Double(dropped) / Double(shown + dropped) : 0
            next.framesPerSecond = Double(shown) / 2
        }
        lastPictures = (displayed, lost)
        let now = Date()
        bufferingEvents.removeAll { now.timeIntervalSince($0) > 60 }
        next.recentStalls = bufferingEvents.count
        next.isPaused = !isPlaying
        next.evaluate()
        refreshTracks()
        checkAudio(stats)
        next.audioIssue = audioIssue
        health = next
        if sessionQuality != nil {
            sessionSamples += 1
            if next.level == .poor { sessionPoor += 1 }
        }
    }

    private func refreshTracks() {
        func tracks(_ names: [Any], _ indexes: [Any]) -> [PlayerTrack] {
            zip(indexes, names).compactMap { index, name in
                guard let id = (index as? NSNumber)?.int32Value else { return nil }
                return PlayerTrack(id: id, name: (name as? String) ?? "Piste \(id)")
            }
        }
        let audio = tracks(player.audioTrackNames, player.audioTrackIndexes)
        let subtitles = tracks(player.videoSubTitlesNames, player.videoSubTitlesIndexes)
        if audio != audioTracks { audioTracks = audio }
        if subtitles != subtitleTracks { subtitleTracks = subtitles }
        if currentAudioTrack != player.currentAudioTrackIndex { currentAudioTrack = player.currentAudioTrackIndex }
        if currentSubtitleTrack != player.currentVideoSubTitleIndex { currentSubtitleTrack = player.currentVideoSubTitleIndex }
    }

    /// Qualité automatique : un cran plus bas après une lecture instable, un cran plus haut après
    /// trois lectures fluides d'au moins 5 minutes à la qualité retenue.
    private func adjustAutoQuality() {
        guard let quality = sessionQuality, sessionSamples >= 15 else { sessionQuality = nil; return }
        let defaults = UserDefaults.standard
        var tier = defaults.object(forKey: QualityPreference.autoTierKey) as? Int ?? ChannelQuality.fhd.rawValue
        var streak = defaults.integer(forKey: "live.autoTier.goodStreak")
        let poorRatio = Double(sessionPoor) / Double(sessionSamples)
        if poorRatio > 0.3 {
            tier = max(min(tier, quality.rawValue - 1), ChannelQuality.sd.rawValue)
            streak = 0
            PlaybackLog.shared.note("Qualité automatique : réception instable en \(quality.label), qualité visée abaissée")
        } else if sessionPoor == 0, sessionSamples >= 150, quality.rawValue >= tier {
            streak += 1
            if streak >= 3, tier < ChannelQuality.uhd.rawValue {
                tier += 1
                streak = 0
                PlaybackLog.shared.note("Qualité automatique : réception fluide, qualité visée relevée")
            }
        }
        defaults.set(tier, forKey: QualityPreference.autoTierKey)
        defaults.set(streak, forKey: "live.autoTier.goodStreak")
        sessionQuality = nil
    }

    func selectAudioTrack(_ id: Int32) {
        player.currentAudioTrackIndex = id
        currentAudioTrack = id
        userDisabledAudio = id < 0
        audioIssue = nil
    }

    // MARK: - Son absent : diagnostic et réparation automatique

    /// Problème de son détecté (affiché dans la pastille de santé et le panneau d'informations).
    private(set) var audioIssue: String?
    @ObservationIgnored private var audioChecks = 0
    @ObservationIgnored private var audioRepairs = 0
    @ObservationIgnored private var triedAudioTracks = Set<Int32>()
    @ObservationIgnored private var lastAudio: (decoded: Int, played: Int)?
    @ObservationIgnored private var userDisabledAudio = false
    @ObservationIgnored private var lastLateAudio: Int?
    /// Chaînes dont l'horloge (PCR) est fausse : on les ouvre sans s'y fier (mémorisé d'une session à l'autre).
    static var clockFixIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "audio.clockFix") ?? []) }
        set { UserDefaults.standard.set(Array(newValue.suffix(500)), forKey: "audio.clockFix") }
    }
    static let maxAudioRepairs = 4

    /// Toutes les 2 s : si aucun son n'est joué alors que l'image avance, on cherche pourquoi et on tente
    /// de réparer (sortie audio non créée → relance de la piste ; piste vide → piste suivante).
    private func checkAudio(_ stats: VLCMedia.Stats) {
        let decoded = Int(stats.decodedAudio)
        let played = Int(stats.playedAudioBuffers)
        let previous = lastAudio
        lastAudio = (decoded, played)
        let late = PlaybackLog.shared.lateAudioDrops()
        let newLate = late - (lastLateAudio ?? late)
        lastLateAudio = late
        // Son décodé mais jeté par VLC : l'horloge (PCR) du flux est fausse — des heures d'écart avec le son.
        // Le remède est de rouvrir la chaîne en laissant VLC caler son horloge sur le son et l'image (sans le PCR).
        if newLate >= 20, isLive, let item = current, !Self.clockFixIDs.contains(item.id), let url = currentURL {
            Self.clockFixIDs.insert(item.id)
            PlaybackLog.shared.note("Son : \(newLate) blocs son jetés en 2 s (horloge du flux faussée) — réouverture sans l'horloge du fournisseur")
            audioIssue = nil
            sameURLRetries = 1
            sessionQuality = nil   // ne pas compter cette lecture dans la qualité automatique
            start(url)
            return
        }
        guard isPlaying, pausedAt == nil, !userDisabledAudio else { return }
        audioChecks += 1
        if audioChecks == 2 { logAudioTracks() }
        guard let previous, audioChecks >= 3 else { return }
        let newDecoded = decoded - previous.decoded
        let newPlayed = played - previous.played
        if newPlayed > 0 {
            if audioIssue != nil {
                audioIssue = nil
                PlaybackLog.shared.note("Son : rétabli")
            }
            return
        }
        let realTracks = audioTracks.filter { $0.id >= 0 }
        if realTracks.isEmpty {
            if audioIssue == nil {
                audioIssue = String(localized: "Ce flux ne contient aucune piste son (problème chez le fournisseur).")
                PlaybackLog.shared.note("Son : aucune piste audio dans le flux")
            }
            return
        }
        guard audioRepairs < Self.maxAudioRepairs else {
            if audioIssue == nil {
                audioIssue = String(localized: "Son absent : le fournisseur envoie une piste son vide ou illisible. Essayez une autre version de la chaîne (HD, SD…).")
                PlaybackLog.shared.note("Son : toujours absent après \(Self.maxAudioRepairs) tentatives (décodé \(decoded), joué \(played))")
            }
            return
        }
        audioRepairs += 1
        let currentTrack = player.currentAudioTrackIndex
        if newDecoded > 0 || realTracks.count == 1 {
            // Le son est décodé (ou il n'y a qu'une piste) mais rien n'est joué : la sortie audio n'a pas pu être
            // créée au démarrage (« too low audio sample frequency (0) »). On relance la piste.
            let track = currentTrack >= 0 ? currentTrack : realTracks[0].id
            PlaybackLog.shared.note("Son : \(newDecoded) bloc(s) décodé(s) mais rien joué — relance de la piste \(track) (essai \(audioRepairs)/\(Self.maxAudioRepairs))")
            player.currentAudioTrackIndex = -1
            let media = player.media
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(300))
                guard let self, self.player.media === media else { return }
                self.player.currentAudioTrackIndex = track
                self.currentAudioTrack = track
                self.applyAudio()
            }
        } else {
            // Rien n'est décodé sur cette piste : on essaie la suivante.
            triedAudioTracks.insert(currentTrack)
            if let next = realTracks.first(where: { !triedAudioTracks.contains($0.id) }) {
                PlaybackLog.shared.note("Son : rien décodé sur la piste \(currentTrack) — essai de « \(next.name) »")
                player.currentAudioTrackIndex = next.id
                currentAudioTrack = next.id
                applyAudio()
            } else {
                triedAudioTracks = []
            }
        }
    }

    /// Note dans le journal le format des pistes son (codec, fréquence, canaux) pour le diagnostic.
    private func logAudioTracks() {
        guard let info = player.media?.tracksInformation else { return }
        var parts: [String] = []
        for case let track as [String: Any] in info where (track["type"] as? String) == "audio" {
            let codec = (track["codec"] as? NSNumber).map { Self.fourCC($0.uint32Value) } ?? "?"
            let rate = (track["rate"] as? NSNumber)?.intValue ?? 0
            let channels = (track["channels_number"] as? NSNumber)?.intValue ?? 0
            let language = (track["language"] as? String).map { " \($0)" } ?? ""
            parts.append("\(codec) \(rate) Hz \(channels) canal(aux)\(language)")
        }
        let names = audioTracks.map(\.name).joined(separator: ", ")
        PlaybackLog.shared.note("Son : \(parts.isEmpty ? "aucune piste audio annoncée" : parts.joined(separator: " ; ")) — pistes : \(names.isEmpty ? "aucune" : names)")
    }

    static func fourCC(_ value: UInt32) -> String {
        let bytes = [value & 0xff, (value >> 8) & 0xff, (value >> 16) & 0xff, (value >> 24) & 0xff]
        let text = String(bytes.compactMap { UnicodeScalar($0).map(Character.init) }).trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? "?" : text
    }

    func selectSubtitleTrack(_ id: Int32) {
        player.currentVideoSubTitleIndex = id
        currentSubtitleTrack = id
    }

    private func handleTime() {
        markStarted()
        elapsed = Double(player.time.intValue) / 1000
        let length = player.media?.length.intValue ?? 0
        duration = length > 0 ? Double(length) / 1000 : 0
        position = Double(player.position)
        isSeekable = player.isSeekable && duration > 0
        timeshiftSeekable = isLive && player.isSeekable
        canPause = player.canPause
        trackProgress()
    }

    /// Reprise à la dernière position, puis mémorisation régulière de la position.
    private func trackProgress() {
        guard let item = current, item.kind != .live else { return }
        if let pending = pendingResume {
            guard isSeekable, duration > 0 else { return }
            let target = min(pending, max(duration - 10, 0))
            player.position = Float(target / duration)
            pendingResume = nil
            resumedAt = target
            ignoreProgressUntil = Date().addingTimeInterval(3)
            return
        }
        let now = Date()
        guard now >= ignoreProgressUntil, duration > 0, elapsed > 1,
              now.timeIntervalSince(lastProgressSave) >= 5 else { return }
        lastProgressSave = now
        watchProgress?.update(id: item.id, position: elapsed, duration: duration)
    }

    /// Variantes à tenter si le flux échoue (.ts ↔ .m3u8 pour le direct).
    static func alternatives(for url: URL) -> [URL] {
        let ext = url.pathExtension.lowercased()
        var list: [URL] = []
        if ext == "ts" {
            list = [url.deletingPathExtension().appendingPathExtension("m3u8")]
        } else if ext == "m3u8", url.path.contains("/live/") {
            list = [url.deletingPathExtension().appendingPathExtension("ts")]
        } else if ext.isEmpty, url.query == nil {
            list = [url.appendingPathExtension("ts")]
        }
        return list
    }

    /// Le serveur a refusé le flux (connexion précédente pas encore libérée, limite de connexions…) :
    /// cela vaut la peine de réessayer la même adresse un peu plus tard.
    static func isRefusal(_ detail: String?) -> Bool {
        guard let detail else { return false }
        return ["HTTP 401", "HTTP 403", "HTTP 404", "HTTP 429", "HTTP 458", "HTTP 509", "HTTP 520", "HTTP 503", "Forbidden", "unable to open"]
            .contains { detail.localizedCaseInsensitiveContains($0) }
    }

    static func stateName(_ state: VLCMediaPlayerState) -> String {
        switch state {
        case .stopped: return String(localized: "arrêté")
        case .opening: return "ouverture"
        case .buffering: return String(localized: "mise en mémoire tampon")
        case .ended: return String(localized: "terminé")
        case .error: return "erreur"
        case .playing: return "lecture"
        case .paused: return "pause"
        default: return String(localized: "autre (\(state.rawValue))")
        }
    }

    static func describe(url: URL?) -> String {
        String(localized: "Lecture impossible : le serveur n'a pas fourni le flux. Votre abonnement n'autorise peut-être qu'une connexion à la fois : vérifiez qu'aucun autre appareil ne regarde, puis réessayez.")
    }
}

extension TimeInterval {
    /// « 1:23:45 » ou « 12:34 ».
    var clockString: String {
        let total = Int(self.rounded(.down))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}


/// Piste audio ou de sous-titres.
struct PlayerTrack: Identifiable, Equatable {
    let id: Int32
    let name: String
}

/// État de santé du flux, présenté sans jargon (Excellent / Correct / Instable).
struct StreamHealth: Equatable {
    enum Level: Int { case unknown, poor, fair, good }

    var level: Level = .unknown
    var bitrateKbps: Double = 0
    var resolution: CGSize?
    var lostRatio: Double = 0
    var framesPerSecond: Double = 0
    var recentStalls = 0
    var isPaused = false
    /// Son absent (diagnostic).
    var audioIssue: String?

    mutating func evaluate() {
        if isPaused { level = .unknown; return }
        if recentStalls >= 3 || lostRatio > 0.08 {
            level = .poor
        } else if recentStalls >= 1 || lostRatio > 0.02 {
            level = .fair
        } else {
            level = .good
        }
    }

    var label: String {
        switch level {
        case .good: return String(localized: "Excellent")
        case .fair: return String(localized: "Correct")
        case .poor: return String(localized: "Instable")
        case .unknown: return String(localized: "En attente")
        }
    }

    /// Définition lisible : 4K, 1080p, 720p, SD.
    var qualityLabel: String? {
        guard let resolution else { return nil }
        let h = resolution.height
        if h >= 2000 { return "4K" }
        if h >= 1000 { return "Full HD 1080p" }
        if h >= 700 { return "HD 720p" }
        return "SD \(Int(h))p"
    }
}
