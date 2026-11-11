import SwiftUI
import KastideoCore

/// Gérer les catégories : ordre, masquage, noms personnalisés et masquage par mot-clé.
struct IOSCategoryManagerView: View {
    @Environment(LibraryStore.self) private var store
    @State private var kind: MediaKind = .live
    @State private var search = ""
    @State private var keyword = ""
    @State private var renaming: String?
    @State private var renameText = ""
    @State private var confirmReset = false

    private var prefs: CategoryPrefs { store.prefs(for: kind) }
    private var all: [String] { store.allCategoriesByKind[kind] ?? [] }

    var body: some View {
        let filtered = search.isEmpty ? all : all.filter {
            $0.localizedCaseInsensitiveContains(search) || prefs.displayName($0).localizedCaseInsensitiveContains(search)
        }
        let move: ((IndexSet, Int) -> Void)? = search.isEmpty
            ? { offsets, destination in store.moveCategories(kind, from: offsets, to: destination) }
            : nil
        List {
            Section {
                Picker("Section", selection: $kind) {
                    Text("Direct").tag(MediaKind.live)
                    Text("Films").tag(MediaKind.movie)
                    Text("Séries").tag(MediaKind.series)
                }
                .pickerStyle(.segmented)
            }

            Section {
                HStack {
                    TextField("Ex. PAKISTAN, ARABIC", text: $keyword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit(addKeyword)
                    Button("Masquer", action: addKeyword)
                        .disabled(keyword.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ForEach(prefs.keywords, id: \.self) { word in
                    HStack {
                        Label(word, systemImage: "eye.slash")
                        Spacer()
                        Button {
                            store.updateCategories(kind) { $0.keywords.removeAll { $0 == word } }
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Masquer les catégories contenant…")
            } footer: {
                Text("Toute catégorie dont le nom contient un de ces mots disparaît de Kastideo.")
            }

            Section {
                if all.isEmpty {
                    Text("Les catégories apparaissent une fois les sources chargées.").foregroundStyle(.secondary)
                } else {
                    ForEach(filtered, id: \.self) { name in
                        row(name)
                    }
                    .onMove(perform: move)
                }
            } header: {
                let hiddenCount = all.filter { prefs.isHidden($0) }.count
                Text("\(all.count) catégories · \(hiddenCount) masquées")
            } footer: {
                Text(search.isEmpty ? "Glissez les poignées pour changer l'ordre." : "Effacez la recherche pour changer l'ordre.")
            }

            Section {
                Button("Tout afficher") {
                    store.updateCategories(kind) { $0.hidden = []; $0.keywords = [] }
                }
                Button("Trier de A à Z") {
                    store.updateCategories(kind) { prefs in
                        prefs.order = all.sorted { prefs.displayName($0).localizedStandardCompare(prefs.displayName($1)) == .orderedAscending }
                    }
                }
                Button("Réinitialiser…", role: .destructive) { confirmReset = true }
            }
        }
        .environment(\.editMode, .constant(.active))
        .searchable(text: $search, prompt: "Rechercher une catégorie")
        .navigationTitle("Catégories")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Renommer la catégorie", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Nouveau nom", text: $renameText)
            Button("Renommer") { applyRename() }
            Button("Nom d'origine") {
                if let name = renaming { store.updateCategories(kind) { $0.renames[name] = nil } }
                renaming = nil
            }
            Button("Annuler", role: .cancel) { renaming = nil }
        } message: {
            Text(renaming ?? "")
        }
        .confirmationDialog("Revenir à l'ordre du fournisseur et tout réafficher ?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Réinitialiser", role: .destructive) {
                store.updateCategories(kind) { $0 = CategoryPrefs() }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("L'ordre, les catégories masquées, les mots-clés et les noms personnalisés de cette section seront effacés.")
        }
    }

    private func row(_ name: String) -> some View {
        let byKeyword = prefs.isHiddenByKeyword(name)
        let visible = !prefs.isHidden(name)
        let displayed = prefs.displayName(name)
        return HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { visible },
                set: { show in
                    store.updateCategories(kind) { prefs in
                        if show { prefs.hidden.remove(name) } else { prefs.hidden.insert(name) }
                    }
                }))
                .labelsHidden()
                .disabled(byKeyword)
            VStack(alignment: .leading, spacing: 1) {
                Text(displayed)
                    .foregroundStyle(visible ? Color.primary : Color.secondary)
                    .strikethrough(!visible)
                    .lineLimit(1)
                if displayed != name {
                    Text(name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                } else if byKeyword {
                    Text("Masquée par un mot-clé").font(.caption).foregroundStyle(.orange)
                }
            }
            Spacer(minLength: 4)
            Text((store.categoryCounts[kind]?[name] ?? 0).formatted())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Menu {
                Button("Renommer…", systemImage: "pencil") {
                    renameText = displayed
                    renaming = name
                }
                Button("Placer en haut", systemImage: "arrow.up.to.line") { moveTo(name, top: true) }
                Button("Placer en bas", systemImage: "arrow.down.to.line") { moveTo(name, top: false) }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private func addKeyword() {
        let word = keyword.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty else { return }
        store.updateCategories(kind) { prefs in
            if !prefs.keywords.contains(where: { $0.caseInsensitiveCompare(word) == .orderedSame }) { prefs.keywords.append(word) }
        }
        keyword = ""
    }

    private func moveTo(_ name: String, top: Bool) {
        var list = all
        list.removeAll { $0 == name }
        if top { list.insert(name, at: 0) } else { list.append(name) }
        store.updateCategories(kind) { $0.order = list }
    }

    private func applyRename() {
        guard let name = renaming else { return }
        let text = renameText.trimmingCharacters(in: .whitespaces)
        store.updateCategories(kind) { $0.renames[name] = (text.isEmpty || text == name) ? nil : text }
        renaming = nil
    }
}

// MARK: - Ordre des chaînes

/// Réordonner les chaînes d'une catégorie (glisser, tri A→Z, par numéro, ordre d'origine).
struct IOSChannelArrangeView: View {
    let category: String
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var channels: [MediaItem] = []
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(channels) { channel in
                    HStack(spacing: 12) {
                        ArtworkView(url: channel.logoURL, name: channel.name)
                            .frame(width: 44, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text(channel.name).lineLimit(1)
                        Spacer()
                        if let number = channel.number {
                            Text("\(number)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
                .onMove { offsets, destination in channels.move(fromOffsets: offsets, toOffset: destination) }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))
            .navigationTitle(category)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Trier de A à Z") {
                            channels.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                        }
                        Button("Trier par numéro") {
                            channels.sort { ($0.number ?? Int.max) < ($1.number ?? Int.max) }
                        }
                        Divider()
                        Button("Ordre du fournisseur", role: .destructive) {
                            store.resetItemOrder(category: category)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        store.setItemOrder(channels.map(\.id), category: category)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                channels = store.items(for: .category(.live, category))
            }
        }
    }
}

// MARK: - Pays

/// Pays dont l'affichage Cinéma montre les rangées et le bandeau.
struct IOSCountrySection: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage(CountryKeys.codes) private var stored = ""
    @AppStorage(CountryKeys.neutral) private var keepNeutral = true
    @State private var detected: [DetectedCountry] = []

    struct DetectedCountry: Identifiable {
        let code: String
        let count: Int
        var id: String { code }
    }

    private var selected: Set<String> { CountryFilter(stored: stored, keepNeutral: keepNeutral).codes }

    var body: some View {
        Section {
            if detected.isEmpty {
                Text("Aucun pays repéré dans les noms des catégories de vos sources.")
                    .foregroundStyle(.secondary)
            } else {
                Toggle("Tous les pays", isOn: Binding(get: { selected.isEmpty }, set: { if $0 { stored = "" } }))
                ForEach(Array(detected.prefix(24))) { entry in
                    Toggle("\(CountryKeys.name(entry.code)) · \(entry.count)", isOn: Binding(
                        get: { selected.contains(entry.code) },
                        set: { on in
                            var codes = selected
                            if on { codes.insert(entry.code) } else { codes.remove(entry.code) }
                            stored = CountryFilter(codes: codes).stored
                        }))
                }
                Toggle("Garder les catégories sans pays indiqué (ex. « Action », « Nouveautés »)", isOn: $keepNeutral)
                    .disabled(selected.isEmpty)
            }
        } footer: {
            Text("Les derniers ajouts, le bandeau « à la une » et les rangées par catégorie de l'affichage Cinéma ne montrent que les pays choisis. Le pays est repéré dans le nom des catégories (« FR| », « |PT| », « FRANCE », « VOSTFR »…). Les listes et la recherche restent complètes.")
        }
        .task(id: store.count(for: .movie) + store.count(for: .series) + store.count(for: .live)) {
            var counts: [String: Int] = [:]
            for kind in [MediaKind.live, .movie, .series] {
                for name in store.allCategoriesByKind[kind] ?? [] {
                    guard let code = CountryDetector.code(for: name) else { continue }
                    counts[code, default: 0] += store.items(for: .category(kind, name)).count
                }
            }
            detected = counts.map { DetectedCountry(code: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
        }
    }
}
