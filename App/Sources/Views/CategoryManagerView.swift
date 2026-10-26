import SwiftUI
import KastideoCore

/// Fenêtre « Gérer les catégories » : ordre, masquage, noms personnalisés et masquage par mot-clé.
struct CategoryManagerView: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage("categoryManager.kind") private var kindRaw = MediaKind.live.rawValue
    @State private var search = ""
    @State private var keyword = ""
    @State private var renaming: String?
    @State private var renameText = ""
    @State private var confirmReset = false

    private var kind: MediaKind { MediaKind(rawValue: kindRaw) ?? .live }
    private var prefs: CategoryPrefs { store.prefs(for: kind) }
    private var all: [String] { store.allCategoriesByKind[kind] ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            keywordBar
            Divider()
            list
            Divider()
            footer
        }
        .frame(minWidth: 560, minHeight: 520)
        .sheet(item: Binding(get: { renaming.map(RenameTarget.init) }, set: { renaming = $0?.name })) { target in
            renameSheet(target.name)
        }
        .confirmationDialog(String(localized: "Revenir à l'ordre du fournisseur et tout réafficher ?"), isPresented: $confirmReset) {
            Button("Réinitialiser", role: .destructive) {
                store.updateCategories(kind) { $0 = CategoryPrefs() }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("L'ordre, les catégories masquées, les mots-clés et les noms personnalisés de cette section seront effacés.")
        }
    }

    // MARK: En-tête

    private var header: some View {
        HStack(spacing: 12) {
            Picker("Section", selection: $kindRaw) {
                Text("Direct").tag(MediaKind.live.rawValue)
                Text("Films").tag(MediaKind.movie.rawValue)
                Text("Séries").tag(MediaKind.series.rawValue)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 260)
            Spacer()
            TextField("Rechercher une catégorie", text: $search)
                .textFieldStyle(.roundedBorder)
                .frame(width: 210)
        }
        .padding(12)
    }

    private var keywordBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.secondary)
                TextField("Masquer les catégories contenant… (ex. PAKISTAN, ARABIC)", text: $keyword)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addKeyword)
                Button("Masquer", action: addKeyword)
                    .disabled(keyword.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if !prefs.keywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(prefs.keywords, id: \.self) { word in
                            HStack(spacing: 4) {
                                Text(word).font(.caption.weight(.medium))
                                Button {
                                    store.updateCategories(kind) { $0.keywords.removeAll { $0 == word } }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .help("Ne plus masquer « \(word) »")
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(12)
    }

    // MARK: Liste

    private var list: some View {
        let filtered = search.isEmpty ? all : all.filter { $0.localizedCaseInsensitiveContains(search)
            || prefs.displayName($0).localizedCaseInsensitiveContains(search) }
        let move: ((IndexSet, Int) -> Void)? = search.isEmpty
            ? { offsets, destination in store.moveCategories(kind, from: offsets, to: destination) }
            : nil
        return Group {
            if all.isEmpty {
                ContentUnavailableView("Aucune catégorie", systemImage: "folder",
                                       description: Text("Les catégories apparaissent une fois les sources chargées."))
            } else {
                VStack(spacing: 0) {
                    selectAllBar(filtered)
                    Divider()
                    List {
                        ForEach(filtered, id: \.self) { name in
                            row(name)
                        }
                        .onMove(perform: move)
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            }
        }
    }

    /// Case « tout sélectionner / désélectionner » (catégories listées, donc celles de la recherche s'il y en a une).
    private func selectAllBar(_ names: [String]) -> some View {
        let editable = names.filter { !prefs.isHiddenByKeyword($0) }
        let shown = editable.filter { !prefs.isHidden($0) }.count
        let allShown = !editable.isEmpty && shown == editable.count
        let none = shown == 0
        let symbol = allShown ? "checkmark.square.fill" : (none ? "square" : "minus.square.fill")
        return HStack(spacing: 10) {
            Button {
                let showAll = !allShown
                store.updateCategories(kind) { prefs in
                    if showAll { prefs.hidden.subtract(editable) } else { prefs.hidden.formUnion(editable) }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: symbol)
                        .foregroundStyle(none ? Color.secondary : Color.accentColor)
                        .font(.body)
                    Text(search.isEmpty ? String(localized: "Tout sélectionner / désélectionner")
                                        : String(localized: "Sélectionner / désélectionner les catégories trouvées"))
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(.plain)
            .disabled(editable.isEmpty)
            .help("Coche ou décoche d'un coup toutes les catégories listées (celles de la recherche, s'il y en a une).")
            Spacer()
            Text("\(shown) / \(editable.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func row(_ name: String) -> some View {
        let byKeyword = prefs.isHiddenByKeyword(name)
        let visible = !prefs.isHidden(name)
        let displayed = prefs.displayName(name)
        return HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
                .help(search.isEmpty ? String(localized: "Glisser pour déplacer") : String(localized: "Effacez la recherche pour déplacer"))
            Toggle("", isOn: Binding(
                get: { visible },
                set: { show in
                    store.updateCategories(kind) { prefs in
                        if show { prefs.hidden.remove(name) } else { prefs.hidden.insert(name) }
                    }
                }))
                .labelsHidden()
                .toggleStyle(.checkbox)
                .disabled(byKeyword)
                .help(byKeyword ? String(localized: "Masquée par un mot-clé") : String(localized: "Afficher ou masquer"))
            VStack(alignment: .leading, spacing: 1) {
                Text(displayed)
                    .foregroundStyle(visible ? .primary : .secondary)
                    .strikethrough(!visible)
                if displayed != name {
                    Text(name).font(.caption).foregroundStyle(.secondary)
                } else if byKeyword {
                    Text("Masquée par un mot-clé").font(.caption).foregroundStyle(.orange)
                }
            }
            Spacer()
            Text((store.categoryCounts[kind]?[name] ?? 0).formatted())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Button {
                renameText = displayed
                renaming = name
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Renommer")
            Menu {
                Button("Placer en haut") { moveTo(name, top: true) }
                Button("Placer en bas") { moveTo(name, top: false) }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.vertical, 2)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            let hiddenCount = all.filter { prefs.isHidden($0) }.count
            Text("\(all.count) catégories · \(hiddenCount) masquées")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Tout afficher") {
                store.updateCategories(kind) { $0.hidden = []; $0.keywords = [] }
            }
            Button("Trier A → Z") {
                store.updateCategories(kind) { prefs in
                    prefs.order = all.sorted { prefs.displayName($0).localizedStandardCompare(prefs.displayName($1)) == .orderedAscending }
                }
            }
            Button("Réinitialiser…") { confirmReset = true }
        }
        .padding(12)
    }

    // MARK: Actions

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

    private func renameSheet(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Renommer la catégorie").font(.headline)
            Text(name).font(.caption).foregroundStyle(.secondary)
            TextField("Nouveau nom", text: $renameText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 340)
                .onSubmit { applyRename(name) }
            HStack {
                Button("Nom d'origine") {
                    store.updateCategories(kind) { $0.renames[name] = nil }
                    renaming = nil
                }
                Spacer()
                Button("Annuler", role: .cancel) { renaming = nil }
                    .keyboardShortcut(.cancelAction)
                Button("Renommer") { applyRename(name) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }

    private func applyRename(_ name: String) {
        let text = renameText.trimmingCharacters(in: .whitespaces)
        store.updateCategories(kind) { $0.renames[name] = (text.isEmpty || text == name) ? nil : text }
        renaming = nil
    }
}

private struct RenameTarget: Identifiable {
    let name: String
    var id: String { name }
}
