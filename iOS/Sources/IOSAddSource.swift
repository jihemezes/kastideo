import SwiftUI
import UniformTypeIdentifiers
import KastideoCore

/// Ajout d'une source : abonnement IPTV (Xtream, M3U) ou « Mes vidéos » (Jellyfin, Emby, Plex, dossiers).
struct IOSAddSourceView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case xtream, m3u, jellyfin, emby, plex, folders
        var id: String { rawValue }
        var label: String {
            switch self {
            case .xtream: return "Xtream Codes"
            case .m3u: return String(localized: "Liste M3U (URL)")
            case .jellyfin: return "Jellyfin"
            case .emby: return "Emby"
            case .plex: return "Plex"
            case .folders: return String(localized: "Dossiers de vidéos")
            }
        }
        var isIPTV: Bool { self == .xtream || self == .m3u }
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

    @State private var mode: Mode = .xtream
    @State private var name = ""
    @State private var server = ""
    @State private var username = ""
    @State private var password = ""
    @State private var token = ""
    @State private var playlist = ""
    @State private var epg = ""
    @State private var folders: [Folder] = []
    @State private var pickingFolder = false
    @State private var saving = false
    @State private var errorText: String?

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
            return XtreamCredentials.normalizeServer(server) != nil && !username.isEmpty && !password.isEmpty
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
            case .jellyfin, .emby:
                Section {
                    TextField("Adresse (192.168.1.20 ou http://serveur:8096)", text: $server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    TextField("Identifiant", text: $username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Mot de passe (facultatif)", text: $password)
                } header: {
                    Text("Serveur \(mode.label)")
                } footer: {
                    Text("Sur le réseau de la maison, l'iPhone doit être sur le même Wi-Fi que le serveur (ou relié par un VPN). Films et séries apparaissent dans Films et Séries, sous « Mes vidéos ».")
                }
            case .plex:
                Section {
                    TextField("Adresse (192.168.1.20 ou http://serveur:32400)", text: $server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    SecureField("Jeton Plex (facultatif)", text: $token)
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

            if let errorText {
                Section { Text(errorText).font(.footnote).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Ajouter une source")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                if saving {
                    ProgressView()
                } else {
                    Button("Ajouter") { Task { await save() } }.disabled(!isValid)
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
        case .folders:
            kind = .folders(bookmarks: folders.map(\.bookmark), paths: folders.map(\.path))
            defaultName = folders.first.map { URL(fileURLWithPath: $0.path).lastPathComponent } ?? String(localized: "Mes vidéos")
        }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let epgText = epg.trimmingCharacters(in: .whitespaces)
        let source = Source(name: trimmed.isEmpty ? defaultName : trimmed, kind: kind,
                            epgURL: mode.isIPTV && !epgText.isEmpty ? URL(string: epgText) : nil)
        if mode.serverType != nil {
            // Identifiants vérifiés avant l'ajout, pour signaler tout de suite une erreur.
            saving = true
            defer { saving = false }
            do {
                try await store.addMediaServer(source, password: password, token: token.isEmpty ? nil : token)
                if store.catalogOrigin == .iptv { store.catalogOrigin = .all }
                dismiss()
            } catch {
                var message = LibraryStore.describe(error)
                if let detail = (error as? MediaServerError)?.detail { message += "\n" + detail }
                errorText = message
            }
            return
        }
        store.addSource(source, password: pass)
        if !mode.isIPTV, store.catalogOrigin == .iptv { store.catalogOrigin = .all }
        dismiss()
    }
}
