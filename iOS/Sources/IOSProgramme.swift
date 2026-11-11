import SwiftUI
import KastideoCore

/// Un programme du guide, avec la chaîne qui le diffuse.
struct ProgrammeRef: Identifiable {
    let channel: MediaItem
    let programme: Programme
    var id: String { channel.id + "|" + programme.id }
}

extension IOSUI {
    /// Revoit un programme depuis l'archive du fournisseur (replay).
    func playReplay(channel: MediaItem, programme: Programme, store: LibraryStore, playback: PlaybackController) {
        guard let replay = store.makeReplay(channel: channel, programme: programme) else { return }
        playback.play(replay)
        showPlayer = true
    }
}

extension Programme {
    /// « 20:55 – 22:30 »
    func timeRange() -> String {
        "\(start.formatted(date: .omitted, time: .shortened)) – \(stop.formatted(date: .omitted, time: .shortened))"
    }

    /// Durée lisible : « 1 h 35 » ou « 40 min ».
    var durationText: String {
        let minutes = Int(stop.timeIntervalSince(start) / 60)
        return minutes >= 60 ? String(format: "%d h %02d", minutes / 60, minutes % 60) : String(localized: "\(minutes) min")
    }
}

/// Fiche d'un programme : résumé, et Regarder / Revoir selon ce qui est possible.
struct IOSProgrammeSheet: View {
    let ref: ProgrammeRef
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @Environment(IOSAlertCenter.self) private var alerts
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let programme = ref.programme
        let channel = ref.channel
        let now = Date()
        let airing = programme.start <= now && now < programme.stop
        let replayable = store.canReplay(channel, programme: programme, now: now)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        ArtworkView(url: channel.logoURL, name: channel.name)
                            .frame(width: 56, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(TMDB.cleanTitle(channel.name).title).font(.subheadline.weight(.semibold))
                            Text("\(programme.start.formatted(.dateTime.weekday(.wide).day().month())) · \(programme.timeRange())")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text(programme.title).font(.title2.bold())
                    HStack(spacing: 8) {
                        if let theme = programme.theme {
                            Label(theme.label, systemImage: theme.icon)
                        }
                        Text(programme.durationText)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    if airing {
                        ProgressView(value: programme.progress(at: now)).tint(IOSPalette.orange)
                    }
                    if let desc = programme.desc, !desc.isEmpty {
                        Text(desc).font(.body)
                    }
                    VStack(spacing: 10) {
                        if airing {
                            Button {
                                ui.programme = nil
                                ui.play(channel, store: store, playback: playback)
                            } label: {
                                Label("Regarder en direct", systemImage: "play.fill").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        if replayable {
                            let start = {
                                ui.programme = nil
                                ui.playReplay(channel: channel, programme: programme, store: store, playback: playback)
                            }
                            if airing {
                                Button(action: start) {
                                    Label("Revoir depuis le début", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Button(action: start) {
                                    Label("Revoir (replay)", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        if !airing && !replayable && programme.start > now {
                            Label("Ce programme n'est pas encore diffusé.", systemImage: "clock")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        if programme.start > now {
                            Button {
                                alerts.toggleOneShot(programme, channel: channel)
                                alerts.reschedule(store: store)
                            } label: {
                                Label(alerts.isWatching(programme) ? String(localized: "Ne plus me prévenir") : String(localized: "Me prévenir au début"),
                                      systemImage: alerts.isWatching(programme) ? "bell.slash" : "bell")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        Button {
                            store.toggleFavorite(channel.id)
                        } label: {
                            Label(store.isFavorite(channel.id) ? String(localized: "Retirer la chaîne des favoris") : String(localized: "Ajouter la chaîne aux favoris"),
                                  systemImage: store.isFavorite(channel.id) ? "star.slash" : "star")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .controlSize(.large)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Ligne « chaîne + programme » commune aux thèmes et au guide.
struct IOSProgrammeRow: View {
    let channel: MediaItem
    let programme: Programme?
    var now: Date = Date()
    var showProgress = true
    @AppStorage(IOSKeys.density) private var densityRaw = IOSDensity.standard.rawValue

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: channel.logoURL, name: channel.name)
                .frame(width: 56, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(programme?.title ?? TMDB.cleanTitle(channel.name).title)
                    .font(.body.weight(.medium)).lineLimit(1)
                HStack(spacing: 5) {
                    Text(TMDB.cleanTitle(channel.name).title)
                    if let programme { Text("· " + programme.timeRange()) }
                }
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                if showProgress, let programme, programme.start <= now, now < programme.stop {
                    ProgressView(value: programme.progress(at: now)).tint(IOSPalette.orange)
                }
            }
            Spacer(minLength: 4)
            if (channel.archiveDays ?? 0) > 0 && ReplaySettings.enabled {
                Image(systemName: "arrow.counterclockwise").font(.caption).foregroundStyle(.secondary)
            }
            if let programme, let theme = programme.theme {
                Image(systemName: theme.icon).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, IOSDensity.current(densityRaw).padding)
        .contentShape(Rectangle())
    }
}
