import SwiftUI
import UniformTypeIdentifiers
import KastideoCore

/// Ajout d'une source : abonnement IPTV (Xtream, M3U) ou « Mes vidéos » (Jellyfin, Emby, Plex, dossiers).
struct IOSAddSourceView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case xtream, m3u, jellyfin, emby, plex, folders
        /// Liste M3U importée d'un fichier (modifiable seulement : nom et guide).
        case m3uFile
        var id: String { rawValue }
        var label: String {
            switch self {
            case .xtream: return "Xtream Codes"
            case .m3u: return String(localized: "Liste M3U (URL)")
            case .jellyfin: return "Jellyfin"
            case .emby: return "Emby"
            case .plex: return "Plex"
            case .folders: return String(localized: "Dossiers de vidéos")
            case .m3uFile: return String(localized: "Liste M3U (fichier)")
            }
        }
        var isIPTV: Bool { self == .xtream || self == .m3u || self == .m3uFile }
        var serverType: MediaServerType? {
            switch self {
            case .jellyfin: return .jellyfin
            case .emby: return .emby
            case .plex: return .plex
            default: return nil
            }
        }
    }

    struct Folder: Identifiable, Hashable {
        let bookmark: Data
        let path: String
        var id: String { path }
    }

    /// Source à modifier (nil : ajout d'une nouvelle source).
    let existing: Source?
    @State private var mode: Mode
    @State private var name: String
    @State private var server: String
    @State private var username: String
    @State private var password = ""
    @State private var token = ""
    @State private var playlist: String
    @State private var epg: String
    @State private var folders: [Folder]
    @State private var pickingFolder = false
    @State private var saving = false
    @State private var testing = false
    @State private var errorText: String?
    @State private var infoText: String?

    init(existing: Source? = nil) {
        self.existing = existing
        var mode = Mode.xtream
        var server = "", username = "", playlist = ""
        var folders: [Folder] = []
        if let existing {
            switch existing.kind {
            case .xtream(let url, let user):
                mode = .xtream; server = url.absoluteString; username = user
            case .m3uURL(let url):
                mode = .m3u; playlist = url.absoluteString
            case .m3uFile:
                mode = .m3uFile
            case .folders(let bookmarks, let paths):
                mode = .folders
                folders = zip(bookmarks, paths).map { Folder(bookmark: $0, path: $1) }
            case .mediaServer(let type, let url, let user):
                mode = type == .plex ? .plex : (type == .emby ? .emby : .jellyfin)
                server = url.absoluteString; username = user
            }
        }
        _mode = State(initialValue: mode)
        _name = State(initialValue: existing?.name ?? "")
        _server = State(initialValue: server)
        _username = State(initialValue: username)
        _playlist = State(initialValue: playlist)
        _epg = State(initialValue: existing?.epgURL?.absoluteString ?? "")
        _folders = State(initialValue: folders)
    }

    private var detectedXtream: XtreamCredentials? {
        guard mode == .m3u, let url = URL(string: playlist.trimmingCharacters(in: .whitespaces)) else { return nil }
        return XtreamCredentials.fromPlaylistURL(url)
    }

    private var serverURL: URL? {
        guard let type = mode.serverType else { return nil }
        return try? MediaServerHTTP.normalize(server, type: type)
    }

    private var isValid: Bool {
        switch mode {
        case .xtream:
            return XtreamCredentials.normalizeServer(server) != nil && !username.isEmpty && (!password.isEmpty || existing != nil)
        case .m3uFile:
            return true
        case .m3u:
            guard let url = URL(string: playlist.trimmingCharacters(in: .whitespaces)), let scheme = url.scheme?.lowercased() else { return false }
            return scheme == "http" || scheme == "https"
        case .jellyfin, .emby:
            return serverURL != nil && !username.trimmingCharacters(in: .whitespaces).isEmpty
        case .plex:
            return serverURL != nil
        case .folders:
            return !folders.isEmpty
        }
    }

    var body: some View {
        Form {
            if existing == nil {
                Picker("Type", selection: $mode) {
                    Section("Abonnement IPTV") {
                        Text("Xtream Codes").tag(Mode.xtream)
                        Text("Liste M3U (URL)").tag(Mode.m3u)
                    }
                    Section("Mes vidéos") {
                        Text("Jellyfin").tag(Mode.jellyfin)
                        Text("Emby").tag(Mode.emby)
                        Text("Plex").tag(Mode.plex)
                        Text("Dossiers de vidéos").tag(Mode.folders)
                    }
                }
                .pickerStyle(.menu)
            } else {
                LabeledContent("Type", value: mode.label)
            }

            Section("Nom (facultatif)") {
                TextField(mode.isIPTV ? "Mon abonnement IPTV" : "Mes vidéos", text: $name)
            }

            switch mode {
            case .xtream:
                Section("Connexion") {
                    TextField("Serveur (http://exemple.com:8080)", text: $server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    TextField("Identifiant", text: $username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField(existing == nil ? "Mot de passe" : "Mot de passe (vide : conserver)", text: $password)
                    Button { Task { await testXtream() } } label: {
                        if testing { ProgressView() } else { Label("Tester la connexion", systemImage: "checkmark.shield") }
                    }
                    .disabled(testing || XtreamCredentials.normalizeServer(server) == nil || username.isEmpty)
                }
            case .m3uFile:
                Section {
                    Label(String(localized: "Liste importée d'un fichier : seuls le nom et le guide TV sont modifiables."), systemImage: "doc.text")
                        .font(.footnote).foregroundStyle(.secondary)
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
            case .jellyfin, .emby:
                Section {
                    TextField("Adresse (192.168.1.20 ou http://serveur:8096)", text: $server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    TextField("Identifiant", text: $username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField(existing == nil ? "Mot de passe (facultatif)" : "Mot de passe (vide : conserver)", text: $password)
                } header: {
                    Text("Serveur \(mode.label)")
                } footer: {
                    Text("Sur le réseau de la maison, l'iPhone doit être sur le même Wi-Fi que le serveur (ou relié par un VPN). Films et séries apparaissent dans Films et Séries, sous « Mes vidéos ».")
                }
            case .plex:
                Section {
                    TextField("Adresse (192.168.1.20 ou http://serveur:32400)", text: $server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    SecureField(existing == nil ? "Jeton Plex (facultatif)" : "Jeton Plex (vide : conserver)", text: $token)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                } header: {
                    Text("Serveur Plex")
                } footer: {
                    Text("Le jeton (X-Plex-Token) n'est pas nécessaire si le serveur est ouvert au réseau local.")
                }
            case .folders:
                Section {
                    ForEach(folders) { folder in
                        Label(folder.path, systemImage: "folder").font(.footnote).lineLimit(2)
                            .swipeActions { Button(role: .destructive) { folders.removeAll { $0 == folder } } label: { Label("Retirer", systemImage: "minus.circle") } }
                    }
                    Button { pickingFolder = true } label: { Label("Choisir un dossier…", systemImage: "plus.circle") }
                } header: {
                    Text("Dossiers")
                } footer: {
                    Text("Dossiers de l'iPhone, d'iCloud Drive, d'une clé USB ou d'un NAS (partage réseau ajouté dans l'app Fichiers). Films et séries sont reconnus d'après les noms de fichiers.")
                }
            }

            if mode.isIPTV {
                Section("Guide TV (facultatif)") {
                    TextField("URL XMLTV", text: $epg)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                }
            }

            if let infoText {
                Section { Text(infoText).font(.footnote).foregroundStyle(.green) }
            }
            if let errorText {
                Section { Text(errorText).font(.footnote).foregroundStyle(.red) }
            }
        }
        .navigationTitle(existing == nil ? "Ajouter une source" : "Modifier la source")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                if saving {
                    ProgressView()
                } else {
                    Button(existing == nil ? "Ajouter" : "Enregistrer") { Task { await save() } }.disabled(!isValid)
                }
            }
        }
        .fileImporter(isPresented: $pickingFolder, allowedContentTypes: [.folder], allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            for url in urls where !folders.contains(where: { $0.path == url.path }) {
                do {
                    folders.append(Folder(bookmark: try FolderAccess.bookmark(for: url), path: url.path))
                    errorText = nil
                } catch {
                    errorText = String(localized: "Impossible d'accéder au dossier : \(error.localizedDescription)")
                }
            }
        }
    }

    /// Vérifie l'adresse, l'identifiant et le mot de passe Xtream (celui déjà enregistré si le champ est vide).
    private func testXtream() async {
        guard let url = XtreamCredentials.normalizeServer(server) else { return }
        var pass = password
        if pass.isEmpty, let existing { pass = store.password(for: existing) ?? "" }
        testing = true
        errorText = nil
        infoText = nil
        defer { testing = false }
        do {
            let account = try await XtreamClient(credentials: XtreamCredentials(server: url, username: username, password: pass),
                                                 sourceID: UUID()).account()
            var message = String(localized: "Connexion réussie — compte \(account.status)")
            if let expiration = account.expiration {
                message += String(localized: ", expire le \(expiration.formatted(date: .long, time: .omitted))")
            }
            if let max = account.maxConnections { message += String(localized: ", \(max) connexion(s) simultanée(s)") }
            infoText = message
        } catch {
            errorText = LibraryStore.describe(error)
        }
    }

    private func save() async {
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
        case .jellyfin, .emby, .plex:
            guard let type = mode.serverType, let url = serverURL else { return }
            kind = .mediaServer(type: type, server: url, username: username.trimmingCharacters(in: .whitespaces))
            defaultName = url.host ?? mode.label
        case .m3uFile:
            guard let existing else { return }
            kind = existing.kind
            defaultName = existing.name
        case .folders:
            kind = .folders(bookmarks: folders.map(\.bookmark), paths: folders.map(\.path))
            defaultName = folders.first.map { URL(fileURLWithPath: $0.path).lastPathComponent } ?? String(localized: "Mes vidéos")
        }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let epgText = epg.trimmingCharacters(in: .whitespaces)
        let source = Source(id: existing?.id ?? UUID(), name: trimmed.isEmpty ? defaultName : trimmed, kind: kind,
                            epgURL: mode.isIPTV && !epgText.isEmpty ? URL(string: epgText) : nil,
                            isEnabled: existing?.isEnabled ?? true, lastRefresh: existing?.lastRefresh)
        if mode.serverType != nil {
            // Identifiants vérifiés avant l'ajout, pour signaler tout de suite une erreur.
            saving = true
            defer { saving = false }
            do {
                if let existing {
                    try await store.updateMediaServer(source, password: password, token: token.isEmpty ? nil : token,
                                                      accessChanged: existing.kind != kind)
                } else {
                    try await store.addMediaServer(source, password: password, token: token.isEmpty ? nil : token)
                    if store.catalogOrigin == .iptv { store.catalogOrigin = .all }
                }
                dismiss()
            } catch {
                var message = LibraryStore.describe(error)
                if let detail = (error as? MediaServerError)?.detail { message += "\n" + detail }
                errorText = message
            }
            return
        }
        if existing != nil {
            store.updateSource(source, password: pass)
        } else {
            store.addSource(source, password: pass)
            if !mode.isIPTV, store.catalogOrigin == .iptv { store.catalogOrigin = .all }
        }
        dismiss()
    }
}
