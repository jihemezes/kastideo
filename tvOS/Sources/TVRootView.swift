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
                TVHelpView()
                    .tabItem { Text("Aide") }
                    .tag(8)
            }
        }
        .overlay(alignment: .top) {
            if !store.loading.isEmpty || ui.working > 0 {
                TVLoadingBanner(names: store.sources.filter { store.loading.contains($0.id) }.map(\.name))
                    .padding(.top, 40)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.loading.isEmpty && ui.working == 0)
        .onAppear {
            playback.onEpisodeEnded = { [weak ui, weak playback] item in
                guard let ui, let playback else { return }
                ui.playNext(after: item, playback: playback)
            }
        }
        .fullScreenCover(item: $ui.playing, onDismiss: {
            // Le bouton Menu peut fermer le lecteur sans passer par notre code : le flux doit toujours être fermé,
            // sinon l'abonnement (une seule connexion) reste occupé et la chaîne suivante est refusée.
            if ui.playing == nil, playback.current != nil || playback.isPlaying {
                PlaybackLog.shared.note("Lecteur fermé : arrêt du flux", topic: .playback)
                playback.stopByUser()
            }
        }) { _ in
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
        let text = LegalNotice.tvContent(for: TVLanguage.shared.code)
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

/// Bandeau au premier plan pendant le chargement du catalogue d'une source : l'écran peut se figer quelques secondes.
struct TVLoadingBanner: View {
    let names: [String]

    var body: some View {
        let list = names.joined(separator: ", ")
        HStack(spacing: 24) {
            ProgressView().scaleEffect(1.6)
            VStack(alignment: .leading, spacing: 6) {
                Text("Mise à jour du catalogue").font(.title3.weight(.bold))
                Text(names.isEmpty
                     ? String(localized: "Kastideo recalcule les chaînes, films et séries affichés. Cela peut prendre quelques secondes : l'application peut sembler figée, c'est normal.")
                     : String(localized: "Kastideo vérifie et télécharge les chaînes, films et séries de « \(list) ». Cela peut prendre une minute : l'application peut sembler figée, c'est normal."))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 36).padding(.vertical, 24)
        .frame(maxWidth: 1100, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(radius: 20)
    }
}
