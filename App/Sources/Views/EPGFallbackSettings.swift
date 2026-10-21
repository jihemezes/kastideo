import SwiftUI
import KastideoCore

/// Réglages : guide TV de secours (xmltvfr.fr ou autre adresse XMLTV).
struct EPGFallbackSettingsSection: View {
    @Environment(LibraryStore.self) private var store
    @State private var enabled = EPGKeys.fallbackEnabled
    @State private var urlText = EPGKeys.fallbackURLText

    var body: some View {
        Section("Guide TV de secours") {
            Toggle("Compléter le guide du fournisseur avec un guide de secours", isOn: $enabled)
                .onChange(of: enabled) { _, value in store.setFallbackEnabled(value) }
            if enabled {
                HStack {
                    TextField("Adresse du guide (XMLTV, .xml ou .xml.gz)", text: $urlText)
                        .onSubmit { store.setFallbackURL(urlText) }
                    Menu("Choisir") {
                        ForEach(EPGKeys.presets, id: \.url) { preset in
                            Button(preset.label) {
                                urlText = preset.url
                                store.setFallbackURL(preset.url)
                            }
                        }
                    }
                    .fixedSize()
                }
                HStack {
                    status
                    Spacer()
                    if store.fallbackStatus.isLoading {
                        ProgressView().controlSize(.small)
                    }
                    Button("Actualiser maintenant") {
                        store.setFallbackURL(urlText)
                    }
                    .disabled(store.fallbackStatus.isLoading)
                }
            }
            Text("Les chaînes sans programme dans le guide de votre fournisseur sont complétées automatiquement, en les rapprochant par leur nom (« |FR| TF1 FHD » → TF1). Guide gratuit et communautaire de xmltvfr.fr, mis à jour chaque jour, rechargé toutes les 12 heures.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var status: some View {
        let state = store.fallbackStatus
        if let error = state.error {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        } else if let date = state.updated {
            Text("\(state.channelCount) chaînes, \(state.matchedChannels) reliées à vos chaînes · mis à jour \(date.formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if !state.isLoading {
            Text("Pas encore chargé.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
