import SwiftUI
import AppKit
import VLCKitSPM
import KastideoCore

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
    @ObservationIgnored let videoView: VLCVideoView
    @ObservationIgnored private let bridge = VLCEventBridge()

    init() {
        player = VLCMediaPlayer(options: ["--no-video-title-show", "--no-snapshot-preview"])
        player.libraryInstance.setHumanReadableName("Kastideo", withHTTPUserAgent: HTTP.userAgent)
        videoView = VLCVideoView(frame: .zero)
        videoView.backColor = .black
        videoView.fillScreen = false
        videoView.autoresizingMask = [.width, .height]
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
        switch layout {
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

/// Fenêtre MultiVue.
struct MultiViewWindow: View {
    @Environment(LibraryStore.self) private var store
    @Environment(MultiViewModel.self) private var model
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    var body: some View {
        let available = MultiViewKeys.isAvailable(sources: store.sources)
        Group {
            if !available {
                unavailable
            } else if model.slots.isEmpty {
                empty
            } else {
                grid
            }
        }
        .frame(minWidth: 720, minHeight: 440)
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("Disposition", selection: Binding(get: { model.layout }, set: { model.layout = $0 })) {
                    ForEach(MultiViewLayout.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
                }
                .pickerStyle(.menu)
                .help("Disposition des écrans")
                if model.layout == .focus {
                    Picker("Taille des vignettes", selection: Binding(get: { model.pipSize }, set: { model.pipSize = $0 })) {
                        ForEach(PipSize.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .help("Taille des vignettes PIP (glissez une vignette pour la déplacer, double-clic pour l'échanger avec la grande)")
                }
                Stepper(value: Binding(get: { model.screenCount },
                                       set: { model.setScreenCount($0, store: store) }),
                        in: 1...max(MultiViewKeys.maxScreens(store.sources), 1)) {
                    Text("Écrans : \(model.slots.count)")
                        .font(.callout.monospacedDigit())
                }
                Button {
                    model.stopAll()
                    model.ensureScreens(store: store)
                } label: {
                    Label("Tout arrêter", systemImage: "stop.fill")
                }
                .disabled(model.slots.allSatisfy { $0.item == nil })
            }
        }
        .navigationTitle("MultiVue")
        .onAppear {
            // Une connexion est libérée pour la MultiVue : la lecture principale s'arrête (sauf enregistrement).
            if MultiViewKeys.isAvailable(sources: store.sources), playback.current != nil, !recordings.isPlayerRecording {
                recordings.requestStop()
            }
        }
        .onAppear { if MultiViewKeys.isAvailable(sources: store.sources) { model.ensureScreens(store: store) } }
        .onDisappear { model.stopAll() }
        .background(keyShortcuts)
    }

    private var keyShortcuts: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Button("") { model.focus(index: index) }
                    .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: [])
                    .opacity(0)
            }
        }
        .allowsHitTesting(false)
    }

    private var grid: some View {
        GeometryReader { geo in
            let frames = model.frames(in: CGSize(width: geo.size.width, height: geo.size.height))
            ZStack(alignment: .topLeading) {
                ForEach(Array(model.slots.enumerated()), id: \.element.id) { index, slot in
                    if index < frames.count {
                        let isPip = model.layout == .focus && model.slots.count > 1
                            && slot.id != (model.slots.first { $0.id == model.bigID } ?? model.slots[0]).id
                        MultiViewTile(slot: slot, index: index, pip: isPip, area: geo.size)
                            .frame(width: max(frames[index].width, 1), height: max(frames[index].height, 1))
                            .offset(x: frames[index].minX, y: frames[index].minY)
                            .zIndex(isPip ? 1 : 0)
                    }
                }
            }
            .coordinateSpace(name: "multiviewArea")
        }
        .padding(4)
    }

    private var empty: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.split.2x2").font(.system(size: 54)).foregroundStyle(.white.opacity(0.5))
            Text("MultiVue").font(.title.weight(.bold))
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var unavailable: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.split.2x2").font(.system(size: 54)).foregroundStyle(.white.opacity(0.4))
            Text("MultiVue désactivée").font(.title2.weight(.bold))
            Text("Chaque abonnement n'autorise qu'une connexion à la fois : un second flux serait refusé par le serveur. Ajoutez une autre source de direct (liste publique, second abonnement) ou indiquez le nombre de connexions de votre abonnement dans Réglages > Général > Lecture.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 480)
            SettingsLink { Text("Ouvrir les réglages") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Vignette d'un flux de la MultiVue.
struct MultiViewTile: View {
    @Environment(MultiViewModel.self) private var model
    @Environment(LibraryStore.self) private var store
    let slot: MultiViewSlot
    let index: Int
    /// Vignette flottante de la disposition PIP (déplaçable, accrochée aux coins).
    var pip = false
    /// Taille de la zone d'affichage (pour accrocher la vignette au coin le plus proche).
    var area: CGSize = .zero
    @State private var hovering = false

    var body: some View {
        let focused = model.focusedID == slot.id
        ZStack {
            Color.black
            MultiViewVideo(slot: slot)
            // Couche de clic sous les boutons : un clic donne le son, un double-clic met l'écran en grand (PIP).
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { if model.layout == .focus { model.makeBig(slot.id) } else { model.focus(slot.id) } }
                .onTapGesture { model.focus(slot.id) }
            if slot.item == nil {
                Button {
                    model.pickerSlotID = slot.id
                } label: {
                    Label("Choisir une chaîne", systemImage: "plus.circle")
                        .font(pip ? .caption : .title3)
                }
                .buttonStyle(.bordered)
            } else if slot.isLoading {
                ProgressView().tint(.white)
            } else if slot.failed {
                Label("Flux refusé ou indisponible", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            overlay(focused: focused)
        }
        .clipShape(RoundedRectangle(cornerRadius: pip ? 10 : 0))
        .overlay(RoundedRectangle(cornerRadius: pip ? 10 : 0)
            .strokeBorder(focused ? KastideoPalette.orange : Color.white.opacity(pip ? 0.35 : 0.08), lineWidth: focused ? 3 : 1))
        .shadow(color: .black.opacity(pip ? 0.6 : 0), radius: pip ? 8 : 0)
        .onHover { hovering = $0 }
        .highPriorityGesture(pipDrag, including: pip ? .all : .subviews)
        .popover(isPresented: Binding(get: { model.pickerSlotID == slot.id },
                                      set: { if !$0, model.pickerSlotID == slot.id { model.pickerSlotID = nil } })) {
            MultiViewChannelPicker(slot: slot, onClose: { model.pickerSlotID = nil })
        }
    }

    /// Glisser une vignette PIP : elle suit la souris puis s'accroche au coin le plus proche.
    private var pipDrag: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("multiviewArea"))
            .onChanged { value in
                slot.drag = value.translation
            }
            .onEnded { value in
                slot.pipCorner = PipCorner.nearest(x: value.location.x, y: value.location.y, in: area)
                withAnimation(.easeOut(duration: 0.18)) { slot.drag = .zero }
            }
    }

    /// Source réservée à cet écran : un clic pour en changer (si plusieurs abonnements ou listes).
    @ViewBuilder
    private var sourceMenu: some View {
        let sources = MultiViewKeys.liveSources(store.sources)
        if sources.count > 1 {
            Menu {
                ForEach(sources) { source in
                    let full = slot.sourceID != source.id
                        && model.assignedCount(source: source.id, excluding: slot.id) >= MultiViewKeys.limit(for: source)
                    Button {
                        model.assign(slot.id, to: source.id, store: store)
                    } label: {
                        if slot.sourceID == source.id {
                            Label(MultiViewKeys.accountLabel(source), systemImage: "checkmark")
                        } else {
                            Text(MultiViewKeys.accountLabel(source) + (full ? " — " + String(localized: "connexions toutes réservées") : ""))
                        }
                    }
                    .disabled(full)
                }
            } label: {
                Text(slot.sourceID.flatMap { store.source(id: $0) }.map(MultiViewKeys.accountLabel) ?? String(localized: "Source"))
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.2), in: Capsule())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Source réservée à cet écran")
        }
    }

    private func overlay(focused: Bool) -> some View {
        VStack {
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.caption.weight(.heavy))
                    .frame(width: 20, height: 20)
                    .background(focused ? KastideoPalette.orange : Color.black.opacity(0.6), in: Circle())
                if let item = slot.item {
                    Text(item.name).font(.callout.weight(.semibold)).lineLimit(1)
                    if !pip, let programme = store.epg.current(for: item.epgID) {
                        Text("· \(programme.title)").font(.caption).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                    }
                }
                Spacer()
                if !pip { sourceMenu }
                Image(systemName: focused ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundStyle(focused ? .white : .white.opacity(0.5))
                if hovering {
                    Button {
                        model.pickerSlotID = slot.id
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .help("Changer de chaîne")
                    Button {
                        model.remove(slot.id)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .help("Retirer de la MultiVue")
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(LinearGradient(colors: [.black.opacity(0.75), .clear], startPoint: .top, endPoint: .bottom))
            Spacer()
        }
        .foregroundStyle(.white)
        .opacity(hovering || focused || slot.item == nil ? 1 : 0.0)
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

/// Vue vidéo d'une vignette : la même VLCVideoView est replacée dans le conteneur affiché.
struct MultiViewVideo: NSViewRepresentable {
    let slot: MultiViewSlot

    func makeNSView(context: Context) -> NSView {
        let container = NSView(frame: .zero)
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.cgColor
        attach(to: container)
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        attach(to: container)
    }

    private func attach(to container: NSView) {
        let view = slot.videoView
        guard view.superview !== container else { return }
        view.removeFromSuperview()
        view.frame = container.bounds
        container.addSubview(view)
    }
}

/// Choix d'une chaîne : catégories de la source de l'écran (comme dans l'interface Classique), favoris, récents et recherche.
/// Un clic lance la chaîne sur l'écran sans fermer le sélecteur (pour zapper) ; un double-clic la lance et ferme.
struct MultiViewChannelPicker: View {
    @Environment(LibraryStore.self) private var store
    @Environment(MultiViewModel.self) private var model
    /// Écran à remplir (zapping). Sans écran : choix d'une chaîne seule, validée par [onPick] (image dans l'image).
    var slot: MultiViewSlot?
    var canPick: ((MediaItem) -> Bool)?
    var onPick: ((MediaItem) -> Void)?
    var onClose: () -> Void = {}
    @State private var categories: [LiveCategory] = []
    @State private var selection = "fav"
    @State private var query = ""
    @State private var pending: Task<Void, Never>?

    private var sourceID: UUID? { slot?.sourceID }

    private func inSource(_ item: MediaItem) -> Bool { item.kind == .live && (sourceID == nil || item.sourceID == sourceID) }
    private var favorites: [MediaItem] { store.favoriteIDs.compactMap { store.item(id: $0) }.filter(inSource) }
    private var recents: [MediaItem] { store.recentIDs.compactMap { store.item(id: $0) }.filter(inSource) }

    var body: some View {
        let key = query.kastideoSearchKey
        HStack(spacing: 0) {
            List(selection: Binding<String?>(get: { selection }, set: { if let v = $0 { selection = v; query = "" } })) {
                if !favorites.isEmpty {
                    Label("Favoris", systemImage: "star").tag("fav")
                }
                if !recents.isEmpty {
                    Label("Récents", systemImage: "clock.arrow.circlepath").tag("rec")
                }
                Section("Catégories") {
                    ForEach(categories) { category in
                        HStack {
                            Text(category.name).lineLimit(1)
                            Spacer()
                            Text(category.items.count, format: .number)
                                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                        .tag("c:" + category.name)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(width: 220)
            Divider()
            VStack(spacing: 0) {
                TextField("Rechercher une chaîne", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(10)
                let items = visibleItems(key: key)
                if items.isEmpty {
                    Text(LocalizedStringKey(key.isEmpty ? "Aucune chaîne dans cette catégorie." : "Aucun résultat."))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(items) { item in row(item) }
                        .listStyle(.plain)
                }
            }
        }
        .frame(width: 720, height: 480)
        .onAppear {
            if let sourceID { categories = store.liveCategories(of: sourceID) }
            else { categories = MultiViewKeys.liveSources(store.sources).flatMap { store.liveCategories(of: $0.id) } }
            if favorites.isEmpty { selection = recents.isEmpty ? "c:" + (categories.first?.name ?? "") : "rec" }
        }
        .onDisappear { pending?.cancel() }
    }

    private func visibleItems(key: String) -> [MediaItem] {
        if !key.isEmpty {
            var found: [MediaItem] = []
            for category in categories {
                for item in category.items where item.searchKey.contains(key) {
                    found.append(item)
                    if found.count >= 200 { return found }
                }
            }
            return found
        }
        switch selection {
        case "fav": return favorites
        case "rec": return recents
        default: return categories.first { "c:" + $0.name == selection }?.items ?? []
        }
    }

    /// Écran qui affiche déjà cette chaîne (autre que celui-ci).
    private func usedElsewhere(_ item: MediaItem) -> Int? {
        guard let slot else { return nil }
        return model.slots.firstIndex { $0.id != slot.id && $0.item?.id == item.id }
    }

    private func row(_ item: MediaItem) -> some View {
        let other = usedElsewhere(item)
        let current = slot?.item?.id == item.id
        let allowed = canPick?(item) ?? true
        return HStack(spacing: 8) {
            LogoView(url: item.logoURL, name: item.name, size: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name).lineLimit(1).fontWeight(current ? .bold : .regular)
                if let other {
                    Text("Déjà affichée sur l'écran \(other + 1)").font(.caption).foregroundStyle(.orange).lineLimit(1)
                } else if !allowed {
                    Text("Connexions de « \(store.source(id: item.sourceID)?.name ?? "") » toutes utilisées")
                        .font(.caption).foregroundStyle(.orange).lineLimit(1)
                } else if let programme = store.epg.current(for: item.epgID) {
                    Text(programme.title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if current { Image(systemName: "play.fill").foregroundStyle(KastideoPalette.orange) }
        }
        .contentShape(Rectangle())
        .opacity(other == nil && allowed ? 1 : 0.4)
        .onTapGesture(count: 2) {
            guard other == nil, allowed, let slot else { return }
            pending?.cancel()
            model.replace(slot.id, with: item, store: store)
            onClose()
        }
        .onTapGesture {
            guard other == nil, allowed else { return }
            if let onPick {
                onPick(item)
                return
            }
            guard let slot, !current else { return }
            // Court délai : un double-clic annule ce premier lancement et le remplace par « lancer + fermer ».
            pending?.cancel()
            pending = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(280))
                guard !Task.isCancelled else { return }
                model.replace(slot.id, with: item, store: store)
            }
        }
    }
}

/// Réglage : une ligne par abonnement ou liste, avec son nombre de connexions simultanées.
struct MultiViewSettingsRow: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        Text("Connexions simultanées de chaque abonnement")
            .font(.headline)
        ForEach(MultiViewKeys.liveSources(store.sources), id: \.id) { source in
            MultiViewSourceRow(source: source)
        }
        Text("Indiquez pour chaque abonnement le nombre de connexions qu'il autorise (1 pour la plupart, 4 pour une liste publique). Dans la fenêtre MultiVue (⌥⌘M), choisissez ensuite le nombre d'écrans, la disposition et la source de chaque écran. Les enregistrements et téléchargements utilisent aussi une connexion.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

/// Une ligne par source : sa propre valeur, enregistrée aussitôt, sans lien avec les autres sources.
struct MultiViewSourceRow: View {
    let source: Source
    @State private var value: Int

    init(source: Source) {
        self.source = source
        _value = State(initialValue: MultiViewKeys.limit(for: source))
    }

    var body: some View {
        Stepper(value: $value, in: 1...MultiViewKeys.totalMax) {
            LabeledContent("\(MultiViewKeys.accountLabel(source)) (\(MultiViewKeys.isSubscription(source) ? String(localized: "abonnement") : String(localized: "liste publique")))",
                           value: "\(value)")
        }
        .onChange(of: value) { _, newValue in MultiViewKeys.setLimit(newValue, for: source) }
        .id(source.id)
    }
}

/// Bouton d'accès à la MultiVue (barre d'outils, accueil) : ouvre la fenêtre.
struct MultiViewOpenButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            openWindow(id: "multiview")
        } label: {
            Label("MultiVue", systemImage: "rectangle.split.2x2")
        }
        .help("MultiVue : plusieurs chaînes en même temps (⌥⌘M)")
    }
}

/// Bouton de la barre de lecture : ouvre la MultiVue avec la chaîne en cours.
struct MultiViewPlayerButton: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(LibraryStore.self) private var store
    @Environment(MultiViewModel.self) private var multiView
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings

    var body: some View {
        Button {
            let item = playback.current
            if MultiViewKeys.isAvailable(sources: store.sources), let item, item.kind == .live {
                // La connexion de la lecture principale est rendue à la MultiVue (sauf enregistrement en cours).
                if !recordings.isPlayerRecording { playback.stopByUser() }
                multiView.add(item, store: store)
            }
            openWindow(id: "multiview")
        } label: {
            Image(systemName: "rectangle.split.2x2")
        }
        .help("Ouvrir la MultiVue avec cette chaîne (⌥⌘M)")
    }
}
