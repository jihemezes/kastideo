import SwiftUI
import WebKit
import UniformTypeIdentifiers
import KastideoCore

// MARK: - Onglet YouTube

private enum IOSYouTubeTab: String, CaseIterable, Identifiable {
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

/// YouTube : chaînes suivies, recherche (clé API de l'utilisateur), à regarder plus tard, favoris, historique.
/// La lecture passe par le lecteur officiel de YouTube (mode confidentialité avancée), comme sur Mac.
struct IOSYouTubeView: View {
    private let youtube = YouTubeStore.shared
    @State private var tab: IOSYouTubeTab = .channels
    @State private var field = ""
    @State private var query = ""
    @State private var order: YouTubeOrder = .relevance
    @State private var results: [YouTubeVideo] = []
    @State private var nextToken: String?
    @State private var previousToken: String?
    @State private var searching = false
    @State private var message: String?
    @State private var working = false
    @State private var importing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(IOSYouTubeTab.allCases) { item in
                                chip(item)
                            }
                        }
                    }
                    if working || youtube.loadingFeeds { ProgressView() }
                    if let message {
                        Label(message, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.orange)
                    }
                    switch tab {
                    case .channels: channelsTab
                    case .search: searchTab
                    case .later:
                        Text("Mettez des vidéos de côté avec un appui long. Une vidéo entamée reprend là où vous l'avez laissée ; elle quitte cette liste quand vous l'avez vue jusqu'au bout.")
                            .font(.caption).foregroundStyle(.secondary)
                        videoGrid(youtube.watchLater, empty: "Aucune vidéo mise de côté.")
                    case .favorites:
                        videoGrid(youtube.favorites, empty: "Ajoutez des vidéos en favoris par un appui long.")
                    case .history:
                        if !youtube.history.isEmpty {
                            Button("Effacer l'historique", role: .destructive) { youtube.clearHistory() }
                        }
                        videoGrid(youtube.history, empty: "Les vidéos que vous regardez apparaîtront ici.")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("YouTube")
            .searchable(text: $field, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Rechercher ou coller un lien (vidéo, playlist, chaîne, @pseudo)")
            .onSubmit(of: .search) { submit() }
            .task { await youtube.refreshFeeds() }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.commaSeparatedText, .json, .plainText]) { result in
                importFile(result)
            }
        }
    }

    private func chip(_ item: IOSYouTubeTab) -> some View {
        Button { tab = item } label: {
            Text(item.label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(tab == item ? Color.accentColor : Color.white.opacity(0.1), in: Capsule())
                .foregroundStyle(tab == item ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: Champ unique : recherche ou adresse collée

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
            VStack(spacing: 12) {
                Image(systemName: "play.tv").font(.system(size: 40)).foregroundStyle(.secondary)
                Text("Aucune chaîne suivie").font(.headline)
                Text("Collez le lien d'une chaîne ou son @pseudo dans le champ de recherche : ses dernières vidéos s'afficheront ici, sans clé ni compte.")
                    .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Importer mes abonnements…") { importing = true }.buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 30)
        } else {
            HStack {
                Button("Importer mes abonnements…") { importing = true }
                Spacer()
                Button {
                    Task { await youtube.refreshFeeds(force: true) }
                } label: { Label("Actualiser", systemImage: "arrow.clockwise") }
                    .disabled(youtube.loadingFeeds)
            }
            .font(.subheadline)
            ForEach(youtube.channels) { channel in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(channel.title).font(.title3.weight(.semibold)).lineLimit(1)
                        Spacer()
                        Button("Ne plus suivre", role: .destructive) { youtube.unfollow(channel) }
                            .font(.caption)
                    }
                    if let error = youtube.feedErrors[channel.id] {
                        Text(error).font(.caption).foregroundStyle(.orange).lineLimit(1)
                    }
                    let videos = youtube.feeds[channel.id] ?? []
                    if videos.isEmpty {
                        Text(youtube.loadingFeeds ? LocalizedStringKey("Chargement…") : LocalizedStringKey("Aucune vidéo récente."))
                            .font(.callout).foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(alignment: .top, spacing: 12) {
                                ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                                    IOSYouTubeCard(video: video, width: 220) { youtube.play(videos, at: index) }
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
                Label("La recherche nécessite votre propre clé API Google (gratuite).", systemImage: "key").font(.headline)
                Text("Ouvrez Réglages > YouTube : la marche à suivre y est expliquée. Sans clé, vous pouvez suivre des chaînes et coller des liens de vidéos ou de playlists.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("Ouvrir les Réglages") { NotificationCenter.default.post(name: IOSYouTubeView.openSettingsName, object: nil) }
                    .buttonStyle(.bordered)
            }
            .padding(14)
            .background(IOSPalette.card, in: RoundedRectangle(cornerRadius: 12))
        } else {
            HStack {
                if !query.isEmpty { Text("Résultats pour « \(query) »").font(.headline).lineLimit(1) }
                Spacer()
                Picker("Tri", selection: $order) {
                    Text("Pertinence").tag(YouTubeOrder.relevance)
                    Text("Date").tag(YouTubeOrder.date)
                    Text("Vues").tag(YouTubeOrder.viewCount)
                }
                .pickerStyle(.menu)
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
                .buttonStyle(.bordered)
            }
        }
    }

    static let openSettingsName = Notification.Name("kastideo.openSettings")

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

    // MARK: Import des abonnements (Google Takeout)

    private func importFile(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            message = String(localized: "Fichier illisible.")
            return
        }
        let added = youtube.importSubscriptions(text)
        message = added > 0
            ? String(localized: "Chaînes importées : ") + added.formatted()
            : String(localized: "Aucune nouvelle chaîne trouvée dans ce fichier.")
        Task { await youtube.refreshFeeds(force: true) }
    }

    @ViewBuilder
    private func videoGrid(_ videos: [YouTubeVideo], empty: LocalizedStringKey) -> some View {
        if videos.isEmpty {
            if !searching {
                Text(empty).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 120)
            }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14, alignment: .top)], alignment: .leading, spacing: 16) {
                ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                    IOSYouTubeCard(video: video, width: nil) { youtube.play(videos, at: index) }
                }
            }
        }
    }
}

/// Vignette d'une vidéo : toucher = lecture (la liste affichée devient la file), appui long = favori, plus tard, partage.
struct IOSYouTubeCard: View {
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
                    Rectangle().fill(IOSPalette.card).aspectRatio(16 / 9, contentMode: .fit)
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
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
            Button(youtube.isLater(video) ? LocalizedStringKey("Retirer de « À regarder »") : LocalizedStringKey("À regarder plus tard"),
                   systemImage: "clock") { youtube.toggleLater(video) }
            Button(youtube.isFavorite(video) ? LocalizedStringKey("Retirer des favoris") : LocalizedStringKey("Ajouter aux favoris"),
                   systemImage: youtube.isFavorite(video) ? "star.slash" : "star") { youtube.toggleFavorite(video) }
            Link(destination: video.watchURL) { Label("Ouvrir sur YouTube", systemImage: "arrow.up.right.square") }
            ShareLink(item: video.watchURL) { Label("Partager le lien", systemImage: "square.and.arrow.up") }
        }
    }

    static func date(_ iso: String?) -> String? {
        guard let iso, let date = ISO8601DateFormatter().date(from: iso) else { return nil }
        return date.formatted(.relative(presentation: .named))
    }
}

// MARK: - Lecteur

/// Lecteur plein écran : lecteur officiel de YouTube dans une vue web.
struct IOSYouTubePlayerScreen: View {
    private let youtube = YouTubeStore.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button { youtube.closePlayer() } label: {
                        Image(systemName: "chevron.down").font(.title3.weight(.semibold))
                    }
                    if let video = youtube.current {
                        Text(video.title).font(.headline).lineLimit(1)
                        Spacer()
                        Button { youtube.toggleLater(video) } label: {
                            Image(systemName: youtube.isLater(video) ? "clock.fill" : "clock")
                        }
                        Button { youtube.toggleFavorite(video) } label: {
                            Image(systemName: youtube.isFavorite(video) ? "star.fill" : "star")
                        }
                        ShareLink(item: video.watchURL) { Image(systemName: "square.and.arrow.up") }
                    } else {
                        Spacer()
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 12)
                IOSYouTubeWebView(queue: youtube.queue, startIndex: youtube.startIndex, chain: youtube.chain, loop: youtube.loop,
                                  muted: youtube.muted, resume: youtube.resumePoints(for: youtube.queue),
                                  onVideo: { index in youtube.didStart(index: index) },
                                  onProgress: { index, t, d in youtube.didProgress(index: index, t: t, d: d) })
                    .id(youtube.playerSession)
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// Page de lecture dans un WKWebView, chargée avec une adresse de base youtube-nocookie.com
/// (condition pour que le lecteur accepte l'intégration).
struct IOSYouTubeWebView: UIViewRepresentable {
    let queue: [YouTubeVideo]
    let startIndex: Int
    let chain: Bool
    let loop: Bool
    let muted: Bool
    let resume: [String: Double]
    let onVideo: (Int) -> Void
    let onProgress: (Int, Double, Double) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onVideo: onVideo, onProgress: onProgress) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(WeakHandler(context.coordinator), name: "kastideo")
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.backgroundColor = .black
        web.scrollView.isScrollEnabled = false
        let html = YouTube.playerHTML(queue: queue, index: startIndex, chain: chain, loop: loop, muted: muted, resume: resume,
                                      labels: YouTubeStore.playerLabels)
        web.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {}

    static func dismantleUIView(_ web: WKWebView, coordinator: Coordinator) {
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

        /// Les liens (« Ouvrir sur YouTube », logo du lecteur…) s'ouvrent dans Safari ou l'application YouTube.
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if action.navigationType == .linkActivated, let url = action.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = action.request.url { UIApplication.shared.open(url) }
            return nil
        }
    }
}

/// Évite que le contrôleur de contenu retienne le coordinateur (cycle de références).
private final class WeakHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}

// MARK: - Réglages

/// Réglages > YouTube : clé API Google (facultative, pour la recherche) et options de lecture.
struct IOSYouTubeSettingsSection: View {
    private let youtube = YouTubeStore.shared
    @State private var draft = ""
    @State private var status: String?
    @State private var checking = false
    @State private var chain = YouTubeStore.shared.chain
    @State private var loop = YouTubeStore.shared.loop
    @State private var muted = YouTubeStore.shared.muted

    var body: some View {
        Section {
            SecureField("Clé API Google (facultative, pour la recherche)", text: $draft)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .onSubmit(save)
            Button("Enregistrer et vérifier", action: save).disabled(checking || draft.trimmingCharacters(in: .whitespaces).isEmpty)
            if youtube.hasKey {
                Button("Retirer la clé", role: .destructive) {
                    draft = ""
                    youtube.apiKey = ""
                    status = nil
                }
            }
            if checking { ProgressView() }
            if let status { Text(status).font(.footnote).foregroundStyle(.secondary) }
            Toggle("Enchaîner les vidéos", isOn: $chain).onChange(of: chain) { _, value in youtube.chain = value }
            Toggle("Répéter la file", isOn: $loop).onChange(of: loop) { _, value in youtube.loop = value }
            Toggle("Démarrer sans le son", isOn: $muted).onChange(of: muted) { _, value in youtube.muted = value }
            Link("Ouvrir la console Google Cloud", destination: URL(string: "https://console.cloud.google.com/apis/library/youtube.googleapis.com")!)
        } header: {
            Text("YouTube")
        } footer: {
            Text("Sans clé, vous pouvez suivre des chaînes (collez leur lien ou @pseudo) et lire des vidéos ou playlists collées. La recherche demande une clé API Google, gratuite (environ 100 recherches par jour) :\n1. Ouvrez console.cloud.google.com, créez un projet.\n2. Activez « YouTube Data API v3 ».\n3. Créez des identifiants > Clé API, puis collez-la ici.\nLa clé reste dans le trousseau de l'iPhone. La lecture utilise le lecteur officiel de YouTube en « mode confidentialité avancée » : ce n'est pas un bloqueur de publicités et rien n'est garanti.")
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
