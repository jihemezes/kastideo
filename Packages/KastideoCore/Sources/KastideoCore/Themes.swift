import Foundation

/// Thème d'une chaîne ou d'un programme.
public enum ContentTheme: String, CaseIterable, Codable, Sendable, Identifiable {
    case general, news, sport, movies, series, documentary, kids, entertainment, music
    case automotive, lifestyle, nature, religion, regional, international, radio, adult
    case other

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
        case .automotive: return "car.side"
        case .lifestyle: return "fork.knife"
        case .nature: return "leaf"
        case .religion: return "building.columns"
        case .regional: return "map"
        case .international: return "globe"
        case .radio: return "radio"
        case .adult: return "eye.slash"
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
            (.automotive, ["sports mecaniques", "sport mecanique", "moteur", "motorsport", "formule 1", "rallye", "automobile", "moto"]),
            (.sport, ["sport", "football", "rugby", "tennis", "cyclisme", "basket", "golf", "athletisme", "moteur", "motorsport", "boxe"]),
            (.kids, ["jeunesse", "dessin anime", "animation", "children", "enfant", "kids", "animated", "cartoon"]),
            (.news, ["journal", "information", "actualite", "news", "infos", "meteo", "politique", "debat"]),
            (.nature, ["animalier", "animaux", "nature", "chasse", "peche", "wildlife"]),
            (.lifestyle, ["cuisine", "gastronomie", "lifestyle", "maison", "bricolage", "jardinage", "mode", "beaute", "tele-achat", "teleachat", "shopping", "deco"]),
            (.religion, ["religion", "religieux", "messe", "spiritualite"]),
            (.adult, ["adulte", "adult", "erotique", "charme"]),
            (.documentary, ["documentaire", "documentary", "decouverte", "histoire", "science", "voyage"]),
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
    public static func theme(forChannelName name: String, group: String = "") -> ContentTheme? {
        if isAdult(name: name, group: group) { return .adult }
        let key = ChannelMatcher.normalize(name)
        let words = Set(fold(name).components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
        let general: Set<String> = ["tf1", "france2", "france3", "france4", "france5", "m6", "c8", "w9", "tmc", "tfx", "nrj12",
                                    "arte", "6ter", "cherie25", "rmcstory", "numero23", "tv5monde", "rtsun", "rtl", "rtlinfo",
                                    "latrois", "lauxun", "laune", "tvbreizh", "paris premiere", "parispremiere", "canalplus", "canal"]
        if general.contains(key) { return .general }
        if isRegional(key: key, words: words) { return .regional }
        let rules: [(ContentTheme, [String])] = [
            (.automotive, ["automoto", "motorsport", "motorstv", "motors", "f1", "formula1", "turbo", "rallye", "nascar", "motogp", "autoplus"]),
            (.religion, ["kto", "emci", "dieu", "god", "catholic", "jewish", "islam", "coran", "quran", "church", "gospel", "orthodox"]),
            (.radio, ["radio", "fip", "rfm", "nostalgie", "skyrock", "funradio", "rtl2", "cheriefm", "virgin radio", "franceinter", "franceculture", "europe1", "rmcradio", "ouifm"]),
            (.sport, ["bein", "eurosport", "rmcsport", "canalplussport", "sport", "equipe", "foot", "golf", "dazn", "infosport", "nba", "skysport", "tennis", "rugby", "equidia", "multisports"]),
            (.news, ["bfm", "lci", "cnews", "franceinfo", "euronews", "france24", "news", "info", "cnn", "bbcworld", "lcp", "publicsenat", "aljazeera"]),
            (.kids, ["gulli", "disney", "nickelodeon", "nick", "cartoon", "boomerang", "tiji", "piwi", "canalj", "teletoon", "junior", "kids", "baby", "boing", "mangas"]),
            (.nature, ["ushuaia", "animaux", "seasons", "chasse", "peche", "wild", "animalplanet", "natgeowild", "nature", "montagne"]),
            (.lifestyle, ["cuisine", "food", "chef", "maison", "deco", "travel", "voyage", "fashion", "mode", "teleshopping", "bestofshopping", "mieuxetre", "gourmet"]),
            (.documentary, ["discovery", "nationalgeographic", "natgeo", "histoire", "history", "planete", "science", "docu", "rmcdecouverte", "toutelhistoire", "museum", "trek"]),
            (.movies, ["cine", "cinema", "film", "movie", "paramount", "tcm", "actionfilm", "ocs", "cinefx", "polar", "warnertv"]),
            (.series, ["serie", "series", "13emerue", "syfy", "comedie", "tf1seriesfilms", "teva", "rtl9", "ab1", "novelas"]),
            (.music, ["mtv", "mcm", "music", "trace", "mezzo", "hits", "melody", "clip"]),
            (.entertainment, ["game", "comedy", "realite"]),
        ]
        for (theme, needles) in rules {
            if needles.contains(where: { key.contains($0) || words.contains($0) }) { return theme }
        }
        if isInternational(name) { return .international }
        return nil
    }

    /// Adulte : « |XX| » dans le nom, ou catégorie du fournisseur explicitement adulte.
    public static func isAdult(name: String, group: String = "") -> Bool {
        let upper = name.uppercased()
        if upper.contains("|XX|") || upper.contains("XXX") || upper.contains("[XX]") { return true }
        let g = fold(group)
        return g.contains("adult") || g.contains("xxx") || g.contains("+18") || g.contains("18+") || fold(group).contains("|xx|")
    }

    /// Chaînes locales : France 3 régions, télévisions locales, BFM des villes.
    static func isRegional(key: String, words: Set<String>) -> Bool {
        if key.hasPrefix("france3"), key != "france3" { return true }
        if key.hasPrefix("bfm"), !["bfm", "bfmtv", "bfmbusiness", "bfmplus"].contains(key), !key.contains("sport") { return true }
        let locals = ["tv7", "tl7", "tvr", "tebeo", "tebesud", "8montblanc", "7alimoges", "viaoccitanie", "biptv", "grandlilletv",
                      "telegrenoble", "tvvendee", "alsace20", "lyoncapitale", "canalalpha", "telenantes", "weo", "noa", "tv8montblanc",
                      "maritima", "provenceazur", "azurtv", "tvsud", "tlm", "ilti", "vosgestv", "dici"]
        return locals.contains { key.contains($0) } || words.contains("locale") || words.contains("regional")
    }

    /// Chaîne étrangère : préfixe de pays autre que francophone (« |IT| », « UK: », « [DE] »).
    public static func isInternational(_ name: String) -> Bool {
        guard let range = name.range(of: #"^\s*[\|\[]?\s*([A-Za-z]{2,3})\s*[\|\]:-]"#, options: .regularExpression) else { return false }
        let code = name[range].uppercased().filter { $0.isLetter }
        let francophone: Set<String> = ["FR", "FRA", "VF", "VFF", "BE", "CH", "QC", "CA", "MC", "LU", "HD", "SD", "FHD", "UHD", "XX"]
        return !francophone.contains(code)
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

    private static let decoration: Set<Character> = Set("-=_*~•●★☆♣♦♠♥◆◇■□▬═─━▪▫◦·✦✧⚡")

    /// Vrai pour une « chaîne » qui n'est qu'un séparateur de catégorie des fournisseurs IPTV
    /// (par exemple « ♣♦♣----|FR| FRANCE FHD |FR|---♣♦♣ » ou « •●★---|FR| CINEMA FHD |FR|---★●• »).
    public static func isSeparator(_ name: String) -> Bool {
        var run = 0
        var best = 0
        for character in name {
            if decoration.contains(character) { run += 1; best = max(best, run) } else { run = 0 }
        }
        return best >= 3
    }
}

/// Discipline d'un programme ou d'une chaîne de sport.
public enum SportKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case football, rugby, tennis, basketball, combat, golf, cycling, handball, motorsport, winter, horse, athletics, other
    public var id: String { rawValue }

    static let keywords: [(SportKind, [String])] = [
        (.football, ["football", "foot", "ligue 1", "ligue 2", "ligue des champions", "champions league", "premier league", "liga", "serie a", "bundesliga", "coupe de france", "europa league", "psg", "om ", "ol "]),
        (.rugby, ["rugby", "top 14", "pro d2", "six nations", "tournoi des 6", "champions cup"]),
        (.tennis, ["tennis", "roland-garros", "roland garros", "wimbledon", "atp", "wta", "us open", "open d'australie", "masters 1000"]),
        (.basketball, ["basket", "nba", "euroleague", "betclic elite"]),
        (.combat, ["boxe", "boxing", "mma", "ufc", "catch", "wwe", "judo", "karate", "kickboxing", "lutte", "combat"]),
        (.golf, ["golf", "pga", "ryder cup"]),
        (.cycling, ["cyclisme", "tour de france", "giro", "vuelta", "velo", "cycling"]),
        (.handball, ["handball"]),
        (.motorsport, ["formule 1", "formula 1", "f1", "motogp", "moto gp", "rallye", "nascar", "endurance", "24 heures", "superbike", "moteur", "motorsport"]),
        (.winter, ["ski", "biathlon", "patinage", "hockey", "snowboard", "sports d'hiver"]),
        (.horse, ["hippisme", "turf", "pmu", "equitation", "quinte", "galop", "trot", "equidia"]),
        (.athletics, ["athletisme", "marathon", "natation", "jeux olympiques", "decathlon"]),
    ]

    /// Discipline d'après un texte (titre, genre, description ou nom de chaîne).
    public static func detect(_ texts: String?...) -> SportKind? {
        let text = " " + texts.compactMap { $0 }.map(ThemeClassifier.fold).joined(separator: " ") + " "
        for (kind, words) in keywords where words.contains(where: { text.contains($0) }) { return kind }
        return nil
    }

    public static func of(_ programme: Programme) -> SportKind? {
        detect(programme.title, programme.category, programme.desc)
    }
}
