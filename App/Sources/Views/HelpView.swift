import SwiftUI

/// Aide intégrée : affiche le fichier AIDE.md embarqué dans l'application.
struct HelpView: View {
    @State private var blocks: [HelpBlock] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(blocks) { block in
                    block.view
                }
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
            .textSelection(.enabled)
        }
        .onAppear { blocks = HelpBlock.load() }
    }
}

/// Bloc de texte de l'aide (rendu Markdown simplifié : titres, listes, notes, paragraphes).
struct HelpBlock: Identifiable {
    enum Kind { case h1, h2, h3, bullet, numbered(String), note, paragraph, rule }
    let id: Int
    let kind: Kind
    let text: String

    static func load() -> [HelpBlock] {
        let name = AppLanguage.effectiveCode == "en" ? "AIDE.en" : "AIDE"
        guard let url = Bundle.main.url(forResource: name, withExtension: "md")
                ?? Bundle.main.url(forResource: "AIDE", withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return [HelpBlock(id: 0, kind: .paragraph, text: String(localized: "Aide introuvable."))]
        }
        return parse(content)
    }

    static func parse(_ content: String) -> [HelpBlock] {
        var result: [HelpBlock] = []
        var paragraph: [String] = []
        func flush() {
            if !paragraph.isEmpty {
                result.append(HelpBlock(id: result.count, kind: .paragraph, text: paragraph.joined(separator: " ")))
                paragraph = []
            }
        }
        for raw in content.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { flush(); continue }
            func add(_ kind: Kind, _ text: String) { flush(); result.append(HelpBlock(id: result.count, kind: kind, text: text)) }
            if line.hasPrefix("### ") { add(.h3, String(line.dropFirst(4))) }
            else if line.hasPrefix("## ") { add(.h2, String(line.dropFirst(3))) }
            else if line.hasPrefix("# ") { add(.h1, String(line.dropFirst(2))) }
            else if line.hasPrefix("- ") || line.hasPrefix("* ") { add(.bullet, String(line.dropFirst(2))) }
            else if line.hasPrefix("> ") { add(.note, String(line.dropFirst(2))) }
            else if line == "---" { add(.rule, "") }
            else if let dot = line.firstIndex(of: "."), line[..<dot].allSatisfy(\.isNumber), !line[..<dot].isEmpty,
                    line[line.index(after: dot)...].hasPrefix(" ") {
                add(.numbered(String(line[..<dot])), String(line[line.index(dot, offsetBy: 2)...]))
            }
            else { paragraph.append(line) }
        }
        flush()
        return result
    }

    private var attributed: AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(text)
    }

    @ViewBuilder
    var view: some View {
        switch kind {
        case .h1:
            Text(attributed).font(.largeTitle.weight(.bold)).padding(.bottom, 4)
        case .h2:
            Text(attributed).font(.title2.weight(.semibold)).padding(.top, 14)
        case .h3:
            Text(attributed).font(.headline).padding(.top, 6)
        case .bullet:
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•").foregroundStyle(Color.accentColor)
                Text(attributed)
            }
            .padding(.leading, 8)
        case .numbered(let number):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(number).").monospacedDigit().foregroundStyle(Color.accentColor)
                Text(attributed)
            }
            .padding(.leading, 8)
        case .note:
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb").foregroundStyle(Color.accentColor)
                Text(attributed)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
        case .paragraph:
            Text(attributed).fixedSize(horizontal: false, vertical: true)
        case .rule:
            Divider().padding(.vertical, 6)
        }
    }
}
