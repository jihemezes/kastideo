import SwiftUI
import PhotosUI
import KastideoCore

/// « Modifier la chaîne » : nom, numéro, logo, thème et chaîne du guide TV (pour cette version de la chaîne uniquement).
struct IOSChannelEditSheet: View {
    let item: MediaItem
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var number = ""
    @State private var epgID = ""
    @State private var logoText = ""
    @State private var theme: ContentTheme?
    @State private var guideSearch = ""
    @State private var choices: [GuideChannelChoice] = []
    @State private var photo: PhotosPickerItem?
    @State private var loaded = false

    private var original: MediaItem { store.originalItem(id: item.id) ?? item }
    private var groupKey: String { ChannelMatcher.variantKey(original.name) }
    private var autoTheme: ContentTheme? { store.liveGroups.first { $0.key == groupKey }?.autoTheme }

    private var previewLogo: URL? {
        let text = logoText.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty, let url = URL(string: text) { return url }
        return original.logoURL
    }

    private var filteredChoices: [GuideChannelChoice] {
        let key = guideSearch.kastideoSearchKey
        let base = key.isEmpty ? choices : choices.filter { $0.name.kastideoSearchKey.contains(key) || $0.id.kastideoSearchKey.contains(key) }
        return Array(base.prefix(40))
    }

    private var currentGuideText: String {
        let id = epgID.isEmpty ? original.epgID : epgID
        if let programme = store.epg.current(for: id) {
            return String(localized: "Guide associé : \(id ?? "—") — en ce moment : \(programme.title)")
        }
        return String(localized: "Aucun programme trouvé pour « \(id ?? "—") ». Choisissez la bonne chaîne ci-dessous.")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        ArtworkView(url: previewLogo, name: name.isEmpty ? original.name : name)
                            .frame(width: 64, height: 46)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nom d'origine").font(.caption).foregroundStyle(.secondary)
                            Text(original.name).font(.subheadline.weight(.medium))
                        }
                    }
                    TextField("Nom", text: $name, prompt: Text(original.name))
                    TextField("Numéro", text: $number, prompt: Text(original.number.map(String.init) ?? "—"))
                        .keyboardType(.numberPad)
                }

                Section("Logo") {
                    TextField("Adresse de l'image (https://…)", text: $logoText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    PhotosPicker(selection: $photo, matching: .images) {
                        Label("Choisir une photo…", systemImage: "photo")
                    }
                }

                Section {
                    Picker("Thème", selection: $theme) {
                        Text("Automatique (\(autoTheme?.label ?? ContentTheme.other.label))").tag(ContentTheme?.none)
                        ForEach(ContentTheme.browsable) { option in
                            Text(option.label).tag(Optional(option))
                        }
                    }
                } header: {
                    Text("Thème de la chaîne")
                } footer: {
                    Text("Utilisé dans l'affichage Thèmes, pour toutes les versions de la chaîne (HD, FHD…).")
                }

                Section {
                    Text(currentGuideText).font(.caption).foregroundStyle(.secondary)
                    TextField("Rechercher une chaîne du guide (ex. TF1)", text: $guideSearch)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        epgID = ""
                    } label: {
                        HStack {
                            Text("Automatique (identifiant d'origine)")
                            Spacer()
                            if epgID.isEmpty { Image(systemName: "checkmark").foregroundStyle(IOSPalette.orange) }
                        }
                    }
                    ForEach(filteredChoices) { choice in
                        Button {
                            epgID = choice.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(choice.name)
                                    if let programme = store.epg.current(for: choice.id) {
                                        Text("En ce moment : \(programme.title)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                                Spacer()
                                if epgID == choice.id { Image(systemName: "checkmark").foregroundStyle(IOSPalette.orange) }
                            }
                        }
                    }
                } header: {
                    Text("Programmes du guide TV")
                }

                Section {
                    Button("Rétablir l'original", role: .destructive) {
                        store.saveChannelEdit(nil, for: item.id)
                        store.setTheme(nil, forChannelKey: groupKey)
                        dismiss()
                    }
                    .disabled(store.channelEdits[item.id] == nil && store.themeOverrides[groupKey] == nil)
                }
            }
            .navigationTitle("Modifier la chaîne")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer", action: save).fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
            .onChange(of: photo) { _, picked in
                guard let picked else { return }
                Task { await importPhoto(picked) }
            }
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        let edit = store.channelEdits[item.id]
        name = edit?.name ?? ""
        number = edit?.number.map(String.init) ?? ""
        epgID = edit?.epgID ?? ""
        logoText = edit?.logo?.absoluteString ?? ""
        theme = store.themeOverrides[groupKey]
        choices = store.guideChannelChoices()
        guideSearch = TMDB.cleanTitle(original.name).title
        if filteredChoices.isEmpty { guideSearch = "" }
    }

    private func save() {
        var edit = ChannelEdit()
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty, trimmedName != original.name { edit.name = trimmedName }
        if let value = Int(number.trimmingCharacters(in: .whitespaces)), value != original.number { edit.number = value }
        if !epgID.isEmpty, epgID != original.epgID { edit.epgID = epgID }
        let logo = logoText.trimmingCharacters(in: .whitespaces)
        if !logo.isEmpty, let url = URL(string: logo), url != original.logoURL { edit.logo = url }
        store.saveChannelEdit(edit, for: item.id)
        if theme != store.themeOverrides[groupKey] { store.setTheme(theme, forChannelKey: groupKey) }
        dismiss()
    }

    /// Copie la photo choisie dans le dossier de l'application : elle reste disponible même si la photo d'origine disparaît.
    private func importPhoto(_ picked: PhotosPickerItem) async {
        guard let data = try? await picked.loadTransferable(type: Data.self) else { return }
        let folder = Storage.directory.appendingPathComponent("logos", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let safe = item.id.replacingOccurrences(of: "[^A-Za-z0-9]", with: "_", options: .regularExpression)
        let destination = folder.appendingPathComponent("\(safe).jpg")
        try? FileManager.default.removeItem(at: destination)
        if (try? data.write(to: destination, options: .atomic)) != nil {
            logoText = destination.absoluteString
        }
        photo = nil
    }
}
