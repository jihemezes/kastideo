import Foundation

// Cast : envoi d'une vidéo vers un téléviseur ou un boîtier du réseau.
// - Chromecast / Google TV / TV Android : moteur VLC (rendu distant), géré côté application.
// - YouTube : lancement de l'application YouTube du téléviseur par DIAL (SSDP + requête HTTP).
// Ce fichier ne contient que la partie sans réseau (recherche SSDP, lecture des réponses, corps de la requête) : testable partout.

/// Appareil qui sait ouvrir l'application YouTube (protocole DIAL).
public struct DIALDevice: Hashable, Identifiable, Sendable {
    public var id: String { host }
    public var name: String
    public var host: String
    /// Adresse de base des applications (en-tête « Application-URL »), toujours terminée par « / ».
    public var applicationURL: URL

    public init(name: String, host: String, applicationURL: URL) {
        self.name = name
        self.host = host
        self.applicationURL = applicationURL
    }
}

public enum CastDIAL {
    public static let multicastAddress = "239.255.255.250"
    public static let multicastPort: UInt16 = 1900
    public static let searchTarget = "urn:dial-multiscreen-org:service:dial:1"

    /// Requête SSDP M-SEARCH qui cherche les appareils DIAL.
    public static var searchRequest: String {
        "M-SEARCH * HTTP/1.1\r\nHOST: \(multicastAddress):\(multicastPort)\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\nST: \(searchTarget)\r\n\r\n"
    }

    /// Valeur d'un en-tête d'une réponse SSDP (casse du nom ignorée).
    public static func header(_ name: String, in response: String) -> String? {
        for line in response.components(separatedBy: "\r\n") {
            guard let colon = line.firstIndex(of: ":") else { continue }
            if line[..<colon].trimmingCharacters(in: .whitespaces).lowercased() == name.lowercased() {
                return String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    /// Nom affiché de l'appareil, d'après sa description UPnP.
    public static func friendlyName(inXML xml: String) -> String? {
        guard let start = xml.range(of: "<friendlyName>"), let end = xml.range(of: "</friendlyName>", range: start.upperBound..<xml.endIndex) else { return nil }
        let raw = String(xml[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&apos;", with: "'")
    }

    /// Adresse de base des applications, normalisée (terminée par « / »).
    public static func applicationURL(from header: String) -> URL? {
        let text = header.hasSuffix("/") ? header : header + "/"
        guard let url = URL(string: text), url.scheme == "http" || url.scheme == "https", url.host != nil else { return nil }
        return url
    }

    /// Corps de la requête POST qui lance YouTube avec une vidéo, à partir d'une position (secondes).
    public static func youTubeBody(videoID: String, startSeconds: Int = 0) -> String {
        "v=\(videoID)&t=\(max(0, startSeconds))"
    }

    /// Adresse de la requête de lancement de YouTube.
    public static func youTubeLaunchURL(_ device: DIALDevice) -> URL {
        device.applicationURL.appendingPathComponent("YouTube")
    }
}
