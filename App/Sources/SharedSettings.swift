import Foundation
import KastideoCore
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// Réglages partagés entre l'app Mac et l'app iPhone/iPad (déplacés depuis ThemesViews.swift et AppearanceSettings.swift).

/// Mode de la vue Thèmes.
enum ThemeMode: String, CaseIterable, Identifiable {
    case now, tonight, channels
    var id: String { rawValue }
    var label: String {
        switch self {
        case .now: return String(localized: "En ce moment")
        case .tonight: return String(localized: "Ce soir")
        case .channels: return String(localized: "Chaînes")
        }
    }
}

/// Qualité des chaînes proposées quand une chaîne existe en plusieurs versions.
enum QualityPreference: String, CaseIterable, Identifiable {
    case auto, uhd, fhd, hd, sd
    var id: String { rawValue }
    static let key = "live.quality"
    static let autoTierKey = "live.autoTier"

    var label: String {
        switch self {
        case .auto: return String(localized: "Automatique (selon la connexion)")
        case .uhd: return "4K"
        case .fhd: return "Full HD"
        case .hd: return "HD"
        case .sd: return "SD"
        }
    }

    static var current: QualityPreference {
        QualityPreference(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .auto
    }

    /// Qualité visée : choisie, ou ajustée automatiquement d'après la réception mesurée pendant les lectures.
    static var target: ChannelQuality {
        switch current {
        case .uhd: return .uhd
        case .fhd: return .fhd
        case .hd: return .hd
        case .sd: return .sd
        case .auto:
            let raw = UserDefaults.standard.object(forKey: autoTierKey) as? Int ?? ChannelQuality.fhd.rawValue
            return ChannelQuality(rawValue: raw) ?? .fhd
        }
    }
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

/// Clés du choix des pays (rangées Cinéma et bandeau), communes avec la version Windows / Linux.
enum CountryKeys {
    static let codes = "catalog.countries"
    static let neutral = "catalog.countries.neutral"

    static var filter: CountryFilter {
        CountryFilter(stored: UserDefaults.standard.string(forKey: codes) ?? "",
                      keepNeutral: UserDefaults.standard.object(forKey: neutral) as? Bool ?? true)
    }

    static func name(_ code: String) -> String {
        switch code {
        case "FR": return String(localized: "France")
        case "PT": return String(localized: "Portugal")
        case "BR": return String(localized: "Brésil")
        case "IT": return String(localized: "Italie")
        case "ES": return String(localized: "Espagne")
        case "EN": return String(localized: "Anglais")
        case "UK": return String(localized: "Royaume-Uni")
        case "US": return String(localized: "États-Unis")
        case "DE": return String(localized: "Allemagne")
        case "AR": return String(localized: "Arabe")
        case "TR": return String(localized: "Turquie")
        case "PL": return String(localized: "Pologne")
        case "NL": return String(localized: "Pays-Bas")
        case "BE": return String(localized: "Belgique")
        case "CH": return String(localized: "Suisse")
        case "CA": return String(localized: "Canada")
        case "QC": return String(localized: "Québec")
        case "IN": return String(localized: "Inde")
        case "RU": return String(localized: "Russie")
        case "GR": return String(localized: "Grèce")
        case "RO": return String(localized: "Roumanie")
        case "AL": return String(localized: "Albanie")
        case "MA": return String(localized: "Maroc")
        case "DZ": return String(localized: "Algérie")
        case "TN": return String(localized: "Tunisie")
        case "LAT": return String(localized: "Amérique latine")
        case "EXYU": return String(localized: "Ex-Yougoslavie")
        case "AF": return String(localized: "Afrique")
        case "MX": return String(localized: "Mexique")
        default: return code
        }
    }
}

// MARK: - Différences macOS / iOS

extension URL.BookmarkCreationOptions {
    /// Signet « à portée de sécurité » sur Mac ; sur iOS, un signet ordinaire.
    static var scoped: URL.BookmarkCreationOptions {
        #if os(macOS)
        return .withSecurityScope
        #else
        return []
        #endif
    }
}

extension URL.BookmarkResolutionOptions {
    static var scoped: URL.BookmarkResolutionOptions {
        #if os(macOS)
        return .withSecurityScope
        #else
        return []
        #endif
    }
}

extension Notification.Name {
    /// Fermeture de l'application (Mac : NSApplication, iOS : UIApplication).
    static var kastideoWillTerminate: Notification.Name {
        #if os(macOS)
        return NSApplication.willTerminateNotification
        #else
        return UIApplication.willTerminateNotification
        #endif
    }
}
