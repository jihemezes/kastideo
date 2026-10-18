import SwiftUI
import UniformTypeIdentifiers
import KastideoCore

/// Ajout ou modification d'une source (Xtream Codes, playlist M3U par URL ou fichier).
struct SourceEditorView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case xtream, m3uURL, m3uFile
        var id: String { rawValue }
        var label: String {
            switch self {
            case .xtream: return "Xtream Codes"
            case .m3uURL: return "Playlist (URL)"
            case .m3uFile: return "Playlist (fichier)"
            }
        }
    }

    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let existing: Source?

    @State private var mode: Mode = .xtream
    @State private var name = ""
    @State private var server = ""
    @State private var username = ""
    @State private var password = ""
    @State private var playlistURL = ""
    @State private var fileBookmark: Data?
    @State private var fileName = ""
    @State private var epgURL = ""
    @State private var showImporter = false
    @State private var testing = false
    @State private var testResult: (ok: Bool, message: String)?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Picker("Type de source", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .disabled(existing != nil)
                    TextField("Nom affiché", text: $name, prompt: Text(defaultName))
                }

                switch mode {
                case .xtream:
                    Section {
                        TextField("Serveur", text: $server, prompt: Text("http://exemple.com:8080"))
                        TextField("Identifiant", text: $username)
                            .textContentType(.username)
                        SecureField("Mot de passe", text: $password,
                                    prompt: Text(existing == nil ? "" : "Inchangé si laissé vide"))
                    } header: {
                        Text("Connexion")
                    } footer: {
                        Text("Le mot de passe est enregistré dans le trousseau macOS. Les chaînes en direct sont lues au format HLS (.m3u8).")
                    }
                case .m3uURL:
                    Section {
                        TextField("Adresse M3U / M3U8", text: $playlistURL, prompt: Text("http://exemple.com/get.php?…"))
                    } header: {
                        Text("Playlist")
                    } footer: {
                        if detectedXtream != nil {
                            Label("Adresse Xtream détectée : la source sera enregistrée en Xtream Codes (chargement bien plus rapide, guide TV inclus, mot de passe dans le trousseau).",
                                  systemImage: "bolt.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                case .m3uFile:
                    Section("Playlist") {
                        HStack {
                            Text(fileName.isEmpty ? "Aucun fichier choisi" : fileName)
                                .foregroundStyle(fileName.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                            Spacer()
                            Button("Choisir…") { showImporter = true }
                        }
                    }
                }

                Section {
                    TextField("Adresse du guide TV (XMLTV)", text: $epgURL, prompt: Text("Facultatif"))
                } header: {
                    Text("Guide TV")
                } footer: {
                    Text(mode == .xtream
                         ? "Laissez vide pour utiliser le guide fourni par le serveur Xtream."
                         : "Laissez vide pour utiliser le guide annoncé dans la playlist (url-tvg), s'il existe. Les fichiers .xml.gz sont acceptés.")
                }

                if let testResult {
                    Section {
                        Label(testResult.message, systemImage: testResult.ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .foregroundStyle(testResult.ok ? .green : .red)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                if mode == .xtream {
                    Button {
                        Task { await test() }
                    } label: {
                        if testing { ProgressView().controlSize(.small) } else { Text("Tester la connexion") }
                    }
                    .disabled(!isValid || testing)
                }
                Spacer()
                Button("Annuler", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(existing == nil ? "Ajouter" : "Enregistrer") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding(16)
        }
        .frame(width: 560)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear(perform: loadExisting)
        .onChange(of: mode) { testResult = nil }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: playlistTypes) { result in
            if case .success(let url) = result { pickFile(url) }
        }
    }

    // MARK: - Logique

    private var playlistTypes: [UTType] {
        var types: [UTType] = [.m3uPlaylist, .plainText]
        if let m3u8 = UTType(filenameExtension: "m3u8") { types.append(m3u8) }
        return types
    }

    /// Identifiants Xtream contenus dans l'adresse de playlist, s'il y en a.
    private var detectedXtream: XtreamCredentials? {
        guard mode == .m3uURL, let url = URL(string: playlistURL.trimmingCharacters(in: .whitespaces)) else { return nil }
        return XtreamCredentials.fromPlaylistURL(url)
    }

    private var defaultName: String {
        switch mode {
        case .xtream: return XtreamCredentials.normalizeServer(server)?.host ?? "Mon abonnement IPTV"
        case .m3uURL: return URL(string: playlistURL)?.host ?? "Ma playlist"
        case .m3uFile: return fileName.isEmpty ? "Ma playlist" : fileName
        }
    }

    private var isValid: Bool {
        switch mode {
        case .xtream:
            let hasPassword = !password.isEmpty || existing != nil
            return XtreamCredentials.normalizeServer(server) != nil && !username.isEmpty && hasPassword
        case .m3uURL:
            guard let url = URL(string: playlistURL.trimmingCharacters(in: .whitespaces)), let scheme = url.scheme?.lowercased() else { return false }
            return scheme == "http" || scheme == "https"
        case .m3uFile:
            return fileBookmark != nil
        }
    }

    private func loadExisting() {
        guard let existing else { return }
        name = existing.name
        epgURL = existing.epgURL?.absoluteString ?? ""
        switch existing.kind {
        case .xtream(let url, let user):
            mode = .xtream; server = url.absoluteString; username = user
        case .m3uURL(let url):
            mode = .m3uURL; playlistURL = url.absoluteString
        case .m3uFile(let bookmark, let display):
            mode = .m3uFile; fileBookmark = bookmark; fileName = display
        }
    }

    private func pickFile(_ url: URL) {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        do {
            fileBookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            fileName = url.lastPathComponent
            testResult = nil
        } catch {
            testResult = (false, "Impossible d'accéder au fichier : \(error.localizedDescription)")
        }
    }

    private func test() async {
        guard let url = XtreamCredentials.normalizeServer(server) else { return }
        var pass = password
        if pass.isEmpty, let existing { pass = store.password(for: existing) ?? "" }
        testing = true
        defer { testing = false }
        do {
            let account = try await XtreamClient(credentials: XtreamCredentials(server: url, username: username, password: pass),
                                                 sourceID: UUID()).account()
            var message = "Connexion réussie — compte \(account.status)"
            if let expiration = account.expiration {
                message += ", expire le \(expiration.formatted(date: .long, time: .omitted))"
            }
            if let max = account.maxConnections { message += ", \(max) connexion(s) simultanée(s)" }
            testResult = (true, message)
        } catch {
            testResult = (false, LibraryStore.describe(error))
        }
    }

    private func save() {
        let kind: SourceKind
        switch mode {
        case .xtream:
            guard let url = XtreamCredentials.normalizeServer(server) else { return }
            kind = .xtream(server: url, username: username.trimmingCharacters(in: .whitespaces))
        case .m3uURL:
            guard let url = URL(string: playlistURL.trimmingCharacters(in: .whitespaces)) else { return }
            if let credentials = detectedXtream {
                kind = .xtream(server: credentials.server, username: credentials.username)
            } else {
                kind = .m3uURL(url)
            }
        case .m3uFile:
            guard let bookmark = fileBookmark else { return }
            kind = .m3uFile(bookmark: bookmark, displayName: fileName)
        }
        let trimmedEPG = epgURL.trimmingCharacters(in: .whitespaces)
        let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty ? defaultName : name
        let source = Source(id: existing?.id ?? UUID(), name: finalName, kind: kind,
                            epgURL: trimmedEPG.isEmpty ? nil : URL(string: trimmedEPG),
                            isEnabled: existing?.isEnabled ?? true, lastRefresh: existing?.lastRefresh)
        let pass = mode == .xtream ? password : detectedXtream?.password
        if existing == nil {
            store.addSource(source, password: pass)
        } else {
            store.updateSource(source, password: pass)
        }
        dismiss()
    }
}
