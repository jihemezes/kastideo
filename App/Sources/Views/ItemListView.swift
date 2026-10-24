import SwiftUI
import AppKit
import KastideoCore

/// Colonne centrale : catalogue ou section « Enregistrements ».
struct ItemListView: View {
    @Environment(NavigationModel.self) private var navigation

    var body: some View {
        if navigation.browse == .recordings {
            RecordingsListView()
        } else if navigation.browse == .themes {
            ThemesListView()
        } else {
            CatalogListView()
        }
    }
}

/// Liste des chaînes / films / séries de la sélection, avec recherche.
struct CatalogListView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation

    var body: some View {
        let browse = navigation.browse ?? .all(.live)
        // Section affichée dans une autre interface (Cinéma, TV) : la liste classique ne doit pas être construite,
        // même un instant (une liste de 100 000 films bloquait l'application près d'une minute).
        if let scope = InterfaceScope.scope(for: browse), scope.style() != .classic {
            Color.clear
        } else {
            list(browse)
        }
    }

    @ViewBuilder
    private func list(_ browse: Browse) -> some View {
        @Bindable var navigation = navigation
        let _ = navigation.mark("Liste classique — \(browse.title)")
        let items = filtered(store.items(for: browse), search: navigation.search)

        Group {
            if items.isEmpty {
                if navigation.search.isEmpty {
                    ContentUnavailableView(browse.title, systemImage: "tray", description: Text(browse.emptyMessage))
                } else {
                    ContentUnavailableView.search(text: navigation.search)
                }
            } else if browse == .recents && navigation.search.isEmpty {
                RecentsList(items: items)
            } else {
                List(items, selection: $navigation.selectedItemID) { item in
                    ItemRow(item: item)
                }
                .listStyle(.inset)
            }
        }
        .recentsUndoToast()
        .navigationTitle(browse.title)
        .navigationSubtitle(items.isEmpty ? "" : String(localized: "\(items.count) éléments"))
        .searchable(text: $navigation.search, placement: .toolbar, prompt: "Rechercher")
        .onChange(of: items.map(\.id), initial: true) { _, ids in
            navigation.visibleIDs = ids
        }
        .onAppear { navigation.noteDisplayed(String(localized: "Classique — \(browse.title)")) }
    }

    private func filtered(_ items: [MediaItem], search: String) -> [MediaItem] {
        let key = search.kastideoSearchKey
        guard !key.isEmpty else { return items }
        return items.filter { $0.searchKey.contains(key) }
    }
}

struct ItemRow: View {
    @Environment(LibraryStore.self) private var store
    @Environment(RecordingCenter.self) private var recordings
    @Environment(WatchProgressStore.self) private var watch
    @AppStorage(AppearanceKeys.density) private var densityRaw = ListDensity.standard.rawValue
    let item: MediaItem

    var body: some View {
        let density = ListDensity(rawValue: densityRaw) ?? .standard
        HStack(spacing: 10) {
            LogoView(url: item.logoURL, name: item.name,
                     size: item.kind == .live ? density.liveLogo : density.posterLogo)
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
                if item.kind != .live, let fraction = watch.fraction(for: item.id) {
                    ProgressView(value: fraction)
                        .progressViewStyle(.linear)
                        .controlSize(.mini)
                        .frame(maxWidth: 160)
                        .help("Déjà vu à \(Int(fraction * 100)) %")
                }
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
        .padding(.vertical, density.rowPadding)
        .contextMenu { ItemActionsMenu(item: item) }
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

/// Actions du menu contextuel d'un contenu (listes et vignettes).
struct ItemActionsMenu: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(RecordingCenter.self) private var recordings
    @Environment(MultiViewModel.self) private var multiView
    @Environment(PlaybackController.self) private var playback
    @Environment(\.openWindow) private var openWindow
    let item: MediaItem

    var body: some View {
        Button(store.isFavorite(item.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris")) {
            store.toggleFavorite(item.id)
        }
        if item.kind == .live {
            Divider()
            Button(recordings.isRecording(item) ? String(localized: "Arrêter l'enregistrement") : String(localized: "Enregistrer maintenant")) {
                if recordings.isRecording(item) { recordings.stopLive() } else { recordings.recordNow(item) }
            }
            Button("Programmer un enregistrement…") { recordings.scheduleSheetItem = item }
            Button("Modifier la chaîne…") { navigation.editingChannel = item }
            let videoOnly = PlaybackController.videoOnlyIDs.contains(item.id)
            Button {
                playback.setVideoOnly(!videoOnly, for: item)
            } label: {
                if videoOnly { Label("Image seule (sans le son)", systemImage: "checkmark") } else { Text("Image seule (sans le son)") }
            }
            if MultiViewKeys.isAvailable {
                Button("Ajouter à la MultiVue") {
                    multiView.add(item)
                    openWindow(id: "multiview")
                }
            }
        } else if let url = item.streamURL, !url.isFileURL {
            Divider()
            Button("Télécharger") { recordings.download(item, tonight: false) }
            Button("Télécharger cette nuit") { recordings.download(item, tonight: true) }
        }
        if store.recentIDs.contains(item.id) {
            Divider()
            Button("Retirer des récents") { store.removeRecents([item.id]) }
        }
        if let url = item.streamURL, !url.isFileURL {
            Divider()
            Button("Copier l'adresse du flux") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
            }
        }
    }
}
