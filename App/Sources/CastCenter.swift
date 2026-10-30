import SwiftUI
import AppKit
import Darwin
import VLCKitSPM
import KastideoCore

/// Réglages du Cast (clés UserDefaults).
enum CastKeys {
    /// Façon de lancer YouTube sur le téléviseur : « dial » (application YouTube du téléviseur) ou « browser » (navigateur).
    static let youtubeMode = "cast.youtubeMode"
}

/// Un téléviseur ou boîtier trouvé par VLC (Chromecast, Google TV, TV Android).
struct CastRenderer: Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let item: VLCRendererItem

    static func == (a: CastRenderer, b: CastRenderer) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Relais des événements du découvreur VLC (objet Objective-C) vers CastCenter.
final class RendererBridge: NSObject, VLCRendererDiscovererDelegate {
    var onAdded: ((VLCRendererItem) -> Void)?
    var onDeleted: ((VLCRendererItem) -> Void)?

    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        DispatchQueue.main.async { [weak self] in self?.onAdded?(item) }
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        DispatchQueue.main.async { [weak self] in self?.onDeleted?(item) }
    }
}

/// Diffusion vers un téléviseur : recherche des appareils (VLC pour la vidéo, DIAL pour YouTube) et appareil actif.
/// VLC prépare lui-même la vidéo pour le Chromecast : le lecteur local est remplacé par le téléviseur, avec les mêmes commandes.
@MainActor
@Observable
final class CastCenter {
    static let shared = CastCenter()

    private(set) var renderers: [CastRenderer] = []
    private(set) var dialDevices: [DIALDevice] = []
    private(set) var isSearching = false
    /// Appareil qui reçoit la lecture en cours (nil : lecture sur le Mac).
    private(set) var active: CastRenderer?
    /// Dernier message d'erreur à afficher (effacé à la prochaine action).
    var message: String?

    @ObservationIgnored private var discoverers: [VLCRendererDiscoverer] = []
    @ObservationIgnored private let bridge = RendererBridge()
    @ObservationIgnored private var searchTask: Task<Void, Never>?

    var isCasting: Bool { active != nil }

    var youtubeMode: String {
        get { UserDefaults.standard.string(forKey: CastKeys.youtubeMode) ?? "dial" }
        set { UserDefaults.standard.set(newValue, forKey: CastKeys.youtubeMode) }
    }

    // MARK: Recherche

    func refresh() {
        guard !isSearching else { return }
        isSearching = true
        message = nil
        if discoverers.isEmpty { startDiscoverers() }
        searchTask = Task { [weak self] in
            let found = await DIALScanner.scan()
            guard let self else { return }
            self.dialDevices = found
            PlaybackLog.shared.note("Cast : \(self.renderers.count) appareil(s) vidéo, \(found.count) appareil(s) YouTube", topic: .playback)
            // Les Chromecast répondent en quelques secondes : on laisse VLC finir sa recherche.
            try? await Task.sleep(for: .seconds(2))
            self.isSearching = false
        }
    }

    private func startDiscoverers() {
        bridge.onAdded = { [weak self] item in MainActor.assumeIsolated { self?.add(item) } }
        bridge.onDeleted = { [weak self] item in MainActor.assumeIsolated { self?.remove(item) } }
        for entry in VLCRendererDiscoverer.list() ?? [] {
            guard let discoverer = VLCRendererDiscoverer(name: entry.name) else { continue }
            discoverer.delegate = bridge
            if discoverer.start() {
                discoverers.append(discoverer)
                PlaybackLog.shared.note("Cast : recherche « \(entry.longName) » lancée", topic: .playback)
            }
        }
        if discoverers.isEmpty { message = String(localized: "La recherche d'appareils n'a pas pu démarrer.") }
    }

    private func add(_ item: VLCRendererItem) {
        let id = "\(item.type)|\(item.name)"
        guard !renderers.contains(where: { $0.id == id }) else { return }
        renderers.append(CastRenderer(id: id, name: item.name, type: item.type, item: item))
        renderers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func remove(_ item: VLCRendererItem) {
        let id = "\(item.type)|\(item.name)"
        renderers.removeAll { $0.id == id }
        if active?.id == id { active = nil }
    }

    // MARK: Diffusion

    /// Envoie la lecture en cours sur l'appareil (nil : retour sur le Mac). La lecture reprend là où elle en était.
    func cast(to renderer: CastRenderer?, playback: PlaybackController) {
        message = nil
        active = renderer
        playback.setRenderer(renderer?.item)
        if let renderer {
            PlaybackLog.shared.note("Cast : diffusion sur « \(renderer.name) »", topic: .playback)
        } else {
            PlaybackLog.shared.note("Cast : retour de la lecture sur le Mac", topic: .playback)
        }
    }

    /// Ouvre les réglages d'écran du Mac, où l'on active la recopie vers une Apple TV (AirPlay).
    func openAirPlayDisplays() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: YouTube

    /// Envoie une vidéo YouTube : application YouTube du téléviseur (DIAL) ou navigateur selon les réglages.
    func castYouTube(_ video: YouTubeVideo, to device: DIALDevice?, start: Int = 0) async {
        message = nil
        if youtubeMode == "browser" || device == nil {
            NSWorkspace.shared.open(video.watchURL)
            return
        }
        guard let device else { return }
        var request = URLRequest(url: CastDIAL.youTubeLaunchURL(device), timeoutInterval: 8)
        request.httpMethod = "POST"
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(CastDIAL.youTubeBody(videoID: video.id, startSeconds: start).utf8)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch status {
            case 200, 201:
                PlaybackLog.shared.note("Cast : YouTube lancé sur « \(device.name) »", topic: .playback)
            case 404:
                message = String(localized: "L'application YouTube n'est pas installée sur ce téléviseur.")
            default:
                message = String(localized: "Le téléviseur a refusé (code \(status)).")
            }
        } catch {
            message = String(localized: "Le téléviseur ne répond pas.")
        }
    }
}

/// Recherche des appareils DIAL (SSDP en multidiffusion) : liste de téléviseurs qui savent ouvrir YouTube.
enum DIALScanner {
    static func scan(timeout: TimeInterval = 3) async -> [DIALDevice] {
        let locations = await Task.detached(priority: .utility) { DIALScanner.collectLocations(timeout: timeout) }.value
        var devices: [DIALDevice] = []
        for location in locations {
            if let device = await describe(location), !devices.contains(where: { $0.host == device.host }) { devices.append(device) }
        }
        return devices.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Envoie la requête M-SEARCH et rassemble les adresses « LOCATION » des réponses.
    private nonisolated static func collectLocations(timeout: TimeInterval) -> [String] {
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        guard fd >= 0 else { return [] }
        defer { close(fd) }
        var receiveTimeout = timeval(tv_sec: 0, tv_usec: 300_000)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &receiveTimeout, socklen_t(MemoryLayout<timeval>.size))
        var ttl: Int32 = 4
        setsockopt(fd, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, socklen_t(MemoryLayout<Int32>.size))
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = CastDIAL.multicastPort.bigEndian
        address.sin_addr.s_addr = inet_addr(CastDIAL.multicastAddress)
        let request = Array(CastDIAL.searchRequest.utf8)
        let sent = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sendto(fd, request, request.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard sent >= 0 else { return [] }
        var found: [String] = []
        var buffer = [UInt8](repeating: 0, count: 4096)
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            let count = recv(fd, &buffer, buffer.count, 0)
            guard count > 0, let text = String(bytes: buffer[0..<count], encoding: .utf8),
                  let location = CastDIAL.header("location", in: text), !found.contains(location) else { continue }
            found.append(location)
        }
        return found
    }

    /// Lit la description de l'appareil : nom affiché et adresse des applications (en-tête « Application-URL »).
    private static func describe(_ location: String) async -> DIALDevice? {
        guard let url = URL(string: location), let host = url.host else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 4)
        request.httpMethod = "GET"
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              let header = http.value(forHTTPHeaderField: "Application-URL"),
              let applications = CastDIAL.applicationURL(from: header) else { return nil }
        let name = CastDIAL.friendlyName(inXML: String(decoding: data, as: UTF8.self)) ?? host
        return DIALDevice(name: name, host: host, applicationURL: applications)
    }
}

// MARK: - Interface

/// Bouton de la barre de lecture : menu des téléviseurs trouvés, arrêt de la diffusion, recopie AirPlay.
struct CastMenuButton: View {
    @Environment(PlaybackController.self) private var playback
    private let cast = CastCenter.shared

    var body: some View {
        Menu {
            if let active = cast.active {
                Button {
                    cast.cast(to: nil, playback: playback)
                } label: {
                    Label("Arrêter la diffusion sur « \(active.name) »", systemImage: "rectangle.badge.xmark")
                }
                Divider()
            }
            if cast.renderers.isEmpty {
                if cast.isSearching { Text("Recherche des téléviseurs…") } else { Text("Aucun téléviseur trouvé") }
            }
            ForEach(cast.renderers) { renderer in
                Button {
                    cast.cast(to: renderer, playback: playback)
                } label: {
                    if cast.active == renderer {
                        Label(renderer.name, systemImage: "checkmark")
                    } else {
                        Label(renderer.name, systemImage: "tv")
                    }
                }
            }
            Divider()
            Button("Chercher à nouveau") { cast.refresh() }
            Button("Apple TV : recopie d'écran AirPlay…") { cast.openAirPlayDisplays() }
            HelpLink(title: "Aide : diffuser sur un téléviseur", page: "cast")
        } label: {
            Image(systemName: cast.isCasting ? "tv.and.mediabox.fill" : "tv")
                .foregroundStyle(cast.isCasting ? Color.orange : Color.white)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(cast.active.map { String(localized: "Diffusion sur « \($0.name) »") } ?? String(localized: "Diffuser sur un téléviseur (Chromecast, Google TV…)"))
        .onAppear { cast.refresh() }
    }
}

/// Voile affiché à la place de l'image pendant une diffusion.
struct CastOverlay: View {
    @Environment(PlaybackController.self) private var playback
    private let cast = CastCenter.shared

    var body: some View {
        if let active = cast.active, playback.current != nil {
            VStack(spacing: 12) {
                Image(systemName: "tv.and.mediabox.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.orange)
                Text("Diffusion sur « \(active.name) »")
                    .font(.title3.weight(.semibold))
                if let name = playback.current?.name {
                    Text(name).foregroundStyle(.secondary).lineLimit(2).multilineTextAlignment(.center)
                }
                Button("Reprendre sur le Mac") { cast.cast(to: nil, playback: playback) }
                    .buttonStyle(.bordered)
            }
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
    }
}

/// Réglages > Général > Cast.
struct CastSettingsSection: View {
    @AppStorage(CastKeys.youtubeMode) private var youtubeMode = "dial"
    private let cast = CastCenter.shared

    var body: some View {
        Section("Cast (diffusion sur un téléviseur)") {
            Picker("YouTube sur le téléviseur", selection: $youtubeMode) {
                Text("Application YouTube du téléviseur").tag("dial")
                Text("Navigateur (bouton Diffuser de Chrome)").tag("browser")
            }
            LabeledContent("Appareils trouvés") {
                HStack {
                    Text("\(cast.renderers.count) vidéo, \(cast.dialDevices.count) YouTube").foregroundStyle(.secondary)
                    Button("Chercher") { cast.refresh() }.disabled(cast.isSearching)
                    if cast.isSearching { ProgressView().controlSize(.small) }
                }
            }
            ForEach(cast.renderers) { renderer in
                Label(renderer.name, systemImage: "tv").font(.caption)
            }
            Text("Le bouton « téléviseur » de la barre de lecture envoie la chaîne, le film, la série ou la vidéo en cours vers un Chromecast, un Google TV ou une TV Android du même réseau : VLC prépare la vidéo, aucune installation n'est nécessaire. Pour une Apple TV, utilisez la recopie d'écran AirPlay de macOS (l'image du Mac est alors reproduite sur le téléviseur).")
                .font(.caption)
                .foregroundStyle(.secondary)
            HelpLink(title: "Aide : diffuser sur un téléviseur", page: "cast")
        }
        .onAppear { cast.refresh() }
    }
}
