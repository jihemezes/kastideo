import SwiftUI
import AppKit
import KastideoCore

// MARK: - Modèle

/// État et commandes de l'interface TV : panneau de chaînes, bandeau d'information,
/// saisie d'un numéro de chaîne et raccourcis clavier.
@MainActor
@Observable
final class TVModel {
    enum Filter: Hashable {
        case all
        case favorites
        case recents
        case category(String)
    }

    var filter: Filter = .all
    var query = ""
    var showPanel = false
    var showBanner = false
    /// Chiffres tapés pour changer de chaîne.
    var typed = ""
    /// Message bref (chaîne introuvable…).
    var notice: String?

    @ObservationIgnored var window: NSWindow?
    @ObservationIgnored private var previousID: String?
    @ObservationIgnored private var store: LibraryStore?
    @ObservationIgnored private var navigation: NavigationModel?
    @ObservationIgnored private var playback: PlaybackController?
    @ObservationIgnored private var monitor: Any?
    @ObservationIgnored private var bannerTask: Task<Void, Never>?
    @ObservationIgnored private var panelTask: Task<Void, Never>?
    @ObservationIgnored private var typeTask: Task<Void, Never>?
    @ObservationIgnored private var noticeTask: Task<Void, Never>?

    func bind(store: LibraryStore, navigation: NavigationModel, playback: PlaybackController) {
        self.store = store
        self.navigation = navigation
        self.playback = playback
    }

    // MARK: Liste des chaînes

    /// Chaînes du filtre courant, après la recherche du panneau.
    var channels: [MediaItem] {
        guard let store else { return [] }
        let base: [MediaItem]
        switch filter {
        case .all:
            base = store.items(for: .all(.live))
        case .favorites:
            base = store.items(for: .favorites).filter { $0.kind == .live }
        case .recents:
            base = store.items(for: .recents).filter { $0.kind == .live }
        case .category(let name):
            base = store.items(for: .category(.live, name))
        }
        let key = query.kastideoSearchKey
        return key.isEmpty ? base : base.filter { $0.searchKey.contains(key) }
    }

    var filterTitle: String {
        switch filter {
        case .all: return String(localized: "Toutes les chaînes")
        case .favorites: return String(localized: "Favoris")
        case .recents: return String(localized: "Récents")
        case .category(let name): return name
        }
    }

    var currentItem: MediaItem? {
        guard let id = navigation?.selectedItemID, let item = store?.item(id: id), item.kind == .live else { return nil }
        return item
    }

    /// Reprend la catégorie ouverte dans la barre latérale en interface Classique.
    func adoptBrowse(_ browse: Browse?) {
        if case .category(.live, let name)? = browse { filter = .category(name) }
    }

    // MARK: Actions

    func select(_ item: MediaItem) {
        guard let navigation else { return }
        if let current = navigation.selectedItemID, current != item.id, store?.item(id: current)?.kind == .live {
            previousID = current
        }
        navigation.selectedItemID = item.id
        flashBanner()
    }

    /// Chaîne précédente (`-1`) ou suivante (`+1`) dans la liste affichée.
    func zap(_ delta: Int) {
        let list = channels
        guard !list.isEmpty else { return }
        let index = currentItem.flatMap { current in list.firstIndex { $0.id == current.id } }
        let next: Int
        if let index {
            next = (index + delta + list.count) % list.count
        } else {
            next = delta >= 0 ? 0 : list.count - 1
        }
        select(list[next])
    }

    /// Revient à la chaîne précédemment regardée.
    func goBack() {
        guard let previousID, let item = store?.item(id: previousID) else { return }
        select(item)
    }

    func toggleFavorite() {
        if let item = currentItem { store?.toggleFavorite(item.id) }
    }

    // MARK: Panneau et bandeau

    func openPanel() {
        if !showPanel { withAnimation(.easeOut(duration: 0.18)) { showPanel = true } }
        touchPanel()
    }

    func closePanel() {
        panelTask?.cancel()
        if showPanel { withAnimation(.easeIn(duration: 0.15)) { showPanel = false } }
    }

    func togglePanel() {
        if showPanel { closePanel() } else { openPanel() }
    }

    /// Prolonge l'affichage du panneau (il se referme après quelques secondes d'inactivité).
    func touchPanel() {
        panelTask?.cancel()
        panelTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            self?.closePanel()
        }
    }

    func flashBanner() {
        bannerTask?.cancel()
        withAnimation(.easeOut(duration: 0.18)) { showBanner = true }
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.25)) { self?.showBanner = false }
        }
    }

    func toggleBanner() {
        if showBanner {
            bannerTask?.cancel()
            withAnimation { showBanner = false }
        } else {
            flashBanner()
        }
    }

    // MARK: Numéro de chaîne

    func type(digit: Character) {
        guard typed.count < 4 else { return }
        typed.append(digit)
        typeTask?.cancel()
        if typed.count == 4 {
            commitNumber()
            return
        }
        typeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            self?.commitNumber()
        }
    }

    func cancelNumber() {
        typeTask?.cancel()
        typed = ""
    }

    func commitNumber() {
        typeTask?.cancel()
        let digits = typed
        typed = ""
        guard let number = Int(digits) else { return }
        if let item = resolve(number: number) {
            select(item)
        } else {
            showNotice(String(localized: "Chaîne \(number) introuvable"))
        }
    }

    /// Chaîne portant ce numéro ; si la playlist ne numérote pas ses chaînes, position dans la liste affichée.
    func resolve(number: Int) -> MediaItem? {
        guard let store else { return nil }
        let all = store.items(for: .all(.live))
        if all.contains(where: { $0.number != nil }) {
            return all.first { $0.number == number }
        }
        let list = channels
        return (1...max(list.count, 1)).contains(number) && !list.isEmpty ? list[number - 1] : nil
    }

    /// Nom de la chaîne correspondant aux chiffres déjà tapés (aperçu).
    var typedPreview: String? {
        guard let number = Int(typed) else { return nil }
        return resolve(number: number)?.name
    }

    private func showNotice(_ text: String) {
        noticeTask?.cancel()
        notice = text
        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            self?.notice = nil
        }
    }

    // MARK: Clavier

    func startKeyboard() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return MainActor.assumeIsolated { self.handle(event) ? nil : event }
        }
    }

    func stopKeyboard() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        for task in [bannerTask, panelTask, typeTask, noticeTask] { task?.cancel() }
        typed = ""
    }

    /// Retourne `true` si la touche est utilisée par l'interface TV.
    private func handle(_ event: NSEvent) -> Bool {
        guard let window, event.window === window, window.isKeyWindow else { return false }
        // Pas de raccourcis pendant la saisie dans un champ (recherche du panneau).
        if window.firstResponder is NSTextView { return false }
        let modifiers = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting([.numericPad, .function, .capsLock])
        guard modifiers.isEmpty else { return false }

        switch event.keyCode {
        case 126: zap(-1); return true                       // ↑
        case 125: zap(1); return true                        // ↓
        case 123: openPanel(); return true                   // ←
        case 124:                                            // →
            if showPanel { closePanel(); return true }
            toggleBanner(); return true
        case 36, 76:                                         // Retour / Entrée
            if !typed.isEmpty { commitNumber() } else { togglePanel() }
            return true
        case 53:                                             // Échap
            if !typed.isEmpty { cancelNumber(); return true }
            if showPanel { closePanel(); return true }
            return false
        case 49:                                             // Espace
            playback?.togglePause(); return true
        default:
            break
        }

        guard let characters = event.charactersIgnoringModifiers?.lowercased(), characters.count == 1,
              let character = characters.first else { return false }
        if character.isASCII, character.isNumber {
            type(digit: character)
            return true
        }
        switch character {
        case "i": toggleBanner(); return true
        case "f": toggleFavorite(); return true
        case "m": playback?.isMuted.toggle(); return true
        case "b": goBack(); return true
        case "g": navigation?.go(.guide); return true
        case "h": navigation?.go(.home); return true
        default: return false
        }
    }
}

// MARK: - Vue principale

/// Interface « TV » pour le direct : chaîne en plein cadre, panneau de chaînes, bandeau d'information.
struct TVRootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    @State private var model = TVModel()
    let scope: InterfaceScope?
    let style: InterfaceStyle

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                stage

                // Bord gauche : l'approche de la souris ouvre le panneau.
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: 14)
                        .contentShape(Rectangle())
                        .onHover { inside in if inside { model.openPanel() } }
                    Spacer(minLength: 0)
                }

                if model.showPanel {
                    TVChannelPanel(model: model)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .zIndex(2)
                }

                overlays
            }
            .background(Color.black)
            .background(WindowReader { model.window = $0 })
            .navigationTitle(model.currentItem?.name ?? String(localized: "Direct"))
            .toolbar {
                SectionPickerToolbar(navigation: navigation, playback: playback, recordings: recordings)
                MainToolbar(store: store, scope: scope, style: style)
            }
            .toolbar(navigation.isTheater ? .hidden : .automatic, for: .windowToolbar)
        }
        .onAppear {
            model.bind(store: store, navigation: navigation, playback: playback)
            model.adoptBrowse(navigation.browse)
            model.startKeyboard()
            startWithLastChannel()
        }
        .onDisappear { model.stopKeyboard() }
        .task(id: VisibleChannels(count: model.channels.count, filter: model.filter, query: model.query)) {
            navigation.visibleIDs = model.channels.map(\.id)
        }
    }

    @ViewBuilder
    private var stage: some View {
        if let item = model.currentItem {
            TVStage(item: item)
        } else {
            ContentUnavailableView {
                Label("Direct", systemImage: "tv")
            } description: {
                Text("Choisissez une chaîne dans le panneau (touche ←), tapez son numéro ou utilisez ↑ / ↓.")
            } actions: {
                Button("Ouvrir les chaînes") { model.openPanel() }
            }
            .foregroundStyle(.white)
        }
    }

    private var overlays: some View {
        ZStack {
            if let item = model.currentItem, model.showBanner {
                VStack {
                    Spacer()
                    TVBanner(item: item)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 76)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
            }
            if !model.typed.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        TVNumberPad(typed: model.typed, preview: model.typedPreview)
                    }
                    Spacer()
                }
                .padding(24)
                .allowsHitTesting(false)
            }
            if let notice = model.notice {
                VStack {
                    Text(notice)
                        .font(.headline)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                .padding(24)
                .allowsHitTesting(false)
            }
        }
    }

    /// À l'ouverture : reprend la dernière chaîne regardée, sinon ouvre le panneau.
    private func startWithLastChannel() {
        if model.currentItem != nil { return }
        if let last = store.recentIDs.compactMap({ store.item(id: $0) }).first(where: { $0.kind == .live }) {
            model.select(last)
        } else {
            model.openPanel()
        }
    }
}

private struct VisibleChannels: Hashable {
    let count: Int
    let filter: TVModel.Filter
    let query: String
}

/// Lecteur de la chaîne courante (même logique que le lecteur de l'interface Classique).
struct TVStage: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    let item: MediaItem

    var body: some View {
        VideoSurface()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: item.id) {
                recordings.requestPlay(item, onCancel: {
                    navigation.selectedItemID = playback.current?.id
                })
                store.recordPlay(item)
            }
    }
}

// MARK: - Panneau de chaînes

struct TVChannelPanel: View {
    @Environment(LibraryStore.self) private var store
    @Bindable var model: TVModel

    var body: some View {
        let channels = model.channels
        let currentID = model.currentItem?.id
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Menu {
                        Button("Toutes les chaînes") { model.filter = .all }
                        Button("Favoris") { model.filter = .favorites }
                        Button("Récents") { model.filter = .recents }
                        let categories = store.categoriesByKind[.live] ?? []
                        if !categories.isEmpty {
                            Divider()
                            ForEach(categories, id: \.self) { name in
                                Button(name) { model.filter = .category(name) }
                            }
                        }
                    } label: {
                        Label(model.filterTitle, systemImage: "line.3.horizontal.decrease.circle")
                            .lineLimit(1)
                    }
                    .menuStyle(.borderlessButton)
                    Spacer()
                    Text("\(channels.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                TextField("Rechercher une chaîne", text: $model.query)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: model.query) { _, _ in model.touchPanel() }
            }
            .padding(12)

            Divider()

            if channels.isEmpty {
                ContentUnavailableView(model.query.isEmpty ? String(localized: "Aucune chaîne") : String(localized: "Aucun résultat"),
                                       systemImage: "tv")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(channels) { item in
                                TVChannelRow(item: item, isCurrent: item.id == currentID) {
                                    model.select(item)
                                    model.touchPanel()
                                }
                                .id(item.id)
                            }
                        }
                        .padding(8)
                    }
                    .onAppear {
                        if let currentID { proxy.scrollTo(currentID, anchor: .center) }
                    }
                }
            }
        }
        .frame(width: 360)
        .frame(maxHeight: .infinity)
        .background(.regularMaterial)
        .overlay(alignment: .trailing) { Rectangle().fill(.separator).frame(width: 1) }
        .onContinuousHover { _ in model.touchPanel() }
    }
}

struct TVChannelRow: View {
    @Environment(LibraryStore.self) private var store
    let item: MediaItem
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let number = item.number {
                    Text("\(number)")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 34, alignment: .trailing)
                }
                LogoView(url: item.logoURL, name: item.name, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).lineLimit(1)
                    if let programme = store.epg.current(for: item.epgID) {
                        Text(programme.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        ProgressView(value: programme.progress())
                            .progressViewStyle(.linear)
                            .controlSize(.mini)
                    }
                }
                Spacer(minLength: 4)
                if store.isFavorite(item.id) {
                    Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.tint)
                        .opacity(0.28)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu { ItemActionsMenu(item: item) }
    }
}

// MARK: - Bandeau et saisie du numéro

/// Bandeau d'information affiché à chaque changement de chaîne.
struct TVBanner: View {
    @Environment(LibraryStore.self) private var store
    let item: MediaItem

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let now = context.date
            let current = store.epg.current(for: item.epgID, at: now)
            let next = store.epg.upcoming(for: item.epgID, after: now, limit: 1).first
            HStack(spacing: 16) {
                LogoView(url: item.logoURL, name: item.name, size: 64)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if let number = item.number {
                            Text("\(number)")
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundStyle(.tint)
                        }
                        Text(item.name).font(.title3.weight(.semibold)).lineLimit(1)
                        if store.isFavorite(item.id) {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                        }
                        Spacer()
                        Text(now.formatted(date: .omitted, time: .shortened))
                            .font(.title3.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    if let current {
                        HStack {
                            Text(current.title).font(.headline).lineLimit(1)
                            Spacer()
                            Text("\(current.start.formatted(date: .omitted, time: .shortened)) – \(current.stop.formatted(date: .omitted, time: .shortened))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: current.progress(at: now))
                            .progressViewStyle(.linear)
                        if let next {
                            Text("Ensuite : \(next.title) (\(next.start.formatted(date: .omitted, time: .shortened)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Pas de programme disponible")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .environment(\.colorScheme, .dark)
        }
    }
}

/// Chiffres tapés au clavier, avec le nom de la chaîne correspondante.
struct TVNumberPad: View {
    let typed: String
    let preview: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(typed)
                .font(.system(size: 54, weight: .bold, design: .rounded).monospacedDigit())
            Text(preview ?? "…")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 22).padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Fenêtre hôte

/// Donne accès à la fenêtre qui contient la vue (pour filtrer les événements clavier).
struct WindowReader: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onWindow(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { onWindow(nsView.window) }
    }
}
