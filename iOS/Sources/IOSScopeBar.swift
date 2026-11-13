import SwiftUI
import KastideoCore

/// Barre de choix de la catégorie (Toutes, Favoris, Récents, puis les catégories) au-dessus des listes,
/// avec un bouton qui ouvre la liste complète des catégories (recherche, nombre de contenus).
struct IOSScopeBar: View {
    let kind: MediaKind
    @Binding var scope: IOSListScope
    @Environment(LibraryStore.self) private var store
    @State private var showAll = false

    private var categories: [String] { store.categoriesByKind[kind] ?? [] }

    var body: some View {
        HStack(spacing: 0) {
            Button { showAll = true } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.body.weight(.semibold))
                    .frame(width: 40, height: 34)
            }
            .buttonStyle(.plain)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        chip(String(localized: "Toutes"), .all)
                        chip(String(localized: "Favoris"), .favorites, icon: "star")
                        chip(String(localized: "Récents"), .recents, icon: "clock")
                        ForEach(categories, id: \.self) { name in
                            chip(name, .category(name))
                        }
                    }
                    .padding(.trailing, 12)
                }
                .onChange(of: scope) { _, new in
                    withAnimation { proxy.scrollTo(new, anchor: .center) }
                }
                .onAppear { proxy.scrollTo(scope, anchor: .center) }
            }
        }
        .padding(.vertical, 6)
        .background(.bar)
        .sheet(isPresented: $showAll) {
            IOSCategoryPicker(kind: kind, scope: $scope)
        }
    }

    private func chip(_ title: String, _ value: IOSListScope, icon: String? = nil) -> some View {
        let selected = scope == value
        return Button { scope = value } label: {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.caption) }
                Text(title).lineLimit(1)
            }
            .font(.callout.weight(selected ? .semibold : .regular))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(selected ? IOSPalette.orange.opacity(0.28) : Color.secondary.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
        .id(value)
    }
}

/// Liste complète des catégories, avec recherche et nombre de contenus.
struct IOSCategoryPicker: View {
    let kind: MediaKind
    @Binding var scope: IOSListScope
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        let categories = (store.categoriesByKind[kind] ?? []).filter {
            search.isEmpty || $0.localizedCaseInsensitiveContains(search)
        }
        NavigationStack {
            List {
                if search.isEmpty {
                    row(String(localized: "Toutes"), .all, icon: "square.grid.2x2")
                    row(String(localized: "Favoris"), .favorites, icon: "star")
                    row(String(localized: "Récents"), .recents, icon: "clock")
                }
                Section(String(localized: "Catégories")) {
                    ForEach(categories, id: \.self) { name in
                        row(name, .category(name), count: store.categoryCounts[kind]?[name])
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $search, prompt: "Rechercher une catégorie")
            .navigationTitle("Catégories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } } }
        }
    }

    private func row(_ title: String, _ value: IOSListScope, icon: String? = nil, count: Int? = nil) -> some View {
        Button {
            scope = value
            dismiss()
        } label: {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon).foregroundStyle(.secondary).frame(width: 22) }
                Text(title).foregroundStyle(.primary).lineLimit(1)
                Spacer()
                if let count { Text(count.formatted()).font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
                if scope == value { Image(systemName: "checkmark").foregroundStyle(IOSPalette.orange) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
