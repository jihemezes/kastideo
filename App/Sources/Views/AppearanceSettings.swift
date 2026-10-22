import SwiftUI
import KastideoCore

/// Clés des réglages d'apparence.
enum AppearanceKeys {
    static let accent = "accent"
    static let density = "listDensity"
    static let cardSize = "cardSize"
}

/// Style d'interface : présentation du catalogue.
enum InterfaceStyle: String, CaseIterable, Identifiable {
    case classic
    case cinema
    case tv

    var id: String { rawValue }

    var label: String {
        switch self {
        case .classic: return String(localized: "Classique")
        case .cinema: return String(localized: "Cinéma")
        case .tv: return String(localized: "TV")
        }
    }

    var icon: String {
        switch self {
        case .classic: return "sidebar.left"
        case .cinema: return "rectangle.grid.1x2"
        case .tv: return "tv"
        }
    }

    var summary: String {
        switch self {
        case .classic: return String(localized: "Trois colonnes : sources et catégories, liste, lecteur.")
        case .cinema: return String(localized: "Grande affiche et rangées horizontales, comme Apple TV ou Netflix.")
        case .tv: return String(localized: "Direct uniquement : la chaîne en plein cadre, panneau de chaînes, bandeau d'information, zapping par numéro.")
        }
    }
}

/// Type de contenu pour lequel on choisit une interface.
enum InterfaceScope: String, CaseIterable, Identifiable {
    case live
    case movie
    case series
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .live: return String(localized: "Direct")
        case .movie: return String(localized: "Films")
        case .series: return String(localized: "Séries")
        case .other: return String(localized: "Favoris et récents")
        }
    }

    var storageKey: String { "interface.\(rawValue)" }

    /// Section à laquelle correspond la navigation courante (`nil` : section toujours classique).
    static func scope(for browse: Browse?) -> InterfaceScope? {
        guard let browse else { return .live }
        switch browse {
        case .all(let kind), .category(let kind, _):
            switch kind {
            case .live: return .live
            case .movie: return .movie
            case .series, .episode: return .series
            }
        case .favorites, .recents:
            return .other
        case .home, .recordings, .guide, .themes:
            return nil
        }
    }

    /// Interfaces proposées pour ce type de contenu (l'interface TV ne concerne que le direct).
    var availableStyles: [InterfaceStyle] {
        self == .live ? InterfaceStyle.allCases : [.classic, .cinema]
    }

    /// Interface enregistrée, ramenée à Classique si elle n'est pas proposée pour ce type de contenu.
    func resolve(_ raw: String) -> InterfaceStyle {
        let style = InterfaceStyle(rawValue: raw) ?? .classic
        return availableStyles.contains(style) ? style : .classic
    }

    func style(in defaults: UserDefaults = .standard) -> InterfaceStyle {
        resolve(defaults.string(forKey: storageKey) ?? "")
    }

    func set(_ style: InterfaceStyle, in defaults: UserDefaults = .standard) {
        guard availableStyles.contains(style) else { return }
        defaults.set(style.rawValue, forKey: storageKey)
    }
}

/// Couleur d'accentuation de l'application.
enum AccentChoice: String, CaseIterable, Identifiable {
    case system, blue, purple, pink, red, orange, green, teal

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return String(localized: "Système")
        case .blue: return String(localized: "Bleu")
        case .purple: return String(localized: "Violet")
        case .pink: return String(localized: "Rose")
        case .red: return String(localized: "Rouge")
        case .orange: return String(localized: "Orange")
        case .green: return String(localized: "Vert")
        case .teal: return String(localized: "Turquoise")
        }
    }

    /// `nil` : couleur choisie dans les réglages du système.
    var color: Color? {
        switch self {
        case .system: return nil
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .green: return .green
        case .teal: return .teal
        }
    }
}

/// Densité des listes (interface Classique).
enum ListDensity: String, CaseIterable, Identifiable {
    case compact, standard, spacious

    var id: String { rawValue }

    var label: String {
        switch self {
        case .compact: return String(localized: "Compacte")
        case .standard: return String(localized: "Standard")
        case .spacious: return String(localized: "Aérée")
        }
    }

    var rowPadding: CGFloat {
        switch self {
        case .compact: return 0
        case .standard: return 2
        case .spacious: return 7
        }
    }

    var liveLogo: CGFloat {
        switch self {
        case .compact: return 28
        case .standard: return 36
        case .spacious: return 46
        }
    }

    var posterLogo: CGFloat {
        switch self {
        case .compact: return 34
        case .standard: return 44
        case .spacious: return 58
        }
    }
}

/// Taille des vignettes (interface Cinéma).
enum CardSize: String, CaseIterable, Identifiable {
    case small, medium, large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return String(localized: "Petites")
        case .medium: return String(localized: "Moyennes")
        case .large: return String(localized: "Grandes")
        }
    }

    /// Largeur d'une affiche de film ou de série.
    var posterWidth: CGFloat {
        switch self {
        case .small: return 120
        case .medium: return 150
        case .large: return 190
        }
    }

    /// Largeur d'une vignette de chaîne.
    var tileWidth: CGFloat {
        switch self {
        case .small: return 190
        case .medium: return 240
        case .large: return 300
        }
    }
}

/// Réglages > Apparence.
struct AppearanceSettingsView: View {
    @AppStorage(SettingsKeys.appearance) private var appearance = Appearance.dark.rawValue
    @AppStorage(AppearanceKeys.accent) private var accent = AccentChoice.system.rawValue
    @AppStorage(AppearanceKeys.density) private var density = ListDensity.standard.rawValue
    @AppStorage(AppearanceKeys.cardSize) private var cardSize = CardSize.medium.rawValue

    var body: some View {
        Form {
            Section("Thème") {
                Picker("Apparence", selection: $appearance) {
                    ForEach(Appearance.allCases) { Text($0.label).tag($0.rawValue) }
                }
                LabeledContent("Couleur d'accent") {
                    HStack(spacing: 10) {
                        ForEach(AccentChoice.allCases) { choice in
                            swatch(choice)
                        }
                    }
                }
            }

            Section {
                ForEach(InterfaceScope.allCases) { scope in
                    InterfaceScopePicker(scope: scope)
                }
            } header: {
                Text("Interface par type de contenu")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(InterfaceStyle.allCases) { style in
                        Text("**\(style.label)** — \(style.summary)")
                    }
                    Text("Vous pouvez aussi changer d'interface depuis le bouton de la barre d'outils ou avec ⌥⌘1 (Classique), ⌥⌘2 (Cinéma) et ⌥⌘3 (TV).")
                }
            }

            Section("Affichage") {
                Picker("Densité des listes (Classique)", selection: $density) {
                    ForEach(ListDensity.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Picker("Taille des vignettes (Cinéma)", selection: $cardSize) {
                    ForEach(CardSize.allCases) { Text($0.label).tag($0.rawValue) }
                }
            }

            HeroSettingsSection()
        }
        .formStyle(.grouped)
    }

    private func swatch(_ choice: AccentChoice) -> some View {
        let selected = accent == choice.rawValue
        return Button {
            accent = choice.rawValue
        } label: {
            ZStack {
                if let color = choice.color {
                    Circle().fill(color)
                } else {
                    Circle().fill(AngularGradient(colors: [.blue, .purple, .pink, .red, .orange, .green, .blue],
                                                  center: .center))
                }
            }
            .frame(width: 20, height: 20)
            .overlay(
                Circle()
                    .strokeBorder(Color.primary, lineWidth: selected ? 2 : 0)
                    .padding(-4)
            )
            .padding(4)
        }
        .buttonStyle(.plain)
        .help(choice.label)
    }
}

/// Choix de l'interface pour un type de contenu.
struct InterfaceScopePicker: View {
    let scope: InterfaceScope
    @AppStorage private var raw: String

    init(scope: InterfaceScope) {
        self.scope = scope
        _raw = AppStorage(wrappedValue: InterfaceStyle.classic.rawValue, scope.storageKey)
    }

    var body: some View {
        Picker(scope.label, selection: $raw) {
            ForEach(scope.availableStyles) { style in
                Label(style.label, systemImage: style.icon).tag(style.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }
}
