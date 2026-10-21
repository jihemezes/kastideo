import SwiftUI
import AppKit
import KastideoCore

/// Fiches des films et séries : informations du fournisseur IPTV, complétées par TMDB si une clé est saisie.
@MainActor
@Observable
final class MediaInfoStore {
    private static let keychainAccount = "tmdb.apiKey"

    private(set) var cache: [String: MediaDetails] = [:]
    private(set) var loading: Set<String> = []
    private(set) var errors: [String: String] = [:]
    /// Clé TMDB (trousseau). Vide : TMDB n'est pas utilisé.
    var tmdbKey: String {
        didSet {
            let key = tmdbKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if key.isEmpty { Keychain.delete(account: Self.keychainAccount) } else { Keychain.set(key, account: Self.keychainAccount) }
            cache.removeAll()
        }
    }

    init() {
        tmdbKey = Keychain.get(account: Self.keychainAccount) ?? ""
    }

    var usesTMDB: Bool { !tmdbKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var language: String { AppLanguage.effectiveCode == "en" ? "en-US" : "fr-FR" }

    func details(for item: MediaItem) -> MediaDetails? { cache[item.id] }

    func isLoading(_ item: MediaItem) -> Bool { loading.contains(item.id) }

    /// Charge la fiche (une seule fois par session).
    func load(_ item: MediaItem, store: LibraryStore) async {
        guard cache[item.id] == nil, !loading.contains(item.id) else { return }
        loading.insert(item.id)
        defer { loading.remove(item.id) }
        let isSeries = item.kind == .series

        var details = MediaDetails()
        details.title = item.name
        if let plot = item.info { details.plot = plot }
        details.posterURL = item.logoURL

        if let client = store.xtreamClient(for: item.sourceID) {
            do {
                let iptv: MediaDetails?
                if isSeries, let id = item.seriesID {
                    iptv = try await client.seriesDetails(seriesID: id)
                } else if item.kind == .movie, let id = item.id.split(separator: ":").last.map(String.init) {
                    iptv = try await client.movieDetails(streamID: id)
                } else {
                    iptv = nil
                }
                if let iptv {
                    var base = iptv
                    if base.title == nil { base.title = item.name }
                    if base.plot == nil { base.plot = details.plot }
                    if base.posterURL == nil { base.posterURL = item.logoURL }
                    details = base
                }
            } catch {
                PlaybackLog.shared.note("Fiche IPTV indisponible pour « \(item.name) » : \(error.localizedDescription)")
            }
        }

        if usesTMDB {
            let client = TMDBClient(apiKey: tmdbKey, language: language)
            do {
                if let tmdb = try await client.details(title: item.name, isSeries: isSeries,
                                                       tmdbID: details.tmdbID, year: details.year) {
                    var merged = details.merged(with: tmdb)
                    // Le titre affiché reste celui de votre catalogue s'il n'y a pas de traduction.
                    if merged.title == nil { merged.title = item.name }
                    details = merged
                }
                errors[item.id] = nil
            } catch {
                errors[item.id] = String(localized: "TMDB n'a pas répondu (vérifiez la clé dans Réglages > Général).")
                PlaybackLog.shared.note("TMDB : échec pour « \(item.name) » : \(error.localizedDescription)")
            }
        }
        if details.sources.isEmpty { details.sources = ["IPTV"] }
        cache[item.id] = details
    }

    // MARK: Tendances (bandeau Cinéma)

    @ObservationIgnored private var trendingCache: [Bool: (date: Date, list: [TMDBTrend])] = [:]
    @ObservationIgnored private var titleIndex: [MediaKind: (count: Int, index: [String: MediaItem])] = [:]

    /// Films ou séries en tendance cette semaine (TMDB), mis en cache 6 h.
    func trending(isSeries: Bool) async -> [TMDBTrend] {
        guard usesTMDB else { return [] }
        if let cached = trendingCache[isSeries], Date().timeIntervalSince(cached.date) < 6 * 3600 { return cached.list }
        do {
            let list = try await TMDBClient(apiKey: tmdbKey, language: language).trending(isSeries: isSeries)
            trendingCache[isSeries] = (Date(), list)
            return list
        } catch {
            PlaybackLog.shared.note("TMDB : tendances indisponibles (\(error.localizedDescription))")
            return []
        }
    }

    /// Retrouve les tendances dans votre catalogue (par titre nettoyé, puis titre original).
    func match(_ trends: [TMDBTrend], in items: [MediaItem], kind: MediaKind) async -> [(item: MediaItem, trend: TMDBTrend)] {
        let index: [String: MediaItem]
        if let cached = titleIndex[kind], cached.count == items.count {
            index = cached.index
        } else {
            index = await Task.detached(priority: .utility) { () -> [String: MediaItem] in
                var result: [String: MediaItem] = [:]
                for item in items {
                    let key = TMDB.titleKey(item.name)
                    if !key.isEmpty, result[key] == nil { result[key] = item }
                }
                return result
            }.value
            titleIndex[kind] = (items.count, index)
        }
        var found: [(item: MediaItem, trend: TMDBTrend)] = []
        for trend in trends {
            let keys = [TMDB.titleKey(trend.title)] + (trend.originalTitle.map { [TMDB.titleKey($0)] } ?? [])
            if let item = keys.lazy.compactMap({ index[$0] }).first {
                found.append((item, trend))
            }
        }
        return found
    }

    func reload(_ item: MediaItem, store: LibraryStore) async {
        cache[item.id] = nil
        await load(item, store: store)
    }
}

/// Page de présentation d'un film ou d'une série (interface Cinéma), avant la lecture.
struct MediaInfoView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(RecordingCenter.self) private var recordings
    @Environment(WatchProgressStore.self) private var watch
    @Environment(MediaInfoStore.self) private var info
    let item: MediaItem

    private var details: MediaDetails? { info.details(for: item) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                backButton
                header
                if let plot = details?.plot {
                    Text(plot)
                        .font(.body)
                        .lineSpacing(3)
                        .frame(maxWidth: 820, alignment: .leading)
                        .textSelection(.enabled)
                } else if info.isLoading(item) {
                    ProgressView().controlSize(.small)
                }
                credits
                castRail
                footer
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Le fond passe sous la barre d'outils ; le contenu, lui, commence sous la barre.
        .background { backdrop }
        .environment(\.colorScheme, .dark)
        .task(id: item.id) { await info.load(item, store: store) }
    }

    private var backButton: some View {
        Button {
            navigation.infoItemID = nil
        } label: {
            Label(String(localized: "Retour à \(sectionName)"), systemImage: "chevron.left")
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white.opacity(0.14), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.cancelAction)
        .help("Revenir au catalogue (Échap)")
    }

    private var sectionName: String {
        navigation.browse?.title ?? (item.kind == .series ? String(localized: "Séries") : String(localized: "Films"))
    }

    /// Titre lisible : celui de TMDB, sinon le nom du catalogue sans les étiquettes (« |FR| », « 4K »…).
    private var displayTitle: String {
        if let title = details?.title, details?.sources.contains("TMDB") == true { return title }
        return TMDB.cleanTitle(details?.title ?? item.name).title
    }

    // MARK: Fond

    private var backdrop: some View {
        ZStack {
            Color.black
            if let url = details?.backdropURL ?? details?.posterURL ?? item.logoURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                            .blur(radius: details?.backdropURL == nil ? 30 : 0)
                    }
                }
                .opacity(0.55)
            }
            LinearGradient(colors: [.black.opacity(0.35), .black.opacity(0.8), .black],
                           startPoint: .top, endPoint: .bottom)
        }
        .clipped()
        .ignoresSafeArea()
    }

    // MARK: En-tête

    private var header: some View {
        HStack(alignment: .bottom, spacing: 26) {
            PosterView(url: details?.posterURL ?? item.logoURL, name: item.name)
                .frame(width: 210, height: 315)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.6), radius: 18, y: 8)
            VStack(alignment: .leading, spacing: 10) {
                Text(displayTitle)
                    .font(.system(size: 36, weight: .bold))
                    .lineLimit(3)
                if let original = details?.originalTitle, original != displayTitle {
                    Text(original)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.65))
                }
                if !metaLine.isEmpty {
                    Text(metaLine)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                if let rating = details?.rating {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                        Text(rating.formatted(.number.precision(.fractionLength(1))) + " / 10")
                            .font(.callout.weight(.semibold))
                    }
                }
                if let tagline = details?.tagline {
                    Text(tagline)
                        .font(.callout.italic())
                        .foregroundStyle(.white.opacity(0.7))
                }
                actions.padding(.top, 6)
            }
            Spacer(minLength: 0)
        }
    }

    private var metaLine: String {
        var parts: [String] = []
        if let year = details?.year { parts.append(String(year)) }
        if let runtime = details?.runtime {
            let text = runtime >= 60 ? String(format: "%d h %02d", runtime / 60, runtime % 60) : "\(runtime) min"
            parts.append(item.kind == .series ? String(localized: "\(text) par épisode") : text)
        }
        if let seasons = details?.seasonCount, seasons > 0 {
            parts.append(seasons == 1 ? String(localized: "1 saison") : String(localized: "\(seasons) saisons"))
        }
        if let genres = details?.genres, !genres.isEmpty { parts.append(genres.prefix(3).joined(separator: ", ")) }
        return parts.joined(separator: " · ")
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                navigation.selectedItemID = item.id
            } label: {
                Label(playTitle, systemImage: item.needsEpisodes ? "list.bullet" : "play.fill")
                    .frame(minWidth: 110)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            if let trailer = details?.trailerURL {
                Button {
                    NSWorkspace.shared.open(trailer)
                } label: {
                    Label("Bande-annonce", systemImage: "film.stack")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .help("Ouvrir la bande-annonce dans le navigateur")
            }

            if item.kind == .movie, let url = item.streamURL, !url.isFileURL {
                Menu {
                    Button("Télécharger maintenant") { recordings.download(item, tonight: false) }
                    Button("Télécharger cette nuit") { recordings.download(item, tonight: true) }
                } label: {
                    Label("Télécharger", systemImage: "arrow.down.circle")
                }
                .menuStyle(.button)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .fixedSize()
            }

            Button {
                store.toggleFavorite(item.id)
            } label: {
                Image(systemName: store.isFavorite(item.id) ? "star.fill" : "star")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .help("Ajouter ou retirer des favoris")
        }
    }

    private var playTitle: String {
        if item.needsEpisodes { return String(localized: "Voir les épisodes") }
        if let fraction = watch.fraction(for: item.id) {
            return String(localized: "Reprendre (\(Int(fraction * 100)) %)")
        }
        return String(localized: "Lire")
    }

    // MARK: Générique

    @ViewBuilder
    private var credits: some View {
        if let directors = details?.directors, !directors.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.kind == .series ? String(localized: "Création") : String(localized: "Réalisation"))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text(directors.joined(separator: ", "))
                    .font(.callout)
            }
        }
    }

    @ViewBuilder
    private var castRail: some View {
        if let cast = details?.cast, !cast.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Distribution")
                    .font(.title3.weight(.semibold))
                if cast.contains(where: { $0.photoURL != nil }) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 16) {
                            ForEach(cast) { person in
                                CastCard(person: person)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text(cast.map(\.name).joined(separator: ", "))
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let error = info.errors[item.id] {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if let sources = details?.sources {
                HStack(spacing: 10) {
                    Text("Informations : \(sources.map { $0 == "IPTV" ? String(localized: "fournisseur IPTV") : $0 }.joined(separator: " + "))")
                    if !info.usesTMDB {
                        Text("· Ajoutez une clé TMDB dans Réglages > Général pour des fiches plus complètes.")
                    }
                    Button("Actualiser") { Task { await info.reload(item, store: store) } }
                        .buttonStyle(.link)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.top, 8)
    }
}

/// Photo et nom d'un acteur.
private struct CastCard: View {
    let person: CastMember

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(Color.white.opacity(0.12))
                if let url = person.photoURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.fill").font(.title).foregroundStyle(.white.opacity(0.4))
                        }
                    }
                } else {
                    Image(systemName: "person.fill").font(.title).foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(width: 84, height: 84)
            .clipShape(Circle())
            Text(person.name)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            if let role = person.role {
                Text(role)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 100)
    }
}

/// Réglages : clé TMDB pour enrichir les fiches.
struct MediaInfoSettingsSection: View {
    @Environment(MediaInfoStore.self) private var info
    @State private var draft = ""
    @State private var status: String?
    @State private var checking = false

    var body: some View {
        Section("Fiches des films et séries") {
            SecureField("Clé API TMDB (facultative)", text: $draft)
                .onSubmit(save)
            HStack {
                Button("Enregistrer et vérifier", action: save)
                    .disabled(checking)
                if !info.tmdbKey.isEmpty {
                    Button("Retirer la clé") {
                        draft = ""
                        info.tmdbKey = ""
                        status = nil
                    }
                }
                if checking { ProgressView().controlSize(.small) }
                if let status { Text(status).font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Link("Obtenir une clé gratuite", destination: URL(string: "https://www.themoviedb.org/settings/api")!)
            }
            Text("En interface Cinéma, un clic sur une affiche ouvre la fiche du film ou de la série. Les informations viennent de votre fournisseur IPTV ; avec une clé TMDB (The Movie Database), Kastideo ajoute affiches HD, photos des acteurs, bande-annonce et résumé traduit.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { draft = info.tmdbKey }
    }

    private func save() {
        let key = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        info.tmdbKey = key
        guard !key.isEmpty else { status = nil; return }
        checking = true
        status = nil
        Task {
            let ok = await TMDBClient(apiKey: key, language: "fr-FR").check()
            checking = false
            status = ok ? String(localized: "Clé valide ✓") : String(localized: "Clé refusée par TMDB")
        }
    }
}
