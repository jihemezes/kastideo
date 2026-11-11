import SwiftUI
import KastideoCore

/// Direct par thème : en ce moment, ce soir, toutes les chaînes du thème.
struct IOSThemesView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @AppStorage("ios.themes.mode") private var modeRaw = ThemeMode.now.rawValue
    @State private var theme: ContentTheme?
    @State private var sportKind: SportKind?

    private var mode: ThemeMode { ThemeMode(rawValue: modeRaw) ?? .now }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Picker("Mode", selection: $modeRaw) {
                        ForEach(ThemeMode.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    themeChips(now: now)
                    if theme == .sport { sportChips }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                content(now: now)
            }
        }
    }

    // MARK: Filtres

    private func themeChips(now: Date) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip(nil, count: nil)
                ForEach(ContentTheme.browsable) { item in
                    let count = mode == .channels
                        ? store.liveGroups.filter { $0.theme == item }.count
                        : nowGroups(item, now: now).count
                    if count > 0 || theme == item { chip(item, count: mode == .tonight ? nil : count) }
                }
            }
        }
    }

    private func chip(_ item: ContentTheme?, count: Int?) -> some View {
        let selected = theme == item
        return Button {
            theme = item
            if item != .sport { sportKind = nil }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: item?.icon ?? "square.grid.2x2")
                Text(item?.label ?? String(localized: "Tout"))
                if let count { Text("\(count)").foregroundStyle(.secondary).monospacedDigit() }
            }
            .font(.callout.weight(selected ? .semibold : .regular))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selected ? IOSPalette.orange.opacity(0.28) : Color.secondary.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var sportChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                sportChip(nil)
                ForEach(SportKind.allCases.filter { $0 != .other }) { kind in sportChip(kind) }
            }
        }
    }

    private func sportChip(_ kind: SportKind?) -> some View {
        let selected = sportKind == kind
        return Button { sportKind = kind } label: {
            Text(kind?.label ?? String(localized: "Tous les sports"))
                .font(.caption.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(selected ? IOSPalette.orange.opacity(0.28) : Color.secondary.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Contenu

    @ViewBuilder
    private func content(now: Date) -> some View {
        switch mode {
        case .now:
            let groups = nowGroups(theme, now: now)
            if groups.isEmpty {
                empty(String(localized: "Aucune chaîne de ce thème en ce moment (d'après le guide TV et le nom des chaînes)."))
            } else {
                List(groups) { group in
                    row(group: group, programme: store.epg.current(for: group.epgID, at: now), now: now)
                }
                .listStyle(.plain)
            }
        case .tonight:
            let entries = tonight(theme, now: now)
            if entries.isEmpty {
                empty(String(localized: "Aucun programme de ce thème ce soir (d'après le guide TV)."))
            } else {
                List(entries, id: \.programme.id) { entry in
                    row(group: entry.group, programme: entry.programme, now: now)
                }
                .listStyle(.plain)
            }
        case .channels:
            let groups = store.liveGroups.filter { (theme == nil || $0.theme == theme) && matchesSport(nil, $0) }
            if groups.isEmpty {
                empty(String(localized: "Aucune chaîne dans ce thème."))
            } else {
                List(groups.prefix(1500).map { $0 }) { group in
                    row(group: group, programme: store.epg.current(for: group.epgID, at: now), now: now)
                }
                .listStyle(.plain)
            }
        }
    }

    private func empty(_ text: String) -> some View {
        ContentUnavailableView(theme?.label ?? String(localized: "Thèmes"),
                               systemImage: theme?.icon ?? "square.grid.2x2",
                               description: Text(text))
            .frame(maxHeight: .infinity)
    }

    private func row(group: LiveChannelGroup, programme: Programme?, now: Date) -> some View {
        let channel = group.preferred
        let airing = programme.map { $0.start <= now && now < $0.stop } ?? true
        return Button {
            if let programme, !airing {
                ui.programme = ProgrammeRef(channel: channel, programme: programme)
            } else {
                ui.play(channel, store: store, playback: playback)
            }
        } label: {
            IOSProgrammeRow(channel: channel, programme: programme, now: now)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Regarder", systemImage: "play.fill") { ui.play(channel, store: store, playback: playback) }
            if let programme {
                Button("Fiche du programme", systemImage: "info.circle") {
                    ui.programme = ProgrammeRef(channel: channel, programme: programme)
                }
            }
            Button(store.isFavorite(channel.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris"),
                   systemImage: store.isFavorite(channel.id) ? "star.slash" : "star") {
                store.toggleFavorite(channel.id)
            }
            if group.variants.count > 1 {
                Menu("Version") {
                    ForEach(group.variants) { variant in
                        Button(variant.name) { ui.play(variant, store: store, playback: playback) }
                    }
                }
            }
            Menu("Thème de la chaîne") {
                ForEach(ContentTheme.browsable) { item in
                    Button {
                        store.setTheme(item, forChannelKey: group.key)
                    } label: {
                        if group.theme == item { Label(item.label, systemImage: "checkmark") } else { Text(item.label) }
                    }
                }
                if store.themeOverrides[group.key] != nil {
                    Divider()
                    Button("Automatique (\(group.autoTheme.label))") { store.setTheme(nil, forChannelKey: group.key) }
                }
            }
        }
    }

    // MARK: Données

    private func matchesSport(_ programme: Programme?, _ group: LiveChannelGroup) -> Bool {
        guard theme == .sport, let sportKind else { return true }
        if let programme, let kind = SportKind.of(programme) { return kind == sportKind }
        return SportKind.detect(group.preferred.name) == sportKind
    }

    private func nowGroups(_ wanted: ContentTheme?, now: Date) -> [LiveChannelGroup] {
        store.liveGroups.filter { group in
            guard let programme = store.epg.current(for: group.epgID, at: now) else {
                // Sans programme au guide : la chaîne reste proposée si son nom suffit à la classer.
                guard group.themeFromName, group.theme != .other else { return false }
                guard let wanted else { return true }
                return group.theme == wanted && matchesSport(nil, group)
            }
            guard let wanted else { return true }
            return (programme.theme ?? group.theme) == wanted && matchesSport(programme, group)
        }
    }

    private func tonight(_ wanted: ContentTheme?, now: Date) -> [(group: LiveChannelGroup, programme: Programme)] {
        let window = ThemeWindows.tonight(now: now)
        var result: [(group: LiveChannelGroup, programme: Programme)] = []
        for group in store.liveGroups {
            for programme in store.epg.programmes(for: group.epgID)
            where programme.start >= window.start && programme.start < window.end
                && programme.stop > now
                && (wanted == nil || (programme.theme ?? group.theme) == wanted)
                && matchesSport(programme, group) {
                result.append((group, programme))
            }
        }
        return result.sorted { $0.programme.start < $1.programme.start }
    }
}
