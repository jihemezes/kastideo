import Foundation

/// Pays (ou langue) d'une catégorie ou d'un titre, repéré dans son nom :
/// « FR| CINÉMA », « |PT| FILMES », « [IT] Film », « FRANCE HD », « VOSTFR »…
/// Même logique que la version Windows / Linux (core/countries.dart).
public enum CountryDetector {
    public static let codes: Set<String> = [
        "FR", "PT", "BR", "IT", "ES", "EN", "UK", "US", "DE", "AR", "TR", "PL", "NL", "BE", "CH", "CA", "QC", "IN", "PK", "RU",
        "GR", "RO", "AL", "MA", "DZ", "TN", "LAT", "EXYU", "SE", "NO", "DK", "FI", "IR", "KU", "AF", "MX", "AT", "HU", "CZ", "SK",
        "BG", "HR", "RS", "IL", "CN", "JP", "KR", "PH", "TH", "VN", "ID", "MY", "SA", "AE", "EG", "LB", "SY", "IQ", "BD", "LK",
    ]

    static let aliases: [String: String] = [
        "FRANCE": "FR", "FRENCH": "FR", "FRANCAIS": "FR", "FRANCAISE": "FR", "VF": "FR", "VFF": "FR", "VFQ": "QC", "VOSTFR": "FR",
        "PORTUGAL": "PT", "PORTUGUESE": "PT", "PORTUGUES": "PT", "PORTUGUESA": "PT",
        "BRASIL": "BR", "BRAZIL": "BR", "BRAZILIAN": "BR", "BRASILEIRO": "BR",
        "ITALIA": "IT", "ITALY": "IT", "ITALIAN": "IT", "ITALIANO": "IT",
        "ESPANA": "ES", "SPAIN": "ES", "SPANISH": "ES", "ESPANOL": "ES", "CASTELLANO": "ES", "LATINO": "LAT", "LATAM": "LAT",
        "ENGLISH": "EN", "GB": "UK", "USA": "US", "GERMANY": "DE", "DEUTSCH": "DE", "GERMAN": "DE", "DEUTSCHLAND": "DE",
        "ARABIC": "AR", "ARAB": "AR", "ARABIA": "AR", "TURKEY": "TR", "TURKISH": "TR", "TURKIYE": "TR", "POLAND": "PL", "POLSKA": "PL",
        "NETHERLANDS": "NL", "DUTCH": "NL", "NEDERLAND": "NL", "BELGIUM": "BE", "BELGIQUE": "BE", "SUISSE": "CH", "SWISS": "CH",
        "CANADA": "CA", "QUEBEC": "QC", "AFRICA": "AF", "AFRIQUE": "AF", "INDIA": "IN", "HINDI": "IN", "PAKISTAN": "PK",
        "RUSSIA": "RU", "RUSSIAN": "RU", "GREECE": "GR", "GREEK": "GR", "ROMANIA": "RO", "ALBANIA": "AL", "MAGHREB": "MA",
        "MAROC": "MA", "MOROCCO": "MA", "ALGERIE": "DZ", "ALGERIA": "DZ", "TUNISIE": "TN", "TUNISIA": "TN", "KURDISH": "KU",
        "IRAN": "IR", "PERSIAN": "IR", "SWEDEN": "SE", "NORWAY": "NO", "DENMARK": "DK", "FINLAND": "FI", "MEXICO": "MX",
        "AUSTRIA": "AT", "HUNGARY": "HU", "CZECH": "CZ", "BULGARIA": "BG", "CROATIA": "HR", "SERBIA": "RS", "ISRAEL": "IL",
        "CHINA": "CN", "CHINESE": "CN", "JAPAN": "JP", "JAPANESE": "JP", "KOREA": "KR", "KOREAN": "KR",
    ]

    // Pas de littéraux regex (/.../) : le paquet doit aussi se compiler sous Linux pour les tests.
    private static let prefix = try! NSRegularExpression(pattern: #"^[\s|\[\(\{#*-]*([A-Z]{2,4})(?:[\s\]\)\}]*[|:\]\)\-–]|\s+[-–|:])"#)
    private static let bracketed = try! NSRegularExpression(pattern: #"[|\[\(]\s*([A-Z]{2,4})\s*[|\]\)]"#)

    /// Code du pays, ou `nil` si le nom n'en indique pas.
    public static func code(for text: String) -> String? {
        let upper = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR")).uppercased()
        let range = NSRange(upper.startIndex..., in: upper)
        if let m = prefix.firstMatch(in: upper, range: range), let r = Range(m.range(at: 1), in: upper),
           let code = normalize(String(upper[r])) {
            return code
        }
        for m in bracketed.matches(in: upper, range: range) {
            if let r = Range(m.range(at: 1), in: upper), let code = normalize(String(upper[r])) { return code }
        }
        let short: Set<String> = ["VF", "VFF", "VFQ", "USA"]
        for word in upper.split(whereSeparator: { !("A"..."Z").contains($0) }).map(String.init) {
            if word.count < 4 && !short.contains(word) { continue }
            if let code = aliases[word] { return code }
        }
        return nil
    }

    private static func normalize(_ token: String) -> String? {
        if let alias = aliases[token] { return alias }
        return codes.contains(token) ? token : nil
    }

    /// Pays d'un contenu : celui de sa catégorie, sinon celui de son nom.
    public static func code(for item: MediaItem) -> String? {
        code(for: item.group) ?? code(for: item.name)
    }
}

/// Choix des pays affichés dans les rangées Cinéma et le bandeau (vide : tous).
public struct CountryFilter: Sendable, Equatable {
    public var codes: Set<String>
    /// Les catégories sans pays reconnu restent affichées.
    public var keepNeutral: Bool

    public init(codes: Set<String> = [], keepNeutral: Bool = true) {
        self.codes = codes
        self.keepNeutral = keepNeutral
    }

    public var isActive: Bool { !codes.isEmpty }

    public func allows(code: String?) -> Bool {
        guard isActive else { return true }
        guard let code else { return keepNeutral }
        return codes.contains(code)
    }

    public func allows(category: String) -> Bool { !isActive || allows(code: CountryDetector.code(for: category)) }
    public func allows(_ item: MediaItem) -> Bool { !isActive || allows(code: CountryDetector.code(for: item)) }

    /// Codes enregistrés dans les réglages (« FR,IT »).
    public init(stored: String, keepNeutral: Bool) {
        self.init(codes: Set(stored.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }),
                  keepNeutral: keepNeutral)
    }

    public var stored: String { codes.sorted().joined(separator: ",") }
}
