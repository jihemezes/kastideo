import SwiftUI
import KastideoCore

/// Réglages > Apparence : thème, couleur, affichages par défaut, taille des affiches, densité, contenus adultes.
struct IOSAppearanceSection: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage("ios.appearance") private var appearance = "dark"
    @AppStorage(IOSKeys.accent) private var accent = IOSAccent.orange.rawValue
    @AppStorage(IOSKeys.cardSize) private var cardSize = IOSCardSize.medium.rawValue
    @AppStorage(IOSKeys.density) private var density = IOSDensity.standard.rawValue
    @AppStorage(IOSKeys.liveMode) private var liveMode = IOSLiveMode.list.rawValue
    @AppStorage(IOSKeys.moviesMode) private var moviesMode = IOSCatalogMode.cinema.rawValue
    @AppStorage(IOSKeys.seriesMode) private var seriesMode = IOSCatalogMode.cinema.rawValue
    @AppStorage("adult.show") private var showAdult = false

    var body: some View {
        Section("Apparence") {
            Picker("Thème", selection: $appearance) {
                Text("Sombre").tag("dark")
                Text("Clair").tag("light")
                Text("Comme le système").tag("system")
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Couleur d'accent")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(IOSAccent.allCases) { choice in
                            swatch(choice)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            Picker("Taille des affiches", selection: $cardSize) {
                ForEach(IOSCardSize.allCases) { Text($0.label).tag($0.rawValue) }
            }
            Picker("Densité des listes", selection: $density) {
                ForEach(IOSDensity.allCases) { Text($0.label).tag($0.rawValue) }
            }
            Toggle("Afficher les chaînes pour adultes", isOn: $showAdult)
                .onChange(of: showAdult) { _, _ in store.refreshAdultFilter() }
        }

        Section {
            Picker("Direct", selection: $liveMode) {
                ForEach(IOSLiveMode.allCases) { Label($0.label, systemImage: $0.icon).tag($0.rawValue) }
            }
            Picker("Films", selection: $moviesMode) {
                ForEach(IOSCatalogMode.allCases) { Label($0.label, systemImage: $0.icon).tag($0.rawValue) }
            }
            Picker("Séries", selection: $seriesMode) {
                ForEach(IOSCatalogMode.allCases) { Label($0.label, systemImage: $0.icon).tag($0.rawValue) }
            }
        } header: {
            Text("Affichage par défaut")
        } footer: {
            Text("Vous pouvez aussi changer l'affichage à tout moment avec le bouton en haut à gauche de chaque onglet.")
        }
    }

    private func swatch(_ choice: IOSAccent) -> some View {
        let selected = accent == choice.rawValue
        return Button {
            accent = choice.rawValue
        } label: {
            ZStack {
                Circle()
                    .fill(choice.color ?? Color.blue)
                    .frame(width: 30, height: 30)
                if choice == .system {
                    Image(systemName: "iphone").font(.caption).foregroundStyle(.white)
                }
                if selected {
                    Circle().strokeBorder(Color.primary, lineWidth: 2).frame(width: 38, height: 38)
                }
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(choice.label))
    }
}

/// Réglages > Organisation : catégories, pays, page de départ.
struct IOSOrganisationSection: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage(IOSKeys.startTab) private var startTab = "home"
    @AppStorage("start.live") private var startLive = "all"
    @AppStorage("start.movie") private var startMovie = "all"
    @AppStorage("start.series") private var startSeries = "all"

    var body: some View {
        Section {
            NavigationLink {
                IOSCategoryManagerView()
            } label: {
                Label("Gérer les catégories", systemImage: "list.bullet.indent")
            }
            NavigationLink {
                Form { IOSCountrySection() }
                    .navigationTitle("Pays et langues")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                Label("Pays et langues", systemImage: "globe.europe.africa")
            }
        } header: {
            Text("Organisation")
        } footer: {
            Text("Ordre, masquage et noms des catégories ; pays montrés dans l'affichage Cinéma. Pour réordonner les chaînes d'une catégorie : onglet Direct en liste, choisissez la catégorie puis « Réordonner les chaînes… ».")
        }

        Section {
            Picker("Onglet au lancement", selection: $startTab) {
                Text("Accueil").tag("home")
                Text("Direct").tag("live")
                Text("Films").tag("movies")
                Text("Séries").tag("series")
            }
            startPicker(.live, $startLive)
            startPicker(.movie, $startMovie)
            startPicker(.series, $startSeries)
        } header: {
            Text("Page de départ")
        } footer: {
            Text("Page affichée en ouvrant Direct, Films ou Séries (affichage Liste ou Grille). « Dernière consultée » reprend la catégorie où vous étiez.")
        }
    }

    private func startPicker(_ kind: MediaKind, _ selection: Binding<String>) -> some View {
        let names = store.categoriesByKind[kind] ?? []
        let current = selection.wrappedValue
        let missing: String? = current.hasPrefix("category:") && !names.contains(String(current.dropFirst("category:".count)))
            ? String(current.dropFirst("category:".count)) : nil
        return Picker(kind.title, selection: selection) {
            Text("Toutes").tag("all")
            Text("Favoris").tag("favorites")
            Text("Récents").tag("recents")
            Text("Dernière consultée").tag("last")
            ForEach(names, id: \.self) { name in
                Text(name).tag(StartPage.categoryValue(name))
            }
            if let missing {
                Text(missing).tag(current)
            }
        }
    }
}
