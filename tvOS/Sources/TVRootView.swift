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
            TabView(selection: $ui.tab) {
                TVHomeView()
                    .tabItem { Text("Accueil") }
                    .tag(0)
                TVBrowseView(kind: .live)
                    .tabItem { Text("Direct") }
                    .tag(1)
                TVBrowseView(kind: .movie)
                    .tabItem { Text("Films") }
                    .tag(2)
                TVBrowseView(kind: .series)
                    .tabItem { Text("Séries") }
                    .tag(3)
                TVGuideView()
                    .tabItem { Text("Guide TV") }
                    .tag(4)
                TVSettingsView()
                    .tabItem { Text("Réglages") }
                    .tag(5)
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
    @FocusState private var acceptFocused: Bool

    var body: some View {
        let code = Locale.current.language.languageCode?.identifier ?? "fr"
        let text = LegalNotice.content(for: code)
        ZStack {
            TVBackground()
            VStack(spacing: 24) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text(text.title).font(.largeTitle.bold())
                        Text(text.subtitle).font(.title3).foregroundStyle(.secondary)
                        Text(text.intro)
                        ForEach(Array(text.points.enumerated()), id: \.offset) { _, point in
                            (Text(point.lead + " ").bold() + Text(point.body))
                        }
                        Text(text.closing).foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    .padding(.horizontal, 80)
                    .padding(.top, 40)
                    .focusable()
                }
                // Bouton toujours visible, hors de la zone défilante : sinon la télécommande ne peut pas l'atteindre.
                Button(text.accept) {
                    LegalNotice.accept()
                    ui.showDisclaimer = false
                }
                .focused($acceptFocused)
                .padding(.bottom, 40)
            }
        }
        .onAppear { acceptFocused = true }
    }}
