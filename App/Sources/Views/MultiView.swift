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

    func play(_ item: MediaItem, muted: Bool) {
        guard let url = item.streamURL else { return }
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
        player.media = media
        setMuted(muted)
        player.play()
        PlaybackLog.shared.note("MultiVue : ouverture de \(item.name)")
    }

    @ObservationIgnored private var muted = true

    func setMuted(_ muted: Bool) {
        self.muted = muted
        player.audio?.isMuted = muted
    }

    func stop() {
        guard player.media != nil else { return }
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
        case .focus: return String(localized: "Une grande + petites")
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
            let big = slots.firstIndex { $0.id == focusedID } ?? 0
            let bigW = (w - spacing) * 2 / 3
            let smallW = w - bigW - spacing
            let smallH = (h - spacing * CGFloat(n - 2)) / CGFloat(n - 1)
            var result = [CGRect](repeating: .zero, count: n)
            var k = 0
            for i in 0..<n {
                if i == big {
                    result[i] = CGRect(x: 0, y: 0, width: bigW, height: h)
                } else {
                    result[i] = CGRect(x: bigW + spacing, y: CGFloat(k) * (smallH + spacing), width: smallW, height: smallH)
                    k += 1
                }
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
                        MultiViewTile(slot: slot, index: index)
                            .frame(width: max(frames[index].width, 1), height: max(frames[index].height, 1))
                            .offset(x: frames[index].minX, y: frames[index].minY)
                    }
                }
            }
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
    @State private var hovering = false

    var body: some View {
        let focused = model.focusedID == slot.id
        ZStack {
            Color.black
            MultiViewVideo(slot: slot)
            if slot.item == nil {
                Button {
                    model.pickerSlotID = slot.id
                } label: {
                    Label("Choisir une chaîne", systemImage: "plus.circle")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
            } else if slot.isLoading {
                ProgressView().tint(.white)
            } else if slot.failed {
                Label("Flux refusé ou indisponible", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { model.focus(slot.id) }
            overlay(focused: focused)
        }
        .overlay(Rectangle().strokeBorder(focused ? KastideoPalette.orange : Color.white.opacity(0.08), lineWidth: focused ? 3 : 1))
        .onHover { hovering = $0 }
        .popover(isPresented: Binding(get: { model.pickerSlotID == slot.id },
                                      set: { if !$0, model.pickerSlotID == slot.id { model.pickerSlotID = nil } })) {
            MultiViewChannelPicker(canPick: { model.canPlay($0, on: slot.id) }, onlySource: slot.sourceID) { item in
                model.replace(slot.id, with: item, store: store)
                model.pickerSlotID = nil
            }
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
                    if let programme = store.epg.current(for: item.epgID) {
                        Text("· \(programme.title)").font(.caption).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                    }
                }
                Spacer()
                sourceMenu
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

/// Choix d'une chaîne : favoris, récents, puis recherche dans tout le direct.
struct MultiViewChannelPicker: View {
    @Environment(LibraryStore.self) private var store
    /// Vrai si la source de la chaîne a encore une connexion libre.
    let canPick: (MediaItem) -> Bool
    /// Écran réservé à une source : seules ses chaînes sont proposées.
    var onlySource: UUID?
    let onPick: (MediaItem) -> Void
    @State private var query = ""

    var body: some View {
        let key = query.kastideoSearchKey
        let inScope: (MediaItem) -> Bool = { $0.kind == .live && (onlySource == nil || $0.sourceID == onlySource) }
        let favorites = store.favoriteIDs.compactMap { store.item(id: $0) }.filter(inScope)
        let recents = store.recentIDs.compactMap { store.item(id: $0) }.filter(inScope)
        // Contenu brut de chaque source : la source active choisie dans la barre latérale ne cache pas les autres comptes.
        let pool: [MediaItem] = (onlySource.map { [$0] } ?? MultiViewKeys.liveSources(store.sources).map(\.id))
            .flatMap { store.content(of: $0)?.items ?? [] }
        let results = key.isEmpty ? [] : Array(pool.lazy.filter { inScope($0) && $0.searchKey.contains(key) }.prefix(60))
        VStack(spacing: 0) {
            TextField("Rechercher une chaîne", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(10)
            List {
                if key.isEmpty {
                    if !favorites.isEmpty { section(String(localized: "Favoris"), favorites) }
                    if !recents.isEmpty { section(String(localized: "Récents"), recents) }
                    if favorites.isEmpty && recents.isEmpty {
                        Text("Tapez le nom d'une chaîne.").foregroundStyle(.secondary)
                    }
                } else {
                    section(String(localized: "Résultats"), results)
                }
            }
            .listStyle(.plain)
        }
        .frame(width: 320, height: 420)
    }

    private func section(_ title: String, _ items: [MediaItem]) -> some View {
        Section(title) {
            ForEach(items) { item in
                let allowed = canPick(item)
                Button {
                    onPick(item)
                } label: {
                    HStack(spacing: 8) {
                        LogoView(url: item.logoURL, name: item.name, size: 26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name).lineLimit(1)
                            if !allowed {
                                Text("Connexions de « \(store.source(id: item.sourceID)?.name ?? "") » toutes utilisées")
                                    .font(.caption).foregroundStyle(.orange).lineLimit(1)
                            } else if let programme = store.epg.current(for: item.epgID) {
                                Text(programme.title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .opacity(allowed ? 1 : 0.5)
                }
                .buttonStyle(.plain)
                .disabled(!allowed)
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
