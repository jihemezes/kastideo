import SwiftUI
import KastideoCore

extension ContentTheme {
    var label: String {
        switch self {
        case .general: return String(localized: "Généralistes")
        case .news: return String(localized: "Info")
        case .sport: return String(localized: "Sport")
        case .movies: return String(localized: "Films")
        case .series: return String(localized: "Séries")
        case .documentary: return String(localized: "Documentaires")
        case .kids: return String(localized: "Jeunesse")
        case .entertainment: return String(localized: "Divertissement")
        case .music: return String(localized: "Musique")
        case .other: return String(localized: "Autres")
        }
    }

    /// Titre d'une rangée « en ce moment » (interface Cinéma, accueil).
    var nowTitle: String {
        switch self {
        case .sport: return String(localized: "Sport en ce moment")
        case .movies: return String(localized: "Films en cours")
        case .series: return String(localized: "Séries en cours")
        case .news: return String(localized: "Info en direct")
        case .documentary: return String(localized: "Documentaires en cours")
        case .kids: return String(localized: "Jeunesse en ce moment")
        case .entertainment: return String(localized: "Divertissement en ce moment")
        case .music: return String(localized: "Musique en ce moment")
        case .general, .other: return String(localized: "En ce moment")
        }
    }

    /// Thèmes proposés dans les filtres (les « autres » à la fin).
    static var browsable: [ContentTheme] { [.sport, .movies, .series, .news, .documentary, .kids, .entertainment, .music, .general, .other] }
}

/// Mode de la vue Thèmes.
enum ThemeMode: String, CaseIterable, Identifiable {
    case now, tonight, channels
    var id: String { rawValue }
    var label: String {
        switch self {
        case .now: return String(localized: "En ce moment")
        case .tonight: return String(localized: "Ce soir")
        case .channels: return String(localized: "Chaînes")
        }
    }
}

/// Qualité des chaînes proposées quand une chaîne existe en plusieurs versions.
enum QualityPreference: String, CaseIterable, Identifiable {
    case auto, uhd, fhd, hd, sd
    var id: String { rawValue }
    static let key = "live.quality"
    static let autoTierKey = "live.autoTier"

    var label: String {
        switch self {
        case .auto: return String(localized: "Automatique (selon la connexion)")
        case .uhd: return "4K"
        case .fhd: return "Full HD"
        case .hd: return "HD"
        case .sd: return "SD"
        }
    }

    static var current: QualityPreference {
        QualityPreference(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .auto
    }

    /// Qualité visée : choisie, ou ajustée automatiquement d'après la réception mesurée pendant les lectures.
    static var target: ChannelQuality {
        switch current {
        case .uhd: return .uhd
        case .fhd: return .fhd
        case .hd: return .hd
        case .sd: return .sd
        case .auto:
            let raw = UserDefaults.standard.object(forKey: autoTierKey) as? Int ?? ChannelQuality.fhd.rawValue
            return ChannelQuality(rawValue: raw) ?? .fhd
        }
    }
}

/// Vue « Thèmes » du direct (colonne centrale de l'interface Classique).
struct ThemesListView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(ProgramAlertCenter.self) private var alerts
    @AppStorage(QualityPreference.key) private var qualityRaw = QualityPreference.auto.rawValue
    @State private var showAlerts = false

    var body: some View {
        @Bindable var navigation = navigation
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Picker("Mode", selection: $navigation.themeMode) {
                        ForEach(ThemeMode.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    themeChips(now: now)
                }
                .padding(12)
                Divider()
                content(now: now)
            }
        }
        .navigationTitle(navigation.themeSelection?.label ?? String(localized: "Thèmes"))
        .navigationSubtitle(navigation.themeMode.label)
        .toolbar {
            ToolbarItem {
                Button {
                    showAlerts = true
                } label: {
                    Label("Alertes", systemImage: alerts.rules.isEmpty ? "bell" : "bell.badge")
                }
                .help("Alertes de programme")
            }
        }
        .sheet(isPresented: $showAlerts) { AlertRulesSheet() }
    }

    // MARK: Filtres

    private func themeChips(now: Date) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip(nil, count: nil)
                ForEach(ContentTheme.browsable) { theme in
                    let count = navigation.themeMode == .channels
                        ? store.liveGroups.filter { $0.theme == theme }.count
                        : nowGroups(theme, now: now).count
                    if count > 0 || navigation.themeSelection == theme { chip(theme, count: count) }
                }
            }
        }
    }

    private func chip(_ theme: ContentTheme?, count: Int?) -> some View {
        let selected = navigation.themeSelection == theme
        return Button {
            navigation.themeSelection = theme
        } label: {
            HStack(spacing: 5) {
                Image(systemName: theme?.icon ?? "square.grid.2x2")
                Text(theme?.label ?? String(localized: "Tout"))
                if let count, navigation.themeMode != .tonight { Text("\(count)").foregroundStyle(.secondary).monospacedDigit() }
            }
            .font(.callout.weight(selected ? .semibold : .regular))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selected ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Contenu

    @ViewBuilder
    private func content(now: Date) -> some View {
        switch navigation.themeMode {
        case .now:
            let groups = nowGroups(navigation.themeSelection, now: now)
            if groups.isEmpty {
                empty(String(localized: "Aucun programme de ce thème en ce moment (d'après le guide TV)."))
            } else {
                List(groups) { group in
                    programmeRow(group: group, programme: store.epg.current(for: group.epgID, at: now), now: now)
                }
                .listStyle(.inset)
            }
        case .tonight:
            let entries = tonight(navigation.themeSelection, now: now)
            if entries.isEmpty {
                empty(String(localized: "Aucun programme de ce thème ce soir (d'après le guide TV)."))
            } else {
                List(entries, id: \.programme.id) { entry in
                    programmeRow(group: entry.group, programme: entry.programme, now: now)
                }
                .listStyle(.inset)
            }
        case .channels:
            let groups = store.liveGroups.filter { navigation.themeSelection == nil || $0.theme == navigation.themeSelection }
            if groups.isEmpty {
                empty(String(localized: "Aucune chaîne dans ce thème."))
            } else {
                List(groups) { group in
                    programmeRow(group: group, programme: store.epg.current(for: group.epgID, at: now), now: now)
                }
                .listStyle(.inset)
            }
        }
    }

    private func empty(_ text: String) -> some View {
        ContentUnavailableView(navigation.themeSelection?.label ?? String(localized: "Thèmes"),
                               systemImage: navigation.themeSelection?.icon ?? "square.grid.2x2",
                               description: Text(text))
            .frame(maxHeight: .infinity)
    }

    private func programmeRow(group: LiveChannelGroup, programme: Programme?, now: Date) -> some View {
        let item = group.preferred
        let airing = programme.map { $0.start <= now && now < $0.stop } ?? true
        let selected = navigation.selectedItemID.map { id in group.variants.contains { $0.id == id } } ?? false
        return Button {
            if airing { navigation.selectedItemID = item.id }
        } label: {
            HStack(spacing: 10) {
                LogoView(url: item.logoURL, name: item.name, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(programme?.title ?? TMDB.cleanTitle(item.name).title)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(TMDB.cleanTitle(item.name).title)
                        if let programme {
                            Text("· \(programme.start.formatted(date: .omitted, time: .shortened))–\(programme.stop.formatted(date: .omitted, time: .shortened))")
                        }
                        Text("· \(ChannelQuality.of(item.name).label)").foregroundStyle(.tertiary)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    if let programme, airing {
                        ProgressView(value: programme.progress(at: now))
                            .progressViewStyle(.linear)
                            .controlSize(.mini)
                            .frame(maxWidth: 220)
                    }
                }
                Spacer()
                if let theme = programme?.theme ?? Optional(group.theme) {
                    Image(systemName: theme.icon).foregroundStyle(.secondary).help(theme.label)
                }
                if !airing, let programme {
                    Image(systemName: alerts.isWatching(programme) ? "bell.fill" : "bell")
                        .foregroundStyle(alerts.isWatching(programme) ? Color.accentColor : .secondary)
                        .help("Clic droit : m'alerter au début du programme")
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selected ? Color.accentColor.opacity(0.18) : Color.clear)
        .contextMenu {
            if airing { Button("Regarder") { navigation.selectedItemID = item.id } }
            if let programme, !airing {
                Button(alerts.isWatching(programme) ? String(localized: "Ne plus m'alerter") : String(localized: "M'alerter au début du programme")) {
                    alerts.toggleOneShot(programme, channel: item)
                }
            }
            if group.variants.count > 1 {
                Menu("Version") {
                    ForEach(group.variants) { variant in
                        Button(variant.name) { navigation.selectedItemID = variant.id }
                    }
                }
            }
            Divider()
            Menu("Thème de la chaîne") {
                ForEach(ContentTheme.browsable) { theme in
                    Button {
                        store.setTheme(theme, forChannelKey: group.key)
                    } label: {
                        if group.theme == theme { Label(theme.label, systemImage: "checkmark") } else { Text(theme.label) }
                    }
                }
                if store.themeOverrides[group.key] != nil {
                    Divider()
                    Button("Automatique (\(group.autoTheme.label))") { store.setTheme(nil, forChannelKey: group.key) }
                }
            }
            ItemActionsMenu(item: item)
        }
    }

    // MARK: Données

    private func nowGroups(_ theme: ContentTheme?, now: Date) -> [LiveChannelGroup] {
        store.liveGroups.filter { group in
            guard let programme = store.epg.current(for: group.epgID, at: now) else { return false }
            guard let theme else { return true }
            return (programme.theme ?? group.theme) == theme
        }
    }

    private func tonight(_ theme: ContentTheme?, now: Date) -> [(group: LiveChannelGroup, programme: Programme)] {
        let window = ThemeWindows.tonight(now: now)
        var result: [(group: LiveChannelGroup, programme: Programme)] = []
        for group in store.liveGroups {
            for programme in store.epg.programmes(for: group.epgID)
            where programme.start >= window.start && programme.start < window.end
                && programme.stop > now
                && (theme == nil || (programme.theme ?? group.theme) == theme) {
                result.append((group, programme))
            }
        }
        return result.sorted { $0.programme.start < $1.programme.start }
    }
}

/// Fenêtres horaires.
enum ThemeWindows {
    /// « Ce soir » : programmes commençant entre 20 h et 23 h (ou dès maintenant si la soirée est entamée).
    static func tonight(now: Date) -> DateInterval {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
        let end = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(3 * 3600)
        if now > end {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return DateInterval(start: tomorrow, end: tomorrow.addingTimeInterval(3 * 3600))
        }
        return DateInterval(start: start, end: end)
    }
}

/// Réglage : qualité des chaînes proposée dans les thèmes.
struct QualitySettingsRow: View {
    @AppStorage(QualityPreference.key) private var qualityRaw = QualityPreference.auto.rawValue
    @AppStorage(QualityPreference.autoTierKey) private var autoTier = ChannelQuality.fhd.rawValue

    var body: some View {
        Picker("Version des chaînes (vue Thèmes)", selection: $qualityRaw) {
            ForEach(QualityPreference.allCases) { Text($0.label).tag($0.rawValue) }
        }
        if qualityRaw == QualityPreference.auto.rawValue {
            Text("Quand une chaîne existe en plusieurs versions (4K, FHD, HD, SD), Kastideo propose celle qui convient à votre connexion : il baisse d'un cran après une lecture instable et remonte après plusieurs lectures fluides. Qualité retenue actuellement : \((ChannelQuality(rawValue: autoTier) ?? .fhd).label).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
