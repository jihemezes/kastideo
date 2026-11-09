import SwiftUI
import KastideoCore

/// Barre d'onglets (iPhone) ; sur iPad iOS 18 la barre devient une barre latérale repliable.
struct IOSRootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        @Bindable var ui = ui
        TabView(selection: $ui.tab) {
            IOSHomeView()
                .tabItem { Label("Accueil", systemImage: "house.fill") }
                .tag(IOSTab.home)
            IOSLiveView()
                .tabItem { Label("Direct", systemImage: "tv.fill") }
                .tag(IOSTab.live)
            IOSCatalogView(kind: .movie)
                .tabItem { Label("Films", systemImage: "film.fill") }
                .tag(IOSTab.movies)
            IOSCatalogView(kind: .series)
                .tabItem { Label("Séries", systemImage: "rectangle.stack.fill") }
                .tag(IOSTab.series)
            IOSSettingsView()
                .tabItem { Label("Réglages", systemImage: "gearshape.fill") }
                .tag(IOSTab.settings)
        }
        .overlay(alignment: .bottom) {
            if playback.current != nil && !ui.showPlayer {
                // Au-dessus de la barre d'onglets (49 pt sur iPhone).
                MiniPlayerBar()
                    .padding(.bottom, sizeClass == .compact ? 49 : 56)
            }
        }
        .fullScreenCover(isPresented: $ui.showPlayer) {
            IOSPlayerScreen()
                .environment(playback)
                .environment(store)
                .environment(ui)
        }
        .sheet(item: $ui.detail) { item in
            IOSDetailSheet(item: item)
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
