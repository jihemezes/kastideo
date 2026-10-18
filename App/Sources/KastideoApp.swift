import SwiftUI
import KastideoCore

@main
struct KastideoApp: App {
    @State private var store = LibraryStore()
    @State private var navigation = NavigationModel()
    @State private var playback = PlaybackController()
    @State private var updater = UpdaterController()
    @AppStorage(SettingsKeys.appearance) private var appearance = Appearance.dark.rawValue

    var body: some Scene {
        WindowGroup("Kastideo", id: "main") {
            RootView()
                .environment(store)
                .environment(navigation)
                .environment(playback)
                .environment(updater)
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
                .frame(minWidth: 960, minHeight: 600)
        }
        .defaultSize(width: 1320, height: 820)
        .commands {
            KastideoCommands(store: store, navigation: navigation, playback: playback, updater: updater)
        }

        Window("Aide de Kastideo", id: "help") {
            HelpView()
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
        }
        .defaultSize(width: 760, height: 680)

        Settings {
            SettingsView()
                .environment(store)
                .environment(updater)
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
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
        case .system: return "Comme le système"
        case .dark: return "Sombre"
        case .light: return "Clair"
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
            Button("Arrêter la lecture") { playback.stop() }
                .keyboardShortcut(".", modifiers: .command)
            Divider()
            Button("Ajouter / retirer des favoris") {
                if let id = navigation.selectedItemID { store.toggleFavorite(id) }
            }
            .keyboardShortcut("d", modifiers: .command)
        }

        CommandMenu("Aller") {
            Button("Direct") { navigation.go(.all(.live)) }.keyboardShortcut("1", modifiers: .command)
            Button("Films") { navigation.go(.all(.movie)) }.keyboardShortcut("2", modifiers: .command)
            Button("Séries") { navigation.go(.all(.series)) }.keyboardShortcut("3", modifiers: .command)
            Button("Favoris") { navigation.go(.favorites) }.keyboardShortcut("4", modifiers: .command)
            Button("Récents") { navigation.go(.recents) }.keyboardShortcut("5", modifiers: .command)
        }

        CommandGroup(replacing: .help) {
            HelpMenuButton()
            Button("Nouveautés de cette version") { navigation.showWhatsNew = true }
        }
    }
}

private struct HelpMenuButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("Aide de Kastideo") { openWindow(id: "help") }
            .keyboardShortcut("?", modifiers: .command)
    }
}
