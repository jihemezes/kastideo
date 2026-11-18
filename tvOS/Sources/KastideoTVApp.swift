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
    @State private var language = TVLanguage.shared

    init() {
        PlaybackLog.setDetail(.detailed, for: .playback)
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
        // Mode démonstration (captures d'écran automatiques) : source M3U publique passée en argument de lancement.
        // Sans cet argument, rien ne change.
        if let demo = UserDefaults.standard.string(forKey: "kastideo-demo-m3u"), let url = URL(string: demo), store.sources.isEmpty {
            store.addSource(Source(name: "Démo", kind: .m3uURL(url)), password: nil)
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
                .environment(language)
                .environment(\.locale, Locale(identifier: language.code))
                .id(language.revision)
                .preferredColorScheme(.dark)
                .tint(TVPalette.orange)
                .task {
                    if UserDefaults.standard.string(forKey: "kastideo-demo-m3u") != nil {
                        LegalNotice.accept()
                        ui.showDisclaimer = false
                    }
                    await store.start(autoRefresh: true)
                }
        }
    }
}
