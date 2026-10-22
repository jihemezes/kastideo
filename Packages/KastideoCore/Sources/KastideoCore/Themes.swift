import Foundation

/// Thème d'une chaîne ou d'un programme.
public enum ContentTheme: String, CaseIterable, Codable, Sendable, Identifiable {
    case general, news, sport, movies, series, documentary, kids, entertainment, music, other

    public var id: String { rawValue }

    /// Icône SF Symbols.
    public var icon: String {
        switch self {
        case .general: return "tv"
        case .news: return "newspaper"
        case .sport: return "sportscourt"
        case .movies: return "film"
        case .series: return "rectangle.stack"
        case .documentary: return "globe.europe.africa"
        case .kids: return "teddybear"
        case .entertainment: return "sparkles.tv"
        case .music: return "music.note"
        case .other: return "square.grid.2x2"
        }
    }
}

/// Classement automatique par thème : nom de la chaîne, genre des programmes du guide.
public enum ThemeClassifier {

    /// Thème d'un programme d'après son genre XMLTV (français ou anglais), puis quelques mots du titre.
    public static func theme(forProgramme programme: Programme) -> ContentTheme? {
        if let category = programme.category, let theme = theme(forCategory: category) { return theme }
        let title = fold(programme.title)
        if title.hasPrefix("journal") || title.contains("le 20h") || title.contains("le 13h") || title.hasPrefix("jt ") { return .news }
        if title.contains("ligue 1") || title.contains("ligue des champions") || title.contains("football") || title.contains("rugby")
            || title.contains("tennis") || title.contains("formule 1") || title.contains("nba") { return .sport }
        return nil
    }

    /// Thème d'un genre XMLTV.
    public static func theme(forCategory raw: String) -> ContentTheme? {
        let c = fold(raw)
        let rules: [(ContentTheme, [String])] = [
            (.sport, ["sport", "football", "rugby", "tennis", "cyclisme", "basket", "golf", "athletisme", "moteur", "motorsport", "boxe"]),
            (.kids, ["jeunesse", "dessin anime", "animation", "children", "enfant", "kids", "animated", "cartoon"]),
            (.news, ["journal", "information", "actualite", "news", "infos", "meteo", "politique", "debat"]),
            (.documentary, ["documentaire", "documentary", "decouverte", "nature", "histoire", "science", "animalier", "voyage"]),
            (.movies, ["film", "movie", "cinema", "telefilm", "court metrage"]),
            (.series, ["serie", "series", "feuilleton", "sitcom", "soap", "drama"]),
            (.music, ["musique", "music", "clip", "concert", "opera", "variete"]),
            (.entertainment, ["divertissement", "jeu", "game show", "talk", "telerealite", "reality", "humour", "spectacle", "magazine", "emission"]),
        ]
        // « Série d'animation » → jeunesse ; « Magazine sportif » → sport : l'ordre des règles compte.
        for (theme, words) in rules where words.contains(where: { c.contains($0) }) { return theme }
        return nil
    }

    /// Thème d'une chaîne d'après son nom (les grandes chaînes françaises et les marques thématiques connues).
    public static func theme(forChannelName name: String) -> ContentTheme? {
        let key = ChannelMatcher.normalize(name)
        let words = Set(fold(name).components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
        let general: Set<String> = ["tf1", "france2", "france3", "france4", "france5", "m6", "c8", "w9", "tmc", "tfx", "nrj12",
                                    "arte", "6ter", "cherie25", "rmcstory", "numero23", "tv5monde", "rtsun", "rtl", "rtlinfo",
                                    "latrois", "lauxun", "laune", "tvbreizh", "paris premiere", "parispremiere", "canalplus", "canal"]
        if general.contains(key) { return .general }
        let rules: [(ContentTheme, [String])] = [
            (.sport, ["bein", "eurosport", "rmcsport", "canalplussport", "sport", "equipe", "foot", "golf", "dazn", "infosport", "automoto", "motorsport", "nba", "skysport", "tennis", "rugby"]),
            (.news, ["bfm", "lci", "cnews", "franceinfo", "euronews", "france24", "news", "info", "cnn", "bbcworld", "lcp", "publicsenat", "aljazeera"]),
            (.kids, ["gulli", "disney", "nickelodeon", "nick", "cartoon", "boomerang", "tiji", "piwi", "canalj", "teletoon", "junior", "kids", "baby", "boing", "mangas"]),
            (.documentary, ["discovery", "nationalgeographic", "natgeo", "histoire", "history", "planete", "ushuaia", "science", "animaux", "docu", "rmcdecouverte", "toutelhistoire", "museum", "trek", "voyage", "chasse", "peche", "seasons"]),
            (.movies, ["cine", "cinema", "film", "movie", "paramount", "tcm", "actionfilm", "ocs", "cinefx", "polar", "warnertv"]),
            (.series, ["serie", "series", "13emerue", "syfy", "comedie", "tf1seriesfilms", "teva", "rtl9", "ab1", "novelas"]),
            (.music, ["mtv", "mcm", "music", "trace", "mezzo", "hits", "melody", "clip", "radio", "skyrock", "funradio"]),
            (.entertainment, ["game", "comedy", "realite", "fashion", "food", "cuisine", "maison", "deco", "auto"]),
        ]
        for (theme, needles) in rules {
            if needles.contains(where: { key.contains($0) || words.contains($0) }) { return theme }
        }
        return nil
    }

    /// Thème dominant d'une liste de programmes (au moins 45 % des programmes classables).
    public static func dominantTheme(of programmes: [Programme]) -> ContentTheme? {
        var counts: [ContentTheme: Int] = [:]
        var total = 0
        for programme in programmes {
            guard let theme = theme(forProgramme: programme) else { continue }
            counts[theme, default: 0] += 1
            total += 1
        }
        guard total >= 4, let best = counts.max(by: { $0.value < $1.value }), Double(best.value) / Double(total) >= 0.45 else {
            return total >= 4 ? .general : nil
        }
        return best.key
    }

    static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR")).lowercased()
    }
}

/// Qualité annoncée dans le nom d'une chaîne (« TF1 FHD », « M6 4K », « France 2 SD »).
public enum ChannelQuality: Int, CaseIterable, Codable, Sendable, Comparable {
    case sd = 0, hd = 1, fhd = 2, uhd = 3

    public static func < (lhs: ChannelQuality, rhs: ChannelQuality) -> Bool { lhs.rawValue < rhs.rawValue }

    public var label: String {
        switch self {
        case .sd: return "SD"
        case .hd: return "HD"
        case .fhd: return "Full HD"
        case .uhd: return "4K"
        }
    }

    /// Qualité lue dans le nom ; HD par défaut.
    public static func of(_ name: String) -> ChannelQuality {
        let words = Set(ThemeClassifier.fold(name).components(separatedBy: CharacterSet.alphanumerics.inverted))
        if words.contains("4k") || words.contains("uhd") || words.contains("2160p") || words.contains("8k") { return .uhd }
        if words.contains("fhd") || words.contains("1080p") || words.contains("1080") { return .fhd }
        if words.contains("sd") || words.contains("lq") || words.contains("low") || words.contains("480p") { return .sd }
        return .hd
    }

    /// Choisit, parmi les versions d'une même chaîne, la meilleure qui ne dépasse pas la qualité visée
    /// (à défaut, la plus faible disponible).
    public static func pick<T>(_ variants: [T], target: ChannelQuality, quality: (T) -> ChannelQuality) -> T? {
        let fitting = variants.filter { quality($0) <= target }
        if let best = fitting.max(by: { quality($0) < quality($1) }) { return best }
        return variants.min(by: { quality($0) < quality($1) })
    }
}

extension ChannelMatcher {
    /// Clé commune aux versions d'une même chaîne (« |FR| TF1 FHD », « TF1 HD », « TF1 4K » → « tf1 »).
    public static func variantKey(_ name: String) -> String { normalize(name) }
}
