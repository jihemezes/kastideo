import SwiftUI
import AppKit
import KastideoCore

/// Couleurs de l'application (reprises de l'icône : violet profond, magenta, orange).
enum KastideoPalette {
    static let night = Color(red: 0.06, green: 0.02, blue: 0.14)
    static let indigo = Color(red: 0.17, green: 0.13, blue: 0.58)
    static let violet = Color(red: 0.34, green: 0.10, blue: 0.55)
    static let magenta = Color(red: 0.80, green: 0.16, blue: 0.52)
    static let orange = Color(red: 1.00, green: 0.60, blue: 0.20)
}

/// Bouton « Accueil » de la barre d'outils.
struct HomeButton: View {
    @Environment(NavigationModel.self) private var navigation

    var body: some View {
        Button {
            navigation.go(.home)
        } label: {
            Label("Accueil", systemImage: "house")
        }
        .help("Retourner à l'accueil (⌘0)")
    }
}

/// Écran d'accueil : trois grands accès (Direct, Films, Séries), accès rapides, recherche et reprise.
struct HomeView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    @Environment(WatchProgressStore.self) private var watch
    @State private var query = ""
    @State private var results: [MediaItem] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                logoWatermark(in: geo.size)
                versionLabel
                ScrollView {
                    VStack(spacing: 26) {
                        header
                        searchField
                        if query.kastideoSearchKey.isEmpty {
                            nowPlaying
                            Spacer(minLength: 0)
                            bigTiles(height: tileHeight(for: geo.size))
                            quickButtons
                            themeShortcuts
                            resumeRail
                            Spacer(minLength: 0)
                        } else {
                            searchResults
                        }
                    }
                    .frame(maxWidth: 1180)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity)
                    // Toute la hauteur de la fenêtre est utilisée : le contenu se répartit au lieu de laisser un grand vide.
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .navigationTitle("Kastideo")
        .toolbarBackground(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if store.isBusy {
                    ProgressView().controlSize(.small)
                        .help("Chargement des sources ou du guide TV…")
                }
                DownloadIndicator()
                SettingsLink {
                    Label("Sources", systemImage: "antenna.radiowaves.left.and.right")
                }
                .help("Gérer les sources et les réglages (⌘,)")
            }
        }
        .task(id: query) {
            let key = query.kastideoSearchKey
            guard !key.isEmpty else {
                results = []
                return
            }
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            results = search(key)
        }
    }

    // MARK: Fond et en-tête

    private var background: some View {
        ZStack {
            LinearGradient(colors: [KastideoPalette.night, KastideoPalette.violet.opacity(0.9), KastideoPalette.night],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [KastideoPalette.magenta.opacity(0.45), .clear],
                           center: .bottomTrailing, startRadius: 20, endRadius: 620)
            RadialGradient(colors: [KastideoPalette.orange.opacity(0.18), .clear],
                           center: .topTrailing, startRadius: 10, endRadius: 420)
        }
        .ignoresSafeArea()
    }

    /// Numéro de version, discret, en bas à droite (clic : nouveautés de la version).
    private var versionLabel: some View {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String
        return VStack {
            Spacer()
            HStack(spacing: 10) {
                Spacer()
                SupportButton(onDark: true)
                Button {
                    navigation.showWhatsNew = true
                } label: {
                    Text("Kastideo \(version)" + (build.map { " (\($0))" } ?? ""))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .help("Nouveautés de cette version")
                .padding(10)
            }
        }
        .zIndex(1)
    }

    /// Grands pavés : plus hauts quand la fenêtre est haute.
    private func tileHeight(for size: CGSize) -> CGFloat {
        min(max(size.height * 0.30, 210), 380)
    }

    /// Logo de l'application en très grand, derrière le contenu.
    private func logoWatermark(in size: CGSize) -> some View {
        let side = min(max(size.height * 0.95, 520), 1100)
        return Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: side, height: side)
            .opacity(0.38)
            .blur(radius: 1.5)
            .rotationEffect(.degrees(-8))
            .shadow(color: KastideoPalette.magenta.opacity(0.6), radius: 80)
            .position(x: size.width - side * 0.28, y: size.height * 0.52)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 92, height: 92)
                .shadow(color: KastideoPalette.magenta.opacity(0.7), radius: 18)
                .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Kastideo")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                Text("Vos chaînes, vos films et vos séries au même endroit")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
        }
        .foregroundStyle(.white)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.6))
            TextField("Rechercher une chaîne, un film ou une série", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .foregroundStyle(.white)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
    }

    // MARK: Lecture en cours

    @ViewBuilder
    private var nowPlaying: some View {
        if let current = playback.current {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(KastideoPalette.orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text("En cours de lecture")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(current.name)
                        .font(.headline)
                        .lineLimit(1)
                }
                Spacer()
                Button("Retourner à la lecture") { navigation.open(current, inLibrary: store.isLibraryItem(current)) }
                    .buttonStyle(.borderedProminent)
                    .tint(KastideoPalette.magenta)
                Button("Arrêter") { recordings.requestStop() }
                    .buttonStyle(.bordered)
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: Les trois grands accès

    private func bigTiles(height: CGFloat) -> some View {
        HStack(spacing: 18) {
            HomeBigTile(title: "Direct", icon: "dot.radiowaves.left.and.right",
                        subtitle: count(.live, one: "chaîne", many: "chaînes"),
                        colors: [KastideoPalette.magenta, KastideoPalette.orange], height: height) {
                navigation.go(.all(.live))
            }
            HomeBigTile(title: "Films", icon: "film",
                        subtitle: count(.movie, one: "film", many: "films"),
                        colors: [KastideoPalette.violet, KastideoPalette.magenta], height: height) {
                navigation.go(.all(.movie))
            }
            HomeBigTile(title: "Séries", icon: "rectangle.stack",
                        subtitle: count(.series, one: "série", many: "séries"),
                        colors: [KastideoPalette.indigo, KastideoPalette.violet], height: height) {
                navigation.go(.all(.series))
            }
            // Vidéothèque : seulement avec des dossiers ou un serveur Jellyfin, Emby, Plex.
            if store.hasLibrary {
                HomeBigTile(title: "Mes vidéos", icon: "photo.stack",
                            subtitle: libraryCount,
                            colors: [KastideoPalette.orange, KastideoPalette.violet], height: height) {
                    navigation.showLibrary(.home)
                }
            }
        }
    }

    private var libraryCount: String {
        let n = store.libraryItems().count
        if n == 0 { return store.isBusy ? String(localized: "Chargement…") : String(localized: "Dossiers et serveurs") }
        return n == 1 ? String(localized: "1 vidéo") : String(localized: "\(n.formatted()) vidéos")
    }

    private func count(_ kind: MediaKind, one: LocalizedStringResource, many: LocalizedStringResource) -> String {
        let n = store.count(for: kind)
        if n == 0 { return store.isBusy ? String(localized: "Chargement…") : "" }
        return "\(n.formatted()) " + String(localized: n == 1 ? one : many)
    }

    // MARK: Accès rapides

    private var quickButtons: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 14)], spacing: 14) {
            HomeSmallButton(title: "Favoris", icon: "star.fill", badge: store.favoriteIDs.count) {
                navigation.go(.favorites)
            }
            HomeSmallButton(title: "Récents", icon: "clock.arrow.circlepath", badge: store.recentIDs.count) {
                navigation.go(.recents)
            }
            HomeSmallButton(title: "Guide TV", icon: "calendar", badge: 0) {
                navigation.go(.guide)
            }
            HomeSmallButton(title: "YouTube", icon: "play.rectangle.fill", badge: 0) {
                navigation.go(.youtube)
            }
            HomeSmallButton(title: "Enregistrements",
                            icon: recordings.activeLive != nil ? "record.circle.fill" : "record.circle",
                            badge: recordings.activityCount) {
                navigation.go(.recordings)
            }
        }
    }

    // MARK: À la télé maintenant

    /// Accès directs à la vue Thèmes : ce qui passe maintenant par thème, et ce soir.
    @ViewBuilder
    private var themeShortcuts: some View {
        let now = Date()
        let counts: [(ContentTheme, Int)] = [ContentTheme.sport, .movies, .series, .news, .documentary, .kids].map { theme in
            (theme, store.liveGroups.filter { group in
                guard let programme = store.epg.current(for: group.epgID, at: now) else { return false }
                return (programme.theme ?? group.theme) == theme
            }.count)
        }.filter { $0.1 > 0 }
        if !counts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("À la télé maintenant")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(counts, id: \.0) { entry in
                            HomeThemeChip(icon: entry.0.icon, title: entry.0.label, detail: "\(entry.1)") {
                                navigation.showThemes(entry.0, mode: .now)
                            }
                        }
                        HomeThemeChip(icon: "moon.stars", title: String(localized: "Ce soir"), detail: "20 h – 23 h") {
                            navigation.showThemes(nil, mode: .tonight)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Reprendre la lecture

    @ViewBuilder
    private var resumeRail: some View {
        let started = store.recentIDs.compactMap { store.item(id: $0) }
            .filter { $0.kind != .live && watch.fraction(for: $0.id) != nil }
            .prefix(14)
        if !started.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Reprendre la lecture")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(Array(started)) { item in
                            HomeResumeCard(item: item, fraction: watch.fraction(for: item.id) ?? 0) {
                                navigation.open(item, inLibrary: store.isLibraryItem(item))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Recherche globale

    private func search(_ key: String) -> [MediaItem] {
        var found: [MediaItem] = []
        for kind in [MediaKind.live, .movie, .series] {
            var perKind = 0
            for item in store.items(for: .all(kind)) where item.searchKey.contains(key) {
                found.append(item)
                perKind += 1
                if perKind >= 25 { break }
            }
        }
        // Vidéothèque (dossiers, serveurs).
        var inLibrary = 0
        for item in store.libraryItems() where item.searchKey.contains(key) {
            found.append(item)
            inLibrary += 1
            if inLibrary >= 25 { break }
        }
        return found
    }

    @ViewBuilder
    private var searchResults: some View {
        if results.isEmpty {
            Text("Aucun résultat")
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 30)
        } else {
            VStack(alignment: .leading, spacing: 18) {
                let library = results.filter { store.isLibraryItem($0) }
                if !library.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mes vidéos")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.75))
                        ForEach(library) { item in
                            HomeResultRow(item: item) {
                                if item.kind == .movie || item.kind == .series {
                                    navigation.showLibrary(.home)
                                    navigation.infoItemID = item.id
                                } else {
                                    navigation.open(item, inLibrary: true)
                                }
                            }
                        }
                    }
                }
                ForEach([MediaKind.live, .movie, .series], id: \.self) { kind in
                    let group = results.filter { $0.kind == kind && !store.isLibraryItem($0) }
                    if !group.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(kind.title)
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.75))
                            ForEach(group) { item in
                                HomeResultRow(item: item) { navigation.open(item) }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Grand pavé d'accès à une section.
struct HomeBigTile: View {
    let title: LocalizedStringKey
    let icon: String
    let subtitle: String
    let colors: [Color]
    var height: CGFloat = 210
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: colors.map { $0.opacity(0.88) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: icon)
                    .font(.system(size: 120, weight: .regular))
                    .foregroundStyle(.white.opacity(0.18))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 14)
                    .padding(.trailing, 10)
                    .clipped()
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .semibold))
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(minHeight: 18, alignment: .leading)
                }
                .foregroundStyle(.white)
                .padding(22)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(hovering ? 0.7 : 0.15), lineWidth: hovering ? 2.5 : 1))
            .shadow(color: .black.opacity(hovering ? 0.5 : 0.3), radius: hovering ? 18 : 10, y: 6)
            .scaleEffect(hovering ? 1.025 : 1)
            .animation(.easeOut(duration: 0.14), value: hovering)
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// Petit bouton d'accès rapide.
struct HomeSmallButton: View {
    let title: LocalizedStringKey
    let icon: String
    let badge: Int
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(KastideoPalette.orange)
                    .frame(width: 26)
                Text(title)
                    .font(.headline)
                Spacer(minLength: 4)
                if badge > 0 {
                    Text(badge.formatted())
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.18), in: Capsule())
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white.opacity(hovering ? 0.2 : 0.11),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(hovering ? 0.4 : 0.12), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// Affiche d'un contenu entamé, avec sa barre de progression.
struct HomeResumeCard: View {
    let item: MediaItem
    let fraction: Double
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                PosterView(url: item.logoURL, name: item.name)
                    .frame(width: 124, height: 186)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(alignment: .bottom) {
                        ProgressView(value: fraction)
                            .progressViewStyle(.linear)
                            .tint(KastideoPalette.orange)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                            .shadow(color: .black.opacity(0.6), radius: 2)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.white.opacity(hovering ? 0.7 : 0.12), lineWidth: hovering ? 2 : 1))
                Text(item.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 124, alignment: .leading)
            }
            .scaleEffect(hovering ? 1.03 : 1)
            .animation(.easeOut(duration: 0.12), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(item.name)
    }
}

/// Ligne de résultat de la recherche globale.
struct HomeResultRow: View {
    let item: MediaItem
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                LogoView(url: item.logoURL, name: item.name, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.body)
                        .lineLimit(1)
                    Text(item.group)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(hovering ? 0.16 : 0.07),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}


/// Pastille d'accès à un thème sur l'accueil.
struct HomeThemeChip: View {
    let icon: String
    let title: String
    let detail: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(KastideoPalette.orange)
                Text(title).font(.callout.weight(.semibold))
                Text(detail).font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.6))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.white.opacity(hovering ? 0.2 : 0.1), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(hovering ? 0.4 : 0.12)))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
