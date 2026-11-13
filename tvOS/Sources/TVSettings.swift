import SwiftUI
import KastideoCore

/// Réglages : sources (ajout, suppression, actualisation) et à propos.
struct TVSettingsView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(TVUI.self) private var ui

    var body: some View {
        NavigationStack {
            List {
                Section("Sources") {
                    ForEach(store.sources) { source in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(source.name)
                                Text(source.kind.typeLabel).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if store.loading.contains(source.id) { ProgressView() }
                            Button("Supprimer", role: .destructive) { store.removeSource(source.id) }
                        }
                    }
                    NavigationLink("Ajouter une source…") { TVAddSourceView() }
                    if store.hasSources {
                        Button("Tout actualiser") { store.refreshAll() }
                    }
                }
                Section {
                    Text("La synchronisation iCloud n'est pas disponible sur Apple TV : saisissez votre source ici (le clavier de l'iPhone proche peut servir de saisie).")
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
