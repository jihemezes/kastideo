import SwiftUI
import KastideoCore

/// Réglages du replay : archive du fournisseur (jusqu'à 14 jours selon l'abonnement).
struct ReplaySettingsSection: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage(ReplaySettings.enabledKey) private var enabled = true
    @AppStorage(ReplaySettings.guideDaysKey) private var guideDays = 3
    @AppStorage(ReplaySettings.offsetKey) private var offset = 0
    @AppStorage(ReplaySettings.returnToLiveKey) private var returnToLive = true

    private var archiveChannels: Int {
        store.items(for: .all(.live)).filter { ($0.archiveDays ?? 0) > 0 }.count
    }

    var body: some View {
        Section("Replay") {
            Toggle("Proposer le replay des chaînes qui en ont un", isOn: $enabled)
            Picker("Jours de programmes passés gardés dans le guide", selection: $guideDays) {
                ForEach([1, 2, 3, 5, 7, 10, 14], id: \.self) { Text("\($0) j").tag($0) }
            }
            .disabled(!enabled)
            Stepper(value: $offset, in: -180...180, step: 5) {
                LabeledContent("Décalage de l'heure du replay", value: "\(offset) min")
            }
            .disabled(!enabled)
            Toggle("Revenir au direct à la fin du programme revu", isOn: $returnToLive)
                .disabled(!enabled)
            Text("\(archiveChannels) chaîne(s) avec replay détectée(s). Plus vous gardez de jours, plus le guide pèse en mémoire : il est rechargé au prochain rafraîchissement. Si le programme revu ne correspond pas à celui choisi, corrigez l'heure avec le décalage (le fuseau du serveur est lu automatiquement).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
