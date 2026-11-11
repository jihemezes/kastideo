import SwiftUI
import UniformTypeIdentifiers
import KastideoCore

/// Document JSON de configuration (même format « kastideo-export » que sur Mac, Windows, Linux et Android).
struct ConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
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
    @State private var diagnostic: Source?
    @State private var editing: Source?

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
                        .contentShape(Rectangle())
                        .onTapGesture { editing = source }
                        .contextMenu {
                            Button { editing = source } label: { Label("Modifier", systemImage: "pencil") }
                        }
                        .swipeActions {
                            Button { editing = source } label: { Label("Modifier", systemImage: "pencil") }
                                .tint(.orange)
                            Button(role: .destructive) { store.removeSource(source.id) } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                            Button { store.refresh(source) } label: {
                                Label("Actualiser", systemImage: "arrow.clockwise")
                            }
                            .tint(.blue)
                            Button { diagnostic = source } label: {
                                Label("Diagnostic", systemImage: "stethoscope")
                            }
                            .tint(.gray)
                        }
                    }
                    Button { ui.showAddSource = true } label: { Label("Ajouter une source", systemImage: "plus.circle") }
                    Button { store.refreshAll() } label: { Label("Tout actualiser", systemImage: "arrow.clockwise") }
                        .disabled(!store.hasSources || store.isBusy)
                }

                IOSActiveSourceSection()

                Section("Lecture") {
                    Picker("Mise en mémoire", selection: $buffering) {
                        ForEach(BufferingMode.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Toggle("Reprendre les films et épisodes là où on s'est arrêté", isOn: $resume)
                    Toggle("Relais de flux (si un fournisseur refuse la connexion)", isOn: $relay)
                }

                IOSMultiViewSettingsSection()
                IOSYouTubeSettingsSection()
                IOSTimeshiftSection()
                Section {
                    NavigationLink { IOSRecordingsView() } label: {
                        Label("Enregistrements et téléchargements", systemImage: "tray.full")
                    }
                    NavigationLink { IOSAlertsView() } label: {
                        Label("Alertes de programmes", systemImage: "bell.badge")
                    }
                }
                IOSReplaySection()
                IOSCinemaSection()

                IOSAppearanceSection()
                IOSOrganisationSection()

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
            .sheet(item: $editing) { source in
                NavigationStack { IOSAddSourceView(existing: source) }
            }
            .sheet(item: $diagnostic) { source in
                IOSSourceDiagnosticSheet(source: source)
            }
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
