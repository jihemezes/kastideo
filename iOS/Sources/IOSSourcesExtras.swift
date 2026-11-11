import SwiftUI
import UIKit
import KastideoCore

/// Choix de la source affichée (sans désactiver les autres) et fusion des doublons entre comptes.
struct IOSActiveSourceSection: View {
    @Environment(LibraryStore.self) private var store
    @State private var counts: [UUID: (live: Int, movies: Int, series: Int)] = [:]

    var body: some View {
        if store.selectableSources.count > 1 {
            Section {
                Picker("Source affichée", selection: Binding(
                    get: { store.activeSource?.id },
                    set: { store.activeSourceID = $0 })) {
                    Text("Toutes les sources").tag(UUID?.none)
                    ForEach(store.selectableSources) { source in
                        Text(label(source)).tag(Optional(source.id))
                    }
                }
                Toggle("Fusionner les doublons entre comptes", isOn: Binding(
                    get: { store.dedupeSources },
                    set: { store.dedupeSources = $0 }))
                    .disabled(store.activeSource != nil)
            } header: {
                Text("Abonnements")
            } footer: {
                Text("Choisissez l'abonnement à afficher sans désactiver les autres. Avec « Toutes les sources », un film ou une série fourni par plusieurs comptes n'apparaît qu'une fois.")
            }
            .task(id: store.count(for: .live) + store.count(for: .movie) + store.count(for: .series)) {
                var result: [UUID: (live: Int, movies: Int, series: Int)] = [:]
                for source in store.selectableSources {
                    result[source.id] = (store.visibleCount(.live, source: source),
                                         store.visibleCount(.movie, source: source),
                                         store.visibleCount(.series, source: source))
                }
                counts = result
            }
        }
    }

    private func label(_ source: Source) -> String {
        guard let c = counts[source.id] else { return source.name }
        return "\(source.name) · \(c.live) / \(c.movies) / \(c.series)"
    }
}

/// « Diagnostic » d'une source : ce que le fournisseur renvoie et ce que Kastideo en affiche.
struct IOSSourceDiagnosticSheet: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let source: Source
    @State private var report = ""
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if loading {
                        ProgressView()
                    } else {
                        Text(report)
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                    Text("Deux comptes d'un même fournisseur peuvent avoir des bouquets de films et séries différents : les chaînes sont souvent communes, pas les catalogues. Si « renvoyés par le fournisseur » diffère, la différence vient du fournisseur, pas de Kastideo.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Diagnostic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIPasteboard.general.string = report
                    } label: {
                        Label("Copier", systemImage: "doc.on.doc")
                    }
                    .disabled(loading)
                }
            }
            .task { await build() }
        }
    }

    private func build() async {
        var lines: [String] = ["\(source.name) · \(source.kind.title)"]
        if case .xtream(let server, _) = source.kind, let host = server.host {
            lines.append(String(localized: "Serveur") + " : " + host)
        }
        if let client = store.xtreamClient(for: source.id) {
            do {
                let info = try await client.accountSummary()
                if !info.isEmpty { lines.append(String(localized: "Compte") + " : " + info.joined(separator: " · ")) }
            } catch {
                lines.append(String(localized: "Compte") + " : " + String(localized: "illisible") + " (\(error.localizedDescription))")
            }
        }
        lines.append("")
        let showAdult = UserDefaults.standard.bool(forKey: "adult.show")
        let raw = store.content(of: source.id)?.items ?? []
        for kind in [MediaKind.live, .movie, .series] {
            let all = raw.filter { $0.kind == kind }
            if all.isEmpty && !source.kind.isIPTV { continue }
            let prefs = store.prefs(for: kind)
            let inHidden = all.filter { prefs.isHidden($0.group) }.count
            let adult = showAdult ? 0 : all.filter { !prefs.isHidden($0.group) && ThemeClassifier.isAdult(name: $0.name, group: $0.group) }.count
            let visible = store.visibleCount(kind, source: source)
            let other = all.count - inHidden - adult - visible
            let label: String
            switch kind {
            case .live: label = String(localized: "Chaînes")
            case .movie: label = String(localized: "Films")
            default: label = String(localized: "Séries")
            }
            let categories = Set(all.map(\.group)).count
            lines.append("\(label) : \(all.count) " + String(localized: "renvoyés par le fournisseur") + " (\(categories) " + String(localized: "catégories") + ")")
            lines.append("   " + String(localized: "Affichés") + " : \(visible)")
            if inHidden > 0 { lines.append("   " + String(localized: "Dans des catégories masquées") + " : \(inHidden)") }
            if adult > 0 { lines.append("   " + String(localized: "Contenus adultes masqués") + " : \(adult)") }
            if other > 0 { lines.append("   " + String(localized: "Autres (doublons fusionnés avec un autre compte, source non affichée)") + " : \(other)") }
        }
        report = lines.joined(separator: "\n")
        loading = false
    }
}
