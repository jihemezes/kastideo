import Foundation

/// Notes de version lues dans le CHANGELOG.md embarqué dans l'application.
struct ReleaseNote: Identifiable, Hashable {
    var version: String
    var date: String?
    var items: [String]
    var id: String { version }
}

enum ReleaseNotes {
    static let lastSeenKey = "lastSeenVersion"

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    static func load() -> [ReleaseNote] {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return parse(text)
    }

    /// Analyse les sections « ## [X.Y.Z] - date » et leurs puces « - … ».
    static func parse(_ text: String) -> [ReleaseNote] {
        var notes: [ReleaseNote] = []
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") {
                var header = String(line.dropFirst(3))
                var date: String?
                if let dash = header.range(of: " - ") {
                    date = String(header[dash.upperBound...]).trimmingCharacters(in: .whitespaces)
                    header = String(header[..<dash.lowerBound])
                }
                let version = header.trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
                notes.append(ReleaseNote(version: version, date: date, items: []))
            } else if line.hasPrefix("- "), !notes.isEmpty {
                notes[notes.count - 1].items.append(String(line.dropFirst(2)))
            }
        }
        return notes
    }

    /// Vrai si l'application vient d'être mise à jour depuis le dernier lancement.
    /// Mémorise la version courante dans tous les cas.
    static func shouldAnnounceUpdate() -> Bool {
        let defaults = UserDefaults.standard
        let current = currentVersion
        let last = defaults.string(forKey: lastSeenKey)
        defaults.set(current, forKey: lastSeenKey)
        if let last { return last != current }
        // Versions antérieures à 0.2.0 : pas de version mémorisée, mais des sources déjà configurées.
        return defaults.data(forKey: "sources.v1") != nil
    }
}
