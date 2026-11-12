import SwiftUI
import KastideoCore

/// « Corriger la fiche… » : code ou adresse TMDB, recherche par titre, ou textes et affiche saisis à la main.
struct IOSFixDetailsSheet: View {
    let item: MediaItem
    @Environment(LibraryStore.self) private var store
    @Environment(MediaInfoStore.self) private var info
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var preview: MediaDetails?
    @State private var codeProblem: String?
    @State private var checking = false

    @State private var title = ""
    @State private var year = ""
    @State private var results: [TMDBMatch] = []
    @State private var searching = false
    @State private var message: String?

    @State private var customTitle = ""
    @State private var customYear = ""
    @State private var customPoster = ""
    @State private var customPlot = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item.name).font(.footnote).foregroundStyle(.secondary).lineLimit(2)
                    if !info.usesTMDB {
                        Label("Ajoutez une clé TMDB (Réglages) pour chercher les fiches.", systemImage: "key")
                            .foregroundStyle(.orange)
                    }
                    if let current = info.edits[item.id], !current.isEmpty {
                        Label(currentSummary(current), systemImage: "link").font(.callout)
                        Button("Retirer la correction", role: .destructive) {
                            Task {
                                await info.setEdit(item, nil, store: store)
                                dismiss()
                            }
                        }
                    }
                }

                Section {
                    TextField("Numéro ou adresse TMDB", text: $code)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .onSubmit { Task { await check() } }
                    Button {
                        Task { await check() }
                    } label: {
                        if checking { ProgressView() } else { Text("Vérifier") }
                    }
                    .disabled(!info.usesTMDB || checking || code.trimmingCharacters(in: .whitespaces).isEmpty)
                    if let codeProblem { Text(codeProblem).font(.callout).foregroundStyle(.orange) }
                    if let preview {
                        HStack(alignment: .top, spacing: 12) {
                            ArtworkView(url: preview.posterURL, name: preview.title ?? "", contentMode: .fill)
                                .frame(width: 54, height: 81)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preview.year.map { "\(preview.title ?? "") (\(String($0)))" } ?? (preview.title ?? ""))
                                    .font(.headline)
                                if let plot = preview.plot {
                                    Text(plot).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                                }
                                Button("Utiliser cette fiche") {
                                    Task {
                                        var edit = info.edits[item.id] ?? FicheEdit()
                                        edit.tmdbID = preview.tmdbID
                                        await info.setEdit(item, edit, store: store)
                                        dismiss()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                } header: {
                    Text("Code TMDB")
                } footer: {
                    Text("Sur themoviedb.org, ouvrez la bonne fiche : le numéro est dans l'adresse (…/movie/12345-hero). Saisissez ce numéro ou collez l'adresse.")
                }

                Section("Chercher par titre") {
                    TextField("Titre", text: $title).onSubmit { Task { await search() } }
                    TextField("Année", text: $year).keyboardType(.numberPad)
                    Button {
                        Task { await search() }
                    } label: {
                        if searching { ProgressView() } else { Text("Chercher") }
                    }
                    .disabled(!info.usesTMDB || searching || title.trimmingCharacters(in: .whitespaces).isEmpty)
                    if let message { Text(message).font(.callout).foregroundStyle(.secondary) }
                    ForEach(results) { match in
                        Button {
                            Task {
                                await info.applyFix(item, match: match, store: store)
                                dismiss()
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                ArtworkView(url: match.posterURL, name: match.title, contentMode: .fill)
                                    .frame(width: 54, height: 81)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(match.year.map { "\(match.title) (\(String($0))) · TMDB \(match.tmdbID)" } ?? "\(match.title) · TMDB \(match.tmdbID)")
                                        .font(.headline).multilineTextAlignment(.leading)
                                    if let overview = match.overview {
                                        Text(overview).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    TextField("Titre affiché", text: $customTitle)
                    TextField("Année", text: $customYear).keyboardType(.numberPad)
                    TextField("Adresse de l'affiche (https://…)", text: $customPoster)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    TextField("Résumé", text: $customPlot, axis: .vertical).lineLimit(3...8)
                    Button("Enregistrer") {
                        Task {
                            var edit = info.edits[item.id] ?? FicheEdit()
                            edit.title = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            edit.year = Int(customYear.trimmingCharacters(in: .whitespaces))
                            edit.poster = customPoster.trimmingCharacters(in: .whitespacesAndNewlines)
                            edit.plot = customPlot.trimmingCharacters(in: .whitespacesAndNewlines)
                            await info.setEdit(item, edit, store: store)
                            dismiss()
                        }
                    }
                } header: {
                    Text("Personnaliser la fiche à la main")
                } footer: {
                    Text("Les champs remplis remplacent ceux du fournisseur et de TMDB. Laissez vide pour ne rien changer.")
                }
            }
            .navigationTitle("Corriger la fiche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } } }
            .task {
                let cleaned = TMDB.cleanTitle(item.name)
                title = cleaned.title
                year = cleaned.year.map(String.init) ?? ""
                if let current = info.edits[item.id] {
                    code = current.tmdbID ?? ""
                    customTitle = current.title ?? ""
                    customYear = current.year.map(String.init) ?? ""
                    customPoster = current.poster ?? ""
                    customPlot = current.plot ?? ""
                }
                if info.usesTMDB, info.edits[item.id] == nil { await search() }
            }
        }
    }

    private func currentSummary(_ edit: FicheEdit) -> String {
        var parts: [String] = []
        if let id = edit.tmdbID, !id.isEmpty { parts.append("TMDB \(id)") }
        if edit.title?.isEmpty == false { parts.append(String(localized: "titre")) }
        if edit.year != nil { parts.append(String(localized: "année")) }
        if edit.posterURL != nil { parts.append(String(localized: "affiche")) }
        if edit.plot?.isEmpty == false { parts.append(String(localized: "résumé")) }
        return String(localized: "Correction en place") + " : " + parts.joined(separator: ", ")
    }

    private func check() async {
        checking = true
        codeProblem = nil
        preview = nil
        defer { checking = false }
        let result = await info.lookup(code, for: item)
        preview = result.details
        codeProblem = result.problem
    }

    private func search() async {
        searching = true
        defer { searching = false }
        do {
            results = try await info.searchTMDB(title: title, isSeries: item.kind == .series,
                                                year: Int(year.trimmingCharacters(in: .whitespaces)))
            message = results.isEmpty ? String(localized: "Aucun résultat : essayez un autre titre, sans l'année.") : nil
        } catch {
            message = String(localized: "TMDB n'a pas répondu (vérifiez la clé dans Réglages).")
        }
    }
}

/// Réglages : clé TMDB, vidéos personnelles, corrections faites à la main.
struct IOSTMDBSettingsSection: View {
    @Environment(MediaInfoStore.self) private var info
    @Environment(LibraryStore.self) private var store
    @State private var draft = ""
    @State private var status: String?
    @State private var checking = false
    @AppStorage("tmdb.personal") private var personal = true

    var body: some View {
        Section {
            SecureField("Clé API TMDB (facultative)", text: $draft)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .onSubmit(save)
            Button("Enregistrer et vérifier", action: save).disabled(checking)
            if checking { ProgressView() }
            if let status { Text(status).font(.caption).foregroundStyle(.secondary) }
            if !info.tmdbKey.isEmpty {
                Button("Retirer la clé", role: .destructive) {
                    draft = ""
                    info.tmdbKey = ""
                    status = nil
                }
            }
            Link(destination: URL(string: "https://www.themoviedb.org/settings/api")!) {
                Label("Obtenir une clé gratuite", systemImage: "key")
            }
            Toggle("Chercher aussi les vidéos personnelles", isOn: $personal)
            if !info.edits.isEmpty {
                DisclosureGroup("Fiches corrigées à la main (\(info.edits.count))") {
                    ForEach(info.edits.keys.sorted(), id: \.self) { id in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.item(id: id)?.name ?? String(localized: "Contenu absent du catalogue")).lineLimit(2)
                                if let edit = info.edits[id] {
                                    Text([edit.tmdbID.map { "TMDB \($0)" }, edit.title, edit.year.map(String.init)]
                                        .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                        .font(.caption).foregroundStyle(.secondary)
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
        } header: {
            Text("Fiches des films et séries")
        } footer: {
            Text("Les informations viennent de votre fournisseur IPTV ; avec une clé TMDB (The Movie Database), Kastideo ajoute affiches HD, photos des acteurs, bande-annonce, résumé traduit et les tendances de la semaine dans le bandeau Cinéma.")
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
