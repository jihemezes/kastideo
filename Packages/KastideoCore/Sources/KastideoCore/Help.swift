import Foundation

/// Aide intégrée : source Markdown unique, partagée avec la version Windows / Linux.
///
/// Format : `# Rubrique`, puis `## Titre de la page {#identifiant}`. Les blocs
/// `<!--mac-->…<!--/mac-->` et `<!--pc-->…<!--/pc-->` ne sont gardés que sur la plateforme concernée.
/// Les liens `[texte](help:identifiant)` renvoient à une autre page, `![texte](img:nom)` insère un schéma.
public enum HelpPlatform: Sendable {
    case mac, pc
}

public struct HelpPage: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let group: String
    public let body: String
}

public struct HelpGroup: Identifiable, Hashable, Sendable {
    public var id: String { title }
    public let title: String
    public let pages: [HelpPage]
}

/// Élément de contenu d'une page.
public enum HelpBlock: Equatable, Sendable {
    case heading(String)
    case paragraph(String)
    case bullet(level: Int, text: String)
    case numbered(Int, String)
    case note(String)
    case image(name: String, alt: String)
    case rule
}

public enum HelpDocument {
    /// Découpe l'aide en rubriques et pages pour la plateforme donnée (les pages vides sont masquées).
    public static func parse(_ source: String, platform: HelpPlatform) -> [HelpGroup] {
        let text = filter(source, platform: platform)
        var groups: [HelpGroup] = []
        var groupTitle = ""
        var pages: [HelpPage] = []
        var current: (id: String, title: String, lines: [String])?

        func closePage() {
            guard let page = current else { return }
            current = nil
            let body = page.lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty { pages.append(HelpPage(id: page.id, title: page.title, group: groupTitle, body: body)) }
        }
        func closeGroup() {
            closePage()
            if !pages.isEmpty { groups.append(HelpGroup(title: groupTitle, pages: pages)) }
            pages = []
        }
        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix("## ") {
                closePage()
                var title = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var id = title
                if let open = title.range(of: "{#", options: .backwards), title.hasSuffix("}") {
                    id = String(title[open.upperBound...].dropLast())
                    title = String(title[..<open.lowerBound]).trimmingCharacters(in: .whitespaces)
                }
                current = (id, title, [])
            } else if line.hasPrefix("# ") {
                closeGroup()
                groupTitle = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            } else if current != nil {
                current?.lines.append(line)
            }
        }
        closeGroup()
        return groups
    }

    /// Retire les blocs de l'autre plateforme et les balises de la plateforme courante.
    static func filter(_ source: String, platform: HelpPlatform) -> String {
        let keep = platform == .mac ? "mac" : "pc"
        let drop = platform == .mac ? "pc" : "mac"
        var text = source
        text = text.replacingOccurrences(of: "(?s)<!--\(drop)-->.*?<!--/\(drop)-->", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<!--\(keep)-->", with: "")
        text = text.replacingOccurrences(of: "<!--/\(keep)-->", with: "")
        return text
    }

    // MARK: Contenu d'une page

    public static func blocks(_ body: String) -> [HelpBlock] {
        var result: [HelpBlock] = []
        var paragraph: [String] = []
        var note: [String] = []
        func flushParagraph() {
            if !paragraph.isEmpty { result.append(.paragraph(paragraph.joined(separator: " "))) }
            paragraph = []
        }
        func flushNote() {
            if !note.isEmpty { result.append(.note(note.joined(separator: " "))) }
            note = []
        }
        for raw in body.components(separatedBy: "\n") {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { flushParagraph(); flushNote(); continue }
            if trimmed.hasPrefix("> ") {
                flushParagraph()
                note.append(String(trimmed.dropFirst(2)))
                continue
            }
            flushNote()
            if trimmed.hasPrefix("### ") {
                flushParagraph()
                result.append(.heading(String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("!["), let image = parseImage(trimmed) {
                flushParagraph()
                result.append(image)
            } else if trimmed == "---" {
                flushParagraph()
                result.append(.rule)
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushParagraph()
                let indent = raw.prefix { $0 == " " }.count
                result.append(.bullet(level: indent / 2, text: String(trimmed.dropFirst(2))))
            } else if let dot = trimmed.firstIndex(of: "."), !trimmed[..<dot].isEmpty,
                      trimmed[..<dot].allSatisfy(\.isNumber), trimmed[trimmed.index(after: dot)...].hasPrefix(" "),
                      let number = Int(trimmed[..<dot]) {
                flushParagraph()
                result.append(.numbered(number, String(trimmed[trimmed.index(dot, offsetBy: 2)...])))
            } else {
                paragraph.append(trimmed)
            }
        }
        flushParagraph()
        flushNote()
        return result
    }

    private static func parseImage(_ line: String) -> HelpBlock? {
        guard let altEnd = line.range(of: "](img:"), line.hasSuffix(")") else { return nil }
        let alt = String(line[line.index(line.startIndex, offsetBy: 2)..<altEnd.lowerBound])
        let name = String(line[altEnd.upperBound...].dropLast())
        return name.isEmpty ? nil : .image(name: name, alt: alt)
    }

    // MARK: Recherche

    /// Texte sans majuscules ni accents, pour comparer.
    public static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Pages contenant tous les mots saisis (titre d'abord, puis nombre d'occurrences). Moins de 2 lettres : aucune.
    public static func search(_ groups: [HelpGroup], query: String) -> [HelpPage] {
        let terms = fold(query).split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard !terms.isEmpty, terms.joined().count >= 2 else { return [] }
        var scored: [(HelpPage, Int)] = []
        for page in groups.flatMap(\.pages) {
            let title = fold(page.title)
            let body = fold(page.body)
            var score = 0
            var all = true
            for term in terms {
                let inTitle = title.contains(term)
                let count = body.components(separatedBy: term).count - 1
                if !inTitle && count == 0 { all = false; break }
                score += (inTitle ? 50 : 0) + min(count, 20)
            }
            if all { scored.append((page, score)) }
        }
        return scored.sorted { $0.1 > $1.1 }.map(\.0)
    }

    /// Extrait du texte autour du premier mot trouvé (pour la liste des résultats).
    public static func snippet(_ page: HelpPage, query: String, length: Int = 90) -> String {
        let plain = page.body
            .replacingOccurrences(of: "\\[([^\\]]*)\\]\\([^)]*\\)", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "[*`>#!]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard let term = fold(query).split(whereSeparator: { $0.isWhitespace }).first.map(String.init) else { return "" }
        let range = plain.range(of: term, options: [.caseInsensitive, .diacriticInsensitive])
        let start = range.map { plain.index($0.lowerBound, offsetBy: -30, limitedBy: plain.startIndex) ?? plain.startIndex } ?? plain.startIndex
        var begin = start
        if begin > plain.startIndex, let space = plain[begin...].firstIndex(of: " "),
           plain.distance(from: begin, to: space) < 15 {
            begin = plain.index(after: space)
        }
        let end = plain.index(begin, offsetBy: length, limitedBy: plain.endIndex) ?? plain.endIndex
        return (begin > plain.startIndex ? "…" : "") + plain[begin..<end].trimmingCharacters(in: .whitespaces) + (end < plain.endIndex ? "…" : "")
    }
}
