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
        }
        .frame(width: 680, height: 460)
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
        .confirmationDialog("Supprimer « \(deleting?.name ?? "") » ?",
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
                }
            }
            Spacer()
            if store.loading.contains(source.id) {
                ProgressView().controlSize(.small)
            } else {
                Button { store.refresh(source) } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.borderless)
                    .help("Actualiser")
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
        var parts = [source.kind.typeLabel]
        if let content = store.contents[source.id] {
            let items = content.items
            let live = items.filter { $0.kind == .live }.count
            let movies = items.filter { $0.kind == .movie }.count
            let series = items.filter { $0.kind == .series }.count
            parts.append("\(live) chaînes · \(movies) films · \(series) séries")
        }
        if let count = store.epgCounts[source.id], count > 0 {
            parts.append("\(count) programmes")
        }
        if let date = source.lastRefresh {
            parts.append("actualisé \(date.formatted(.relative(presentation: .named)))")
        }
        return parts.joined(separator: " — ")
    }
}

struct GeneralSettingsView: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage(SettingsKeys.appearance) private var appearance = Appearance.dark.rawValue
    @AppStorage(SettingsKeys.autoRefresh) private var autoRefresh = true
    @State private var cacheSize: Int64 = 0

    var body: some View {
        Form {
            Picker("Apparence", selection: $appearance) {
                ForEach(Appearance.allCases) { Text($0.label).tag($0.rawValue) }
            }
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
                Button("Effacer les récents") { store.clearRecents() }
            }
            LabeledContent("Version") {
                Text(appVersion).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { cacheSize = Storage.size() }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}
