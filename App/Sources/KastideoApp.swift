import SwiftUI
import KastideoCore

@main
struct KastideoApp: App {
    @State private var store: LibraryStore
    @State private var navigation = NavigationModel()
    @State private var playback: PlaybackController
    @State private var recordings: RecordingCenter
    @State private var updater = UpdaterController()
    @State private var watchProgress: WatchProgressStore
    @State private var mediaInfo: MediaInfoStore
    @State private var multiView = MultiViewModel()
    @State private var alerts = ProgramAlertCenter()
    @AppStorage(SettingsKeys.appearance) private var appearance = Appearance.dark.rawValue
    @AppStorage(AppearanceKeys.accent) private var accent = AccentChoice.system.rawValue

    init() {
        _ = AppLanguage.effectiveCode
        let store = LibraryStore()
        let playback = PlaybackController()
        let watch = WatchProgressStore()
        let info = MediaInfoStore()
        _store = State(initialValue: store)
        _playback = State(initialValue: playback)
        _watchProgress = State(initialValue: watch)
        _mediaInfo = State(initialValue: info)
        playback.watchProgress = watch
        // Jellyfin, Emby, Plex : reprise de lecture et contenus vus partagés dans les deux sens.
        store.onServerProgress = { [weak watch] progress in watch?.apply(progress) }
        playback.onProgress = { [weak store] item, position, duration, event in
            store?.reportPlayback(item, position: position, duration: duration, event: event)
        }
        // Dossiers : affiches et résumés TMDB pour les films et séries reconnus.
        store.onContentLoaded = { [weak store, weak info] source in
            guard let store, let info else { return }
            info.enrichLocal(source, store: store)
        }
        _recordings = State(initialValue: RecordingCenter(store: store, playback: playback))
    }

    var body: some Scene {
        WindowGroup("Kastideo", id: "main") {
            RootView()
                .environment(store)
                .environment(navigation)
                .environment(playback)
                .environment(recordings)
                .environment(updater)
                .environment(watchProgress)
                .environment(mediaInfo)
                .environment(multiView)
                .environment(alerts)
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
                .tint(AccentChoice(rawValue: accent)?.color)
                .onAppear {
                    playback.watchProgress = watchProgress
                    let playback = playback
                    let recordings = recordings
                    updater.isBusy = { playback.current != nil || recordings.activeLive != nil }
                    updater.startBackgroundChecks()
                    alerts.start(store: store)
                }
                .frame(minWidth: 960, minHeight: 600)
        }
        .defaultSize(width: 1320, height: 820)
        .commands {
            KastideoCommands(store: store, navigation: navigation, playback: playback,
                             recordings: recordings, updater: updater)
        }

        Window("Journal de lecture", id: "playbackLog") {
            PlaybackLogView()
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
        }
        .defaultSize(width: 900, height: 520)

        Window("MultiVue", id: "multiview") {
            MultiViewWindow()
                .environment(store)
                .environment(multiView)
                .environment(playback)
                .environment(recordings)
                .tint(AccentChoice(rawValue: accent)?.color)
        }
        .defaultSize(width: 1280, height: 760)

        Window("Gérer les catégories", id: "categories") {
            CategoryManagerView()
                .environment(store)
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
                .tint(AccentChoice(rawValue: accent)?.color)
        }
        .defaultSize(width: 640, height: 640)

        Window("Aide de Kastideo", id: "help") {
            HelpView()
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
        }
        .defaultSize(width: 760, height: 680)

        Settings {
            SettingsView()
                .environment(store)
                .environment(recordings)
                .environment(updater)
                .environment(watchProgress)
                .environment(mediaInfo)
                .environment(multiView)
                .environment(alerts)
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
                .tint(AccentChoice(rawValue: accent)?.color)
        }
    }
}

/// Clés des réglages stockés dans les préférences.
enum SettingsKeys {
    static let appearance = "appearance"
    static let autoRefresh = "autoRefresh"
}

/// Apparence de l'interface.
enum Appearance: String, CaseIterable, Identifiable {
    case system, dark, light
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return String(localized: "Comme le système")
        case .dark: return String(localized: "Sombre")
        case .light: return String(localized: "Clair")
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

/// Menus et raccourcis clavier.
struct KastideoCommands: Commands {
    let store: LibraryStore
    let navigation: NavigationModel
    let playback: PlaybackController
    let recordings: RecordingCenter
    let updater: UpdaterController

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Rechercher les mises à jour…") { updater.checkForUpdates() }
                .disabled(!updater.canCheckForUpdates)
        }

        CommandGroup(after: .newItem) {
            Button("Actualiser les sources") { store.refreshAll() }
                .keyboardShortcut("r", modifiers: .command)
        }

        CommandMenu("Lecture") {
            Button("Élément précédent") { navigation.step(-1) }
                .keyboardShortcut(.upArrow, modifiers: .command)
            Button("Élément suivant") { navigation.step(1) }
                .keyboardShortcut(.downArrow, modifiers: .command)
            Divider()
            Button("Lecture / Pause") { playback.togglePause() }
                .keyboardShortcut("k", modifiers: .command)
            Button("Arrêter la lecture") { recordings.requestStop() }
                .keyboardShortcut(".", modifiers: .command)
            Button(recordings.isPlayerRecording ? String(localized: "Arrêter l'enregistrement") : String(localized: "Enregistrer la chaîne")) {
                recordings.toggleCurrentRecording()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            Button("Mode cinéma") { navigation.isTheater.toggle() }
                .keyboardShortcut(.return, modifiers: .command)
            Button("Panneau d'informations (pistes, sous-titres, qualité)") { navigation.showContextPanel.toggle() }
                .keyboardShortcut("i", modifiers: .command)
            OpenWindowButton(title: "MultiVue…", windowID: "multiview")
                .keyboardShortcut("m", modifiers: [.command, .option])
            Divider()
            Button("Reculer de 10 secondes") { playback.jump(seconds: -10) }
                .keyboardShortcut("[", modifiers: .command)
            Button("Avancer de 30 secondes") { playback.jump(seconds: 30) }
                .keyboardShortcut("]", modifiers: .command)
            Divider()
            OpenWindowButton(title: "Journal de lecture…", windowID: "playbackLog")
                .keyboardShortcut("l", modifiers: [.command, .option])
            Divider()
            Button("Ajouter / retirer des favoris") {
                if let id = navigation.selectedItemID { store.toggleFavorite(id) }
            }
            .keyboardShortcut("d", modifiers: .command)
        }

        CommandGroup(after: .toolbar) {
            OpenWindowButton(title: "Gérer les catégories…", windowID: "categories")
                .keyboardShortcut("c", modifiers: [.command, .option])
            Divider()
            Button("Interface Classique") { applyInterface(.classic) }
                .keyboardShortcut("1", modifiers: [.command, .option])
            Button("Interface Cinéma") { applyInterface(.cinema) }
                .keyboardShortcut("2", modifiers: [.command, .option])
            Button("Interface TV (direct)") { applyInterface(.tv) }
                .keyboardShortcut("3", modifiers: [.command, .option])
        }

        CommandMenu("Aller") {
            Button("Accueil") { navigation.go(.home) }.keyboardShortcut("0", modifiers: .command)
            Divider()
            Button("Direct") { navigation.go(.all(.live)) }.keyboardShortcut("1", modifiers: .command)
            Button("Films") { navigation.go(.all(.movie)) }.keyboardShortcut("2", modifiers: .command)
            Button("Séries") { navigation.go(.all(.series)) }.keyboardShortcut("3", modifiers: .command)
            Button("Favoris") { navigation.go(.favorites) }.keyboardShortcut("4", modifiers: .command)
            Button("Récents") { navigation.go(.recents) }.keyboardShortcut("5", modifiers: .command)
            Button("Enregistrements") { navigation.go(.recordings) }.keyboardShortcut("6", modifiers: .command)
            Button("Guide TV") { navigation.go(.guide) }.keyboardShortcut("7", modifiers: .command)
        }

        CommandGroup(replacing: .help) {
            HelpMenuButton()
            Button("Nouveautés de cette version") { navigation.showWhatsNew = true }
        }
    }
}

extension KastideoCommands {
    /// Applique l'interface choisie au type de contenu affiché.
    func applyInterface(_ style: InterfaceStyle) {
        InterfaceScope.scope(for: navigation.browse)?.set(style)
    }
}

/// Bouton de menu qui ouvre une fenêtre secondaire.
struct OpenWindowButton: View {
    @Environment(\.openWindow) private var openWindow
    let title: LocalizedStringKey
    let windowID: String
    var body: some View {
        Button(title) { openWindow(id: windowID) }
    }
}

private struct HelpMenuButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("Aide de Kastideo") { openWindow(id: "help") }
            .keyboardShortcut("?", modifiers: .command)
    }
}
