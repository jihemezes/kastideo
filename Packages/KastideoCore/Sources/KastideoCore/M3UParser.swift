import Foundation

/// Analyse des playlists M3U / M3U8 « étendues » utilisées par les fournisseurs IPTV.
///
/// Gère : `#EXTM3U url-tvg="…" x-tvg-url="…"`, `#EXTINF:-1 tvg-id="…" tvg-name="…" tvg-logo="…"
/// group-title="…" tvg-chno="…",Nom`, `#EXTGRP:`, les options `#EXTVLCOPT` (ignorées)
/// et les URL nues sans `#EXTINF`.
public enum M3UParser {

    public struct Result: Sendable {
        public var items: [MediaItem]
        public var epgURL: URL?
    }

    public static let defaultGroup = "Sans catégorie"

    public static func parse(_ text: String, sourceID: UUID) -> Result {
        var items: [MediaItem] = []
        var epgURL: URL?
        var seenIDs: [String: Int] = [:]

        var pendingAttributes: [String: String] = [:]
        var pendingName: String?
        var pendingGroup: String?

        // Gère les fins de ligne \n, \r\n et \r.
        let lines = text.split(omittingEmptySubsequences: true, whereSeparator: { $0 == "\n" || $0 == "\r" || $0 == "\r\n" })

        for rawLine in lines {
            var line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("\u{FEFF}") { line.removeFirst() }
            if line.isEmpty { continue }

            if line.hasPrefix("#EXTM3U") {
                let attrs = parseAttributes(String(line.dropFirst("#EXTM3U".count)))
                if let raw = attrs["url-tvg"] ?? attrs["x-tvg-url"] ?? attrs["tvg-url"],
                   let first = raw.split(separator: ",").first,
                   let url = URL(string: first.trimmingCharacters(in: .whitespaces)) {
                    epgURL = url
                }
                continue
            }

            if line.hasPrefix("#EXTINF") {
                let body = String(line.dropFirst("#EXTINF".count)).drop(while: { $0 == ":" })
                let (attrPart, name) = splitInfo(String(body))
                pendingAttributes = parseAttributes(attrPart)
                pendingName = name
                continue
            }

            if line.hasPrefix("#EXTGRP:") {
                pendingGroup = String(line.dropFirst("#EXTGRP:".count)).trimmingCharacters(in: .whitespaces)
                continue
            }

            if line.hasPrefix("#") { continue } // #EXTVLCOPT, #KODIPROP, commentaires…

            // Ligne d'URL.
            guard let url = URL(string: line), url.scheme != nil else {
                pendingAttributes = [:]; pendingName = nil; pendingGroup = nil
                continue
            }

            var name = pendingName?.trimmingCharacters(in: .whitespaces) ?? ""
            if name.isEmpty { name = pendingAttributes["tvg-name"] ?? "" }
            if name.isEmpty { name = url.deletingPathExtension().lastPathComponent }
            if name.isEmpty { name = line }

            var group = pendingAttributes["group-title"] ?? pendingGroup ?? ""
            group = group.trimmingCharacters(in: .whitespaces)
            if group.isEmpty { group = defaultGroup }

            let logo = pendingAttributes["tvg-logo"].flatMap { $0.isEmpty ? nil : URL(string: $0) }
            let epgID = pendingAttributes["tvg-id"].flatMap { $0.isEmpty ? nil : $0 }
            let number = pendingAttributes["tvg-chno"].flatMap { Int($0) }
            let kind = guessKind(url: url)

            var id = "\(sourceID.uuidString):\(url.absoluteString)"
            if let count = seenIDs[id] {
                seenIDs[id] = count + 1
                id += "#\(count + 1)"
            } else {
                seenIDs[id] = 0
            }

            items.append(MediaItem(id: id, sourceID: sourceID, kind: kind, name: name, group: group,
                                   logoURL: logo, streamURL: url, epgID: epgID, number: number))

            pendingAttributes = [:]
            pendingName = nil
            pendingGroup = nil
        }

        return Result(items: items, epgURL: epgURL)
    }

    /// Devine le type de contenu à partir de l'URL (conventions Xtream et extensions de fichiers).
    public static func guessKind(url: URL) -> MediaKind {
        let path = url.path.lowercased()
        if path.contains("/series/") { return .series }
        if path.contains("/movie/") { return .movie }
        if path.contains("/live/") { return .live }
        let ext = url.pathExtension.lowercased()
        if ["mp4", "mkv", "avi", "mov", "m4v", "wmv", "flv", "webm"].contains(ext) { return .movie }
        return .live
    }

    /// Sépare la partie attributs du nom affiché (après la première virgule hors guillemets).
    static func splitInfo(_ body: String) -> (String, String) {
        var inQuotes = false
        for index in body.indices {
            let char = body[index]
            if char == "\"" { inQuotes.toggle() }
            if char == "," && !inQuotes {
                let attrs = String(body[..<index])
                let name = String(body[body.index(after: index)...])
                return (attrs, name)
            }
        }
        return (body, "")
    }

    /// Extrait les paires `clé="valeur"` (ou `clé=valeur`) d'une chaîne.
    static func parseAttributes(_ text: String) -> [String: String] {
        var result: [String: String] = [:]
        let chars = Array(text)
        var i = 0
        while i < chars.count {
            // Avance jusqu'au début d'une clé.
            while i < chars.count, chars[i] == " " || chars[i] == "\t" { i += 1 }
            let keyStart = i
            while i < chars.count, chars[i] != "=", chars[i] != " ", chars[i] != "\t" { i += 1 }
            guard i < chars.count, chars[i] == "=" else {
                // Pas une paire (ex. la durée « -1 ») : on passe au mot suivant.
                while i < chars.count, chars[i] != " ", chars[i] != "\t" { i += 1 }
                continue
            }
            let key = String(chars[keyStart..<i]).lowercased()
            i += 1 // saute '='
            var value = ""
            if i < chars.count, chars[i] == "\"" {
                i += 1
                let valueStart = i
                while i < chars.count, chars[i] != "\"" { i += 1 }
                value = String(chars[valueStart..<min(i, chars.count)])
                i += 1 // saute le guillemet fermant
            } else {
                let valueStart = i
                while i < chars.count, chars[i] != " ", chars[i] != "\t" { i += 1 }
                value = String(chars[valueStart..<i])
            }
            if !key.isEmpty { result[key] = value.trimmingCharacters(in: .whitespaces) }
        }
        return result
    }
}
