import Foundation

/// Chaîne déclarée dans un guide XMLTV.
public struct XMLTVChannel: Sendable, Hashable, Codable {
    public var id: String
    public var names: [String]

    public init(id: String, names: [String]) {
        self.id = id
        self.names = names
    }
}

/// Résultat complet de l'analyse d'un guide XMLTV.
public struct XMLTVGuide: Sendable {
    public var programmes: [Programme]
    public var channels: [XMLTVChannel]
    /// Faux si le document n'est pas un guide XMLTV (page d'erreur, réponse vide…).
    public var isValid: Bool
    public var byteCount: Int

    public init(programmes: [Programme], channels: [XMLTVChannel], isValid: Bool, byteCount: Int) {
        self.programmes = programmes
        self.channels = channels
        self.isValid = isValid
        self.byteCount = byteCount
    }
}

/// Rapprochement des chaînes d'un fournisseur IPTV avec celles d'un guide de secours (xmltvfr.fr…),
/// par identifiant puis par nom normalisé (« |FR| TF1 FHD » → « tf1 »).
public struct ChannelMatcher: Sendable {
    private var byID: [String: String] = [:]
    private var byName: [String: String] = [:]

    public init(channels: [XMLTVChannel]) {
        // Plusieurs chaînes peuvent donner le même nom réduit : les noms affichés priment sur les identifiants,
        // et les chaînes françaises (.fr) sur les autres (« Canal+ » → CanalPlus.fr plutôt que CanalPlus.ch).
        var scores: [String: Int] = [:]
        func offer(_ key: String, _ id: String, _ base: Int) {
            guard !key.isEmpty else { return }
            let score = base + (id.lowercased().hasSuffix(".fr") ? 5 : 0)
            if score > scores[key] ?? -1 {
                scores[key] = score
                byName[key] = id
            }
        }
        for channel in channels {
            byID[channel.id.lowercased()] = channel.id
            let stem = channel.id.split(separator: ".").first.map(String.init) ?? channel.id
            offer(Self.normalize(stem, keepResolution: true), channel.id, 10)
            for name in channel.names {
                offer(Self.normalize(name, keepResolution: true), channel.id, 20)
                // Nom sans « 4K / UHD » : rang inférieur, ne remplace pas la version standard.
                offer(Self.normalize(name), channel.id, 15)
            }
        }
    }

    public var isEmpty: Bool { byID.isEmpty }

    /// Identifiant de la chaîne du guide correspondant à une chaîne du fournisseur.
    public func match(name: String, epgID: String?) -> String? {
        if let epgID, let id = byID[epgID.lowercased()] { return id }
        for key in [Self.normalize(name, keepResolution: true), Self.normalize(name)] where !key.isEmpty {
            if let id = byName[key] { return id }
        }
        return nil
    }

    private static let tags: Set<String> = [
        "fhd", "hd", "uhd", "sd", "4k", "8k", "hevc", "h265", "h264", "raw", "ott", "backup", "multi", "vip",
        "fr", "france", "be", "ch", "ca", "qc", "lq", "hq", "50fps", "60fps", "1080p", "720p", "low", "direct", "live", "tv"
    ]

    /// Nom réduit à l'essentiel : minuscules sans accents, sans préfixes de pays ni mentions de qualité.
    private static let resolutionTags: Set<String> = ["4k", "8k", "uhd"]

    public static func normalize(_ raw: String, keepResolution: Bool = false) -> String {
        var text = raw.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased()
        // Préfixes « |FR| », « [FR] », « FR: », « FR - ».
        text = text.replacingOccurrences(of: #"^\s*(\|[^|]*\||\[[^\]]*\])\s*"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"^\s*[a-z]{2,3}\s*[:|\-]\s+"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\([^)]*\)|\[[^\]]*\]"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "+", with: " plus ")
        text = text.replacingOccurrences(of: "&", with: " et ")
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        var kept = words
        // Retire les mentions de qualité en fin de nom (« tf1 fhd », « m6 4k » → mais garde « tv5monde »).
        while let last = kept.last, kept.count > 1, tags.contains(last),
              !(keepResolution && resolutionTags.contains(last)) { kept.removeLast() }
        while let first = kept.first, kept.count > 1, ["fr", "be", "ch", "ca"].contains(first) { kept.removeFirst() }
        // « La chaîne L'Équipe » → « lequipe ».
        if kept.count > 2, kept[0] == "la", kept[1] == "chaine" { kept.removeFirst(2) }
        return kept.joined()
    }
}
