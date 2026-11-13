import SwiftUI
import VLCKitSPM
import KastideoCore
#if canImport(AppKit)
import AppKit
#endif

/// Réglages MultiVue : un nombre de connexions simultanées par source (abonnement), 4 flux au plus en tout.
enum MultiViewKeys {
    /// Ancien réglage global : devient la valeur par défaut des abonnements (Xtream, M3U avec identifiants).
    static let connections = "multiview.connections"
    static let totalMax = 4
    static var legacyCount: Int { min(max(UserDefaults.standard.integer(forKey: connections), 1), totalMax) }

    private static func key(_ id: UUID) -> String { "multiview.max." + id.uuidString }

    /// Une liste M3U avec identifiants dans l'adresse (get.php?username=…) est un abonnement à connexions limitées.
    static func isSubscription(_ source: Source) -> Bool {
        switch source.kind {
        case .xtream: return true
        case .m3uURL(let url):
            let text = url.absoluteString.lowercased()
            return text.contains("username=") || text.contains("get.php") || text.contains("password=")
        default: return false
        }
    }

    /// Valeur choisie pour la source, sinon la valeur par défaut de son type.
    static func defaultLimit(for source: Source) -> Int { isSubscription(source) ? legacyCount : totalMax }

    /// Flux simultanés autorisés pour une source (listes publiques : jusqu'à 4 ; abonnement : sa limite).
    static func limit(for source: Source?) -> Int {
        guard let source else { return legacyCount }
        let stored = UserDefaults.standard.integer(forKey: key(source.id))
        return min(max(stored > 0 ? stored : defaultLimit(for: source), 1), totalMax)
    }

    static func setLimit(_ value: Int, for source: Source) {
        UserDefaults.standard.set(min(max(value, 1), totalMax), forKey: key(source.id))
    }

    /// Sources de direct actives.
    static func liveSources(_ sources: [Source]) -> [Source] { sources.filter { $0.isEnabled && $0.kind.isIPTV } }

    /// Nom + identifiant du compte (deux abonnements peuvent porter le même nom).
    static func accountLabel(_ source: Source) -> String {
        switch source.kind {
        case .xtream(_, let user):
            return user.isEmpty ? source.name : "\(source.name) · \(user)"
        case .m3uURL(let url):
            let user = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "username" }?.value ?? ""
            return user.isEmpty ? source.name : "\(source.name) · \(user)"
        default:
            return source.name
        }
    }

    /// Nombre d'écrans possible : somme des connexions des sources, 4 au plus.
    static func maxScreens(_ sources: [Source]) -> Int {
        min(totalMax, liveSources(sources).reduce(0) { $0 + limit(for: $1) })
    }

    /// Vrai si au moins deux flux peuvent tourner en même temps (deux sources, ou une source qui en autorise plusieurs).
    static func isAvailable(sources: [Source]) -> Bool {
        let live = sources.filter { $0.isEnabled && $0.kind.isIPTV }
        return live.reduce(0) { $0 + limit(for: $1) } >= 2
    }
}

/// Un flux de la MultiVue : son propre lecteur VLC et sa vue vidéo.
@MainActor
@Observable
final class MultiViewSlot: Identifiable {
    let id = UUID()
    private(set) var item: MediaItem?
    /// Source réservée à cet écran (ses chaînes seules sont proposées).
    var sourceID: UUID?
    /// Disposition PIP : coin où la vignette est accrochée, et déplacement en cours (glisser).
    var pipCorner: PipCorner = .bottomRight
    var drag: CGSize = .zero
    private(set) var isLoading = false
    private(set) var failed = false
    @ObservationIgnored let player: VLCMediaPlayer
    #if os(macOS)
    @ObservationIgnored let videoView: VLCVideoView
    #else
    @ObservationIgnored let videoView: UIView
    #endif
    @ObservationIgnored private let bridge = VLCEventBridge()

    init() {
        player = VLCMediaPlayer(options: ["--no-video-title-show", "--no-snapshot-preview"])
        player.libraryInstance.setHumanReadableName("Kastideo", withHTTPUserAgent: HTTP.userAgent)
        #if os(macOS)
        videoView = VLCVideoView(frame: .zero)
        videoView.backColor = .black
        videoView.fillScreen = false
        videoView.autoresizingMask = [.width, .height]
        #else
        videoView = UIView(frame: .zero)
        videoView.backgroundColor = .black
        #endif
        player.drawable = videoView
        player.delegate = bridge
        bridge.onState = { [weak self] state in
            MainActor.assumeIsolated { self?.handle(state) }
        }
        bridge.onTime = { [weak self] in
            MainActor.assumeIsolated { self?.isLoading = false }
        }
    }

    @ObservationIgnored private var startTask: Task<Void, Never>?
    @ObservationIgnored private var stoppedAt = Date.distantPast

    func play(_ item: MediaItem, muted: Bool) {
        guard let url = item.streamURL else { return }
        // Un flux était ouvert sur cet écran : on laisse au fournisseur le temps de libérer la connexion.
        stop()
        self.item = item
        failed = false
        isLoading = true
        let media = VLCMedia(url: url)
        let caching = BufferingMode.current.networkCaching
        media.addOption(":network-caching=\(caching)")
        media.addOption(":live-caching=\(caching)")
        media.addOption(":http-user-agent=\(HTTP.userAgent)")
        media.addOption(":http-reconnect")
        let wait = max(0, 1.2 - Date().timeIntervalSince(stoppedAt))
        PlaybackLog.shared.note("MultiVue : ouverture de \(item.name)")
        startTask = Task { @MainActor [weak self] in
            if wait > 0 { try? await Task.sleep(for: .milliseconds(Int(wait * 1000))) }
            guard !Task.isCancelled, let self else { return }
            self.startTask = nil
            self.player.media = media
            self.setMuted(muted)
            self.player.play()
        }
    }

    @ObservationIgnored private var muted = true

    func setMuted(_ muted: Bool) {
        self.muted = muted
        player.audio?.isMuted = muted
    }

    func stop() {
        startTask?.cancel()
        startTask = nil
        if item != nil { stoppedAt = Date() }
        guard player.media != nil else {
            item = nil
            isLoading = false
            return
        }
        let engine = player
        Task.detached(priority: .userInitiated) { engine.stop() }
        item = nil
        isLoading = false
    }

    private func handle(_ state: VLCMediaPlayerState) {
        switch state {
        case .playing:
            isLoading = false
            // La sortie audio n'existe qu'une fois la lecture lancée : on réapplique la coupure du son.
            player.audio?.isMuted = muted
        case .error:
            isLoading = false
            failed = true
        default: break
        }
    }
}

/// Dispositions de la MultiVue.
enum MultiViewLayout: String, CaseIterable, Identifiable {
    case sideBySide, stacked, grid, focus
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sideBySide: return String(localized: "Côte à côte")
        case .stacked: return String(localized: "Empilé")
        case .grid: return String(localized: "Grille")
        case .focus: return String(localized: "Une grande + vignettes (PIP)")
        }
    }
    var icon: String {
        switch self {
        case .sideBySide: return "rectangle.split.2x1"
        case .stacked: return "rectangle.split.1x2"
        case .grid: return "rectangle.split.2x2"
        case .focus: return "rectangle.leadinghalf.inset.filled"
        }
    }
}

/// Coin où une vignette PIP s'accroche.
enum PipCorner: String {
    case topLeft, topRight, bottomLeft, bottomRight
    var isRight: Bool { self == .topRight || self == .bottomRight }
    var isBottom: Bool { self == .bottomLeft || self == .bottomRight }
    static func nearest(x: CGFloat, y: CGFloat, in size: CGSize) -> PipCorner {
        switch (x > size.width / 2, y > size.height / 2) {
        case (false, false): return .topLeft
        case (true, false): return .topRight
        case (false, true): return .bottomLeft
        case (true, true): return .bottomRight
        }
    }
}

/// Taille des vignettes PIP (part de la largeur de la fenêtre).
enum PipSize: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { rawValue }
    var label: String {
        switch self {
        case .small: return String(localized: "Petites")
        case .medium: return String(localized: "Moyennes")
        case .large: return String(localized: "Grandes")
        }
    }
    var fraction: CGFloat {
        switch self {
        case .small: return 0.16
        case .medium: return 0.22
        case .large: return 0.30
        }
    }
}

/// MultiVue : jusqu'à 4 écrans, chacun réservé à une source ; le son suit la vignette active.
@MainActor
@Observable
final class MultiViewModel {
    private(set) var slots: [MultiViewSlot] = []
    var focusedID: UUID?
    var pickerSlotID: UUID?
    var layout: MultiViewLayout = MultiViewLayout(rawValue: UserDefaults.standard.string(forKey: "multiview.layout") ?? "") ?? .grid {
        didSet { UserDefaults.standard.set(layout.rawValue, forKey: "multiview.layout") }
    }
    /// Écran affiché en grand dans la disposition PIP (le premier par défaut).
    var bigID: UUID?
    var pipSize: PipSize = PipSize(rawValue: UserDefaults.standard.string(forKey: "multiview.pipsize") ?? "") ?? .medium {
        didSet { UserDefaults.standard.set(pipSize.rawValue, forKey: "multiview.pipsize") }
    }
    private(set) var screenCount = max(UserDefaults.standard.integer(forKey: "multiview.screens"), 2)

    /// Cases de la grille : 4 au plus.
    var capacity: Int { MultiViewKeys.totalMax }

    /// Écrans déjà réservés à une source (hors l'écran indiqué).
    func assignedCount(source: UUID, excluding slotID: UUID? = nil) -> Int {
        slots.filter { $0.id != slotID && $0.sourceID == source }.count
    }

    /// Première source de direct qui a encore une connexion à réserver.
    func freeSource(store: LibraryStore, excluding slotID: UUID? = nil) -> UUID? {
        MultiViewKeys.liveSources(store.sources).first { assignedCount(source: $0.id, excluding: slotID) < MultiViewKeys.limit(for: $0) }?.id
    }

    /// Prépare les écrans à l'ouverture de la fenêtre.
    func ensureScreens(store: LibraryStore) {
        setScreenCount(max(screenCount, slots.count), store: store)
    }

    /// Fixe le nombre d'écrans (les nouveaux sont réservés à la première source disponible).
    func setScreenCount(_ wanted: Int, store: LibraryStore) {
        let target = min(max(wanted, 1), max(MultiViewKeys.maxScreens(store.sources), 1))
        while slots.count > target, let last = slots.last { remove(last.id) }
        while slots.count < target {
            let slot = MultiViewSlot()
            slot.sourceID = freeSource(store: store)
            slots.append(slot)
            if focusedID == nil { focusedID = slot.id }
        }
        screenCount = target
        UserDefaults.standard.set(target, forKey: "multiview.screens")
    }

    /// Réserve un écran à une source ; faux si toutes ses connexions sont déjà réservées.
    @discardableResult
    func assign(_ slotID: UUID, to source: UUID, store: LibraryStore) -> Bool {
        guard let slot = slots.first(where: { $0.id == slotID }), let src = store.source(id: source) else { return false }
        guard slot.sourceID == source || assignedCount(source: source, excluding: slotID) < MultiViewKeys.limit(for: src) else { return false }
        slot.sourceID = source
        if let item = slot.item, item.sourceID != source { slot.stop() }
        return true
    }

    /// Vrai si la chaîne peut être lue sur cet écran (celui-ci est réservé à sa source).
    func canPlay(_ item: MediaItem, on slotID: UUID) -> Bool {
        slots.first { $0.id == slotID }?.sourceID == item.sourceID
    }

    /// Ajoute une chaîne : dans un écran libre de sa source, sinon dans un écran vide réaffecté, sinon dans un nouvel écran.
    @discardableResult
    func add(_ item: MediaItem, store: LibraryStore) -> Bool {
        if slots.contains(where: { $0.item?.id == item.id }) { return true }
        guard let source = store.source(id: item.sourceID) else { return false }
        if let own = slots.first(where: { $0.item == nil && $0.sourceID == item.sourceID }) {
            own.play(item, muted: own.id != focusedID)
            return true
        }
        let quota = MultiViewKeys.limit(for: source)
        guard assignedCount(source: item.sourceID) < quota else { return false }
        if let empty = slots.first(where: { $0.item == nil }) {
            empty.sourceID = item.sourceID
            empty.play(item, muted: empty.id != focusedID)
            return true
        }
        guard slots.count < MultiViewKeys.maxScreens(store.sources) else { return false }
        let slot = MultiViewSlot()
        slot.sourceID = item.sourceID
        slots.append(slot)
        screenCount = slots.count
        if focusedID == nil { focusedID = slot.id }
        slot.play(item, muted: slot.id != focusedID)
        return true
    }

    func replace(_ slotID: UUID, with item: MediaItem, store: LibraryStore) {
        guard let slot = slots.first(where: { $0.id == slotID }), canPlay(item, on: slotID) else { return }
        slot.play(item, muted: slot.id != focusedID)
    }

    func remove(_ slotID: UUID) {
        guard let index = slots.firstIndex(where: { $0.id == slotID }) else { return }
        slots[index].stop()
        slots[index].videoView.removeFromSuperview()
        slots.remove(at: index)
        if focusedID == slotID { focus(slots.first?.id) }
    }

    /// Donne le son à une vignette (les autres sont coupées).
    func focus(_ id: UUID?) {
        focusedID = id
        for slot in slots { slot.setMuted(slot.id != id) }
    }

    /// Met un écran en grand (disposition PIP) et lui donne le son.
    func makeBig(_ id: UUID) {
        bigID = id
        focus(id)
    }

    func focus(index: Int) {
        guard slots.indices.contains(index) else { return }
        focus(slots[index].id)
    }

    func stopAll() {
        for slot in slots {
            slot.stop()
            slot.videoView.removeFromSuperview()
        }
        slots = []
        focusedID = nil
        bigID = nil
    }

    /// Rectangles des écrans selon la disposition.
    func frames(in size: CGSize, spacing: CGFloat = 4) -> [CGRect] {
        let n = slots.count
        guard n > 0 else { return [] }
        let w = size.width, h = size.height
        if n == 1 { return [CGRect(x: 0, y: 0, width: w, height: h)] }
        // Zone en portrait (iPad ou iPhone tenu droit) : côte à côte et grille donneraient des vidéos minuscules
        // en hauteur ; les écrans sont alors empilés, chacun pleine largeur.
        let effective: MultiViewLayout = (h > w * 1.1 && (layout == .sideBySide || layout == .grid)) ? .stacked : layout
        switch effective {
        case .sideBySide:
            let cw = (w - spacing * CGFloat(n - 1)) / CGFloat(n)
            return (0..<n).map { CGRect(x: CGFloat($0) * (cw + spacing), y: 0, width: cw, height: h) }
        case .stacked:
            let ch = (h - spacing * CGFloat(n - 1)) / CGFloat(n)
            return (0..<n).map { CGRect(x: 0, y: CGFloat($0) * (ch + spacing), width: w, height: ch) }
        case .grid:
            let columns = 2
            let rows = Int(ceil(Double(n) / Double(columns)))
            let cw = (w - spacing) / 2
            let ch = (h - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            return (0..<n).map { i in
                let row = i / columns, col = i % columns
                // Dernière ligne incomplète : l'écran seul prend toute la largeur.
                let alone = (i == n - 1) && n % columns == 1
                return CGRect(x: alone ? 0 : CGFloat(col) * (cw + spacing), y: CGFloat(row) * (ch + spacing),
                              width: alone ? w : cw, height: ch)
            }
        case .focus:
            // Un écran en grand ; les autres en vignettes 16:9 flottantes, accrochées aux coins.
            let big = slots.firstIndex { $0.id == bigID } ?? 0
            let margin: CGFloat = 12, gap: CGFloat = 8
            let pw = min(max(w * pipSize.fraction, 200), w / 2)
            let ph = pw * 9 / 16
            var result = [CGRect](repeating: .zero, count: n)
            var used: [PipCorner: Int] = [:]
            for i in 0..<n {
                if i == big {
                    result[i] = CGRect(x: 0, y: 0, width: w, height: h)
                    continue
                }
                let corner = slots[i].pipCorner
                let k = CGFloat(used[corner, default: 0])
                used[corner, default: 0] += 1
                var x = corner.isRight ? w - margin - pw - k * (pw + gap) : margin + k * (pw + gap)
                let y = corner.isBottom ? h - margin - ph : margin
                x = min(max(x, 0), max(w - pw, 0))
                let d = slots[i].drag
                result[i] = CGRect(x: x + d.width, y: y + d.height, width: pw, height: ph)
            }
            return result
        }
    }
}

