import SwiftUI
import KastideoCore

/// Guide TV en grille : fenêtre de 3 heures (colonne des chaînes fixe), décalable de 3 h en 3 h.
/// Un appui sur un programme propose de regarder la chaîne ou de revoir le programme (replay).
struct TVGuideView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(TVUI.self) private var ui
    @State private var category: String?
    @State private var windowStart = TVGuideView.roundedNow()
    @State private var selected: ProgrammePick?

    private let windowMinutes = 180.0
    private let labelWidth: CGFloat = 250
    private let rowHeight: CGFloat = 96

    struct ProgrammePick: Identifiable {
        let channel: MediaItem
        let programme: Programme
        var id: String { channel.id + "|" + programme.id }
    }

    private static func roundedNow() -> Date {
        let now = Date()
        return Date(timeIntervalSince1970: (now.timeIntervalSince1970 / 1800).rounded(.down) * 1800 - 1800)
    }

    private var categories: [String] { store.categoriesByKind[.live] ?? [] }
    private var activeCategory: String? { category ?? categories.first }
    private var channels: [MediaItem] {
        guard let name = activeCategory else { return [] }
        return store.items(for: .category(.live, name))
    }
    private var windowEnd: Date { windowStart.addingTimeInterval(windowMinutes * 60) }

    var body: some View {
        if !store.hasSources || store.count(for: .live) == 0 {
            TVEmptyView(text: String(localized: "Le guide apparaît quand une source de direct est chargée."))
        } else {
            GeometryReader { geo in
                let gridWidth = max(geo.size.width - 120 - labelWidth, 600)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        chips
                        controls
                        header(gridWidth: gridWidth)
                        let list = channels
                        ForEach(list.prefix(60)) { channel in
                            row(channel, list: list, gridWidth: gridWidth)
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 20)
                }
            }
            .confirmationDialog(selected?.programme.title ?? "", isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } }),
                                titleVisibility: .visible, presenting: selected) { pick in
                Button("Regarder la chaîne") { ui.play(pick.channel, list: channels, playback: playback) }
                if store.canReplay(pick.channel, programme: pick.programme), let replay = store.makeReplay(channel: pick.channel, programme: pick.programme) {
                    Button("Revoir ce programme") { ui.play(replay, playback: playback) }
                }
                Button("Annuler", role: .cancel) {}
            } message: { pick in
                Text("\(pick.channel.name) · \(pick.programme.timeRange())\n\(pick.programme.desc ?? "")")
            }
        }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(categories, id: \.self) { name in
                    Button { category = name } label: {
                        Text(name).font(.callout.weight(activeCategory == name ? .bold : .regular))
                    }
                    .tint(activeCategory == name ? TVPalette.orange : nil)
                }
            }
            .padding(.vertical, 10)
        }
    }

    private var controls: some View {
        HStack(spacing: 24) {
            Button { windowStart = windowStart.addingTimeInterval(-windowMinutes * 60) } label: { Label("3 h", systemImage: "chevron.left") }
            Button { windowStart = Self.roundedNow() } label: { Text("Maintenant") }
            Button { windowStart = windowStart.addingTimeInterval(windowMinutes * 60) } label: { Label("3 h", systemImage: "chevron.right") }
            Text(windowStart.formatted(.dateTime.weekday(.wide).day().month())).font(.callout).foregroundStyle(.secondary)
        }
    }

    private func header(gridWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: labelWidth, height: 30)
            ZStack(alignment: .topLeading) {
                ForEach(0..<6, id: \.self) { index in
                    let date = windowStart.addingTimeInterval(Double(index) * 1800)
                    Text(date.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .offset(x: gridWidth * CGFloat(index) / 6)
                }
            }
            .frame(width: gridWidth, height: 30, alignment: .topLeading)
        }
    }

    private func row(_ channel: MediaItem, list: [MediaItem], gridWidth: CGFloat) -> some View {
        let programmes = store.epg.programmes(for: channel.epgID).filter { $0.stop > windowStart && $0.start < windowEnd }
        return HStack(spacing: 0) {
            Button { ui.play(channel, list: list, playback: playback) } label: {
                HStack(spacing: 12) {
                    ArtworkView(url: channel.logoURL, name: channel.name)
                        .frame(width: 70, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text(channel.name).font(.caption).lineLimit(2).multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .frame(width: labelWidth, height: rowHeight)
            }
            .buttonStyle(.card)
            ZStack(alignment: .topLeading) {
                if programmes.isEmpty {
                    Text("Programme non disponible").font(.caption).foregroundStyle(.secondary)
                        .frame(width: gridWidth, height: rowHeight, alignment: .leading).padding(.leading, 16)
                }
                ForEach(programmes) { programme in
                    let from = max(programme.start.timeIntervalSince(windowStart) / 60, 0)
                    let to = min(programme.stop.timeIntervalSince(windowStart) / 60, windowMinutes)
                    let x = gridWidth * CGFloat(from / windowMinutes)
                    let w = max(gridWidth * CGFloat((to - from) / windowMinutes) - 6, 30)
                    let airing = programme.start <= Date() && programme.stop > Date()
                    Button { selected = ProgrammePick(channel: channel, programme: programme) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(programme.title).font(.caption.weight(.semibold)).lineLimit(1)
                            Text(programme.timeRange()).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .frame(width: w, height: rowHeight - 8, alignment: .leading)
                        .background(airing ? TVPalette.orange.opacity(0.35) : Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .offset(x: x, y: 4)
                }
            }
            .frame(width: gridWidth, height: rowHeight, alignment: .topLeading)
            .clipped()
        }
    }
}
