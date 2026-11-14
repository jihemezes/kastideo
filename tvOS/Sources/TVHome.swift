import SwiftUI
import KastideoCore

/// Accueil, comme sur iPad : grandes tuiles (Direct, Films, Séries, Mes vidéos) et petits boutons d'accès rapide.
struct TVHomeView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(TVUI.self) private var ui
    @State private var collection: TVCollection?

    private var resumeItems: [MediaItem] {
        watch.entries
            .filter { watch.inResume($0.key) }
            .sorted { $0.value.updatedAt > $1.value.updatedAt }
            .compactMap { store.item(id: $0.key) }
    }
    private var recentItems: [MediaItem] { store.recentIDs.compactMap { store.item(id: $0) } }
    private var favoriteItems: [MediaItem] { store.favoriteIDs.compactMap { store.item(id: $0) } }

    var body: some View {
        if !store.hasSources {
            TVEmptyView(text: String(localized: "Bienvenue dans Kastideo. Ajoutez une source dans Réglages (ou depuis votre téléphone)."))
        } else {
            VStack(spacing: 40) {
                Spacer(minLength: 0)
                tiles
                quickButtons
                Text("Kastideo \(ReleaseNotes.currentVersion)").font(.caption).foregroundStyle(.white.opacity(0.35))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 100)
            .fullScreenCover(item: $collection) { TVCollectionView(collection: $0) }
        }
    }

    // MARK: Tuiles

    private var tiles: some View {
        let showLibrary = store.hasLibrary
        let columns = Array(repeating: GridItem(.flexible(), spacing: 30), count: showLibrary ? 4 : 3)
        return LazyVGrid(columns: columns, spacing: 30) {
            tile("Direct", "tv.fill", count(.live, String(localized: "chaînes")), [TVBrand.magenta, TVBrand.orange]) { ui.tab = 1 }
            tile("Films", "film.fill", count(.movie, String(localized: "films")), [TVBrand.violet, TVBrand.magenta]) { ui.tab = 2 }
            tile("Séries", "rectangle.stack.fill", count(.series, String(localized: "séries")), [TVBrand.indigo, TVBrand.violet]) { ui.tab = 3 }
            if showLibrary {
                tile("Mes vidéos", "photo.stack.fill", libraryCount, [TVBrand.orange, TVBrand.violet]) { ui.tab = 7 }
            }
        }
    }

    private func tile(_ title: LocalizedStringKey, _ icon: String, _ subtitle: String, _ colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).font(.system(size: 50, weight: .semibold))
                Spacer(minLength: 0)
                Text(title).font(.system(size: 40, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
                Text(subtitle.isEmpty ? " " : subtitle).font(.callout).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(26)
            .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240, alignment: .leading)
            .background(LinearGradient(colors: colors.map { $0.opacity(0.85) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.card)
    }

    private func count(_ kind: MediaKind, _ label: String) -> String {
        let n = store.count(for: kind)
        if n == 0 { return store.loading.isEmpty ? "" : String(localized: "Chargement…") }
        return "\(n.formatted()) \(label)"
    }

    private var libraryCount: String {
        let n = store.libraryItems().count
        if n == 0 { return store.loading.isEmpty ? String(localized: "Serveurs") : String(localized: "Chargement…") }
        return n == 1 ? String(localized: "1 vidéo") : String(localized: "\(n.formatted()) vidéos")
    }

    // MARK: Petits boutons

    private var quickButtons: some View {
        HStack(spacing: 20) {
            small("Reprendre", "play.circle.fill", resumeItems.count) { collection = TVCollection(title: String(localized: "Reprendre la lecture"), items: resumeItems) }
            small("Récents", "clock.arrow.circlepath", recentItems.count) { collection = TVCollection(title: String(localized: "Récents"), items: recentItems) }
            small("Favoris", "star.fill", favoriteItems.count) { collection = TVCollection(title: String(localized: "Favoris"), items: favoriteItems) }
            small("Guide TV", "calendar", 0) { ui.tab = 4 }
            small("Recherche", "magnifyingglass", 0) { ui.tab = 6 }
            small("Réglages", "gearshape.fill", 0) { ui.tab = 5 }
        }
    }

    private func small(_ title: LocalizedStringKey, _ icon: String, _ badge: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.callout.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
                Text(badge > 0 ? "\(badge)" : " ").font(.caption.monospacedDigit()).foregroundStyle(TVBrand.orange)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.card)
    }
}

/// Liste affichée en plein écran depuis l'accueil (Reprendre, Récents, Favoris).
struct TVCollection: Identifiable {
    let id = UUID()
    let title: String
    let items: [MediaItem]
}

struct TVCollectionView: View {
    let collection: TVCollection
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(TVUI.self) private var ui
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TVBackground()
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(collection.title).font(.largeTitle.bold())
                    Spacer()
                    Button("Fermer") { dismiss() }
                }
                if collection.items.isEmpty {
                    TVEmptyView(text: String(localized: "Rien à afficher pour l'instant."))
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 36, alignment: .top)], spacing: 40) {
                            ForEach(collection.items.prefix(240)) { item in
                                Button { open(item) } label: {
                                    VStack(spacing: 8) {
                                        ArtworkView(url: item.logoURL, name: item.name, contentMode: item.kind == .live ? .fit : .fill)
                                            .frame(height: item.kind == .live ? 120 : 300).clipped()
                                        Text(TMDB.cleanTitle(item.name).title).font(.caption).lineLimit(2).multilineTextAlignment(.center).padding(.horizontal, 6)
                                        if let fraction = watch.fraction(for: item.id) {
                                            ProgressView(value: fraction).tint(TVPalette.orange).padding(.horizontal, 12)
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                                .buttonStyle(.card)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .padding(60)
        }
    }

    private func open(_ item: MediaItem) {
        dismiss()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            switch item.kind {
            case .live: ui.play(item, list: collection.items.filter { $0.kind == .live }, playback: playback)
            case .episode: ui.play(item, playback: playback)
            default: ui.detail = item
            }
        }
    }
}

/// Mes vidéos : contenus des serveurs Emby, Jellyfin et Plex, par groupe.
struct TVLibraryView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(TVUI.self) private var ui
    @State private var group = ""

    private var all: [MediaItem] { store.libraryItems().filter { $0.kind == .movie || $0.kind == .series } }
    private var groups: [String] { Array(Set(all.map(\.group))).sorted() }

    var body: some View {
        let shown = group.isEmpty ? all : all.filter { $0.group == group }
        if all.isEmpty {
            TVEmptyView(text: store.loading.isEmpty ? String(localized: "Aucun contenu. Ajoutez un serveur Emby, Jellyfin ou Plex dans Réglages.") : String(localized: "Chargement des sources…"))
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TVCategoryButton(title: String(localized: "Groupe : ") + (group.isEmpty ? String(localized: "Tous") : group),
                                     options: [TVOption(value: TVScope.all, label: String(localized: "Tous"))] + groups.map { TVOption(value: TVScope.category($0), label: $0) },
                                     selection: Binding(get: { group.isEmpty ? TVScope.all : TVScope.category(group) }, set: { value in
                                         if case .category(let name) = value { group = name } else { group = "" }
                                     }))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 36, alignment: .top)], spacing: 40) {
                        ForEach(shown.prefix(240)) { item in
                            Button { ui.detail = item } label: {
                                VStack(spacing: 8) {
                                    ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill).frame(height: 300).clipped()
                                    Text(TMDB.cleanTitle(item.name).title).font(.caption).lineLimit(2).multilineTextAlignment(.center)
                                        .padding(.horizontal, 6).padding(.bottom, 8)
                                }
                            }
                            .buttonStyle(.card)
                        }
                    }
                    if shown.count > 240 { Text("\(shown.count) contenus : affinez par groupe ou utilisez la recherche.").foregroundStyle(.secondary) }
                }
                .padding(.horizontal, 60).padding(.vertical, 30)
            }
        }
    }
}
