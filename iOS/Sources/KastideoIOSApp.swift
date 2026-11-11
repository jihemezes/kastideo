import SwiftUI
import AVFoundation
import KastideoCore

@main
struct KastideoIOSApp: App {
    @State private var store: LibraryStore
    @State private var playback: PlaybackController
    @State private var watch: WatchProgressStore
    @State private var navigation: NavigationModel
    @State private var ui = IOSUI()
    @AppStorage("ios.appearance") private var appearance = "dark"

    init() {
        let store = LibraryStore()
        let nav = NavigationModel()
        nav.categoryNames = { [weak store] kind in store?.categoriesByKind[kind] ?? [] }
        let playback = PlaybackController()
        let watch = WatchProgressStore()
        playback.watchProgress = watch
        // Le son continue écran verrouillé ou application en arrière-plan.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        IOSVideoHost.attach(playback.player)
        // Jellyfin, Emby, Plex : reprise de lecture partagée dans les deux sens.
        store.onServerProgress = { [weak watch] progress in watch?.apply(progress) }
        playback.onProgress = { [weak store] item, position, duration, event in
            store?.reportPlayback(item, position: position, duration: duration, event: event)
        }
        // Fin d'un replay : retour au direct de la chaîne (réglable).
        playback.onReplayEnded = { [weak store, weak playback] item in
            guard ReplaySettings.returnToLive, let channel = store?.replayChannel(of: item) else { return }
            playback?.play(channel)
        }
        _store = State(initialValue: store)
        _navigation = State(initialValue: nav)
        _playback = State(initialValue: playback)
        _watch = State(initialValue: watch)
    }

    var body: some Scene {
        WindowGroup {
            IOSRootView()
                .environment(store)
                .environment(navigation)
                .environment(playback)
                .environment(watch)
                .environment(ui)
                .preferredColorScheme(scheme)
                .tint(IOSPalette.orange)
                .task { await store.start(autoRefresh: true) }
        }
    }

    private var scheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "system": return nil
        default: return .dark
        }
    }
}
