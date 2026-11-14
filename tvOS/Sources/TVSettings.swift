import SwiftUI
import KastideoCore

/// Réglages : sources (ajout, modification, suppression), page de départ, catégories, lecture, TMDB, à propos.
struct TVSettingsView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(TVUI.self) private var ui
    @Environment(MediaInfoStore.self) private var info
    @AppStorage("start.live") private var startLive = "all"
    @AppStorage("start.movie") private var startMovie = "all"
    @AppStorage("start.series") private var startSeries = "all"
    @AppStorage(PlaybackKeys.buffering) private var buffering = BufferingMode.fast.rawValue
    @AppStorage(PlaybackKeys.resume) private var resume = true
    @AppStorage("decode.always") private var softwareDecoding = false
    @AppStorage("tv.zapMode") private var zapMode = "confirm"
    @AppStorage("adult.show") private var adult = false

    var body: some View {
        NavigationStack {
            List {
                Section("Sources") {
                    ForEach(store.sources) { source in
                        NavigationLink {
                            TVSourceDetailView(source: source)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(source.name)
                                    Text(source.kind.typeLabel).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if store.loading.contains(source.id) { ProgressView() }
                            }
                        }
                    }
                    NavigationLink("Ajouter depuis un téléphone (QR code)") { TVRemoteSetupView() }
                    NavigationLink("Ajouter une source au clavier…") { TVAddSourceView() }
                    if store.hasSources {
                        Button("Tout actualiser") { store.refreshAll() }
                    }
                }
                Section("Page de départ") {
                    startPicker(.live, $startLive)
                    startPicker(.movie, $startMovie)
                    startPicker(.series, $startSeries)
                }
                Section("Catégories") {
                    NavigationLink("Catégories du direct") { TVCategoriesView(kind: .live) }
                    NavigationLink("Catégories des films") { TVCategoriesView(kind: .movie) }
                    NavigationLink("Catégories des séries") { TVCategoriesView(kind: .series) }
                    Toggle("Afficher les chaînes adultes", isOn: Binding(get: { adult }, set: { adult = $0; store.refreshAdultFilter() }))
                }
                Section("Lecture") {
                    TVChoiceRow(title: String(localized: "Zapping ↑ / ↓"), options: [
                        TVOption(value: "confirm", label: String(localized: "Avec confirmation (liste + clic)")),
                        TVOption(value: "direct", label: String(localized: "Direct (changement immédiat)"))], selection: $zapMode)
                    TVChoiceRow(title: String(localized: "Mémoire tampon"),
                                options: BufferingMode.allCases.map { TVOption(value: $0.rawValue, label: $0.label) }, selection: $buffering)
                    Toggle("Reprendre les films là où je me suis arrêté", isOn: $resume)
                    Toggle("Toujours décoder en logiciel (flux qui se figent)", isOn: $softwareDecoding)
                }
                Section("TMDB") {
                    SecureField("Clé API TMDB (facultatif)", text: Binding(get: { info.tmdbKey }, set: { info.tmdbKey = $0 }))
                    Text("Affiches, résumés, distribution et tendances sur l'Accueil et les fiches.").font(.callout).foregroundStyle(.secondary)
                }
                Section {
                    Text("La synchronisation iCloud n'est pas disponible sur Apple TV : ajoutez votre source depuis un téléphone (QR code) ou au clavier.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Section("À propos") {
                    Text("Kastideo \(ReleaseNotes.currentVersion)")
                    Button("Avertissement légal") { ui.showDisclaimer = true }
                    Text("Kastideo est un lecteur : il ne fournit aucun contenu.").font(.callout).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Réglages")
        }
    }

    private func startPicker(_ kind: MediaKind, _ selection: Binding<String>) -> some View {
        let names = store.categoriesByKind[kind] ?? []
        var options = [TVOption(value: "all", label: String(localized: "Première catégorie")),
                       TVOption(value: "favorites", label: String(localized: "Favoris")),
                       TVOption(value: "recents", label: String(localized: "Récents")),
                       TVOption(value: "last", label: String(localized: "Dernière consultée"))]
        options += names.map { TVOption(value: StartPage.categoryValue($0), label: $0) }
        return TVChoiceRow(title: kind.title, options: options, selection: selection)
    }
}

/// Afficher ou masquer les catégories d'un type de contenu.
struct TVCategoriesView: View {
    let kind: MediaKind
    @Environment(LibraryStore.self) private var store

    var body: some View {
        let names = store.allCategoriesByKind[kind] ?? []
        let prefs = store.prefs(for: kind)
        List {
            Button("Tout afficher") { store.updateCategories(kind) { $0.hidden = []; $0.keywords = [] } }
            ForEach(names, id: \.self) { name in
                let hidden = prefs.isHidden(name)
                Button {
                    store.updateCategories(kind) { p in
                        if p.hidden.contains(name) { p.hidden.remove(name) } else { p.hidden.insert(name) }
                    }
                } label: {
                    HStack {
                        Text(prefs.renames[name] ?? name).foregroundStyle(hidden ? .secondary : .primary)
                        Spacer()
                        Image(systemName: hidden ? "eye.slash" : "checkmark.circle.fill")
                    }
                }
            }
        }
        .navigationTitle(kind.title)
    }
}

/// Une source : modifier, actualiser, supprimer.
struct TVSourceDetailView: View {
    let source: Source
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var server: String
    @State private var username: String
    @State private var password = ""
    @State private var epg: String
    @State private var confirmDelete = false
    @State private var saved = false

    init(source: Source) {
        self.source = source
        _name = State(initialValue: source.name)
        var server = "", user = ""
        switch source.kind {
        case .xtream(let url, let u): server = url.absoluteString; user = u
        case .m3uURL(let url): server = url.absoluteString
        default: break
        }
        _server = State(initialValue: server)
        _username = State(initialValue: user)
        _epg = State(initialValue: source.epgURL?.absoluteString ?? "")
    }

    private var isXtream: Bool { if case .xtream = source.kind { return true } else { return false } }
    private var isURL: Bool { if case .m3uURL = source.kind { return true } else { return isXtream } }

    var body: some View {
        Form {
            Section("Source") {
                TextField("Nom", text: $name)
                if isURL {
                    TextField(isXtream ? "Serveur (http://…)" : "Adresse de la liste (http://…)", text: $server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                if isXtream {
                    TextField("Identifiant", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Nouveau mot de passe (vide = inchangé)", text: $password)
                }
                if isURL {
                    TextField("Guide TV XMLTV (facultatif)", text: $epg).textInputAutocapitalization(.never).autocorrectionDisabled()
                }
            }
            Section {
                Button("Enregistrer et actualiser", action: save)
                Button("Actualiser") { store.refresh(source) }
                Button("Supprimer cette source", role: .destructive) { confirmDelete = true }
                if saved { Label("Enregistré", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
            }
        }
        .navigationTitle(source.name)
        .confirmationDialog("Supprimer « \(source.name) » ?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                store.removeSource(source.id)
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private func save() {
        var updated = source
        let title = name.trimmingCharacters(in: .whitespaces)
        if !title.isEmpty { updated.name = title }
        if isURL {
            var text = server.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.contains("://") { text = "http://" + text }
            if let url = URL(string: text), url.host != nil {
                if isXtream {
                    updated.kind = .xtream(server: url, username: username.trimmingCharacters(in: .whitespaces))
                } else {
                    updated.kind = .m3uURL(url)
                }
            }
            let guide = epg.trimmingCharacters(in: .whitespaces)
            updated.epgURL = guide.isEmpty ? nil : URL(string: guide)
        }
        store.updateSource(updated, password: password)
        saved = true
    }
}

/// Ajout d'une source Xtream Codes ou d'une liste M3U (adresse).
struct TVAddSourceView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var mode = 0
    @State private var name = ""
    @State private var server = ""
    @State private var username = ""
    @State private var password = ""
    @State private var error: String?

    var body: some View {
        Form {
            Picker("Type", selection: $mode) {
                Text("Xtream Codes").tag(0)
                Text("Liste M3U (adresse)").tag(1)
            }
            TextField("Nom (facultatif)", text: $name)
            TextField(mode == 0 ? "Serveur (http://…)" : "Adresse de la liste (http://…)", text: $server)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if mode == 0 {
                TextField("Identifiant", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Mot de passe", text: $password)
            }
            if let error { Text(error).foregroundStyle(.red) }
            Button("Ajouter", action: add)
        }
        .navigationTitle("Ajouter une source")
    }

    private func add() {
        var text = server.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.contains("://") { text = "http://" + text }
        guard let url = URL(string: text), url.host != nil else {
            error = String(localized: "Adresse invalide.")
            return
        }
        let title = name.trimmingCharacters(in: .whitespaces)
        if mode == 0 {
            let user = username.trimmingCharacters(in: .whitespaces)
            guard !user.isEmpty, !password.isEmpty else {
                error = String(localized: "Identifiant et mot de passe requis.")
                return
            }
            let source = Source(name: title.isEmpty ? (url.host ?? "Xtream") : title, kind: .xtream(server: url, username: user))
            store.addSource(source, password: password)
        } else {
            let source = Source(name: title.isEmpty ? (url.host ?? "M3U") : title, kind: .m3uURL(url))
            store.addSource(source, password: nil)
        }
        dismiss()
    }
}
