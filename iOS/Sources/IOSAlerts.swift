import SwiftUI
import UserNotifications
import KastideoCore

/// Règle d'alerte : mot-clé dans le titre, thème (sur les chaînes favorites) ou programme précis.
struct IOSAlertRule: Codable, Identifiable, Hashable {
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

    var icon: String {
        switch kind {
        case .keyword: return "magnifyingglass"
        case .themeOnFavorites: return "star"
        case .programme: return "bell"
        }
    }
}

/// Prévient quand un programme recherché commence. Les alertes sont programmées à l'avance comme notifications locales :
/// elles arrivent même application fermée (la liste est recalculée à chaque ouverture et toutes les 10 minutes).
@MainActor
@Observable
final class IOSAlertCenter {
    private(set) var rules: [IOSAlertRule] = []
    private(set) var scheduledCount = 0
    private static let key = "ios.alerts.v1"
    static let leadKey = "ios.alerts.lead"
    private static let prefix = "kastideo.alert."
    /// iOS garde au plus 64 notifications programmées.
    private static let limit = 60
    private static let horizon: TimeInterval = 48 * 3600

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([IOSAlertRule].self, from: data) {
            rules = decoded.filter {
                if case .programme(_, _, _, let start) = $0.kind { return start > Date() }
                return true
            }
        }
    }

    static var leadMinutes: Int { UserDefaults.standard.object(forKey: leadKey) as? Int ?? 2 }

    func addKeyword(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        add(.keyword(trimmed))
    }

    func addTheme(_ theme: ContentTheme) {
        add(.themeOnFavorites(theme))
    }

    private func add(_ kind: IOSAlertRule.Kind) {
        guard !rules.contains(where: { $0.kind == kind }) else { return }
        IOSNotifier.requestAuthorization()
        rules.append(IOSAlertRule(kind: kind))
        save()
    }

    func remove(_ rule: IOSAlertRule) {
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

    // MARK: Programmation

    /// Recalcule les notifications des 48 prochaines heures.
    func reschedule(store: LibraryStore) {
        let center = UNUserNotificationCenter.current()
        let now = Date()
        let lead = TimeInterval(Self.leadMinutes * 60)
        let favorites = Set(store.favoriteIDs)
        var planned: [(date: Date, id: String, title: String, body: String, channelID: String)] = []
        if !rules.isEmpty {
            for group in store.liveGroups {
                for programme in store.epg.programmes(for: group.epgID)
                where programme.start > now.addingTimeInterval(lead + 5) && programme.start < now.addingTimeInterval(Self.horizon) {
                    guard rules.contains(where: { matches($0, programme, group, favorites) }) else { continue }
                    let channel = group.preferred
                    planned.append((programme.start.addingTimeInterval(-lead), Self.prefix + programme.id + "." + channel.id,
                                    String(localized: "Bientôt : \(programme.title)"),
                                    String(localized: "\(TMDB.cleanTitle(channel.name).title) à \(programme.start.formatted(date: .omitted, time: .shortened))"),
                                    channel.id))
                }
            }
        }
        planned.sort { $0.date < $1.date }
        let kept = Array(planned.prefix(Self.limit))
        scheduledCount = kept.count
        center.getPendingNotificationRequests { pending in
            let old = pending.map(\.identifier).filter { $0.hasPrefix(Self.prefix) }
            center.removePendingNotificationRequests(withIdentifiers: old)
            for entry in kept {
                let content = UNMutableNotificationContent()
                content.title = entry.title
                content.body = entry.body
                content.sound = .default
                content.userInfo = ["channelID": entry.channelID]
                let seconds = max(entry.date.timeIntervalSinceNow, 1)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
                center.add(UNNotificationRequest(identifier: entry.id, content: content, trigger: trigger))
            }
        }
        // Les alertes sur un programme précis déjà passées sont retirées.
        let before = rules.count
        rules.removeAll { if case .programme(_, _, _, let start) = $0.kind { return start < now.addingTimeInterval(-3600) } else { return false } }
        if rules.count != before { save() }
    }

    private func matches(_ rule: IOSAlertRule, _ programme: Programme, _ group: LiveChannelGroup, _ favorites: Set<String>) -> Bool {
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

/// Réglages > Alertes de programmes.
struct IOSAlertsView: View {
    @Environment(IOSAlertCenter.self) private var alerts
    @Environment(LibraryStore.self) private var store
    @AppStorage(IOSAlertCenter.leadKey) private var lead = 2
    @State private var keyword = ""
    @State private var showKeyword = false

    var body: some View {
        List {
            Section {
                if alerts.rules.isEmpty {
                    Text("Aucune alerte. Ajoutez un mot-clé (« Roland-Garros », « Tour de France »…) ou un thème, ou touchez « Me prévenir » dans la fiche d'un programme.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(alerts.rules) { rule in
                    Label(rule.label, systemImage: rule.icon)
                        .swipeActions {
                            Button(role: .destructive) { alerts.remove(rule); alerts.reschedule(store: store) } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text("Mes alertes")
            } footer: {
                if alerts.scheduledCount > 0 {
                    Text("\(alerts.scheduledCount) notification(s) programmée(s) dans les 48 prochaines heures.")
                }
            }

            Section("Ajouter") {
                Button { showKeyword = true } label: { Label("Mot-clé dans le titre…", systemImage: "magnifyingglass") }
                Menu {
                    ForEach(ContentTheme.browsable) { theme in
                        Button { add { alerts.addTheme(theme) } } label: { Label(theme.label, systemImage: theme.icon) }
                    }
                } label: {
                    Label("Thème sur mes chaînes favorites…", systemImage: "star")
                }
            }

            Section {
                Picker("Prévenir", selection: $lead) {
                    Text("À l'heure").tag(0)
                    Text("2 minutes avant").tag(2)
                    Text("5 minutes avant").tag(5)
                    Text("10 minutes avant").tag(10)
                    Text("30 minutes avant").tag(30)
                }
                .onChange(of: lead) { _, _ in alerts.reschedule(store: store) }
            } footer: {
                Text("Les alertes reposent sur le guide TV de vos sources et sur les notifications de l'iPhone. Touchez une notification pour ouvrir la chaîne.")
            }
        }
        .navigationTitle("Alertes de programmes")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Mot-clé", isPresented: $showKeyword) {
            TextField("Titre contenant…", text: $keyword)
            Button("Ajouter") { let word = keyword; keyword = ""; add { alerts.addKeyword(word) } }
            Button("Annuler", role: .cancel) { keyword = "" }
        } message: {
            Text("Vous serez prévenu quand un programme dont le titre contient ce mot va commencer.")
        }
    }

    private func add(_ action: () -> Void) {
        action()
        alerts.reschedule(store: store)
    }
}
