import SwiftUI
import AVFoundation
import KastideoCore

@main
struct KastideoTVApp: App {
    @State private var store: LibraryStore
    @State private var playback: PlaybackController
    @State private var watch: WatchProgressStore
    @State private var ui = TVUI()
    @State private var mediaInfo = MediaInfoStore()
    @State private var setup = TVRemoteSetup()

    init() {
        let store = LibraryStore()
        let playback = PlaybackController()
        let watch = WatchProgressStore()
        playback.watchProgress = watch
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        TVVideoHost.attach(playback.player)
        // Jellyfin, Emby, Plex : reprise de lecture partagée dans les deux sens.
        store.onServerProgress = { [weak watch] progress in watch?.apply(progress) }
        playback.onProgress = { [weak store] item, position, duration, event in
            store?.reportPlayback(item, position: position, duration: duration, event: event)
        }
        _store = State(initialValue: store)
        _playback = State(initialValue: playback)
        _watch = State(initialValue: watch)
    }

    var body: some Scene {
        WindowGroup {
            TVRootView()
                .environment(store)
                .environment(playback)
                .environment(watch)
                .environment(ui)
                .environment(mediaInfo)
                .environment(setup)
                .preferredColorScheme(.dark)
                .tint(TVPalette.orange)
                .task { await store.start(autoRefresh: true) }
        }
    }
}
