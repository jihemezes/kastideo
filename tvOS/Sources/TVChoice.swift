import SwiftUI
import KastideoCore

/// Une option d'une liste de choix.
struct TVOption<Value: Hashable>: Identifiable {
    let value: Value
    let label: String
    var id: String { label }
}

/// Liste lisible (une option par ligne, coche sur le choix actuel) : remplace les sélecteurs en boutons minuscules.
struct TVChoiceList<Value: Hashable>: View {
    let title: String
    let options: [TVOption<Value>]
    @Binding var selection: Value
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    selection = option.value
                    dismiss()
                } label: {
                    HStack {
                        Text(option.label)
                        Spacer()
                        if option.value == selection { Image(systemName: "checkmark.circle.fill").foregroundStyle(TVPalette.orange) }
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}

/// Ligne de réglages : titre + valeur actuelle ; ouvre la liste de choix.
struct TVChoiceRow<Value: Hashable>: View {
    let title: String
    let options: [TVOption<Value>]
    @Binding var selection: Value

    var body: some View {
        NavigationLink {
            TVChoiceList(title: title, options: options, selection: $selection)
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text(options.first { $0.value == selection }?.label ?? "").foregroundStyle(.secondary)
            }
        }
    }
}

/// Bouton « Catégorie : … » qui ouvre une fenêtre avec toutes les catégories (Direct, Films, Séries).
struct TVCategoryButton: View {
    let title: String
    let options: [TVOption<TVScope>]
    @Binding var selection: TVScope
    @State private var showing = false

    var body: some View {
        Button { showing = true } label: {
            Label {
                Text(title).font(.callout.weight(.semibold)).lineLimit(1)
            } icon: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
        .sheet(isPresented: $showing) {
            NavigationStack {
                TVChoiceList(title: String(localized: "Catégorie"), options: options, selection: $selection)
            }
        }
    }
}

/// Recherche dans les chaînes, films et séries.
struct TVSearchView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(TVUI.self) private var ui
    @State private var query = ""
    @State private var results: [MediaItem] = []
    @State private var searching = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if results.isEmpty {
                    Text(query.count < 2 ? String(localized: "Saisissez au moins 2 lettres.") : (searching ? String(localized: "Recherche…") : String(localized: "Aucun résultat.")))
                        .foregroundStyle(.secondary).padding(.top, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 36, alignment: .top)], spacing: 40) {
                        ForEach(results) { item in
                            Button { open(item) } label: {
                                VStack(spacing: 8) {
                                    ArtworkView(url: item.logoURL, name: item.name, contentMode: item.kind == .live ? .fit : .fill)
                                        .frame(height: item.kind == .live ? 120 : 300)
                                        .clipped()
                                    Text(TMDB.cleanTitle(item.name).title).font(.caption).lineLimit(2).multilineTextAlignment(.center).padding(.horizontal, 6)
                                    Text(item.kind == .live ? "Direct" : (item.kind == .movie ? "Film" : "Série"))
                                        .font(.caption2).foregroundStyle(.secondary).padding(.bottom, 8)
                                }
                            }
                            .buttonStyle(.card)
                        }
                    }
                    .padding(.horizontal, 60)
                }
            }
            .searchable(text: $query, prompt: Text("Chaînes, films, séries"))
            .task(id: query) { await search() }
        }
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else { results = []; return }
        searching = true
        try? await Task.sleep(for: .milliseconds(450))
        if Task.isCancelled { return }
        let pool = store.items(for: .all(.live)) + store.items(for: .all(.movie)) + store.items(for: .all(.series))
        let found = await Task.detached(priority: .userInitiated) { () -> [MediaItem] in
            var out: [MediaItem] = []
            for item in pool where item.name.range(of: text, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                out.append(item)
                if out.count >= 120 { break }
            }
            return out
        }.value
        if !Task.isCancelled { results = found; searching = false }
    }

    private func open(_ item: MediaItem) {
        if item.kind == .live {
            ui.play(item, list: results.filter { $0.kind == .live }, playback: playback)
        } else {
            ui.detail = item
        }
    }
}
