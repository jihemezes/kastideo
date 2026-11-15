import SwiftUI
import KastideoCore

/// Aide Apple TV : un guide court, propre à l'Apple TV, dans la langue de l'application.
struct TVHelpView: View {
    @Environment(TVLanguage.self) private var language
    @State private var groups: [HelpGroup] = []

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    Text("Aide introuvable.").foregroundStyle(.secondary)
                }
                ForEach(groups) { group in
                    Section(group.title) {
                        ForEach(group.pages) { page in
                            NavigationLink { TVHelpPageView(page: page) } label: { Text(page.title) }
                        }
                    }
                }
            }
            .navigationTitle("Aide")
        }
        .onAppear { if groups.isEmpty { groups = load() } }
    }

    private func load() -> [HelpGroup] {
        let name = "aide-tv-\(language.helpLanguage)"
        guard let url = Bundle.main.url(forResource: name, withExtension: "md")
                ?? Bundle.main.url(forResource: "aide-tv-en", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return HelpDocument.parse(text, platform: .mac)
    }
}

/// Une page d'aide. Chaque bloc prend le focus : la télécommande fait défiler la page en descendant.
struct TVHelpPageView: View {
    let page: HelpPage

    private func inline(_ text: String) -> AttributedString {
        let plain = text.replacingOccurrences(of: "\\[([^\\]]*)\\]\\([^)]*\\)", with: "$1", options: .regularExpression)
        return (try? AttributedString(markdown: plain, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(plain)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(page.title).font(.largeTitle.weight(.bold)).focusable()
                ForEach(Array(HelpDocument.blocks(page.body).enumerated()), id: \.offset) { _, block in
                    blockView(block).focusable()
                }
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
            .frame(maxWidth: 1400, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func blockView(_ block: HelpBlock) -> some View {
        switch block {
        case .heading(let text):
            Text(inline(text)).font(.title2.weight(.semibold)).padding(.top, 10)
        case .paragraph(let text):
            Text(inline(text)).font(.body).fixedSize(horizontal: false, vertical: true)
        case .bullet(let level, let text):
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(level == 0 ? "•" : "◦").foregroundStyle(TVPalette.orange)
                Text(inline(text)).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, CGFloat(level) * 30)
        case .numbered(let number, let text):
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(number).").monospacedDigit().foregroundStyle(TVPalette.orange)
                Text(inline(text)).fixedSize(horizontal: false, vertical: true)
            }
        case .note(let text):
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "lightbulb").foregroundStyle(TVPalette.orange)
                Text(inline(text)).fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
        case .image:
            EmptyView()
        case .rule:
            Divider().padding(.vertical, 6)
        }
    }
}
