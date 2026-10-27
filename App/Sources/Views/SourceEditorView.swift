import SwiftUI
import AppKit
import UniformTypeIdentifiers
import KastideoCore

/// Ajout ou modification d'une source : abonnement IPTV (Xtream Codes, playlist M3U par URL ou fichier),
/// dossiers de vidéos (disque, clé USB, NAS) ou serveur de la maison (Jellyfin, Emby, Plex).
struct SourceEditorView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case xtream, m3uURL, m3uFile, folders, jellyfin, emby, plex
        var id: String { rawValue }
        var label: String {
            switch self {
            case .xtream: return "Xtream Codes"
            case .m3uURL: return String(localized: "Playlist (URL)")
            case .m3uFile: return String(localized: "Playlist (fichier)")
            case .folders: return String(localized: "Dossiers (disque, USB, NAS)")
            case .jellyfin: return "Jellyfin"
            case .emby: return "Emby"
            case .plex: return "Plex"
            }
        }
        var icon: String {
            switch self {
            case .xtream: return "server.rack"
            case .m3uURL: return "link"
            case .m3uFile: return "doc.text"
            case .folders: return "folder"
            case .jellyfin, .emby: return "server.rack"
            case .plex: return "play.rectangle.on.rectangle"
            }
        }
        var serverType: MediaServerType? {
            switch self {
            case .jellyfin: return .jellyfin
            case .emby: return .emby
            case .plex: return .plex
            default: return nil
            }
        }
        var isIPTV: Bool { self == .xtream || self == .m3uURL || self == .m3uFile }
    }

    /// Dossier choisi : signet du bac à sable et chemin affiché.
    struct Folder: Identifiable, Equatable {
        var bookmark: Data
        var path: String
        var id: String { path }
    }

    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let existing: Source?

    @State private var mode: Mode = .xtream
    @State private var name = ""
    @State private var server = ""
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var playlistURL = ""
    @State private var fileBookmark: Data?
    @State private var fileName = ""
    @State private var folders: [Folder] = []
    @State private var token = ""
    @State private var epgURL = ""
    @State private var showImporter = false
    @State private var testing = false
    @State private var saving = false
    @State private var testResult: (ok: Bool, message: String)?
    // Recherche sur le réseau et connexion Plex.
    @State private var scanning = false
    @State private var found: [DiscoveredServer]?
    @State private var plexPin: PlexPin?
    @State private var plexServers: [PlexServer] = []
    @State private var plexTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Picker("Type de source", selection: $mode) {
                        Section("Abonnement IPTV") {
                            ForEach([Mode.xtream, .m3uURL, .m3uFile]) { Label($0.label, systemImage: $0.icon).tag($0) }
                        }
                        Section("Vos vidéos") {
                            ForEach([Mode.folders, .jellyfin, .emby, .plex]) { Label($0.label, systemImage: $0.icon).tag($0) }
                        }
                    }
                    .disabled(existing != nil)
                    TextField("Nom affiché", text: $name, prompt: Text(defaultName))
                }

                if mode.serverType != nil, existing == nil {
                    discoverySection
                }

                switch mode {
                case .xtream:
                    Section {
                        TextField("Serveur", text: $server, prompt: Text("http://exemple.com:8080"))
                        TextField("Identifiant", text: $username)
                            .textContentType(.username)
                        passwordField(String(localized: "Mot de passe"))
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
                            Text(fileName.isEmpty ? String(localized: "Aucun fichier choisi") : fileName)
                                .foregroundStyle(fileName.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                            Spacer()
                            Button("Choisir…") { showImporter = true }
                        }
                    }
                case .folders:
                    folderSection
                case .jellyfin, .emby:
                    Section {
                        serverAddressRow(prompt: "http://192.168.1.10:8096")
                        TextField("Identifiant", text: $username)
                            .textContentType(.username)
                        passwordField(String(localized: "Mot de passe (ou clé d'API) — facultatif"))
                    } header: {
                        Text("Connexion au serveur")
                    } footer: {
                        Text("Les bibliothèques de films, de séries et de vidéos du serveur apparaissent dans Films et Séries. La lecture est directe (sans conversion) et la reprise de lecture ainsi que les contenus vus sont partagés avec le serveur et ses autres appareils.")
                    }
                case .plex:
                    plexSection
                }

                if mode.isIPTV {
                    Section {
                        TextField("Adresse du guide TV (XMLTV)", text: $epgURL, prompt: Text("Facultatif"))
                    } header: {
                        Text("Guide TV")
                    } footer: {
                        Text(mode == .xtream
                             ? String(localized: "Laissez vide pour utiliser le guide fourni par le serveur Xtream.")
                             : String(localized: "Laissez vide pour utiliser le guide annoncé dans la playlist (url-tvg), s'il existe. Les fichiers .xml.gz sont acceptés."))
                    }
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
                if mode == .xtream || mode.serverType != nil {
                    Button {
                        Task { await test() }
                    } label: {
                        if testing { ProgressView().controlSize(.small) } else { Text("Tester la connexion") }
                    }
                    .disabled(!isValid || testing)
                }
                if saving {
                    ProgressView().controlSize(.small)
                    Text(mode == .folders ? String(localized: "Examen des dossiers…") : String(localized: "Connexion au serveur…"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Annuler", role: .cancel) {
                    plexTask?.cancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button(existing == nil ? String(localized: "Ajouter") : String(localized: "Enregistrer")) {
                    Task { await save() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid || saving)
            }
            .padding(16)
        }
        .frame(width: 600)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear(perform: loadExisting)
        .onDisappear { plexTask?.cancel() }
        .onChange(of: mode) { testResult = nil }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: mode == .folders ? [.folder] : playlistTypes,
                      allowsMultipleSelection: mode == .folders) { result in
            guard case .success(let urls) = result else { return }
            if mode == .folders {
                addFolders(urls)
            } else if let url = urls.first {
                pickFile(url)
            }
        }
    }

    // MARK: - Sections

    private func passwordField(_ title: String) -> some View {
        HStack {
            Group {
                if showPassword {
                    TextField(title, text: $password, prompt: Text(existing == nil ? "" : String(localized: "Inchangé si laissé vide")))
                } else {
                    SecureField(title, text: $password, prompt: Text(existing == nil ? "" : String(localized: "Inchangé si laissé vide")))
                }
            }
            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
            .help(showPassword ? String(localized: "Masquer") : String(localized: "Afficher"))
        }
    }

    private func serverAddressRow(prompt: String) -> some View {
        TextField("Adresse du serveur", text: $server, prompt: Text(prompt))
    }

    private var discoverySection: some View {
        Section {
            HStack {
                Text("Serveurs Jellyfin, Emby ou Plex de la maison")
                Spacer()
                Button {
                    Task { await discover() }
                } label: {
                    if scanning {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Rechercher sur le réseau", systemImage: "wifi")
                    }
                }
                .disabled(scanning)
            }
            if let found {
                if found.isEmpty {
                    Text("Aucun serveur trouvé. Saisissez son adresse (ex. http://192.168.1.10:8096), ou vérifiez qu'il est allumé et sur le même réseau.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(found) { result in
                        Button {
                            choose(result)
                        } label: {
                            HStack {
                                Image(systemName: result.type == .plex ? "play.rectangle.on.rectangle" : "server.rack")
                                Text(result.name).fontWeight(.medium)
                                Text("· \(result.type.label) · \(URL(string: result.address)?.host ?? result.address)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var folderSection: some View {
        Section {
            if folders.isEmpty {
                Text("Aucun dossier pour l'instant.").foregroundStyle(.secondary)
            }
            ForEach(folders) { folder in
                HStack {
                    Image(systemName: "folder.fill").foregroundStyle(.orange)
                    Text(folder.path).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button {
                        folders.removeAll { $0 == folder }
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Retirer")
                }
            }
            Button {
                showImporter = true
            } label: {
                Label("Ajouter un dossier…", systemImage: "folder.badge.plus")
            }
        } header: {
            Text("Dossiers à examiner")
        } footer: {
            Text("Disque interne, clé ou disque USB, ou partage d'un NAS : montez d'abord le partage dans le Finder (Aller > Se connecter au serveur…), puis choisissez-le ici. Les films (« Titre (2020).mkv »), les séries (« Série S01E02 ») et les autres vidéos sont reconnus d'après leur nom ; avec une clé TMDB, ils reçoivent affiches et fiches. Les sous-titres .srt placés à côté sont chargés à la lecture.")
        }
    }

    private var plexSection: some View {
        Section {
            HStack {
                Button {
                    plexSignIn()
                } label: {
                    if let plexPin {
                        Label(String(localized: "En attente de plex.tv (\(plexPin.code))"), systemImage: "hourglass")
                    } else {
                        Label("Se connecter avec Plex", systemImage: "person.crop.circle.badge.checkmark")
                    }
                }
                .disabled(plexPin != nil)
                Text("ou saisissez le jeton du serveur ci-dessous.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !plexServers.isEmpty {
                Picker("Serveur de votre compte", selection: Binding(
                    get: { plexServers.first { $0.addresses.contains(server) }?.id ?? "" },
                    set: { id in if let chosen = plexServers.first(where: { $0.id == id }) { choosePlex(chosen) } })) {
                    Text("—").tag("")
                    ForEach(plexServers) { s in
                        Text("\(s.name) · \(s.addresses.first.flatMap { URL(string: $0)?.host } ?? "?")").tag(s.id)
                    }
                }
            }
            serverAddressRow(prompt: "http://192.168.1.10:32400")
            HStack {
                Group {
                    if showPassword {
                        TextField(existing == nil ? String(localized: "Jeton Plex (X-Plex-Token)") : String(localized: "Jeton Plex (laisser vide : inchangé)"),
                                  text: $token)
                    } else {
                        SecureField(existing == nil ? String(localized: "Jeton Plex (X-Plex-Token)") : String(localized: "Jeton Plex (laisser vide : inchangé)"),
                                    text: $token)
                    }
                }
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
            }
        } header: {
            Text("Connexion au serveur")
        } footer: {
            Text("« Se connecter avec Plex » ouvre plex.tv dans le navigateur : autorisez Kastideo, et les serveurs de votre compte sont proposés. Les bibliothèques de films et de séries apparaissent dans Films et Séries, avec la reprise de lecture partagée.")
        }
    }

    // MARK: - Logique

    /// Message d'erreur, avec la requête et la réponse exacte du serveur (diagnostic de connexion).
    static func describeWithDetail(_ error: Error) -> String {
        let message = LibraryStore.describe(error)
        guard let detail = (error as? MediaServerError)?.detail else { return message }
        return message + "\n" + detail
    }

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

    private var serverURL: URL? {
        guard let type = mode.serverType else { return nil }
        return try? MediaServerHTTP.normalize(server, type: type)
    }

    private var defaultName: String {
        switch mode {
        case .xtream: return XtreamCredentials.normalizeServer(server)?.host ?? String(localized: "Mon abonnement IPTV")
        case .m3uURL: return URL(string: playlistURL)?.host ?? String(localized: "Ma playlist")
        case .m3uFile: return fileName.isEmpty ? String(localized: "Ma playlist") : fileName
        case .folders:
            return folders.first.map { URL(fileURLWithPath: $0.path).lastPathComponent } ?? String(localized: "Mes vidéos")
        case .jellyfin, .emby, .plex: return serverURL?.host ?? mode.label
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
        case .folders:
            return !folders.isEmpty
        case .jellyfin, .emby:
            // Mot de passe facultatif : sur le réseau de la maison, un compte n'en a pas toujours.
            return serverURL != nil && !username.trimmingCharacters(in: .whitespaces).isEmpty
        case .plex:
            // Jeton facultatif : un serveur Plex peut être ouvert au réseau local sans authentification.
            return serverURL != nil
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
        case .folders(let bookmarks, let paths):
            mode = .folders
            folders = zip(bookmarks, paths).map { Folder(bookmark: $0, path: $1) }
        case .mediaServer(let type, let url, let user):
            mode = type == .plex ? .plex : (type == .emby ? .emby : .jellyfin)
            server = url.absoluteString
            username = user
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
            testResult = (false, String(localized: "Impossible d'accéder au fichier : \(error.localizedDescription)"))
        }
    }

    private func addFolders(_ urls: [URL]) {
        for url in urls where !folders.contains(where: { $0.path == url.path }) {
            do {
                folders.append(Folder(bookmark: try FolderAccess.bookmark(for: url), path: url.path))
                testResult = nil
            } catch {
                testResult = (false, String(localized: "Impossible d'accéder au dossier : \(error.localizedDescription)"))
            }
        }
    }

    private func discover() async {
        scanning = true
        found = nil
        found = await ServerDiscovery.scan()
        scanning = false
    }

    private func choose(_ result: DiscoveredServer) {
        mode = result.type == .plex ? .plex : (result.type == .emby ? .emby : .jellyfin)
        server = result.address
        if name.trimmingCharacters(in: .whitespaces).isEmpty { name = result.name }
        testResult = (true, "\(result.type.label) : \(result.address)")
    }

    private func plexSignIn() {
        plexTask?.cancel()
        testResult = nil
        plexTask = Task {
            do {
                let pin = try await PlexClient.createPin()
                plexPin = pin
                NSWorkspace.shared.open(pin.url)
                // Jusqu'à 5 minutes pour autoriser Kastideo dans la page plex.tv.
                for _ in 0..<150 {
                    try await Task.sleep(for: .seconds(2))
                    guard let value = try? await pin.poll() else { continue }
                    token = value
                    plexPin = nil
                    plexServers = (try? await PlexClient.accountServers(token: value)) ?? []
                    if let first = plexServers.first, plexServers.count == 1 { choosePlex(first) }
                    testResult = (true, plexServers.isEmpty
                                  ? String(localized: "Connecté à Plex. Indiquez l'adresse du serveur.")
                                  : String(localized: "Connecté à Plex : choisissez le serveur."))
                    return
                }
                plexPin = nil
            } catch is CancellationError {
                plexPin = nil
            } catch {
                plexPin = nil
                testResult = (false, Self.describeWithDetail(error))
            }
        }
    }

    private func choosePlex(_ chosen: PlexServer) {
        if let address = chosen.addresses.first { server = address }
        token = chosen.token
        if name.trimmingCharacters(in: .whitespaces).isEmpty { name = chosen.name }
    }

    private func test() async {
        testing = true
        defer { testing = false }
        do {
            switch mode {
            case .jellyfin, .emby:
                guard let url = serverURL else { return }
                let info = try await JellyfinClient.publicInfo(server: url)
                testResult = (true, info.map { String(localized: "Serveur trouvé : \($0)") } ?? String(localized: "Le serveur répond."))
            case .plex:
                guard let url = serverURL else { return }
                var value = token.trimmingCharacters(in: .whitespaces)
                if value.isEmpty, let existing {
                    value = ServerSession.decode(Keychain.get(account: "session.\(existing.id.uuidString)"))?.token ?? ""
                }
                let identity = try await PlexClient(server: url, sourceID: UUID(), token: value).identity()
                testResult = (true, identity.map { String(localized: "Serveur trouvé : \($0)") } ?? String(localized: "Le serveur répond."))
            default:
                guard let url = XtreamCredentials.normalizeServer(server) else { return }
                var pass = password
                if pass.isEmpty, let existing { pass = store.password(for: existing) ?? "" }
                let account = try await XtreamClient(credentials: XtreamCredentials(server: url, username: username, password: pass),
                                                     sourceID: UUID()).account()
                var message = String(localized: "Connexion réussie — compte \(account.status)")
                if let expiration = account.expiration {
                    message += String(localized: ", expire le \(expiration.formatted(date: .long, time: .omitted))")
                }
                if let max = account.maxConnections { message += String(localized: ", \(max) connexion(s) simultanée(s)") }
                testResult = (true, message)
            }
        } catch {
            testResult = (false, Self.describeWithDetail(error))
        }
    }

    private func save() async {
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
        case .folders:
            kind = .folders(bookmarks: folders.map(\.bookmark), paths: folders.map(\.path))
        case .jellyfin, .emby, .plex:
            guard let type = mode.serverType, let url = serverURL else { return }
            kind = .mediaServer(type: type, server: url, username: username.trimmingCharacters(in: .whitespaces))
        }
        let trimmedEPG = epgURL.trimmingCharacters(in: .whitespaces)
        let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty ? defaultName : name
        let source = Source(id: existing?.id ?? UUID(), name: finalName, kind: kind,
                            epgURL: mode.isIPTV && !trimmedEPG.isEmpty ? URL(string: trimmedEPG) : nil,
                            isEnabled: existing?.isEnabled ?? true, lastRefresh: existing?.lastRefresh)
        if mode.serverType != nil {
            // Serveur : identifiants vérifiés avant l'ajout, pour signaler tout de suite une erreur.
            saving = true
            defer { saving = false }
            do {
                if let existing {
                    try await store.updateMediaServer(source, password: password, token: token, accessChanged: existing.kind != kind)
                } else {
                    try await store.addMediaServer(source, password: password, token: token)
                }
                dismiss()
            } catch {
                testResult = (false, Self.describeWithDetail(error))
            }
            return
        }
        let pass = mode == .xtream ? password : detectedXtream?.password
        if existing == nil {
            store.addSource(source, password: pass)
        } else {
            store.updateSource(source, password: pass)
        }
        dismiss()
    }
}
