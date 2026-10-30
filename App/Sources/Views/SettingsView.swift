import SwiftUI
import KastideoCore

/// Fenêtre Réglages (⌘,) : sources et préférences générales.
struct SettingsView: View {
    var body: some View {
        TabView {
            SourcesSettingsView()
                .tabItem { Label("Sources", systemImage: "antenna.radiowaves.left.and.right") }
            GeneralSettingsView()
                .tabItem { Label("Général", systemImage: "gearshape") }
            AppearanceSettingsView()
                .tabItem { Label("Apparence", systemImage: "paintpalette") }
            RecordingSettingsView()
                .tabItem { Label("Enregistrements", systemImage: "record.circle") }
            UpdateSettingsView()
                .tabItem { Label("Mises à jour", systemImage: "arrow.down.circle") }
            AboutSettingsView()
                .tabItem { Label("À propos", systemImage: "info.circle") }
        }
        .frame(width: 720, height: 600)
    }
}

struct SourcesSettingsView: View {
    @Environment(LibraryStore.self) private var store
    @State private var showAdd = false
    @State private var editing: Source?
    @State private var deleting: Source?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.sources.isEmpty {
                ContentUnavailableView("Aucune source",
                                       systemImage: "antenna.radiowaves.left.and.right",
                                       description: Text("Ajoutez un abonnement Xtream Codes ou une playlist M3U."))
            } else {
                List {
                    ForEach(store.sources) { source in
                        SourceSettingsRow(source: source,
                                          onEdit: { editing = source },
                                          onDelete: { deleting = source })
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
            Divider()
            HStack {
                Button {
                    showAdd = true
                } label: {
                    Label("Ajouter une source", systemImage: "plus")
                }
                Spacer()
                Button("Tout actualiser") { store.refreshAll() }
                    .disabled(store.sources.isEmpty)
            }
            .padding(12)
        }
        .sheet(isPresented: $showAdd) {
            SourceEditorView(existing: nil).environment(store)
        }
        .sheet(item: $editing) { source in
            SourceEditorView(existing: source).environment(store)
        }
        .confirmationDialog(String(localized: "Supprimer « \(deleting?.name ?? "") » ?"),
                            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                            titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                if let deleting { store.removeSource(deleting.id) }
                deleting = nil
            }
        } message: {
            Text("La source, son cache et son mot de passe seront effacés. Les favoris liés ne seront plus affichés.")
        }
    }
}

struct SourceSettingsRow: View {
    @Environment(LibraryStore.self) private var store
    let source: Source
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: Binding(get: { source.isEnabled }, set: { store.setEnabled(source.id, $0) }))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
            VStack(alignment: .leading, spacing: 3) {
                Text(source.name).font(.headline)
                Text(details).font(.caption).foregroundStyle(.secondary)
                if let error = store.errors[source.id] {
                    Text(error).font(.caption).foregroundStyle(.red)
                } else if let epgError = store.epgErrors[source.id] {
                    Text("Guide TV : \(epgError)").font(.caption).foregroundStyle(.orange)
                } else if source.kind.isIPTV, let count = store.epgCounts[source.id] {
                    Text(count > 0 ? String(localized: "Guide TV du fournisseur : \(count) programmes")
                                   : String(localized: "Guide TV du fournisseur : aucun programme reçu (voir le Journal, sujet « Guide TV »)"))
                        .font(.caption)
                        .foregroundStyle(count > 0 ? Color.secondary : Color.orange)
                }
            }
            Spacer()
            if store.loading.contains(source.id) {
                ProgressView().controlSize(.small)
            } else {
                Button { store.refresh(source) } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.borderless)
                    .help("Actualiser")
                if source.kind.isIPTV {
                    Button { store.reloadGuide(for: source.id) } label: { Image(systemName: "calendar.badge.clock") }
                        .buttonStyle(.borderless)
                        .disabled(store.epgLoadingCount > 0)
                        .help("Recharger le guide TV (résultat détaillé dans le Journal, sujet « Guide TV »)")
                }
            }
            Button { onEdit() } label: { Image(systemName: "pencil") }
                .buttonStyle(.borderless)
                .help("Modifier")
            Button { onDelete() } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless)
                .help("Supprimer")
        }
        .padding(.vertical, 4)
    }

    private var details: String {
        var parts = [source.kind.title]
        if let content = store.contents[source.id] {
            let items = content.items
            let live = items.filter { $0.kind == .live }.count
            let movies = items.filter { $0.kind == .movie }.count
            let series = items.filter { $0.kind == .series }.count
            if source.kind.isIPTV {
                parts.append(String(localized: "\(live) chaînes · \(movies) films · \(series) séries"))
            } else {
                parts.append(String(localized: "\(movies) films et vidéos · \(series) séries"))
            }
        }
        switch source.kind {
        case .folders(_, let paths): parts.append(paths.joined(separator: ", "))
        case .mediaServer(_, let server, _): parts.append(server.host ?? server.absoluteString)
        default: break
        }
        if let count = store.epgCounts[source.id], count > 0 {
            parts.append(String(localized: "\(count) programmes"))
        }
        if let date = source.lastRefresh {
            parts.append(String(localized: "actualisé \(date.formatted(.relative(presentation: .named)))"))
        }
        return parts.joined(separator: " — ")
    }
}

struct GeneralSettingsView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(WatchProgressStore.self) private var watch
    @AppStorage(PlaybackKeys.resume) private var resumePlayback = true
    @AppStorage(SettingsKeys.autoRefresh) private var autoRefresh = true
    @AppStorage(PlaybackKeys.buffering) private var buffering = BufferingMode.fast.rawValue
    @AppStorage(StreamRelay.enabledKey) private var relayEnabled = true
    @AppStorage(PlaybackKeys.showStartupTime) private var showStartupTime = true
    @AppStorage(AppLanguage.storageKey) private var languageRaw = ""
    @State private var cacheSize: Int64 = 0
    @State private var askRelaunch = false

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: languageRaw) ?? .system },
            set: { language in
                language.apply()
                languageRaw = language.rawValue
                if language.needsRelaunch { askRelaunch = true }
            }
        )
    }

    var body: some View {
        Form {
            Section("Langue") {
                Picker("Langue de l'application", selection: languageBinding) {
                    ForEach(AppLanguage.allCases) { Text($0.label).tag($0) }
                }
                Text("Le changement s'applique au prochain lancement de Kastideo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ReplaySettingsSection()
            Section("Lecture") {
                Picker("Mémoire tampon", selection: $buffering) {
                    ForEach(BufferingMode.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Toggle("Afficher le temps de démarrage des chaînes", isOn: $showStartupTime)
                Toggle("Reprendre les films et épisodes là où vous vous êtes arrêté", isOn: $resumePlayback)
                Toggle("Relais de flux pour le direct (une seule connexion au fournisseur)", isOn: $relayEnabled)
                Text("Kastideo ouvre lui-même la connexion chez le fournisseur et la transmet au moteur VLC, comme Piboard : la chaîne précédente est fermée net avant d'ouvrir la suivante. À désactiver seulement pour comparer en cas de souci.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledContent("Chaînes à l'horloge réparée") {
                    Button("Réinitialiser") { PlaybackController.resetClockFixes() }
                }
                Text("Kastideo mémorise les chaînes dont l'horloge envoyée par le fournisseur est incohérente (ouvertes en se calant sur le son et l'image, ou en image seule si le son est inutilisable). « Réinitialiser » revient à la lecture normale pour toutes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TimeshiftSettingsRow()
                MultiViewSettingsRow()
                QualitySettingsRow()
                AdultSettingsRow()
                Text("Moteur de lecture : VLC. Une seule connexion au fournisseur est ouverte à la fois.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            MediaInfoSettingsSection()
            CastSettingsSection()
            YouTubeSettingsSection()
            EPGFallbackSettingsSection()
            ConfigTransferSection()
            Toggle("Actualiser les sources au démarrage (si plus de 6 h)", isOn: $autoRefresh)
            LabeledContent("Cache") {
                HStack {
                    Text(ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file))
                        .foregroundStyle(.secondary)
                    Button("Vider et recharger") {
                        store.clearCache()
                        cacheSize = 0
                    }
                }
            }
            LabeledContent("Historique") {
                HStack {
                    Button("Effacer les récents") { store.clearRecents() }
                    Button("Oublier les positions de lecture") { watch.clearAll() }
                }
            }
            LabeledContent("Version") {
                Text(appVersion).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { cacheSize = Storage.size() }
        .alert("Relancer Kastideo ?", isPresented: $askRelaunch) {
            Button("Relancer maintenant") { AppLanguage.relaunch() }
            Button("Plus tard", role: .cancel) {}
        } message: {
            Text("La nouvelle langue sera appliquée après le redémarrage de l'application.")
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

struct UpdateSettingsView: View {
    @Environment(UpdaterController.self) private var updater
    @AppStorage(UpdateKeys.betaChannel) private var betaChannel = false
    @State private var autoCheck = true

    var body: some View {
        Form {
            Section {
                Toggle("Rechercher les mises à jour au démarrage (puis une fois par jour)", isOn: $autoCheck)
                    .onChange(of: autoCheck) { _, value in updater.automaticallyChecks = value }
            } footer: {
                Text("La recherche se fait discrètement quelques secondes après le lancement. Si une version est disponible, un bandeau la propose en haut de la fenêtre — jamais pendant un visionnage ni un enregistrement. La mise à jour reste facultative : « Plus tard » ou « Ignorer cette version ». Les mises à jour sont publiées sur GitHub, signées et notarisées par Apple ; Kastideo vérifie leur signature avant de les installer.")
            }

            Section {
                Toggle("Recevoir les versions de test (bêta)", isOn: $betaChannel)
            } footer: {
                Text("Les versions bêta apportent les nouveautés plus tôt mais peuvent être moins stables. Vous pouvez revenir aux versions stables à tout moment ; la version suivante sera alors proposée normalement.")
            }

            Section {
                LabeledContent("Version installée") {
                    Text(ReleaseNotes.currentVersion).foregroundStyle(.secondary)
                }
                LabeledContent("Dernière vérification") {
                    Text(updater.lastCheck.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? String(localized: "Jamais"))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Button("Rechercher maintenant") { updater.checkForUpdates() }
                        .disabled(!updater.canCheckForUpdates)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            autoCheck = updater.automaticallyChecks
        }
    }
}
