import SwiftUI
import KastideoCore

/// Aide intégrée : pages propres à l'iPhone et à l'iPad en tête, puis le guide complet de Kastideo.
struct IOSHelpView: View {
    @State private var groups: [HelpGroup] = []
    @State private var query = ""
    @State private var path: [String] = []

    /// Pages qui concernent directement l'iPhone et l'iPad.
    private static let featured = ["ios", "icloud", "tmdb-perso", "page-depart"]

    private var allPages: [HelpPage] { groups.flatMap(\.pages) }
    private var featuredPages: [HelpPage] { Self.featured.compactMap { id in allPages.first { $0.id == id } } }
    private var results: [HelpPage] { HelpDocument.search(groups, query: query) }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                    Section("Résultats") {
                        if results.isEmpty { Text("Aucun résultat").foregroundStyle(.secondary) }
                        ForEach(results) { page in
                            NavigationLink(value: page.id) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(page.title).font(.body.weight(.medium))
                                    Text(HelpDocument.snippet(page, query: query)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                }
                            }
                        }
                    }
                } else {
                    Section("Sur iPhone et iPad") {
                        ForEach(featuredPages) { page in
                            NavigationLink(value: page.id) { Label(page.title, systemImage: "iphone") }
                        }
                    }
                    ForEach(groups) { group in
                        Section(group.title) {
                            ForEach(group.pages) { page in
                                NavigationLink(value: page.id) { Text(page.title) }
                            }
                        }
                    }
                    Section {
                        EmptyView()
                    } footer: {
                        Text("Le guide est commun à toutes les versions de Kastideo : certaines indications (menus, raccourcis clavier) concernent le Mac, Windows ou Linux. Une aide dédiée à l'iPhone et à l'iPad viendra compléter cette section.")
                    }
                }
            }
            .searchable(text: $query, prompt: "Rechercher dans l'aide")
            .navigationTitle("Aide")
            .navigationDestination(for: String.self) { id in
                if let page = allPages.first(where: { $0.id == id }) {
                    IOSHelpPageView(page: page, query: query)
                } else {
                    Text("Aide introuvable.")
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "help" {
                    let id = String(url.absoluteString.dropFirst("help:".count))
                    if allPages.contains(where: { $0.id == id }) { path.append(id) }
                    return .handled
                }
                return .systemAction
            })
            .onAppear {
                if groups.isEmpty { groups = Self.load() }
            }
        }
    }

    static func load() -> [HelpGroup] {
        let language = (Bundle.main.preferredLocalizations.first ?? "fr") == "en" ? "en" : "fr"
        guard let url = Bundle.main.url(forResource: "aide-\(language)", withExtension: "md")
                ?? Bundle.main.url(forResource: "aide-fr", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return [HelpGroup(title: "", pages: [HelpPage(id: "erreur", title: String(localized: "Aide"),
                                                          group: "", body: String(localized: "Aide introuvable."))])]
        }
        return HelpDocument.parse(text, platform: .mac)
    }
}

struct IOSHelpPageView: View {
    let page: HelpPage
    let query: String

    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(text)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(page.group.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(Color.accentColor)
                Text(page.title).font(.largeTitle.weight(.bold)).padding(.bottom, 4)
                ForEach(Array(HelpDocument.blocks(page.body).enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .padding(20)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func blockView(_ block: HelpBlock) -> some View {
        switch block {
        case .heading(let text):
            Text(inline(text)).font(.title3.weight(.semibold)).padding(.top, 10)
        case .paragraph(let text):
            Text(inline(text)).fixedSize(horizontal: false, vertical: true)
        case .bullet(let level, let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(level == 0 ? "•" : "◦").foregroundStyle(Color.accentColor)
                Text(inline(text)).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 6 + CGFloat(level) * 16)
        case .numbered(let number, let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(number).").monospacedDigit().foregroundStyle(Color.accentColor)
                    .frame(minWidth: 22, alignment: .trailing)
                Text(inline(text)).fixedSize(horizontal: false, vertical: true)
            }
        case .note(let text):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb").foregroundStyle(Color.accentColor)
                Text(inline(text)).fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
        case .image:
            EmptyView()
        case .rule:
            Divider().padding(.vertical, 6)
        }
    }
}
