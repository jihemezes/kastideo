import AVFoundation
import Observation
import KastideoCore

/// Pilote le lecteur vidéo natif (AVPlayer : HLS .m3u8, MP4, MOV…).
@MainActor
@Observable
final class PlaybackController {
    let player = AVPlayer()
    private(set) var current: MediaItem?
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    private(set) var isPaused = false

    private var statusObservation: NSKeyValueObservation?
    private var timeObservation: NSKeyValueObservation?
    /// URL alternatives à essayer si le flux d'origine échoue (ex. .ts → .m3u8).
    private var fallbacks: [URL] = []
    private var currentURL: URL?

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
        timeObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor in
                guard let self else { return }
                self.isPaused = status == .paused
                if status == .playing { self.isLoading = false }
            }
        }
    }

    func play(_ item: MediaItem) {
        guard let url = item.streamURL else { return }
        if current?.id == item.id, player.currentItem != nil, errorMessage == nil {
            player.play()
            return
        }
        current = item
        fallbacks = Self.alternatives(for: url)
        start(url)
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        statusObservation = nil
        current = nil
        errorMessage = nil
        isLoading = false
    }

    func togglePause() {
        guard player.currentItem != nil else { return }
        if player.timeControlStatus == .paused { player.play() } else { player.pause() }
    }

    func retry() {
        guard let item = current else { return }
        current = nil
        play(item)
    }

    private func start(_ url: URL) {
        errorMessage = nil
        isLoading = true
        currentURL = url
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": HTTP.userAgent]])
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 4
        statusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] observed, _ in
            let status = observed.status
            let error = observed.error
            Task { @MainActor in self?.handle(status: status, error: error, url: url) }
        }
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }

    private func handle(status: AVPlayerItem.Status, error: Error?, url: URL) {
        guard url == currentURL else { return }
        switch status {
        case .readyToPlay:
            isLoading = false
        case .failed:
            if !fallbacks.isEmpty {
                start(fallbacks.removeFirst())
                return
            }
            isLoading = false
            errorMessage = Self.describe(error, url: url)
        default:
            break
        }
    }

    /// Variantes à tenter : beaucoup de serveurs IPTV proposent le même flux en HLS.
    static func alternatives(for url: URL) -> [URL] {
        let ext = url.pathExtension.lowercased()
        if ext == "ts" {
            return [url.deletingPathExtension().appendingPathExtension("m3u8")]
        }
        if ext.isEmpty, url.query == nil {
            return [url.appendingPathExtension("m3u8")]
        }
        return []
    }

    static func describe(_ error: Error?, url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if ["ts", "mkv", "avi", "wmv", "flv"].contains(ext) {
            return "Ce flux (.\(ext)) n'est pas pris en charge par le lecteur natif d'Apple. Les formats HLS (.m3u8) et MP4 fonctionnent. Un moteur de lecture étendu est prévu dans une prochaine version."
        }
        if ext == "m3u8", url.path.contains("/live/") {
            return "Lecture impossible. Certains fournisseurs ne diffusent le direct qu'au format MPEG-TS (.ts), que le lecteur natif d'Apple ne sait pas lire. Un moteur de lecture étendu est prévu dans une prochaine version."
        }
        if let error {
            return "Lecture impossible : \(error.localizedDescription)"
        }
        return "Lecture impossible : le flux ne répond pas."
    }
}
