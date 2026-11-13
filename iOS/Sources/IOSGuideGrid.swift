import SwiftUI
import KastideoCore

/// Décalage horizontal de la grille : lu seulement par les éléments qui restent « collés » au bord gauche.
@MainActor @Observable
final class IOSGuideScroll {
    var x: CGFloat = 0
}

private struct GuideOffsetKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { value = nextValue() }
}

/// Suit le défilement horizontal : API de défilement d'iOS 18 (exacte), sinon mesure de la position du contenu.
private struct HScrollTracking: ViewModifier {
    let scroll: IOSGuideScroll

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.x }, action: { _, new in
                scroll.x = max(new, 0)
            })
        } else {
            content
                .coordinateSpace(name: "guideScroll")
                .onPreferenceChange(GuideOffsetKey.self) { point in
                    scroll.x = max(-point.x, 0)
                }
        }
    }
}

/// Guide TV en grille, comme sur Mac : la journée en ligne du temps horizontale, une ligne par chaîne,
/// colonne des chaînes et ligne des heures toujours visibles, repère « maintenant », zoom par pincement.
struct IOSGuideGrid: View {
    let channels: [MediaItem]
    /// Début (minuit) du jour affiché.
    let dayStart: Date
    /// Demi-heure vers laquelle défiler (0…47) ; nil = maintenant (ou 20 h pour un autre jour).
    let jumpTarget: Int?
    /// Change à chaque demande de défilement.
    let jumpToken: Int

    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @Environment(IOSAlertCenter.self) private var alerts
    @AppStorage("ios.guide.zoom") private var zoom = 1.0
    @State private var zoomBase: Double?
    @State private var scroll = IOSGuideScroll()
    @State private var now = Date()

    private let labelW: CGFloat = 84
    private let headerH: CGFloat = 32
    private let rowH: CGFloat = 60

    /// Points par minute (30 minutes = 90 pt au zoom normal).
    private var ppm: CGFloat { 3.0 * CGFloat(min(max(zoom, 0.5), 3.0)) }
    private var totalW: CGFloat { 1440 * ppm }
    private var dayEnd: Date { Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86400) }
    private var isToday: Bool { Calendar.current.isDateInToday(dayStart) }

    private func x(_ date: Date) -> CGFloat { CGFloat(date.timeIntervalSince(dayStart) / 60) * ppm }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    anchors
                    Section {
                        ForEach(channels.prefix(400)) { channel in
                            row(channel)
                        }
                    } header: {
                        header
                    }
                }
                .frame(width: labelW + totalW, alignment: .leading)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: GuideOffsetKey.self,
                                               value: geo.frame(in: .named("guideScroll")).origin)
                    }
                )
            }
            .scrollIndicators(.hidden)
            .modifier(HScrollTracking(scroll: scroll))
            .onAppear { go(proxy) }
            .onChange(of: jumpToken) { _, _ in go(proxy) }
        }
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    if zoomBase == nil { zoomBase = zoom }
                    zoom = min(max((zoomBase ?? 1) * value.magnification, 0.5), 3.0)
                }
                .onEnded { _ in zoomBase = nil }
        )
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
    }

    // MARK: Défilement

    /// Repères invisibles (un par demi-heure) vers lesquels on défile.
    private var anchors: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: labelW, height: 0.5)
            ForEach(0..<48, id: \.self) { index in
                Color.clear.frame(width: 30 * ppm, height: 0.5).id(index)
            }
        }
    }

    private func go(_ proxy: ScrollViewProxy) {
        let target: Int
        if let jumpTarget {
            target = jumpTarget
        } else if isToday {
            target = max(Int(now.timeIntervalSince(dayStart) / 1800) - 1, 0)
        } else {
            target = 40
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            proxy.scrollTo(min(max(target, 0), 47), anchor: .topLeading)
        }
    }

    // MARK: En-tête

    private var header: some View {
        ZStack(alignment: .topLeading) {
            let step = 30 * ppm >= 62 ? 1 : 2
            ForEach(Array(stride(from: 0, to: 48, by: step)), id: \.self) { index in
                Text(String(format: "%02d:%02d", index / 2, (index % 2) * 30))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(index % 2 == 0 ? Color.primary : Color.secondary)
                    .offset(x: labelW + CGFloat(index) * 30 * ppm + 6, y: 8)
            }
            if now >= dayStart, now < dayEnd {
                Rectangle().fill(Color.red).frame(width: 1.5, height: headerH)
                    .offset(x: labelW + x(now))
            }
            IOSGuideCorner(scroll: scroll, width: labelW, height: headerH, day: dayStart)
        }
        .frame(width: labelW + totalW, height: headerH, alignment: .topLeading)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: Lignes

    private func row(_ channel: MediaItem) -> some View {
        let programmes = store.epg.programmes(for: channel.epgID).filter { $0.stop > dayStart && $0.start < dayEnd }
        return ZStack(alignment: .topLeading) {
            ForEach(programmes) { programme in
                cell(channel, programme)
            }
            if now >= dayStart, now < dayEnd {
                Rectangle().fill(Color.red.opacity(0.8)).frame(width: 1.5, height: rowH)
                    .offset(x: labelW + x(now))
                    .allowsHitTesting(false)
            }
            IOSGuideChannelLabel(channel: channel, scroll: scroll, width: labelW, height: rowH)
                .zIndex(1)
        }
        .frame(width: labelW + totalW, height: rowH, alignment: .topLeading)
        .overlay(alignment: .bottom) { Divider() }
    }

    @ViewBuilder
    private func cell(_ channel: MediaItem, _ programme: Programme) -> some View {
        let x0 = max(x(programme.start), 0)
        let x1 = min(x(programme.stop), totalW)
        if x1 - x0 > 3 {
            let airing = programme.start <= now && now < programme.stop
            let past = programme.stop <= now
            Button {
                ui.programme = ProgrammeRef(channel: channel, programme: programme)
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text(programme.title).font(.caption.weight(.semibold)).lineLimit(2)
                    Text(programme.start.formatted(date: .omitted, time: .shortened))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6).padding(.vertical, 3)
                .frame(width: max(x1 - x0 - 2, 1), height: rowH - 6, alignment: .topLeading)
                .background(airing ? IOSPalette.orange.opacity(0.28) : Color.secondary.opacity(past ? 0.08 : 0.17),
                            in: RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .bottomLeading) {
                    if airing {
                        Capsule().fill(IOSPalette.orange)
                            .frame(width: max((x1 - x0 - 2) * CGFloat(programme.progress(at: now)), 2), height: 3)
                            .padding(.bottom, 2)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .offset(x: labelW + x0 + 1, y: 3)
            .contextMenu { menu(channel, programme, airing: airing) }
        }
    }

    @ViewBuilder
    private func menu(_ channel: MediaItem, _ programme: Programme, airing: Bool) -> some View {
        if airing {
            Button("Regarder en direct", systemImage: "play.fill") { ui.play(channel, store: store, playback: playback) }
        }
        if store.canReplay(channel, programme: programme, now: now) {
            Button(airing ? String(localized: "Revoir depuis le début") : String(localized: "Revoir (replay)"),
                   systemImage: "arrow.counterclockwise") {
                ui.playReplay(channel: channel, programme: programme, store: store, playback: playback)
            }
        }
        if programme.start > now {
            Button(alerts.isWatching(programme) ? String(localized: "Ne plus me prévenir") : String(localized: "Me prévenir au début"),
                   systemImage: alerts.isWatching(programme) ? "bell.slash" : "bell") {
                alerts.toggleOneShot(programme, channel: channel)
                alerts.reschedule(store: store)
            }
        }
        Button(store.isFavorite(channel.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris"),
               systemImage: store.isFavorite(channel.id) ? "star.slash" : "star") {
            store.toggleFavorite(channel.id)
        }
    }
}

/// Coin en haut à gauche : le jour affiché, collé au bord gauche.
private struct IOSGuideCorner: View {
    let scroll: IOSGuideScroll
    let width: CGFloat
    let height: CGFloat
    let day: Date

    var body: some View {
        Text(day.formatted(.dateTime.weekday(.abbreviated).day()))
            .font(.caption.weight(.semibold))
            .frame(width: width, height: height)
            .background(Color(.systemBackground))
            .overlay(alignment: .trailing) { Divider() }
            .offset(x: scroll.x)
            .zIndex(2)
    }
}

/// Chaîne de la ligne, collée au bord gauche pendant le défilement horizontal.
private struct IOSGuideChannelLabel: View {
    let channel: MediaItem
    let scroll: IOSGuideScroll
    let width: CGFloat
    let height: CGFloat
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui

    var body: some View {
        Button {
            ui.play(channel, store: store, playback: playback)
        } label: {
            VStack(spacing: 3) {
                ArtworkView(url: channel.logoURL, name: channel.name)
                    .frame(width: 44, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(TMDB.cleanTitle(channel.name).title)
                    .font(.system(size: 9.5))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .frame(width: width, height: height)
            .background(Color(.systemBackground))
            .overlay(alignment: .trailing) { Divider() }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Regarder en direct", systemImage: "play.fill") { ui.play(channel, store: store, playback: playback) }
            Button(store.isFavorite(channel.id) ? String(localized: "Retirer des favoris") : String(localized: "Ajouter aux favoris"),
                   systemImage: store.isFavorite(channel.id) ? "star.slash" : "star") {
                store.toggleFavorite(channel.id)
            }
            Button("Modifier la chaîne…", systemImage: "pencil") { ui.editingChannel = channel }
        }
        .offset(x: scroll.x)
    }
}
