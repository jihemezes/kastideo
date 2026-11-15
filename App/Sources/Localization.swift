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
        case .gallery: return String(localized: "Galerie")
        }
    }
}

/// Langue de l'application. Le changement s'applique au prochain lancement (l'application peut se relancer seule).
/// Langues gérées : français, anglais, espagnol, allemand, italien, portugais du Portugal et du Brésil.
/// Si la langue du système n'est pas gérée, l'application s'affiche en anglais.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, fr, en, es, de, it, ptPT, ptBR

    var id: String { rawValue }

    static let storageKey = "appLanguage"

    /// Noms laissés dans chaque langue, pour être compris quelle que soit la langue actuelle.
    var label: String {
        switch self {
        case .system: return "Système / System"
        case .fr: return "Français"
        case .en: return "English"
        case .es: return "Español"
        case .de: return "Deutsch"
        case .it: return "Italiano"
        case .ptPT: return "Português (Portugal)"
        case .ptBR: return "Português (Brasil)"
        }
    }

    /// Langue choisie (`nil` tant que l'utilisateur n'a pas choisi).
    static var stored: AppLanguage? {
        UserDefaults.standard.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:))
    }

    /// Code de la langue effectivement utilisée par l'application ce lancement-ci (lu une seule fois au démarrage).
    /// Valeurs possibles : fr, en, es, de, it, pt-PT, pt-BR (l'anglais quand la langue du système n'est pas gérée).
    static let effectiveCode: String = Bundle.main.preferredLocalizations.first ?? "en"

    /// Code géré correspondant à un identifiant de langue du système (« pt-BR », « es-419 »…), ou `nil`.
    static func supportedCode(for identifier: String) -> String? {
        let locale = Locale(identifier: identifier)
        guard let language = locale.language.languageCode?.identifier else { return nil }
        switch language {
        case "fr", "en", "es", "de", "it": return language
        case "pt":
            // Le portugais du Brésil seulement pour « pt » ou « pt-BR » ; les autres régions (PT, AO, MZ…) suivent l'usage européen.
            let region = locale.language.region?.identifier
            return (region == nil || region == "BR") ? "pt-BR" : "pt-PT"
        default: return nil
        }
    }

    /// Première langue préférée du système parmi celles gérées (anglais si aucune).
    static var systemCode: String {
        for identifier in Locale.preferredLanguages {
            if let code = supportedCode(for: identifier) { return code }
        }
        return "en"
    }

    /// Code de langue voulu (pour le système : la première langue préférée parmi celles gérées).
    var code: String {
        switch self {
        case .system: return Self.systemCode
        case .fr: return "fr"
        case .en: return "en"
        case .es: return "es"
        case .de: return "de"
        case .it: return "it"
        case .ptPT: return "pt-PT"
        case .ptBR: return "pt-BR"
        }
    }

    /// Enregistre le choix et le transmet au système pour les prochains lancements.
    func apply() {
        let defaults = UserDefaults.standard
        defaults.set(rawValue, forKey: Self.storageKey)
        switch self {
        case .system: defaults.removeObject(forKey: "AppleLanguages")
        default: defaults.set([code], forKey: "AppleLanguages")
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

    /// Langue de l'aide intégrée : fr, en, es, de, it ou pt (pt-PT et pt-BR partagent l'aide portugaise ; repli : anglais).
    static var helpLanguage: String {
        let base = String(effectiveCode.lowercased().prefix(2))
        return ["fr", "es", "de", "it", "pt"].contains(base) ? base : "en"
    }
}
