import SwiftUI
import AppKit
import KastideoCore

/// Colonne centrale : liste des chaînes / films / séries de la sélection, avec recherche.
struct ItemListView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation
        let browse = navigation.browse ?? .all(.live)
        let items = filtered(store.items(for: browse), search: navigation.search)

        Group {
            if items.isEmpty {
                if navigation.search.isEmpty {
                    ContentUnavailableView(browse.title, systemImage: "tray", description: Text(browse.emptyMessage))
                } else {
                    ContentUnavailableView.search(text: navigation.search)
                }
            } else {
                List(items, selection: $navigation.selectedItemID) { item in
                    ItemRow(item: item)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(browse.title)
        .navigationSubtitle(items.isEmpty ? "" : "\(items.count) éléments")
        .searchable(text: $navigation.search, placement: .toolbar, prompt: "Rechercher")
        .onChange(of: items.map(\.id), initial: true) { _, ids in
            navigation.visibleIDs = ids
        }
    }

    private func filtered(_ items: [MediaItem], search: String) -> [MediaItem] {
        let key = search.kastideoSearchKey
        guard !key.isEmpty else { return items }
        return items.filter { $0.searchKey.contains(key) }
    }
}

struct ItemRow: View {
    @Environment(LibraryStore.self) private var store
    let item: MediaItem

    var body: some View {
        HStack(spacing: 10) {
            LogoView(url: item.logoURL, name: item.name, size: item.kind == .live ? 36 : 44)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let number = item.number, item.kind == .live {
                        Text("\(number)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text(item.name)
                        .lineLimit(1)
                }
                subtitle
            }
            Spacer(minLength: 4)
            if store.isFavorite(item.id) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
            if item.needsEpisodes {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(store.isFavorite(item.id) ? "Retirer des favoris" : "Ajouter aux favoris") {
                store.toggleFavorite(item.id)
            }
            if let url = item.streamURL {
                Button("Copier l'adresse du flux") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.absoluteString, forType: .string)
                }
            }
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        if item.kind == .live, let programme = store.epg.current(for: item.epgID) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                VStack(alignment: .leading, spacing: 2) {
                    Text(programme.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    ProgressView(value: programme.progress(at: context.date))
                        .progressViewStyle(.linear)
                        .controlSize(.mini)
                        .frame(maxWidth: 160)
                }
            }
        } else {
            Text(item.group)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

/// Logo d'une chaîne ou affiche, avec initiales en secours.
struct LogoView: View {
    let url: URL?
    let name: String
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(.quaternary)
            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.15))) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit().padding(size * 0.08)
                    default:
                        initials
                    }
                }
            } else {
                initials
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }

    private var initials: some View {
        Text(String(name.filter { $0.isLetter || $0.isNumber }.prefix(2)).uppercased())
            .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
    }
}
