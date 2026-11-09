import SwiftUI
import UniformTypeIdentifiers
import KastideoCore

/// Document JSON de configuration (même format « kastideo-export » que sur Mac, Windows, Linux et Android).
struct ConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfigurationFileDocumentConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct IOSSettingsView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSUI.self) private var ui
    @AppStorage("ios.appearance") private var appearance = "dark"
    @AppStorage(PlaybackKeys.buffering) private var buffering = BufferingMode.fast.rawValue
    @AppStorage(PlaybackKeys.resume) private var resume = true
    @AppStorage("adult.show") private var showAdult = false
    @AppStorage("relay.enabled") private var relay = true
    @State private var importing = false
    @State private var exporting = false
    @State private var exportDocument = ConfigDocument(data: Data())
    @State private var includePasswords = true
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Sources") {
                    ForEach(store.sources) { source in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.name).font(.body.weight(.medium))
                                Text(subtitle(for: source)).font(.caption).foregroundStyle(.secondary)
                                if let error = store.errors[source.id] {
                                    Text(error).font(.caption).foregroundStyle(.red)
                                }
                            }
                            Spacer()
                            if store.loading.contains(source.id) { ProgressView() }
                            Toggle("", isOn: Binding(get: { source.isEnabled }, set: { store.setEnabled(source.id, $0) }))
                                .labelsHidden()
                        }
                        .swipeActions {
                            Button(role: .destructive) { store.removeSource(source.id) } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                            Button { store.refresh(source) } label: {
                                Label("Actualiser", systemImage: "arrow.clockwise")
                            }
                            .tint(.blue)
                        }
                    }
                    Button { ui.showAddSource = true } label: { Label("Ajouter une source", systemImage: "plus.circle") }
                    Button { store.refreshAll() } label: { Label("Tout actualiser", systemImage: "arrow.clockwise") }
                        .disabled(!store.hasSources || store.isBusy)
                }

                Section("Lecture") {
                    Picker("Mise en mémoire", selection: $buffering) {
                        ForEach(BufferingMode.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Toggle("Reprendre les films et épisodes là où on s'est arrêté", isOn: $resume)
                    Toggle("Relais de flux (si un fournisseur refuse la connexion)", isOn: $relay)
                }

                Section("Apparence") {
                    Picker("Thème", selection: $appearance) {
                        Text("Sombre").tag("dark")
                        Text("Clair").tag("light")
                        Text("Comme le système").tag("system")
                    }
                    Toggle("Afficher les chaînes pour adultes", isOn: $showAdult)
                        .onChange(of: showAdult) { _, _ in store.refreshAdultFilter() }
                }

                Section {
                    Toggle("Inclure les mots de passe", isOn: $includePasswords)
                    Button { exportConfig() } label: { Label("Exporter la configuration…", systemImage: "square.and.arrow.up") }
                    Button { importing = true } label: { Label("Importer une configuration…", systemImage: "square.and.arrow.down") }
                    if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
                } header: {
                    Text("Sauvegarde")
                } footer: {
                    Text("Même fichier que sur Mac, Windows, Linux et Android : enregistrez-le dans iCloud Drive pour le retrouver sur tous vos appareils.")
                }

                Section("À propos") {
                    LabeledContent("Version", value: ReleaseNotes.currentVersion)
                    if FileManager.default.fileExists(atPath: PlaybackLog.currentFile.path) {
                        ShareLink(item: PlaybackLog.currentFile) { Label("Partager le journal de lecture", systemImage: "doc.text") }
                    }
                    Button { ui.showDisclaimer = true } label: { Label("Avertissement", systemImage: "exclamationmark.shield") }
                    Link(destination: Support.url) { Label("Offrir un café (Ko-fi)", systemImage: "cup.and.saucer") }
                    Link(destination: URL(string: "https://github.com/jihemezes/kastideo")!) { Label("Kastideo sur GitHub", systemImage: "chevron.left.forwardslash.chevron.right") }
                }
            }
            .navigationTitle("Réglages")
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                importConfig(result)
            }
            .fileExporter(isPresented: $exporting, document: exportDocument, contentType: .json,
                          defaultFilename: "Kastideo-configuration") { result in
                if case .success = result { message = String(localized: "Configuration exportée.") }
            }
        }
    }

    private func subtitle(for source: Source) -> String {
        switch source.kind {
        case .xtream(let server, _): return "Xtream Codes · \(server.host ?? "")"
        case .m3uURL(let url): return String(localized: "Playlist M3U") + " · \(url.host ?? "")"
        default: return source.kind.typeLabel
        }
    }

    private func exportConfig() {
        var export = store.makeExport(includePasswords: includePasswords)
        export.app = "ios"
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(export) {
            exportDocument = ConfigDocument(data: data)
            exporting = true
        }
    }

    private func importConfig(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(KastideoExport.self, from: Data(contentsOf: url))
            guard export.format == "kastideo-export" else {
                message = String(localized: "Ce fichier n'est pas une configuration Kastideo.")
                return
            }
            let summary = store.importConfig(export)
            message = String(localized: "Importation terminée : \(summary.sourcesAdded) source(s) ajoutée(s), \(summary.sourcesSkipped) déjà présente(s), \(summary.favoritesAdded) favori(s), catégories de \(summary.categoriesImported) section(s).")
        } catch {
            message = String(localized: "Fichier illisible : \(error.localizedDescription)")
        }
    }
}

// MARK: - Ajout d'une source

struct IOSAddSourceView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case xtream, m3u
        var id: String { rawValue }
    }

    @State private var mode: Mode = .xtream
    @State private var name = ""
    @State private var server = ""
    @State private var username = ""
    @State private var password = ""
    @State private var playlist = ""
    @State private var epg = ""

    private var detectedXtream: XtreamCredentials? {
        guard mode == .m3u, let url = URL(string: playlist.trimmingCharacters(in: .whitespaces)) else { return nil }
        return XtreamCredentials.fromPlaylistURL(url)
    }

    private var isValid: Bool {
        switch mode {
        case .xtream:
            return XtreamCredentials.normalizeServer(server) != nil && !username.isEmpty && !password.isEmpty
        case .m3u:
            guard let url = URL(string: playlist.trimmingCharacters(in: .whitespaces)), let scheme = url.scheme?.lowercased() else { return false }
            return scheme == "http" || scheme == "https"
        }
    }

    var body: some View {
        Form {
            Picker("Type", selection: $mode) {
                Text("Xtream Codes").tag(Mode.xtream)
                Text("Liste M3U (URL)").tag(Mode.m3u)
            }
            .pickerStyle(.segmented)

            Section("Nom (facultatif)") {
                TextField("Mon abonnement IPTV", text: $name)
            }

            switch mode {
            case .xtream:
                Section("Connexion") {
                    TextField("Serveur (http://exemple.com:8080)", text: $server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    TextField("Identifiant", text: $username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Mot de passe", text: $password)
                }
            case .m3u:
                Section("Playlist") {
                    TextField("https://…/playlist.m3u", text: $playlist)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    if detectedXtream != nil {
                        Label("Adresse Xtream détectée : la source sera enregistrée en Xtream Codes (chargement plus rapide, guide TV inclus).",
                              systemImage: "bolt.fill")
                            .font(.footnote).foregroundStyle(IOSPalette.orange)
                    }
                }
            }

            Section("Guide TV (facultatif)") {
                TextField("URL XMLTV", text: $epg)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
            }
        }
        .navigationTitle("Ajouter une source")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Ajouter") { save() }.disabled(!isValid) }
        }
    }

    private func save() {
        let kind: SourceKind
        var pass: String?
        var defaultName = String(localized: "Mon abonnement IPTV")
        switch mode {
        case .xtream:
            guard let url = XtreamCredentials.normalizeServer(server) else { return }
            kind = .xtream(server: url, username: username.trimmingCharacters(in: .whitespaces))
            pass = password
            defaultName = url.host ?? defaultName
        case .m3u:
            guard let url = URL(string: playlist.trimmingCharacters(in: .whitespaces)) else { return }
            if let credentials = detectedXtream {
                kind = .xtream(server: credentials.server, username: credentials.username)
                pass = credentials.password
            } else {
                kind = .m3uURL(url)
            }
            defaultName = url.host ?? String(localized: "Ma playlist")
        }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let epgText = epg.trimmingCharacters(in: .whitespaces)
        let source = Source(name: trimmed.isEmpty ? defaultName : trimmed, kind: kind,
                            epgURL: epgText.isEmpty ? nil : URL(string: epgText))
        store.addSource(source, password: pass)
        dismiss()
    }
}
