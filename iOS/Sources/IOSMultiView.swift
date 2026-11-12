import SwiftUI
import KastideoCore

/// Vue vidéo d'un écran de la MultiVue : la même vue VLC est replacée dans le conteneur affiché.
struct IOSMultiViewVideo: UIViewRepresentable {
    let slot: MultiViewSlot

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .black
        attach(to: container)
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        attach(to: container)
    }

    private func attach(to container: UIView) {
        let view = slot.videoView
        guard view.superview !== container else { return }
        view.removeFromSuperview()
        view.frame = container.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(view)
    }
}

/// MultiVue : 2 à 4 chaînes en même temps, chacune sur une source réservée ; le son suit l'écran actif.
struct IOSMultiViewScreen: View {
    @Environment(LibraryStore.self) private var store
    @Environment(MultiViewModel.self) private var model
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSRecorder.self) private var recorder
    @Environment(IOSUI.self) private var ui

    var body: some View {
        let available = MultiViewKeys.isAvailable(sources: store.sources)
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar(available: available)
                if !available {
                    unavailable
                } else if model.slots.isEmpty {
                    ProgressView().tint(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    grid
                }
            }
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .onAppear {
            guard available else { return }
            // Une connexion est libérée pour la MultiVue : la lecture principale s'arrête (sauf enregistrement).
            if playback.current != nil, !recorder.isRecording { playback.stopByUser() }
            model.ensureScreens(store: store)
        }
        .onDisappear { model.stopAll() }
        .sheet(isPresented: Binding(get: { model.pickerSlotID != nil },
                                    set: { if !$0 { model.pickerSlotID = nil } })) {
            if let id = model.pickerSlotID, let slot = model.slots.first(where: { $0.id == id }) {
                IOSMultiViewPicker(slot: slot)
            }
        }
    }

    private func topBar(available: Bool) -> some View {
        HStack(spacing: 14) {
            Button { ui.showMultiView = false } label: {
                Image(systemName: "chevron.down").font(.title3.weight(.semibold))
            }
            Text("MultiVue").font(.headline)
            Spacer()
            if available {
                Menu {
                    Picker("Disposition", selection: Binding(get: { model.layout }, set: { model.layout = $0 })) {
                        ForEach(MultiViewLayout.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
                    }
                    if model.layout == .focus {
                        Picker("Taille des vignettes", selection: Binding(get: { model.pipSize }, set: { model.pipSize = $0 })) {
                            ForEach(PipSize.allCases) { Text($0.label).tag($0) }
                        }
                    }
                    Picker("Écrans", selection: Binding(get: { model.screenCount }, set: { model.setScreenCount($0, store: store) })) {
                        ForEach(1...max(MultiViewKeys.maxScreens(store.sources), 1), id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    Button(role: .destructive) {
                        model.stopAll()
                        model.ensureScreens(store: store)
                    } label: {
                        Label("Tout arrêter", systemImage: "stop.fill")
                    }
                    .disabled(model.slots.allSatisfy { $0.item == nil })
                } label: {
                    Image(systemName: model.layout.icon).font(.title3)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private var grid: some View {
        GeometryReader { geo in
            let frames = model.frames(in: geo.size)
            ZStack(alignment: .topLeading) {
                ForEach(Array(model.slots.enumerated()), id: \.element.id) { index, slot in
                    if index < frames.count {
                        let isPip = model.layout == .focus && model.slots.count > 1
                            && slot.id != (model.slots.first { $0.id == model.bigID } ?? model.slots[0]).id
                        IOSMultiViewTile(slot: slot, index: index, pip: isPip, area: geo.size)
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

    private var unavailable: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.split.2x2").font(.system(size: 54)).foregroundStyle(.white.opacity(0.4))
            Text("MultiVue désactivée").font(.title2.weight(.bold))
            Text("Chaque abonnement n'autorise qu'une connexion à la fois : un second flux serait refusé par le serveur. Ajoutez une autre source de direct (liste publique, second abonnement) ou indiquez le nombre de connexions de votre abonnement dans Réglages > MultiVue.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 480)
            Button("Ouvrir les réglages") {
                ui.showMultiView = false
                ui.tab = .settingsApp
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Un écran de la MultiVue.
struct IOSMultiViewTile: View {
    @Environment(MultiViewModel.self) private var model
    @Environment(LibraryStore.self) private var store
    let slot: MultiViewSlot
    let index: Int
    /// Vignette flottante de la disposition PIP (déplaçable, accrochée aux coins).
    var pip = false
    var area: CGSize = .zero

    var body: some View {
        let focused = model.focusedID == slot.id
        ZStack {
            Color.black
            IOSMultiViewVideo(slot: slot)
            // Toucher : donne le son. Double toucher : met l'écran en grand (disposition PIP).
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { if model.layout == .focus { model.makeBig(slot.id) } else { model.focus(slot.id) } }
                .onTapGesture { model.focus(slot.id) }
            if slot.item == nil {
                Button { model.pickerSlotID = slot.id } label: {
                    Label("Choisir une chaîne", systemImage: "plus.circle").font(pip ? .caption : .title3)
                }
                .buttonStyle(.bordered)
            } else if slot.isLoading {
                ProgressView().tint(.white)
            } else if slot.failed {
                Label("Flux refusé ou indisponible", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
            }
            overlay(focused: focused)
        }
        .clipShape(RoundedRectangle(cornerRadius: pip ? 10 : 0))
        .overlay(RoundedRectangle(cornerRadius: pip ? 10 : 0)
            .strokeBorder(focused ? IOSPalette.orange : Color.white.opacity(pip ? 0.35 : 0.1), lineWidth: focused ? 3 : 1))
        .shadow(color: .black.opacity(pip ? 0.6 : 0), radius: pip ? 8 : 0)
        .highPriorityGesture(pipDrag, including: pip ? .all : .subviews)
        .contextMenu { menu }
    }

    /// Glisser une vignette PIP : elle suit le doigt puis s'accroche au coin le plus proche.
    private var pipDrag: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("multiviewArea"))
            .onChanged { value in slot.drag = value.translation }
            .onEnded { value in
                slot.pipCorner = PipCorner.nearest(x: value.location.x, y: value.location.y, in: area)
                withAnimation(.easeOut(duration: 0.18)) { slot.drag = .zero }
            }
    }

    @ViewBuilder
    private var menu: some View {
        Button { model.pickerSlotID = slot.id } label: { Label("Changer de chaîne", systemImage: "arrow.triangle.2.circlepath") }
        Button { model.focus(slot.id) } label: { Label("Donner le son", systemImage: "speaker.wave.2") }
        if model.layout == .focus {
            Button { model.makeBig(slot.id) } label: { Label("Mettre en grand", systemImage: "arrow.up.left.and.arrow.down.right") }
        }
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
                Label("Source de cet écran", systemImage: "antenna.radiowaves.left.and.right")
            }
        }
        Button(role: .destructive) { model.remove(slot.id) } label: { Label("Retirer de la MultiVue", systemImage: "xmark") }
    }

    private func overlay(focused: Bool) -> some View {
        VStack {
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.caption.weight(.heavy))
                    .frame(width: 20, height: 20)
                    .background(focused ? IOSPalette.orange : Color.black.opacity(0.6), in: Circle())
                if let item = slot.item {
                    Text(TMDB.cleanTitle(item.name).title).font(pip ? .caption2.weight(.semibold) : .callout.weight(.semibold)).lineLimit(1)
                    if !pip, let programme = store.epg.current(for: item.epgID) {
                        Text("· \(programme.title)").font(.caption).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                    }
                }
                Spacer()
                if !pip {
                    if let source = slot.sourceID.flatMap({ store.source(id: $0) }), MultiViewKeys.liveSources(store.sources).count > 1 {
                        Text(MultiViewKeys.accountLabel(source))
                            .font(.caption2.weight(.semibold)).lineLimit(1)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color.white.opacity(0.2), in: Capsule())
                    }
                    Image(systemName: focused ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .foregroundStyle(focused ? .white : .white.opacity(0.5))
                    Button { model.pickerSlotID = slot.id } label: { Image(systemName: "arrow.triangle.2.circlepath") }
                    Button { model.remove(slot.id) } label: { Image(systemName: "xmark") }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(LinearGradient(colors: [.black.opacity(0.75), .clear], startPoint: .top, endPoint: .bottom))
            Spacer()
        }
        .foregroundStyle(.white)
    }
}

/// Choix d'une chaîne pour un écran : favoris, récents, catégories de la source de l'écran, recherche.
struct IOSMultiViewPicker: View {
    let slot: MultiViewSlot
    @Environment(LibraryStore.self) private var store
    @Environment(MultiViewModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var categories: [LiveCategory] = []
    @State private var selection = "fav"
    @State private var query = ""

    private func inSource(_ item: MediaItem) -> Bool { item.kind == .live && (slot.sourceID == nil || item.sourceID == slot.sourceID) }
    private var favorites: [MediaItem] { store.favoriteIDs.compactMap { store.item(id: $0) }.filter(inSource) }
    private var recents: [MediaItem] { store.recentIDs.compactMap { store.item(id: $0) }.filter(inSource) }

    private var title: String {
        slot.sourceID.flatMap { store.source(id: $0) }.map(MultiViewKeys.accountLabel) ?? String(localized: "Choisir une chaîne")
    }

    var body: some View {
        NavigationStack {
            let items = visibleItems(key: query.kastideoSearchKey)
            List {
                if items.isEmpty {
                    Text(query.isEmpty ? "Aucune chaîne dans cette catégorie." : "Aucun résultat.").foregroundStyle(.secondary)
                }
                ForEach(items) { item in row(item) }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Rechercher une chaîne")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Liste", selection: $selection) {
                            if !favorites.isEmpty { Label("Favoris", systemImage: "star").tag("fav") }
                            if !recents.isEmpty { Label("Récents", systemImage: "clock.arrow.circlepath").tag("rec") }
                            ForEach(categories) { category in
                                Text("\(category.name) (\(category.items.count))").tag("c:" + category.name)
                            }
                        }
                    } label: {
                        Label(scopeLabel, systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } }
            }
        }
        .onAppear {
            if let sourceID = slot.sourceID { categories = store.liveCategories(of: sourceID) }
            else { categories = MultiViewKeys.liveSources(store.sources).flatMap { store.liveCategories(of: $0.id) } }
            if favorites.isEmpty { selection = recents.isEmpty ? "c:" + (categories.first?.name ?? "") : "rec" }
        }
    }

    private var scopeLabel: String {
        switch selection {
        case "fav": return String(localized: "Favoris")
        case "rec": return String(localized: "Récents")
        default: return String(selection.dropFirst(2))
        }
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

    private func row(_ item: MediaItem) -> some View {
        let other = model.slots.firstIndex { $0.id != slot.id && $0.item?.id == item.id }
        let current = slot.item?.id == item.id
        return Button {
            guard other == nil else { return }
            model.replace(slot.id, with: item, store: store)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                ArtworkView(url: item.logoURL, name: item.name)
                    .frame(width: 44, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 1) {
                    Text(TMDB.cleanTitle(item.name).title).lineLimit(1).fontWeight(current ? .bold : .regular)
                    if let other {
                        Text("Déjà affichée sur l'écran \(other + 1)").font(.caption).foregroundStyle(.orange)
                    } else if let programme = store.epg.current(for: item.epgID) {
                        Text(programme.title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                if current { Image(systemName: "play.fill").foregroundStyle(IOSPalette.orange) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(other == nil ? 1 : 0.4)
    }
}

/// Réglages > MultiVue : nombre de connexions simultanées de chaque abonnement.
struct IOSMultiViewSettingsSection: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        Section {
            ForEach(MultiViewKeys.liveSources(store.sources), id: \.id) { source in
                IOSMultiViewSourceRow(source: source)
            }
        } header: {
            Text("MultiVue")
        } footer: {
            Text("Indiquez pour chaque abonnement le nombre de connexions qu'il autorise (1 pour la plupart, 4 pour une liste publique). Dans la MultiVue (bouton dans Direct ou dans le lecteur), choisissez ensuite le nombre d'écrans, la disposition et la source de chaque écran. Les enregistrements et téléchargements utilisent aussi une connexion.")
        }
    }
}

struct IOSMultiViewSourceRow: View {
    let source: Source
    @State private var value: Int

    init(source: Source) {
        self.source = source
        _value = State(initialValue: MultiViewKeys.limit(for: source))
    }

    var body: some View {
        Stepper(value: $value, in: 1...MultiViewKeys.totalMax) {
            VStack(alignment: .leading, spacing: 2) {
                Text(MultiViewKeys.accountLabel(source)).font(.body)
                Text("\(MultiViewKeys.isSubscription(source) ? String(localized: "abonnement") : String(localized: "liste publique")) · \(value)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .onChange(of: value) { _, newValue in MultiViewKeys.setLimit(newValue, for: source) }
        .id(source.id)
    }
}

/// Bouton de la barre : ouvre la MultiVue (s'il y a au moins deux connexions possibles).
struct IOSMultiViewButton: View {
    @Environment(LibraryStore.self) private var store
    @Environment(IOSUI.self) private var ui

    var body: some View {
        Button { ui.showMultiView = true } label: {
            Image(systemName: "rectangle.split.2x2")
        }
    }
}
