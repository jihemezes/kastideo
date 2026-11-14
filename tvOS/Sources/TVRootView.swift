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
                if store.hasLibrary {
                    TVLibraryView()
                        .tabItem { Text("Mes vidéos") }
                        .tag(7)
                }
                TVSearchView()
                    .tabItem { Text("Recherche") }
                    .tag(6)
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
/// Lu page par page (boutons Précédent / Suivant) : pas de défilement à la télécommande.
struct TVDisclaimerView: View {
    @Environment(TVUI.self) private var ui
    @State private var page = 0
    @FocusState private var nextFocused: Bool

    private struct Page { var heading: String?; var lines: [(lead: String?, body: String)] }

    private func pages(_ text: LegalNotice.Content) -> [Page] {
        var result: [Page] = [Page(heading: text.title, lines: [(nil, text.subtitle), (nil, text.intro)])]
        var current = Page(heading: nil, lines: [])
        var size = 0
        for point in text.points {
            let length = point.lead.count + point.body.count
            if size + length > 750, !current.lines.isEmpty {
                result.append(current)
                current = Page(heading: nil, lines: [])
                size = 0
            }
            current.lines.append((point.lead, point.body))
            size += length
        }
        current.lines.append((nil, text.closing))
        result.append(current)
        return result
    }

    var body: some View {
        let code = Locale.current.language.languageCode?.identifier ?? "fr"
        let text = LegalNotice.content(for: code)
        let all = pages(text)
        let last = page >= all.count - 1
        ZStack {
            TVBackground()
            VStack(alignment: .leading, spacing: 28) {
                if let heading = all[min(page, all.count - 1)].heading { Text(heading).font(.largeTitle.bold()) }
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(Array(all[min(page, all.count - 1)].lines.enumerated()), id: \.offset) { _, line in
                        if let lead = line.lead {
                            (Text(lead + " ").bold() + Text(line.body))
                        } else {
                            Text(line.body).foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.title3)
                Spacer(minLength: 0)
                HStack(spacing: 40) {
                    Text("\(page + 1) / \(all.count)").foregroundStyle(.secondary)
                    Spacer()
                    if page > 0 { Button("Précédent") { page -= 1 } }
                    if last {
                        Button(text.accept) {
                            LegalNotice.accept()
                            ui.showDisclaimer = false
                        }
                        .focused($nextFocused)
                    } else {
                        Button("Suivant") { page += 1 }
                            .focused($nextFocused)
                    }
                }
            }
            .padding(.horizontal, 100)
            .padding(.vertical, 60)
        }
        .onAppear { nextFocused = true }
        .onChange(of: page) { _, _ in nextFocused = true }
    }
}
