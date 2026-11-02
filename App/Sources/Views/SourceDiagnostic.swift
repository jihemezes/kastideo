import SwiftUI
import AppKit
import KastideoCore

/// « Diagnostic » d'une source : ce que le fournisseur renvoie et ce que Kastideo en affiche (utile pour comparer deux comptes).
struct SourceDiagnosticSheet: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let source: Source
    @State private var report = ""
    @State private var loading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diagnostic de la source").font(.title2.weight(.semibold))
            if loading {
                ProgressView().controlSize(.small)
            } else {
                ScrollView {
                    Text(report)
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 200, maxHeight: 360)
                .padding(8)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            }
            Text("Deux comptes d'un même fournisseur peuvent avoir des bouquets de films et séries différents : les chaînes sont souvent communes, pas les catalogues. Si « renvoyés par le fournisseur » diffère, la différence vient du fournisseur, pas de Kastideo.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button("Copier") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(report, forType: .string)
                }
                .disabled(loading)
                Spacer()
                Button("Fermer") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 560)
        .task { await build() }
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
