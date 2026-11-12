import SwiftUI
import UniformTypeIdentifiers

/// Réglages > iCloud (iPhone, iPad et Mac) : dossier d'iCloud Drive, éléments synchronisés, phrase secrète.
struct CloudSettingsSection: View {
    @Environment(CloudSync.self) private var cloud
    @AppStorage(CloudKeys.enabled) private var enabled = false
    @AppStorage(CloudKeys.library) private var library = true
    @AppStorage(CloudKeys.progress) private var progress = true
    @AppStorage(CloudKeys.fiches) private var fiches = true
    @AppStorage(CloudKeys.passwords) private var passwords = true
    @State private var picking = false
    @State private var passphrase = ""
    @State private var savedPassphrase = false
    @State private var confirmErase = false

    var body: some View {
        Section {
            Toggle("Synchroniser avec iCloud Drive", isOn: $enabled)
                .onChange(of: enabled) { _, on in
                    if on { Task { await cloud.syncNow() } }
                }
            if enabled {
                LabeledContent("Dossier de synchronisation") {
                    Button(cloud.folderName ?? String(localized: "Choisir…")) { picking = true }
                }
                Toggle("Sources, favoris, catégories et réglages", isOn: $library)
                Toggle("Reprise de lecture", isOn: $progress)
                Toggle("Fiches corrigées et clé TMDB", isOn: $fiches)
                Toggle("Mots de passe des sources", isOn: $passwords)
                    .disabled(!library)
                if (library && passwords) || fiches {
                    SecureField("Phrase secrète (la même sur chaque appareil)", text: $passphrase)
                        .onSubmit(savePassphrase)
                    HStack {
                        Button("Enregistrer la phrase secrète", action: savePassphrase)
                            .disabled(passphrase == cloud.passphrase)
                        if savedPassphrase { Text("Enregistrée").font(.caption).foregroundStyle(.secondary) }
                    }
                }
                Button {
                    Task { await cloud.syncNow() }
                } label: {
                    HStack {
                        Label("Synchroniser maintenant", systemImage: "arrow.triangle.2.circlepath.icloud")
                        if cloud.state == .syncing { Spacer(); ProgressView().controlSize(.small) }
                    }
                }
                .disabled(cloud.state == .syncing || !CloudFolder.isChosen)
                LabeledContent("Dernière synchronisation") {
                    if let date = cloud.lastSync {
                        Text(date, format: .relative(presentation: .named))
                    } else {
                        Text("Jamais")
                    }
                }
                if case .problem(let message) = cloud.state {
                    Label(message, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange)
                } else if let summary = cloud.summary {
                    Text(summary).font(.caption).foregroundStyle(.secondary)
                }
                Button("Effacer les fichiers de synchronisation", role: .destructive) { confirmErase = true }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("Retrouvez vos sources, favoris et la reprise de lecture sur tous vos iPhone, iPad et Mac. Choisissez sur chaque appareil le même dossier d'iCloud Drive (par exemple « Kastideo ») : Kastideo y dépose de petits fichiers. Les mots de passe y sont chiffrés avec la phrase secrète (à saisir une fois par appareil). La modification la plus récente l'emporte. Dossiers, fichiers locaux et galerie restent propres à chaque appareil.")
        }
        .onAppear { passphrase = cloud.passphrase }
        .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { cloud.chooseFolder(url) }
        }
        .confirmationDialog("Effacer les fichiers de synchronisation ?", isPresented: $confirmErase, titleVisibility: .visible) {
            Button("Effacer et arrêter la synchronisation", role: .destructive) { Task { await cloud.eraseCloudData() } }
        } message: {
            Text("Les données de cet appareil sont conservées ; les fichiers du dossier iCloud Drive sont supprimés pour tous vos appareils.")
        }
    }

    private func savePassphrase() {
        cloud.setPassphrase(passphrase)
        savedPassphrase = true
        Task { await cloud.syncNow() }
    }
}
