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

    var isLive: Bool { current?.kind == .live && !(current?.streamURL?.isFileURL ?? false) }
    var isTimeshifted: Bool { isLive && (liveDelay > 0.5 || pausedAt != nil) }

    func delay(at date: Date) -> TimeInterval {
        liveDelay + (pausedAt.map { date.timeIntervalSince($0) } ?? 0)
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
        start(url)
    }

    func stop() {
        flushProgress()
        pendingResume = nil
        resumedAt = nil
        watchdog?.cancel()
        pausedAt = nil
        liveDelay = 0
        if player.media != nil { player.stop() }
        player.media = nil
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
            if isLive { pausedAt = Date() }
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
        fallbacks = Self.alternatives(for: url)
        start(url)
    }

    /// Démarre l'enregistrement du flux en cours (même connexion), dans un dossier de travail.
    /// Vrai quand le flux est ouvert et l'image affichée : l'enregistrement peut alors démarrer.
    var canRecord: Bool { player.media != nil && didStart }

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
        guard isSeekable else { return }
        if seconds >= 0 { player.jumpForward(Int32(seconds)) } else { player.jumpBackward(Int32(-seconds)) }
    }

    // MARK: - Interne

    private func start(_ url: URL) {
        // Une seule connexion autorisée par l'abonnement : on ferme d'abord le flux en cours.
        if player.media != nil { player.stop() }
        errorMessage = nil
        isLoading = true
        isPlaying = false
        startupTime = nil
        didStart = false
        canPause = false
        liveDelay = 0
        pausedAt = nil
        startedAt = Date()
        currentURL = url
        resetTimeline()

        let caching = BufferingMode.current.networkCaching
        PlaybackLog.shared.note("Ouverture de \(url.absoluteString) — tampon \(caching) ms")
        let media = VLCMedia(url: url)
        media.addOption(":network-caching=\(caching)")
        media.addOption(":live-caching=\(caching)")
        media.addOption(":http-user-agent=\(HTTP.userAgent)")
        media.addOption(":http-reconnect")
        // Direct en différé : VLC met le flux en mémoire sur disque pendant les pauses.
        media.addOption(":input-timeshift-path=\(NSTemporaryDirectory())")
        media.addOption(":input-timeshift-granularity=52428800")
        player.media = media
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
        guard player.media != nil else { return }
        if state != .buffering || !didStart { PlaybackLog.shared.note("État : \(Self.stateName(state))") }
        switch state {
        case .opening, .buffering:
            if !didStart { isLoading = true }
        case .playing:
            isPlaying = true
            markStarted()
            applyAudio()
        case .paused:
            isPlaying = false
        case .error:
            if !fallbacks.isEmpty {
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
    }

    private func handleTime() {
        markStarted()
        elapsed = Double(player.time.intValue) / 1000
        let length = player.media?.length.intValue ?? 0
        duration = length > 0 ? Double(length) / 1000 : 0
        position = Double(player.position)
        isSeekable = player.isSeekable && duration > 0
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
        if ext == "ts" {
            return [url.deletingPathExtension().appendingPathExtension("m3u8")]
        }
        if ext == "m3u8", url.path.contains("/live/") {
            return [url.deletingPathExtension().appendingPathExtension("ts")]
        }
        if ext.isEmpty, url.query == nil {
            return [url.appendingPathExtension("ts")]
        }
        return []
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
