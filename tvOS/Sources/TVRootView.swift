import SwiftUI
import KastideoCore

struct TVRootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(TVUI.self) private var ui

    var body: some View {
        @Bindable var ui = ui
        ZStack {
            TVBackground()
            TabView {
                TVHomeView()
                    .tabItem { Text("Accueil") }
                TVBrowseView(kind: .live)
                    .tabItem { Text("Direct") }
                TVBrowseView(kind: .movie)
                    .tabItem { Text("Films") }
                TVBrowseView(kind: .series)
                    .tabItem { Text("Séries") }
                TVGuideView()
                    .tabItem { Text("Guide TV") }
                TVSettingsView()
                    .tabItem { Text("Réglages") }
            }
        }
        .onAppear {
            playback.onEpisodeEnded = { [weak ui, weak playback] item in
                guard let ui, let playback else { return }
                ui.playNext(after: item, playback: playback)
            }
        }
        .fullScreenCover(item: $ui.playing) { _ in
            TVPlayerView()
        }
        .fullScreenCover(item: $ui.detail) { item in
            TVDetailView(item: item)
        }
        .fullScreenCover(isPresented: $ui.showDisclaimer) {
            TVDisclaimerView()
        }
    }
}

/// Avertissement légal : à accepter au premier lancement et après chaque mise à jour.
struct TVDisclaimerView: View {
    @Environment(TVUI.self) private var ui

    var body: some View {
        let code = Locale.current.language.languageCode?.identifier ?? "fr"
        let text = LegalNotice.content(for: code)
        ZStack {
            TVBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(text.title).font(.largeTitle.bold())
                    Text(text.subtitle).font(.title3).foregroundStyle(.secondary)
                    Text(text.intro)
                    ForEach(Array(text.points.enumerated()), id: \.offset) { _, point in
                        (Text(point.lead + " ").bold() + Text(point.body))
                    }
                    Text(text.closing).foregroundStyle(.secondary)
                    Button(text.accept) {
                        LegalNotice.accept()
                        ui.showDisclaimer = false
                    }
                    .padding(.top, 12)
                }
                .font(.callout)
                .padding(80)
            }
        }
    }
}
