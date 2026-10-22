import SwiftUI
import Observation
import KastideoCore

/// Règle d'alerte : mot-clé dans le titre, thème (sur les chaînes favorites) ou programme précis.
struct AlertRule: Codable, Identifiable, Hashable {
    enum Kind: Codable, Hashable {
        case keyword(String)
        case themeOnFavorites(ContentTheme)
        case programme(id: String, title: String, channel: String, start: Date)
    }
    var id = UUID()
    var kind: Kind

    var label: String {
        switch kind {
        case .keyword(let word): return String(localized: "Titre contenant « \(word) »")
        case .themeOnFavorites(let theme): return String(localized: "\(theme.label) sur mes chaînes favorites")
        case .programme(_, let title, let channel, let start):
            return "\(title) — \(channel), \(start.formatted(date: .abbreviated, time: .shortened))"
        }
    }
}

/// Alerte déclenchée (bandeau dans la fenêtre).
struct ProgramAlert: Identifiable, Equatable {
    let id = UUID()
    let programme: Programme
    let channel: MediaItem
}

/// Surveille le guide TV et prévient quand un programme recherché commence (2 minutes avant).
@MainActor
@Observable
final class ProgramAlertCenter {
    private(set) var rules: [AlertRule] = []
    var current: ProgramAlert?
    @ObservationIgnored private var notified = Set<String>()
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private weak var store: LibraryStore?
    private static let key = "alerts.rules.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([AlertRule].self, from: data) {
            rules = decoded.filter {
                if case .programme(_, _, _, let start) = $0.kind { return start > Date().addingTimeInterval(-3600) }
                return true
            }
        }
    }

    func start(store: LibraryStore) {
        self.store = store
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                self?.check()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    // MARK: Règles

    func add(_ kind: AlertRule.Kind) {
        guard !rules.contains(where: { $0.kind == kind }) else { return }
        rules.append(AlertRule(kind: kind))
        save()
    }

    func remove(_ rule: AlertRule) {
        rules.removeAll { $0.id == rule.id }
        save()
    }

    func isWatching(_ programme: Programme) -> Bool {
        rules.contains { if case .programme(let id, _, _, _) = $0.kind { return id == programme.id } else { return false } }
    }

    func toggleOneShot(_ programme: Programme, channel: MediaItem) {
        if let rule = rules.first(where: { if case .programme(let id, _, _, _) = $0.kind { return id == programme.id } else { return false } }) {
            remove(rule)
        } else {
            add(.programme(id: programme.id, title: programme.title, channel: TMDB.cleanTitle(channel.name).title, start: programme.start))
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(rules) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    // MARK: Surveillance

    private func check() {
        guard let store, !rules.isEmpty else { return }
        let now = Date()
        let favorites = Set(store.favoriteIDs)
        for group in store.liveGroups {
            for programme in store.epg.programmes(for: group.epgID)
            where programme.start > now.addingTimeInterval(-60) && programme.start <= now.addingTimeInterval(120) {
                guard !notified.contains(programme.id),
                      let rule = rules.first(where: { matches($0, programme, group, favorites) }) else { continue }
                notified.insert(programme.id)
                let channel = group.preferred
                current = ProgramAlert(programme: programme, channel: channel)
                Notifier.post(String(localized: "C'est l'heure : \(programme.title)"),
                              String(localized: "\(TMDB.cleanTitle(channel.name).title) à \(programme.start.formatted(date: .omitted, time: .shortened))"))
                if case .programme = rule.kind { remove(rule) }
            }
        }
    }

    private func matches(_ rule: AlertRule, _ programme: Programme, _ group: LiveChannelGroup, _ favorites: Set<String>) -> Bool {
        switch rule.kind {
        case .keyword(let word):
            return programme.title.range(of: word, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        case .themeOnFavorites(let theme):
            return group.variants.contains { favorites.contains($0.id) } && (programme.theme ?? group.theme) == theme
        case .programme(let id, _, _, _):
            return id == programme.id
        }
    }
}

/// Bandeau d'alerte de programme.
struct ProgramAlertBanner: View {
    @Environment(ProgramAlertCenter.self) private var alerts
    @Environment(NavigationModel.self) private var navigation

    var body: some View {
        if let alert = alerts.current {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill").font(.title2).foregroundStyle(KastideoPalette.orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text(alert.programme.title).font(.headline).lineLimit(1)
                    Text("\(TMDB.cleanTitle(alert.channel.name).title) · \(alert.programme.start.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Button("Fermer") { alerts.current = nil }
                Button("Regarder") {
                    navigation.watchLive(alert.channel)
                    alerts.current = nil
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: 620)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(radius: 10, y: 3)
            .padding(.top, 70)
            .transition(.move(edge: .top).combined(with: .opacity))
            .task(id: alert.id) {
                try? await Task.sleep(for: .seconds(60))
                if alerts.current?.id == alert.id { alerts.current = nil }
            }
        }
    }
}

/// Gestion des alertes.
struct AlertRulesSheet: View {
    @Environment(ProgramAlertCenter.self) private var alerts
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var theme: ContentTheme = .sport

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Alertes de programme").font(.title3.weight(.semibold))
            Text("Kastideo vous prévient (notification et bandeau) deux minutes avant le début d'un programme correspondant, d'après le guide TV.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                TextField("Mot du titre (ex. PSG, Ligue des champions, Formule 1)", text: $keyword)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addKeyword)
                Button("Ajouter", action: addKeyword).disabled(keyword.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            HStack {
                Picker("Thème sur mes chaînes favorites", selection: $theme) {
                    ForEach(ContentTheme.browsable) { Text($0.label).tag($0) }
                }
                Button("Ajouter") { alerts.add(.themeOnFavorites(theme)) }
            }
            List {
                if alerts.rules.isEmpty {
                    Text("Aucune alerte. Vous pouvez aussi faire un clic droit sur un programme de « Ce soir ».").foregroundStyle(.secondary)
                }
                ForEach(alerts.rules) { rule in
                    HStack {
                        Image(systemName: "bell")
                        Text(rule.label).lineLimit(1)
                        Spacer()
                        Button { alerts.remove(rule) } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                    }
                }
            }
            .frame(minHeight: 160)
            HStack {
                Spacer()
                Button("Terminé") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 520, height: 460)
    }

    private func addKeyword() {
        let word = keyword.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty else { return }
        alerts.add(.keyword(word))
        keyword = ""
    }
}
