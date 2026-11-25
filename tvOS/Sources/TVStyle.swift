import SwiftUI
import KastideoCore

// MARK: - Bouton « tuile » (une seule forme, pas de plaque translucide décalée)

/// Remplace `.card` : le contenu, le liseré de focus et la zone cliquable partagent exactement la même forme arrondie.
struct TVTileStyle: ButtonStyle {
    var radius: CGFloat = 18
    /// Fond translucide derrière un contenu sans fond propre (affiches, logos).
    var plate = false

    func makeBody(configuration: Configuration) -> some View {
        TVTileBody(configuration: configuration, radius: radius, plate: plate)
    }
}

private struct TVTileBody: View {
    let configuration: ButtonStyleConfiguration
    let radius: CGFloat
    let plate: Bool
    @Environment(\.isFocused) private var focused

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        configuration.label
            .background(plate ? Color.white.opacity(0.10) : Color.clear)
            .clipShape(shape)
            .overlay(shape.stroke(TVBrand.orange, lineWidth: focused ? 6 : 0))
            .scaleEffect(focused ? 1.06 : 1)
    }
}

// MARK: - Affichages Classique / Cinéma / TV

enum TVStyle: String, CaseIterable {
    case classic, cinema, tv

    var label: String {
        switch self {
        case .classic: return String(localized: "Classique")
        case .cinema: return String(localized: "Cinéma")
        case .tv: return String(localized: "TV")
        }
    }
}

enum TVInterface {
    static func key(_ kind: MediaKind) -> String { "tv.interface.\(kind.rawValue)" }

    /// L'affichage TV (lecteur plein écran + zapping) n'existe que pour le direct.
    static func available(for kind: MediaKind) -> [TVStyle] {
        kind == .live ? [.classic, .cinema, .tv] : [.classic, .cinema]
    }

    static func current(for kind: MediaKind) -> TVStyle {
        let style = TVStyle(rawValue: UserDefaults.standard.string(forKey: key(kind)) ?? "") ?? .classic
        return available(for: kind).contains(style) ? style : .classic
    }
}

/// Bouton qui ouvre une liste de choix (affichage, catégorie…).
struct TVPickButton<Value: Hashable>: View {
    let title: String
    let icon: String
    let listTitle: String
    let options: [TVOption<Value>]
    @Binding var selection: Value
    @State private var showing = false

    var body: some View {
        Button { showing = true } label: {
            Label {
                TVMarqueeText(title, font: .callout.weight(.semibold))
            } icon: {
                Image(systemName: icon)
            }
        }
        .sheet(isPresented: $showing) {
            NavigationStack {
                TVChoiceList(title: listTitle, options: options, selection: $selection)
            }
        }
    }
}

/// « Affichage : Cinéma » : change l'affichage de Direct, Films ou Séries.
struct TVStyleButton: View {
    let kind: MediaKind
    @AppStorage private var raw: String

    init(kind: MediaKind) {
        self.kind = kind
        _raw = AppStorage(wrappedValue: TVStyle.classic.rawValue, TVInterface.key(kind))
    }

    private var current: TVStyle {
        let style = TVStyle(rawValue: raw) ?? .classic
        return TVInterface.available(for: kind).contains(style) ? style : .classic
    }

    var body: some View {
        TVPickButton(title: String(localized: "Affichage : ") + current.label,
                     icon: "rectangle.3.group",
                     listTitle: String(localized: "Affichage"),
                     options: TVInterface.available(for: kind).map { TVOption(value: $0, label: $0.label) },
                     selection: Binding(get: { current }, set: { raw = $0.rawValue }))
    }
}

// MARK: - Données partagées

extension TVScope {
    /// Sans choix, la page de départ du réglage (ou la première catégorie).
    static func start(for kind: MediaKind, categories: [String]) -> TVScope {
        switch StartPage.destination(for: kind, categories: categories) {
        case .favorites: return .favorites
        case .recents: return .recents
        case .category(_, let name): return .category(name)
        default: break
        }
        if let first = categories.first { return .category(first) }
        return .all
    }

    @MainActor
    func items(kind: MediaKind, store: LibraryStore) -> [MediaItem] {
        switch self {
        case .none, .all: return store.items(for: .all(kind))
        case .favorites:
            return store.favoriteIDs.compactMap { store.item(id: $0) }.filter { $0.kind == kind || (kind == .series && $0.kind == .episode) }
        case .recents:
            return store.recentIDs.compactMap { store.item(id: $0) }.filter { $0.kind == kind || (kind == .series && $0.kind == .episode) }
        case .category(let name): return store.items(for: .category(kind, name))
        }
    }
}

/// Vignette d'une chaîne (logo + programme en cours) ou d'une affiche.
struct TVItemTile: View {
    let item: MediaItem
    @Environment(LibraryStore.self) private var store

    var body: some View {
        if item.kind == .live {
            VStack(spacing: 10) {
                ArtworkView(url: item.logoURL, name: item.name)
                    .frame(height: 130)
                Text(item.name).font(.caption).lineLimit(2).multilineTextAlignment(.center)
                if let programme = store.epg.current(for: item.epgID) {
                    Text(programme.title).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .padding(12)
        } else {
            VStack(spacing: 8) {
                ArtworkView(url: item.logoURL, name: item.name, contentMode: .fill)
                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    .overlay(alignment: .topTrailing) { TVWatchedMark(id: item.id) }
                Text(TMDB.cleanTitle(item.name).title).font(.caption).lineLimit(2).multilineTextAlignment(.center)
                    .padding(.horizontal, 6).padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Affichage Cinéma

/// Bandeau « à la une » puis rails horizontaux : reprendre, favoris, récents, catégories.
struct TVCinemaView: View {
    let kind: MediaKind
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(TVUI.self) private var ui

    private var categories: [String] { store.categoriesByKind[kind] ?? [] }

    /// La catégorie de départ passe en premier.
    private var orderedCategories: [String] {
        var list = categories
        if case .category(let name) = TVScope.start(for: kind, categories: categories), let index = list.firstIndex(of: name) {
            list.remove(at: index)
            list.insert(name, at: 0)
        }
        return Array(list.prefix(40))
    }

    private var resumeItems: [MediaItem] {
        watch.entries
            .filter { watch.inResume($0.key) }
            .sorted { $0.value.updatedAt > $1.value.updatedAt }
            .compactMap { store.item(id: $0.key) }
            .filter { $0.kind == kind || (kind == .series && $0.kind == .episode) }
    }

    private var heroItem: MediaItem? {
        if kind == .live {
            let candidates = TVScope.favorites.items(kind: .live, store: store) + TVScope.recents.items(kind: .live, store: store)
            if let live = candidates.first(where: { store.epg.current(for: $0.epgID) != nil }) { return live }
        }
        let start = TVScope.start(for: kind, categories: categories).items(kind: kind, store: store)
        return start.prefix(30).first(where: { $0.logoURL != nil }) ?? start.first
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                HStack {
                    TVStyleButton(kind: kind)
                    Spacer()
                }
                .padding(.horizontal, 60)
                if let hero = heroItem { heroCard(hero) }
                TVRail(title: String(localized: "Reprendre la lecture"), kind: kind, items: { resumeItems })
                TVRail(title: String(localized: "Favoris"), kind: kind, items: { TVScope.favorites.items(kind: kind, store: store) })
                TVRail(title: String(localized: "Récents"), kind: kind, items: { TVScope.recents.items(kind: kind, store: store) })
                ForEach(orderedCategories, id: \.self) { name in
                    TVRail(title: name, kind: kind, items: { TVScope.category(name).items(kind: kind, store: store) })
                }
            }
            .padding(.vertical, 20)
        }
    }

    private func heroCard(_ item: MediaItem) -> some View {
        let list = TVScope.start(for: kind, categories: categories).items(kind: kind, store: store)
        return Button { ui.open(item, list: list, playback: playback) } label: {
            HStack(spacing: 36) {
                ArtworkView(url: item.logoURL, name: item.name, contentMode: item.kind == .live ? .fit : .fill)
                    .frame(width: item.kind == .live ? 280 : 190, height: item.kind == .live ? 170 : 285)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 12) {
                    Text("À LA UNE").font(.caption.weight(.bold)).foregroundStyle(TVBrand.orange)
                    Text(item.kind == .live ? item.name : TMDB.cleanTitle(item.name).title)
                        .font(.largeTitle.bold()).lineLimit(2).multilineTextAlignment(.leading)
                    if item.kind == .live, let programme = store.epg.current(for: item.epgID) {
                        Text(programme.title).font(.title3).lineLimit(1)
                        Text(programme.timeRange()).font(.callout).foregroundStyle(.white.opacity(0.7))
                    } else if !item.group.isEmpty {
                        Text(item.group).font(.callout).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                    }
                    Label(item.kind == .live ? String(localized: "Regarder") : String(localized: "Voir la fiche"),
                          systemImage: item.kind == .live ? "play.fill" : "info.circle")
                        .font(.callout.weight(.semibold))
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [TVBrand.violet.opacity(0.9), TVBrand.magenta.opacity(0.75)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .buttonStyle(TVTileStyle(radius: 28))
        .padding(.horizontal, 60)
        .padding(.vertical, 12)
    }
}

/// Une rangée horizontale d'affiches ou de chaînes.
struct TVRail: View {
    let title: String
    let kind: MediaKind
    let items: () -> [MediaItem]
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(TVUI.self) private var ui

    var body: some View {
        let shown = Array(items().prefix(30))
        if !shown.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.title3.bold()).padding(.horizontal, 60)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 28) {
                        ForEach(shown) { item in
                            Button { ui.open(item, list: shown, playback: playback) } label: { TVItemTile(item: item) }
                                .buttonStyle(.card)
                                .frame(width: kind == .live ? 250 : 200)
                                .contextMenu {
                                    Button(store.isFavorite(item.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris"),
                                           systemImage: store.isFavorite(item.id) ? "star.slash" : "star") { store.toggleFavorite(item.id) }
                                }
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 28)
                }
            }
        }
    }
}

// MARK: - Affichage TV (direct)

/// Lecteur plein écran et zapping : cet écran n'est que le point d'entrée (la dernière chaîne démarre toute seule).
struct TVLiveTVView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(TVUI.self) private var ui
    @AppStorage("tv.autoStart") private var autoStart = true
    @State private var scope: TVScope = .none

    private var categories: [String] { store.categoriesByKind[.live] ?? [] }
    private var effective: TVScope { scope != .none ? scope : TVScope.start(for: .live, categories: categories) }
    private var list: [MediaItem] { effective.items(kind: .live, store: store) }

    private var channel: MediaItem? {
        if let id = UserDefaults.standard.string(forKey: TVUI.lastLiveKey), let item = store.item(id: id) { return item }
        return list.first
    }

    private var scopeOptions: [TVOption<TVScope>] {
        var options: [TVOption<TVScope>] = [TVOption(value: TVScope.all, label: String(localized: "Toutes")),
                                            TVOption(value: TVScope.favorites, label: String(localized: "Favoris")),
                                            TVOption(value: TVScope.recents, label: String(localized: "Récents"))]
        options += categories.map { TVOption(value: TVScope.category($0), label: $0) }
        return options
    }

    private var scopeTitle: String {
        switch effective {
        case .none, .all: return String(localized: "Toutes")
        case .favorites: return String(localized: "Favoris")
        case .recents: return String(localized: "Récents")
        case .category(let name): return name
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                TVPickButton(title: String(localized: "Liste de zapping : ") + scopeTitle, icon: "line.3.horizontal.decrease.circle",
                             listTitle: String(localized: "Catégorie"), options: scopeOptions,
                             selection: Binding(get: { effective }, set: { scope = $0 }))
                TVStyleButton(kind: .live)
                Spacer()
            }
            .padding(.horizontal, 60)
            Spacer(minLength: 0)
            if let channel {
                VStack(spacing: 18) {
                    ArtworkView(url: channel.logoURL, name: channel.name)
                        .frame(width: 280, height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text(channel.name).font(.largeTitle.bold()).lineLimit(1)
                    if let programme = store.epg.current(for: channel.epgID) {
                        Text(programme.title).font(.title3).lineLimit(1)
                        Text(programme.timeRange()).font(.callout).foregroundStyle(.secondary)
                    }
                    Button { start(channel) } label: {
                        Label("Regarder", systemImage: "play.fill")
                            .font(.title3.weight(.semibold))
                            .padding(.horizontal, 50).padding(.vertical, 14)
                            .background(LinearGradient(colors: [TVBrand.magenta, TVBrand.orange], startPoint: .leading, endPoint: .trailing))
                    }
                    .buttonStyle(TVTileStyle(radius: 40))
                    Text("Pendant la lecture, ↑ et ↓ changent de chaîne.").font(.callout).foregroundStyle(.secondary)
                }
            } else {
                TVEmptyView(text: String(localized: "Aucune chaîne dans cette liste."))
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 30)
        .task(id: channel?.id) {
            guard autoStart, ui.tab == 1, !ui.tvAutoStarted, ui.playing == nil, let channel else { return }
            ui.tvAutoStarted = true
            start(channel)
        }
    }

    private func start(_ channel: MediaItem) {
        ui.play(channel, list: list, playback: playback)
    }
}
