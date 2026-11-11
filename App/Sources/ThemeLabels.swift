import Foundation
import KastideoCore

// Libellés des thèmes du direct, partagés entre Mac et iPhone/iPad.

extension ContentTheme {
    var label: String {
        switch self {
        case .general: return String(localized: "Généralistes")
        case .news: return String(localized: "Info")
        case .sport: return String(localized: "Sport")
        case .movies: return String(localized: "Films")
        case .series: return String(localized: "Séries")
        case .documentary: return String(localized: "Documentaires")
        case .kids: return String(localized: "Jeunesse")
        case .entertainment: return String(localized: "Divertissement")
        case .music: return String(localized: "Musique")
        case .automotive: return String(localized: "Auto-Moto")
        case .lifestyle: return String(localized: "Cuisine & Maison")
        case .nature: return String(localized: "Nature, Chasse & Pêche")
        case .religion: return String(localized: "Religion")
        case .regional: return String(localized: "Régional")
        case .international: return String(localized: "International")
        case .radio: return String(localized: "Radio")
        case .adult: return String(localized: "Adulte")
        case .other: return String(localized: "Autres")
        }
    }

    /// Titre d'une rangée « en ce moment » (interface Cinéma, accueil).
    var nowTitle: String {
        switch self {
        case .sport: return String(localized: "Sport en ce moment")
        case .movies: return String(localized: "Films en cours")
        case .series: return String(localized: "Séries en cours")
        case .news: return String(localized: "Info en direct")
        case .documentary: return String(localized: "Documentaires en cours")
        case .kids: return String(localized: "Jeunesse en ce moment")
        case .entertainment: return String(localized: "Divertissement en ce moment")
        case .music: return String(localized: "Musique en ce moment")
        case .automotive: return String(localized: "Sports mécaniques en ce moment")
        case .lifestyle: return String(localized: "Cuisine & Maison en ce moment")
        case .nature: return String(localized: "Nature en ce moment")
        case .regional: return String(localized: "Régional en ce moment")
        case .international: return String(localized: "International en ce moment")
        case .religion, .radio, .adult, .general, .other: return String(localized: "En ce moment")
        }
    }

    /// Thèmes proposés dans les filtres (les « autres » à la fin).
    static var browsable: [ContentTheme] {
        var list: [ContentTheme] = [.sport, .automotive, .movies, .series, .news, .documentary, .nature, .kids, .entertainment,
                                    .lifestyle, .music, .general, .regional, .international, .religion, .radio]
        if UserDefaults.standard.bool(forKey: "adult.show") { list.append(.adult) }
        list.append(.other)
        return list
    }
}

extension SportKind {
    var label: String {
        switch self {
        case .football: return String(localized: "Football")
        case .rugby: return String(localized: "Rugby")
        case .tennis: return String(localized: "Tennis")
        case .basketball: return String(localized: "Basket")
        case .combat: return String(localized: "Sports de combat")
        case .golf: return String(localized: "Golf")
        case .cycling: return String(localized: "Cyclisme")
        case .handball: return String(localized: "Handball")
        case .motorsport: return String(localized: "Sports mécaniques")
        case .winter: return String(localized: "Sports d'hiver")
        case .horse: return String(localized: "Hippisme")
        case .athletics: return String(localized: "Athlétisme & natation")
        case .other: return String(localized: "Autres sports")
        }
    }
}

/// Fenêtres horaires.
enum ThemeWindows {
    /// « Ce soir » : programmes commençant entre 20 h et 23 h (ou dès maintenant si la soirée est entamée).
    static func tonight(now: Date) -> DateInterval {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
        let end = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(3 * 3600)
        if now > end {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return DateInterval(start: tomorrow, end: tomorrow.addingTimeInterval(3 * 3600))
        }
        return DateInterval(start: start, end: end)
    }
}
