import SwiftUI
import KastideoCore

/// Direct, Films ou Séries : barre de catégories + grille. Un appui lance la lecture (direct) ou ouvre la fiche.
struct TVBrowseView: View {
    let kind: MediaKind
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(TVUI.self) private var ui
    @State private var scope: TVScope = .none
    @AppStorage private var styleRaw: String

    init(kind: MediaKind) {
        self.kind = kind
        _styleRaw = AppStorage(wrappedValue: TVStyle.classic.rawValue, TVInterface.key(kind))
    }

    private var style: TVStyle {
        let value = TVStyle(rawValue: styleRaw) ?? .classic
        return TVInterface.available(for: kind).contains(value) ? value : .classic
    }

    private var categories: [String] { store.categoriesByKind[kind] ?? [] }

    private var items: [MediaItem] { effectiveScope.items(kind: kind, store: store) }

    /// Sans choix, la page de départ du réglage (tout le catalogue d'un fournisseur serait trop lourd à afficher).
    private var effectiveScope: TVScope {
        scope != .none ? scope : TVScope.start(for: kind, categories: categories)
    }

    @ViewBuilder
    var body: some View {
        if !store.hasSources {
            TVEmptyView(text: String(localized: "Ajoutez une source dans Réglages."))
        } else if store.count(for: kind) == 0 {
            TVEmptyView(text: store.loading.isEmpty ? String(localized: "Aucun contenu pour cette section.") : String(localized: "Chargement des sources…"))
        } else if style == .cinema {
            TVCinemaView(kind: kind)
        } else if style == .tv {
            TVLiveTVView()
        } else {
            classic
        }
    }

    private var classic: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                chips
                let shown = items
                LazyVGrid(columns: columns, alignment: .leading, spacing: 40) {
                    ForEach(shown.prefix(240)) { item in
                        Button { open(item, list: shown) } label: { TVItemTile(item: item) }
                            .buttonStyle(.card)
                            .contextMenu {
                                Button(store.isFavorite(item.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris"),
                                       systemImage: store.isFavorite(item.id) ? "star.slash" : "star") { store.toggleFavorite(item.id) }
                            }
                    }
                }
                if shown.count > 240 {
                    Text("\(shown.count) contenus : affinez par catégorie.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }

    private var columns: [GridItem] {
        kind == .live
            ? [GridItem(.adaptive(minimum: 260, maximum: 300), spacing: 36, alignment: .top)]
            : [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 36, alignment: .top)]
    }

    private var scopeOptions: [TVOption<TVScope>] {
        var list: [TVOption<TVScope>] = [TVOption(value: TVScope.all, label: String(localized: "Toutes")),
                                         TVOption(value: TVScope.favorites, label: String(localized: "Favoris")),
                                         TVOption(value: TVScope.recents, label: String(localized: "Récents"))]
        list += categories.map { TVOption(value: TVScope.category($0), label: $0) }
        return list
    }

    private var scopeTitle: String {
        switch effectiveScope {
        case .none, .all: return String(localized: "Toutes")
        case .favorites: return String(localized: "Favoris")
        case .recents: return String(localized: "Récents")
        case .category(let name): return name
        }
    }

    private var chips: some View {
        HStack {
            TVCategoryButton(title: String(localized: "Catégorie : ") + scopeTitle, options: scopeOptions,
                             selection: Binding(get: { effectiveScope }, set: { value in
                                 scope = value
                                 if case .category(let name) = value { UserDefaults.standard.set(name, forKey: StartPage.lastKey(kind)) }
                             }))
            TVStyleButton(kind: kind)
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private func open(_ item: MediaItem, list: [MediaItem]) {
        if item.kind == .live {
            ui.play(item, list: list, playback: playback)
        } else {
            ui.detail = item
        }
    }
}

enum TVScope: Hashable {
    case none, all, favorites, recents
    case category(String)
}

struct TVEmptyView: View {
    let text: String
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv").font(.system(size: 90)).foregroundStyle(.secondary)
            Text(text).font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
