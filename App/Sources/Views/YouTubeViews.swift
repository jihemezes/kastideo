import SwiftUI
import AppKit
import WebKit
import UniformTypeIdentifiers
import KastideoCore

// MARK: - Fenêtre principale de la section YouTube

/// Section YouTube : navigateur (chaînes suivies, recherche, favoris, historique) puis, au clic sur une vidéo,
/// bascule sur le lecteur officiel (mode confidentialité avancée).
struct YouTubeRootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    @State private var columns = NavigationSplitViewVisibility.all
    private let youtube = YouTubeStore.shared

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            Group {
                if youtube.isPlaying {
                    YouTubePlayerScreen()
                } else {
                    YouTubeBrowser()
                }
            }
            .navigationTitle("YouTube")
        }
        .toolbar {
            MainToolbar(store: store, scope: nil, style: .classic)
        }
        .task { CastCenter.shared.refresh() }
        .overlay(alignment: .bottom) {
            if let message = CastCenter.shared.message {
                Label(message, systemImage: "exclamationmark.triangle")
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(16)
                    .onTapGesture { CastCenter.shared.message = nil }
            }
        }
        .onChange(of: youtube.playerSession) { _, _ in
            // Une seule source sonore : la lecture IPTV s'arrête, sauf enregistrement en cours.
            if youtube.isPlaying, playback.current != nil, !recordings.isPlayerRecording { playback.stop() }
        }
    }
}

// MARK: - Navigateur

private enum YouTubeTab: String, CaseIterable, Identifiable {
    case channels, search, later, favorites, history
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .channels: return "Mes chaînes"
        case .search: return "Recherche"
        case .later: return "À regarder"
        case .favorites: return "Favoris"
        case .history: return "Historique"
        }
    }
}

struct YouTubeBrowser: View {
    private let youtube = YouTubeStore.shared
    @State private var tab: YouTubeTab = .channels
    @State private var field = ""
    @State private var query = ""
    @State private var order: YouTubeOrder = .relevance
    @State private var results: [YouTubeVideo] = []
    @State private var nextToken: String?
    @State private var previousToken: String?
    @State private var searching = false
    @State private var message: String?
    @State private var working = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let message {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }
                    switch tab {
                    case .channels: channelsTab
                    case .search: searchTab
                    case .later: laterTab
                    case .favorites: videoGrid(youtube.favorites, empty: "Ajoutez des vidéos en favoris avec l'étoile ou le clic droit.")
                    case .history: historyTab
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task { await youtube.refreshFeeds() }
    }

    // MARK: En-tête : un seul champ pour chercher ou coller une adresse

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "play.rectangle.fill").foregroundStyle(.red).font(.title2)
                TextField("Rechercher sur YouTube ou coller un lien (vidéo, playlist, chaîne, @pseudo)", text: $field)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submit)
                Button("OK", action: submit)
                    .disabled(field.trimmingCharacters(in: .whitespaces).isEmpty || working)
                if working || youtube.loadingFeeds { ProgressView().controlSize(.small) }
            }
            Picker("", selection: $tab) {
                ForEach(YouTubeTab.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(14)
    }

    private func submit() {
        let text = field.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        message = nil
        if let source = YouTube.parseSource(text), text.contains(".") || text.hasPrefix("@") {
            open(source)
        } else {
            query = text
            tab = .search
            Task { await search(token: nil) }
        }
    }

    /// Lien collé : une vidéo se lit, une playlist devient la file, une chaîne est suivie.
    private func open(_ source: YouTubeSource) {
        working = true
        Task {
            defer { working = false }
            do {
                switch source {
                case .video(let id):
                    let video = await youtube.client.describe(videoID: id)
                    youtube.play([video])
                case .playlist(let id):
                    let feed = try await youtube.client.playlistFeed(id)
                    if feed.videos.isEmpty { message = String(localized: "Playlist vide ou privée."); return }
                    youtube.play(feed.videos)
                case .channel, .handle:
                    let channel = try await youtube.follow(source: source)
                    field = ""
                    tab = .channels
                    message = String(localized: "Chaîne suivie : ") + channel.title
                    await youtube.refreshFeeds(force: true)
                }
            } catch {
                message = String(localized: "Adresse non reconnue ou introuvable (une chaîne privée ou une playlist supprimée ne se lit pas).")
            }
        }
    }

    // MARK: Mes chaînes

    @ViewBuilder
    private var channelsTab: some View {
        if youtube.channels.isEmpty {
            ContentUnavailableView {
                Label("Aucune chaîne suivie", systemImage: "play.tv")
            } description: {
                Text("Collez le lien d'une chaîne ou son @pseudo dans le champ ci-dessus : ses dernières vidéos s'afficheront ici, sans clé ni compte.")
            } actions: {
                HStack(spacing: 16) {
                    Button("Importer mes abonnements…") { importSubscriptions() }
                    HelpLink(title: "Comment obtenir mon fichier ?", page: "youtube-import")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 260)
        } else {
            HStack {
                Button("Importer mes abonnements…") { importSubscriptions() }
                    .help("Ajoute les chaînes de votre export Google Takeout (abonnements.csv)")
                HelpLink(title: "Comment obtenir mon fichier ?", page: "youtube-import")
                Spacer()
                Button {
                    Task { await youtube.refreshFeeds(force: true) }
                } label: {
                    Label("Actualiser", systemImage: "arrow.clockwise")
                }
                .disabled(youtube.loadingFeeds)
            }
            ForEach(youtube.channels) { channel in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(channel.title).font(.title3.weight(.semibold))
                        if let error = youtube.feedErrors[channel.id] {
                            Text(error).font(.caption).foregroundStyle(.orange).lineLimit(1)
                        }
                        Spacer()
                        Button("Ne plus suivre", role: .destructive) { youtube.unfollow(channel) }
                            .buttonStyle(.link)
                            .font(.caption)
                    }
                    let videos = youtube.feeds[channel.id] ?? []
                    if videos.isEmpty {
                        Text(youtube.loadingFeeds ? LocalizedStringKey("Chargement…") : LocalizedStringKey("Aucune vidéo récente."))
                            .font(.callout).foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(alignment: .top, spacing: 14) {
                                ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                                    YouTubeCard(video: video, width: 230) { youtube.play(videos, at: index) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Recherche

    @ViewBuilder
    private var searchTab: some View {
        if !youtube.hasKey {
            VStack(alignment: .leading, spacing: 10) {
                Label("La recherche nécessite votre propre clé API Google (gratuite).", systemImage: "key")
                    .font(.headline)
                Text("Ouvrez Réglages > Général > YouTube : la marche à suivre y est expliquée en quelques étapes. Sans clé, vous pouvez suivre des chaînes et coller des liens de vidéos ou de playlists.")
                    .font(.callout).foregroundStyle(.secondary)
                SettingsLink { Text("Ouvrir les Réglages") }
            }
            .padding(16)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
        } else {
            HStack {
                if !query.isEmpty { Text("Résultats pour « \(query) »").font(.headline) }
                Spacer()
                Picker("Tri", selection: $order) {
                    Text("Pertinence").tag(YouTubeOrder.relevance)
                    Text("Date").tag(YouTubeOrder.date)
                    Text("Vues").tag(YouTubeOrder.viewCount)
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                .onChange(of: order) { _, _ in
                    if !query.isEmpty { Task { await search(token: nil) } }
                }
            }
            if searching { ProgressView().frame(maxWidth: .infinity) }
            videoGrid(results, empty: query.isEmpty ? "Tapez votre recherche dans le champ ci-dessus." : "Aucun résultat.")
            if previousToken != nil || nextToken != nil {
                HStack {
                    Spacer()
                    Button("Précédent") { Task { await search(token: previousToken) } }.disabled(previousToken == nil)
                    Button("Suivant") { Task { await search(token: nextToken) } }.disabled(nextToken == nil)
                    Spacer()
                }
            }
        }
    }

    private func search(token: String?) async {
        guard !query.isEmpty else { return }
        searching = true
        message = nil
        defer { searching = false }
        do {
            let page = try await youtube.client.search(query, order: order, pageToken: token)
            results = page.videos
            nextToken = page.next
            previousToken = page.previous
        } catch YouTubeError.noKey {
            message = String(localized: "Clé API manquante.")
        } catch YouTubeError.api(let code, let text) {
            message = code == 403
                ? String(localized: "Quota ou clé refusés par Google : ") + text
                : String(localized: "Erreur de l'API YouTube : ") + text
        } catch {
            message = String(localized: "Recherche impossible : ") + error.localizedDescription
        }
    }

    // MARK: À regarder plus tard

    @ViewBuilder
    private var laterTab: some View {
        Text("Mettez des vidéos de côté avec le clic droit. Une vidéo entamée reprend là où vous l'avez laissée ; elle quitte cette liste quand vous l'avez vue jusqu'au bout.")
            .font(.caption).foregroundStyle(.secondary)
        videoGrid(youtube.watchLater, empty: "Aucune vidéo mise de côté.")
    }

    // MARK: Import des abonnements

    private func importSubscriptions() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .json, .plainText]
        panel.allowsMultipleSelection = false
        panel.message = String(localized: "Choisissez le fichier « abonnements.csv » de votre export Google Takeout")
        guard panel.runModal() == .OK, let url = panel.url,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        let added = youtube.importSubscriptions(text)
        message = added > 0
            ? String(localized: "Chaînes importées : ") + added.formatted()
            : String(localized: "Aucune nouvelle chaîne trouvée dans ce fichier.")
        Task { await youtube.refreshFeeds(force: true) }
    }

    // MARK: Historique

    @ViewBuilder
    private var historyTab: some View {
        if !youtube.history.isEmpty {
            HStack {
                Spacer()
                Button("Effacer l'historique", role: .destructive) { youtube.clearHistory() }
            }
        }
        videoGrid(youtube.history, empty: "Les vidéos que vous regardez apparaîtront ici.")
    }

    @ViewBuilder
    private func videoGrid(_ videos: [YouTubeVideo], empty: LocalizedStringKey) -> some View {
        if videos.isEmpty {
            if !searching {
                Text(empty).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 160)
            }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 16, alignment: .top)], alignment: .leading, spacing: 18) {
                ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                    YouTubeCard(video: video, width: nil) { youtube.play(videos, at: index) }
                }
            }
        }
    }
}

/// Vignette d'une vidéo : clic = lecture (la liste affichée devient la file), clic droit = favori, copie du lien.
struct YouTubeCard: View {
    let video: YouTubeVideo
    let width: CGFloat?
    let action: () -> Void
    private let youtube = YouTubeStore.shared

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                AsyncImage(url: video.thumbnailURL) { image in
                    image.resizable().aspectRatio(16 / 9, contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(.quaternary).aspectRatio(16 / 9, contentMode: .fit)
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        if youtube.isLater(video) { Image(systemName: "clock.fill").foregroundStyle(.white) }
                        if youtube.isFavorite(video) { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                    }
                    .padding(6).shadow(radius: 2)
                }
                .overlay(alignment: .bottom) {
                    let fraction = youtube.fraction(of: video)
                    if fraction > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(.black.opacity(0.5))
                                Rectangle().fill(.red).frame(width: geo.size.width * fraction)
                            }
                        }
                        .frame(height: 3)
                    }
                }
                Text(video.title).font(.subheadline.weight(.semibold)).lineLimit(2).multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Text(video.channel).lineLimit(1)
                    if let date = Self.date(video.published) { Text("· " + date) }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            .frame(width: width)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(youtube.isLater(video) ? LocalizedStringKey("Retirer de « À regarder »") : LocalizedStringKey("À regarder plus tard")) { youtube.toggleLater(video) }
            Button(youtube.isFavorite(video) ? LocalizedStringKey("Retirer des favoris") : LocalizedStringKey("Ajouter aux favoris")) { youtube.toggleFavorite(video) }
            YouTubeCastMenu(video: video)
            Button("Ouvrir sur YouTube") { NSWorkspace.shared.open(video.watchURL) }
            Button("Copier le lien") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(video.watchURL.absoluteString, forType: .string)
            }
        }
    }

    static func date(_ iso: String?) -> String? {
        guard let iso, let date = ISO8601DateFormatter().date(from: iso) else { return nil }
        return date.formatted(.relative(presentation: .named))
    }
}

// MARK: - Lecteur

/// Lecteur : le navigateur laisse place à la vidéo (lecteur officiel, mode confidentialité avancée).
struct YouTubePlayerScreen: View {
    private let youtube = YouTubeStore.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    youtube.closePlayer()
                } label: {
                    Label("Navigateur YouTube", systemImage: "chevron.left")
                }
                .keyboardShortcut(.cancelAction)
                if let video = youtube.current {
                    Text(video.title).font(.headline).lineLimit(1)
                    Spacer()
                    Button {
                        youtube.toggleLater(video)
                    } label: {
                        Image(systemName: youtube.isLater(video) ? "clock.fill" : "clock")
                    }
                    .help("À regarder plus tard")
                    Button {
                        youtube.toggleFavorite(video)
                    } label: {
                        Image(systemName: youtube.isFavorite(video) ? "star.fill" : "star")
                    }
                    .help("Favori")
                    Menu {
                        YouTubeCastMenu(video: video)
                    } label: {
                        Image(systemName: "tv")
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("Lire sur un téléviseur")
                }
            }
            .padding(10)
            .background(.bar)
            YouTubeWebView(queue: youtube.queue, startIndex: youtube.startIndex, chain: youtube.chain, loop: youtube.loop,
                           muted: youtube.muted, resume: youtube.resumePoints(for: youtube.queue),
                           onVideo: { index in youtube.didStart(index: index) },
                           onProgress: { index, t, d in youtube.didProgress(index: index, t: t, d: d) })
                .id(youtube.playerSession)
        }
    }
}

/// Page de lecture dans un WKWebView. La page est chargée avec une adresse de base youtube-nocookie.com,
/// condition pour que le lecteur accepte l'intégration.
struct YouTubeWebView: NSViewRepresentable {
    let queue: [YouTubeVideo]
    let startIndex: Int
    let chain: Bool
    let loop: Bool
    let muted: Bool
    let resume: [String: Double]
    let onVideo: (Int) -> Void
    let onProgress: (Int, Double, Double) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onVideo: onVideo, onProgress: onProgress) }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.isElementFullscreenEnabled = true
        config.userContentController.add(WeakScriptHandler(context.coordinator), name: "kastideo")
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        web.setValue(false, forKey: "drawsBackground")
        let html = YouTube.playerHTML(queue: queue, index: startIndex, chain: chain, loop: loop, muted: muted, resume: resume,
                                      labels: YouTubeStore.playerLabels)
        web.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
        return web
    }

    func updateNSView(_ web: WKWebView, context: Context) {}

    static func dismantleNSView(_ web: WKWebView, coordinator: Coordinator) {
        // Le son doit s'arrêter avec la page.
        web.configuration.userContentController.removeScriptMessageHandler(forName: "kastideo")
        web.loadHTMLString("", baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let onVideo: (Int) -> Void
        let onProgress: (Int, Double, Double) -> Void
        init(onVideo: @escaping (Int) -> Void, onProgress: @escaping (Int, Double, Double) -> Void) {
            self.onVideo = onVideo
            self.onProgress = onProgress
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let type = body["type"] as? String,
                  let index = body["index"] as? Int else { return }
            if type == "video" {
                DispatchQueue.main.async { self.onVideo(index) }
            } else if type == "progress", let t = (body["t"] as? NSNumber)?.doubleValue, let d = (body["d"] as? NSNumber)?.doubleValue {
                DispatchQueue.main.async { self.onProgress(index, t, d) }
            }
        }

        /// Les liens (« Ouvrir sur YouTube », logo du lecteur…) s'ouvrent dans le navigateur du système.
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if action.navigationType == .linkActivated, let url = action.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = action.request.url { NSWorkspace.shared.open(url) }
            return nil
        }
    }
}

/// Évite que le contrôleur de contenu retienne le coordinateur (cycle de références).
private final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}

// MARK: - Réglages

/// Réglages > Général > YouTube : clé API Google (facultative, pour la recherche).
struct YouTubeSettingsSection: View {
    private let youtube = YouTubeStore.shared
    @State private var draft = ""
    @State private var status: String?
    @State private var checking = false

    var body: some View {
        Section("YouTube") {
            SecureField("Clé API Google (facultative, pour la recherche)", text: $draft)
                .onSubmit(save)
            HStack {
                Button("Enregistrer et vérifier", action: save).disabled(checking)
                if youtube.hasKey {
                    Button("Retirer la clé") {
                        draft = ""
                        youtube.apiKey = ""
                        status = nil
                    }
                }
                if checking { ProgressView().controlSize(.small) }
                if let status { Text(status).font(.caption).foregroundStyle(.secondary) }
                Spacer()
            }
            Text("Sans clé, vous pouvez suivre des chaînes (collez leur lien ou @pseudo) et lire des vidéos ou playlists collées. La recherche demande une clé API Google, gratuite (environ 100 recherches par jour) :\n1. Ouvrez console.cloud.google.com, créez un projet.\n2. Activez « YouTube Data API v3 ».\n3. Créez des identifiants > Clé API, puis collez-la ici.\nLa clé reste dans votre trousseau et n'est jamais publiée.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Link("Ouvrir la console Google Cloud", destination: URL(string: "https://console.cloud.google.com/apis/library/youtube.googleapis.com")!)
                .font(.caption)
            Text("La lecture utilise le lecteur officiel de YouTube en « mode confidentialité avancée » : pas de cookie de suivi, donc le plus souvent aucune publicité personnalisée. Ce n'est pas un bloqueur de publicités et rien n'est garanti : YouTube reste libre d'y diffuser des annonces, qui financent les créateurs.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { draft = youtube.apiKey }
    }

    private func save() {
        let key = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        youtube.apiKey = key
        guard !key.isEmpty else { status = nil; return }
        checking = true
        status = nil
        Task {
            do {
                _ = try await YouTubeClient(apiKey: key).search("kastideo")
                status = String(localized: "Clé valide ✓")
            } catch YouTubeError.api(_, let text) {
                status = String(localized: "Clé refusée : ") + text
            } catch {
                status = String(localized: "Vérification impossible : ") + error.localizedDescription
            }
            checking = false
        }
    }
}

/// Lire une vidéo YouTube sur un téléviseur : application YouTube du téléviseur (DIAL) ou navigateur, selon les réglages.
struct YouTubeCastMenu: View {
    let video: YouTubeVideo
    private let cast = CastCenter.shared

    var body: some View {
        if cast.youtubeMode == "browser" {
            Button("Lire sur un téléviseur (navigateur)") { Task { await cast.castYouTube(video, to: nil) } }
        } else if cast.dialDevices.isEmpty {
            Button("Chercher les téléviseurs…") { cast.refresh() }
        } else {
            Menu("Lire sur un téléviseur") {
                ForEach(cast.dialDevices) { device in
                    Button(device.name) { Task { await cast.castYouTube(video, to: device) } }
                }
            }
        }
    }
}
