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
    @State private var recorder = IOSRecorder()
    @State private var downloads = IOSDownloads()
    @State private var alerts = IOSAlertCenter()
    @State private var multiView = MultiViewModel()
    @State private var mediaInfo: MediaInfoStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("ios.appearance") private var appearance = "dark"
    @AppStorage(IOSKeys.accent) private var accent = IOSAccent.orange.rawValue

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
        // Vidéos locales : examen de la galerie et résolution du fichier avant la lecture.
        GalleryHook.scan = { source in try await IOSGallery.scan(source) }
        playback.galleryResolver = { item in try await IOSGallery.resolve(item) }
        IOSGallery.purgeCaches()
        // Dossiers et galerie : affiches et résumés TMDB pour les films reconnus (titre exact).
        let info = MediaInfoStore()
        store.onContentLoaded = { [weak store, weak info] source in
            guard let store, let info else { return }
            info.enrichLocal(source, store: store)
        }
        _mediaInfo = State(initialValue: info)
        IOSFiles.ensureFolders()
        IOSNotifier.setup()
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
                .environment(recorder)
                .environment(downloads)
                .environment(alerts)
                .environment(multiView)
                .environment(mediaInfo)
                .preferredColorScheme(scheme)
                .tint(IOSAccent.current(accent).color)
                .task { await store.start(autoRefresh: true) }
                .task {
                    // Alertes : notifications recalculées au lancement puis toutes les 10 minutes.
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(20))
                        alerts.reschedule(store: store)
                        try? await Task.sleep(for: .seconds(580))
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { alerts.reschedule(store: store) }
                    if phase == .active, UserDefaults.standard.object(forKey: IOSGallery.autoRefreshKey) as? Bool ?? true {
                        for source in store.sources where source.isEnabled && !store.loading.contains(source.id) {
                            if case .gallery = source.kind { store.refresh(source) }
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: IOSNotifier.openChannelName)) { note in
                    guard let id = note.object as? String,
                          let group = store.liveGroups.first(where: { $0.variants.contains { $0.id == id } }) else { return }
                    let channel = group.variants.first { $0.id == id } ?? group.preferred
                    ui.play(channel, store: store, playback: playback)
                }
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
