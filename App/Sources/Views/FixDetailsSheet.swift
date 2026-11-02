import SwiftUI
import KastideoCore

/// « Corriger la fiche… » d'un film ou d'une série : code ou adresse TMDB, recherche par titre, ou textes et affiche saisis à la main.
struct FixDetailsSheet: View {
    @Environment(LibraryStore.self) private var store
    @Environment(MediaInfoStore.self) private var info
    @Environment(\.dismiss) private var dismiss
    let item: MediaItem

    @State private var code = ""
    @State private var preview: MediaDetails?
    @State private var codeProblem: String?
    @State private var checking = false

    @State private var title = ""
    @State private var year = ""
    @State private var results: [TMDBMatch] = []
    @State private var searching = false
    @State private var message: String?

    @State private var customTitle = ""
    @State private var customYear = ""
    @State private var customPoster = ""
    @State private var customPlot = ""
    @State private var showCustom = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Corriger la fiche").font(.title2.weight(.semibold))
                Text(item.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !info.usesTMDB {
                    Label("Ajoutez une clé TMDB (Réglages > Général) pour chercher les fiches.", systemImage: "key")
                        .foregroundStyle(.orange)
                }
                if let current = info.edits[item.id], !current.isEmpty {
                    HStack {
                        Label(currentSummary(current), systemImage: "link")
                            .font(.callout)
                        Spacer()
                        Button("Retirer la correction", role: .destructive) {
                            Task {
                                await info.setEdit(item, nil, store: store)
                                dismiss()
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                }

                GroupBox("Code TMDB") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sur themoviedb.org, ouvrez la bonne fiche : le numéro est dans l'adresse (…/movie/12345-hero). Saisissez ce numéro ou collez l'adresse.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            TextField("Numéro ou adresse TMDB", text: $code)
                                .onSubmit { Task { await check() } }
                            Button {
                                Task { await check() }
                            } label: {
                                if checking { ProgressView().controlSize(.small) } else { Text("Vérifier") }
                            }
                            .disabled(!info.usesTMDB || checking || code.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        if let codeProblem {
                            Text(codeProblem).font(.callout).foregroundStyle(.orange)
                        }
                        if let preview {
                            HStack(alignment: .top, spacing: 12) {
                                PosterView(url: preview.posterURL, name: preview.title ?? "")
                                    .frame(width: 54, height: 81)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preview.year.map { "\(preview.title ?? "") (\(String($0)))" } ?? (preview.title ?? ""))
                                        .font(.headline)
                                    if let plot = preview.plot {
                                        Text(plot).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                                    }
                                    Button("Utiliser cette fiche") {
                                        Task {
                                            var edit = info.edits[item.id] ?? FicheEdit()
                                            edit.tmdbID = preview.tmdbID
                                            await info.setEdit(item, edit, store: store)
                                            dismiss()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(6)
                }

                GroupBox("Chercher par titre") {
                    VStack(alignment: .leading, spacing: 8) {
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
                        ForEach(results) { match in
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
                                        Text(match.year.map { "\(match.title) (\(String($0))) · TMDB \(match.tmdbID)" } ?? "\(match.title) · TMDB \(match.tmdbID)")
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
                    }
                    .padding(6)
                }

                DisclosureGroup("Personnaliser la fiche à la main", isExpanded: $showCustom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Les champs remplis remplacent ceux du fournisseur et de TMDB. Laissez vide pour ne rien changer.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Titre affiché", text: $customTitle)
                        TextField("Année", text: $customYear)
                            .frame(width: 100)
                        TextField("Adresse de l'affiche (https://…)", text: $customPoster)
                        Text("Résumé").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $customPlot)
                            .frame(height: 90)
                            .border(Color.secondary.opacity(0.3))
                        HStack {
                            Spacer()
                            Button("Enregistrer") {
                                Task {
                                    var edit = info.edits[item.id] ?? FicheEdit()
                                    edit.title = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                    edit.year = Int(customYear.trimmingCharacters(in: .whitespaces))
                                    edit.poster = customPoster.trimmingCharacters(in: .whitespacesAndNewlines)
                                    edit.plot = customPlot.trimmingCharacters(in: .whitespacesAndNewlines)
                                    await info.setEdit(item, edit, store: store)
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(.top, 6)
                }

                HStack {
                    Spacer()
                    Button("Fermer") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
            .padding(20)
        }
        .frame(width: 640, height: 640)
        .task {
            let cleaned = TMDB.cleanTitle(item.name)
            title = cleaned.title
            year = cleaned.year.map(String.init) ?? ""
            if let current = info.edits[item.id] {
                code = current.tmdbID ?? ""
                customTitle = current.title ?? ""
                customYear = current.year.map(String.init) ?? ""
                customPoster = current.poster ?? ""
                customPlot = current.plot ?? ""
                showCustom = !(customTitle.isEmpty && customYear.isEmpty && customPoster.isEmpty && customPlot.isEmpty)
            }
            if info.usesTMDB, info.edits[item.id] == nil { await search() }
        }
    }

    private func currentSummary(_ edit: FicheEdit) -> String {
        var parts: [String] = []
        if let id = edit.tmdbID, !id.isEmpty { parts.append("TMDB \(id)") }
        if edit.title?.isEmpty == false { parts.append(String(localized: "titre")) }
        if edit.year != nil { parts.append(String(localized: "année")) }
        if edit.posterURL != nil { parts.append(String(localized: "affiche")) }
        if edit.plot?.isEmpty == false { parts.append(String(localized: "résumé")) }
        return String(localized: "Correction en place") + " : " + parts.joined(separator: ", ")
    }

    private func check() async {
        checking = true
        codeProblem = nil
        preview = nil
        defer { checking = false }
        let result = await info.lookup(code, for: item)
        preview = result.details
        codeProblem = result.problem
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
