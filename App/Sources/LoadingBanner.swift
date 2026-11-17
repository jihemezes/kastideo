import SwiftUI

/// Bandeau au premier plan pendant le chargement ou le recalcul du catalogue : l'écran peut se figer quelques secondes.
struct LoadingBanner: View {
    let names: [String]

    var body: some View {
        let list = names.joined(separator: ", ")
        HStack(spacing: 12) {
            ProgressView().controlSize(.regular)
            VStack(alignment: .leading, spacing: 2) {
                Text("Mise à jour du catalogue").font(.subheadline.weight(.bold))
                Text(names.isEmpty
                     ? String(localized: "Kastideo recalcule les chaînes, films et séries affichés. Cela peut prendre quelques secondes : l'application peut sembler figée, c'est normal.")
                     : String(localized: "Kastideo vérifie et télécharge les chaînes, films et séries de « \(list) ». Cela peut prendre une minute : l'application peut sembler figée, c'est normal."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: 520, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(radius: 10)
        .padding(.top, 10).padding(.horizontal, 12)
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

extension LibraryStore {
    /// Vrai pendant qu'une source se charge ou que les listes sont recalculées.
    var showsUpdateBanner: Bool { !loading.isEmpty || indexing }
    var loadingSourceNames: [String] { sources.filter { loading.contains($0.id) }.map(\.name) }
}
