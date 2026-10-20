import SwiftUI
import AppKit
import KastideoCore

/// Fenêtre principale : accueil si aucune source, sinon navigation en trois colonnes.
struct RootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(NavigationModel.self) private var navigation
    @Environment(RecordingCenter.self) private var recordings
    @AppStorage(SettingsKeys.autoRefresh) private var autoRefresh = true
    @State private var showAddSource = false
    @AppStorage(AppLanguage.storageKey) private var appLanguage = ""

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var recordings = recordings
        Group {
            if store.hasSources {
                if navigation.browse == .home {
                    HomeView()
                } else {
                    MainSplitView()
                }
            } else {
                WelcomeView(showAddSource: $showAddSource)
            }
        }
        .sheet(isPresented: Binding(get: { appLanguage.isEmpty }, set: { _ in })) {
            LanguagePickerSheet(chosen: $appLanguage)
        }
        .sheet(isPresented: $showAddSource) {
            SourceEditorView(existing: nil)
                .environment(store)
        }
        .sheet(isPresented: $navigation.showWhatsNew) {
            WhatsNewView()
        }
        .sheet(item: $recordings.scheduleSheetItem) { item in
            ScheduleRecordingSheet(item: item)
                .environment(store)
                .environment(recordings)
        }
        .alert(recordings.conflict?.title ?? "",
               isPresented: Binding(get: { recordings.conflict != nil },
                                    set: { if !$0 { recordings.conflict = nil } }),
               presenting: recordings.conflict) { conflict in
            Button(conflict.confirmTitle, role: .destructive) {
                recordings.conflict = nil
                conflict.onConfirm()
            }
            Button("Annuler", role: .cancel) {
                recordings.conflict = nil
                conflict.onCancel()
            }
        } message: { conflict in
            Text(conflict.message)
        }
        .task {
            if ReleaseNotes.shouldAnnounceUpdate() { navigation.showWhatsNew = true }
            await store.start(autoRefresh: autoRefresh)
        }
    }
}

struct MainSplitView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @AppStorage("interface.live") private var uiLive = InterfaceStyle.classic.rawValue
    @AppStorage("interface.movie") private var uiMovie = InterfaceStyle.classic.rawValue
    @AppStorage("interface.series") private var uiSeries = InterfaceStyle.classic.rawValue
    @AppStorage("interface.other") private var uiOther = InterfaceStyle.classic.rawValue
    @State private var columns = NavigationSplitViewVisibility.all

    /// Type de contenu affiché (`nil` pour Enregistrements, toujours en interface Classique).
    private var scope: InterfaceScope? { InterfaceScope.scope(for: navigation.browse) }

    private var isGuide: Bool { navigation.browse == .guide }

    /// Le guide TV suit l'interface choisie pour le direct.
    private var style: InterfaceStyle {
        guard let scope = isGuide ? InterfaceScope.live : scope else { return .classic }
        let raw: String
        switch scope {
        case .live: raw = uiLive
        case .movie: raw = uiMovie
        case .series: raw = uiSeries
        case .other: raw = uiOther
        }
        return scope.resolve(raw)
    }

    var body: some View {
        Group {
            if isGuide && style != .classic {
                GuideRootView(style: style)
            } else {
                switch style {
                case .tv:
                    TVRootView(scope: scope, style: style)
                case .cinema:
                    CinemaRootView(scope: scope, style: style)
                case .classic:
                    classic
                }
            }
        }
        .onChange(of: navigation.isTheater) { _, theater in
            withAnimation { columns = theater ? .detailOnly : .all }
            setFullScreen(theater)
        }
    }

    @ViewBuilder
    private var classic: some View {
        if isGuide {
            NavigationSplitView(columnVisibility: $columns) {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
            } detail: {
                GuideView()
                    .navigationTitle("Guide TV")
            }
            .toolbar {
                MainToolbar(store: store, scope: .live, style: style)
            }
        } else {
            NavigationSplitView(columnVisibility: $columns) {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
            } content: {
                ItemListView()
                    .navigationSplitViewColumnWidth(min: 280, ideal: 360, max: 520)
            } detail: {
                DetailView()
            }
            .toolbar {
                MainToolbar(store: store, scope: scope, style: style)
            }
        }
    }
}

/// Boutons de la barre d'outils, communs aux interfaces Classique et Cinéma.
struct MainToolbar: ToolbarContent {
    let store: LibraryStore
    let scope: InterfaceScope?
    let style: InterfaceStyle

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HomeButton()
        }
        ToolbarItemGroup(placement: .primaryAction) {
            if store.isBusy {
                ProgressView().controlSize(.small)
                    .help("Chargement des sources ou du guide TV…")
            }
            DownloadIndicator()
            if let scope {
                Menu {
                    Section("Interface — \(scope.label)") {
                        ForEach(scope.availableStyles) { option in
                            Button {
                                scope.set(option)
                            } label: {
                                if option == style {
                                    Label(option.label, systemImage: "checkmark")
                                } else {
                                    Text(option.label)
                                }
                            }
                        }
                    }
                } label: {
                    Label("Interface", systemImage: style.icon)
                }
                .help("Changer d'interface pour \(scope.label) (⌥⌘1 Classique, ⌥⌘2 Cinéma, ⌥⌘3 TV)")
            }
            Button {
                store.refreshAll()
            } label: {
                Label("Actualiser", systemImage: "arrow.clockwise")
            }
            .help("Actualiser toutes les sources (⌘R)")
            SettingsLink {
                Label("Sources", systemImage: "antenna.radiowaves.left.and.right")
            }
            .help("Gérer les sources et les réglages (⌘,)")
        }
    }
}

/// Passe la fenêtre principale en plein écran (ou en sort) pour le mode cinéma.
@MainActor
private func setFullScreen(_ enabled: Bool) {
    guard let window = NSApp.keyWindow ?? NSApp.mainWindow else { return }
    let isFull = window.styleMask.contains(.fullScreen)
    if enabled != isFull { window.toggleFullScreen(nil) }
}
