import SwiftUI
import AppKit
import VLCKitSPM
import KastideoCore

/// Réglages MultiVue.
enum MultiViewKeys {
    /// Nombre de connexions simultanées autorisées par l'abonnement (1 = MultiVue désactivé).
    static let connections = "multiview.connections"
    static var connectionCount: Int { max(UserDefaults.standard.integer(forKey: connections), 1) }
    static var maxStreams: Int { min(connectionCount, 4) }
    static var isAvailable: Bool { connectionCount >= 2 }
}

/// Un flux de la MultiVue : son propre lecteur VLC et sa vue vidéo.
@MainActor
@Observable
final class MultiViewSlot: Identifiable {
    let id = UUID()
    private(set) var item: MediaItem?
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

/// MultiVue : jusqu'à 4 chaînes en direct, le son suit la vignette active.
@MainActor
@Observable
final class MultiViewModel {
    private(set) var slots: [MultiViewSlot] = []
    var focusedID: UUID?
    var pickerSlotID: UUID?

    var capacity: Int { MultiViewKeys.maxStreams }

    /// Ajoute une chaîne (dans une case vide, ou une nouvelle case s'il en reste).
    func add(_ item: MediaItem) {
        if slots.contains(where: { $0.item?.id == item.id }) { return }
        if let empty = slots.first(where: { $0.item == nil }) {
            empty.play(item, muted: empty.id != focusedID)
            return
        }
        guard slots.count < capacity else { return }
        let slot = MultiViewSlot()
        slots.append(slot)
        if focusedID == nil { focusedID = slot.id }
        slot.play(item, muted: slot.id != focusedID)
    }

    func addEmptySlot() {
        guard slots.count < capacity else { return }
        let slot = MultiViewSlot()
        slots.append(slot)
        if focusedID == nil { focusedID = slot.id }
        pickerSlotID = slot.id
    }

    func replace(_ slotID: UUID, with item: MediaItem) {
        guard let slot = slots.first(where: { $0.id == slotID }) else { return }
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
}

/// Fenêtre MultiVue.
struct MultiViewWindow: View {
    @Environment(LibraryStore.self) private var store
    @Environment(MultiViewModel.self) private var model
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    @AppStorage(MultiViewKeys.connections) private var connections = 1

    var body: some View {
        Group {
            if connections < 2 {
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
                Text("\(model.slots.filter { $0.item != nil }.count) / \(model.capacity)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button {
                    model.addEmptySlot()
                } label: {
                    Label("Ajouter une chaîne", systemImage: "plus.rectangle.on.rectangle")
                }
                .disabled(connections < 2 || model.slots.count >= model.capacity)
                .help("Ajouter une chaîne à la MultiVue")
                Button {
                    model.stopAll()
                } label: {
                    Label("Tout arrêter", systemImage: "stop.fill")
                }
                .disabled(model.slots.isEmpty)
            }
        }
        .navigationTitle("MultiVue")
        .onAppear {
            // Une connexion est libérée pour la MultiVue : la lecture principale s'arrête (sauf enregistrement).
            if connections >= 2, playback.current != nil, !recordings.isPlayerRecording {
                recordings.requestStop()
            }
        }
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
        let count = model.slots.count
        let columns = count <= 1 ? 1 : 2
        let rows = Int(ceil(Double(count) / Double(columns)))
        return GeometryReader { geo in
            let spacing: CGFloat = 4
            let width = (geo.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let height = (geo.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { column in
                            let index = row * columns + column
                            if index < count {
                                MultiViewTile(slot: model.slots[index], index: index)
                                    .frame(width: width, height: height)
                            } else {
                                addTile.frame(width: width, height: height)
                            }
                        }
                    }
                }
            }
        }
        .padding(4)
    }

    private var addTile: some View {
        Button {
            model.addEmptySlot()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle").font(.system(size: 40))
                Text("Ajouter une chaîne")
            }
            .foregroundStyle(.white.opacity(0.6))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.05))
        }
        .buttonStyle(.plain)
        .disabled(model.slots.count >= model.capacity)
    }

    private var empty: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.split.2x2").font(.system(size: 54)).foregroundStyle(.white.opacity(0.5))
            Text("MultiVue").font(.title.weight(.bold))
            Text("Regardez jusqu'à \(model.capacity) chaînes en même temps. Le son suit la vignette sélectionnée (clic ou touches 1 à 4).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 440)
            Button("Choisir une première chaîne") { model.addEmptySlot() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var unavailable: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.split.2x2").font(.system(size: 54)).foregroundStyle(.white.opacity(0.4))
            Text("MultiVue désactivée").font(.title2.weight(.bold))
            Text("Votre abonnement n'autorise qu'une connexion à la fois : un second flux serait refusé par le serveur. Si votre abonnement permet plusieurs connexions, indiquez leur nombre dans Réglages > Général > Lecture.")
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
            MultiViewChannelPicker { item in
                model.replace(slot.id, with: item)
                model.pickerSlotID = nil
            }
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
    let onPick: (MediaItem) -> Void
    @State private var query = ""

    var body: some View {
        let key = query.kastideoSearchKey
        let favorites = store.favoriteIDs.compactMap { store.item(id: $0) }.filter { $0.kind == .live }
        let recents = store.recentIDs.compactMap { store.item(id: $0) }.filter { $0.kind == .live }
        let results = key.isEmpty ? [] : Array(store.items(for: .all(.live)).lazy.filter { $0.searchKey.contains(key) }.prefix(60))
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
                Button {
                    onPick(item)
                } label: {
                    HStack(spacing: 8) {
                        LogoView(url: item.logoURL, name: item.name, size: 26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name).lineLimit(1)
                            if let programme = store.epg.current(for: item.epgID) {
                                Text(programme.title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Réglage : nombre de connexions de l'abonnement.
struct MultiViewSettingsRow: View {
    @AppStorage(MultiViewKeys.connections) private var connections = 1

    var body: some View {
        Stepper(value: $connections, in: 1...4) {
            LabeledContent("Connexions simultanées de l'abonnement", value: "\(connections)")
        }
        Text(connections < 2
             ? String(localized: "MultiVue désactivée : avec une seule connexion, un second flux serait refusé par votre fournisseur.")
             : String(localized: "MultiVue : jusqu'à \(min(connections, 4)) chaînes en même temps (menu Lecture > MultiVue, ⌥⌘M). Les enregistrements et téléchargements utilisent aussi une connexion."))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
