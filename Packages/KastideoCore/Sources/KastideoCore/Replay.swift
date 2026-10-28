import Foundation

/// Horloge d'un serveur Xtream : sert à écrire l'heure de début d'un replay dans le fuseau du serveur.
public struct ServerClock: Codable, Hashable, Sendable {
    /// Nom du fuseau (« Europe/Paris »), si le serveur l'annonce et que le système le connaît.
    public var timezone: String?
    /// Décalage actuel avec UTC en secondes, déduit de `time_now` et `timestamp_now`.
    public var offset: Int?

    public init(timezone: String? = nil, offset: Int? = nil) {
        self.timezone = timezone
        self.offset = offset
    }

    /// Lit le bloc `server_info` de player_api.php.
    public static func parse(_ info: [String: Any]?, now: Date = Date()) -> ServerClock? {
        guard let info else { return nil }
        func text(_ key: String) -> String? {
            switch info[key] {
            case let s as String: return s.isEmpty ? nil : s
            case let n as NSNumber: return n.stringValue
            default: return nil
            }
        }
        var offset: Int?
        if let local = text("time_now"), let stamp = text("timestamp_now").flatMap({ Double($0) }) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            f.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let asUTC = f.date(from: local) {
                // Arrondi au quart d'heure : l'écart des horloges ne doit pas fausser le décalage.
                let raw = asUTC.timeIntervalSince1970 - stamp
                offset = Int((raw / 900).rounded()) * 900
            }
        }
        let zone = text("timezone").flatMap { TimeZone(identifier: $0) != nil ? $0 : nil }
        if zone == nil && offset == nil { return nil }
        return ServerClock(timezone: zone, offset: offset)
    }

    /// Décalage avec UTC (secondes) à un instant donné ; `fallback` = fuseau de l'appareil si le serveur ne dit rien.
    public func offset(at date: Date, fallback: TimeZone = .current) -> Int {
        if let timezone, let tz = TimeZone(identifier: timezone) { return tz.secondsFromGMT(for: date) }
        if let offset { return offset }
        return fallback.secondsFromGMT(for: date)
    }
}

/// Adresses de replay (archive du fournisseur, « timeshift » Xtream Codes).
public enum ReplayURL {
    /// Préfixe des identifiants des éléments de replay.
    public static let idPrefix = "replay:"

    /// Marge avant le début annoncé du programme (le guide est rarement exact à la minute).
    public static let marginBefore: TimeInterval = 60
    /// Marge après la fin annoncée (les programmes débordent).
    public static let marginAfter: TimeInterval = 5 * 60

    /// Adresse du replay d'une chaîne depuis son adresse directe
    /// (`…/live/identifiant/mot-de-passe/ID.ts` → `…/timeshift/identifiant/mot-de-passe/durée/AAAA-MM-JJ:HH-MM/ID.ts`).
    /// - Parameters:
    ///   - start: début du programme (instant absolu).
    ///   - end: fin du programme.
    ///   - extraOffsetMinutes: correction manuelle de l'heure écrite dans l'adresse.
    public static func make(live: URL, start: Date, end: Date, clock: ServerClock?,
                            extraOffsetMinutes: Int = 0, fallbackZone: TimeZone = .current) -> URL? {
        guard var comps = URLComponents(url: live, resolvingAgainstBaseURL: false) else { return nil }
        let parts = comps.percentEncodedPath.split(separator: "/").map(String.init)
        guard parts.count >= 4, let liveIndex = parts.lastIndex(of: "live"), liveIndex + 3 == parts.count - 1 else { return nil }
        let user = parts[liveIndex + 1], pass = parts[liveIndex + 2]
        let file = parts[liveIndex + 3]
        let id = (file as NSString).deletingPathExtension
        let begin = start.addingTimeInterval(-marginBefore)
        let finish = end.addingTimeInterval(marginAfter)
        let minutes = max(1, Int(((finish.timeIntervalSince(begin)) / 60).rounded(.up)))
        let shifted = begin.addingTimeInterval(TimeInterval((clock?.offset(at: begin, fallback: fallbackZone) ?? fallbackZone.secondsFromGMT(for: begin)) + extraOffsetMinutes * 60))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: shifted)
        let stamp = String(format: "%04d-%02d-%02d:%02d-%02d", c.year!, c.month!, c.day!, c.hour!, c.minute!)
        let prefix = parts[..<liveIndex].map { "/" + $0 }.joined()
        comps.percentEncodedPath = prefix + "/timeshift/" + [user, pass, String(minutes), stamp, "\(id).ts"].joined(separator: "/")
        comps.query = nil
        return comps.url
    }
}

public extension MediaItem {
    /// Vrai pour un élément de replay (programme déjà diffusé relu depuis l'archive du fournisseur).
    var isReplay: Bool { id.hasPrefix(ReplayURL.idPrefix) }
}
