import SwiftUI
import AppKit
import UniformTypeIdentifiers
import KastideoCore

/// « Modifier la chaîne » : nom, numéro, chaîne du guide TV et logo (pour cette version de la chaîne uniquement).
struct ChannelEditSheet: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let item: MediaItem

    @State private var name = ""
    @State private var number = ""
    @State private var epgID: String?
    @State private var logoText = ""
    @State private var guideSearch = ""
    @State private var choices: [GuideChannelChoice] = []

    private var original: MediaItem { store.originalItem(id: item.id) ?? item }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                LogoView(url: previewLogo, name: name.isEmpty ? original.name : name, size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Modifier la chaîne").font(.title3.weight(.semibold))
                    Text("Nom d'origine : \(original.name)").font(.caption).foregroundStyle(.secondary)
                }
            }

            Form {
                TextField("Nom", text: $name, prompt: Text(original.name))
                TextField("Numéro", text: $number, prompt: Text(original.number.map(String.init) ?? "—"))
                LabeledContent("Logo") {
                    HStack {
                        TextField("", text: $logoText, prompt: Text("Adresse de l'image (https://…)"))
                            .labelsHidden()
                        Button("Choisir un fichier…", action: chooseLogo)
                    }
                }
            }
            .formStyle(.grouped)
            .frame(height: 170)

            VStack(alignment: .leading, spacing: 6) {
                Text("Programmes du guide TV").font(.headline)
                Text(currentGuideText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Rechercher une chaîne du guide (ex. TF1, France 2…)", text: $guideSearch)
                    .textFieldStyle(.roundedBorder)
                List(selection: $epgID) {
                    Text("Automatique (identifiant d'origine)").tag("")
                    ForEach(filteredChoices) { choice in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(choice.name)
                                if let programme = store.epg.current(for: choice.id) {
                                    Text("En ce moment : \(programme.title)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            Spacer()
                            Text(choice.source).font(.caption2).foregroundStyle(.tertiary)
                        }
                        .tag(choice.id)
                    }
                }
                .frame(minHeight: 170)
            }

            HStack {
                Button("Rétablir l'original", role: .destructive) {
                    store.saveChannelEdit(nil, for: item.id)
                    dismiss()
                }
                .disabled(store.channelEdits[item.id] == nil)
                Spacer()
                Button("Annuler", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Enregistrer", action: save)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 560)
        .onAppear(perform: load)
    }

    private var previewLogo: URL? {
        let text = logoText.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty, let url = URL(string: text) { return url }
        return original.logoURL
    }

    private var currentGuideText: String {
        let id = (epgID?.isEmpty == false ? epgID : nil) ?? original.epgID
        if let programme = store.epg.current(for: id) {
            return String(localized: "Guide associé : \(id ?? "—") — en ce moment : \(programme.title)")
        }
        return String(localized: "Aucun programme trouvé pour « \(id ?? "—") ». Choisissez la bonne chaîne ci-dessous.")
    }

    private var filteredChoices: [GuideChannelChoice] {
        let key = guideSearch.kastideoSearchKey
        let base = key.isEmpty ? choices : choices.filter { $0.name.kastideoSearchKey.contains(key) || $0.id.kastideoSearchKey.contains(key) }
        return Array(base.prefix(300))
    }

    private func load() {
        let edit = store.channelEdits[item.id]
        name = edit?.name ?? ""
        number = edit?.number.map(String.init) ?? ""
        epgID = edit?.epgID ?? ""
        logoText = edit?.logo?.absoluteString ?? ""
        choices = store.guideChannelChoices()
        guideSearch = TMDB.cleanTitle(original.name).title
        if filteredChoices.isEmpty { guideSearch = "" }
    }

    private func save() {
        var edit = ChannelEdit()
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty, trimmedName != original.name { edit.name = trimmedName }
        if let value = Int(number.trimmingCharacters(in: .whitespaces)), value != original.number { edit.number = value }
        if let epgID, !epgID.isEmpty, epgID != original.epgID { edit.epgID = epgID }
        let logo = logoText.trimmingCharacters(in: .whitespaces)
        if !logo.isEmpty, let url = URL(string: logo), url != original.logoURL { edit.logo = url }
        store.saveChannelEdit(edit, for: item.id)
        dismiss()
    }

    /// Copie l'image choisie dans le dossier de l'application (elle reste disponible même si le fichier d'origine bouge).
    private func chooseLogo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let source = panel.url else { return }
        let folder = Storage.directory.appendingPathComponent("logos", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let safe = item.id.replacingOccurrences(of: "[^A-Za-z0-9]", with: "_", options: .regularExpression)
        let destination = folder.appendingPathComponent("\(safe).\(source.pathExtension.isEmpty ? "png" : source.pathExtension)")
        try? FileManager.default.removeItem(at: destination)
        if (try? FileManager.default.copyItem(at: source, to: destination)) != nil {
            logoText = destination.absoluteString
        }
    }
}
