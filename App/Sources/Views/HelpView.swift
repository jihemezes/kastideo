import SwiftUI
import AppKit
import KastideoCore

/// Point d'entrée de l'aide : permet d'ouvrir la fenêtre d'aide directement sur une page.
@MainActor
@Observable
final class HelpCenter {
    static let shared = HelpCenter()
    /// Page demandée (identifiant) ; consommée par la fenêtre d'aide.
    var requested: String?

    /// Page d'aide qui correspond à l'écran affiché.
    nonisolated static func pageID(for browse: Browse?) -> String {
        switch browse {
        case .home, .none: return "accueil"
        case .all(let kind), .category(let kind, _):
            return kind == .live ? "interfaces" : "colonnes"
        case .favorites, .recents: return "favoris"
        case .recordings: return "enregistrements"
        case .guide: return "guide-grille"
        case .themes: return "direct-theme"
        case .library: return "mes-videos"
        case .youtube: return "youtube"
        }
    }
}

/// Bouton « ? » : ouvre l'aide à la page de l'écran courant (ou à la page donnée).
struct HelpButton: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(NavigationModel.self) private var navigation
    var page: String?
    /// Présentation discrète pour l'accueil (fond sombre).
    var onDark = false

    private func open() {
        HelpCenter.shared.requested = page ?? HelpCenter.pageID(for: navigation.browse)
        openWindow(id: "help")
    }

    @ViewBuilder
    var body: some View {
        if onDark {
            Button(action: open) {
                Image(systemName: "questionmark.circle")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .buttonStyle(.plain)
            .help("Aide sur cet écran (⌘?)")
        } else {
            Button(action: open) {
                Label("Aide", systemImage: "questionmark.circle")
            }
            .help("Aide sur cet écran (⌘?)")
        }
    }
}

/// Lien « Comment faire ? » qui ouvre l'aide à une page précise.
struct HelpLink: View {
    @Environment(\.openWindow) private var openWindow
    let title: LocalizedStringKey
    let page: String

    var body: some View {
        Button {
            HelpCenter.shared.requested = page
            openWindow(id: "help")
        } label: {
            Label(title, systemImage: "questionmark.circle")
        }
        .buttonStyle(.link)
    }
}

/// Aide intégrée : sommaire à gauche, recherche, page à droite.
struct HelpView: View {
    @State private var groups: [HelpGroup] = []
    @State private var selected: String = ""
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var pages: [HelpPage] { groups.flatMap(\.pages) }
    private var terms: [String] {
        HelpDocument.fold(query).split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }
    private var searching: Bool { terms.joined().count >= 2 }
    private var results: [HelpPage] { HelpDocument.search(groups, query: query) }
    private var page: HelpPage? { pages.first { $0.id == selected } ?? pages.first }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 270)
            Divider()
            content
        }
        .frame(minWidth: 760, minHeight: 480)
        .onAppear {
            groups = HelpView.load()
            consumeRequest()
            if selected.isEmpty { selected = pages.first?.id ?? "" }
        }
        .onChange(of: HelpCenter.shared.requested) { _, _ in consumeRequest() }
        .onChange(of: query) { _, _ in
            if searching, let first = results.first, !results.contains(where: { $0.id == selected }) {
                selected = first.id
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "help" {
                select(String(url.absoluteString.dropFirst("help:".count)))
                return .handled
            }
            return .systemAction
        })
    }

    private func consumeRequest() {
        guard let id = HelpCenter.shared.requested else { return }
        HelpCenter.shared.requested = nil
        query = ""
        select(id)
    }

    private func select(_ id: String) {
        if pages.contains(where: { $0.id == id }) { selected = id }
    }

    static func load() -> [HelpGroup] {
        let language = AppLanguage.effectiveCode == "en" ? "en" : "fr"
        guard let url = Bundle.main.url(forResource: "aide.\(language)", withExtension: "md")
                ?? Bundle.main.url(forResource: "aide.fr", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return [HelpGroup(title: "", pages: [HelpPage(id: "erreur", title: String(localized: "Aide"),
                                                          group: "", body: String(localized: "Aide introuvable."))])]
        }
        return HelpDocument.parse(text, platform: .mac)
    }

    // MARK: Colonne de gauche

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Rechercher dans l'aide", text: $query)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .padding(10)

            if searching {
                if results.isEmpty {
                    Spacer()
                    Text("Aucun résultat").foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List(selection: Binding(get: { selected as String? }, set: { if let id = $0 { selected = id } })) {
                        ForEach(results) { result in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title).font(.callout.weight(.semibold))
                                Text(result.group).font(.caption2).foregroundStyle(.secondary)
                                Text(HelpDocument.snippet(result, query: query))
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                            .tag(result.id as String?)
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.sidebar)
                }
            } else {
                List(selection: Binding(get: { selected as String? }, set: { if let id = $0 { selected = id } })) {
                    ForEach(groups) { group in
                        Section(group.title) {
                            ForEach(group.pages) { entry in
                                Text(entry.title).tag(entry.id as String?)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: Page

    @ViewBuilder
    private var content: some View {
        if let page {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(page.group.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text(page.title)
                        .font(.largeTitle.weight(.bold))
                        .padding(.bottom, 4)
                    ForEach(Array(HelpDocument.blocks(page.body).enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                    Divider().padding(.top, 16)
                    pager(for: page)
                }
                .padding(32)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
                .textSelection(.enabled)
            }
            .id(page.id)
        } else {
            Text("Aide introuvable.").frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func pager(for page: HelpPage) -> some View {
        let all = pages
        let index = all.firstIndex(of: page) ?? 0
        return HStack {
            if index > 0 {
                Button { selected = all[index - 1].id } label: {
                    Label(all[index - 1].title, systemImage: "chevron.left")
                }
            }
            Spacer()
            if index + 1 < all.count {
                Button { selected = all[index + 1].id } label: {
                    HStack(spacing: 4) { Text(all[index + 1].title); Image(systemName: "chevron.right") }
                }
            }
        }
        .buttonStyle(.link)
    }

    // MARK: Blocs

    private func inline(_ text: String) -> AttributedString {
        var result = (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(text)
        guard searching else { return result }
        for term in terms {
            var from = result.startIndex
            while from < result.endIndex,
                  let found = result[from...].range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) {
                result[found].backgroundColor = Color.yellow.opacity(0.4)
                from = found.upperBound
            }
        }
        return result
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
            .padding(.leading, 8 + CGFloat(level) * 18)
        case .numbered(let number, let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(number).").monospacedDigit().foregroundStyle(Color.accentColor)
                    .frame(minWidth: 22, alignment: .trailing)
                Text(inline(text)).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 4)
        case .note(let text):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb").foregroundStyle(Color.accentColor)
                Text(inline(text)).fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
        case .image(let name, let alt):
            helpImage(name, alt: alt)
        case .rule:
            Divider().padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func helpImage(_ name: String, alt: String) -> some View {
        let language = AppLanguage.effectiveCode == "en" ? "en" : "fr"
        if let url = Bundle.main.url(forResource: "help-\(name)-\(language)", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 620)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(alt)
                .padding(.vertical, 6)
        }
    }
}
