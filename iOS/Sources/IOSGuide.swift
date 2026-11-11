import SwiftUI
import KastideoCore

/// Guide TV par créneau : on choisit le jour et l'heure, chaque chaîne montre son programme à ce moment.
/// Les jours passés (replay du fournisseur) sont proposés selon Réglages > Replay.
struct IOSGuideView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @State private var dayOffset = 0
    /// nil : « maintenant » (aujourd'hui) ou 20 h (autres jours).
    @State private var hour: Int?
    @State private var scope: Scope?
    @State private var guideOnly = true
    @State private var search = ""

    enum Scope: Hashable {
        case favorites, all
        case category(String)
    }

    private static let hours = [8, 12, 14, 18, 20, 21, 22, 23]

    private var effectiveScope: Scope {
        scope ?? (store.favoriteIDs.contains { store.item(id: $0)?.kind == .live } ? .favorites : .all)
    }

    private var channels: [MediaItem] {
        var list: [MediaItem]
        switch effectiveScope {
        case .favorites: list = store.items(for: .favorites).filter { $0.kind == .live }
        case .all: list = store.items(for: .all(.live))
        case .category(let name): list = store.items(for: .category(.live, name))
        }
        if guideOnly { list = list.filter { store.epg.hasProgrammes(for: $0.epgID) } }
        let key = search.kastideoSearchKey
        if !key.isEmpty { list = list.filter { $0.searchKey.contains(key) } }
        return list
    }

    private var pastDays: Int { ReplaySettings.enabled ? ReplaySettings.guideDays : 1 }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let at = moment(now: context.date)
            let list = channels
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    dayChips
                    hourChips
                }
                .padding(.vertical, 8)
                List {
                    ForEach(list.prefix(400)) { channel in
                        row(channel, at: at)
                    }
                    if list.count > 400 {
                        Text("Affinez la recherche ou choisissez une catégorie pour voir les \(list.count - 400) autres chaînes.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if list.isEmpty {
                        ContentUnavailableView("Aucune chaîne", systemImage: "calendar",
                                               description: Text(store.epg.isEmpty
                                                                 ? String(localized: "Le guide TV n'est pas encore chargé. Tirez pour actualiser depuis l'accueil.")
                                                                 : String(localized: "Aucune chaîne avec guide dans cette sélection.")))
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Rechercher une chaîne")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { scope = .favorites } label: { check(String(localized: "Favoris"), effectiveScope == .favorites) }
                    Button { scope = .all } label: { check(String(localized: "Toutes les chaînes"), effectiveScope == .all) }
                    Divider()
                    Toggle("Seulement celles avec un guide", isOn: $guideOnly)
                    Divider()
                    ForEach(store.categoriesByKind[.live] ?? [], id: \.self) { name in
                        Button { scope = .category(name) } label: { check(name, effectiveScope == .category(name)) }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }

    @ViewBuilder
    private func check(_ title: String, _ on: Bool) -> some View {
        if on { Label(title, systemImage: "checkmark") } else { Text(title) }
    }

    // MARK: Créneau

    private func moment(now: Date) -> Date {
        let calendar = Calendar.current
        if dayOffset == 0 && hour == nil { return now }
        let base = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) ?? now
        return calendar.date(bySettingHour: hour ?? 20, minute: 0, second: 0, of: base) ?? base
    }

    private func dayLabel(_ offset: Int) -> String {
        switch offset {
        case 0: return String(localized: "Aujourd'hui")
        case 1: return String(localized: "Demain")
        case -1: return String(localized: "Hier")
        default:
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            return date.formatted(.dateTime.weekday(.abbreviated).day())
        }
    }

    private var dayChips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(-pastDays...3, id: \.self) { offset in
                        chip(dayLabel(offset), selected: dayOffset == offset) {
                            dayOffset = offset
                            if offset != 0 && hour == nil { hour = 20 }
                        }
                        .id(offset)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear { proxy.scrollTo(dayOffset, anchor: .center) }
        }
    }

    private var hourChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if dayOffset == 0 {
                    chip(String(localized: "Maintenant"), selected: hour == nil) { hour = nil }
                }
                ForEach(Self.hours, id: \.self) { value in
                    chip(String(format: "%02d:00", value), selected: hour == value || (hour == nil && dayOffset != 0 && value == 20)) {
                        hour = value
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(selected ? IOSPalette.orange.opacity(0.28) : Color.secondary.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Lignes

    private func row(_ channel: MediaItem, at: Date) -> some View {
        let programme = store.epg.current(for: channel.epgID, at: at)
        let following = store.epg.upcoming(for: channel.epgID, after: programme?.stop ?? at, limit: 1).first
        return Button {
            if let programme {
                ui.programme = ProgrammeRef(channel: channel, programme: programme)
            } else {
                ui.play(channel, store: store, playback: playback)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                IOSProgrammeRow(channel: channel, programme: programme, now: at)
                if programme == nil {
                    Text("Programme non disponible").font(.caption).foregroundStyle(.secondary).padding(.leading, 68)
                }
                if let following {
                    Text("Ensuite · \(following.start.formatted(date: .omitted, time: .shortened)) \(following.title)")
                        .font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                        .padding(.leading, 68)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Regarder en direct", systemImage: "play.fill") { ui.play(channel, store: store, playback: playback) }
            Button(store.isFavorite(channel.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris"),
                   systemImage: store.isFavorite(channel.id) ? "star.slash" : "star") {
                store.toggleFavorite(channel.id)
            }
            replayMenu(channel)
        }
    }

    @ViewBuilder
    private func replayMenu(_ channel: MediaItem) -> some View {
        let past = store.replayProgrammes(of: channel)
        if !past.isEmpty {
            Menu("Revoir (replay)") {
                ForEach(past) { programme in
                    Button("\(programme.start.formatted(.dateTime.weekday(.abbreviated).hour().minute())) — \(programme.title)") {
                        ui.playReplay(channel: channel, programme: programme, store: store, playback: playback)
                    }
                }
            }
        }
    }
}
