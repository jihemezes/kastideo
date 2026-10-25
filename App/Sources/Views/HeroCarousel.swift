import SwiftUI
import AppKit
import KastideoCore

/// Réglages du bandeau « à la une » de l'interface Cinéma.
enum HeroKeys {
    static let enabled = "hero.enabled"
    static let height = "hero.height"
    static let categoryMovie = "hero.category.movie"
    static let categorySeries = "hero.category.series"
    static let useCategory = "hero.useCategory"
    static let useTrending = "hero.useTrending"
    static let useRecent = "hero.useRecent"
    static let interval = "hero.interval"

    static func bool(_ key: String) -> Bool { UserDefaults.standard.object(forKey: key) as? Bool ?? true }

    static func categoryKey(for kind: MediaKind) -> String { kind == .series ? categorySeries : categoryMovie }
}

/// Hauteur du bandeau.
enum HeroHeight: String, CaseIterable, Identifiable {
    case compact, normal, large
    var id: String { rawValue }
    var label: String {
        switch self {
        case .compact: return String(localized: "Compact")
        case .normal: return String(localized: "Normal")
        case .large: return String(localized: "Grand")
        }
    }
    var points: CGFloat {
        switch self {
        case .compact: return 280
        case .normal: return 360
        case .large: return 460
        }
    }
}

/// Une diapositive du bandeau.
struct HeroSlide: Identifiable, Equatable {
    let item: MediaItem
    let caption: String
    var backdrop: URL?
    var id: String { item.id }
}

/// Bandeau « à la une » : carrousel plein cadre (films, séries ou programmes en cours du direct).
struct CinemaHeroCarousel: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(MediaInfoStore.self) private var info
    @AppStorage(HeroKeys.height) private var heightRaw = HeroHeight.normal.rawValue
    @AppStorage(HeroKeys.interval) private var interval = 8.0
    @AppStorage(HeroKeys.categoryMovie) private var categoryMovie = ""
    @AppStorage(HeroKeys.categorySeries) private var categorySeries = ""
    @AppStorage(HeroKeys.useCategory) private var useCategory = true
    @AppStorage(HeroKeys.useTrending) private var useTrending = true
    @AppStorage(HeroKeys.useRecent) private var useRecent = true
    @AppStorage(CountryKeys.codes) private var countryCodes = ""
    @AppStorage(CountryKeys.neutral) private var countryNeutral = true
    let kind: MediaKind
    /// Contenu affiché si le carrousel n'a rien à montrer.
    let fallback: MediaItem?
    let fallbackCaption: String

    @State private var slides: [HeroSlide] = []
    @State private var index = 0
    @State private var hovering = false
    @State private var direction: Edge = .trailing

    private var height: CGFloat { (HeroHeight(rawValue: heightRaw) ?? .normal).points }

    private var settingsKey: String {
        "\(kind.rawValue)|\(categoryMovie)|\(categorySeries)|\(useCategory)|\(useTrending)|\(useRecent)|\(info.usesTMDB)|\(store.count(for: kind))|\(countryCodes)|\(countryNeutral)"
    }

    var body: some View {
        // Largeur imposée par la fenêtre : une image de fond très large ne peut plus élargir le bandeau
        // (l'affiche et le texte sortaient du cadre).
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay { GeometryReader { geo in content.frame(width: geo.size.width, height: geo.size.height) } }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
            .onHover { hovering = $0 }
            .task(id: settingsKey) {
                let built = await buildSlides()
                withAnimation(.easeInOut(duration: 0.4)) {
                    slides = built
                    index = 0
                }
            }
            .task(id: "\(index)|\(slides.count)") {
                await prefetch()
            }
            .task(id: "timer|\(slides.count)|\(interval)") {
                guard slides.count > 1 else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(max(interval, 4)))
                    guard !Task.isCancelled else { return }
                    if !hovering { go(1) }
                }
            }
    }

    private var content: some View {
        ZStack {
            if slides.isEmpty {
                if let fallback {
                    CinemaHero(item: fallback, caption: fallbackCaption)
                        .padding(.horizontal, -24)
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.05))
                }
            } else {
                let slide = slides[min(index, slides.count - 1)]
                Group {
                    if slide.item.kind == .live {
                        HeroLiveSlideView(slide: slide)
                    } else {
                        HeroSlideView(slide: slide)
                    }
                }
                .id(slide.id)
                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: direction)).combined(with: .scale(scale: 1.02)),
                                        removal: .opacity))
                controls
            }
        }
    }

    // MARK: Commandes

    private var controls: some View {
        ZStack {
            if slides.count > 1 {
                HStack {
                    arrow("chevron.left") { go(-1) }
                    Spacer()
                    arrow("chevron.right") { go(1) }
                }
                .padding(.horizontal, 10)
                .opacity(hovering ? 1 : 0)
                .animation(.easeOut(duration: 0.15), value: hovering)

                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(slides.indices, id: \.self) { i in
                            Capsule()
                                .fill(Color.white.opacity(i == index ? 0.95 : 0.35))
                                .frame(width: i == index ? 22 : 7, height: 7)
                                .onTapGesture { jump(to: i) }
                        }
                    }
                    .padding(.bottom, 12)
                    .animation(.easeOut(duration: 0.2), value: index)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 24)
            }
        }
    }

    private func arrow(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.black.opacity(0.45), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func go(_ delta: Int) {
        guard slides.count > 1 else { return }
        direction = delta >= 0 ? .trailing : .leading
        withAnimation(.easeInOut(duration: 0.6)) {
            index = (index + delta + slides.count) % slides.count
        }
    }

    private func jump(to i: Int) {
        direction = i >= index ? .trailing : .leading
        withAnimation(.easeInOut(duration: 0.5)) { index = i }
    }

    /// Charge la fiche (image de fond, résumé…) de la diapositive affichée et de la suivante.
    private func prefetch() async {
        guard !slides.isEmpty else { return }
        for offset in 0..<min(2, slides.count) {
            let slide = slides[(index + offset) % slides.count]
            if slide.item.kind != .live { await info.load(slide.item, store: store) }
        }
    }

    // MARK: Composition

    private func buildSlides() async -> [HeroSlide] {
        if kind == .live { return liveSlides() }
        let all = store.items(for: .all(kind))
        guard !all.isEmpty else { return [] }
        let begin = Date()
        defer {
            let elapsed = Date().timeIntervalSince(begin)
            if elapsed > 0.5 { PlaybackLog.shared.note("Bandeau « à la une » préparé en \(String(format: "%.1f", elapsed)) s") }
        }

        var groups: [[HeroSlide]] = []
        // Pays choisis (Réglages > Apparence) : derniers ajouts, tendances et sélection au hasard.
        let countries = CountryFilter(stored: countryCodes, keepNeutral: countryNeutral)

        if useTrending, info.usesTMDB {
            let trends = await info.trending(isSeries: kind == .series)
            if !trends.isEmpty {
                let matched = await info.match(trends, in: all, kind: kind)
                let caption = String(localized: "TENDANCE CETTE SEMAINE")
                groups.append(matched.filter { countries.allows($0.item) }.prefix(6).map { HeroSlide(item: $0.item, caption: caption, backdrop: $0.trend.backdropURL) })
            }
        }

        if useRecent {
            // Calcul hors du fil principal (catalogue de ~100 000 films).
            let newest: [MediaItem] = await Task.detached(priority: .userInitiated) {
                var top: [MediaItem] = []
                var datedCount = 0
                // Pays de chaque catégorie calculé une seule fois (catalogues de ~100 000 films).
                var groupCode: [String: String?] = [:]
                func allowed(_ item: MediaItem) -> Bool {
                    guard countries.isActive else { return true }
                    let code: String?
                    if let cached = groupCode[item.group] {
                        code = cached
                    } else {
                        code = CountryDetector.code(for: item.group)
                        groupCode[item.group] = .some(code)
                    }
                    return countries.allows(code: code ?? CountryDetector.code(for: item.name))
                }
                for item in all {
                    guard let date = item.added else { continue }
                    datedCount += 1
                    guard allowed(item) else { continue }
                    if top.count < 6 || date > (top.last?.added ?? .distantPast) {
                        top.append(item)
                        top.sort { ($0.added ?? .distantPast) > ($1.added ?? .distantPast) }
                        if top.count > 6 { top.removeLast() }
                    }
                }
                // Sans date d'ajout : les derniers éléments de la liste du fournisseur sont en général les plus récents.
                return datedCount > all.count / 4 ? top : Array(all.suffix(400).reversed().filter { countries.allows($0) }.prefix(6))
            }.value
            let caption = String(localized: "AJOUTÉ RÉCEMMENT")
            groups.append(newest.map { HeroSlide(item: $0, caption: caption) })
        }

        if useCategory {
            let chosen = kind == .series ? categorySeries : categoryMovie
            let pool: [MediaItem]
            let caption: String
            if !chosen.isEmpty, !store.items(for: .category(kind, chosen)).isEmpty {
                pool = store.items(for: .category(kind, chosen))
                caption = chosen.uppercased()
            } else {
                pool = all
                caption = String(localized: "À DÉCOUVRIR")
            }
            // Tirage au hasard de quelques affiches (sans parcourir tout le catalogue).
            var picked: [MediaItem] = []
            var ids = Set<String>()
            let filtered = pool.count == all.count && countries.isActive
            for _ in 0..<(filtered ? 300 : 60) where picked.count < 6 {
                guard let item = pool.randomElement() else { break }
                if filtered && !countries.allows(item) { continue }
                if item.logoURL != nil, ids.insert(item.id).inserted { picked.append(item) }
            }
            groups.append(picked.map { HeroSlide(item: $0, caption: caption) })
        }

        // Mélange : une diapositive de chaque source à tour de rôle.
        var result: [HeroSlide] = []
        var seen = Set<String>()
        let longest = groups.map(\.count).max() ?? 0
        for i in 0..<longest {
            for group in groups where i < group.count {
                if seen.insert(group[i].id).inserted { result.append(group[i]) }
            }
        }
        return Array(result.prefix(15))
    }

    /// Direct : chaînes favorites puis récentes, avec leur programme en cours.
    private func liveSlides() -> [HeroSlide] {
        var ids = store.favoriteIDs + store.recentIDs
        var seen = Set<String>()
        ids = ids.filter { seen.insert($0).inserted }
        let caption = String(localized: "EN CE MOMENT")
        return ids.compactMap { store.item(id: $0) }
            .filter { $0.kind == .live && store.epg.current(for: $0.epgID) != nil }
            .prefix(10)
            .map { HeroSlide(item: $0, caption: caption) }
    }
}

/// Diapositive film / série.
private struct HeroSlideView: View {
    @Environment(NavigationModel.self) private var navigation
    @Environment(MediaInfoStore.self) private var info
    @Environment(WatchProgressStore.self) private var watch
    let slide: HeroSlide

    private var item: MediaItem { slide.item }
    private var details: MediaDetails? { info.details(for: item) }
    private var backdrop: URL? { details?.backdropURL ?? slide.backdrop }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // L'image remplit le cadre sans l'agrandir (sinon le texte et les boutons sortent du bandeau).
            Color.clear
                .overlay { background }
                .clipped()
            LinearGradient(colors: [.black.opacity(0.92), .black.opacity(0.55), .clear],
                           startPoint: .leading, endPoint: .trailing)
            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
            HStack(alignment: .bottom, spacing: 24) {
                PosterView(url: details?.posterURL ?? item.logoURL, name: item.name)
                    .frame(width: 150, height: 225)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.6), radius: 16, y: 6)
                VStack(alignment: .leading, spacing: 8) {
                    Text(slide.caption)
                        .font(.caption.weight(.heavy))
                        .tracking(1.6)
                        .foregroundStyle(KastideoPalette.orange)
                    Text(title)
                        .font(.system(size: 34, weight: .bold))
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.5), radius: 6)
                    meta
                    if let plot = details?.plot {
                        Text(plot)
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(3)
                            .frame(maxWidth: 560, alignment: .leading)
                    }
                    buttons.padding(.top, 4)
                }
                Spacer(minLength: 60)
            }
            .foregroundStyle(.white)
            .padding(28)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var background: some View {
        if let backdrop {
            // Cadrage sur le 2e quart de l'image (en partant du haut) : visages et titres y sont le plus souvent.
            FocusedRemoteImage(url: backdrop, focus: 0.375) { posterBackground }
        } else {
            posterBackground
        }
    }

    /// Sans image de fond : dégradé aux couleurs de l'application et affiche agrandie, floutée sur la droite.
    private var posterBackground: some View {
        ZStack(alignment: .trailing) {
            LinearGradient(colors: [KastideoPalette.night, KastideoPalette.violet, KastideoPalette.magenta.opacity(0.7)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let url = details?.posterURL ?? item.logoURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                            .frame(width: 520)
                            .blur(radius: 18)
                            .opacity(0.55)
                            .mask(LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing))
                    }
                }
            }
        }
    }

    private var title: String {
        if let title = details?.title, details?.sources.contains("TMDB") == true { return title }
        return TMDB.cleanTitle(item.name).title
    }

    @ViewBuilder
    private var meta: some View {
        let parts: [String] = {
            var p: [String] = []
            if let year = details?.year { p.append(String(year)) }
            if let runtime = details?.runtime, item.kind == .movie {
                p.append(runtime >= 60 ? String(format: "%d h %02d", runtime / 60, runtime % 60) : "\(runtime) min")
            }
            if let seasons = details?.seasonCount, seasons > 0 {
                p.append(seasons == 1 ? String(localized: "1 saison") : String(localized: "\(seasons) saisons"))
            }
            if let genres = details?.genres, !genres.isEmpty { p.append(genres.prefix(2).joined(separator: ", ")) }
            return p
        }()
        HStack(spacing: 10) {
            if let rating = details?.rating {
                Label(rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.yellow)
            }
            if !parts.isEmpty {
                Text(parts.joined(separator: " · "))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .font(.callout.weight(.medium))
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button {
                navigation.selectedItemID = item.id
            } label: {
                Label(playTitle, systemImage: item.needsEpisodes ? "list.bullet" : "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Button {
                navigation.infoItemID = item.id
            } label: {
                Label("Plus d'infos", systemImage: "info.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            if let trailer = details?.trailerURL {
                Button {
                    NSWorkspace.shared.open(trailer)
                } label: {
                    Label("Bande-annonce", systemImage: "film.stack")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    private var playTitle: String {
        if item.needsEpisodes { return String(localized: "Voir les épisodes") }
        if watch.fraction(for: item.id) != nil { return String(localized: "Reprendre") }
        return String(localized: "Lire")
    }
}

/// Diapositive du direct : programme en cours d'une chaîne favorite ou récente.
private struct HeroLiveSlideView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    let slide: HeroSlide

    var body: some View {
        let item = slide.item
        let programme = store.epg.current(for: item.epgID)
        let next = store.epg.upcoming(for: item.epgID, limit: 1).first
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [KastideoPalette.night, KastideoPalette.indigo, KastideoPalette.magenta.opacity(0.75)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let url = item.logoURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFit()
                            .frame(width: 340, height: 220)
                            .opacity(0.22)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 50)
            }
            HStack(alignment: .bottom, spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.1))
                    LogoView(url: item.logoURL, name: item.name, size: 110)
                }
                .frame(width: 170, height: 130)
                VStack(alignment: .leading, spacing: 8) {
                    Text(slide.caption + " · " + TMDB.cleanTitle(item.name).title.uppercased())
                        .font(.caption.weight(.heavy))
                        .tracking(1.4)
                        .foregroundStyle(KastideoPalette.orange)
                    Text(programme?.title ?? item.name)
                        .font(.system(size: 32, weight: .bold))
                        .lineLimit(2)
                    if let programme {
                        HStack(spacing: 10) {
                            Text("\(programme.start.formatted(date: .omitted, time: .shortened)) – \(programme.stop.formatted(date: .omitted, time: .shortened))")
                            ProgressView(value: programme.progress())
                                .progressViewStyle(.linear)
                                .tint(KastideoPalette.orange)
                                .frame(width: 180)
                        }
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                        if let desc = programme.desc {
                            Text(desc)
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(2)
                                .frame(maxWidth: 560, alignment: .leading)
                        }
                    }
                    if let next {
                        Text("Ensuite à \(next.start.formatted(date: .omitted, time: .shortened)) : \(next.title)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Button {
                        navigation.selectedItemID = item.id
                    } label: {
                        Label("Regarder", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 4)
                }
                Spacer(minLength: 60)
            }
            .foregroundStyle(.white)
            .padding(28)
            .padding(.bottom, 8)
        }
    }
}

/// Réglages du bandeau (onglet Apparence).
struct HeroSettingsSection: View {
    @Environment(LibraryStore.self) private var store
    @Environment(MediaInfoStore.self) private var info
    @AppStorage(HeroKeys.enabled) private var enabled = true
    @AppStorage(HeroKeys.height) private var heightRaw = HeroHeight.normal.rawValue
    @AppStorage(HeroKeys.interval) private var interval = 8.0
    @AppStorage(HeroKeys.categoryMovie) private var categoryMovie = ""
    @AppStorage(HeroKeys.categorySeries) private var categorySeries = ""
    @AppStorage(HeroKeys.useCategory) private var useCategory = true
    @AppStorage(HeroKeys.useTrending) private var useTrending = true
    @AppStorage(HeroKeys.useRecent) private var useRecent = true

    var body: some View {
        Section {
            Toggle("Afficher le bandeau « à la une »", isOn: $enabled)
            if enabled {
                Picker("Hauteur", selection: $heightRaw) {
                    ForEach(HeroHeight.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Picker("Défilement", selection: $interval) {
                    Text("Toutes les 6 s").tag(6.0)
                    Text("Toutes les 8 s").tag(8.0)
                    Text("Toutes les 12 s").tag(12.0)
                    Text("Toutes les 20 s").tag(20.0)
                }
                Toggle("Tendances de la semaine (TMDB) disponibles dans votre catalogue", isOn: $useTrending)
                    .disabled(!info.usesTMDB)
                Toggle("Derniers ajouts du fournisseur", isOn: $useRecent)
                Toggle("Sélection d'une catégorie", isOn: $useCategory)
                if useCategory {
                    categoryPicker(String(localized: "Catégorie des films"), kind: .movie, selection: $categoryMovie)
                    categoryPicker(String(localized: "Catégorie des séries"), kind: .series, selection: $categorySeries)
                }
            }
        } header: {
            Text("Bandeau « à la une » (Cinéma)")
        } footer: {
            Text("Le bandeau fait défiler les films ou séries choisis, avec image de fond, résumé, note et bande-annonce ; il s'arrête quand la souris le survole. En Direct, il montre le programme en cours de vos chaînes favorites et récentes. Les tendances nécessitent une clé TMDB (Réglages > Général).")
        }
    }

    private func categoryPicker(_ title: String, kind: MediaKind, selection: Binding<String>) -> some View {
        Picker(title, selection: selection) {
            Text("Tout le catalogue (au hasard)").tag("")
            ForEach(store.categoriesByKind[kind] ?? [], id: \.self) { Text($0).tag($0) }
        }
    }
}


/// Image distante qui remplit son cadre en gardant visible une hauteur choisie de l'image
/// (`focus` : 0 = haut, 0,5 = milieu, 1 = bas).
struct FocusedRemoteImage<Placeholder: View>: View {
    let url: URL
    var focus: CGFloat = 0.375
    @ViewBuilder var placeholder: () -> Placeholder
    @State private var image: NSImage?

    var body: some View {
        GeometryReader { geo in
            if let image, image.size.width > 0, image.size.height > 0 {
                let frame = geo.size
                let scale = max(frame.width / image.size.width, frame.height / image.size.height)
                let width = image.size.width * scale
                let height = image.size.height * scale
                let y = min(0, max(frame.height - height, frame.height / 2 - height * focus))
                Image(nsImage: image)
                    .resizable()
                    .frame(width: width, height: height)
                    .offset(x: (frame.width - width) / 2, y: y)
                    .transition(.opacity)
            } else {
                placeholder()
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .clipped()
        .task(id: url) {
            image = RemoteImageCache.shared.object(forKey: url as NSURL)
            guard image == nil else { return }
            guard let (data, _) = try? await URLSession.shared.data(from: url), let loaded = NSImage(data: data) else { return }
            RemoteImageCache.shared.setObject(loaded, forKey: url as NSURL)
            withAnimation(.easeIn(duration: 0.4)) { image = loaded }
        }
    }
}

/// Cache mémoire des grandes images (bandeau, accueil).
enum RemoteImageCache {
    static let shared: NSCache<NSURL, NSImage> = {
        let cache = NSCache<NSURL, NSImage>()
        cache.countLimit = 60
        return cache
    }()
}
