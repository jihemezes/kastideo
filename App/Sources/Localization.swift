import SwiftUI
import AppKit
import KastideoCore

/// Libellés du cœur de l'application, traduits.
extension MediaKind {
    var title: String {
        switch self {
        case .live: return String(localized: "Direct")
        case .movie: return String(localized: "Films")
        case .series: return String(localized: "Séries")
        case .episode: return String(localized: "Épisodes")
        }
    }
}

extension SourceKind {
    var title: String {
        switch self {
        case .m3uURL: return String(localized: "Playlist M3U (URL)")
        case .m3uFile: return String(localized: "Playlist M3U (fichier)")
        case .xtream: return String(localized: "Xtream Codes")
        case .folders: return String(localized: "Dossiers")
        case .mediaServer(let type, _, _): return type.label
        }
    }
}

/// Langue de l'application. Le changement s'applique au prochain lancement (l'application peut se relancer seule).
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, fr, en

    var id: String { rawValue }

    static let storageKey = "appLanguage"

    /// Noms laissés dans chaque langue, pour être compris quelle que soit la langue actuelle.
    var label: String {
        switch self {
        case .system: return "Système / System"
        case .fr: return "Français"
        case .en: return "English"
        }
    }

    /// Langue choisie (`nil` tant que l'utilisateur n'a pas choisi).
    static var stored: AppLanguage? {
        UserDefaults.standard.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:))
    }

    /// Code de la langue effectivement utilisée par l'application ce lancement-ci (lu une seule fois au démarrage).
    static let effectiveCode: String = Bundle.main.preferredLocalizations.first ?? "fr"

    /// Code de langue voulu (pour le système : la première langue préférée parmi celles gérées).
    var code: String {
        switch self {
        case .fr: return "fr"
        case .en: return "en"
        case .system:
            for language in Locale.preferredLanguages {
                if language.hasPrefix("fr") { return "fr" }
                if language.hasPrefix("en") { return "en" }
            }
            return "fr"
        }
    }

    /// Enregistre le choix et le transmet au système pour les prochains lancements.
    func apply() {
        let defaults = UserDefaults.standard
        defaults.set(rawValue, forKey: Self.storageKey)
        switch self {
        case .system: defaults.removeObject(forKey: "AppleLanguages")
        case .fr: defaults.set(["fr"], forKey: "AppleLanguages")
        case .en: defaults.set(["en"], forKey: "AppleLanguages")
        }
    }

    /// Vrai si la langue voulue diffère de celle déjà affichée (une relance est alors nécessaire).
    var needsRelaunch: Bool { code != Self.effectiveCode }

    /// Relance l'application pour appliquer la langue.
    @MainActor
    static func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}

/// Premier lancement : choix de la langue.
struct LanguagePickerSheet: View {
    @Binding var chosen: String
    @State private var selection: AppLanguage

    init(chosen: Binding<String>) {
        _chosen = chosen
        let initial: AppLanguage = AppLanguage.system.code == "fr" ? .fr : .en
        _selection = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
            Text("Choisissez votre langue")
                .font(.title2.weight(.semibold))
            Text("Choose your language")
                .font(.title3)
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                languageButton(.fr, flag: "🇫🇷")
                languageButton(.en, flag: "🇬🇧")
            }
            Button {
                selection.apply()
                chosen = selection.rawValue
                if selection.needsRelaunch { AppLanguage.relaunch() }
            } label: {
                Text(selection == .fr ? "Continuer" : "Continue")
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            Text("Vous pourrez la changer dans Réglages > Général. / You can change it later in Settings > General.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(width: 440)
        .interactiveDismissDisabled()
    }

    private func languageButton(_ language: AppLanguage, flag: String) -> some View {
        let selected = selection == language
        return Button {
            selection = language
        } label: {
            VStack(spacing: 6) {
                Text(flag).font(.system(size: 38))
                Text(language.label).font(.headline)
            }
            .frame(width: 150, height: 96)
            .background(selected ? Color.accentColor.opacity(0.22) : Color.gray.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(selected ? Color.accentColor : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}
