import SwiftUI
import KastideoCore

/// Conteneur principal : l'écran choisi à l'accueil + barre du bas (Accueil, Contenu, Application, Aide).
struct IOSRootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @Environment(IOSRecorder.self) private var recorder

    @ViewBuilder
    private var screen: some View {
        switch ui.tab {
        case .home: IOSHomeView()
        case .live: IOSLiveHub()
        case .movies: IOSCatalogHub(kind: .movie)
        case .series: IOSCatalogHub(kind: .series)
        case .youtube: IOSYouTubeView()
        case .library: IOSLibraryScreen()
        case .resume: IOSCollectionScreen(kind: .resume)
        case .recents: IOSCollectionScreen(kind: .recents)
        case .favorites: IOSCollectionScreen(kind: .favorites)
        case .guide: NavigationStack { IOSGuideView().navigationTitle("Guide TV") }
        case .recordings: NavigationStack { IOSRecordingsView().navigationTitle("Enregistrements") }
        case .settingsContent: IOSSettingsView(family: .content)
        case .settingsApp: IOSSettingsView(family: .app)
        case .help: IOSHelpView()
        }
    }

    var body: some View {
        @Bindable var ui = ui
        VStack(spacing: 0) {
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if playback.current != nil && !ui.showPlayer {
                MiniPlayerBar()
            }
            IOSBottomBar()
        }
        .background(IOSBrand.night.ignoresSafeArea())
        .fullScreenCover(isPresented: $ui.showPlayer) {
            IOSPlayerScreen()
                .environment(playback)
                .environment(store)
                .environment(ui)
                .environment(recorder)
        }
        .fullScreenCover(isPresented: $ui.showMultiView) {
            IOSMultiViewScreen()
        }
        .fullScreenCover(isPresented: Binding(get: { YouTubeStore.shared.isPlaying },
                                              set: { if !$0 { YouTubeStore.shared.closePlayer() } })) {
            IOSYouTubePlayerScreen()
        }
        .onChange(of: YouTubeStore.shared.playerSession) { _, _ in
            // Une seule source sonore : la lecture IPTV s'arrête, sauf enregistrement en cours.
            if YouTubeStore.shared.isPlaying, playback.current != nil, !recorder.isRecording {
                playback.stopByUser()
                ui.showPlayer = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: IOSYouTubeView.openSettingsName)) { _ in
            ui.tab = .settingsContent
        }
        .sheet(item: $ui.detail) { item in
            IOSDetailSheet(item: item)
        }
        .sheet(item: $ui.editingChannel) { channel in
            IOSChannelEditSheet(item: channel)
        }
        .sheet(item: $ui.programme) { ref in
            IOSProgrammeSheet(ref: ref)
        }
        .sheet(isPresented: $ui.showAddSource) {
            NavigationStack { IOSAddSourceView() }
        }
        .fullScreenCover(isPresented: $ui.showDisclaimer) {
            IOSDisclaimerView()
        }
        .onChange(of: store.hasSources) { _, has in
            if !has && !ui.showDisclaimer { ui.showAddSource = true }
        }
    }
}

/// Mini-lecteur : la lecture continue (son) quand on referme l'écran de lecture.
struct MiniPlayerBar: View {
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui

    var body: some View {
        if let item = playback.current {
            HStack(spacing: 12) {
                ArtworkView(url: item.logoURL, name: item.name)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(playback.isLoading ? "Chargement…" : (playback.isPlaying ? "En lecture" : "En pause"))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { playback.togglePause() } label: {
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill").font(.title3)
                }
                Button { playback.stopByUser() } label: {
                    Image(systemName: "xmark").font(.body)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .contentShape(Rectangle())
            .onTapGesture { ui.showPlayer = true }
        }
    }
}

/// Avertissement légal : à accepter au premier lancement et après chaque mise à jour.
struct IOSDisclaimerView: View {
    @Environment(IOSUI.self) private var ui
    @AppStorage("appLanguage") private var language = ""

    private var content: LegalNotice.Content {
        let code = Locale.preferredLanguages.first?.hasPrefix("fr") == true ? "fr" : "en"
        return LegalNotice.content(for: code)
    }

    var body: some View {
        let content = content
        VStack(alignment: .leading, spacing: 16) {
            Text(content.title).font(.largeTitle.bold())
            Text(content.subtitle).foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(content.intro)
                    ForEach(Array(content.points.enumerated()), id: \.offset) { _, point in
                        Text(point.lead).bold() + Text(" " + point.body)
                    }
                    Text(content.closing).fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                LegalNotice.accept()
                ui.showDisclaimer = false
            } label: {
                Text(content.accept).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .interactiveDismissDisabled(true)
    }
}
