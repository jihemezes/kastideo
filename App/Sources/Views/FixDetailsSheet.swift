import SwiftUI
import KastideoCore

/// « Corriger la fiche… » d'un film ou d'une série trouvé dans un dossier : recherche TMDB et choix du bon titre.
struct FixDetailsSheet: View {
    @Environment(LibraryStore.self) private var store
    @Environment(MediaInfoStore.self) private var info
    @Environment(\.dismiss) private var dismiss
    let item: MediaItem

    @State private var title = ""
    @State private var year = ""
    @State private var results: [TMDBMatch] = []
    @State private var searching = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Corriger la fiche").font(.title2.weight(.semibold))
            if let file = item.streamURL, file.isFileURL {
                Text(file.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if !info.usesTMDB {
                Label("Ajoutez une clé TMDB (Réglages > Général) pour chercher les fiches.", systemImage: "key")
                    .foregroundStyle(.orange)
            }
            HStack {
                TextField("Titre", text: $title)
                    .onSubmit { Task { await search() } }
                TextField("Année", text: $year)
                    .frame(width: 80)
                    .onSubmit { Task { await search() } }
                Button {
                    Task { await search() }
                } label: {
                    if searching { ProgressView().controlSize(.small) } else { Text("Chercher") }
                }
                .disabled(!info.usesTMDB || searching || title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let message {
                Text(message).font(.callout).foregroundStyle(.secondary)
            }
            List(results) { match in
                Button {
                    Task {
                        await info.applyFix(item, match: match, store: store)
                        dismiss()
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        PosterView(url: match.posterURL, name: match.title)
                            .frame(width: 54, height: 81)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(match.year.map { "\(match.title) (\(String($0)))" } ?? match.title)
                                .font(.headline)
                            if let overview = match.overview {
                                Text(overview).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
            .frame(minHeight: 280)
            HStack {
                Spacer()
                Button("Fermer") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 620, height: 560)
        .task {
            let cleaned = TMDB.cleanTitle(item.name)
            title = cleaned.title
            year = cleaned.year.map(String.init) ?? ""
            if info.usesTMDB { await search() }
        }
    }

    private func search() async {
        searching = true
        defer { searching = false }
        do {
            results = try await info.searchTMDB(title: title, isSeries: item.kind == .series,
                                                year: Int(year.trimmingCharacters(in: .whitespaces)))
            message = results.isEmpty ? String(localized: "Aucun résultat : essayez un autre titre, sans l'année.") : nil
        } catch {
            message = String(localized: "TMDB n'a pas répondu (vérifiez la clé dans Réglages > Général).")
        }
    }
}
