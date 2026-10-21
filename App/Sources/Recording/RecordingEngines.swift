import Foundation
import VLCKitSPM
import KastideoCore

/// Enregistre une chaîne en direct sans l'afficher (enregistrement programmé), avec le moteur VLC.
/// En cas de coupure, la connexion est rouverte et l'enregistrement continue dans un nouveau segment.
@MainActor
final class BackgroundRecorder {
    private var player: VLCMediaPlayer?
    private let bridge = VLCEventBridge()
    private let workDir: URL
    private var url: URL?
    private var stopping = false
    private(set) var segments: [URL] = []

    init(workDir: URL) {
        self.workDir = workDir
        bridge.onState = { [weak self] state in
            MainActor.assumeIsolated { self?.handle(state) }
        }
    }

    func start(url: URL) {
        self.url = url
        stopping = false
        openSegment()
    }

    /// Arrête l'enregistrement et renvoie les segments non vides.
    func stop() -> [URL] {
        stopping = true
        player?.stop()
        player = nil
        return segments.filter { ((try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) > 0 }
    }

    private func openSegment() {
        guard let url, !stopping else { return }
        let output = workDir.appendingPathComponent("part\(segments.count + 1).ts")
        segments.append(output)
        PlaybackLog.shared.note("Enregistrement en arrière-plan : segment \(segments.count) de \(url.absoluteString)")
        let recorder = VLCMediaPlayer(options: ["--no-video-title-show"])
        recorder.libraryInstance.setHumanReadableName("Kastideo", withHTTPUserAgent: HTTP.userAgent)
        let media = VLCMedia(url: url)
        media.addOption(":sout=#std{access=file,mux=ts,dst=\"\(output.path)\"}")
        media.addOption(":sout-all")
        media.addOption(":http-user-agent=\(HTTP.userAgent)")
        media.addOption(":http-reconnect")
        media.addOption(":network-caching=3000")
        recorder.delegate = bridge
        recorder.media = media
        player = recorder
        recorder.play()
    }

    private func handle(_ state: VLCMediaPlayerState) {
        guard !stopping else { return }
        guard state == .error || state == .ended else { return }
        PlaybackLog.shared.note("Enregistrement en arrière-plan interrompu (\(PlaybackController.stateName(state))) : nouvelle tentative dans 5 s")
        player?.stop()
        player = nil
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard let self, !self.stopping else { return }
            self.openSegment()
        }
    }
}

/// Conversion d'un enregistrement .ts en .mp4 sans réencodage (changement de conteneur), avec VLC.
/// Les sous-titres DVB et le télétexte (incompatibles avec le MP4) sont écartés ; en cas d'échec,
/// un second essai ne garde que la vidéo et la piste audio principales.
@MainActor
final class Remuxer {
    private var player: VLCMediaPlayer?
    private let bridge = VLCEventBridge()
    private var completion: ((Bool) -> Void)?
    private var input: URL?
    private var output: URL?
    private var attempt = 0
    private var timeout: Task<Void, Never>?
    private var watchdog: Task<Void, Never>?

    func run(input: URL, output: URL, completion: @escaping (Bool) -> Void) {
        self.completion = completion
        self.input = input
        self.output = output
        bridge.onState = { [weak self] state in
            MainActor.assumeIsolated { self?.handle(state) }
        }
        attempt = 0
        start()
    }

    private func start() {
        guard let input, let output else { return }
        attempt += 1
        try? FileManager.default.removeItem(at: output)
        let converter = VLCMediaPlayer(options: ["--no-video-title-show", "--no-sout-spu", "--no-spu"])
        let media = VLCMedia(url: input)
        // Vidéo copiée telle quelle ; son converti en AAC (le MP2 et certains AC-3 du direct sont muets dans QuickTime).
        media.addOption(":sout=#transcode{acodec=mp4a,ab=192,channels=2,samplerate=48000}:std{access=file,mux=mp4,dst=\"\(output.path)\"}")
        if attempt == 1 { media.addOption(":sout-all") } else { media.addOption(":no-sout-all") }
        media.addOption(":no-sout-spu")
        converter.delegate = bridge
        converter.media = media
        player = converter
        PlaybackLog.shared.note("Conversion en MP4 (essai \(attempt)) : \(output.lastPathComponent)")
        converter.play()
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4 * 3600))
            guard !Task.isCancelled else { return }
            self?.done(false, reason: "délai dépassé")
        }
        // Certains flux finissent sur « arrêté » sans « terminé » : on surveille la taille du fichier produit.
        watchdog?.cancel()
        watchdog = Task { [weak self] in
            var last: Int64 = -1
            var still = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self, let output = self.output else { return }
                let size = RecordingLocator.size(of: output)
                if size == last { still += 1 } else { still = 0; last = size }
                if still >= 6 { self.done(size > 64 * 1024, reason: "le fichier n'avance plus"); return }
            }
        }
    }

    private func handle(_ state: VLCMediaPlayerState) {
        switch state {
        case .ended: done(true, reason: nil)
        case .stopped: done(output.map { RecordingLocator.size(of: $0) > 64 * 1024 } ?? false, reason: "arrêt du moteur")
        case .error: done(false, reason: "erreur du moteur VLC")
        default: break
        }
    }

    private func done(_ success: Bool, reason: String?) {
        guard completion != nil else { return }
        timeout?.cancel()
        watchdog?.cancel()
        let finished = player
        player = nil
        finished?.delegate = nil
        finished?.stop()
        let size = output.map { RecordingLocator.size(of: $0) } ?? 0
        let ok = success && size > 64 * 1024
        if !ok, attempt < 2 {
            PlaybackLog.shared.note("Conversion en MP4 : échec (\(reason ?? "fichier vide")), nouvel essai avec les pistes principales")
            start()
            return
        }
        PlaybackLog.shared.note(ok ? "Conversion en MP4 réussie (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))"
                                   : "Conversion en MP4 impossible (\(reason ?? "fichier vide"))")
        let completion = self.completion
        self.completion = nil
        completion?(ok)
    }
}

/// Téléchargements HTTP (films, épisodes) avec reprise.
@MainActor
final class DownloadEngine {
    var onProgress: ((UUID, Int64, Int64) -> Void)?
    var onFinished: ((UUID, URL?, Error?) -> Void)?

    private let proxy = DownloadDelegateProxy()
    private var session: URLSession?
    private var task: URLSessionDownloadTask?
    private var currentID: UUID?

    init() {
        proxy.onProgress = { [weak self] written, expected in
            MainActor.assumeIsolated {
                guard let self, let id = self.currentID else { return }
                self.onProgress?(id, written, expected)
            }
        }
        proxy.onFinished = { [weak self] location, error in
            MainActor.assumeIsolated {
                guard let self, let id = self.currentID else { return }
                self.currentID = nil
                self.task = nil
                self.onFinished?(id, location, error)
            }
        }
    }

    var isActive: Bool { currentID != nil }

    func start(id: UUID, url: URL, resumeData: Data?) {
        let session = self.session ?? makeSession()
        self.session = session
        currentID = id
        if let resumeData {
            task = session.downloadTask(withResumeData: resumeData)
        } else {
            var request = URLRequest(url: url)
            request.setValue(HTTP.userAgent, forHTTPHeaderField: "User-Agent")
            request.setValue("*/*", forHTTPHeaderField: "Accept")
            task = session.downloadTask(with: request)
        }
        task?.resume()
    }

    /// Met en pause et renvoie les données de reprise.
    func pause(completion: @escaping (Data?) -> Void) {
        guard let task else { completion(nil); return }
        currentID = nil
        self.task = nil
        task.cancel(byProducingResumeData: { data in
            DispatchQueue.main.async { completion(data) }
        })
    }

    func cancel() {
        currentID = nil
        task?.cancel()
        task = nil
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 24 * 3600
        configuration.httpAdditionalHeaders = ["User-Agent": HTTP.userAgent, "Accept": "*/*"]
        return URLSession(configuration: configuration, delegate: proxy, delegateQueue: .main)
    }
}

/// Délégué URLSession (objet Objective-C) relayé vers DownloadEngine.
final class DownloadDelegateProxy: NSObject, URLSessionDownloadDelegate {
    var onProgress: ((Int64, Int64) -> Void)?
    var onFinished: ((URL?, Error?) -> Void)?
    private var lastProgress = Date.distantPast

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let http = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            onFinished?(nil, XtreamError.badResponse(http.statusCode))
            return
        }
        // Le fichier temporaire est supprimé au retour de cette méthode : on le déplace tout de suite.
        let kept = FileManager.default.temporaryDirectory.appendingPathComponent("kastideo-dl-\(UUID().uuidString)")
        do {
            try FileManager.default.moveItem(at: location, to: kept)
            onFinished?(kept, nil)
        } catch {
            onFinished?(nil, error)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let now = Date()
        guard now.timeIntervalSince(lastProgress) > 0.5 else { return }
        lastProgress = now
        onProgress?(totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        if (error as? URLError)?.code == .cancelled { return }
        onFinished?(nil, error)
    }
}

/// Données de reprise des téléchargements (fichiers dans Application Support).
enum ResumeStore {
    static func url(_ id: UUID) -> URL { Storage.directory.appendingPathComponent("resume-\(id.uuidString).data") }
    static func save(_ data: Data?, for id: UUID) {
        if let data { try? data.write(to: url(id), options: .atomic) } else { delete(id) }
    }
    static func load(_ id: UUID) -> Data? { try? Data(contentsOf: url(id)) }
    static func delete(_ id: UUID) { try? FileManager.default.removeItem(at: url(id)) }
}

/// Assemble plusieurs segments .ts (le format MPEG-TS se concatène directement).
enum SegmentJoiner {
    static func join(_ segments: [URL], into output: URL) throws {
        let manager = FileManager.default
        if segments.count == 1 {
            try manager.moveItem(at: segments[0], to: output)
            return
        }
        manager.createFile(atPath: output.path, contents: nil)
        let writer = try FileHandle(forWritingTo: output)
        defer { try? writer.close() }
        for segment in segments {
            let reader = try FileHandle(forReadingFrom: segment)
            while let chunk = try reader.read(upToCount: 8 * 1024 * 1024), !chunk.isEmpty {
                try writer.write(contentsOf: chunk)
            }
            try? reader.close()
            try? manager.removeItem(at: segment)
        }
    }
}
