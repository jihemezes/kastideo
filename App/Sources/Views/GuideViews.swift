import SwiftUI
import KastideoCore

/// Guide TV en grille : chaînes en lignes, heures en colonnes.
struct GuideView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @AppStorage("guide.span") private var spanHours = 3
    @State private var windowStart = GuideView.defaultStart()
    @State private var filter: TVModel.Filter = .all
    @State private var query = ""
    @State private var rows: [MediaItem] = []

    private let labelWidth: CGFloat = 200

    /// Début de la demi-heure en cours, moins 30 minutes (pour voir ce qui vient de commencer).
    static func defaultStart(now: Date = Date()) -> Date {
        Date(timeIntervalSince1970: floor(now.timeIntervalSince1970 / 1800) * 1800 - 1800)
    }

    private struct RowsKey: Hashable {
        let filter: TVModel.Filter
        let query: String
        let guideChannels: Int
        let liveCount: Int
    }

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            content
        }
        .task(id: RowsKey(filter: filter, query: query,
                          guideChannels: store.epg.channelCount, liveCount: store.count(for: .live))) {
            rows = computeRows()
        }
    }

    // MARK: Barre de commandes

    private var controls: some View {
        HStack(spacing: 10) {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                .help("Plus tôt")
            Button("Maintenant") { windowStart = Self.defaultStart() }
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
                .help("Plus tard")
            Menu {
                ForEach(0..<7, id: \.self) { offset in
                    Button(dayLabel(offset: offset)) { jump(toDayOffset: offset) }
                }
            } label: {
                Text(windowStart.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.headline)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            Spacer()
            Picker("Durée affichée", selection: $spanHours) {
                Text("2 h").tag(2)
                Text("3 h").tag(3)
                Text("6 h").tag(6)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 140)
            .help("Durée affichée dans la grille")
            Menu {
                Button("Toutes les chaînes") { filter = .all }
                Button("Favoris") { filter = .favorites }
                Button("Récents") { filter = .recents }
                let categories = store.categoriesByKind[.live] ?? []
                if !categories.isEmpty {
                    Divider()
                    ForEach(categories, id: \.self) { name in
                        Button(name) { filter = .category(name) }
                    }
                }
            } label: {
                Label(filterTitle, systemImage: "line.3.horizontal.decrease.circle")
                    .lineLimit(1)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            TextField("Rechercher une chaîne", text: $query)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
        }
        .padding(10)
    }

    private var filterTitle: String {
        switch filter {
        case .all: return String(localized: "Toutes les chaînes")
        case .favorites: return String(localized: "Favoris")
        case .recents: return String(localized: "Récents")
        case .category(let name): return name
        }
    }

    private func dayLabel(offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        let text = date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        switch offset {
        case 0: return String(localized: "Aujourd'hui — \(text)")
        case 1: return String(localized: "Demain — \(text)")
        default: return text
        }
    }

    /// Aujourd'hui : maintenant. Les autres jours : 19 h (début de soirée).
    private func jump(toDayOffset offset: Int) {
        if offset == 0 {
            windowStart = Self.defaultStart()
            return
        }
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        windowStart = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: day) ?? day
    }

    private func shift(_ direction: Int) {
        let step = Double(max(spanHours / 2, 1)) * 3600
        windowStart = windowStart.addingTimeInterval(Double(direction) * step)
    }

    // MARK: Grille

    @ViewBuilder
    private var content: some View {
        if rows.isEmpty {
            if store.isBusy {
                ProgressView("Chargement du guide TV…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(query.isEmpty ? String(localized: "Aucun programme") : String(localized: "Aucun résultat"),
                                       systemImage: "calendar",
                                       description: Text(query.isEmpty
                                            ? String(localized: "Le guide TV n'est pas chargé, ou aucune chaîne de ce filtre n'a de programmes. Vérifiez l'adresse du guide dans les réglages de la source, et le guide de secours dans Réglages > Général.")
                                            : String(localized: "Aucune chaîne ne correspond à cette recherche.")))
            }
        } else {
            GeometryReader { geo in
                let gridWidth = max(geo.size.width - labelWidth, 240)
                let span = Double(spanHours) * 3600
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            Section {
                                ForEach(rows) { item in
                                    GuideRow(item: item, windowStart: windowStart, span: span,
                                             labelWidth: labelWidth, gridWidth: gridWidth, now: context.date)
                                }
                            } header: {
                                GuideHeader(windowStart: windowStart, span: span,
                                            labelWidth: labelWidth, gridWidth: gridWidth, now: context.date)
                            }
                        }
                    }
                }
            }
        }
    }

    private func computeRows() -> [MediaItem] {
        let base: [MediaItem]
        switch filter {
        case .all:
            base = store.items(for: .all(.live))
        case .favorites:
            base = store.items(for: .favorites).filter { $0.kind == .live }
        case .recents:
            base = store.items(for: .recents).filter { $0.kind == .live }
        case .category(let name):
            base = store.items(for: .category(.live, name))
        }
        let key = query.kastideoSearchKey
        return base.filter { item in
            (key.isEmpty || item.searchKey.contains(key)) && !store.epg.programmes(for: item.epgID).isEmpty
        }
    }
}

/// En-tête de la grille : heures et repère « maintenant ».
struct GuideHeader: View {
    let windowStart: Date
    let span: TimeInterval
    let labelWidth: CGFloat
    let gridWidth: CGFloat
    let now: Date

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: labelWidth, height: 28)
            ZStack(alignment: .topLeading) {
                let count = Int(span / 1800)
                ForEach(0..<count, id: \.self) { index in
                    let date = windowStart.addingTimeInterval(Double(index) * 1800)
                    Text(date.formatted(date: .omitted, time: .shortened))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(index % 2 == 0 ? .primary : .secondary)
                        .padding(.leading, 6)
                        .offset(x: gridWidth * CGFloat(Double(index) * 1800 / span), y: 6)
                }
                if now >= windowStart, now <= windowStart.addingTimeInterval(span) {
                    Rectangle()
                        .fill(.red)
                        .frame(width: 1.5, height: 28)
                        .offset(x: gridWidth * CGFloat(now.timeIntervalSince(windowStart) / span))
                }
            }
            .frame(width: gridWidth, height: 28, alignment: .topLeading)
            .clipped()
        }
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }
}

/// Une chaîne et ses programmes sur la période affichée.
struct GuideRow: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    let item: MediaItem
    let windowStart: Date
    let span: TimeInterval
    let labelWidth: CGFloat
    let gridWidth: CGFloat
    let now: Date

    var body: some View {
        HStack(spacing: 0) {
            channelCell
            strip
        }
        .frame(height: 58)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var channelCell: some View {
        Button {
            navigation.watchLive(item)
        } label: {
            HStack(spacing: 8) {
                if let number = item.number {
                    Text("\(number)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
                LogoView(url: item.logoURL, name: item.name, size: 32)
                Text(item.name)
                    .font(.callout)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(width: labelWidth, height: 58, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Regarder \(item.name)")
        .contextMenu { ItemActionsMenu(item: item) }
    }

    private var strip: some View {
        let end = windowStart.addingTimeInterval(span)
        let programmes = store.epg.programmes(for: item.epgID).filter { $0.stop > windowStart && $0.start < end }
        return ZStack(alignment: .topLeading) {
            ForEach(programmes) { programme in
                let x0 = max(programme.start.timeIntervalSince(windowStart) / span, 0) * gridWidth
                let x1 = min(programme.stop.timeIntervalSince(windowStart) / span, 1) * gridWidth
                if x1 - x0 > 4 {
                    GuideCell(item: item, programme: programme, now: now, width: x1 - x0)
                        .offset(x: x0)
                }
            }
            if now >= windowStart, now <= end {
                Rectangle()
                    .fill(.red.opacity(0.85))
                    .frame(width: 1.5, height: 58)
                    .offset(x: gridWidth * CGFloat(now.timeIntervalSince(windowStart) / span))
                    .allowsHitTesting(false)
            }
        }
        .frame(width: gridWidth, height: 58, alignment: .topLeading)
        .clipped()
    }
}

/// Un programme dans la grille ; un clic ouvre la fiche avec les actions.
struct GuideCell: View {
    @Environment(RecordingCenter.self) private var recordings
    let item: MediaItem
    let programme: Programme
    let now: Date
    let width: CGFloat
    @State private var showPopover = false

    var body: some View {
        let isCurrent = programme.start <= now && now < programme.stop
        let isPast = programme.stop <= now
        let scheduled = recordings.isScheduled(item, programme)

        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                if scheduled {
                    Image(systemName: "record.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
                Text(programme.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
            }
            if width > 80 {
                Text("\(programme.start.formatted(date: .omitted, time: .shortened)) – \(programme.stop.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(isPast ? .secondary : .primary)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(width: max(width - 2, 1), height: 54, alignment: .topLeading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.quaternary)
                    .opacity(isPast ? 0.35 : 0.75)
                if isCurrent {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.tint)
                        .opacity(0.3)
                }
            }
        }
        .padding(.horizontal, 1)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { showPopover = true }
        .help(programme.title)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            GuideProgrammePopover(item: item, programme: programme, close: { showPopover = false })
        }
    }
}

/// Fiche d'un programme : description et actions (regarder, enregistrer, programmer).
struct GuideProgrammePopover: View {
    @Environment(NavigationModel.self) private var navigation
    @Environment(RecordingCenter.self) private var recordings
    let item: MediaItem
    let programme: Programme
    let close: () -> Void

    var body: some View {
        let now = Date()
        let isCurrent = programme.start <= now && now < programme.stop
        let isFuture = programme.start > now
        VStack(alignment: .leading, spacing: 10) {
            Text(programme.title).font(.headline)
            Text("\(item.name) · \(programme.start.formatted(date: .abbreviated, time: .shortened)) – \(programme.stop.formatted(date: .omitted, time: .shortened)) (\(durationText))")
                .font(.caption)
                .foregroundStyle(.secondary)
            if isCurrent {
                ProgressView(value: programme.progress(at: now))
                    .progressViewStyle(.linear)
            }
            if let desc = programme.desc, !desc.isEmpty {
                ScrollView {
                    Text(desc)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 140)
            }
            Divider()
            HStack {
                if !(programme.stop <= now) {
                    Button {
                        navigation.watchLive(item)
                        close()
                    } label: {
                        Label(isCurrent ? "Regarder" : "Aller sur la chaîne", systemImage: "play.fill")
                    }
                }
                Spacer()
                if isCurrent {
                    if recordings.isRecording(item) {
                        Label("Enregistrement en cours", systemImage: "record.circle.fill")
                            .foregroundStyle(.red)
                    } else {
                        Button {
                            recordings.recordNow(item)
                            close()
                        } label: {
                            Label("Enregistrer", systemImage: "record.circle")
                        }
                    }
                } else if isFuture {
                    if recordings.isScheduled(item, programme) {
                        Label("Programmé", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.red)
                    } else {
                        Button {
                            recordings.schedule(item, programme: programme)
                            close()
                        } label: {
                            Label("Programmer l'enregistrement", systemImage: "calendar.badge.clock")
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    private var durationText: String {
        let minutes = Int(programme.stop.timeIntervalSince(programme.start) / 60)
        return minutes >= 60 ? String(format: "%d h %02d", minutes / 60, minutes % 60) : String(localized: "\(minutes) min")
    }
}

/// Guide TV en pleine fenêtre (interfaces Cinéma et TV) : onglets de section en haut.
struct GuideRootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings
    let style: InterfaceStyle

    var body: some View {
        NavigationStack {
            GuideView()
                .navigationTitle("Guide TV")
                .toolbar {
                    SectionPickerToolbar(navigation: navigation, playback: playback, recordings: recordings)
                    MainToolbar(store: store, scope: .live, style: style)
                }
        }
    }
}
