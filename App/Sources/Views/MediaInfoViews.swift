import SwiftUI
import AppKit
import KastideoCore

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
                    if item.kind == .movie || item.kind == .series {
                        Button("Corriger la fiche…") { navigation.fixingItem = item }
                            .buttonStyle(.link)
                    }
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
    @Environment(LibraryStore.self) private var store
    @State private var draft = ""
    @State private var status: String?
    @State private var checking = false
    @AppStorage("tmdb.personal") private var personal = true

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
            Toggle("Chercher aussi les vidéos personnelles (dossiers)", isOn: $personal)
                .help("Affiche et résumé pour vos fichiers : seul un titre identique à celui de TMDB est retenu (sinon, « Corriger la fiche »)")
            if !info.edits.isEmpty {
                DisclosureGroup("Fiches corrigées à la main (\(info.edits.count))") {
                    ForEach(info.edits.keys.sorted(), id: \.self) { id in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.item(id: id)?.name ?? String(localized: "Contenu absent du catalogue"))
                                if let edit = info.edits[id] {
                                    Text([edit.tmdbID.map { "TMDB \($0)" }, edit.title, edit.year.map(String.init)]
                                        .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Retirer") {
                                if let item = store.item(id: id) {
                                    Task { await info.setEdit(item, nil, store: store) }
                                } else {
                                    info.discardEdit(id: id)
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
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
