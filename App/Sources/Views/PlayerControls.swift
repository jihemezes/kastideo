import SwiftUI
import AppKit
import KastideoCore

/// Barre de contrôles compacte : lecture, avance / recul, mini-timeline, santé du flux, volume, panneau, mode cinéma.
struct ControlsBar: View {
    @Environment(PlaybackController.self) private var playback
    @Environment(NavigationModel.self) private var navigation
    @Environment(RecordingCenter.self) private var recordings
    @Binding var scrubbing: Double?

    var body: some View {
        @Bindable var playback = playback
        VStack(spacing: 6) {
            if playback.isSeekable {
                ScrubBar(scrubbing: $scrubbing)
            } else if playback.isTimeshifted {
                TimeshiftBar()
            }
            if let notice = playback.timeshiftNotice {
                Text(notice)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
                    .task(id: notice) {
                        try? await Task.sleep(for: .seconds(4))
                        if playback.timeshiftNotice == notice { playback.timeshiftNotice = nil }
                    }
            }
            HStack(spacing: 14) {
                Button { playback.togglePause() } label: {
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 22)
                }
                .help(playback.isLive && !playback.canPause ? String(localized: "Ce flux ne permet pas la pause") : String(localized: "Lecture / pause (⌘K) — en direct : différé"))
                .disabled(playback.isLive && playback.isPlaying && !playback.canPause)

                if playback.isSeekable {
                    Button { playback.jump(seconds: -10) } label: { Image(systemName: "gobackward.10") }
                        .help("Reculer de 10 s")
                    Button { playback.jump(seconds: 30) } label: { Image(systemName: "goforward.30") }
                        .help("Avancer de 30 s")
                    Text("\((scrubbing.map { $0 * playback.duration } ?? playback.elapsed).clockString) / \(playback.duration.clockString)")
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.85))
                } else if playback.isTimeshifted {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("DIFFÉRÉ −\(playback.delay(at: context.date).clockString)")
                                .font(.caption.weight(.bold).monospacedDigit())
                        }
                        .foregroundStyle(.yellow)
                    }
                    if playback.timeshiftSeekable {
                        Button { playback.jump(seconds: -10) } label: { Image(systemName: "gobackward.10") }
                            .help("Reculer de 10 s dans le différé")
                    }
                    Button { playback.jump(seconds: 30) } label: { Image(systemName: "goforward.30") }
                        .help(playback.timeshiftSeekable ? String(localized: "Avancer de 30 s dans le différé") : String(localized: "Avancer de 30 s (lecture accélérée jusqu'au point visé)"))
                    Menu {
                        ForEach(TimeshiftSettings.speeds, id: \.self) { speed in
                            Button {
                                playback.setRate(speed)
                            } label: {
                                if playback.rate == speed { Label(TimeshiftSettings.label(speed), systemImage: "checkmark") } else { Text(TimeshiftSettings.label(speed)) }
                            }
                        }
                    } label: {
                        Text(TimeshiftSettings.label(playback.rate))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(playback.rate > 1 ? Color.yellow : .white)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Vitesse de lecture du différé : accélérez pour rattraper le direct")
                    Button {
                        playback.catchUp(toDelay: 0)
                    } label: {
                        Label("Rattraper", systemImage: "forward.fill")
                    }
                    .help("Accélérer la lecture jusqu'à rattraper le direct (vitesse réglable dans Réglages > Général > Lecture)")
                    Button {
                        playback.goLive()
                    } label: {
                        Label("Retour au direct", systemImage: "dot.radiowaves.left.and.right")
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.red.opacity(0.85), in: Capsule())
                    }
                    .disabled(recordings.isPlayerRecording && !playback.timeshiftSeekable)
                    .help(recordings.isPlayerRecording && !playback.timeshiftSeekable
                          ? String(localized: "Indisponible pendant un enregistrement")
                          : playback.timeshiftSeekable
                            ? String(localized: "Revenir immédiatement au direct (le différé reste disponible)")
                            : String(localized: "Revenir immédiatement au direct (le flux est rouvert : le différé est effacé). Pour le garder, utilisez « Rattraper »."))
                } else {
                    HStack(spacing: 6) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text("EN DIRECT").font(.caption.weight(.bold))
                    }
                }

                Spacer(minLength: 8)

                HealthPill()

                if playback.isLive {
                    Button { recordings.toggleCurrentRecording() } label: {
                        Image(systemName: recordings.isRecording(playback.current) ? "stop.circle.fill" : "record.circle")
                            .foregroundStyle(.red)
                    }
                    .help(recordings.isRecording(playback.current) ? String(localized: "Arrêter l'enregistrement (⇧⌘R)") : String(localized: "Enregistrer cette chaîne (⇧⌘R)"))
                }

                Button { playback.isMuted.toggle() } label: {
                    Image(systemName: playback.isMuted || playback.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .frame(width: 22)
                }
                .help("Couper / rétablir le son")
                Slider(value: $playback.volume, in: 0...200)
                    .controlSize(.small)
                    .frame(width: 80)
                    .help("Volume (100 = normal, jusqu'à 200 %)")

                Button { navigation.showContextPanel.toggle() } label: {
                    Image(systemName: navigation.showContextPanel ? "sidebar.trailing" : "info.circle")
                }
                .help("Informations, pistes audio, sous-titres et qualité (⌘I)")

                Button { navigation.isTheater.toggle() } label: {
                    Image(systemName: navigation.isTheater ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                }
                .help("Mode cinéma (⌘↩ ou double-clic)")
            }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.white)
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .environment(\.colorScheme, .dark)
    }
}

/// Mini-timeline : un trait fin qui s'épaissit au survol ou pendant le déplacement, avec l'heure visée.
struct ScrubBar: View {
    @Environment(PlaybackController.self) private var playback
    @Binding var scrubbing: Double?
    @State private var hoverX: CGFloat?

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let progress = scrubbing ?? playback.position
            let active = hoverX != nil || scrubbing != nil
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.25))
                Capsule().fill(KastideoPalette.orange)
                    .frame(width: width * CGFloat(min(max(progress, 0), 1)))
                if active {
                    Circle().fill(.white)
                        .frame(width: 12, height: 12)
                        .offset(x: width * CGFloat(min(max(progress, 0), 1)) - 6)
                }
            }
            .frame(height: active ? 7 : 3)
            .frame(maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                if let x = hoverX ?? scrubbing.map({ CGFloat($0) * width }) {
                    Text((Double(x / width) * playback.duration).clockString)
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.black.opacity(0.75), in: Capsule())
                        .fixedSize()
                        .offset(x: min(max(x - 22, 0), width - 50), y: -20)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let point): hoverX = min(max(point.x, 0), width)
                case .ended: hoverX = nil
                }
            }
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in scrubbing = Double(min(max(value.location.x / width, 0), 1)) }
                .onEnded { value in
                    playback.seek(to: Double(min(max(value.location.x / width, 0), 1)))
                    scrubbing = nil
                })
            .animation(.easeOut(duration: 0.12), value: active)
        }
        .frame(height: 14)
    }
}

/// Pastille de santé du flux : couleur et mot simple, détails au survol.
struct HealthPill: View {
    @Environment(PlaybackController.self) private var playback
    @State private var hovering = false

    var body: some View {
        let health = playback.health
        HStack(spacing: 5) {
            Circle().fill(health.color).frame(width: 8, height: 8)
            if hovering || health.level == .poor {
                Text(health.label).font(.caption.weight(.semibold))
            }
            if let quality = health.qualityShort {
                Text(quality).font(.caption2.weight(.bold))
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.white.opacity(0.6), lineWidth: 1))
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .help(health.detailText)
        .opacity(health.level == .unknown ? 0.5 : 1)
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

extension StreamHealth {
    var color: Color {
        switch level {
        case .good: return .green
        case .fair: return .orange
        case .poor: return .red
        case .unknown: return .gray
        }
    }

    var qualityShort: String? {
        guard let resolution else { return nil }
        let h = resolution.height
        if h >= 2000 { return "4K" }
        if h >= 1000 { return "HD" }
        if h >= 700 { return "HD" }
        return "SD"
    }

    var bitrateText: String? {
        guard bitrateKbps > 0 else { return nil }
        return bitrateKbps >= 1000 ? String(format: "%.1f Mb/s", bitrateKbps / 1000) : String(format: "%.0f kb/s", bitrateKbps)
    }

    var detailText: String {
        var lines = [String(localized: "Qualité de réception : \(label)")]
        if let quality = qualityLabel, let resolution {
            lines.append("\(quality) (\(Int(resolution.width))×\(Int(resolution.height)))")
        }
        if let bitrateText { lines.append(String(localized: "Débit : \(bitrateText)")) }
        if framesPerSecond > 0 { lines.append(String(format: String(localized: "Images : %.0f par seconde"), framesPerSecond)) }
        if lostRatio > 0 { lines.append(String(format: String(localized: "Images perdues : %.1f %%"), lostRatio * 100)) }
        lines.append(recentStalls == 0 ? String(localized: "Aucune coupure dans la dernière minute")
                                       : String(localized: "\(recentStalls) coupure(s) dans la dernière minute"))
        return lines.joined(separator: "\n")
    }
}

/// Panneau « Contexte » : chaîne ou film, programme, épisodes, pistes audio, sous-titres et qualité.
struct PlayerContextPanel: View {
    @Environment(PlaybackController.self) private var playback
    @Environment(NavigationModel.self) private var navigation
    @Environment(LibraryStore.self) private var store
    @Environment(MediaInfoStore.self) private var info

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Informations").font(.headline)
                Spacer()
                Button {
                    navigation.showContextPanel = false
                } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
                .help("Fermer (⌘I)")
            }
            .padding(14)
            Divider().overlay(Color.white.opacity(0.15))
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let item = playback.current {
                        identity(item)
                        if item.kind == .live { programmes(item) } else { summary(item) }
                    }
                    tracksSection
                    qualitySection
                }
                .padding(14)
            }
        }
        .foregroundStyle(.white)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.1)))
        .environment(\.colorScheme, .dark)
        .task(id: playback.current?.id) {
            if let item = playback.current, item.kind == .movie || item.kind == .series {
                await info.load(item, store: store)
            }
        }
    }

    private func identity(_ item: MediaItem) -> some View {
        HStack(spacing: 12) {
            LogoView(url: item.logoURL, name: item.name, size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.kind == .live ? item.name : TMDB.cleanTitle(item.name).title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                Text(item.kind == .episode ? item.group : (item.number.map { "\($0) · " } ?? "") + item.group)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func programmes(_ item: MediaItem) -> some View {
        let current = store.epg.current(for: item.epgID)
        let upcoming = store.epg.upcoming(for: item.epgID, limit: 4)
        VStack(alignment: .leading, spacing: 10) {
            if let current {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EN CE MOMENT").font(.caption2.weight(.heavy)).foregroundStyle(KastideoPalette.orange)
                    Text(current.title).font(.headline)
                    Text("\(current.start.formatted(date: .omitted, time: .shortened)) – \(current.stop.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.white.opacity(0.7))
                    ProgressView(value: current.progress()).tint(KastideoPalette.orange)
                    if let desc = current.desc {
                        Text(desc).font(.callout).foregroundStyle(.white.opacity(0.85)).lineLimit(6)
                    }
                }
            } else {
                Text("Pas de programme dans le guide pour cette chaîne.")
                    .font(.callout).foregroundStyle(.white.opacity(0.6))
            }
            if !upcoming.isEmpty {
                Text("ENSUITE").font(.caption2.weight(.heavy)).foregroundStyle(.white.opacity(0.6))
                ForEach(upcoming) { programme in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(programme.start.formatted(date: .omitted, time: .shortened))
                            .font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.6))
                            .frame(width: 44, alignment: .leading)
                        Text(programme.title).font(.callout).lineLimit(2)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func summary(_ item: MediaItem) -> some View {
        let details = info.details(for: item)
        VStack(alignment: .leading, spacing: 6) {
            if let plot = details?.plot ?? item.info {
                Text(plot).font(.callout).foregroundStyle(.white.opacity(0.85)).lineLimit(8)
            }
            if let directors = details?.directors, !directors.isEmpty {
                Text("Réalisation : \(directors.joined(separator: ", "))").font(.caption).foregroundStyle(.white.opacity(0.7))
            }
            if let cast = details?.cast, !cast.isEmpty {
                Text("Avec : \(cast.prefix(5).map(\.name).joined(separator: ", "))").font(.caption).foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    @ViewBuilder
    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PISTE AUDIO").font(.caption2.weight(.heavy)).foregroundStyle(.white.opacity(0.6))
            if playback.audioTracks.isEmpty {
                Text("Aucune piste détectée").font(.callout).foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(playback.audioTracks) { track in
                    trackRow(track.name, selected: track.id == playback.currentAudioTrack) { playback.selectAudioTrack(track.id) }
                }
            }
            Text("SOUS-TITRES").font(.caption2.weight(.heavy)).foregroundStyle(.white.opacity(0.6)).padding(.top, 6)
            if playback.subtitleTracks.isEmpty {
                Text("Aucun sous-titre dans ce flux").font(.callout).foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(playback.subtitleTracks) { track in
                    trackRow(track.id < 0 ? String(localized: "Désactivés") : track.name,
                             selected: track.id == playback.currentSubtitleTrack) { playback.selectSubtitleTrack(track.id) }
                }
            }
        }
    }

    private func trackRow(_ name: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? KastideoPalette.orange : .white.opacity(0.4))
                Text(name).lineLimit(1)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .font(.callout)
    }

    private var qualitySection: some View {
        let health = playback.health
        return VStack(alignment: .leading, spacing: 6) {
            Text("RÉCEPTION").font(.caption2.weight(.heavy)).foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 8) {
                Circle().fill(health.color).frame(width: 10, height: 10)
                Text(health.label).font(.headline)
            }
            Text(health.detailText.split(separator: "\n").dropFirst().joined(separator: "\n"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
    }
}


/// Timeline du direct en différé : de la mise en pause (à gauche) jusqu'au direct (à droite).
/// Glisser le curseur vers la droite avance dans le différé (en accélérant la lecture si le moteur ne sait pas sauter).
struct TimeshiftBar: View {
    @Environment(PlaybackController.self) private var playback
    @State private var dragFraction: Double?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let delay = playback.delay(at: context.date)
            let total = max(playback.peakDelay, delay, 1)
            let current = (total - delay) / total
            GeometryReader { geo in
                let width = max(geo.size.width, 1)
                let shown = dragFraction ?? current
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.22))
                    // Déjà regardé (on ne peut pas y revenir sans déplacement possible dans le différé).
                    Capsule().fill(Color.white.opacity(playback.timeshiftSeekable ? 0.45 : 0.12))
                        .frame(width: width * CGFloat(current))
                    if let target = playback.catchUpTarget {
                        Rectangle().fill(Color.yellow)
                            .frame(width: 2, height: 12)
                            .offset(x: width * CGFloat((total - target) / total) - 1)
                    }
                    Circle().fill(Color.yellow)
                        .frame(width: 13, height: 13)
                        .offset(x: width * CGFloat(min(max(shown, 0), 1)) - 6.5)
                }
                .frame(height: 5)
                .frame(maxHeight: .infinity)
                .overlay(alignment: .topLeading) {
                    if let dragFraction {
                        Text(Self.label(total * (1 - dragFraction)))
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.black.opacity(0.75), in: Capsule())
                            .fixedSize()
                            .offset(x: min(max(width * CGFloat(dragFraction) - 26, 0), width - 60), y: -20)
                    }
                }
                .overlay(alignment: .trailing) {
                    Text("DIRECT").font(.system(size: 8, weight: .heavy)).foregroundStyle(.red).offset(y: 10)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = Double(min(max(value.location.x / width, 0), 1))
                        dragFraction = playback.timeshiftSeekable ? fraction : max(fraction, current)
                    }
                    .onEnded { _ in
                        if let fraction = dragFraction {
                            playback.catchUp(toDelay: total * (1 - fraction))
                        }
                        dragFraction = nil
                    })
            }
            .frame(height: 18)
        }
        .help("Glissez vers la droite pour avancer dans le différé ; tout à droite : le direct")
    }

    static func label(_ delay: TimeInterval) -> String {
        delay < 1 ? String(localized: "Direct") : "−" + delay.clockString
    }
}

/// Réglages du différé (Réglages > Général > Lecture).
struct TimeshiftSettingsRow: View {
    @AppStorage(PlaybackKeys.timeshiftMax) private var maxMinutes = 120
    @AppStorage(PlaybackKeys.catchUpSpeed) private var speed = 1.5

    var body: some View {
        Picker("Durée maximale du différé", selection: $maxMinutes) {
            Text("30 min").tag(30)
            Text("1 h").tag(60)
            Text("2 h").tag(120)
            Text("3 h").tag(180)
            Text("Sans limite").tag(0)
        }
        Picker("Vitesse pour rattraper le direct", selection: $speed) {
            Text("×1,25").tag(1.25)
            Text("×1,5").tag(1.5)
            Text("×2").tag(2.0)
        }
        LabeledContent("Dossier du différé") {
            HStack {
                Text(TimeshiftSettings.folder.path)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Button("Afficher") { NSWorkspace.shared.open(TimeshiftSettings.folder) }
            }
        }
        Text("Pendant une pause du direct, le flux continue d'être mis en mémoire sur le disque (environ 1 à 4 Go par heure selon la qualité). Les fichiers sont effacés au changement de chaîne. Une fois la durée maximale atteinte, la lecture reprend toute seule.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
