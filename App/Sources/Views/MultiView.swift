import SwiftUI
import AppKit
import VLCKitSPM
import KastideoCore

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
