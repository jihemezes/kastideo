import SwiftUI
import KastideoCore

/// Couleurs de l'application (reprises de l'icône : violet profond, magenta, orange) — comme sur le Mac.
enum IOSBrand {
    static let night = Color(red: 0.06, green: 0.02, blue: 0.14)
    static let indigo = Color(red: 0.17, green: 0.13, blue: 0.58)
    static let violet = Color(red: 0.34, green: 0.10, blue: 0.55)
    static let magenta = Color(red: 0.80, green: 0.16, blue: 0.52)
    static let orange = Color(red: 1.00, green: 0.60, blue: 0.20)
}

/// Fond coloré en dégradé avec le gros logo flouté et transparent (comme la version de bureau).
struct IOSBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            let side = max(geo.size.height * 0.95, 420)
            ZStack {
                LinearGradient(colors: [IOSBrand.night, IOSBrand.violet.opacity(0.9), IOSBrand.night],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [IOSBrand.magenta.opacity(0.45), .clear],
                               center: .bottomTrailing, startRadius: 20, endRadius: 520)
                RadialGradient(colors: [IOSBrand.orange.opacity(0.18), .clear],
                               center: .topTrailing, startRadius: 10, endRadius: 360)
                Image("KastideoLogo")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: side, height: side)
                    .opacity(0.32)
                    .blur(radius: 6)
                    .rotationEffect(.degrees(-8))
                    .shadow(color: IOSBrand.magenta.opacity(0.6), radius: 70)
                    .position(x: geo.size.width - side * 0.18, y: geo.size.height * 0.55)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .clipped()
        }
        .ignoresSafeArea()
    }
}

/// Grand accès (Direct, Films, Séries, YouTube, Mes vidéos).
struct IOSHomeTile: View {
    let title: LocalizedStringKey
    let icon: String
    let subtitle: String
    let colors: [Color]
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon).font(.system(size: 28, weight: .semibold))
                Spacer(minLength: 0)
                Text(title).font(.system(size: 22, weight: .bold, design: .rounded))
                Text(subtitle.isEmpty ? " " : subtitle)
                    .font(.caption).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .leading)
            .background(LinearGradient(colors: colors.map { $0.opacity(0.85) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// Petit bouton d'accès rapide (Reprendre, Récents, Favoris, Guide TV, Enregistrements).
struct IOSHomeSmallButton: View {
    let title: LocalizedStringKey
    let icon: String
    var badge: Int = 0
    var alert = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3)
                    .foregroundStyle(alert ? Color.red : Color.white)
                Text(title).font(.footnote.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.vertical, 6)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.14), lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                if badge > 0 {
                    Text(badge > 999 ? "999+" : "\(badge)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(IOSBrand.magenta, in: Capsule())
                        .foregroundStyle(.white)
                        .offset(x: -6, y: 6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct IOSHomeView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(WatchProgressStore.self) private var watch
    @Environment(IOSRecorder.self) private var recorder
    @Environment(IOSDownloads.self) private var downloads
    @Environment(IOSUI.self) private var ui
    @State private var query = ""
    @State private var results: [MediaItem] = []

    private var resumeCount: Int {
        store.recentIDs.compactMap { store.item(id: $0) }.filter { $0.kind != .live && watch.inResume($0.id) }.count
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                IOSBackdrop()
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        searchField
                        if query.kastideoSearchKey.isEmpty {
                            if !store.hasSources {
                                welcome
                            } else {
                                if store.isBusy && store.itemsByKind.isEmpty {
                                    HStack(spacing: 10) { ProgressView().tint(.white); Text("Chargement des sources…") }
                                        .font(.footnote).foregroundStyle(.white.opacity(0.8))
                                }
                                tiles(height: min(max(geo.size.height * 0.14, 104), 150))
                                quickButtons
                            }
                            versionLabel
                        } else {
                            searchResults
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .refreshable { store.refreshAll() }
            }
        }
        .environment(\.colorScheme, .dark)
        .task(id: query) {
            let key = query.kastideoSearchKey
            guard !key.isEmpty else { results = []; return }
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            results = search(key)
        }
    }

    // MARK: En-tête

    private var header: some View {
        HStack(spacing: 14) {
            Image("KastideoLogo")
                .resizable()
                .frame(width: 66, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: IOSBrand.magenta.opacity(0.7), radius: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text("Kastideo").font(.system(size: 40, weight: .heavy, design: .rounded))
                Text("Vos chaînes, vos films et vos séries au même endroit")
                    .font(.caption).foregroundStyle(.white.opacity(0.7)).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.top, 6)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.6))
            TextField("Rechercher une chaîne, un film ou une série", text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain).foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(.white.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
    }

    // MARK: Accès

    private func tiles(height: CGFloat) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                IOSHomeTile(title: "Direct", icon: "tv.fill", subtitle: count(.live, one: "chaîne", many: "chaînes"),
                            colors: [IOSBrand.magenta, IOSBrand.orange], height: height) { ui.tab = .live }
                IOSHomeTile(title: "Films", icon: "film.fill", subtitle: count(.movie, one: "film", many: "films"),
                            colors: [IOSBrand.violet, IOSBrand.magenta], height: height) { ui.tab = .movies }
            }
            HStack(spacing: 12) {
                IOSHomeTile(title: "Séries", icon: "rectangle.stack.fill", subtitle: count(.series, one: "série", many: "séries"),
                            colors: [IOSBrand.indigo, IOSBrand.violet], height: height) { ui.tab = .series }
                IOSHomeTile(title: "YouTube", icon: "play.rectangle.fill", subtitle: String(localized: "Recherche et abonnements"),
                            colors: [Color(red: 0.75, green: 0.12, blue: 0.22), IOSBrand.violet], height: height) { ui.tab = .youtube }
            }
            if store.hasLibrary {
                IOSHomeTile(title: "Mes vidéos", icon: "photo.stack.fill", subtitle: libraryCount,
                            colors: [IOSBrand.orange, IOSBrand.violet], height: height * 0.78) { ui.tab = .library }
            }
        }
    }

    private var libraryCount: String {
        let n = store.libraryItems().count
        if n == 0 { return store.isBusy ? String(localized: "Chargement…") : String(localized: "Galerie, dossiers et serveurs") }
        return n == 1 ? String(localized: "1 vidéo") : String(localized: "\(n.formatted()) vidéos")
    }

    private func count(_ kind: MediaKind, one: LocalizedStringResource, many: LocalizedStringResource) -> String {
        let n = store.count(for: kind)
        if n == 0 { return store.isBusy ? String(localized: "Chargement…") : "" }
        return "\(n.formatted()) " + String(localized: n == 1 ? one : many)
    }

    private var quickButtons: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            IOSHomeSmallButton(title: "Reprendre", icon: "play.circle.fill", badge: resumeCount) { ui.tab = .resume }
            IOSHomeSmallButton(title: "Récents", icon: "clock.arrow.circlepath", badge: store.recentIDs.count) { ui.tab = .recents }
            IOSHomeSmallButton(title: "Favoris", icon: "star.fill", badge: store.favoriteIDs.count) { ui.tab = .favorites }
            IOSHomeSmallButton(title: "Guide TV", icon: "calendar") { ui.tab = .guide }
            IOSHomeSmallButton(title: "Enregistrements",
                               icon: recorder.isRecording ? "record.circle.fill" : "record.circle",
                               badge: downloads.jobs.count, alert: recorder.isRecording) { ui.tab = .recordings }
        }
    }

    private var versionLabel: some View {
        Text("Kastideo \(ReleaseNotes.currentVersion)")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.white.opacity(0.35))
            .padding(.top, 8)
    }

    private var welcome: some View {
        VStack(spacing: 14) {
            Text("Bienvenue dans Kastideo").font(.title2.bold())
            Text("Ajoutez votre abonnement IPTV (Xtream Codes ou liste M3U), ou importez la configuration de votre Mac.")
                .multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.8))
            Button { ui.showAddSource = true } label: {
                Label("Ajouter une source", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large).tint(IOSBrand.magenta)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: Recherche

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
            Text("Aucun résultat").foregroundStyle(.white.opacity(0.7)).padding(.top, 30)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(results) { item in
                    Button { ui.open(item, store: store, playback: playback) } label: {
                        HStack(spacing: 12) {
                            ArtworkView(url: item.logoURL, name: item.name)
                                .frame(width: item.kind == .live ? 64 : 44, height: item.kind == .live ? 40 : 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.subheadline.weight(.semibold)).lineLimit(2)
                                Text(kindLabel(item.kind)).font(.caption).foregroundStyle(.white.opacity(0.65))
                            }
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func kindLabel(_ kind: MediaKind) -> String {
        switch kind {
        case .live: return String(localized: "Chaîne")
        case .movie: return String(localized: "Film")
        case .series: return String(localized: "Série")
        case .episode: return String(localized: "Épisode")
        }
    }
}
